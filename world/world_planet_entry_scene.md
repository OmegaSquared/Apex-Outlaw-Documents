# Planet Entry Scene — DEPRECATED (split into two docs)

> **This doc is deprecated as of 2026-05-29.** The 2D arc-based planet entry
> model described here has been retired in favor of the **three-scene world
> architecture** (Solar / Low Orbit / Surface). See the meta-plan at
> `C:\Users\Aaron\.claude\plans\if-i-was-going-mutable-parnas.md` for the full
> design rationale.

## What replaced this

The single "planet entry scene" concept has been split into two distinct scenes:

- **[`world_low_orbit_scene.md`](world_low_orbit_scene.md)** — Scene 2. The
  3D Planet Forge body with real ships in low orbit, orbital structures (docks,
  citadels, satcom, planetary defense), all fleet sizes including capitals.
  Open entry from Solar.
- **[`world_surface_scene.md`](world_surface_scene.md)** — Scene 3. Same 3D
  Planet Forge body at low altitude with 3D-placed surface bases. Permit-gated
  entry from Low Orbit. Capital ships excluded. Activity-noise radar stealth
  for bases.

The two scenes share the same `PlanetForgeRenderer` + `TerrainThemeSchema`
infrastructure; what differs is the altitude band, what entities populate the
scene, and the entry gate.

## What got retired (no longer canon)

- 2D rotating planet view with arc-projected POIs
- `viewLongitude` / `viewLatitude` planet rotation under fixed camera
- `Planet_<bodyId>.unity` per-planet scenes
- `PlanetSurfaceViewController.cs`
- `PlanetFleetLongitudePinner.cs`
- `MacroFOWOverlay.cs` (planet-view variant)
- `PlanetSurfaceBaseSpawner.cs` (arc-band placement)
- `MacroSurfaceBasePoi.cs` as a 2D marker on an arc

## What carried over

- `CelestialChildType.SurfaceBase` enum value — still used; just interprets
  `surfaceLongitude` + `surfaceLatitude` as actual 3D lat/lon coordinates now,
  not 1D arc positions.
- `MacroBaseRecord` with `BaseKind.Surface` + `longitudeDeg` + `crossAxis` — unchanged.
- `celestial_surface_bases.js` CloudScript (`BuildSurfaceBase`, `DemolishSurfaceBase`)
  — kept; great-circle distance validation already handled the 3D case.
- `MIN_SLOT_SPACING_DEG = 15°` minimum spacing — unchanged.

## Archive

The original deprecated design is preserved verbatim at
[`world_planet_entry_scene_OLD.md`](world_planet_entry_scene_OLD.md) for
historical reference.
