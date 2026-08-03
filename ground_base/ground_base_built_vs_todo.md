# Ground Base — Built vs. To-Build

> **Status board for the ground-base supply chain.** This is a *curated snapshot* — the **live source of truth** for "what's authored" is the ScriptableObject catalog (`Assets/GameData/Bases/…` + `Assets/Resources/Schemas/Recipes/…`), auto-discovered by the build UI. This doc tracks the chain at a glance and links each item to its canon. Reconciled 2026-06-04 from [`progression_production_tree.md`](progression_production_tree.md) §2, [`progression_base_building.md`](progression_base_building.md) §5, and [`to_do_smelter.md`](to_do_smelter.md).

## Production chain — facility by facility

| Layer | Facility | Status | Notes / canon |
|---|---|---|---|
| Mint | **Smelter T1** | ✅ built end-to-end | Placement/snap, doors, production state machine, visuals, UI, ingot intermediate. [`to_do_smelter.md`](to_do_smelter.md) |
| Metallurgy | **Refinery T1** | ❌ author | Module SO + prefab (reuse the Smelter pattern). The alloy step. [`progression_production_tree.md`](progression_production_tree.md) §7 |
| Gas / Cryo | **Gas Plant T1** | ❌ author | New `FacilityType.GasPlant = 5` + JS mirror; re-point 5 gas recipes Lab→GasPlant. |
| Synthesis | **Foundry Lab T1** | ✅ module SO authored | Recipes gate via `requiredFacility`. |
| Fabrication | **Forge / Component Assembler T1** | ⚠️ shell only | Module SO exists; **zero part-recipes authored** — the printer has no outputs yet (Railgun, reactor, jammer …). |
| Assembly | **Construction Yard** | ✅ authored | Bootstrap industrial module; drone build/stock loop works. |
| Assembly | **Light Shipyard T1** | ✅ module SO authored | T1 win-condition target. |

## Modules & infrastructure

**✅ Built / authored:** Outpost_Starter chassis · Fusion Reactor T1 · Bunk Pod T1 · Bulk Storage T1 · `BaseDroneFleet` build+stock lifecycle · unified crate inventory (`CrateInventoryPanel`) · surface tile builder (stacked levels, floor-peel logic) · themed part sets (Smuggler, Hanger kit) · ~156-SO module pool (pre-consolidation).

**❌ To build / author:**
- **`ProductionTreeResolver`** + `BaseModuleUnlockResolver` (+ CloudScript mirrors) — the unlock/reachability engine. [`progression_production_tree.md`](progression_production_tree.md) §5
- **Tech-tree screen** — browsable UI rendering the resolver.
- **`buildCost` wiring** + `BuildCostValidator` — field reserved, not active. [`progression_base_building.md`](progression_base_building.md) §6
- **Module catalog consolidation** — ~156 SOs → ~25–30 buildable. [`progression_base_building.md`](progression_base_building.md) §4
- **Forge part-recipes** — the first printable parts (own design pass).
- **External armor layer** — designed, deferred to Phase 6.11. [`progression_base_building.md`](progression_base_building.md) §7
- **Wiring build-out** — Phase 6.12. [`progression_wiring.md`](progression_wiring.md)

## Authoring order (Phase 6.10 spine)

Per [`progression_production_tree.md`](progression_production_tree.md) §7, in dependency order: (1) `GasPlant` enum, (2) audit 22 recipes vs. the phase rule, (3) `Refinery_T1` SO + prefab, (4) `GasPlant_T1` SO + prefab, (5) Forge part-recipes, (6) `ProductionTreeResolver` + 3 UI consumers, (7) tech-tree screen, (8) doc reconciliation. Tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md).
