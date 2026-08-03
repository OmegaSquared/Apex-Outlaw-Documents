# Session handoff — Planet Forge surface spike (atmosphere + weather + space)

**Date:** 2026-06-08. Read this, then continue. Context ran out mid-tuning the aurora; everything below is current.

---

## 0. TL;DR — the decision that drove this session
We were tuning Aridon's atmosphere on **SgtTerrain** and it kept fighting us (orange sky, black bands, camera-vs-surface radius mismatches). We found **Planet Forge** (CW asset, already in the project at `Assets/Plugins/CW/Planet Forge/`, and already referenced by `PlanetForgeRenderer.cs` for the Low Orbit scene). **Aaron decided: adopt Planet Forge (SgtSphereLandscape) for the SURFACE substrate**, because its integrated Landscape + Sky + Cloud + Ocean + Biome "just works," whereas Terrain's single-radius shells fought the bumpy surface. This **reverses** the recent `project_terrain_vs_landscape_substrate` memory (Terrain-for-surface) — that divergence is **not yet doc-synced** (see §6).

A test planet was built to validate it: **`Assets/Scenes/Planets/Planet_aridonPF.unity`**.

---

## 1. Current state of `Planet_aridonPF.unity`
A Planet Forge planet at radius **100000**, using OUR Aridon data:
- `Planet/Landscape` — `SgtSphereLandscape` (R=100000). `HeightTex` = `Aridon_Continents.asset` (our continents), `AlbedoTex` = `Aridon_BiomeAlbedo.asset` (our latitude desert→green→ice), `HeightRange` 4000, `HeightMidpoint` 0. `Planet/Landscape/Biome` = `SgtLandscapeBiome` (Color=false, vendor example texture for tiling detail only).
- `Planet/Sky` — `SgtSky`, thin atmosphere `Height = R/20 = 5000`, **`InnerMeshRadius = 101400` (MUST equal the ocean radius)**, scattering scaled down for the shell.
- `Planet/Cloud` (+ `Detail`) — `SgtCloud`, de-eroded for density (`CarveCore` ~0.12) + global wind (`SgtVolumeManager.WindVelocity`).
- `Planet/Ocean` — `SgtOcean`, `Radius = 101400` (sea level), rays + debris.
- `Planet/Aridon Aurora` — `SgtAurora` **+ `SgtAuroraMainTex`** (the curtain-texture generator). 16 short ribbons, `PointSpiral` 6, transparent body (`ColorsAlpha` 0). **Still being tuned — see §4.**
- `Planet/Aridon Lightning` — `SgtLightningSpawner` (whole-sphere strikes for now).
- `Skybox` — SGT `SkyboxStars` on a 1e7 inside-out sphere.
- `Sun (Directional)` (+ `SgtLight`, `PlanetDayNightCycle`) + child `Sun Disk` (visible).
- `Moonlight` + `Aridon Moons` (`PlanetMoonSystem`, 3 grey-sphere moons Selas/Veil/Orin, orbit factors 3/4/5 to stay inside the 600k far clip).
- `SgtVolumeManager`, `SgtSkyLighter`, `Main Camera` (`GroundBuildOrbitCamera` with `landscape` wired = terrain-aware floor, + `SgtVolumeCamera`).

Day/night + moons animate **in Play only** (CelestialClock-driven).

---

## 2. ⚠️ Throwaway patch scripts at the REPO ROOT (not under Assets)
These hold the working fixes but are **applied via Coplay `execute_script`, NOT baked into the builder** — so they drift if the scene reloads. **They must be folded into `PlanetForgeTestBuilder.cs` and deleted** (see §5 TODO #1).

- **`_PFWeather.cs`** ← **THE consolidated patch.** Running it re-applies *everything*: the camera clip fix + clouds + aurora (incl. `SgtAuroraMainTex`) + lightning + space/celestials (skybox, sun disk, day/night, moons). **This is the one to run to restore the scene.**
- `_PFTestRunner.cs` — runs `PlanetForgeTestBuilder.BuildTest()` (full rebuild — rebakes the landscape, slow).
- `_PFCamFix.cs`, `_PFSkyFix.cs`, `_PFLightFix.cs` — older one-off fixes, now **superseded** by `_PFWeather.cs` (which includes them).
- `_AtmoSpikeRunner.cs` — old runner for `PlanetAridonBuilder.AddSky` (the abandoned **Terrain** atmosphere spike).

**To re-apply the whole scene after any drift:** open `Planet_aridonPF.unity` (edit mode) → Coplay `execute_script` `{filePath:"_PFWeather.cs", methodName:"Run"}` → Play.

---

## 3. Hard-won gotchas (the camera + heightmap + sky ones are already in `pipelines/pipeline_planet.md` §9)
1. **Black band/blob over the planet = `GroundBuildOrbitCamera.dynamicClipPlanes` / `scaleFarClip`.** When ON, the far clip is pinned to the horizon (~42 km at 6 km alt) and **clips the SGT volumetric atmosphere**. Fix: both **false**, `twoTierEnabled` **false**, fixed clips (`near 60 / far 600000`, ratio ≤ 10000 keeps volumetrics alive). **It kept reverting** to builder defaults during play/stop churn → that's why the camera fix is now *inside* `_PFWeather.cs`.
2. **Planet Forge heightmap** goes in **`SgtSphereLandscape.HeightTex`**, NOT the biome's tiling-detail layers (those expect small *repeating* textures; a continents map there renders flat). `HeightTex` must be single-channel **Alpha8/R8/R16 + Read/Write**, equirect. Latitude colour → **`AlbedoTex`** (equirect, any format).
3. **`SgtSky.InnerMeshRadius` must equal the OCEAN radius** (per PF docs), else a black "underground" band at the horizon.
4. **AURORA needs `SgtAuroraMainTex`** — a companion generator that builds the curtain texture (the `.mat` ships with `_SGT_MainTex` null, so without it the ribbons are SOLID). Same pattern as `SgtAtmosphereLightingTex`/`DepthTex`. The aurora *editor* even has a "Fix" button that just adds this component.
5. **SGT renders can't be screenshotted via Coplay `capture_scene_object`** (DrawMesh, not MeshRenderer) — verify by eye in Play. Aaron drives the eyeballing.
6. **Coplay/Unity quirks this session:** editing a script under `Assets/` triggers a domain reload → `check_compile_errors`/`execute_script` time out for ~30–60 s (wait, re-check `get_unity_editor_state.hasCompilationErrors`). Root-level `.cs` (the `_PF*` patches) are Coplay-compiled, **no reload**. `stop_game` sometimes reports "Stopped" while still in Play — verify with `get_unity_editor_state` before an edit-mode `execute_script` (it throws "cannot be used during play mode" on `MarkSceneDirty`).

---

## 4. Aurora — where it was left (still tuning)
Working reference: the author's own promo + `Assets/Plugins/CW/SpaceGraphicsToolkit/Features/Aurora/Examples/01 Aurora.unity` (params copied at line ~615–672 of that scene). Key params (in `_PFWeather.cs`): `PointSpiral` (twist — high=merged swirl, low=distinct), `PathLengthMin/Max` (short=separate ribbons), `PathCount` (#ribbons), `ColorsAlpha` (**0 = fully transparent body**, only textured streaks show), `Colors` gradient (top-half palette; first alpha stop 0 = soft fade), and **`SgtAuroraMainTex`** (REQUIRED for the wispy streaks). Last state: green, 16 short ribbons, transparent body, texture on. Aaron may still want it more like the reference — adjust the `Colors` gradient + spiral/length, don't re-derive from scratch.

---

## 5. TODO (priority order)
1. **Consolidate & clean up:** fold `_PFWeather.cs`'s camera/sky/lighting/weather/space logic into `PlanetForgeTestBuilder.cs` so ONE build = the complete scene, then **delete the ~6 root `_PF*`/`_AtmoSpikeRunner` scripts**. (They're untracked clutter at the repo root.)
2. **Band-targeted storms** (Aaron's ask): stock `SgtLightningSpawner` strikes the *whole sphere*. Write a small custom spawner that strikes only where cloud coverage is dense / in chosen latitude bands.
3. **Rain/snow:** NOT an SGT/PF feature (the only "snow" is a biome *terrain* texture; "marine snow" is underwater). These are **custom Unity ParticleSystems for the SURFACE scene** (invisible from orbit) — build when we do boots-on-ground.
4. **Real moon bodies** (vs grey-sphere placeholders) — `PlanetMoonSystem.moonBodyPrefab`.
5. **doc-sync the substrate decision:** `world/world_surface_scene.md` still says `SgtSphereLandscape`; memory `project_terrain_vs_landscape_substrate` says migrate to Terrain; `project_planet_aridon` calls Aridon "the first SGT Terrain planet." If Planet Forge wins for the surface, all three need reconciling (deprecate, don't delete).
6. **Aurora final pass** (§4).

---

## 6. Architecture context captured this session (for the shield plan)
- **Three-scene model** (canon, `world/world_low_orbit_scene.md` + `world/world_surface_scene.md`): Solar (sector map) → **Low Orbit** (Scene 2, **Planet Forge**, `PlanetForgeRenderer.cs`, capitals + orbital structures) → **Surface** (Scene 3, where the base builder lives). Same planet, different scenes, shared baked heightmap.
- **Aaron's planetary shield/gate plan** (Rogue One / Scarif): an alliance-built **`ShieldGenerator`** structure in the **Low Orbit scene** rendered as a dome shell at the low-orbit radius with a **gate aperture**; while up, non-allies can't drop to Surface (extends the existing permit-gate in `world_low_orbit_scene.md` "Permit-gated transition" + `social/social_war_doctrine.md` §6.1 "all defenses destroyed"). NOT built yet — design only.

---

## 7. Key paths
- Scene: `Assets/Scenes/Planets/Planet_aridonPF.unity`
- Builder: `Assets/Editor/PlanetForgeTestBuilder.cs`
- Re-apply patch: `_PFWeather.cs` (repo root)
- PF asset: `Assets/Plugins/CW/Planet Forge/` (`Scripts/SgtPlanetForge.cs` = the recipe I mirrored, `Documentation.pdf`, example Surface/Orbit scenes)
- Our planet assets: `Assets/GameData/Planets/Aridon/` (`Aridon_Continents.asset`, `Aridon_BiomeAlbedo.asset`)
- Old Terrain Aridon (still exists): `Assets/Scenes/Planets/Planet_aridon.unity` + `Assets/Editor/PlanetAridonBuilder.cs` (source of the celestial/sun/space code I ported)
- Docs touched: `Design_Documents/pipelines/pipeline_planet.md` (§9 gotchas updated)
