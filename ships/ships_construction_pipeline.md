---
status: canon (locked with Aaron 2026-07-02)
phase: ship-building
last-reviewed: 2026-07-02
---

# Ship Construction Pipeline — Resources → Parts → Blueprints → Ships

> **Locked decisions (Aaron, 2026-07-02):**
> - The design process **starts with blueprints**. The structural builder scene is renamed
>   **`BlueprintDesign`** (was `ShipBuilder`).
> - A **Parts Construction Lab** turns *discovered* part designs + graded materials into
>   **mountable graded part instances** — the only place quality grades enter the economy.
> - The **Shipyard** marries a blueprint with actual graded parts from inventory to produce a ship.
> - Everything derives from schemas + equipped items downstream (see the schema-driven combat work,
>   2026-07-02): a ship's stats come from the grades of the parts it was built with.

## The chain

```
RESOURCES ──► RESEARCH LAB ──► FABRICATION ─────────────► BLUEPRINT DESIGN ──► SHIPYARD ──► SHIP
 (graded       (discovers       materials → COMPONENTS      (pure geometry,      (blueprint +    (NpcShipRecord:
  materials)    designs)        components → PARTS           no matter)           graded parts)   parts + grades)
```

**Component tier (Aaron, 2026-07-02: "parts need to be broken down too"):** parts are not forged
straight from raw tons — they are ASSEMBLED from fabricated **components** (structural frames,
hull plating, plasma coils, actuators, control circuits, reactor cells — `ComponentSchema`,
`Resources/Schemas/Components`). Grade quality **compounds up the chain**:
material grade → component grade → part grade → ship performance. Every stage's output grade is
the qty-weighted average of its inputs.

### 1. Resources (exists)
Mining/extraction produces **graded material stacks** (21-grade ladder, `GradedStack`). Input
grade matters all the way down — the strategic reason to hold good territory.

### 2. Discovery sources (lore/scanning; partial)
Wreck salvage, scanning, and research unlock **part designs** — schema entries in the player's
catalog. A discovered design is knowledge, not a usable part ("damaged plasma cannon,
unidentified drive section"). Wreck salvage / scanning will FEED the Research Lab (samples,
blueprints fragments); the lab is where the unlock actually happens.

### 3a. Research Lab — THE CRUCIBLE (scene `ResearchLab`; alchemy-combiner model, Aaron 2026-07-02)
**The KNOWLEDGE faucet, as a game.** Place **2–4 ingredients** (materials by the ton, parts/
components by the piece; 4 = exotic max) into the CRUCIBLE and RUN RESEARCH: the ingredients are
**destroyed** (worst grades first — junk becomes science) and, if the combination matches a secret
recipe, a **blueprint** is discovered — a permanent unlock in `PlayerDiscoveryStore`
(`player_discoveries.json`). Bad combinations yield slag (ingredients still lost — experimentation
has real cost). Think mobile-alchemy / Minecraft recipes.

**THE TECH TREE IS BLIND (locked):** nothing anywhere lists what remains undiscovered — only a
count teaser ("N combinations remain…"). Players find recipes by experimenting, rumor, and trade.

**The secret combinations ARE the fabrication data** (no parallel recipe table to maintain):
- materials-only combo == a `ComponentSchema.buildCost` resource TYPE set → discovers that component
  (copper + lithium → Plasma Coil);
- parts/components combo == a design's `ComponentBillFor` TYPE set → discovers that part/module
  (frame + coil → an engine-family blueprint — multiple matches pick RANDOM among the undiscovered,
  so repeating a combo finds the siblings).
Quantities don't matter for matching; each placement costs 1t (material) or ×1 (part instance) —
and the player picks the EXACT GRADE STACK to place (stock rows are per-grade, inventory-style with
periodic element codes and grade badges).

**Quality thresholds (Aaron 2026-07-02: "a rare object requires grade A materials"):**
`minimumGradeRequired` on ItemSchema (components/modules) and ShipPartSchema — EVERY ingredient in
the crucible must meet the output's threshold or the run fails with a "too crude" hint (ingredients
still lost). Example authored: Reactor Cell demands grade A. The same field will gate fabrication.

**Run outcomes (all as popups):** ✦ BLUEPRINT DISCOVERED (consume) · THE MIXTURE RESISTS — right
combo, grades too low (consume, hints quality) · NOTHING NEW — combo only matches known blueprints
(**ingredients returned, never wasted**) · RESEARCH FAILED — slag (consume).

**Blueprint trading (Aaron 2026-07-02, for the Market slice):** known blueprints can be BOUGHT and
SOLD on the market — discovery knowledge is a tradable good (a research-focused playstyle is a
blueprint dealer). Selling never removes your own unlock; buying writes into PlayerDiscoveryStore.

### 3b. Fabrication (scene `Fabrication`, renamed from ConstructionLab 2026-07-02)
**The MATTER faucet (and the grade faucet).** TWO STAGES in one facility (component tier, 2026-07-02):
1. **COMPONENTS ← materials.** Discovered component design + graded material stacks (best first) →
   a graded component instance. Costs authored on `ComponentSchema.buildCost`.
2. **PARTS/MODULES ← components.** Discovered part design + graded component instances (best first)
   → a mountable graded part: `{itemID, grade}` — the exact `PartInstance` / `AssembledPartTag`
   shape combat resolves. Bills authored on `ShipPartSchema.componentCost`, else the explicit
   class/mass rule in `FabricationController.ComponentBillFor`.

Output families:
- **Components** (frames, plating, coils, actuators, circuits, reactor cells) — consumed by part assembly.
- **Structural parts** (hulls, wings, drive sections, thrusters…) — consumed by Shipyard assembly.
- **Fitted modules** (weapons, shields, sensors, power cores, engines) — mounted on hardpoints.

Output grade derives from **input material grades + lab/facility tier** (alchemy-band model;
`RecipeSchema` already reserves `Fabrication` recipes and Module outputs minting via
`ForgePartInstance` — the lab is the UI over that machinery). Offline-first storage:
`persistentDataPath/player_parts.json` (`PlayerPartsStore`), mirroring the PlayFab
`PlayerProfile.moduleInventory` shape (same `PartInstance` fields; CloudScript `ForgePartInstance`
is the canonical online mint).

**Material feed (real, 2026-07-02):** costs come from authored `ShipPartSchema.buildCost`, else the
explicit mass-based iron rule (`FabricationController.CostFor` — tracked to tighten); consumption is
all-or-nothing from `PlayerMaterialsStore` (`player_materials.json`, `GradedStack` shape), BEST
stacks first; output grade = qty-weighted average of the inputs. A DEV GRANT button seeds test
materials until the mining drop-off writes into the store (tracked bridge).

### 4. Blueprint Design (scene `BlueprintDesign`, renamed from `ShipBuilder`)
**Pure geometry — knowledge, not matter.** Arrange part *types* (never instances), validate the
build rules (≥1 engine, thruster minimums, power budget vs. the midframe's single core slot).
Saving yields the part layout + derived hardpoints — effectively a **bill of materials**:
"needs 2× wing engine, 6× medium thruster, 1× medium core; provides 3 weapon hardpoints."
Blueprints carry **no grad