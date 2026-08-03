# Schema-Driven Authoring Pipelines — Overview

Every piece of gameplay content in Apex Outlaw — base parts, ships, weapons, modules, recipes, resources, containers, contracts, celestial bodies — follows the same six-stage authoring pipeline. This doc explains the pattern; the per-content-type docs in this folder spell out the specifics.

This is the canonical project rule (see [`../../CLAUDE.md`](../../CLAUDE.md) "Hard Rules — Do"). Don't author content ad-hoc. Don't bake inline data. Don't bypass the schema.

---

## The Six Stages

### 1. Schema (the data record)
A `ScriptableObject` class under `Assets/Scripts/Schemas/`. One schema class per content **family** (e.g. `WeaponSchema` for all weapons, `FacilityModuleSchema` for all base modules). One **instance** asset per content item, stored under `Assets/GameData/<Category>/`.

The schema is the single source of truth for the content's data. Everything else (UI, runtime, persistence) reads through it.

### 2. Setup Script (the asset baker)
A one-shot editor script that turns raw inputs (FBX, textures, etc.) into a ready-to-use prefab + schema asset. Lives under `Assets/Editor/` with a `[MenuItem]` so it can be re-run. Idempotent — re-running resets the prefab and schema to the authored state (so don't hand-tune in the inspector and expect changes to survive).

Per-content-family helpers (e.g. `BasePartSetupHelpers` for base parts) factor out the common moves: FBX import config, URP material creation, per-child component installation, etc. The per-asset setup script is then thin — ~20 lines.

### 3. Auto-Discovery Catalog (runtime collection)
Every system that needs to enumerate the content (build menu, market browser, fleet selector) discovers schemas via `AssetDatabase.FindAssets($"t:{nameof(Schema)}")` (editor) or an Addressables label query (build). Never hand-maintained lists.

If a content type needs to be filtered (e.g. only Conduit-prefixed connectors show in the build menu), the filter lives at the catalog level, not at the consumer.

### 4. UI Consumes the Catalog
UI surfaces (build panel, inspect panel, market browser) read **exclusively** from the catalog. They never know about specific instances — they iterate, filter by schema fields, and render generically.

When a new instance is authored, it shows up in the UI automatically. No UI code changes for new content.

### 5. Runtime Reads the Schema
Combat, economy, build pipeline, etc., always look up properties via the schema reference held on the placed/equipped instance. Stats are recomputed server-side from the schema (Double-Schema rule). Client never assumes values.

### 6. Per-Pipeline Design Doc
Every content family gets a `Design_Documents/pipelines/pipeline_<family>.md` that documents:
- Where the schema lives
- Required + optional fields on the schema
- Folder layout for instance assets
- Setup script template / shared helpers used
- Where instances appear in the UI
- Runtime systems that consume the schema
- Authoring checklist for adding a new instance

A new content family requires the doc before code. A new instance requires the doc to be followed.

---

## Why This Pattern

- **Discoverability** — Anyone can grep for `t:WeaponSchema` to find every weapon, every consumer of weapon data.
- **No drift** — UI / runtime can't get out of sync with the data because they read from the same source.
- **Easy onboarding** — One doc per content type, one shape across all of them.
- **Cheap iteration** — Add a new asset → it shows up everywhere automatically.
- **Server authority** — Schemas baked into the build can't be tampered with by the client.

---

## Pipeline Index

| Pipeline | Schema(s) | Status | Doc |
|---|---|---|---|
| **Base parts** (chassis / connectors / modules / armor) | `BaseChassisSchema`, `BaseConnectorSchema`, `FacilityModuleSchema`, `ArmorSchema` | **Live (T1)** | [`pipeline_base.md`](pipeline_base.md) |
| **Surface tiles** (foundation / wall / ceiling / ramp on 4 m grid) | `BaseTileSchema` | **Authoring (Phase 6.9.A.tile)** | [`pipeline_surface_tile.md`](pipeline_surface_tile.md) |
| **Ships** (parts → assembled ship → derive-at-spawn) | `ShipPartSchema`, `ShipSchema` | **Live (local path)** — Fusion-loader convergence + `ShipHullData` retirement pending | [`pipeline_ship.md`](pipeline_ship.md) |
| **Weapons** (combat armaments + ammo) | `WeaponSchema`, `AmmunitionSchema` | Partial | [`pipeline_weapon.md`](pipeline_weapon.md) |
| **Recipes** (refining / fabrication) | `RecipeSchema` | **Live (Slice 2)** | [`pipeline_recipe.md`](pipeline_recipe.md) |
| **Resources** (raws + refined materials) | `ResourceSchema` | **Live (33 assets)** | [`pipeline_resource.md`](pipeline_resource.md) |
| **Resource cards** (periodic-table icons) | `ResourceSchema` (extended) | **Live** | [`pipeline_resource_card.md`](pipeline_resource_card.md) |
| **Containers** (inventory slices) | `ContainerInstance` + helpers | **Live (Slice 1)** | [`pipeline_container.md`](pipeline_container.md) |
| **Contracts** (freight + future hauler jobs) | `Contract`, `CargoManifest`, `HaulerProfile` | Proposed | [`pipeline_contract.md`](pipeline_contract.md) |
| **Celestial** (bodies + POIs + jump gates) | `CelestialRegistry` JSON (mirror) | **Live** | [`pipeline_celestial.md`](pipeline_celestial.md) |
| **Modules — utility / hacking** (mining laser, scanners, taps) | `UtilityModuleSchema` | Proposed | (folded into ship pipeline for now) |
| **Terrain themes** (ground-base planet visuals — *Landscape* substrate, existing) | `TerrainThemeSchema` | **Authoring (Phase 6.8.A)** | [`pipeline_terrain.md`](pipeline_terrain.md) |
| **Planet generation** (full *Terrain* planet — shape + biomes + ocean + sky) | baked heightmap + `PlanetAridonBuilder` (reference) | **Authoring (Aridon)** | [`pipeline_planet.md`](pipeline_planet.md) |
| **Crosshairs** (cursor / aim reticle states) | `CrosshairSchema` | **Authoring** | [`pipeline_crosshair.md`](pipeline_crosshair.md) |
| **Biome zones** (lat/lon surface regions → visuals + resource signature) | `BiomeZoneSchema` | Proposed | [`pipeline_biome.md`](pipeline_biome.md) |

**Status legend**
- **Live** — pipeline is fully wired, instances exist, UI/runtime consumes them
- **Partial** — schema exists and some instances authored, but one or more pipeline stages still ad-hoc
- **Proposed** — pipeline designed in canon docs but not yet implemented

---

## When to add a new pipeline

A new pipeline is justified when:
1. The content family has **its own schema class** distinct from existing ones (different fields, different consumers, different setup needs)
2. There will be **multiple instances** of that content type (one-off content doesn't need a pipeline)
3. The content has **runtime consumers** beyond just appearing in a menu (combat, economy, persistence, etc.)

If a new content item fits an existing schema family, **don't make a new pipeline** — author the instance under the existing one.

---

## When to update an existing pipeline doc

- A new field is added to the schema → update the field reference table
- The setup script template changes → update the template + checklist
- A new UI surface starts consuming the catalog → add it to the "UI consumers" list
- A new runtime system starts consuming the schema → add it to the "Runtime consumers" list

Pipeline docs are living references — keep them current as the implementation evolves.
