# Terrain Theme Pipeline

Canonical authoring pipeline for **ground-base planet terrain themes**. Themes drive the visual look of the planet rendered under a ground base — biome textures, sky, atmosphere, clouds, props — while a deterministic per-base heightmap drives the shape. See [`pipelines_overview.md`](pipelines_overview.md) for the cross-cutting six-stage pattern.

**Scope:** the planet visual layer inside `GroundBase.unity` (single-player builder *and* Fusion combat instance). Excludes orbital station authoring, sector / planet 2D-view scenes, and asteroid bases (asteroid surface bases are deferred — not part of this slice).

The plan that introduced this pipeline lives at `C:\Users\Aaron\.claude\plans\if-i-was-going-mutable-parnas.md`.

---

## 1. The Schema Family

| Schema | Role | Storage |
|---|---|---|
| [`TerrainThemeSchema`](../../Assets/Scripts/Schemas/TerrainThemeSchema.cs) | One asset per visual theme (lava, ice, rocky, jungle, etc.). References a hand-authored Planet Forge planet prefab and supplies the runtime overrides applied when the theme loads. | `Assets/GameData/TerrainThemes/` |

A "theme" is the visual style of the planet. The *shape* of the planet (heightmap) is a per-base deterministic bake — same `baseId` always renders the same terrain, swappable theme on top.

---

## 2. Schema Field Reference

### Identity
| Field | Notes |
|---|---|
| `themeId` | Stable kebab-case ID (e.g. `lava`, `ice`). Matches the `terrainThemeId` field on the body's registry entry. |
| `displayName` | Player-facing label. |

### Renderer
| Field | Notes |
|---|---|
| `themePlanetPrefab` | Hand-authored Planet Forge planet prefab. Must have an `SgtSphereLandscape` on the root or first child — its `HeightTex` is overridden at runtime from the per-base baked heightmap. Authoring uses Planet Forge's editor menu (`GameObject ▸ CW ▸ Planet Forge ▸ Planet (Radius = …)`) as a starting template; iterate textures, gradients, biome layers, sky, clouds, and ocean to taste; save as prefab. |

### Heightmap override (drives `SgtSphereLandscape`)
| Field | Notes |
|---|---|
| `heightMidpoint` | 0–1. Where 0.5 grey in the heightmap sits relative to the radius. 0.5 = bidirectional displacement (default for fBm/ridged noise). |
| `heightRange` | World-unit max vertical displacement. Lava planets tend higher (jagged); ice tends lower (rolling). |

### Scene lighting (applied on top of prefab visuals)
| Field | Notes |
|---|---|
| `skyboxOverride` | Optional. Override the scene skybox material for this theme. Leave null to let the prefab's `SgtSky` dominate the atmospheric look. |
| `sunColor`, `sunIntensity` | Applied to the scene's main directional light when the theme loads. |
| `fogColor`, `fogDensity` | Applied to `RenderSettings` fog when the theme loads. |

### Build placement
| Field | Notes |
|---|---|
| `slopeMaxBuildable` | Degrees. Max terrain slope on which base modules can be placed. `GroundBuildController` rejects raycasts steeper than this. |

---

## 3. Folder Layout

```
Assets/
├── GameData/
│   └── TerrainThemes/
│       ├── lava.asset      ← first theme; validates the pipeline
│       ├── ice.asset       ← second theme; validates swap
│       └── …
└── Prefabs/
    └── TerrainThemes/
        ├── PlanetTheme_Lava.prefab    ← hand-authored, referenced by lava.asset
        ├── PlanetTheme_Ice.prefab     ← hand-authored, referenced by ice.asset
        └── …
```

The theme **asset** (`lava.asset`) is a small data record. The theme **prefab** (`PlanetTheme_Lava.prefab`) is the visual heavy lifting — a full Planet Forge planet hierarchy.

---

## 4. Authoring a New Theme — Checklist

> Reference: Planet Forge shipped example scenes live at `Assets/Plugins/CW/Planet Forge/Scenes/` — `Caelith.unity`, `Tessara.unity`, `Lunara.unity`, etc. Each is a complete themed planet you can copy components from.

1. **Author the prefab.**
   - Open a Planet Forge example scene closest to the theme you want (e.g. lava-y reds = open one with warm gradients).
   - Save the planet hierarchy out as a prefab at `Assets/Prefabs/TerrainThemes/PlanetTheme_<ThemeName>.prefab`.
   - Tune biome layers (`SgtLandscapeBiome.Layers`), sky color, cloud density, ocean, and props to the theme.
   - Leave the `SgtSphereLandscape.HeightTex` field assigned to *any* placeholder for editor-preview — runtime will override it.
2. **Create the schema asset.**
   - In `Assets/GameData/TerrainThemes/`, right-click → `Create ▸ Apex Outlaw ▸ Schemas ▸ Terrain Theme Schema`.
   - Name it `<themeId>.asset` (e.g. `lava.asset`).
   - Set `themeId` = the kebab-case ID. Must match what registry entries reference.
   - Drag the prefab into `themePlanetPrefab`.
   - Tune `heightRange` / `heightMidpoint` for the theme's expected dramaticness.
   - Tune lighting / fog fields for scene-level mood.
3. **Verify in the catalog.**
   - Auto-discovered via `AssetDatabase.FindAssets("t:TerrainThemeSchema")` (editor) or Addressables (build). No catalog code changes needed.
4. **Assign to a body** in `Assets/GameData/Celestial/seed.json` by setting `terrainThemeId` on the body entry. Push registry via `CelestialRegistrySeeder` (do **not** use "Seed Registry from Scene" — single-system rule).
5. **Verify end-to-end:** load `GroundBase.unity` with a `baseId` whose parent body uses the new theme; confirm the planet renders with the expected look.

---

## 5. Runtime Pipeline

```
Registry (terrainThemeId on body entry)
        │
        ▼
GroundBaseSceneLoader  (reads handoff: { baseId, mode })
        │
        ├──► Looks up TerrainThemeSchema by themeId via the catalog
        │
        ├──► Loads the baked heightmap bytes for this baseId
        │       (Builder mode: from PlayFab; Combat mode: from GroundCombatSnapshot)
        │
        ▼
PlanetForgeRenderer
        │
        ├──► Instantiates themePlanetPrefab
        ├──► HeightmapBaker.BakeToTexture(seed, params) → Texture2D
        ├──► SgtSphereLandscape.HeightTex = baked texture
        ├──► SgtSphereLandscape.HeightMidpoint / HeightRange = schema values
        ├──► Applies sunColor / sunIntensity / fog / optional skybox
        ▼
Visible themed planet, base placed at registered surface lat/lon
```

**Determinism contract**: same `baseId` + same theme + same `HeightmapBaker.Params` → byte-identical heightmap → identical rendered planet on every client. This is the substrate guarantee that lets Builder mode and Fusion combat mode share the same scene template without ever syncing geometry over the wire.

---

## 6. UI Consumers
- `GroundBaseSceneLoader` — looks up the theme by ID, hands it to the renderer.
- (Future) base-creation UI when ground bases become player-buildable — shows the theme name + preview thumbnail.

## 7. Runtime Consumers
- `PlanetForgeRenderer` — applies the prefab + heightmap + lighting overrides.
- `GroundBuildController` — uses `slopeMaxBuildable` to reject steep placements.
- `GroundCombatBootstrap` (Fusion) — passes the theme ID through the `GroundCombatSnapshot` so combat-instance clients render the same planet.

---

## 8. Bridges currently in place
See `Design_Documents/meta/master_to_do.md` "Bridge code to remove":
- `BakeGroundBaseHeightmap` CloudScript handler not yet shipped — local bake runs client-side on base creation.
- `SetBodyTerrainTheme` CloudScript handler not yet shipped — themes assigned via `seed.json` + `CelestialRegistrySeeder`.
- `GroundCombatSnapshot.bakedHeightmap` not signed — server-sign path lands with the Phase 6.9 snapshot signature work.

---

## 9. Stamped mountains for SgtTerrainPlanet planets (Aaron 2026-06-11)

Whole-planet surface scenes (e.g. `Planet_01_surface`) use **heightmap stamp compositing**
on top of the procedural base bake, because fBm alone makes blobby hills, never ridgelines:

- [`PlanetHeightmapRecipeSchema`](../../Assets/Scripts/Schemas/PlanetHeightmapRecipeSchema.cs)
  — one asset per planet next to its textures (e.g. `GameData/Planets/Planet_01/Planet_01_HeightmapRecipe.asset`).
  Holds the untouched base heightmap + stamp layers (texture, lon/lat, rotation, angular
  radius, strength, Max/Add/Subtract blend, feather).
- `Apex Outlaw → Build → Bake Planet Heightmap Recipe (selected)`
  ([`PlanetHeightmapStampBaker`](../../Assets/Editor/PlanetHeightmapStampBaker.cs)) —
  gnomonic-projects each stamp onto the equirect landforms (no polar smearing), writes
  the output texture asset IN PLACE so SgtTerrainHeightmap scene refs survive, rebuilds
  live terrains. Deterministic, idempotent, re-bakeable.
- Stamp sources: `Art_Assets/Enviroment/TerrainSampleAssets/Textures/Heightmaps/*.tif`
  (Unity Terrain Sample Asset Pack — URP-safe import: everything except `Settings/`).
- Format note: SGT landforms textures are **Alpha8 (height in alpha)**; stamps are **R16
  (height in red)**. The baker handles both — keep that mapping if formats change.
