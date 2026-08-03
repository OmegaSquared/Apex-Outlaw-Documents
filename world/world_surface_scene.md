---
status: active
phase: 6.9
last-reviewed: 2026-06-09
---

# Surface Scene — Canon Design (Scene 3 of 3)

> Replaces the 2D arc-based [`world_planet_entry_scene.md`](world_planet_entry_scene_OLD.md)
> (archived). This is **Scene 3** in the three-scene world model — see
> [`world_overview.md`](world_overview.md) for the full architecture, and
> [`world_low_orbit_scene.md`](world_low_orbit_scene.md) for Scene 2.

## Scope

The Surface scene is where the player drives non-capital ships at low altitude
over a real 3D Planet Forge planet — close enough to see individual base modules,
mining sites, and terrain features. It is **permit-gated**: most attackers can't
enter without first earning the right (own a base / ally / defenses defeated).
Bases are physically rendered in the 3D world; only their **radar/minimap
markers** are stealth-gated by activity-noise mechanics.

## Experience

When the scene loads:

- The planet renders as the **same 3D Planet Forge body** as Scene 2 (Low Orbit),
  but the camera spawns at low altitude — typically 2–500 m above the actual
  terrain surface. Continuous LOD provides full detail.
- Camera is [`GroundBuildOrbitCamera`](../../Assets/Scripts/Macro/Ground/GroundBuildOrbitCamera.cs)
  with the surface-tuned values from `PlanetTest_Alythar`: 2 m minimum altitude
  above terrain, multi-sample look-ahead probe, panic rate cap (5 m/s normal →
  2000 m/s when approaching a rising peak), tiered wheel zoom (precise <18 km,
  fast >18 km — Scene 3's altitude range typically stays well below the threshold).
- **Only non-capital ships** are present. Capitals stayed in Low Orbit per the
  Scene 2 → Scene 3 permit gate. Frigates, drones, drop-pods, ground transports —
  these can all be here.
- **Player bases scattered at real (lat, lon)** — each `SurfaceBase` registry
  child resolves to a 3D world position on the displaced terrain via
  `SgtSphereLandscape.GetLocalPoint(unitDir × radius)`. Base prefab instantiates
  there, oriented with surface normal as local up.
- **Bases are always physically rendered in the 3D world** (subject to LOD /
  draw-distance budget). A silent base **does not disappear** — you can still
  fly over it and see it visually.
- **Radar / minimap visibility is activity-gated.** A base appears as a HUD
  marker for an enemy player only when:
  1. The base is currently emitting `NoiseLevel > 0` (smelter running, forge
     active, drone building, etc. — tracked by `BaseNoiseEmitter`), AND
  2. An enemy ship's sensor (`SensorSchema.sensorRadius` per grade) is within
     the noise radius of the base.
- **Silent = off-radar, NOT invisible.** Active scouting (visual flyover) is a
  valid attacker strategy. Terrain hiding (placing bases in canyons / behind
  ridges) is meaningful. Defenders who go silent lose their radar tag but
  remain visually discoverable.
- **Three-scope FOW** governs ship visibility (same as Scene 2 — see
  [`combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md)).
- **Fusion runners** spawn on FOW-driven engagement clusters, identical to
  Scene 2's pattern.

## Sky, shield & weather — current build (`Planet_01_surface.unity`, 2026-06-09)

The surface scene shares `Planet_01`'s visual stack with Low Orbit (same shield material + gate; radii table in [`world_low_orbit_scene.md`](world_low_orbit_scene.md)):

- **Shield dome.** The same `ApexOutlaw/PlanetShield` shell (radius 110,000) encloses the surface, so from the ground it reads as a faint blue **dome overhead** with the rim toward the horizon — the shader is double-sided, so it renders correctly from beneath. The pole **aperture** + the **orbital shield gate** loom directly overhead because the surface vantage (`CameraFocus`) is parked at the north pole, under the gate.
- **Cloud layering** (`SgtCloud` deck 105,500–105,650 + storm 105,650–108,000) clears the ~104,500 m terrain peaks, so mountains no longer poke through the clouds.
- **Precipitation.** [`SurfacePrecipitation`](../../Assets/Scripts/Macro/SurfacePrecipitation.cs) is a camera-following emitter: a tangent box of particles spawns above the view camera and falls along the planet radial, so weather stays around the player at any latitude. It **auto-picks by latitude** — `|lat| ≥ snowLatitude` (default 50°) → **snow** (slow drifting flakes); warmer → **rain** (fast streaks). The pole vantage is cold, so it shows snow; set `Mode = Rain` to preview rain. Soft-dot sprite + URP transparent particle material under `Assets/Prefabs/Weather/`.
- **Storms.** The same banded `StormRig` (`PlanetStormLightning`, belts 0° / ±38°) is present, but those belts are equatorial/mid-latitude — the polar vantage sits outside them, so the pole sees snow with little lightning (thunderstorms ring the tropics; the pole stays snowy). A polar band can be added if wanted.

> **Bridge:** as in Low Orbit, the shield / gate / storm rig and the surface vantage location are **scene-authored, not registry-driven** yet (Phase 6.9, [`../meta/master_to_do.md`](../meta/master_to_do.md)).

## Architecture layer

PlayFab macro by default — **Fusion only during active combat clusters**. Same
pattern as Low Orbit. `SceneManager.LoadScene("Surface")` with a `PlanetSceneEntry`
handoff. `ServerFowMatcher` drives runner spawning.

## Scene composition (template)

One template scene, `Assets/Scenes/Surface.unity`. Structurally identical to
Low Orbit with two differences:
- `OrbitalPOIsRoot` is replaced by `SurfaceBasesRoot` (3D base prefab placements)
- No capital ships in `PlayerFleetRoot`

```
SgtVolumeManager
Sun (Directional Light + SgtLight)
EventSystem (InputSystemUIInputModule)
Main Camera                (GroundBuildOrbitCamera, SgtVolumeCamera)
PlanetRoot                 (PF planet, identical to Low Orbit body)
SurfaceBasesRoot           (3D-placed base prefabs from SurfaceBase registry children)
PlayerFleetRoot            (non-capital ships only)
NoiseEmittersRoot          (BaseNoiseEmitter components attached to active bases)
ServerPresenceSubscription (Body_<bodyId>_Presence subscription)
FusionRunnerHost           (empty until engagement)
PositionCompressor + SnappingCamera
```

## Runtime flow

1. From Low Orbit, player requests surface drop. `PlanetSurfacePermitCheck` (server)
   evaluates: owns base / allied / defenses defeated. (See Low Orbit doc for the
   full rules.)
2. If granted, eligible (non-capital) ships are extracted from the fleet; their
   `FleetSnapshot` is written to `PlanetSceneEntry`. `SceneManager.LoadScene("Surface")`
   fires with `sceneType: Surface`.
3. Surface scene loader reads handoff, instantiates the planet via
   `PlanetForgeRenderer.Render(theme, bakedHeightmap)` (identical to Low Orbit —
   same seed, same theme, same terrain mesh).
4. `SurfaceBasesRoot` populates from `CelestialChildRecord` children of `bodyId`
   where `type == CelestialChildType.SurfaceBase`:
   - Resolve 3D world position from (`surfaceLatitude`, `surfaceLongitude`) via
     `SgtSphereLandscape.GetLocalPoint`.
   - Instantiate the base's `chassisID` prefab (from `MacroBaseRecord.chassisID`)
     at that position, oriented with surface normal as local up.
   - Attach `BaseNoiseEmitter` driven by the registered facility activity tasks.
5. Player ships spawn at the entry (lat, lon) handoff position with surface-tuned
   physics. Camera starts low (~500 m above terrain).
6. `ServerPresenceSubscription` tracks other-player ships and bases — rendering
   is gated by my-client FOW for ships and by activity-noise for base markers.
7. `FleetEncounterClient` listens for `ServerFowMatcher` notifications. On
   engagement, joins the cluster's `NetworkRunner`. Combat plays out, then runner
   tears down (same pattern as Scene 2).

## Activity-noise radar stealth

Every active surface base attaches a `BaseNoiseEmitter` MonoBehaviour:

- Listens to facility activity ticks (smelter loaded, forge running, drone
  fabricating, mining laser cutting, etc.).
- Computes a `NoiseLevel` float (sum of per-facility contributions; idle = 0).
- Broadcasts a noise event to nearby ship sensors via a simple per-tick check
  (the same per-frame tick used by `TacticalSensorResolver`).
- Enemy ships within their `SensorSchema.sensorRadius` of the noise source
  add this base to their `revealed-on-radar` set for that ship's local minimap
  / HUD overlay.
- Stop production → `NoiseLevel` falls to 0 over a configurable decay window
  (default 60 s). Base marker fades from enemy radar after decay.

**Critical:** the base GameObject is always present, always rendered. The
`BaseNoiseEmitter` only controls HUD marker visibility. A defender who pauses
their smelter still has the base physically there, visible to anyone who flies
over it directly.

## Data model

`MacroBaseRecord` already supports `BaseKind.Surface` with `longitudeDeg` and
`crossAxis` (latitude). One new field:

- `NoiseLevel` (computed, not persisted) — drives `BaseNoiseEmitter` at runtime.
  Per-tick from active facility tasks. Not in PlayFab; recomputed each session.

`CelestialChildRecord` still uses `surfaceLongitude` and `surfaceLatitude` from
the deprecated arc model — they remain valid since they're just (lat, lon)
coordinates on a sphere.

### System-view cleanliness

`SurfaceBase` children still **never** appear in the system view
([`SolarSystem.unity`](../../Assets/Scenes/Maps/SolarSystem.unity),
[`Vesperion.unity`](../../Assets/Scenes/Maps/Vesperion.unity)) — they live only
inside Scene 3. Enforced as before in
[`CelestialSpawner.cs`](../../Assets/Scripts/Macro/Celestial/CelestialSpawner.cs).

## CloudScript

[`celestial_surface_bases.js`](../../cloudscript/celestial_surface_bases.js)
handlers stay mostly the same:

- `BuildSurfaceBase({ playerId, bodyId, surfaceLongitude, surfaceLatitude, chassisID })`
  — validates great-circle distance to nearest existing `SurfaceBase` child of
  `bodyId` (`MIN_SLOT_SPACING_DEG = 15°`). Rejects on `slot_too_close`. Caller's
  allianceId (or PlayFabId fallback) becomes `ownerId`. Also bakes the body's
  heightmap on first base creation if not yet baked.
- `DemolishSurfaceBase({ childId })` — owner-only.

Bundled into [`_deploy_bundle.js`](../../cloudscript/_deploy_bundle.js).

## Bridges (live-data discipline)

- `BaseNoiseEmitter` initially reads from local `MacroBaseRecord.installedModules`
  and infers activity from module state. Once a real CloudScript-backed
  "facility activity tick" channel exists, this reads from that instead.
  Marked `// BRIDGE: remove when facility activity tick CloudScript ships` and
  tracked in [`master_to_do.md`](../meta/master_to_do.md).

## Rollout (Phase 6.9.A → 6.9.E)

Per the meta-plan in
`C:\Users\Aaron\.claude\plans\if-i-was-going-mutable-parnas.md`:

- **6.9.A** — Build `Surface.unity` template. Loader, surface-base placement,
  activity-noise visibility. Single-planet test (Avernus), no Fusion.
- **6.9.D** — `PlanetSurfacePermitCheck` server-side. Permit gate active.
- **6.9.E** — `BaseNoiseEmitter` + radar-marker reveal. Verify silent-base
  visual discovery still works.
- **6.9.F** — Fusion engagement spawns when two clients converge.

## Portable per-planet rig (Aaron 2026-06-11)

Every surface scene's gameplay layer is stood up by ONE idempotent editor tool —
`Apex Outlaw → Build → Setup Surface Gameplay Rig (active scene)`
([`PlanetSurfaceGameplayRigger`](../../Assets/Editor/PlanetSurfaceGameplayRigger.cs)) —
so a new planet goes from art scene to playable in one click. Decision: **no
hand-wiring per scene**; scene-specific limits derive from the scene's own
authored objects, not hardcoded numbers:

- Requires: `SgtTerrainPlanet` + `PlanetSurfaceContext` (bodyId) + `GroundBuildOrbitCamera`.
- Adds: `SgtTerrainCollider` (raycast floor for tiles + camera), `SurfaceBaseRoot`
  (`SurfaceTilePlacer` + `SurfaceBaseRenderer`), `BuildPanelHost` (`BaseBuildPanel`),
  `SurfaceFleetSpawner` (local no-Fusion flight, Smuggler_Frigate_MK1 BRIDGE fleet).
- Camera ground-clip floor: `minDistance` = `minAltitudeAboveTerrain` = 8 (alythar canon).
- Zoom-out cap: if the planet has a `*Shield*` dome child (dome sphere authored at
  localScale = radius), `maxDistance` = shieldRadius − (planetRadius + heightmap
  displacement) − 1500 margin — the camera can never leave the dome. First applied
  to `Planet_01_surface` (shield raised 110k → 120k, cap 14,000).

## Gate control — planetary king-of-the-hill (Aaron 2026-06-11, design locked, runtime TODO)

A protected planet has **5 orbital shield gates, all resting on the EQUATOR** (72° apart);
**moons carry 2** (antipodal). Gates are the only way through the shield, which makes them
the strategic terrain of the body:

- **Winning the planet is king-of-the-hill over its gates — OWNERSHIP = CONTROLLING ALL 5**
  (Aaron 2026-06-11). Planetary control belongs to the alliance that HOLDS every gate —
  control is continuous (keep them), not a one-time conquest. Faction/alliance control
  state drives the protected-planet rules (e.g. the delivery-freighter protection /
  patrol response in
  [`../ground_base/ground_base_deployment_beacon.md`](../ground_base/ground_base_deployment_beacon.md)).
- **Full control unlocks LOW-ORBIT alliance construction** (Scene 2 — see
  [`world_low_orbit_scene.md`](world_low_orbit_scene.md)): with all 5 gates held, the
  alliance can build additional points of interest in low orbit, including a **SatCom
  station** and a **missile defense platform**. Implementation hooks already in the
  project: `LowOrbitOrbitalStructure` (Scripts/Macro/LowOrbit) for the structure layer,
  and the `ScifiOrbitalSatCom` + `ScifiOrbitalTorpedoMissileLauncher` art packs for the
  visuals. Lose a gate → planet drops out of full control; rules for what happens to
  orbital POIs then (offline? capturable?) are an open design question.
- **Captured gates are buildable.** Once an alliance captures a gate it can build defenses
  ON the gate structure (turrets/shields — defense tile set TBD), making each gate a
  fortifiable chokepoint and raising the cost of flipping the planet.
- Deliveries and arrivals route through the NEAREST gate to their destination (the claim
  delivery already does this), so holding specific gates shapes the planet's logistics.

- **The shield has a SOURCE: the Shield Generator at the NORTH POLE** (Aaron 2026-06-11).
  The planetary shield is generated by a ground installation at the planet's north pole —
  a physical, attackable strategic site distinct from the 5 equatorial gates. Gates are
  the doors; the generator is the power. Implication: taking the planet has two military
  axes — capture the gates (control) or kill the generator (shield down).
- **Shield down → orbital bombardment** (Aaron 2026-06-11, future): when a planet's
  shield is DOWN (generator destroyed/offline), capital ships in orbit may fire orbital
  bombardments at surface targets. Makes the shield/gate layer the planet's survival
  condition, not just its border control. Depends on combat wiring + capital ship class.

Runtime status: Planet_01 has its full 5-gate equatorial ring authored. Capture
mechanics, gate defenses, and bombardment depend on the combat wiring (Phase 4/6.9.F).

## See also

- [`world_low_orbit_scene.md`](world_low_orbit_scene.md) — Scene 2 (low orbit)
- [`world_surface_navigation.md`](world_surface_navigation.md) — surface nav HUD: top-center compass strip (+ lat/lon/alt) + nav-minimap
- [`world_planet_authoring.md`](world_planet_authoring.md) — registry-driven planet authoring
- [`world_sector_map.md`](world_sector_map.md) — Solar (Scene 1) entry
- [`combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md) — three-scope FOW + activity noise
- [`ground_base/progression_base_building.md`](../ground_base/progression_base_building.md) — base construction pipeline
- [`world_planet_entry_scene_OLD.md`](world_planet_entry_scene_OLD.md) — archived 2D doc
