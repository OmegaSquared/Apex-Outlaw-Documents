---
status: in-build (MVP slice 1)
phase: ship-building
last-reviewed: 2026-06-10
---

# Ship Manufacturing — Parts, Sockets, Builder

> **Locked decisions (Aaron, 2026-06-09):**
> - Ships are manufactured by combining **large structural parts** ("a wing with an engine on it"), socketed together — same philosophy as ground-base tiles, bigger chunks.
> - **Pre-built hulls** (market/starter ships like the Smuggler Frigate) stay monolithic — one mesh + fitting sockets. **Manufactured ships** are assembled from parts.
> - Builds **start with a hull** (midframe). Other part classes are locked until one is placed.
> - Builds must satisfy **minimum-viability rules** — e.g. ≥1 engine, ≥6 side thrusters. Rules are data-driven (`ShipBuildRules` asset), not hardcoded.
> - The frigate stays **Medium** (per `hull_smuggler_frigate_mk1` canon). Size buckets for parts: `Prefabs/ShipParts/Small|Medium/`.

## 1. Part taxonomy (MVP)

Every donor ship from SF_Vol17 is cut into the same anatomy (Blender chunker; sources + .blend per ship under `Art_Assets/ShipParts/<Ship>/`):

| Part class | Source chunk | Provides (MVP socket counts) |
|---|---|---|
| **Cockpit** | Nose | 2× front thruster |
| **Midframe** | HullCore | 4× side thruster, 2× utility, **1× power core (the ship's single energy slot)** — **the build anchor; placed first; defines the ship's size class** |
| **DriveSection** | Stern | 4× engine, 2× side thruster |
| **Wing** | Wing_R (+ mirrored Wing_L) | 1× engine, 2× side thruster, 1× weapon |
| **WeaponMount** | Fighter wing gun pods | 2× weapon (fixed forward) |
| **Turret** | Frigate's bundled plasma turret | 1× weapon (traversing) |
| **SensorArray** | Frigate antenna fins | 1× sensor + intrinsic `sensorRadius` (FOW canon) |
| **CargoPod** | Ambiguous chunks ("can't tell what it's for → extra cargo") | `cargoCapacityKg` |
| **CrateRail** | Hauler clamp arms — canon **Crate-Push Rail** (`ships_weapons_armaments.md` §D) | `crateCapacity` external crates |

**Energy cap doctrine (Aaron, 2026-06-09):** the midframe provides exactly one power-core slot. Part-count rules stay deliberately loose — the assembled ship's summed `powerDrawMW` against the fitted core's output is the real build limiter (enforced when the fitting pass lands).

**Free combination (Aaron, 2026-06-09, supersedes size gating):** ALL parts combine — fighter pods on a frigate hull, whatever. "The game will balance itself" via the power budget. `ShipBuildRules.enforceHullSizeMatch` (default OFF) can restore strict matching if playtesting demands it.

**Permissive placement (Aaron, 2026-06-09):** parts can be PLACED anywhere — buried, floating, mid-edit chaos is fine. Geometry validity (every part attached via the snap-point rule, none buried past the overlap cap) is checked ONCE, as ASSEMBLE-gate checklist rows, not during placement. Hologram colors during drag are advisory.

**Starting roster (Aaron, 2026-06-09):** `ShipBuildRules.enabledFamilies = [bomber, fighter, smuggler]` — the builder launches with three donor families; add families to the list to grow the catalog, no code changes.

**Hand-cut parts workflow (Aaron, 2026-06-09, supersedes heuristic chunking):** Aaron selects islands in the shared Blender session and names the part; the assistant joins → names → cap-fills → exports FBX → bakes the Unity prefab → removes it from the working blend so remaining pieces stay easy to pick. The position-heuristic cuts were a scaffold; every ship gets the hand-cut treatment as it's reviewed.

**Bomber canon (first hand-cut ship, 2026-06-09):** 9 parts → 6 schemas: Hull (Midframe — **cockpit included: small ships have no cockpit part; bridges arrive with capital chassis**, so the Cockpit rule is now 0–1), Wing (pair), Plasma Cannon (WeaponMount pair), Engine Pod (new **EnginePod** class, pair), Rear Engine (EnginePod single), Missile Launcher (new **MissileLauncher** class with **Missile** fitting sockets).

**Direction note (Aaron, 2026-06-09):** ~~Shipyard (fitting) + Ship Builder likely merge into ONE build mode~~ — **SUPERSEDED 2026-07-02** by `ships_construction_pipeline.md`: they stay separate stages. The builder scene is renamed **`BlueprintDesign`** (pure geometry → blueprint/BOM); the **Construction Lab** (`ConstructionLab` scene) forges discovered designs + graded materials into mountable graded part instances; the **Shipyard** assembles blueprint + graded parts into the ship record.

**Part rotation rules (Aaron, 2026-06-09):** amber knob handles on the gizmo — side knobs = yaw, top knob = pitch. **Engines (EnginePod) are yaw-only** (no pitch knob): thrust always points rearward. Mirror pairs: **yaw mirrors on the twin, pitch applies uniformly** (matches the actual mirror math: reflection across the centerline negates yaw/roll, preserves pitch). Ctrl = 15° steps; rotations preview on the hologram and commit on release; undo restores pose.

One **Wing schema per family** — it fits either side; the builder mirrors the mesh for the left mount (decision from the frigate naming pass).

### Per-part statistics (Aaron, 2026-06-09)

Every part schema carries a combat/ops stat block: `structureHealth` (hp contributed), `armorRating` (0–1, ship armor = health-weighted average), `powerDrawMW` (consumed from the fitted power core — total draw vs core output is enforced when the fitting pass lands), `radarCrossSection` (m² eq, feeds the FOW signature model), `massKg`. Baselines are authored per class and scaled ×3 for Medium parts. The builder's right panel shows the selected part's stats, or SHIP TOTALS when nothing / everything is selected.

### Mesh capping

Chunk cuts leave open boundary faces. Every part is hole-filled in Blender (boundary-loop fill) with a shared **`PartCap_Black`** material (near-black metal — swap an electrical-panel texture into `Art_Assets/ShipParts/PartCap_Black.mat` to retheme every cap at once). Re-run the fill pass after any re-cut.

Donor families (size bucket): SM5 Fighter (S), SM8 Bomber (S), SM4 Smuggler Frigate (M), SM3 Transporter (M), SM7 Destroyer (M), SM6 CargoShip (M).

## 2. Geometry / assembly model (MVP — important simplification)

Every part keeps the **donor ship-root origin**, so same-family parts placed at local zero reassemble the donor exactly. Cross-family kitbash is allowed but will visually overlap — **acceptable for slice 1**; real per-socket attach transforms (`PartSocket { localPos, localRot, allowedClass }`) are the slice-2 upgrade and the schema is shaped to receive them.

### Placement interaction (locked 2026-06-09)

- **Mirror pairs ("parallel")** — `ShipPartSchema.mirrorPlacement` parts (wings) place as a linked L/R pair; dragging either keeps the pair symmetric. One palette click = both wings.
- **Magnetic drag + flush seating (v3, Aaron 2026-06-10: "no gaps — actually attached")** — each part has ONE snap face (largest cap patch, mint glow). The magnet raycasts along the snap face's own normal and pulls the part so the face lands FLUSH on the surface it points at; on release any remaining gap closes automatically (snap click). Shift/Ctrl precision drags bypass the auto-seat. Snap reach is 3× `attachToleranceM` — "really close" counts as attached. Capless parts fall back to the generic nearest-geometry magnet.
- **Snap rule — THE EDGE RULE (Aaron 2026-06-10, final form after three stricter attempts):** "if this edge is past this edge — snap." A part is attached when its padded **snap-face bounding box** (the largest capped cut surface, mint glow; whole-part box when capless; pad = max(2×`attachToleranceM`, 10% of part radius)) **crosses any other attached part's bounding box**. That's the whole test — no mesh sampling, no probes. The mint face also drives the **directed magnet** (pull along the face normal to flush contact) and the **auto-seat on release** (closes remaining gaps, part-scaled reach, Shift/Ctrl bypasses), so permissive attachment still LOOKS flush. Any blue part is a valid target; validity **chains outward from the hull** (a part touching only a floating part stays red). Interpenetration is legal kitbashing. Turrets chain only through TurretMounts. Lesson recorded: precise mesh-geometry attachment tests (vertex proximity / coverage rays) repeatedly read as "broken" in playtests — generous box tests + visual seating beat clever geometry.
- **The midframe is the anchor** — it cannot be dragged; everything moves relative to it.
- **Camera** — opens nose-toward-player (nose axis measured from cockpit geometry); drag empty space orbits. **Shift+A** selects all parts and dragging then rotates the entire ship.
- Click part (3D or manifest row) → emission highlight; click empty space → clear.

## 3. Rules (`ShipBuildRules` asset)

Two rule kinds, both data-driven:
- **Part-class counts** — exactly 1 Midframe, exactly 1 Cockpit, exactly 1 DriveSection, 0–2 Wings (MVP defaults).
- **Provided-socket minimums** — ≥1 engine socket, ≥6 side-thruster sockets (Aaron's examples; tune in the asset).

The builder shows a live checklist; ASSEMBLE enables only when all rules pass.

## 4. What assembly produces

**The studio produces blueprints, not ships (Aaron 2026-06-10: "this is the research, not the building process").** SAVE BLUEPRINT (gated on the rules checklist) serializes the layout to a `ShipBlueprint` (`Macro/Fleet/ShipBlueprint.cs`) — local JSON under `persistentDataPath/blueprints/` + PlayFab user data (`bp_<id>`) when logged in. Same name = revision. Blueprints load back into the studio for iteration (mirror twins re-linked on load). **BRIDGE:** the fabricator/Drydock BUILD flow compiles a blueprint into a `ShipInstance` (hardpoints = union of provided sockets) behind the Light Shipyard facility + material costs (`ground_base_build_order.md` spine) — see §5.

## 5. Blueprints & the manufactured-ship economy (locked, Aaron 2026-06-10)

**Two modes, two places (locked 2026-06-10):**

- **Design mode — research facility, holographic.** The entire ship renders as
  hologram (the builder's ghost tech becomes the only render mode here). Design
  is pure information: free, no materials consumed, unlimited iteration. Output:
  a saved ship blueprint. This resolves the "where did the dragged part come
  from?" question — it was never matter. **Hologram color language (Aaron
  2026-06-10): BLUE = part fits (touching or inside the hull/another blue part,
  chained from the hull, re-evaluated every refresh), RED = doesn't fit,
  YELLOW-ORANGE = the part being moved.** Selection
  brightens the state color. A **VIEW FINAL PRODUCT** toggle swaps in the real
  prefab materials — visuals only, editing paused, never a production path. The
  scene is titled **BLUEPRINT DESIGN**.
- **Build mode — fabricator / Drydock, resource-based.** Load a blueprint → the
  ship appears as a faint full-size holo shell in the yard → each part is
  fabricated from materials (`ShipPartSchema.buildCost`) or pulled from
  inventory, and drones replace its hologram with the real mesh. Half-built
  ships are visibly half-solid. The Shipyard fitting UI merges here (build
  mode), while design mode lives at the research facility.

**Part blueprints are discoverable (locked 2026-06-10).** Every part is a
blueprint the player must DISCOVER — players start with zero (the starter
frigate is a monolithic pre-built hull, so day one you fly but can't design).
Primary discovery path: the **tech tree** (research facility, alongside alchemy
unlocks — `economy_alchemy_tech_tree.md`; matches economy canon "Researchers
find Blueprints but need raw materials"). Second path: **salvage + reverse
engineering** (below). The design palette shows ONLY discovered parts (palette
filter next to the existing family-roster gate in `BuildPalette()`).

### Salvage → reverse engineering (locked, Aaron 2026-06-10)

Destroyed ships drop **parts as physical salvage**. Cargo space forces the
choice — you can't haul the wreck, you pick the part worth knowing ("a new
turret you've never seen before"). At the research facility, an unknown part can
be **reverse engineered into its part blueprint** — and **RE consumes the
part**: keep the one rare turret you may never replace, or destroy it to learn
to make infinite copies. That tension is the mechanic. This gives pirates and
combat players a first-class seat in the manufacturing economy: kills are
research material, and "what do they have fitted?" is a reason to pick fights.

### Parts ARE the blueprint market (locked, Aaron 2026-07-14)

Blueprints stay **personal and non-tradable** — that rule survives. What trades
is **physical parts**, and reverse engineering is how information changes
hands: buy any part on the market, take it to the crucible, **destroy it to
learn its blueprint** — the same RE mechanic as salvage, one rule for both.
"Selling a blueprint" therefore means selling a part the buyer intends to
destroy. This supersedes the blueprint For-Sale / blueprint-market phases in
`shipyard_build_pipeline_plan.md` (Phase 4–5) — there is no blueprint catalog;
the parts market carries the information economy.

Consequences, all intended:

- **Learning self-prices.** A top-tier weapon costs top-tier money, and
  learning it costs the weapon. No separate blueprint pricing to balance.
- **The reveal is post-destruction.** The buyer learns how many of the
  blueprint's materials they haven't discovered only AFTER the part is
  consumed — a **count only, never names** (blind-tech-tree rule). Buying a
  part to RE is a gamble; that's the mechanic.
- **Selling parts leaks tech, quality doesn't leak.** The per-account alchemy
  seed is the firewall: a buyer who REs your cannon learns WHAT to build, but
  their copies roll grades on their own matrix, ceilinged by their own
  Best-Found materials. Researchers sell performance; the secrets protect
  themselves.

### Maker's Mark vs reverse engineering (locked, Aaron 2026-07-14)

The Maker's Mark is a **seed-bound seal on the part INSTANCE** (it already
carries forger identity + integrity checksum — the mark is the player-facing
face of that cryptography). Rules:

- **Marked + intact** (bought, traded, stolen intact off a wreck): the crucible
  **refuses** it — no RE, the part is not consumed. Signing your work protects
  your catalog through every peaceful or larcenous transfer. (The existing
  "Golden Logic" repair-recipe rule is unchanged — maintenance knowledge never
  unlocks manufacturing.)
- **Unmarked**: standard RE — one part destroyed = blueprint learned. Selling
  unsigned work IS selling a license; unmarked top-tier parts price accordingly
  (intentional: two market tiers — marked = product market, unmarked = license
  market at a steep premium).
- **Marked + combat-severed** (shot off in battle): violence DAMAGES the seal
  rather than removing it — the part is RE-able but **lossy**: one blueprint
  requires **FIVE severed samples of the same design** (locked, Aaron
  2026-07-14), each sample consumed per attempt, the blueprint assembling on
  the fifth (dormant as usual if materials are missing). Rationale: keeps
  "kills are research material" alive for marked gear; makes staged-fight
  laundering cost more than an honest unmarked license; turns cracking a famous
  crafter's catalog into a sustained piracy CAMPAIGN against their customers —
  tech secrecy is defended in space, not by a database flag.

Because the mark lives on part instances, a "marked ship" is just a ship of
marked parts — mixed builds behave per-part. "Buy the ship, learn the
shipwright's catalog" (intended, Aaron 2026-07-14) therefore applies only to
UNMARKED ships, which is what makes them extremely valuable.

### Dormant blueprints (locked, Aaron 2026-07-14)

A learned blueprint with undiscovered materials is **not lost and not
relearned** — it sits **dormant** in the blueprint library, showing the count
of missing materials (masked entries, per "material unknown" below). The moment
the last required material is discovered in the research tree, the blueprint
**auto-completes to discovered/buildable** — no second RE, no re-purchase.
Learning and building are separate gates: RE grants the knowledge permanently;
material discovery unlocks the fabrication.

### "Material unknown" (locked, Aaron 2026-06-10)

A blueprint's build recipe (`buildCost`) may require materials the player hasn't
unlocked in the research tree. Those entries render as **"material unknown"** —
name and icon masked — and the part CANNOT be built until every input material
is unlocked. A reverse-engineered blueprint is a *map fragment*: it proves
something exists in the tech tree worth hunting without saying what.
Implementation is cheap — `buildCost` already lists the materials; the UI masks
any entry missing from the player's unlock flags.

### Blueprint upgrading (locked, Aaron 2026-06-10)

Known blueprints are **upgradable** by combining them with an unlocked material
at the research facility (e.g. steel turret + carbon composite → composite
turret):

- **Attempt gate:** input material must meet a **per-schema quality grade
  threshold** (alchemy letter grades — a hull tolerates B-grade, a precision
  sensor demands A+). Authored on the schema, variable per part.
- **Success roll:** meeting the threshold lets you TRY; the actual grade scales
  the success chance — quality matters twice.
- **Failure:** consumes the materials, **never harms the blueprint**. A material
  sink that makes high-grade inputs precious without losing designs.
- **Success:** unlocks the upgraded blueprint variant.
- **Data model — no schema explosion:** an upgraded blueprint is the base part
  + a **material substitution record** (`{basePartID, fromMaterial, toMaterial}`);
  stats derive from the substituted material's properties (mass, strength, power
  draw). One rule, every part upgradable, zero hand-authored Mk2 schemas.

**Ship blueprints are personal and non-tradable.** ASSEMBLE serializes the layout
to a small blueprint record — `{ blueprintID, name, author, parts[{partID,
localPos, localRot, mirrored}], checksum }` — saved to the player's PlayFab data
like a loadout. Blueprints never appear on the market. A shipwright's designs are
trade secrets: the only way to fly someone else's layout is to buy a ship they
built. Designs become reputation and recurring business, not a one-time
information sale.

**The market trades matter, not information.** Sellable goods are exactly two
tiers, both flowing through the existing exchange (`economy_exchange_pricing.md`):

- **Parts** — fabricated from materials per `ShipPartSchema.buildCost`. Part
  quality inherits from input material quality (alchemy canon: the 0–12345
  quality lerp + parent-quality ceiling, `economy_alchemy_research.md`).
- **Complete ships** — assembled from parts against a blueprint.

**Ship value = layout × material quality × build facility.** Scarcity comes from
execution, not the design: high-grade inputs are genuinely rare (parent-quality
ceiling), facilities are finite capital someone built and defends, and build
timers make yard capacity a queue. Two ships off the same blueprint can be worlds
apart — commodity builds sell near cost; peak-matrix builds command premiums.

**Build sites by size bucket:**

| Bucket | Facility | Status |
|---|---|---|
| Small | Light Shipyard / fabricator, ground base | T1 win condition (`ground_base_build_order.md` spine) |
| Medium | **Orbital Drydock**, in space | future structure, gated behind Light Shipyard |
| Large | **Capital Construction Yard**, in space | later — pairs with Frigate Hangar tier |

Naming note: the ground-base bootstrap module is already called Construction
Yard — space facilities use the names above to avoid collision.

**Server authority:** CloudScript re-validates the blueprint (class rules, socket
minimums, checksum) on every build — matches the existing per-player-instance
pattern (`architecture_plan.md` §4); clients cannot forge stat'd ships.

**Back pocket (not MVP, don't design it out): reverse engineering.** Tow a
captured/purchased ship into your yard, spend research + time, recover an
approximate blueprint. Gives pirates and salvagers a path into manufacturing and
makes design leakage a gameplay event. Nothing in the model above blocks it.

**Visual freebie:** the blueprint stores every part transform, so orbital builds
can assemble visibly part-by-part — drones placing the actual prefabs in layout
order.

Slice order: **(A)** ✅ SAVE BLUEPRINT → blueprint JSON local + PlayFab, LOAD back
into the studio (2026-06-10) → **(A2)** ✅ BUILD SHIP [DEV] (2026-06-10):
`ShipBlueprintCompiler` turns a blueprint into a real `ShipInstance`
(hullID `bp:<blueprintID>`) in the fleet dry-dock; `TacticalFleetLoader`
recognises the prefix, spawns the frigate FLIGHT BASE (TacticalFlightEngine +
Fusion + thruster sockets), strips its meshes, and dresses it with the
blueprint's parts at their designed transforms — manufactured ships FLY.
BRIDGEs: fallback loadout (no socket→hardpoint compile yet), base-hull hitboxes,
frigate flight physics regardless of design → **(B)** material costs + build
timer + size gate + discovered-parts palette filter + per-part mass/thrust into
the physics matrix → **(C)** part/ship listings on the exchange + tech-tree
discovery hookup + "material unknown" masking → **(D)** Orbital Drydock + drone
build visuals → **(E)** part salvage drops + reverse engineering + blueprint
upgrading.

## 6. Code map

- `Schemas/ShipPartSchema.cs`, `Schemas/ShipBuildRules.cs` — data.
- `Macro/Fleet/ShipPartCatalog.cs` — discovery (BeaconCatalog pattern).
- `Macro/Fleet/ShipBlueprint.cs` — blueprint record + store (local JSON + PlayFab sync).
- `UI/ShipBuilderController.cs` + `Resources/UI/ShipBuilder/` — the DESIGN STUDIO scene (holographic).
- Scene: `Assets/Scenes/ShipBuilder.unity`; entry: nav Shipyard chip → ENTER SHIP BUILDER.
