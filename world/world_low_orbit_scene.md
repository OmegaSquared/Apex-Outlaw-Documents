---
status: active
phase: 6.9
last-reviewed: 2026-06-09
---

# Low Orbit Scene — Canon Design (Scene 2 of 3)

> Replaces the 2D arc-based [`world_planet_entry_scene.md`](world_planet_entry_scene_OLD.md)
> (archived). This is **Scene 2** in the three-scene world model — see
> [`world_overview.md`](world_overview.md) for the full architecture.

## Scope

The Low Orbit scene is what loads when a player enters a planet voluntarily from
Solar (the sector map / hyperspace). It renders the planet as an actual 3D Planet
Forge body with real ships, orbital structures, and FOW-gated visibility. Compared
to the deprecated 2D rotating planet view, **everything is real 3D** — no arc
projection, no longitude pinning, no rotating the planet under a fixed camera.

## Experience

When the scene loads:

- The planet renders as a **3D Planet Forge sphere** below the player's fleet via
  [`PlanetForgeRenderer.cs`](../../Assets/Scripts/Macro/Ground/PlanetForgeRenderer.cs)
  using the body's `terrainThemeId` from `CelestialRegistry`. Atmosphere ring,
  clouds, ocean, and biome detail all render per the theme.
- The player's **fleet ships are 3D entities** flying in low orbit. Capital ships,
  frigates, drones — all fleet sizes welcome here. (Capitals are blocked from the
  Surface scene below; this is their home.)
- **Orbital structures** spawn from the registry at registered (altitude, latitude,
  longitude) positions: satcom arrays, planetary defense platforms, citadels, docks,
  jump gates, ring stations. Each is a real 3D prefab.
- **Camera** is [`GroundBuildOrbitCamera`](../../Assets/Scripts/Macro/Ground/GroundBuildOrbitCamera.cs)
  at high altitudes (default ~5–50 km above the smooth sphere). Wheel zoom uses
  the tiered factor (precise <18 km surface mode, fast >18 km orbital mode).
- **Ship controls** are the existing RTS pipeline:
  [`TacticalSelectionManager`](../../Assets/Scripts/Tactical/TacticalSelectionManager.cs)
  for right-click move / left-click marquee / shift-append, driving
  [`TacticalFlightEngine`](../../Assets/Scripts/Tactical/TacticalFlightEngine.cs)
  for waypoint physics. Same input model as `shipmanagerTestFleet.unity`.
- **Three-scope FOW** governs visibility (see
  [`combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md)):
  - My-client FOW renders friendly + revealed-enemy ships and orbital POIs
  - Server-side FOW (wider) drives encounter prediction + Fusion runner spawn
  - Their-client FOW (asymmetric) renders only what the other player can see
- **Fusion `NetworkRunner` spawns lazily** per engagement cluster when the server
  FOW matcher detects mutual hostile fleet contact. Up to 16 players per runner
  (CLAUDE.md combat-instance cap). Multiple parallel runners per planet are
  normal. Players not in any engagement remain in PlayFab macro state.

## Architecture layer

PlayFab macro by default — **Fusion only during active combat clusters**. The
scene itself is just another Unity scene loaded via `SceneManager.LoadScene("LowOrbit")`
with a `PlanetSceneEntry` static handoff. No `NetworkRunner` exists until the
`ServerFowMatcher` (PlayFab CloudScript) detects a hostile cluster and spins one
up. After the cluster disengages, the runner tears down.

This matches the existing combat-instance bridge pattern from
[`architecture_data_schemas.md`](../architecture/architecture_data_schemas.md) §6 —
`FleetSnapshot` carries pre-resolved stats across the macro→Fusion boundary; no
formulas cross.

## Scene composition (template)

One template scene, `Assets/Scenes/LowOrbit.unity`. Built programmatically by an
editor strip-and-rebuild script analogous to
[`PlanetTest_Alythar_StripAndRebuild.cs`](../../Assets/Editor/PlanetTest_Alythar_StripAndRebuild.cs).
The handoff drives per-planet content:

```
SgtVolumeManager           (SGT atmosphere/volumetrics singleton)
Sun (Directional Light + SgtLight)
EventSystem (InputSystemUIInputModule)
Main Camera                (GroundBuildOrbitCamera, SgtVolumeCamera)
PlanetRoot                 (instantiated by PlanetForgeRenderer; theme-skinned PF planet)
  ├─ SgtSphereLandscape    (radius from registry, baked heightmap injected)
  ├─ SgtSky, SgtCloud, SgtOcean
  └─ SgtLandscapeCollider  (mesh colliders for raycast queries)
OrbitalPOIsRoot            (3D prefabs per registry: docks, citadels, satcom, etc.)
PlayerFleetRoot            (player's ships spawn here on scene load)
ServerPresenceSubscription (subscribes to Body_<bodyId>_Presence PlayFab channel)
FusionRunnerHost           (empty until engagement; NetworkRunner spawns here on demand)
PositionCompressor + SnappingCamera (floating-origin for 5M-radius planets)
```

## Runtime flow

1. Player in Solar view right-clicks a planet POI → existing
   [`MacroPlanet.BeginTransit`](../../Assets/Scripts/Macro/MacroPlanet.cs) starts a
   transit timer (`TransitKind.PlanetEntry`).
2. On timer completion, `CompleteOrbitEntry` writes `PlanetSceneEntry.bodyId`,
   `fleetEntryWorldPos` (low-orbit position around the body),
   `fleetEntryHeading`, `sceneType: LowOrbit`, then calls
   `SceneManager.LoadScene("LowOrbit")`.
3. The Low Orbit scene's loader reads the handoff, looks up the body in
   `CelestialRegistry`, calls `PlanetForgeRenderer.Render(theme, bakedHeightmap)`
   to instantiate the planet.
4. `OrbitalPOIsRoot` populates from `CelestialChildRecord`s of types `JumpGate`,
   `DefenseStation`, `Citadel`, `Dock`, `Satcom`, `RingStation` (sub-types of
   `CelestialChildType`).
5. The player's fleet spawns at `fleetEntryWorldPos` with `TacticalFlightEngine`
   + `MacroFlightController` (single-player cruise; networked only if a Fusion
   runner spawns later).
6. `GroundBuildOrbitCamera` follows the fleet centroid by default; user can
   take manual pan control with WASD/mouse.
7. **`ServerPresenceSubscription`** polls the `Body_<bodyId>_Presence` channel
   for other-player fleets and renders them via low-fidelity ship prefabs,
   gated by my-client FOW.
8. **`FleetEncounterClient`** subscribes to the `ServerFowMatcher`. When notified
   of engagement, joins the indicated `NetworkRunner`; ships in the cluster hand
   off to networked authority via `FleetSnapshot`. Combat plays out via
   `TacticalFlightEngine` + `FusionCombatServer`. On disengagement, runner tears
   down, surviving ships persist to PlayFab macro state.

## Permit-gated transition to Surface

When the player wants to drop from Low Orbit to Surface, the client calls
`PlanetSurfacePermitCheck` (server-side, CloudScript). The check evaluates:

1. Player owns at least one `SurfaceBase` child of this `bodyId` in the registry, OR
2. Player's alliance includes a player who owns a `SurfaceBase` here, OR
3. All `DefenseStation` and `Citadel` children of this `bodyId` are destroyed
   (`defenseCurrentHp <= 0`).

If allowed: `SceneManager.LoadScene("Surface")` with `PlanetSceneEntry.sceneType =
Surface` and the entry lat/lon. If denied: client shows a reason banner
(`"no permit at this body"`, `"defenses still active"`).

**Capital ships can never drop.** Each `ShipChassisSchema` carries a
`canEnterAtmosphere` bool; capitals are flagged `false`. The Surface scene rejects
any non-eligible ships from the entry batch and they stay parked in Low Orbit.

## Data model

Orbital POIs are existing `CelestialChildRecord` types in `CelestialRegistry`:

- `JumpGate` (existing) — drives hyperspace exit to a destination body
- `DefenseStation` (existing) — planetary defense, contributes to the permit gate
- `Citadel` (new sub-type) — alliance flagship orbital structure
- `Dock` (new sub-type) — capital-ship dock
- `Satcom` (new sub-type) — communication / vision broadcaster
- `RingStation` (new sub-type) — large alliance station with internal sub-scenes

Each carries:
- `orbitAltitude` (float, meters above smooth sphere — distinguishes "low orbit" vs
  "high orbit" placements)
- `orbitLongitude`, `orbitLatitude` (float, degrees — placed on a sphere around the
  body at the configured altitude)
- `ownerId` (alliance UUID, player ID, or empty for NPC structures)
- `defenseCurrentHp`, `defenseMaxHp` (for destructible structures)

`SurfaceBase` records (used in Scene 3) are **never** spawned in Low Orbit — see
the next doc.

## CloudScript

Handlers added/extended for the Low Orbit scene:

- `PlanetSurfacePermitCheck({ playerId, bodyId })` — returns
  `{ ok: bool, reason?: string }` per the gate rules above. Server-authoritative.
- `BuildOrbitalStructure({ playerId, bodyId, type, altitude, longitude, latitude })` —
  alliance-permission-gated orbital construction. Replaces the older single
  `BuildSurfaceBase` flow with a typed variant.

Bundled into [`_deploy_bundle.js`](../../cloudscript/_deploy_bundle.js).

## Planet visual stack — current build (`Planet_A_orbit.unity`, 2026-06-09)

The working orbit-view scene (`Assets/Scenes/Planets/Planet_A_orbit.unity`, planet `Planet_01`, `SgtTerrainPlanet` R=100,000) carries the full atmospheric + defensive visual stack. Radii are world units from the planet centre; terrain peaks reach **~104,500** (SgtTerrain displacement 4,500), so every layer above is sized to clear them:

| Layer | Radius (world u) | Component |
|---|---|---|
| Terrain peaks | ~104,500 | `SgtTerrainPlanet` + `SgtTerrainHeightmap` (displacement 4500) |
| Cloud deck | 105,500 – 105,650 | `SgtCloud` "Planet_01 Cloud Deck" |
| Storm clouds | 105,650 – 108,000 | `SgtCloud` "Planet_01 Storm Clouds" (the lightning band) |
| Atmosphere | 101,575 → 121,575 | `SgtSky` "Planet_01 Sky" |
| **Planetary shield** | **110,000** | `ApexOutlaw/PlanetShield` icosphere under `Planet_01` |
| **Orbital shield gate** | on the shield, **north pole** | `RoundSpaceStation` ring |

For reference, `Planet_alythar` (same R=100,000) keeps clouds low (`SgtCloud` inner 101,100 / outer 101,180, ≈1.1 km) with a 5 km atmosphere (inner 100,000, height 5,000) — its terrain is tame, so it doesn't need the higher stack Planet_01's 4.5 km peaks demand.

**Planetary shield.** A semi-transparent blue energy shell — [`Assets/Shaders/PlanetShield.shader`](../../Assets/Shaders/PlanetShield.shader) (URP transparent fresnel, double-sided via VFACE, soft edge-gradient + HDR rim, lifted by a subtle global Bloom `Assets/GameData/Rendering/ShieldBloom.asset`). The shader clips a circular **aperture** around `_ApertureDir` (object space) with a glowing ring; `_ApertureCos = cos(asin(holeRadius / shieldRadius))`. Mesh `Assets/Prefabs/Weather/ShieldIcoSphere.asset`, material `Assets/Prefabs/Weather/PlanetShield.mat` (shared across both scenes → the aperture is one shared material setting). Parented under `Planet_01` at `localScale` = shield radius, so it tracks the planet.

**Orbital shield gate.** A ring station (`Assets/Art_Assets/RoundSpaceStation/`) seated in the aperture at the north pole — ships descend through the centre. Hull textured via `GateHull.mat` / `GateWindows.mat`. The aperture is sized to the ring's opening. Conceptually a `RingStation` orbital structure (see Data model) but for now **scene-authored, not registry-driven** (BRIDGE). The registry-driven, alliance-controlled design that supersedes this bridge is specced in [`world_orbital_shield_gates.md`](world_orbital_shield_gates.md) (`CelestialChildType.OrbitalShieldGate`, dual-scene sync, build/capture).

**Moons & eclipse.** [`PlanetMoonSystem`](../../Assets/Scripts/Macro/PlanetMoonSystem.cs) instances real SGT Planet Forge bodies (`Assets/Prefabs/Moons/Moon_Luna.prefab`, harvested from SGT's *Lunara* demo) for the three moons (Selas / Veil / Orin); positions are a pure function of `CelestialClock`. The flat sun-disk billboard is hidden — the eclipse reads against the SGT atmospheric glow (corona). [`CelestialTimeScrubber`](../../Assets/Scripts/Macro/CelestialTimeScrubber.cs) drives `CelestialClock.DesignerOffsetSeconds` to scrub moons + sun together to pose an eclipse for a screenshot.

**Storms.** [`PlanetStormLightning`](../../Assets/Scripts/Macro/PlanetStormLightning.cs) emits banded lightning bolts at `boltRadius` 106,500 (mid storm-cloud band) in latitude belts 0° / ±38°, paired with `LightningFlasher` glow lights — extracted from `Planet_aridonPF.unity` into `Assets/Prefabs/Weather/StormRig.prefab`.

**Camera.** `GroundBuildOrbitCamera` with `lockZoomBand` on: `minDistance` 10,100 (≈100 m above the raised shield — can't dive through it), `maxDistance` 25,000, opens at 20,000; `CameraFocus` sits at the north pole so the view launches at the gate.

> **Bridges (Phase 6.9):** the shield, gate, storm rig, and the 3-moon *set* are all **scene-authored**, not yet driven by `CelestialRegistry`. When orbital structures + a moon-ladder become registry-driven, the gate becomes a `RingStation`(+shield) child and the moons come from the registry. Tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md). The surface scene ([`world_surface_scene.md`](world_surface_scene.md)) shares the same shield material + gate, plus camera-following precipitation.

## See also

- [`world_surface_scene.md`](world_surface_scene.md) — Scene 3 design (surface zoom + bases)
- [[world_surface_navigation]] — shared nav HUD (compass + sensor radar) this scene carries
- [`world_planet_authoring.md`](world_planet_authoring.md) — registry-driven planet authoring (now 3D)
- [`world_sector_map.md`](world_sector_map.md) — Solar (Scene 1) entry contract
- [`combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md) — three-scope FOW
- [`architecture/architecture_overview.md`](../architecture/architecture_overview.md) — three-scene model
- [`world_planet_entry_scene_OLD.md`](world_planet_entry_scene_OLD.md) — archived 2D doc
