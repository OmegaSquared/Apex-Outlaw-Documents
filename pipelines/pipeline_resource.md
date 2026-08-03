# Resource Pipeline

**Status: Live (33 assets)** — schema, all Tier-1 raws + Tier-2 refined outputs authored, mass-per-unit field added, container math + recipe pipeline both consume from it. One of the simplest pipelines in the project.

**Schema:** [`ResourceSchema`](../../Assets/Scripts/Schemas/ResourceSchema.cs) — `resourceID`, `displayName`, `description`, `icon` (legacy, see card pipeline), `massPerUnitKg`, `phase` (`Solid`/`Liquid`/`Gas`), `miningTier` (0–4), plus card-pipeline fields (`chemicalSymbol`, `atomicNumber`, `cardKind`, `iconOverride`). **Incoming (master_to_do 6.9.I.0): `materialClass` (`Graded`/`Bulk`)** — Graded raws carry a scanned grade; Bulk (granite, regolith, water, scrap) are ungraded tonnage. No setup script needed beyond `Create → Apex Outlaw → Schemas → Resource Schema` in the project window. *(Prior versions of this line listed removed `tier`/`vein` fields — corrected 2026-06-07.)*

**Icon rendering:** procedurally-rendered periodic-table cards via [`pipeline_resource_card.md`](pipeline_resource_card.md). No per-resource sprite authoring needed — every schema auto-renders as a card with its chemical symbol + atomic number, with phase-colored background and ingot/compound variants.

**Storage:** `Assets/Resources/Schemas/Resources/` for instance assets (loaded via `ResourceCatalogLoader`).

**Pipeline shape (already live):**
1. Right-click in folder → Create → Resource Schema
2. Fill in fields per canon (Tier 1 raws are flat-mass / no recipe-inputs; Tier 2 refined have a corresponding RecipeSchema)
3. `ResourceCatalogLoader` auto-discovers
4. Used by: container mass-cap math, recipe inputs/outputs, market listings, mining yield, scanner highlighting, NPC arbitrage stock levels

**Gaps to address when filling in this doc:**
- Same title-data export bridge as recipes (CloudScript can't read ScriptableObjects directly, uses `DEFAULT_RESOURCE_MASS_PER_UNIT_KG = 1.0` fallback for server-side mass-cap checks)
- 2D icons now solved via [periodic card pipeline](pipeline_resource_card.md) — no per-resource sprite authoring needed
- No 3D model authoring for "raw resource pile" / "refined block" visual representation in cargo bays

**Canon:** [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) (canonical list of every resource, tier ladder, vein assignment).

**Author this pipeline doc fully when:** Tier-3+ resources are authored, OR a 3D representation pass happens, OR the title-data export bridge ships.
