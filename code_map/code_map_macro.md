---
status: canon
phase: "6.9"
last-reviewed: 2026-06-09
tags: [code-map, macro]
---

# Code Map — Macro Layer (`Assets/Scripts/Macro/`)

**211 .cs files — the bulk of the game.** The PlayFab-backed strategic layer: sector views, fleets, celestial orbits, jump gates, FOW mesh networking, asteroid belts, surface bases, resource scanning. MonoBehaviours + lazy evaluation. **No Photon Fusion here, ever** (CLAUDE.md hard rule). Design canon: [`world/world_sector_map.md`](../world/world_sector_map.md), [`architecture/architecture_plan.md`](../architecture/architecture_plan.md) §1.5.

## Singletons / managers (the spine)
| File | Role |
|---|---|
| `MacroSelectionManager.cs` | Fleet selection + command dispatch; holds `AllFleets` / `SelectedFleets`; right-click waypoints → `MacroFlightController.IssueCommand`. `Instance`. |
| `MacroViewModeController.cs` | Camera mode driver SectorView ↔ SectorMap ↔ SolarMap; hotkeys `M` / `Shift+M`; `ModeChanged` event; `Toggle()` is what the HUD sector-map button calls. `Instance`. |
| `MacroSyncMesh.cs` | FOW mesh-network graph — proximity clustering of allied fleets pools sensors (`min(syncRadii)` rule); `OnPlayerSyncStateChanged`. `Instance`. BRIDGE: client-side, moves server-side Phase E. |
| `Celestial/CelestialClock.cs` | Static time-of-truth: UTC epoch from PlayFab title data `CelestialEpoch`; positions are pure functions of `(UtcNow − Epoch)` — **never accumulate `Time.deltaTime`**. Dev fallback epoch 2026-01-01. |
| `Celestial/CelestialRegistryClient.cs` | Live `CelestialRegistry` from title data (fallback `Resources/CelestialSeed`); `OnRegistryUpdated`. `Instance`. |
| `Celestial/CelestialSpawner.cs` | Spawns/syncs registry-driven bodies + POI children into SolarSystem scene. `Instance`. |
| `MacroPartyService.cs` | Raiding-party trust groups (in-memory stub; feeds SyncMesh FOW pooling). `Instance`. |

## Fleets & movement
| File | Role |
|---|---|
| `MacroFleet.cs` | Core fleet entity: `ships` (FleetShip), `allianceId`, position/velocity, `IsEngaged` lock, mass-weighted cruise speed. |
| `MacroFlightController.cs` | Per-fleet waypoint queue executor + intercept math. |
| `FleetCompositionService.cs` | Drag-drop transfer/split between fleets; `MAX_FLEET_MASS = 2000f`. BRIDGE: client-side until `PlayerTransferShip`/`PlayerSplitFleet` CloudScript lands. |
| `FleetJumpController.cs` | Gate entry, destination resolve, jump timer. |
| `PlanetTransition/` + `FleetPlanetEntryController` | Planet orbit entry/exit handoff. |

## Sub-systems (folders)
| Area | Key files | Notes |
|---|---|---|
| Jump gates | `MacroJumpGate.cs` (data marker), `JumpGateNetwork.cs` (graph), `JumpGateNetworkVisualizer`, click/ping/broadcast visuals | Bubble-radius connectivity — **not** chain-pairs (legacy `SectorChainRegistry` pattern deprecated, see CLAUDE.md). |
| Celestial math | `CelestialOrbiter`, `CelestialPositionEvaluator`, `CelestialEllipticalOrbiter`, `MacroOrbiter` | Evaluate-at-time, deterministic across clients. |
| FOW | `MacroFOWOverlay`, `MacroFOWUnion`, `MacroFOWVisibilityGate` | Three-scope FOW design: [[combat_fog_of_war]]. |
| Asteroids/mining | `MacroAsteroidBelt`, `MacroAsteroidYield`, `MacroSectorDirector` (drifter spawner), `MacroMiningBridge` (BRIDGE stub) | |
| Surface bases | `SurfaceBase/` (23 files): `SurfaceBaseStore`, `SurfaceGridManager`, `SurfaceTileCatalog`, `SurfaceStabilityGraph`, `SurfaceBaseLifecycle` | Design: [`ground_base/ground_base_overview.md`](../ground_base/ground_base_overview.md). |
| Ground/LowOrbit | `Ground/` (7), `LowOrbit/` (6) — scene loaders, drones, near-orbit view | Three-scene world model: [[world_low_orbit_scene]], [[world_surface_scene]]. |
| Resource scanner | `ResourceScanner/ResourceScannerPanel.cs` (ThemedMenu consumer; CloudScript `ResolveMaterialAnchors`), `ResourceScannerMarker` | Self-bootstraps into scenes with a `MacroAsteroidBelt`. |
| Combat handoff | `MacroCombatBridge.cs` | Phase-4 placeholder: virtual `MacroCombatSession` (join window, chevron tinting, wreckage) — **no Fusion runner yet**. |
| Cameras | `MacroCameraController`, `SolarSystemZoomController`, `PlanetCameraController`, `Helion/` variants | |
| Context/labels | `MacroSectorContext`, `MacroSceneScale`, `*Label.cs` files, `MacroInteractable`/`MacroInteractionResolver` (right-click context menus) | |

## Boot order
1. `CelestialClock` fallback epoch (BeforeSceneLoad) → 2. `CelestialRegistryClient` singleton (AfterSceneLoad; fetch on login via `CelestialEpochFetcher`) → 3. scene managers' `Start()` register fleets → 4. `MacroSyncMesh.LateUpdate` rebuilds graph → 5. `ResourceScannerPanel.Bootstrap` self-installs.

Scenes: `Maps/SolarSystem.unity` (registry-driven system map), sector scenes (`Maps/Vesperion.unity`, `Sectors/*.unity`), planet/orbit scenes via `GroundBaseSceneLoader`.

## Cross-system touchpoints
- PlayFab: title data (`CelestialEpoch`, `CelestialRegistry`), CloudScript `ResolveMaterialAnchors`; planet control via `PlanetControlBinder` ([[code_map_backend]]).
- UI: `SectorSceneLoader`/`SolarSystemSceneLoader` live in `UI/` ([[code_map_ui]]); roster cards call `FleetPlanetEntryController`.
- Tactical: only through `MacroCombatBridge` (FleetSnapshot bundling at instance start — [[code_map_tactical]]).

## Traps
- BRIDGEs (tracked in [`meta/master_to_do.md`](../meta/master_to_do.md)): client-side FOW mesh, celestial seed fallback (Phase 6.0.G), fleet composition CloudScript, MacroCombatBridge placeholder, party persistence.
- Deprecated: `SolarSystemTimeScale` fast-forward (use `CelestialClock.DesignerOffsetSeconds`), cyan FOW ring auto-spawn compat in `MacroViewModeController.EnsureFOWOverlay`, "FormationDots" cluster in `MacroFleetVisualizer`.
- Don't hand-bake bodies/POIs into SolarSystem.unity — registry-driven (CLAUDE.md hard rule).
