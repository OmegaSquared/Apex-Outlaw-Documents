---
status: canon
phase: "6.9"
last-reviewed: 2026-06-09
tags: [code-map, combat]
---

# Code Map — Tactical / Micro-Game (`Assets/Scripts/Tactical/`, `Assets/Scripts/ECS/`)

**29 .cs files in Tactical/; ECS/ is currently EMPTY** (no .cs files — the `ShipDamageSystem.cs` / `TacticalDamageRenderer.cs` DOTS subsystem referenced in CLAUDE.md has been removed; CLAUDE.md is stale on this point #needs-review). Short-lived **Photon Fusion event instances** for combat (3v3 + 10 spectators cap — [`world/world_sector_rules.md`](../world/world_sector_rules.md) §1). Beta-functional, not mature. Design canon: [`combat/combat_overview.md`](../combat/combat_overview.md), [[combat_mechanics]], [[combat_missile_system]].

## Key files
| File | Role |
|---|---|
| `Networking/FusionCombatServer.cs` | Session orchestration — Fusion `AutoHostOrClient` keyed by sectorID; spins the runner up/down. (Lives in Networking/ but belongs to this layer.) |
| `TacticalSimulatorBootstrapper.cs` | Combat-scene entry point: resolves FleetSnapshot from PlayFab, ignites the Fusion server; exit → `runner.Shutdown()` → loads `Shipyard` scene. |
| `TacticalFlightEngine.cs` | Authoritative ship flight — `NetworkBehaviour`, `[Networked]` state, Rigidbody physics with asymmetric thruster matrices. |
| `TacticalFleetLoader.cs` | Loads fleet/ship loadouts into the instance from profile data. |
| `TacticalHitbox.cs` | Per-subsystem damage accumulation, authority-gated (anti-cheat). |
| `TacticalFiringMechanism.cs`, `TacticalProjectile.cs`, `TacticalWeaponArc.cs`, `TacticalTurretAI.cs` | Gun pipeline: arcs, firing, projectiles, turret tracking. |
| `TacticalMissile*.cs` (7 files: Bay, BayHUD, Entity, FireController, Launcher, MountSelector) + `IMissileMount.cs` | Missile system per [[combat_missile_system]]. |
| `TacticalSensorResolver.cs`, `TacticalFOWRing.cs`, `TacticalFleetFOWUnionRing.cs`, `TacticalJammerEmitter.cs` | Sensors, FOW rings, e-war jamming. |
| `TacticalSelectionManager.cs`, `TacticalCameraController.cs` | Input/selection + camera (mirrored by Macro's selection manager). |
| `TacticalShipHUD.cs`, `TacticalMinimap.cs`, `TacticalRangeRing.cs`, `TacticalCrosshairContextProvider.cs` | Combat HUD elements. |
| `SectorContext.cs` | Static handoff: Macro sets `SectorContext.PendingSectorID` before loading the combat scene. |
| `ShipLoadoutConfig.cs`, `TacticalFactionRelations.cs`, `TacticalExplosiveCargo.cs`, `TacticalExhaustFactory.cs` | Loadout config, IFF, cargo explosions, exhaust VFX. |

## Instance lifecycle
1. Macro side: `MacroCombatBridge` session forms → (intended) FleetSnapshot bundle ([[code_map_backend]]).
2. `SectorContext.PendingSectorID` set → combat scene loaded.
3. `TacticalSimulatorBootstrapper` resolves snapshot from PlayFab → starts `FusionCombatServer` (AutoHostOrClient, keyed by sectorID).
4. Fight runs on Fusion tick authority.
5. Exit → `runner.Shutdown()` → back to Shipyard scene. **Results do NOT persist back to PlayFab yet (TODO).**

## Rules of the layer (CLAUDE.md hard rules)
- Fusion `[Networked]` only inside combat/mining event instances — never on sector/planet-map systems.
- Authoritative math is Fusion tick, not client.
- If DOTS returns it's visual-only (damage → GPU arrays), never combat authority.

## Traps / status
- ~7 active TODO markers; combat-result persistence is the big missing piece.
- Maturity: scaffolded/beta — don't assume patterns here are settled; `MacroCombatBridge` on the macro side is still a placeholder (no real runner handoff).
- ECS/ folder exists but is empty — don't cite ShipDamageSystem as a pattern.
