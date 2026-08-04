# Session 2026-08-03 — α1.8/α1.9 GROUND TIER: plan → built in one session

**Headline:** the fourth world level exists. Sector → Low Orbit → Surface chart → **GROUND**
(the surface micro — battles at 150 m). Everything below is committed and compiling clean;
Aaron reviews next session. Live status table: `Design_Documents/ground_tier_implementation_plan.md` (rev 3).

## The two approved pivots (same day)
1. **Rev 2 — "we are landing on what we see":** no separate ground scene. The ground tier is
   `Tier.Ground` INSIDE `Rubicon_surface`, on the native 1M Draxxor. Terrain identity by construction.
2. **Rev 3 — "the ground IS the micro view for the surface":** the CombatSandbox surface stage is
   retired (dormant, delete after soak). Dropping out of hyper on the surface chart descends the
   SELECTED FLEET to the 150 m floor — a fleet action, camera rides along; no fleet, no drop.

## What shipped (by system)
- **Seeds** (`GroundContentSeeds`): game-seed placement (same rocks for every player) on
  EQUAL-AREA cells (lon cells widen 1/cos(lat) — kills the polar needle-lines Aaron screenshotted);
  avalanche-mixed per-rock RNG streams (kills lattice strings); sizes 6–55 u² skew; ore grade =
  hash(alchemySeed ⊕ material ⊕ body ⊕ asteroidId) **capped A−** (decided — matches canon).
  Editor proof: `Apex Outlaw → Ground Tier → Seed Determinism Check` (now includes the polar-spread
  criterion). Verified in-editor: 0 mismatches, 0 cap violations, 89.9°N cell spreads 1,056 m E-W (was 1.5 m).
- **Asteroids** (`GroundAsteroidField`): half-buried (center = terrain − r×0.5), MinableRockFactory
  stack (vein/hitbox/yield/RadarContact), kinematic; **per-player depletion** restored at spawn,
  banked to cloud on exit.
- **Stones** (`GroundStoneField`): fly within 60 m → stone flies aboard; collected ids cloud-pushed
  per pickup (stays gone FOR YOU). BRIDGE: primitive art; tonnage = session tally until cargo integration.
- **Flight:** fleet spawns at 150 m over each ship's OWN terrain (`ApplyGroundLevelBand`) with
  `ShipTerrainFollow` (eases shellRadius over ridges; min-clearance clamp); nav lines + arrowheads
  drape over terrain (`ConformNavPointToGround`); ▼/▲ bands attach/detach the follow.
- **Access/nav:** `WorldTier.Ground`; GROUND chip on the surface chart (hidden off-surface, "You are
  here" at ground); hyper drop = same action; SURFACE chip / [M] climb back in-scene. Honest greys everywhere.
- **Combat parity (code side):** `GroundTerrainOcclusion` — analytic terrain LOS (radar detection
  honors ridges; matches the scope's shadow wedges); projectiles detonate on analytic dirt (stats
  MISS); battle-exit gate (living hostile blocks [M]/chips); **dev [K] = mirror-enemy soak** (sandbox
  wiring + ground band + follow + engine handicap; tags player ships team-0).
- **Radar:** surface ships now get sandbox-style sensor wiring (self contact, part-gated ranges) —
  the scope works at ground; terrain-gap shadow wedges (48-bearing horizon walk, 2 Hz cache);
  obstacle blips 1–4 px scaled by physical rock size.
- **Persistence:** ground damage capture on despawn/scene-exit → `rec.dmg` → PlayerCloudStore (restore
  already worked); `PlayerProfile.groundStonesCollected` + `groundAsteroids` (client-written BRIDGE).
- **Base binding:** ownerId "test_player" bridge CLOSED at both record-creation sites (live PlayFab id);
  bodyId already context-sourced; claim prompt now DRONE-GATED (research-drone card arms it; fleet
  selection suppresses).
- **Cross-cutting fixes from Aaron's live testing:** micro stage anchors at the DROPPED FLEET, not the
  camera (ring drops land in the ring with mineable rocks); antimeridian unwrap on surface picks (the
  20 h ETA); night ambient floor inside `PlanetDayNightCycle` (it rewrites ambient per frame — one-shot
  floors get stomped); `Rubicon_surface` sun flipped to `syncToOrbitSun` (scene-saved) so orbit and
  surface agree on day/night; marquee selection ignores overlay renderers (nav lines etc. — the
  two-ships-stay-selected bug); ground WASD floored at 1.3× ship cruise.

## NEXT SESSION — in order
1. **Verify-pass in play** (one session): ring-drop mining · scattered rocks (no lines) · marquee
   single-select · radar blips/gaps/LOS · night + orbit/surface lighting agreement · sane ETAs ·
   damage round-trip · stone round-trip · base founding via drone card.
2. **[K] battle soak:** fight the mirror enemy — LOS feel, dirt impacts, AI vs ridges, float precision
   at 1M radius (float-origin fallback is scoped if it jitters), exit gate releases on win.
3. **Acceptance passes:** terrain-identity (micro landmark == ground landmark) + two-account determinism.
4. **Rev-3 deletion list** (after soak): `DropToMicro` + `SurfaceStageDrop` dresser path +
   `PendingGroundEntry`/`LastMicroGroupId` + dev [G]/[K] keys.
5. **Stakeouts:** firing-arc sound with no firing (probe playing AudioSources live — say "check" while
   audible); surface-macro movement bounce (possibly cured by the seam unwrap); one-time stale
   "HYPER → 1102 km" card status at ground.

## TUNE knobs parked
Asteroid density (4/cell, ring 3) + size range 6–55 · stone density/tons · night ambient floor
(0.26/0.28/0.34) · WASD 1.3× · terrain-follow smoothTime 0.6 / min-clearance 25 · arrival framing.

## Late-session additions (sector chart QoL — Aaron's "minor tweak" pair)
- **First-entry chart defaults** (`MacroHomeBaseCameraAnchor`): opening zoom is now
  `ChartOpeningOrtho = 55` (a const — Aaron's live-read pick; the serialized
  `OrthoSizeOnAnchor 50` is LEGACY and deliberately ignored). Centering rule, in order:
  first deployed fleet WITH a marker on this chart → home planet → first MacroPlanet.
  The chase-follow now rides the anchored FLEET too, not just the orbiting home planet.
  `ChartCameraRestorer` still wins on M-returns, as before.
- **Sector WASD hyper-chase floor** (`MacroView1CameraController` — the LIVE chart camera
  on `[VesperionBootstrap]`): pan is floored at `HyperChaseFactor (4/3) ×` the player
  fleet's live `EffectiveCruiseSpeed`, zoom-scaled from `hyperFloorOrtho 55`. Aaron's law:
  "WASD needs to be about 1/3 faster than the hyperspeed of the fleet."
  **FINDING:** the earlier sector pan bumps (1.5 → 2.4 + floor) went to
  `HelionCameraController`, which is NOT in the Helion scene — dead code; that's why they
  never felt different. Measured live before the fix: pan at ortho 55 = 3.17 u/s vs fleet
  hyper 2.4 u/s (already ≈1.32×), so the FLOOR is a guarantee more than a felt speed-up —
  if Aaron still reports slow WASD next session, the knobs are `HyperChaseFactor` and the
  scene-serialized `PanSpeedAtMaxZoom` (30, over-riding the script's 80), and consider
  whether the anchor chase-follow drag was the real culprit. `HelionCameraController` is a
  rev-3-style deletion candidate.
