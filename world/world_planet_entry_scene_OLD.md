# Planet Entry Scene — Canon Design

> Lock-in for the long-deferred `MMO_Orbit_Scene.md` placeholder referenced in
> [`world_sector_map.md`](world_sector_map.md). This is the canonical doc for what the
> player sees when they enter / dock at a planet. Phase 6.7.F is the rollout phase;
> Avernus (inside Vesperion.unity) is the prototype.

## Experience: Vega-Conflict-style near-orbit

When a player enters a planet, the game cuts to a PlayFab lazy-loaded scene
(`Planet_<bodyId>.unity`) showing:

- The planet as a **large near-orbit backdrop** sized in proportion to its system-map
  rendering — same body, just a much tighter camera. **Really zoomed in**: only a
  horizontal equatorial band is visible; the camera's W/S pan is clamped so the
  player can never see the poles.
- The local player's **fleet visual** parked on the band, controlled the same way as
  in Vesperion: **right-click** anywhere in the band issues a waypoint, the fleet
  cruises there at the mass-weighted speed (reused `MacroFlightController`).
- A **horizontal band of slot positions** on the planet's surface that can host
  player-owned bases. The band is a **true 360° loop** — there is no visible-arc
  cutoff; travel far enough and the same bases come around again.
- **WASD** pans the camera (W/S vertically clamped), **QE** rotates the camera,
  **mouse wheel** zooms — same controls as `MacroView1CameraController` in
  Vesperion. A/D pan is free inside a central band (~60% of the screen width);
  beyond that the camera clamps and the residual input rotates the planet via
  `viewLongitude` — the player feels like they're orbiting around the planet.
- A `MacroSunFacingLight` driven by a `Sun_System` anchor at world origin lights the
  planet from the system's center. As the planet rotates under `viewLongitude`, the
  day / night terminator sweeps across the visible band.

Inspirations: Vega Conflict's planet view. Diegetic, low-orbit, horizontal.

## Fleet entry positioning

When the scene loads, `PlanetSurfaceBaseSpawner` resolves the initial `viewLongitude`
from the registry, before the camera is exposed to input:

- **Player has owned bases on this planet** — pick the owned base whose
  `surfaceLongitude` is closest (by `Mathf.DeltaAngle`) to the persisted last-view
  value (`PlayerPrefs` key `Planet_<bodyId>_lastView`). Fleet enters at the base
  nearest to where the player last left off.
- **No owned base** — pick a uniform random longitude in `[0, 360)`. The player
  enters at an unpredictable point on the planet, encouraging exploration.

Current `viewLongitude` is persisted back on scene unload. **BRIDGE**: PlayerPrefs
is local-only; cross-device sessions will need this stored in PlayFab player data.
Tracked in `master_to_do.md` under Phase 6.x.

## Architecture layer

PlayFab macro — **not Fusion**. The planet-entry scene is just another macro scene
loaded by `MacroPlanet.CompleteOrbitEntry → SceneManager.LoadScene(orbitSceneAddress)`.
No `NetworkRunner` spins up. Attack telegraphs reuse `MacroFleetTransitTimer`; the
actual attack resolution flows through CloudScript (Phase 4.x).

## Data model

Surface bases are stored as registry children, **not** as a separate schema. This
keeps the PlayFab data path single-source-of-truth.

- New `CelestialChildType.SurfaceBase = 16` —
  [`CelestialChildType.cs`](../../Assets/Scripts/Schemas/Celestial/CelestialChildType.cs).
- New `CelestialChildRecord.surfaceLongitude` (float, `[0, 360)`) — slot's longitude
  around the host planet. Only meaningful for `SurfaceBase` children.
- New `CelestialChildRecord.surfaceLatitude` (float, `[-90, 90]`) — slot's latitude.
  Surface bases can sit anywhere on the planet, not just the equator. Defaults to 0
  so legacy records authored before this field stay on the equator.
- `BuildSurfaceBase` accepts an optional `surfaceLatitude` (default 0) and the
  minimum-spacing check uses **great-circle distance** over `(lat, lon)` instead of
  1D longitude delta — so two bases on different longitudes but the same pole-region
  can still collide.
- `defenseCurrentHp` (float) added alongside `defenseMaxHp` so attack resolution has
  a place to decrement HP without needing a separate combat record.
- `ownerId` carries either an alliance UUID (per the canon "factions ARE alliances")
  or a player id for solo-owned bases.

### System-view cleanliness

`SurfaceBase` children must **never** appear in the system view
([`SolarSystem.unity`](../../Assets/Scenes/Maps/SolarSystem.unity),
[`Vesperion.unity`](../../Assets/Scenes/Maps/Vesperion.unity)) — they live only
inside their host planet's entry scene. Enforced in
[`CelestialSpawner.cs`](../../Assets/Scripts/Macro/Celestial/CelestialSpawner.cs)
by skipping `c.type == CelestialChildType.SurfaceBase` during pass 3 (children).

## Scene composition

Authored programmatically by
[`PlanetAvernusSceneBuilder.cs`](../../Assets/Editor/PlanetAvernusSceneBuilder.cs)
(re-runnable; idempotent — tunable inspector fields are only written on first author).
Each planet scene mirrors this layout:

```
Sun_System                (empty at world origin — MacroSunFacingLight reference)
Main Camera               (orthographic, slight tilt)
  PlanetCameraController          ─ WASD/QE pan + rotate, vertical clamp, edge handoff
Directional Light         (warm)
  MacroSunFacingLight             ─ tracks planet → sun direction every frame
PlanetView                (root)
  PlanetSurfaceViewController     ─ owns viewLongitude, planet rotation, slot positioning
  PlanetSurfaceBaseSpawner        ─ pulls SurfaceBase children of planetId from the registry
  PlanetFleetController           ─ spawns the player fleet visual, click-to-move
  PlanetSphere                    ─ large background sphere with the body's material
    Visual                          (FORGE3D prefab or sphere primitive)
  SlotsRoot                       ─ parent for spawned MacroSurfaceBasePoi children
  FleetAnchor                     ─ transform where the local player's fleet visual parks
```

## Runtime flow

1. Player right-clicks the planet's entry POI in the system view.
2. [`MacroPlanet.BeginTransit`](../../Assets/Scripts/Macro/MacroPlanet.cs) starts a
   5-second `MacroFleetTransitTimer` (`TransitKind.PlanetEntry`) on the fleet.
3. On timer completion, `CompleteOrbitEntry` calls
   `SceneManager.LoadScene(orbitSceneAddress)` — for Avernus that's `Planet_avernus`.
4. The new scene's [`PlanetSurfaceBaseSpawner`](../../Assets/Scripts/Macro/PlanetSurfaceBaseSpawner.cs)
   subscribes to `CelestialRegistryClient.OnRegistryUpdated` and instantiates a
   [`MacroSurfaceBasePoi`](../../Assets/Scripts/Macro/MacroSurfaceBasePoi.cs) per
   `SurfaceBase` child of `planetId`.
5. [`PlanetSurfaceViewController`](../../Assets/Scripts/Macro/PlanetSurfaceViewController.cs)
   reads horizontal input every frame, advances `viewLongitude`, rotates the planet,
   and repositions visible POIs along the horizontal arc.
6. Right-click an enemy POI → `MacroSurfaceBasePoi.BeginAttack` starts a
   `MacroFleetTransitTimer` with `TransitKind.SurfaceBaseAttack`. On completion, the
   BRIDGE stub fires until Phase 4.x ships real macro-base-combat resolution.

## CloudScript

[`celestial_surface_bases.js`](../../cloudscript/celestial_surface_bases.js) exposes:

- `BuildSurfaceBase({ planetId, surfaceLongitude, displayName? })` — validates that
  no existing `SurfaceBase` child of `planetId` is within `MIN_SLOT_SPACING_DEG = 15°`
  of the requested slot. Rejects with `{ ok: false, reason: "slot_too_close" }`
  otherwise. Caller's allianceId (or PlayFabId fallback) becomes `ownerId`.
- `DemolishSurfaceBase({ childId })` — owner-only.

Bundled into [`_deploy_bundle.js`](../../cloudscript/_deploy_bundle.js).

## Bridges (live-data discipline)

Per the CLAUDE.md live-data rule, every player-visible system in this design is
wired to the live PlayFab path. The single exception, tracked for removal:

- `MacroSurfaceBasePoi.BeginAttack` onComplete callback — logs that the attack window
  elapsed. Real handler is the Phase 4.x macro-base-combat resolution (a CloudScript
  call that decrements `defenseCurrentHp`, flips `isOnline`, optionally seeds a
  Fusion combat instance). Marked with `// BRIDGE: remove when Phase 4.x macro-base-
  combat resolution lands` and tracked in
  [`master_to_do.md`](../meta/master_to_do.md) under "Bridge code to remove".

## Rollout (Phase 6.7.F)

- Prototype target: **Avernus** (inside Vesperion.unity). Wired by
  [`AvernusOrbitSceneAddressPatcher.cs`](../../Assets/Editor/AvernusOrbitSceneAddressPatcher.cs).
- Each additional planet gets its own `Planet_<bodyId>.unity` scene built off the same
  template + a registry parent entry + per-planet `orbitSceneAddress`. Faction
  homeworlds (Concordia, Ferrum) and hostile bodies stay off-limits per the
  inhabitable-sectors canon — no scene for those until policy changes.

## See also

- [`world_planet_authoring.md`](world_planet_authoring.md) — system-view planet authoring (gates, orbits)
- [`world_sector_map.md`](world_sector_map.md) — sector-view contract this docks into
- [`architecture/architecture_plan.md`](../architecture/architecture_plan.md) §1.5 — registry-driven design
