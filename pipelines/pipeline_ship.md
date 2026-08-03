---
status: active
phase: 6.9
last-reviewed: 2026-07-14
---

# Ship Pipeline — discover, forge, design, build, derive everything at spawn

**Status: Live end-to-end** (Aaron 2026-07-14 review). The schema-driven manufacturing
pipeline is implemented and flying via `NpcShipSpawner`, and as of 2026-07-14 the loop
closed at both ends: DISCOVERY now gates every fabricable part (crucible combos + reverse
engineering), and persistence for ships/blueprints/fleet-groups moved to **PlayFab UserData**
(`PlayerCloudStore`) — the local-JSON bridge is retired for those stores.

## The data flow (as built, 2026-07-14)

```
DISCOVER   crucible combos (component bill = the secret recipe) or reverse engineering
           (destroy a part; Maker's Mark rules) → PlayerDiscoveryStore
MINE       drones cut rock / siphon pockets → MiningCargoLedger routes GAS vs PHYSICAL
           into the ship's fitted internal containers (overflow is LOST)
FORGE      Fabrication consumes components → {itemID, grade} parts (PlayerPartsStore),
           discovery-gated; uniqueIrreplaceable (ZR7) never fabricable
DESIGN     BlueprintDesign: geometry + INTERNAL BAYS loadout (shields/drones/containers)
           + REACTOR/BATTERY special slots → ShipBlueprint (checksummed, cloud-saved)
BUILD      Shipyard: blueprint + forged instances (best grade first, BOM-gated)
           → NpcShipRecord (parts + per-part grade + weapons + stowed internals)
SYNC       PlayerCloudStore ⇄ PlayFab UserData (ship_<id> / bp_<id> / fleet_groups keys,
           pull-on-login, push-on-change, offline queue)
SPAWN      NpcShipSpawner.Spawn(record) derives ALL stats from schemas at forged grade
```

Nothing gameplay-relevant is stored on the record except **which parts, at which grade**.
Stats recompute at spawn — a Flawless engine genuinely outperforms an F-grade one, and a
hull with no engine part *does not move* (visible, honest, no fallback).

## Stage-by-stage state

| Stage | Implementation | State |
|---|---|---|
| **1. Schema** | [`ShipPartSchema`](../../Assets/Scripts/Schemas/ShipPartSchema.cs): prefab, engine/powerCore/sensor profile ids, per-grade stats, `componentCost` (= fabrication bill AND crucible recipe). 2026-07-14 additions: `ShipPartClass.Drone/Reactor/Battery`, `DroneRole`, `uniqueIrreplaceable`, `gasCapacityKg`, `batteryCapacityMJ`, `FittingSocketClass.Internal/Reactor/Battery`. | ✅ clean |
| **2. Discovery** | Research Lab crucible (type-set match against component bills) + REVERSE ENGINEER panel (unmarked = 1 part; marked+intact = refused; marked+severed = 5 samples via `PlayerDiscoveryStore.reProgress`). ZR7 excluded everywhere. | ✅ works |
| **3. Forge** | Fabrication consumes components → `PlayerPartsStore` `{itemID, grade}`; discovery-gated; skips `uniqueIrreplaceable`. | ✅ works |
| **4. Catalog** | [`ShipPartCatalog`](../../Assets/Scripts/Macro/Fleet/ShipPartCatalog.cs) — auto-discovery, `ByID`/`OfClass`. Drone spawners (ZR7 pilot, construction fleet, CB11 miners) resolve prefabs through it. | ✅ clean |
| **5. Design UI** | BlueprintDesign palette + INTERNAL BAYS strip (⊕/✓ squares, amber REACTOR/BATTERY specials, size-gated pickers). Loadout + specials save into `ShipBlueprint.internals/reactorID/batteryID`, checksummed. | ✅ works |
| **6. Build** | Shipyard `BuildRecordFromFitting`: structural parts + attach tree + stowed internals (drones/containers/reactor/battery as record parts; internal shields as INTERNAL_BAY mounts); consumes forged instances. | ✅ works |
| **7. Sync** | [`PlayerCloudStore`](../../Assets/Scripts/Networking/PlayerCloudStore.cs) → PlayFab UserData. Hydrates at login from the profile's own GetUserData round-trip. | ✅ ships/blueprints/fleet-groups |
| **8. Runtime** | [`NpcShipSpawner`](../../Assets/Scripts/Tactical/NpcShipSpawner.cs): `AssembleParts` (skips stowed internals), `DeriveFlightStatsFromParts`, `DerivePowerFromParts` (fitted REACTOR/BATTERY override the hull core: battery→pool, reactor→rail MW + recharge), `ResolveWeaponMounts`, `AttachShieldEnvelope` (STACKS every shield's HP into one envelope). Mining launches stowed `drone_miner_cb11` (tier from grade). | ✅ schema-driven, derive-at-spawn |
| **9. Doc** | this file. | ✅ 2026-07-14 |

The canonical assembler is **`NpcShipSpawner`** — CombatSandbox, MiningSandbox, and the
Vesperion macro handoff all fly records through it.

## Stores

**Cloud (PlayFab UserData via `PlayerCloudStore`, 2026-07-14):**
- ships (`ship_<recordId>`), blueprints (`bp_<blueprintID>`), fleet groups (`fleet_groups`).

**Still local JSON (PlayFab-shaped, migration candidates — same pattern applies):**
- `PlayerPartsStore` → `player_parts.json` — forged `{itemID, grade}` inventory.
- `PlayerMaterialsStore` → `player_materials.json`.
- `MiningCargoLedger` → `player_mining_cargo.json` (now with gas/physical pools + capacities).
- `PlayerDiscoveryStore` → `player_discoveries.json` (+ RE sample progress).
- `NpcShipRegistry` → `npc_ships.json` — admin/NPC ships.

> NOTE (dev workflow): blueprints are cloud-only now — playing a scene directly in the
> editor without a login shows an empty blueprint list.

## Remaining gaps (tracked — `meta/master_to_do.md` Pipeline Hardening)

1. **Converge spawn paths.** Legacy Fusion loader `TacticalFleetLoader.GetModuleResourcePath`
   still resolves module visuals by name string-matching to hardcoded Addressable keys and
   munges hull ids. Route through the catalog like `NpcShipSpawner`, or delegate wholesale.
2. **Retire legacy `ShipHullData`.** Superseded by `ShipSchema` + `ShipPartSchema`;
   `Smuggler_Frigate_Data.asset` loads null. Deprecate + remove references.
3. **Thruster name smell.** `NpcShipSpawner` classifies thrusters via
   `partID.Contains("thruster")` — replace with a schema-explicit propulsion kind.
4. **Baked vitality.** Armor/shield/AI-range still read the record's `baked*` fields;
   derive from parts like flight + power, then drop `baked*`.
5. **Cloud-migrate the remaining stores** (parts, materials, mining cargo, discoveries)
   onto the `PlayerCloudStore` pattern.
6. **Reactor/battery grade curves.** Flat authored values today (150/500/1050 MW,
   300/1000/2100 MJ); per-grade curves needed before "hard to upgrade" is mechanical.
   Combat salvage must also start setting `PartInstance.severed` for the 5-sample RE path.
7. **Internal-picker discovery gate.** The designer's bay picker lists all internal
   components regardless of discovery (dev convenience) — gate before alpha testers.

## See also

- [`../ships/ships_construction_pipeline.md`](../ships/ships_construction_pipeline.md) — resources → parts → blueprints → ships (canon)
- [`../ships/ships_manufacturing.md`](../ships/ships_manufacturing.md) — manufacturing model + 2026-07-14 canon: parts ARE the blueprint market, dormant blueprints, Maker's Mark RE rules, internal bays
- [`../ships/ships_fleet_management.md`](../ships/ships_fleet_management.md) — grouping built ships into fleets
- [`pipeline_weapon.md`](pipeline_weapon.md) — the fitted-weapon side
- [`pipelines_overview.md`](pipelines_overview.md) — the six-stage pattern
