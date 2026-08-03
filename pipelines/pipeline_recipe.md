# Recipe Pipeline

**Status: Live (Slice 2)** — schema, 14 instance assets, CloudScript handler, UI, and dev-seed migration all shipped. This is one of the more complete pipelines in the project; a full pipeline doc would mostly be retroactive documentation of what's already in place.

**Schemas:** [`RecipeSchema`](../../Assets/Scripts/Schemas/RecipeSchema.cs) (refining + fabrication recipes — Iron → Steel, Titanium → Ferro-Titanium, etc.) + [`FacilityType`](../../Assets/Scripts/Schemas/FacilityType.cs) enum (Smelter / Lab / Shipyard / Refinery / Miner / …).

**Storage:** `Assets/Resources/Schemas/Recipes/` for instance assets (loaded via `RecipeCatalogLoader`).

**Pipeline shape (already live):**
1. Author `RecipeSchema` asset with inputs (List of `RecipeInput` = ResourceSchema ref + qty), output (single ResourceSchema + qty), `facilityType`, `tier`, build time
2. Drop into `Assets/Resources/Schemas/Recipes/`
3. `RecipeCatalogLoader` auto-discovers
4. `ForgePanel` UI lists all recipes, greys ones whose facility-tier isn't met
5. Player clicks "Run" → `RecipeClient.RunRecipe()` → CloudScript `RunRecipe` handler validates inputs + facility-tier + mass-cap, mints output

**Gaps to address when filling in this doc:**
- The CloudScript-side `RECIPE_CATALOG` is currently a hardcoded JS mirror (BRIDGE) — title-data export pipeline from ScriptableObjects to PlayFab title data hasn't shipped
- Facility-tier source is currently `PlayerProfile.refineryLevel`/`labLevel`/`minerLevel` flat fields (Slice 2 stopgap) — switches to per-base installed-facility scanning when Phase 6.8 base-building lands
- No per-recipe artwork / UI thumbnail authoring yet (recipes render text-only)

**Canon:** [`../economy/economy_overview.md`](../economy/economy_overview.md) "Slice 2 Recipes & Refining" + [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md).

**Author this pipeline doc fully when:** any new authoring pass on recipes goes in (Tier-3 chains, late-game advanced recipes, ship-construction recipes). For now the canon docs cover the design and the implementation matches.
