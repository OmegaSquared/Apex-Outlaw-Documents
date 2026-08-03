# Session handoff — 2026-07-20 (the diorama day)

Landmark session: the macro chart became a **diorama** — the real SGT world at true
scale beneath the gameplay plane — and Rubicon became **Draxxor** (Planet Forge
Earth-Sized), by look and by name. Plus a long tail of seam, radar, weapon, and UX
fixes. Everything below is committed; nothing is pushed to PlayFab (CloudScript
stayed at rev 11 — no server changes today).

## Shipped & verified

- **Radar root cause** — UIDocument SetActive cycles destroy the visual tree; every
  Awake-wired HUD died silently after a menu round-trip. Self-heal (`panel == null`
  → rewire) in SurfaceMinimapHUD + SpaceCompassHUD; GlobalNavHub RETIRED (right-side
  chip stack gone for good — MainMenu pipeline owns nav). "○ NO RADAR" chip removed.
- **Weapon test-range parity** — in-game turret arming now runs the exact
  WeaponTestRange staging recipe: catalog schema forced onto arcs, LOD-duplicate
  combat stacks disabled, ammo auto-loaded by family/size (the old path NULLED the
  round). Flak airburst matches the range.
- **Library consolidation** — BlueprintLibraryOverlay deleted; THE library is the
  ResearchLab one (tabs/search/compare/TEST FIRE). Main-menu BLUEPRINT LIBRARY card
  + LIBRARY buttons route there (`ResearchLabController.OpenLibraryOnLoad`). Admin
  sees the full catalog (red [ADMIN] tag); players see discoveries only.
- **Seam (B5/B6)** — sandbox dressed from map position at TRUE scale (LocalScale
  225); M-return restores camera AND fleet positions (ChartCameraRestorer); zoom
  floor + "DROP OUT OF HYPERSPACE?" prompt (floor ortho 55, Aaron-picked; hook lives
  in **MacroView1CameraController** — HelionCameraController is NOT in the scene).
- **Macro diorama (P1+P2)** — MacroDioramaRig: perspective base cam slaved to the
  ortho chart cam (`decoRoot = camPos × (1−S)`), URP overlay stacking, chart layer-9
  skybox + layer-10 masked off the chart cam. HelionDioramaBuilder: whole system
  (Draxxor + Alea + Iacta + sun), forge ring system + belt, SgtLight sun,
  DecoFarBody mounts native-scale Draxxor (5,000,000 radius — NEVER scale it) at
  matching angular size. Exposure debugged: no deco skybox (SkyboxStars bakes a
  warm glow into its DOWN direction), chart sun glow sprite hidden, atmosphere
  clones skipped, sun ball modest.
- **QoL batch** — Doppler factor 0 (zoom screech), SceneLoadSpinner (login spinner
  prefab over dark cover, holds through the Helion diorama build — no old-planet
  flash), menu ambience = SciFiSoundscapes13, FOW veil dimmed 0.38 + quadY 30
  (fleets/labels float above it), fleet marker stack at ChartY 45, Sally's card
  bakes bird's-eye, blueprint libraries seeded from disabled PlanetVisual meshes.

## Built this hour — NEEDS AARON'S VERIFY

1. **Sandbox Draxxor terrain fix (task #18)** — root cause found: SGT landscapes
   render only for cameras with **SgtVolumeCamera**; the sandbox camera never had
   one (the "gray ball" was only the SgtSky shell). Dresser now adds it. VERIFY:
   drop out → cratered terrain should render. If good, try re-enabling the
   instance's SgtSky at reduced density for rim glow.
2. **Planet-in-ring composition** — sandbox ring re-homed around the far native
   Draxxor (chart ratios × 5M), mount dir up-tilted (bearing×0.85 + up×0.38).
3. **WASD parallax** (BackdropParallax: yaw 0.004°/u, pitch 0.0015°/u) and the
   **flat radial-fade FOW** (rim height 0 — the bowl rim silhouetted badly).

## Next session order

1. Verify #18 (terrain in micro) + composition/exposure iteration with Aaron.
2. **#9 Refit flow** — open a built fleet ship in the shipyard, swap slot parts,
   removed parts return to stock, record updates in place. Oldest gameplay debt.
3. **P3 dive** — freeze the diorama rig and descend instead of the scene cut.
4. Backlogs C (sector grid), D (seeded wrecks), E (red zone rings).
5. Polish: ring translucency (went flat after far-plane push), proper starfield
   (SgtBackdrop), belt-seed body-name '' cosmetic, ring/dust brightness.

## Gotchas learned today (do not relearn)

- UIDocument SetActive → tree death; self-heal via `element.panel == null`.
- SGT: landscapes need SgtVolumeManager (scene) + SgtVolumeCamera (camera); rings
  need SgtLight or render black; SgtRingSystem.SourceMaterial null = MAGENTA;
  SkyboxStars is unusable under top-down cams; SgtRing is DEAD at runtime on the
  chart (use ring-mesh bounds for radii).
- MacroCombatHandoff.Consume() clears EnvironmentBodyName before the dresser runs —
  derive bodyId from the payload name.
- The stage must never sit inside the ring slab (black arc on tilt) — thin it and
  offset the plane.
- Helion zoom = MacroView1CameraController on [VesperionBootstrap].
