# CloudScript — Currently Deployed (PlayFab)

This document tracks the CloudScript revision currently Live in the PlayFab GameManager for this title. The **source of truth** for handler code is the per-file sources under [`cloudscript/`](../../cloudscript/); the deployable bundle is auto-generated at [`cloudscript/_deploy_bundle.js`](../../cloudscript/_deploy_bundle.js).

> **Phase 6.9 CloudScript domains (planned, not yet deployed):**
> - `cloudscript/server_fow_matcher.js` (Phase 6.9.F) — Wide-FOW encounter prediction + `NetworkRunner` spawn matching per body. Adaptive cron, 15s baseline, ramps to 1s when fleets are converging.
> - `cloudscript/planet_surface_permits.js` (Phase 6.9.D) — `PlanetSurfacePermitCheck` handler. Validates Low Orbit → Surface drop eligibility: owns base / allied / defenses defeated.
> - `cloudscript/celestial_surface_bases.js` (existing, extended in Phase 6.9.A) — `BuildSurfaceBase`/`DemolishSurfaceBase` already use lat/lon; extend with first-base heightmap bake for the body.
> - `cloudscript/orbital_structures.js` (Phase 6.9.C) — `BuildOrbitalStructure` for satcom, citadels, docks, planetary defense, ring stations. Alliance-permission-gated.
>
> Canon: [`architecture_overview.md`](./architecture_overview.md), [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md), [`../world/world_surface_scene.md`](../world/world_surface_scene.md).

## Bundle rule

PlayFab CloudScript revisions are **namespace-level, not file-level** — uploading one file replaces every handler. We deploy a single concatenated bundle containing every per-file source in alphabetical order.

**Update protocol — every time a new CloudScript revision is deployed:**

1. Edit the per-file source under `cloudscript/<file>.js`.
2. Rebuild the bundle: **Apex Outlaw → CloudScript → Rebuild Deploy Bundle** (or call `RebuildCloudScriptBundle.Execute` from a script). Auto-generates `cloudscript/_deploy_bundle.js` from every `cloudscript/*.js` source except files starting with `_`.
3. Upload the bundle in PlayFab GameManager → Automation → CloudScript → Revisions → Upload New Revision → Save → Deploy Revision.
4. **Append a new row to the revision history below** noting which handlers shipped + verification status.
5. Commit the per-file edits + the regenerated `_deploy_bundle.js` + this doc together.

If a revision goes Live without updating this doc, the doc is stale — the per-file sources under `cloudscript/` are still authoritative.

---

## Currently live: revision 18 (deployed 2026-07-22)

### Handlers exposed by the bundle

| Handler | Source file | Authority | Storage written |
|---|---|---|---|
| `AdminSetGateBubble` | [`celestial_admin.js`](../../cloudscript/celestial_admin.js) | PlayFab Player Tag `"admin"` | `TitleInternalData["CelestialRegistry"]` |
| `AllianceConstructPOI` | [`celestial_alliance_pois.js`](../../cloudscript/celestial_alliance_pois.js) | Alliance officer rank + planet ownership | `TitleInternalData["CelestialRegistry"]` |
| `AllianceDemolishPOI` | [`celestial_alliance_pois.js`](../../cloudscript/celestial_alliance_pois.js) | Alliance officer rank + POI ownership | `TitleInternalData["CelestialRegistry"]` |
| `BuildSurfaceBase` | [`celestial_surface_bases.js`](../../cloudscript/celestial_surface_bases.js) | Alliance officer rank + planet ownership + slot spacing | `TitleInternalData["CelestialRegistry"]` |
| `DemolishSurfaceBase` | [`celestial_surface_bases.js`](../../cloudscript/celestial_surface_bases.js) | Owner-of-record | `TitleInternalData["CelestialRegistry"]` |
| `ForgePartInstance` | [`forge.js`](../../cloudscript/forge.js) | Self only — caller becomes the Maker's Mark | `UserData["Profile"]` |
| `InventoryReadOwn` / `InventoryListOwn` / `InventoryInsert` / `InventoryExtract` / `InventoryMove` | [`inventory.js`](../../cloudscript/inventory.js) | Self only; container-ownership + mass-cap enforcement | `UserData["Profile"]` |
| `PlayerEnsureHomeLocation` | [`player_home_location.js`](../../cloudscript/player_home_location.js) | Self only; idempotent first-login default (Helion / `Planet_rubicon` as of rev 11) | `PlayerReadOnlyData["homeBasePlanetBodyId"]` + `["currentSolarSystemId"]` |
| `PlayerEnsurePlayerNumber` | [`player_number.js`](../../cloudscript/player_number.js) | Self only; idempotent sequential number grant | `TitleInternalData` counter + `PlayerReadOnlyData["playerNumber"]` |
| `AdminSaveNpcShip` / `GetNpcShipRegistry` | [`npc_ships.js`](../../cloudscript/npc_ships.js) | Save: PlayFab Player Tag `"admin"`; Get: any caller | `TitleData["NpcShipRegistry"]` |
| `PlayerSetSector` | [`player_sector_fleet.js`](../../cloudscript/player_sector_fleet.js) | Self only; destination validated vs celestial registry + whitelist | `PlayerReadOnlyData["currentSectorId"]` |
| `PlayerSaveFleetGroups` | [`player_sector_fleet.js`](../../cloudscript/player_sector_fleet.js) | Self only; ship ownership, one-fleet-per-ship, mass cap, dockable whitelist, bounded coords — clean doc rebuilt | `PlayerReadOnlyData["fleet_groups"]` (+ deletes legacy UserData copy) |
| `PlayerSaveShip` | [`player_sector_fleet.js`](../../cloudscript/player_sector_fleet.js) | Self only; structural validation (size/parts/weapons caps, plausible mass, bounded stats, id regex) | `PlayerReadOnlyData["ship_<id>"]` (+ deletes legacy UserData copy) |
| `PlayerDeleteShip` | [`player_sector_fleet.js`](../../cloudscript/player_sector_fleet.js) | Self only | Removes `ship_<id>` from both stores |
| `RunRecipe` | [`recipes.js`](../../cloudscript/recipes.js) | Self only; facility-tier gate + mass-cap; mints via forge.js primitive | `UserData["Profile"]` |
| `ResolveMaterialAnchors` | [`scanning.js`](../../cloudscript/scanning.js) | Self only; read-only (consults caller's `alchemySeed` + `maxDiscoveredGoods`) | None — pure compute, returns anchor indices |

### Where to read the actual deployed source

Open [`cloudscript/_deploy_bundle.js`](../../cloudscript/_deploy_bundle.js) — that file IS the deployed text (it's regenerated by step 2 above). Per-file sources under `cloudscript/<file>.js` are the canonical edit surface; the bundle is generated, not hand-maintained.

---

## Revision history

| Rev | Date | Bundle commit | Handlers added/changed | Verification |
|---|---|---|---|---|
| 1 | (pre-existing) | n/a | PlayFab default "Hello World" template. | n/a |
| 2 | 2026-05-04 | (lost) | `player_home_base.js` only. **Mistake.** Single-file upload silently dropped the celestial handlers; `AdminSetGateBubble`, `AllianceConstructPOI`, `AllianceDemolishPOI` were not live this revision. | n/a |
| 3 | 2026-05-04 | (commit landing rev-3) | Full bundle: `celestial_admin.js` + `celestial_alliance_pois.js` + `player_home_base.js`. Restored celestial handlers; first use of `_deploy_bundle.js` workflow. | (manual) |
| 4 | (undocumented) | (lost) | Intermediate deploy — protocol drifted; doc not updated. Likely added `celestial_surface_bases.js`, `forge.js`, `inventory.js`, `recipes.js`, and renamed `player_home_base.js` → `player_home_location.js`. | n/a |
| 5 | (undocumented) | (lost) | Intermediate deploy — protocol drifted; doc not updated. State of the bundle at this point matches the per-file sources committed before 2026-05-16. | n/a |
| 6 | 2026-05-16 | (commit landing Phase 3 schemas) | Adds `scanning.js` (`EnterAsteroidInstance`, `ExitAsteroidInstance`, `ScanResourceAnomaly`, `FrequencyLockAnomaly`), `beacons.js` (`DeployBeacon`, `RetrieveBeacon`, `ListBeaconsInBody`), `mining.js` (`ApplyExtractionTick`); `recipes.js` gets `recipe_telemetry_beacon`; `inventory.js` extends mass helpers with graded-stack support. | Smoke test: `EnterAsteroidInstance` → ok, `ScanResourceAnomaly` → ok (gradeHint=Refined, intensity=0.35), `FrequencyLockAnomaly` → null payload (server-side `freq` ReferenceError — fixed in rev 7), `ExitAsteroidInstance` → ok. |
| 7 | 2026-05-16 | (this commit) | Fixes `FrequencyLockAnomaly` `ReferenceError: freq is not defined` (`lockedFrequency: freq` → `lockedFrequency: freqBucket / 1000`). No other changes. | **Full end-to-end smoke test passed.** `EnterAsteroidInstance` → ok, `ScanResourceAnomaly` → ok (gradeHint=Standard, intensity=0.25), `FrequencyLockAnomaly` → ok (grade=15 / Standard / C, `improvedRecord=true` first-time stamp on `maxDiscoveredGoods.iron`), `ExitAsteroidInstance` → ok. Harness: [`Assets/Editor/Debug/ScanningHandlerFireAndLog.cs`](../../Assets/Editor/Debug/ScanningHandlerFireAndLog.cs). |
| 8 | 2026-05-17 | (this commit) | **Resource Scanner pivot.** `scanning.js` rewritten: removes `EnterAsteroidInstance` / `ExitAsteroidInstance` / `ScanResourceAnomaly` / `FrequencyLockAnomaly`; adds `ResolveMaterialAnchors(materialId, beltSeed, virtualCount)` — read-only deterministic anchor picker that returns up to 50 belt indices per material per `(alchemySeed, materialId, beltSeed, index)`. Deletes `beacons.js` (`DeployBeacon` / `RetrieveBeacon` / `ListBeaconsInBody`) and `mining.js` (`ApplyExtractionTick`) entirely — the deployable-beacon + mining-tick UX was demolished in the pivot. 9 prior handlers unchanged. | **Smoke-tested in Vesperion editor play session.** Toggle "iron" in right-side scanner panel → ~50 markers flash on belt rocks at deterministic anchor positions. Other 5 materials (carbon / silicates / titanium / helium3 / platinum) toggle independently. |
| 9–10 | (undocumented) | (lost) | Intermediate deploys — protocol drifted; doc not updated. Likely added `npc_ships.js` (`AdminSaveNpcShip` / `GetNpcShipRegistry`, source dated 2026-06-29). | n/a |
| 11 | 2026-07-19 | (this commit) | Adds `player_number.js` (`PlayerEnsurePlayerNumber` — sequential player numbers, #1 = root admin; counter in `TitleInternalData["nextPlayerNumber"]`, number in `PlayerReadOnlyData["playerNumber"]`); `player_home_location.js` updated with the Helion home default (`currentSolarSystemId=Helion`, `homeBasePlanetBodyId=Planet_rubicon`). Full 10-file bundle (101,709 bytes). **First deploy via the new `CloudScriptDeployer` menu item** (Apex Outlaw → CloudScript → Push Revision) — replaces the manual GameManager paste. | Upload + publish confirmed in Editor.log (`revision 11, published=True`). End-to-end smoke test pending: DB wipe → re-register should land player #000001 with the Helion/Rubicon home. |
| 12–16 | (undocumented) | (lost) | Intermediate deploys — protocol drifted; doc not updated. | n/a |
| 17 | 2026-07-21 | (commit landing α1.1/α1.3) | Adds `player_sector_fleet.js`: `PlayerSetSector` (server-owned `currentSectorId` in ReadOnlyData, registry+whitelist validation) and `PlayerSaveFleetGroups` (validated fleet-state write to ReadOnlyData, legacy key deleted). First server-authoritative world slice. | **Live-verified on the real title:** `SetSector(Moon_alea)` ok; `SetSector(Planet_hackerville)` rejected "unknown location"; tampered fleet doc rejected ("ship 'not_my_ship_123' is not owned by the caller"); legit save landed in ReadOnlyData (428 chars) with legacy key deleted; fresh login hydrated 2 groups from RO, sector=Planet_rubicon. |
| 18 | 2026-07-22 | (this commit) | α1.2 ship-record validation: `player_sector_fleet.js` gains `PlayerSaveShip` / `PlayerDeleteShip` (ship_<id> records migrate to ReadOnlyData behind structural validation; original JSON written through) and `plfOwnedShips` (fleet validation now scans BOTH data stores so the migration window can't break fleet saves). Client: `PlayerCloudStore` reroutes ship push/remove + offline flush through the handlers; `PlayFabManager` login fetches the whole ReadOnly store and RO records win on hydrate. | **Live-verified on the real title:** valid `PlayerSaveShip` → ok + RO `ship_probe_alpha_ship` present; tampered mass 1e12 rejected ("implausible mass"); `PlayerDeleteShip` → RO key gone; real ship record migrated (legacy=0, readonly=1); `PlayerSaveFleetGroups` passed both pre- and post-migration (fleets:2). |
