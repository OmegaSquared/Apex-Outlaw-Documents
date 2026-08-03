---
status: canon
phase: "6.9"
last-reviewed: 2026-06-09
tags: [code-map, backend]
---

# Code Map — Backend / Networking (`Assets/Scripts/Networking/`, `cloudscript/`)

7 .cs files + 9 CloudScript .js handlers. PlayFab is **authoritative** for everything economic/persistent (CLAUDE.md hard rule: never trust the client). Design canon: [`architecture/architecture_backend_network.md`](../architecture/architecture_backend_network.md), [[architecture_data_schemas]].

## C# files
| File | Role |
|---|---|
| `Networking/PlayFabManager.cs` | THE singleton. `Instance`, `IsLoggedIn`, `ActiveProfile`, login flow (hardware-ID → email/password), `ResolveCurrentEditTarget`, `EnsureFleetSeeded`, events `OnLoginComplete` / `OnRequireRegistration` / `OnLoginError`. |
| `Networking/PlayerProfile.cs` | The `ActiveProfile` shape: `displayName`, `federationCredits`, `stackableInventory` (dict), `moduleInventory` (List of `PartInstance` — `itemID`, `grade`), ship instances, fleets, home location, integrity checksums. |
| `Networking/InventoryClient.cs` | CloudScript wrapper for inventory mutations. |
| `Networking/RecipeClient.cs` | CloudScript wrapper for recipe/crafting calls. |
| `Networking/BuildCostValidator.cs` | Client-side pre-validation of build costs (server still authoritative). |
| `Networking/CelestialEpochFetcher.cs` | Consolidated boot fetch of `CelestialEpoch` + `CelestialRegistry` title data after login ([[code_map_macro]]). |
| `Networking/FusionCombatServer.cs` | Photon Fusion session orchestration — documented in [[code_map_tactical]]. |

## CloudScript handlers (`cloudscript/`)
| File | Handles |
|---|---|
| `inventory.js` | Inventory mutations (add/remove/transfer). |
| `recipes.js` | Crafting/recipe execution. |
| `forge.js` | Forge production. |
| `scanning.js` | Resource scanning (`ResolveMaterialAnchors` — belt-rock resolution by seed). |
| `player_home_location.js` | Home location seed/ensure. |
| `celestial_admin.js` | Admin registry edits. |
| `celestial_alliance_pois.js` | Alliance-built POIs (canonical write path — never direct registry writes). |
| `celestial_surface_bases.js` | Surface base records. |
| (+ `README.md`, test/meta files) | Deploy notes; `Assets/Editor/Debug/RebuildCloudScriptBundle.cs` + `SyncPushRegistry.cs` push from editor. |

## Boot / login order
Hardware-ID login attempt → email/password (registration if required) → profile load + integrity validation → `EnsureFleetSeeded` → `EnsureHomeLocation` → `OnLoginComplete` → `CelestialEpochFetcher` fetch → scene flow continues (`LoginScreenUI` → Shipyard).

## Consumers of `ActiveProfile`
`ShipyardUI`, `DashboardUI`, `GlobalNavHub`, `InventoryView`, `TacticalFleetLoader`, fleet/loadout systems. Title data flows: PlayFab → `CelestialRegistryClient` (fallback mirror `Assets/GameData/Celestial/seed.json`).

## Traps
- Legacy v1 fields in profile: `activeShipID`, `draftEquippedParts` — don't extend, migrate.
- `stackableInventory` refactor pending (Phase 1 note); facility tier migration Phase 6.8.
- Hardcoded local catalogs (Resource/Item/Recipe/Anomaly) are BRIDGEs until title-data export lands ([[code_map_schemas_editor]]).
- Double-Schema rule: player instances store `ModuleID + ResearchValue + Checksum` only; stats recomputed server-side via `Lerp(min, max, quality/12345)` — never persist computed stats.
- Legacy `"PACT"` faction strings normalized to `"FED"` on read via `Common/FactionId.cs`.
