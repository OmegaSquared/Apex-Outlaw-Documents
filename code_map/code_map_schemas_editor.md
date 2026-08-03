---
status: canon
phase: "6.9"
last-reviewed: 2026-06-09
tags: [code-map, pipelines]
---

# Code Map — Schemas & Editor Pipeline (`Assets/Scripts/Schemas/`, `Assets/Editor/`, `Assets/GameData/`)

69 schema .cs files + **336** editor .cs files. The code side of the six-stage content pipeline ([`pipelines/pipelines_overview.md`](../pipelines/pipelines_overview.md) is the design canon — read it first; this map covers where the code lives).

## Schemas (`Assets/Scripts/Schemas/`)
**ScriptableObject families** (all content derives from these):
- `ItemSchema` — base for all items: grade-aware stats via `AnchorCurve`, material requirements, tech gates. Subclasses: `ShipSchema`, `WeaponSchema`, `UtilityModuleSchema` (mining lasers/salvage), `MiningLaserSchema`, `SalvageBeamSchema`, `SensorSchema`, `ThrusterSchema`, `EngineSchema`, `PowerCoreSchema`, `ShieldSchema`, `Missile*Schema` (5), `EWarfareSchema`, `AmmunitionSchema`, `ArmorSchema`, etc.
- Base building: `BaseTileSchema` (4m grid pieces, sockets, stability), `BaseChassisSchema`, `BaseConnectorSchema`, `FacilityModuleSchema`, `ThemeSchema`, `TerrainThemeSchema`.
- World: `SectorSchema`, `SectorBodyDefinition`, `PlanetControlSchema`, `BiomeZoneSchema`, `AsteroidCategorySchema`, `ResourceSchema`, `ResourceAnomalySchema`, `CelestialBodyBaseRoster`.
- Meta: `GradeSchema` — **21-tier ladder, anchors at fixed indices; `GradeSchema.Default` loads `Resources/Schemas/Grades/grade_table_default`** (UI uses `BandFor(grade).shortCode`). `RecipeSchema`, `TechnologySchema`, `FleetSchema`, `CrosshairSchema`.

**Key structs:** `AnchorCurve` (9 anchors F→[Flaw], runtime interpolation, allocation-free), `GradeBand`, `HardpointSlot`, `TileSocket`, `GradedStack`, `CelestialRegistry` (+Parent/Child records — JSON, PlayFab-authoritative).

**Catalog loaders** (static cache-on-first-access via `Resources.LoadAll`, `.Reload()` for editor iteration — **no AssetDatabase at runtime**): `UtilityModuleCatalogLoader`, `RecipeCatalogLoader`, `CrosshairCatalog`, `SectorRegistry` (fallback `"ignis"`), `FleetTierRegistry`, `SectorChainRegistry` (legacy).

**Enums are append-only** (Unity serializes by index): `ShipClass`, `Faction` (v1 affiliation + v2 territorial entries; `Belt` is legacy alias for IronCore), `MenuPlacement` (drives BaseBuildPanel tabs).

## GameData / Resources bake locations
| Path | Contents |
|---|---|
| `Assets/GameData/Bases/{Themes,Chassis,Modules,Connectors}/` | Base-building schema instances |
| `Assets/GameData/Bodies/` | `CelestialBodyBaseRoster` per planet |
| `Assets/GameData/Celestial/seed.json` | CelestialRegistry dev mirror (PlayFab is authority) |
| `Assets/GameData/Sectors/MainChain.asset` | Legacy sector chain |
| `Assets/Resources/Schemas/{Grades,Crosshairs,UtilityModules,Recipes,Sectors,Fleet_Tiers,Anomalies}/` | Runtime-loadable catalogs |

## Editor (`Assets/Editor/`, 336 files — navigate by prefix pattern, don't browse)
| Pattern | What it is |
|---|---|
| `*_Setup.cs` | One-shot, re-runnable MenuItem bakers (schema instances, prefab wiring) — pipeline stage 2. ~40 files (Themes_Setup, UtilityModules_Setup, Tile_*, Smelter_T1_* ~18 micro-patches). |
| `*Builder.cs` | Scene assembly for named planets/systems (Planet01Builder, SolarSystemMapBuilder, AureliusLowOrbitBuilder…). |
| `Patch*.cs` / `*Patcher.cs` | Emergency scene/prefab mutations (orbit fixes, URP materials, wiring). |
| `*Diag*.cs` / `Diagnose*.cs` | Non-destructive inspection (~30: VesperionDiagnose* ×14, snap/socket matrices, FOW layers). |
| `*_ConvertToPrefab.cs` | Scene → prefab bakes for ship hulls. |
| `Debug/SyncPushRegistry.cs`, `Debug/RebuildCloudScriptBundle.cs` | Push CelestialRegistry / CloudScript bundle to PlayFab. |

## Traps
- BRIDGEs awaiting Addressables/title-data export: `BaseTileSchema.prefabAddress`, `BeaconSchema`, `ThemeSchema.referencePackPath`, `RecipeSchema` + `ResourceAnomalySchema` local catalogs, `SurfaceBaseRecord` in-memory records.
- Armor placement temporarily in Conduits tab (Phase 6.10.G moves it to inspect panel).
- `SectorChainRegistry` / chain-pair gates deprecated — bubble-radius network is canon.
- Never reorder enum members; never hand-edit baked .asset files a Setup script owns (re-run the script).
