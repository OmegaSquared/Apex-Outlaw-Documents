# Ground Base — Category Overview

> **The single home for building a ground base** — the supply chain, the parts catalog, the production tech tree (mine → smelter → refinery → gas plant → lab → **forge** → assembly), wiring, and the build-order gating that ties them together. New category as of 2026-06-04 (pulled out of `progression/` + `meta/`).
>
> **Scope:** *ground* bases — non-capital surface structures placed in the Surface scene (Scene 3). Capital-scale and orbital structures (citadels, heavy shipyards, Aegis shields) live in space (Scene 2) — see [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md). This category is everything you build on the dirt.

## The map — raw commodity → finished part

Everything converges on the **Forge** (the "3D printer" that mints graded parts). The full facility spine, tier ladders, and the derive-don't-draw resolver are canon in [`progression_production_tree.md`](progression_production_tree.md); this is the orientation:

```
LAYER 0  Extraction       mine metal ore · mine gas · salvage scrap
LAYER 1  Mint             SMELTER       ore → ingots
LAYER 2  Metallurgy       REFINERY      ingots → alloys (steel, ferro-Ti …)
LAYER 2g Gas / Cryo       GAS PLANT     raw gas → ammonia, ion-plasma, cryo
LAYER 3  Synthesis        LAB           alloys + gas-products → super-conductor, composites
LAYER 4  Fabrication  ★   FORGE         materials → GRADED parts   (the 3D printer)
LAYER 5  Assembly         SHIPYARD → hulls   ·   CONSTRUCTION YARD → base modules / conduits
```

- **Recipes** run *inside* a processing facility (Smelter / Refinery / Gas Plant / Lab) and output **materials**; the **Forge** outputs **graded parts**.
- **`buildCost`** is what the Construction Yard drone consumes to erect base modules — a placement-time deduction, not a recipe.
- The **material DAG** (what combines into what) is authored separately in [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md); the production tree doesn't re-list recipes, it gates them by facility.

## Docs in this category

| Doc | Purpose |
|---|---|
| [`progression_base_building.md`](progression_base_building.md) | The module catalog, the unlock tech tree (T1 unlock map), build-cost ladder, freighter-intro bootstrap, the T1 "build a Light Ship" win condition, external armor, and the surface build interaction (floor-peel). |
| [`progression_production_tree.md`](progression_production_tree.md) | The facility-gated production tree (smelter → forge), tier ladders, the `ProductionTreeResolver`, and the "derive the tree, don't draw it" rule. |
| [`ground_base_build_order.md`](ground_base_build_order.md) | **Module build order** — the phased tree (power → … → shipyard), the critical path to the T1 win, and the dependency graph. |
| [`progression_wiring.md`](progression_wiring.md) | Conduit-holders + power-routing wires (Phase 6.12). |
| [`to_do_smelter.md`](to_do_smelter.md) | Smelter session handoff — the one production facility that's **built end-to-end** today. |
| [`ground_base_built_vs_todo.md`](ground_base_built_vs_todo.md) | **Status board:** what's built ✅ vs. still to author ❌ across the whole supply chain. |

## Related canon (other categories)

- [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) — the material recipe DAG the production tree gates.
- [`../world/world_surface_scene.md`](../world/world_surface_scene.md) — the Scene-3 placement model + activity-noise radar stealth bases run under.
- [`../pipelines/pipeline_base.md`](../pipelines/pipeline_base.md) — the authoring pipeline for adding a new base part (chassis / connector / module / armor).
- [`../pipelines/pipeline_surface_tile.md`](../pipelines/pipeline_surface_tile.md) — surface tile authoring.
- [`../meta/master_to_do.md`](../meta/master_to_do.md) — active build tasks (Phase 6.10 = the T1 production spine).

## Where this sits in the build order

Phase **6.10** is the T1 win-condition spine: the player walks the chain from spawn to a working Light Shipyard and queues a Light Ship. See [`progression_base_building.md`](progression_base_building.md) §5.F for the 9-step path and [`progression_production_tree.md`](progression_production_tree.md) §7 for the authoring backlog.
