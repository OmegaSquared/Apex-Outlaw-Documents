# Planet Generation Pipeline — SGT Terrain

How Apex Outlaw generates a full, **stand-on-it** planet on the **SGT Terrain** substrate (`SgtTerrainPlanet`). Reference build: **Aridon** (`Assets/Scenes/Planets/Planet_aridon.unity`), authored by `Assets/Editor/PlanetAridonBuilder.cs`.

> **This is NOT the same system as [`pipeline_terrain.md`](pipeline_terrain.md).** That doc is the *Landscape*-based ground-base **theme** pipeline (`SgtSphereLandscape` + `TerrainThemeSchema`) that the existing ground-base builder (Planet_alythar) still uses. **This** doc is the *Terrain*-based **full planet** pipeline — the successor substrate. Alythar stays on Landscape until migrated; new planets use Terrain. See the substrate decision: `architecture_plan.md` §1.5 framing + the "Landscape vs Terrain" decision.

---

## 1. Why SGT Terrain (not Landscape)

SGT ships two planet systems; we use **Terrain** for new planets:

| | **Landscape** (`SgtSphereLandscape`) | **Terrain** (`SgtTerrainPlanet`) ← us |
|---|---|---|
| Mesh | one baked whole-planet mesh, fixed detail | quad-sphere **LOD chunk streaming**, refines near camera |
| Close-up | limited by bake resolution | near-infinite detail at ground level |
| Used by | Alythar ground-base builder (existing) | Aridon + all new planets |

**Driver:** base building + ground resource gathering happen at **ground level today**, and **seamless orbit→ground descent** is wanted later — both need Terrain's LOD. The asset investment (heightmaps, biome textures, props) is substrate-agnostic, so this isn't throwaway.

---

## 2. Anatomy of a planet (the component stack)

Reference: Aridon, radius **100000** (100 km), at world origin.

| GameObject | Components | Key config |
|---|---|---|
| **Aridon** (planet) | `SgtTerrainPlanet` | Radius 100000, SmallestTriangleSize 8, Resolution 128, Detail 1 |
| | `SgtTerrainPlanetMaterial` | Material = `Aridon_Surface.mat`; **Water → "Aridon Ocean"** (shore blend) |
| | `SgtTerrainHeightmap` | Heightmap = `Aridon_Continents.asset`; Displacement 4000 |
| **Aridon Ocean** | `SgtTerrainOcean` (+ `SgtTerrainOceanMaterial`) | Radius ≈ 101400 (sea level); **Ground → Aridon** (depth) |
| **Aridon Aurora** (child) | `SgtAurora` (+ auto `SgtAuroraModel`) | polar oval shell R 102000–112000 |
| **Main Camera** | `GroundBuildOrbitCamera` | copied from Alythar; target = `CameraFocus`; planetRadius 100000 |
| **CameraFocus** | (Transform) | the surface point the camera orbits/pans |
| **Sun (Directional)** | `Light` | the star |
| *(TODO)* Atmosphere | `SgtAtmosphere` + model | blue limb (URP-fragile — see §6) |

Assets live in `Assets/GameData/Planets/<name>/`. Scene at `Assets/Scenes/Planets/Planet_<name>.unity`.

---

## 3. Shape — **baked heightmap, never live noise** (CANON)

**Rule: the land/sea shape is a baked equirectangular heightmap (`SgtTerrainHeightmap`), never a live `SgtTerrainSimplex`.**

- **Why:** live simplex evaluates noise *per mesh-vertex in 3D*. LOD sets vertex density by distance-to-camera, and that distance changes when you **zoom AND when you orbit/tilt** — so the coastline *breathes* as the camera moves (proven and rejected on Aridon). A baked heightmap is a **texture lookup**: the height at a given lat/lon is identical at every LOD/zoom/angle → coastline is **locked**.
- **Bonus:** baked = **deterministic** (the bake-once contract). Same map renders the identical planet on every client — required for the single-player builder and the Fusion combat instance to agree on geography.
- **How:** `HeightmapBaker` (`ApexOutlaw.Macro.Ground`, deterministic 3D-simplex fBm, equirect, seed + params) → an `Alpha8` texture asset → `SgtTerrainHeightmap.Heightmap`. `Displacement` = world-unit relief.
- **Height model:** the heightmap **ADDS** above the base radius. So base radius = sea floor; terrain ∈ `[radius, radius+Displacement]`; the **ocean radius picks the sea level** within that band.
- **Continent size / shape:** re-bake with different `baseFrequency` (lower = fewer, bigger landmasses), `octaves`, `seed`. **Detail baked into the texture stays LOD-stable** — only *live* per-vertex noise breathes — so you can crank texture detail freely.
- **Fine surface roughness** comes from the **material's normal/detail maps** (shading), never from geometry that crosses sea level.

---

## 4. Biome color — latitude albedo in `_MainTex`

The SGT **TerrainPlanet** shader's base color = **`_MainTex`** (an equirectangular albedo) sampled by lat/lon. The demo material's *painted* `_MainTex` is what made early biomes look "inverted."

- We bake our **own** equirect `_MainTex` by **latitude** (and, future, moisture): desert equator → green mid-latitudes → ice poles. Reference asset: `Aridon_BiomeAlbedo.asset`.
- **Smoothness gotcha (cost us a fumble):** the shader computes `Smoothness = _GlossMapScale * _MainTex.alpha` (`TerrainPlanet.shader` ~line 998). **`_GlossMapScale` is the inspector slider labeled "Smoothness"** — `_Smoothness` and `_Glossiness` in the .mat are **dead leftovers** that no-op. Set `_GlossMapScale` low (we use 0.05) to matte the land; the ocean stays shiny (correct). **Future:** bake per-biome wetness into the albedo **alpha** (ice glossy, desert bone-dry).
- The material is a **clone** of CW's `Terrain Planet (01).mat` (`Aridon_Surface.mat`) with `_MainTex` swapped, `_GlossMapScale` lowered, and the built-in `_Water`/`_MaskMap` disabled.

---

## 5. Water — `SgtTerrainOcean`

- A **second LOD sphere** (its own GameObject) at the sea-level radius, **`Ground`-linked** to the planet for depth/shore foam.
- **`Radius` = sea level**, and it's the live coverage knob: **lower = less water**. With the heightmap-ADD model, valid range is `[base radius, base+Displacement]` (Aridon: 100000–104000; sea ≈ 101400).
- **Lakes / inland seas** = wherever the heightmap dips below sea level. There is **one global sea level** (a sphere) — you can't perch water at an arbitrary elevation.
- Tune it live in the **Scene view in edit mode** (the ocean previews without Play); Play-mode edits revert.

---

## 6. Atmosphere / clouds / aurora

- **Aurora (DONE):** `SgtAurora` (+ auto `SgtAuroraModel` via `Create()`), a polar-oval ribbon shell. `RadiusMin/Max` = altitude shell (absolute units, above the surface); `StartMin/Max` = distance-from-pole (0 = pole, 1 = equator) → oval width; `StartTop` = which pole (0.5 = both); `Colors` gradient = curtain colors; `Brightness`. Best seen on the **night side** (additive glow). Material: `…/Aurora/Examples/Materials/Aurora + Animation.mat`.
- **Atmosphere (TODO):** `SgtAtmosphere` + `SgtAtmosphereModel` child + scattering/lighting textures. Material: `…/Atmosphere/Examples/Materials/Atmosphere + Lighting.mat`. **URP-fragile:** needs the camera **Depth Texture** enabled or it renders as a solid blob / vanishes. Do as its own careful pass.
- **Clouds (TODO):** the standard `SgtCloud` does **not** natively ride `SgtTerrainPlanet` — needs a Terrain-specific approach (shared-material or a cloud sphere). Not yet wired.
- **Space background (Alythar's exact rig):** `SkyboxStars.mat` (the **SGT/Skybox _mesh_ shader**) on a **giant inside-out `Sphere` scaled `1e7`** at origin — NOT `RenderSettings.skybox` (that shader is a mesh shader, so it must ride a sphere; the skybox-slot path renders nothing). The shader draws it as background → **always visible at every zoom**, camera clears solid black behind it. Aaron pulled this from the CW "Alythar - Earth Sized" example (the `Demo UI + Light + Camera` group: Skybox + `SgtVolumeManager` + `SgtSkyLighter`).
- **Sun (visible body):** a bright unlit **Sun Disk** parented to the Sun light so it rides the day/night rotation across the sky. `PlanetAridonBuilder.AddSunAndSpace()`. **Caveat:** the sun disk + moons are *geometry*, so the camera's dynamic far-clip hides them at extreme surface zoom (visible from orbit/mid zoom) — upgrade to an **SGT flare/corona** (screen-space) for a sun visible boots-on-ground too.

---

## 6b. Celestials — day/night, moons, eclipse (CANON)

Ported faithfully from **Planet_alythar** (the reference rig). **Everything is time-driven off `CelestialClock` (UTC − epoch), never `Time.deltaTime`** → every client sees the same time-of-day, moon positions, and eclipse with zero server sync. **Animates in Play mode only.**

- **`PlanetSurfaceContext`** (on the planet root) — the ONE frame every surface system reads: `Center` = transform.position, `PoleAxis` = +Y, `PrimeMeridian` = +Z, `radius`, `dayLengthHours`. **Terrain gotcha:** it normally auto-reads radius from a child `SgtSphereLandscape`, which a Terrain planet doesn't have → **set `radius` explicitly** (Aridon: 100000) or it defaults to 1 and moons spawn *inside* the planet. `dayLengthHours` is per-planet (Aridon = **12**, same as Alythar at this size).
- **`PlanetDayNightCycle`** (on the sun Light) — rotates the sun around the fixed planet so the day side sweeps under you (sub-solar longitude = pure function of `CelestialClock.Now()`); drives day/night sun color/intensity + ambient (keyed to where the camera looks); applies the **eclipse** dimming + the moonlight fill. `eclipseDarkness 0.85`, warm `eclipseSunColor`. **This is also what properly *lights* the planet** — without the cycle running (e.g. in edit mode) the day side reads dark.
- **`PlanetMoonSystem`** (+ `PlanetMoon[]`) — moons orbit at a **finite** distance (`orbitRadiusFactor × radius`) so the eclipse lands on a moving **shadow path** (parallax). Aridon's three: **Selas 12 h (`isEclipseMoon` → resonance-locked daily total eclipse)**, **Veil 14 h**, **Orin 16 h**. Per-moon: orbit period / radius factor / inclination / size factor / tint. `moonBodyPrefab` null → grey lit-sphere placeholders (real SGT moon bodies, like Alythar's, are a follow-up); eclipse math always uses the *real* orbital distance, not the render distance.
- **Moonlight** — a dim cool fill Light the cycle aims from a moon and brightens at night.
- **Speed it up to test:** the global `CelestialPreviewSpeed` advances the sun AND moons together — watch a full day + eclipse in seconds.

Reference build: `PlanetAridonBuilder.AddCelestials()`.

---

## 7. Camera

- **`GroundBuildOrbitCamera`** (Alythar's exact rig) `CopySerialized` onto the Main Camera, so all of Aaron's tuned values come across. `target` = a `CameraFocus` Transform; `planetCenter` = 0; `planetRadius` = the planet's radius; **`landscape` = null** (Terrain has no `SgtSphereLandscape`, so it orbits the *smooth sphere* — controls identical, but no terrain-follow until a Terrain-native floor is added).
- Controls: **WASD** pan, **Q/E** yaw, **R/F** pitch, **RMB** orbit, **wheel** zoom.
- **Zoom ceiling gotcha:** `RecomputeLevels()` runs every frame and **overwrites** `maxDistance` with `lowOrbitFactor × planetRadius` (the serialized `maxDistance` is ignored). Default `lowOrbitFactor 0.05` caps zoom-out at 5% of radius — a *base-builder* ceiling (same on Alythar; you just never hit it there). For full-planet survey, raise `lowOrbitFactor` (Aridon uses **4** → 400 km ceiling).

---

## 8. Authoring a new Terrain planet — recipe

Reference implementation: `Assets/Editor/PlanetAridonBuilder.cs` (methods: `Execute`, `SwitchToHeightmap`, `MatteLand`, `EnhanceAridon`, `UseAlytharCamera`, `AddAurora`). Steps:

1. **Scene + planet.** New scene; `SgtTerrainPlanet.Create()` (auto-adds `SgtTerrainPlanetMaterial`); set Radius / SmallestTriangleSize / Resolution.
2. **Shape.** Bake continents via `HeightmapBaker.BakeToTexture(seed, params)` → save asset → `SgtTerrainHeightmap.Heightmap` + Displacement. **(Never `SgtTerrainSimplex`.)**
3. **Biome color.** Bake an equirect latitude albedo → clone CW `Terrain Planet (01).mat`, swap `_MainTex`, set `_GlossMapScale` ≈ 0.05.
4. **Ocean.** `SgtTerrainOcean.Create()`; Radius = sea level in the heightmap band; `Ground` = planet; assign a cloned `Terrain Ocean` material; set planet material's `Water` = ocean.
5. **Camera.** `CopySerialized` Alythar's `GroundBuildOrbitCamera` onto the Main Camera; create a `CameraFocus`; set planetCenter/planetRadius; landscape = null; raise `lowOrbitFactor`.
6. **Sky.** Aurora (`SgtAurora.Create()`); atmosphere (TODO); clouds (TODO).
7. **Sun + save.**

---

## 9. Gotchas (hard-won — read before touching planet code)

- **Live simplex breathes with LOD/zoom/angle → always bake heightmaps** (§3).
- **Smoothness = `_GlossMapScale` × albedo.alpha** — `_Smoothness`/`_Glossiness` are dead (§4).
- **Ocean radius must sit in the heightmap height band** (heightmap ADDS above base radius) or you get all-land / all-water.
- **Zoom cap = `lowOrbitFactor` × radius**, recomputed each frame (§7).
- **SGT atmosphere needs the camera Depth Texture in URP** or it breaks (§6). General SGT-URP fragility: a compile error anywhere freezes SGT rendering; never re-import SGT.
- **Coplay `capture_scene_object` cannot screenshot SGT terrain** (it draws via `Graphics.DrawMesh`, not a `MeshRenderer`) — verify renders **by eye** in the Unity Game/Scene view, not via screenshots. Normal `MeshRenderer` objects (a test cube) DO show.
- **`HeightmapBaker` output must be readable** for `SgtTerrainHeightmap` to displace (else flat planet).
- **`GroundBuildOrbitCamera.dynamicClipPlanes` / `scaleFarClip` clip the SGT volumetric atmosphere → a black band swallows the sky** (hit repeatedly 2026-06-08). When on, the far clip is pinned to the horizon (`1.2·√(2·R·dist)` — only ~42 km at 6 km altitude), which culls the atmosphere shell past the near horizon: you get a thin blue limb with a **black gap beneath it**. The camera's own code comment warns of exactly this. **Fix:** set both `dynamicClipPlanes` and `scaleFarClip` **false** and use fixed clips with a volumetric-safe ratio (`near = far/10000`, e.g. near 60 / far 600000). Substrate-agnostic — recurred on Terrain *and* the Planet Forge surface until these were off.
- **(Planet Forge / Landscape) A pre-generated equirect heightmap goes in `SgtSphereLandscape.HeightTex`, NOT the biome's tiling-detail layers** (2026-06-08). The `SgtLandscapeBiome` layer `HeightTexture` slots expect small *repeating* detail textures (from the Bundle); a whole-planet continents map there renders flat. `HeightTex` must be single-channel **Alpha8/R8/R16 + Read/Write**, equirect; the latitude colour goes in `AlbedoTex` (equirect, any format).
- **(Planet Forge / Landscape) `SgtSky.InnerMeshRadius` must equal the OCEAN radius**, not the landscape base radius (per the PF docs). Mismatch = the atmosphere shell sits below the surface and renders a black "underground" band at the horizon.

---

## 10. Status & roadmap (Aridon)

**Done:** Terrain substrate validated • LOD-stable continents (baked heightmap) • latitude biome color • ocean (tunable sea level) • matte land • Alythar camera • northern lights • day/night + 3 moons + eclipse (12 h, CelestialClock-driven) • **space background (Alythar SkyboxStars sphere) + visible sun disk**.

**Next (pick up here):**
1. **Atmosphere** (blue limb) — **port Alythar's sky rig faithfully**: the `Demo UI + Light + Camera` group's `SgtSky` + `SgtVolumeManager` + `SgtSkyLighter` (Alythar uses `SgtSky`, NOT the heavier `SgtAtmosphere`). Same copy-from-Alythar approach as the camera + skybox. URP needs the camera Depth Texture. Then **re-tune the aurora** against the now-lit planet, and polish (real moon bodies vs grey spheres, an SGT sun corona/flare).
2. **Surface detail** — per-biome tiling + normal maps so the ground reads as real terrain up close (needs ground PBR — CC0 / StableGen). *Vegetation is the asset gap.*
3. **Biome refinement** — moisture (tropical/green hug shorelines), sand seas, snow-by-elevation; bake the **`SgtTerrainAreas`** splatmap (also drives scatter + the resource signature).
4. **Scatter** — rocks (owned) then vegetation, via `SgtTerrainPrefabSpawner`.
5. **Game systems** — port the planet-agnostic base-builder / drone / resource loop; day-night; slope buildability; the deferred **height-field dig** (architected as a stacked modifier).

---

## 11. Related

- [`pipeline_terrain.md`](pipeline_terrain.md) — the *Landscape* ground-base theme pipeline (the OTHER, existing surface system; Alythar).
- [`pipelines_overview.md`](pipelines_overview.md) — the schema-driven authoring pattern.
- `Assets/Editor/PlanetAridonBuilder.cs` — the reference builder.
- `Assets/Plugins/CW/SpaceGraphicsToolkit/Features/Terrain/` — the SGT Terrain feature (+ `Examples/` scenes 01–17).
