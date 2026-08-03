# CW Planet Pipeline — Building Themed Planets on Space Graphics Toolkit

How Apex Outlaw builds a surface/orbit planet on the **CW Space Graphics Toolkit (SGT)** +
**Planet Forge** plugins. This is the reference behind the `civitas-ferri` theme and the
`Planet_civitas_ferri` scene. Everything here was verified in-editor (screenshots + runtime
probes), 2026-06-02.

> Worked example: **Civitas Ferri** (ICE homeworld) — a 100k-radius red-rock "Moab/Dune"
> desert world: high desert equator, sunk polar basins. Theme `Assets/GameData/TerrainThemes/civitas-ferri.asset`.

---

## 1. The two-layer model (don't bypass it)

A planet here is **never** hand-placed in a scene. It is:

1. **`TerrainThemeSchema`** (`Assets/GameData/TerrainThemes/<id>.asset`) — the data: radius,
   height range, ocean level, lighting, and the **bake params** (noise + latitude climate).
2. **`themePlanetPrefab`** (`Assets/Prefabs/TerrainThemes/PlanetTheme_<Name>.prefab`) — a
   Planet Forge prefab (SgtSphereLandscape + biome + sky/cloud/ocean) holding the *look*.
3. **Baked heightmap** — generated at scene load by `HeightmapBaker` from the theme's seed +
   bake params, injected into the prefab's `SgtSphereLandscape.HeightTex`.

`PlanetForgeRenderer.Render(theme, bytes, w, h)` ties them together: instantiates the prefab,
injects the heightmap, and **syncs all SGT radii from `theme.planetRadius`** (sky/ocean/cloud
shells follow the landscape radius — never edit radii on the prefab directly).

`GroundBaseSceneLoader` is the scene entry point: reads `themeIdOverride` (or the cross-scene
`GroundBaseSceneEntry.ThemeId`), builds bake `Params` from the theme, bakes, and renders.

| Concept | File |
|---|---|
| Theme schema | `Assets/Scripts/Schemas/TerrainThemeSchema.cs` |
| Heightmap baker | `Assets/Scripts/Macro/Ground/HeightmapBaker.cs` |
| Renderer (prefab + heightmap + radii + lighting) | `Assets/Scripts/Macro/Ground/PlanetForgeRenderer.cs` |
| Scene loader | `Assets/Scripts/Macro/Ground/GroundBaseSceneLoader.cs` |

---

## 2. Planet Forge build recipe (what a prefab is made of)

Menu **GameObject ▸ CW ▸ Planet Forge ▸ Planet (Radius = …)** builds:

```
Planet
├── Landscape   SgtSphereLandscape          ← terrain sphere (radius, HeightTex, HeightRange)
│   └── Biome   SgtLandscapeBiome           ← displacement layers + colour gradient + strata
├── Sky         SgtSky                      ← atmosphere shell (InnerMeshRadius, Height)
├── Cloud       SgtCloud (+ SgtCloudDetail)
└── Ocean       SgtOcean (+ Rays, Debris)   ← "fluid" (water OR lava); shows where land < sea level
```

**Three scene singletons are mandatory or the look silently breaks:**
- `SgtVolumeManager` (one per scene) — volumetrics manager.
- `SgtVolumeCamera` on the render camera — **without it the atmosphere doesn't render.**
- `SgtLight` on the sun directional light — without it the atmosphere is unlit.

Radius coupling (done by `PlanetForgeRenderer.SyncPlanetRadii`): `sky.InnerMeshRadius = R`,
`sky.Height = R*atmosphereThicknessFraction`, `ocean.Radius = R + heightRange*(oceanLevelFraction-heightMidpoint)`,
cloud band inside the sky shell.

---

## 3. Heightmap baker + latitude climate

`HeightmapBaker.BakeR8(seed, params)` → deterministic equirectangular R8/Alpha8 bytes (3D
Simplex on the unit sphere, seamless at the longitude wrap). Theme-driven params:

- `bakeBaseFrequency` — **low = a few big landforms, high = many busy peaks.** NOTE: frequency
  is *cycles per unit sphere*, so 0.8 on a 100k-radius planet = mountains tens-to-hundreds of
  km wide (planet-scale). Close-range mesa/cliff texture comes from the **biome layers**, not this.
- `bakeOctaves`, `bakeRidgeBias` (0 = smooth dunes, 1 = jagged ridges).
- **Latitude climate** (added for banded planets): `bakeEquatorLift` raises low/mid latitudes
  into a plateau; `bakePolarSink` sinks the high latitudes into basins (so the global ocean
  shell floods *only* the poles); `bakePolarStart` = `|sin(lat)|` where the sink begins.
  All default 0 = off → existing themes bake byte-identical.

Civitas Ferri verified bake: equator-row avg **221**/255, pole-row avg **48**/255; runtime
displacement probe: equator **+2885**, poles **−1800** (a ~4.6k-unit climate swing).

**Heightmap format rules (SGT is strict):** equirectangular (cylindrical) projection,
**Read/Write enabled**, single channel **Alpha8 / R8 / R16** (R16 = finer steps, less terracing).

---

## 4. CW capabilities & limitations (for terrain art direction)

The terrain is a **heightfield** (one height per surface point). Therefore:

| Want | How | Native? |
|---|---|---|
| Mesas, plateaus, buttes, canyons, dunes | heightmap + biome layers + `Strata` banding | ✅ |
| Red-rock colour by elevation | biome `GradientTexture` (U = low→high) | ✅ |
| Cliff-vs-sand material by slope/height | biome `textureLayers` (Min/MaxSlope, Min/MaxHeight) | ✅ |
| Seamless orbit → surface | cube-sphere LOD, Burst + double precision | ✅ |
| **Overhangs, arches, hoodoos, true spires** | **prop meshes** via `SgtLandscapePrefabSpawner` | ❌ heightfield can't; scatter props |
| **Caves, slot-canyon "narrows"** | `SgtLandscapeCave` (prefab + shader-cut terrain hole, Box entrance) | ❌ from heightfield; authored inserts |

So "Moab" = heightfield landforms + scattered rock-prop meshes (arches/hoodoos) + cave/trench
inserts for narrows. The hero arch is always a prop, never terrain.

---

## 5. Gotchas hit (and fixed) building Civitas Ferri — read before tuning

1. **`SgtLandscapeBiome.Replace` overwrites the injected heightmap.** Default `Replace=true`
   makes the biome's *first* displace layer **replace** the base `HeightTex` — wiping the macro
   latitude shape + mountains, leaving a near-smooth sphere. **Fix: `biome.Replace = false`** so
   biome detail *adds* on top of the macro heightmap. (The lava theme keeps `Replace=true`; it
   relies on the biome's own tiling, not the baked macro.)

2. **Biome detail layers are scaled for the authored prefab radius (2.5k), not 100k.** The lava
   defaults (`HeightRange` 4 / 0.5 / 0.1) are invisible on a 100k planet. Boost them to
   mesa/cliff/rock scale (Civitas Ferri uses **650 / 160 / 35** with `GlobalSize` 900 / 170 / 35).

3. **LOD authored for a small radius is too coarse/slow at 100k.** On `SgtSphereLandscape`:
   `MinimumTriangleSize` (0.01 is fine), but raise **`Detail`** (→6) and **`LodBudget`** (0.001→0.02)
   so terrain refines near the camera in reasonable time. LOD tracks `Camera.main` live each frame.

4. **Camera altitude must be measured from the DISPLACED radius, not the base.** Equator is
   lifted to ~102.9k on a 100k planet — a camera at radius 102.2k is *underground*. Place surface
   cameras at `displacedRadius + altitude` (≈107k+ for Civitas Ferri).

5. **URP capture / atmosphere.** `SgtVolumeCamera` logs a benign warning ("Camera.AddCommandBuffer
   only with built-in renderer") — the atmosphere still renders. For deterministic screenshots use
   **`RenderPipeline.SubmitRenderRequest(cam, new RenderPipeline.StandardRequest{destination=rt})`** →
   ReadPixels. `ScreenCapture.CaptureScreenshotAsTexture()` from an editor-thread script returns an
   undefined/white buffer under URP — do not use it.

6. **`SaveAsPrefabAsset` on a planet prefab is slow** — the MCP `execute_script` call may *time out
   at 60s while the work still completes*. Verify by re-reading the asset, not by the return value.

---

## 6. Authoring a new themed planet (checklist)

1. Duplicate an existing `TerrainThemeSchema` (`lava.asset`) → `<id>.asset`; set `themeId`,
   `planetRadius`, `heightRange` (~6% of radius for visible mountains), `oceanLevelFraction`
   (low → polar-only ocean), bake params (frequency/ridge/equatorLift/polarSink), lighting.
2. Copy the lava prefab → `PlanetTheme_<Name>.prefab` (**never edit the lava prefab**). On its
   biome: `Color=true`, **`Replace=false`**, swap `GradientTexture`, set `Strata`, boost the
   displace layers; on the landscape raise `Detail`/`LodBudget` for big radii. Point the theme's
   `themePlanetPrefab` at it.
3. Build a scene with `SgtVolumeManager` + Camera(`SgtVolumeCamera`) + Sun(`SgtLight`) +
   `GroundBaseSceneLoader{ themeIdOverride = "<id>" }`. Enter play → loader bakes + renders.
4. Verify: bake preview PNG (climate bands), runtime displacement probe (`GetLocalPoint`),
   render captures (orbit / surface vista / pole).

Editor tool suite (`Assets/Editor/CivitasFerri/`): `ConfigureCivitasFerriTheme`,
`BuildCivitasFerriScene`, `ReskinCivitasFerriPrefab`, `BakeHeightmapPreview`,
`RuntimePlanetDiag`, `CaptureCivitasFerri` (orbit) / `CaptureCivitasFerriVista` (surface) /
`CapturePole`.

---

## 7. Open items (need investigation, not yet solved)

- **Multi-biome colour (green poles, sand belt, dune sea).** A second `SgtLandscapeBiome` with a
  polar latitude `Mask` + green gradient did **not** tint the poles — SGT did not composite the
  second biome's colour over the first via the mask (attempt reverted). The displacement/climate
  are correct; only *latitude-varying colour* is unsolved. Options to try: (a) the biome's
  `textureLayers` with `MinSlope/MaxHeight` constraints; (b) an equirectangular `AlbedoTex` on the
  landscape carrying the latitude tint with `biome.Color=false`; (c) confirm SGT's intended
  multi-biome colour workflow from the PLANETS pack example scenes (`Packs/PLANETS/All * Planets.unity`).
- Dramatic Moab cliffs/strata, atmosphere haze tuning, sand vs dune regions — aesthetic passes.
- `LodBudget=0.02` is a look-dev value; profile for real-time before shipping.
