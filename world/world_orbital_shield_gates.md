---
status: active
phase: 6.9
last-reviewed: 2026-06-21
supersedes: []
---

# Orbital Shield Gates — Canon Design & Authoring Pipeline

> The orbital shield gate is the **alliance-controlled objective that grants control of a
> planet**. It is a registry-driven [orbital structure](world_low_orbit_scene.md#data-model)
> of the dedicated type [`CelestialChildType.OrbitalShieldGate`](../../Assets/Scripts/Schemas/Celestial/CelestialChildType.cs).
> This doc replaces the scene-authored gate BRIDGE noted in
> [`world_low_orbit_scene.md`](world_low_orbit_scene.md) (the ring station seated in the
> shield aperture).

## Concept

Every shield-bearing planet hosts one or more **orbital shield gates** — ring stations that
sit in the planetary shield's aperture and gate descent to the surface. Whoever holds a
planet's gates controls the planet. Gates are an **alliance objective** (a faction IS an
alliance — see [`world_story_lore.md`](world_story_lore.md) §3, so "owner" is always a
single `ownerId`: `"FED"` / `"ICE"` / an alliance UUID / empty).

A planet's **gate capacity** is declared on its schema; alliances decide **where** each gate
goes (its lat/long). A gate exists in two ways:

1. **Alliance-built** — an alliance constructs a gate at a chosen lat/long, up to the
   planet's slot cap. `source = AllianceBuilt`, owned by `ownerAllianceId`.
2. **Pre-existing / conquerable** — a gate is seeded on the planet (`source = Static`) with
   defenses; it is captured by **defeating its defenses** in combat, which flips `ownerId`
   to the victor's alliance. Same attack pattern as `SurfaceBase` / `DefenseStation`.

## The sync guarantee (why this exists)

Each planet has two player-facing scenes — the **Low Orbit** scene
([`world_low_orbit_scene.md`](world_low_orbit_scene.md), e.g. `Planet_01_orbit.unity`) and
the **Surface** scene ([`world_surface_scene.md`](world_surface_scene.md), e.g.
`Planet_01_surface.unity`). A gate must appear in **both**, at the **same lat/long**, with
the **same count**.

This is guaranteed structurally: **one registry record → two presentations.** Both scenes
carry a `PlanetGateSpawner` that reads the *same* `OrbitalShieldGate` children of the planet
from `CelestialRegistry` and instantiates a gate per record. Because both scenes read the
identical records:

- **Count** matches — both spawn exactly the registry's gate records.
- **Lat/long** matches — both read `orbitLatitude` / `orbitLongitude` off the record.
- **Nav (lat/long readout)** matches — the nav HUD derives lat/long from the same
  `PlanetSurfaceCoordinates` frame both scenes use.

The only difference between the two presentations is **radius**:

- **Low Orbit:** lat/long lifted to `orbitAltitude` (the planetary-shield radius — the gate
  sits in the shield aperture).
- **Surface:** the *same* lat/long projected to the planet's surface radius (the gate's
  ground footprint / descent point directly below the orbital ring).

There is no second source of truth, so the scenes cannot drift. **No scene-baked gates** —
this replaces the four hand-placed surface gates + the single hand-placed orbit gate that
existed before this system (removed in the migration; see Bridges).

## Data model

Schema lives in [`CelestialRegistry.cs`](../../Assets/Scripts/Schemas/Celestial/CelestialRegistry.cs)
and [`CelestialChildType.cs`](../../Assets/Scripts/Schemas/Celestial/CelestialChildType.cs).

**Planet capacity** — `CelestialParentRecord`:

| Field | Meaning |
|---|---|
| `orbitalGateSlots` (int) | Max gates this planet supports. `0` = no gate objective (star, moons, lore-locked bodies). The schema declares the cap; alliances choose placement up to it. |

**Per-gate record** — `CelestialChildRecord` with `type = OrbitalShieldGate`:

| Field | Meaning |
|---|---|
| `orbitLatitude` / `orbitLongitude` | Where the gate sits on the host sphere (authored once; used by BOTH scenes). |
| `orbitAltitude` | Radius the orbital ring rides at (the shield radius, e.g. 110,000 for Planet_01). |
| `ownerId` | Controlling owner — `"FED"` / `"ICE"` / alliance UUID / empty (inherit planet baseline). |
| `ownerAllianceId` | Alliance that built it (alliance-built only). |
| `source` | `Static` (seeded, conquerable) or `AllianceBuilt`. |
| `defenseMaxHp` / `defenseCurrentHp` | The defenses to defeat for capture. `0` HP ⇒ undefended / captured. |
| `isOnline` | Operational state (green/gray). Flipped by CloudScript on destruction / repair. |
| `displayName` | e.g. "Concordia North Gate". |

Reusing the existing `ownerId` / `source` / defense fields keeps gates on the same
ownership + combat plumbing as `SurfaceBase` and `DefenseStation` — no parallel system.

## Runtime — spawn & sync

`PlanetGateSpawner` (MonoBehaviour, one per planet-entry scene) mirrors the existing
[`PlanetSurfaceBaseSpawner`](../../Assets/Scripts/Macro/PlanetSurfaceBaseSpawner.cs) pattern:

- Carries `planetId` and a `SceneKind { LowOrbit, Surface }`.
- Subscribes to `CelestialRegistryClient.OnRegistryUpdated`; calls `Apply()` on update.
- `Apply()` enumerates `registry.ChildrenOf(planetId)`, filters
  `type == OrbitalShieldGate`, and spawns/updates one gate per record (idempotent dict keyed
  by record id), despawning records that disappeared.
- Placement: direction from `PlanetSurfaceCoordinates.DirectionFromLatLon(orbitLatitude,
  orbitLongitude, poleAxis, primeMeridian)`; multiply by `orbitAltitude` (LowOrbit) or the
  surface radius (Surface).
- Re-applies live on any registry change (build / demolish / capture flips owner / HP), so
  both scenes reflect authoritative PlayFab state without a reload.

The gate visual is the existing `RoundSpaceStation` ring prefab
(`Assets/Art_Assets/RoundSpaceStation/`), and the shield aperture is sized to the ring via
the shared `PlanetShield.mat` `_ApertureDir` / `_ApertureCos` (one shared material across
both scenes — see [`world_low_orbit_scene.md`](world_low_orbit_scene.md)). With multiple
gates the shield needs one aperture per gate (see Open questions).

## Two creation paths

### Alliance-built
`BuildOrbitalStructure({ playerId, bodyId, type: OrbitalShieldGate, latitude, longitude,
altitude })` CloudScript (planned in [`world_low_orbit_scene.md`](world_low_orbit_scene.md)
§CloudScript) — server-authoritative:

1. Verify the alliance controls / is permitted on `bodyId`.
2. Verify gate count `< orbitalGateSlots`.
3. Verify min great-circle spacing from existing gates (reuse the `SurfaceBase`
   `MIN_SLOT_SPACING_DEG` rule).
4. Append an `OrbitalShieldGate` `CelestialChildRecord` (`source = AllianceBuilt`,
   `ownerAllianceId`, `ownerId`, `defenseMaxHp`). Registry update → both scenes spawn it.

### Pre-existing / conquerable
Seeded in `seed.json` (`source = Static`) with `defenseMaxHp` and a starting `ownerId`
(or empty / `FED` / `ICE`). Capture = defeat the gate's defenses; CloudScript flips `ownerId`
to the victor and resets `defenseCurrentHp`. This rides the **Phase 4** combat path — until
combat lands, the capture flip is bridged (admin/dev action), not earned in a fight.

## Authoring a planet's gates (pipeline)

1. **Set capacity** — on the planet's `CelestialParentRecord` in
   [`seed.json`](../../Assets/GameData/Celestial/seed.json), set `orbitalGateSlots` to the
   number of gates the planet supports.
2. **Seed pre-existing gates (optional)** — add `OrbitalShieldGate` child records with
   `orbitLatitude` / `orbitLongitude` / `orbitAltitude`, `source: Static`, `defenseMaxHp`,
   and `ownerId`.
3. **Leave the rest to alliances** — remaining slots are filled in-game via
   `BuildOrbitalStructure`.
4. **Nothing in the scene** — do NOT place gate GameObjects in `*_orbit.unity` /
   `*_surface.unity`. The `PlanetGateSpawner` in each scene instantiates them from the
   registry. (Per CLAUDE.md live-data rule.)

## Bridges (remove when the gated phase lands)

- **Combat capture (Phase 4).** Capturing a Static gate by defeating defenses can't resolve
  in a real fight yet. `// BRIDGE: remove when Phase 4 combat lands` on the capture path;
  flips happen via admin/dev tooling until then.
- **`BuildOrbitalStructure` CloudScript.** Until the handler ships, alliance-built gates are
  created via the local/admin seed path. `// BRIDGE: remove when BuildOrbitalStructure lands`.
- **Hand-baked scene gates removed.** The 4 surface + 1 orbit hand-placed gates are deleted
  in this migration; the spawner is the only source. (Was the scene-authored gate BRIDGE in
  [`world_low_orbit_scene.md`](world_low_orbit_scene.md).)

All tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md) "Bridge code to remove".

## Open questions

- **Multiple shield apertures.** `PlanetShield.shader` currently cuts ONE aperture
  (`_ApertureDir`). N gates need N apertures — either an aperture array in the shader or a
  per-gate local shield patch. Resolve before authoring planets with `orbitalGateSlots > 1`.
- **Surface footprint visual.** What the gate looks like on the ground in the Surface scene
  (descent pad? shield-down emitter?) vs. the orbital ring above.

## See also

- [`world_low_orbit_scene.md`](world_low_orbit_scene.md) — Scene 2; orbital structures, shield, gate BRIDGE this supersedes
- [`world_surface_scene.md`](world_surface_scene.md) — Scene 3; surface placement
- [[world_surface_navigation]] — shared lat/long nav HUD both scenes carry
- [`world_story_lore.md`](world_story_lore.md) §3 — faction = alliance ownership canon
- [`../architecture/architecture_plan.md`](../architecture/architecture_plan.md) §1.5 — registry-driven bodies & POIs
- [`PlanetSurfaceCoordinates.cs`](../../Assets/Scripts/Macro/PlanetSurfaceCoordinates.cs) — lat/long ↔ world frame
- [`PlanetSurfaceBaseSpawner.cs`](../../Assets/Scripts/Macro/PlanetSurfaceBaseSpawner.cs) — spawner pattern mirrored by PlanetGateSpawner
