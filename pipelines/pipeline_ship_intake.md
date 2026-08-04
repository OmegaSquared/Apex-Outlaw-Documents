---
status: draft for review
phase: ship-intake at scale
last-reviewed: 2026-08-03
---

# Ship Intake Pipeline — FBX → parts → schemas → Factory Spec → in game

> **Goal:** take any solid donor ship FBX, cut it into build parts in Blender, land those
> parts in Unity as prefabs + `ShipPartSchema` assets with **auto-derived build costs from
> size and materials**, produce the ship's **Factory Spec blueprint**, and grant a
> **Factory-Complete bonus** to players who build the ship exactly as designed.
> Written 2026-08-03 to consolidate the proven pieces before the big ship-onboarding push.

This doc SUPERSEDES nothing — it stitches together what already works:

- `ships/ships_part_identification_process.md` — the hand-cut workflow ("that workflow is
  perfect"), Aaron points, assistant cuts. Still the heart of Stage 2.
- Corsair recipe (memory: corsair-parts-pipeline) — solidify, ship-root origin, export
  settings, region re-cut, mirror pairs.
- `ships/ships_construction_pipeline.md` — materials → components → parts → blueprint →
  shipyard (grades on instances only). Costing rules live here; intake feeds them.
- `ships/ships_blueprint_slot_model.md` — blueprint = frame + slots (canon 2026-07-20).
- `pipelines/pipeline_ship.md` — derive-everything-at-spawn via `NpcShipSpawner`.

What's NEW in this doc: the intake **manifest**, the **auto-costing formulas**
(volume × material density → mass → bills), per-part **convex colliders** as a first-class
output, the **Factory Spec blueprint** as the final verification step, and the
**Factory-Complete bonus** system.

---

## 0. The flow at a glance

```
MANIFEST    ship_intake/<family>.json — identity, family, nose axis, material, class
BLENDER     assisted cut (Aaron selects+names, script joins/solidifies/caps/exports)
INGEST      Unity batch: FBX → prefab + convex collider + ShipPartSchema (auto-costed)
FACTORY     reassemble all parts at local zero → save "<Ship> — Factory Spec" blueprint
            (this IS the verification: if it doesn't snap together, the cut is wrong)
BONUS       FactorySpec asset records the canonical frame; ships built to spec get
            +ATK / +DEF / −mass at spawn, derived — never stored
```

One ship = one manifest + one Blender session + one ingest run. Target throughput once
warm: **one ship per session** (the SM8 bomber took one pass; the F3 took longer because
the recipe was being invented).

---

## 1. Stage 0 — Intake manifest (new)

One JSON per donor ship, at `Assets/ShipIntake/<family>.json`. It is the single source
of truth the Blender script and the Unity ingest both read, and it's where per-ship
decisions get made ONCE instead of rediscovered per part:

```json
{
  "shipId": "smuggler_corvette",          // internal key, never renamed later
  "displayName": "Smuggler Corvette",
  "family": "smuggler",                   // schema family, alignment group
  "sourceFbx": "Art_Assets/3D_Ships/.../SM4_Corvette.fbx",
  "prefix": "SM4",                        // part naming: <prefix>_Part_<Name>
  "shipClass": "Corvette",  "size": "Medium",
  "originTag": "OUT",  "role": "Military",
  "noseLocalAxis": [0, 0, 1],             // CONFIRMED BY AARON before ingest, per canon
  "hullMaterial": "steel_standard",       // density + material mix for auto-costing (§4)
  "partsOutDir": "Art_Assets/ShipParts/SmugglerCorvette/",
  "bonus": { "attackPct": 10, "defensePct": 10, "massPct": -10 }   // Factory-Complete
}
```

Rules:

- **noseLocalAxis is confirmed in Unity, not eyeballed in Blender** (X-flip lesson;
  ship-nose-axis canon). New ships should be re-axed to nose = +Z at cut time so the
  schema default holds — the Y-long SM hulls remain the documented open asset bug, and we
  do not mint more of them.
- `hullMaterial` picks a row in the **material table** (§4) — that plus geometry is what
  makes cost derivation automatic.

## 2. Stage 1 — Blender assisted cut (proven, consolidated)

The locked workflow from `ships_part_identification_process.md`, with the Corsair
additions folded in. Aaron drives WHAT is a part; the script does everything else.

1. Import donor FBX into a working blend (`<prefix>_chunks.blend`). Bundled weapon props
   are separated into their own consideration pile (they become fittings, not parts —
   Plasma Lance precedent).
2. `separate(type='LOOSE')` everything; golden-ratio color every island (set shader color
   AND `diffuse_color`, viewport Solid `color_type='MATERIAL'`).
3. **Aaron selects a group and names it** ("left wing", "missile launcher"). Mirror side =
   Aaron's left with nose facing him — but side labels are only FINAL once confirmed in
   the Unity builder (X-flip).
4. Script locks it in, one pass per part:
   - read `selected_objects`, duplicate → join → rename `<prefix>_Part_<Name>`;
   - **make solid** (recalc normals → `fill_holes(sides=0)` → recalc; 0 open boundary
     edges required — this is what makes per-part convex colliders and volume math work);
   - restore donor material + `PartCap_Black` on the fill faces (caps = snap faces);
   - `transform_apply(scale)` only — **origin stays at ship root** (parts reassemble at
     local zero, non-negotiable);
   - export FBX: `use_selection, apply_unit_scale, bake_space_transform,
     axis_forward='-Z', axis_up='Y'`;
   - remove the part's islands from the working blend, `save_mainfile()` immediately.
5. Repeat until the remainder IS the hull → `<prefix>_Part_Hull` (midframe).
6. Mirror sanity check per pair: same island count, same vert count. Mismatch = missed
   piece.

Standing gotchas (all previously paid for — checklist, don't relearn):

- **Never roundtrip an exported part FBX** — `bake_space_transform` applies twice and
  Y/Z swap. To amend a part: re-cut from a fresh donor import (region bbox filter, or
  precise center-matching when regions overlap).
- Roundtrips also **flatten material groups** — after any, verify `subMeshCount == 2`;
  recovery = geometric cap re-derivation (BVH, faces within 0.2 m of a neighbour).
- Exact-name rejoin preserves Unity prefab mesh refs (Plasma Lance recipe) when carving
  a fitting out of an existing part.
- Don't reference removed objects in the result dict; never overwrite Aaron's viewport
  selection; his undo does not revert scripted joins — hence save-per-lock-in.

## 3. Stage 2 — Unity ingest (the automation upgrade)

Today this is a per-part hand pass. For the onboarding push it becomes **one batch run
per ship** — an editor tool (`ShipIntakeImporter`, editor-only) or an `execute_code`
batch that reads the manifest and, for every `<prefix>_Part_*.fbx` in `partsOutDir`:

1. **Import settings**: `globalScale=1`, `useFileScale=true`, ForceUpdate.
2. **Prefab** at `Assets/Prefabs/ShipParts/<bucket>/<Ship>/<Part>.prefab`; bind family
   material + `PartCap_Black` by slot name (the CoplayBakePart pattern, made manifest-driven).
3. **Collider — the "smaller colliders" ask**: each part prefab gets its own
   **convex `MeshCollider`** from its solid mesh (solidity from Stage 1 guarantees a sane
   hull; convex cap 255 tris is fine at these densities — log any part whose convex hull
   deviates >15% in volume from the mesh, candidates for a hand-simplified collider).
   The assembled ship then collides as its true silhouette per part — no more one-box
   ships, and per-part hit/severance falls out for free.
4. **ShipPartSchema** at `Resources/Schemas/ShipParts/<partId>.asset`: partClass
   (from the part's name bucket, new classes minted on demand), family, size,
   noseLocalAxis (family axis), mirror pairs share one schema
   (`prefab`/`mirroredPrefab`/`mirrorPlacement` — R mesh in `prefab`, confirmed in
   builder), providedSockets from any `WPN_/WTUR_/ENG_/THR_/SEN_/MSL_` markers present +
   class defaults, and **auto-derived stats and costs** (§4).
5. **Report**: one summary table per ship (part, tris, volume, mass, bill, flags) so the
   whole ship gets eyeballed once instead of asset-by-asset.

Socket markers stay a light hand pass after ingest (raycast-placement method from the
turret-sockets work) — heuristics place engines/thrusters markers at mesh centers where
the class implies them; weapon hardpoints remain Aaron's call.

## 4. Stage 3 — Auto-costing: size + material → mass → resources (new)

**Doctrine:** authored values always win; everything else derives from geometry so a new
ship costs nothing to stat. Derived values are stamped `autoCosted = true` so the balance
pass can find and freeze them later.

**Material table** (new small asset/JSON, `ShipIntake/material_table.json`) — one row per
hull material, mapping to the existing composite-ore roster:

| hullMaterial | density (t/m³ solid) | solidity | material mix (per ton) |
|---|---|---|---|
| steel_standard | 7.8 | 0.18 | 0.80 iron · 0.15 carbon · 0.05 nickel |
| titan_light | 4.5 | 0.16 | 0.60 titanium · 0.30 iron · 0.10 silicates |
| composite_heavy | 5.9 | 0.22 | 0.50 iron · 0.25 tungsten · 0.25 carbon |

(Solidity = how much of the closed volume is actually structure vs interior space;
starting values, tune per class.)

**Per part, at ingest:**

- `volume` = signed tetrahedron sum over the (watertight) mesh — exact, cheap, and the
  reason Stage 1 insists on 0 open edges.
- `massKg = volume × density × solidity` — sanity-anchored so the Corsair engine pod
  (~1,800 kg authored) round-trips within ~2×; a global `familyMassCalibration` scalar in
  the manifest absorbs donor-scale weirdness.
- `structureHealth = classBase × (massKg / classRefMass)^0.8` (sub-linear — big parts are
  tough but not invincible); `armorRating` from class default (hull 0.30, wing 0.45,
  engine 0.18 — the Corsair values become the defaults table).
- `buildCost` (materials, tons) = `massKg` split by the material mix — **this is "the
  resources needed to build based on size and materials."**
- `componentCost` = existing `ComponentBillFor` class/mass rule (frames+plating scaled by
  mass, coils for engines, etc.) — unchanged, now fed by derived mass. Crucible discovery
  combos therefore keep working automatically (component bill IS the recipe).
- `radarCrossSection` from projected silhouette area; `powerDrawMW` class default.

Net effect: the **ship's total build bill is the sum of its parts' derived bills** — a
bigger ship in a heavier material is automatically more expensive, with zero hand
authoring, and the whole economy (fabrication, crucible, market) picks it up through the
existing stores untouched.

## 5. Stage 4 — Factory Spec blueprint (new, and the verification step)

Because every part keeps ship-root origin, instantiating all of a ship's parts at local
zero reassembles the donor exactly. The ingest run finishes by doing exactly that and
saving it as a real `ShipBlueprint` named **"<DisplayName> — Factory Spec"**:

- Frame parts placed as geometry; socketed positions (engines/thrusters/weapons) recorded
  as **slot positions** per the frame+slots canon — the Factory Spec ships with EMPTY
  slots like any schematic; fittings are the player's business.
- The reassembly render (top-down + iso capture) goes in the ingest report — **if the
  Factory Spec doesn't look like the donor ship, the cut or an axis is wrong and it's
  caught same-day**, not three weeks later in a thumbnail.
- The Factory Spec blueprint is ordinary discoverable knowledge (starter kits, crucible,
  RE of salvaged parts) — no special store, no new persistence.

## 6. The Factory-Complete bonus (new)

**Design intent (Aaron):** a ship built the way its designer meant is more than the sum
of its parts. All canonical parts, in factory positions → the ship gets a bonus. Add,
move, or remove a frame part → the ship still flies, but the bonus is gone.

**Rule — "exact hull layout, fittings free" (decided 2026-08-03):**

- The check covers the **FRAME**: the multiset of structural part IDs and their
  positions/rotations, compared against the Factory Spec within epsilon
  (pos 0.25 u, rot 2°). Mirror-pair twins match by their mirrored transform.
- **Fittings never affect it**: whatever is plugged into sockets/slots — weapons,
  engines-in-slots, reactor, battery, internal bays — can be swapped freely at the yard.
  The bonus is about the airframe, and it composes cleanly with the frame+slots model:
  *blueprint tier = bonus-relevant, slot tier = free*.
- **Grades never affect it** — an all-F-grade factory build still qualifies (grades
  already carry their own reward through derived stats).
- Extra frame parts, missing frame parts, or moved frame parts (beyond epsilon) all
  break it. Rebuilding back to spec at the yard restores it — nothing is permanent.

**Data:** no new store. The Factory Spec blueprint already IS the canonical layout; a
tiny `FactorySpecRegistry` (Resources asset, one entry per shipId → blueprint checksum +
bonus block from the manifest) makes the lookup cheap and server-verifiable.

**Application — derived at spawn, never stored (schema-driven doctrine):**

- `NpcShipSpawner.Spawn` (the one canonical assembler), after `DeriveFlightStatsFromParts`
  / `DerivePowerFromParts`: run the frame match; on success apply the multipliers —
  default **+10% weapon damage, +10% structure & armor effectiveness, −10% effective
  mass** (accel/turn improve through the existing thrust/mass math — no new flight code),
  per-ship overrides from the manifest. The record itself stores nothing; a modified
  ship re-derives with no bonus automatically. Server-authority-friendly for the same
  reason: the check is deterministic from record + schema, CloudScript can re-run it.
- **UI:** shipyard header + fleet cards show a `✦ FACTORY SPEC` badge while the frame
  matches, with the delta preview flipping live during refit ("moving this wing forfeits
  Factory Spec: −10% ATK/DEF, +10% mass"). No silent loss — the player always chooses.

**Balance note:** 10/10/10 is deliberately "meaningful but beatable" — a good custom
build with better parts should still out-fly a factory ship; the bonus rewards the
lore-authentic silhouette, it does not make custom design a trap. Role-flavored bonuses
(smuggler = +evasion/−RCS instead of +ATK) stay on the table as a v2 — the manifest block
already supports arbitrary percentages.

## 7. Onboarding many ships — the batch checklist

Per donor ship, in order (☐ = per-ship checklist row in `master_to_do`):

1. ☐ Write manifest (5 min — identity, material, nose axis TBC).
2. ☐ Blender session: explode + color, Aaron cuts N parts (the long pole, human-paced).
3. ☐ Ingest run: prefabs + colliders + schemas + auto-costs + report table.
4. ☐ Review report: masses/bills sane, no collider flags, mirror pairs verified in
   builder (X-flip check), nose axis confirmed → write into schema.
5. ☐ Factory Spec blueprint auto-saved; visual match vs donor confirmed.
6. ☐ Socket pass: weapon/turret hardpoints placed with Aaron.
7. ☐ Registry entry + bonus block → Factory-Complete live for that ship.
8. ☐ Discovery seeding decision (starter kit family? crucible-only? boss salvage?).

Steps 3, 5, 7 are fully scripted; 1, 4, 6, 8 are minutes; 2 is Aaron's eye and stays
that way on purpose — heuristic auto-cutting was tried and retired ("it grouped pieces
wrong").

## 8. Open questions for review

1. **Material table starting rows** — the three above are placeholders; which hull
   materials do the incoming FBX ships actually represent, and do families map 1:1 to a
   material or per-ship?
2. **Solidity + calibration constants** — propose calibrating once against the Corsair
   and SM8 authored values, then freezing.
3. **Convex collider budget** — one convex hull per part is the plan; capital-class
   parts may want 2–3 hull decomposition later (defer until a ship needs it?).
4. **Epsilon for the frame match** (0.25 u / 2°) — tight enough to stop "nudged wing
   still counts", loose enough for float noise. Tune in play.
5. **Does Factory-Complete show on enemy ships?** (Presence fleets fly real builds —
   an attacker seeing `✦` on a foreign corvette is nice intel. Recommend yes.)
6. **Re-axing new cuts to nose=+Z** — confirm we adopt it for all NEW ships (old
   Y-long hulls stay as-is until a dedicated repair pass).

## See also

- `ships/ships_part_identification_process.md` — the cut workflow this wraps
- `ships/ships_construction_pipeline.md` — costing/economy chain the auto-costs feed
- `ships/ships_blueprint_slot_model.md` — frame+slots split the bonus rule rides on
- `pipelines/pipeline_ship.md` — derive-at-spawn runtime the bonus hooks into
