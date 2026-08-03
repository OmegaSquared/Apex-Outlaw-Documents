# α1.8/α1.9 — GROUND TIER: Implementation Plan (rev 3)

## REV 3 PIVOT (Aaron 2026-08-03, approved): THE GROUND *IS* THE SURFACE MICRO

> "We are going to remove the surface micro scene; instead dropping out of hyper speed will
> put you on the ground. So basically the ground IS the micro view for the surface. Leave
> macro alone, and the micro version is the ground level. Battles in this scene are fought
> about 150 m off the ground. This will simplify the game, removing an unneeded fight area."
> Rationale confirmed: "Fusion will need to work around ground anyway when we build base combat."

**What changed (SHIPPED in-session):**
- The surface macro's zoom-floor hyper drop now calls `DropToGroundTier()` → in-scene `EnterGround()` at the selected fleet's spot. No scene load; the CombatSandbox surface stage is unreachable.
- GROUND chip moved to the **surface chart** (live there, "You are here" at ground, hidden off-surface). Entry stays a **fleet action** — no fleet, no drop.
- Battle gating moves to the ground **exit** (battles are fought down here now) — lands with combat parity.

**Dormant-then-delete list (one slice of soak, then remove):**
- `PlanetSurfaceMacro.DropToMicro()` (marked ⚰ LEGACY, unreachable)
- `MacroCombatHandoff.SurfaceStageDrop` + the dresser's terrain-floor stage path
- `PlanetSurfaceMacro.PendingGroundEntry` / `LastMicroGroupId` (cross-scene plumbing the pivot obsoleted)
- Dev [G] key bridge on the macro chart (the chip + hyper drop cover it)

**Consequences for the remaining work:**
- Step 10 (micro-visibility pass) is **OBSOLETE** — the micro is the scene with the real seeded asteroids.
- Step 12 (combat parity) **GROWS**: terrain LOS (hills block fire/sensors), projectiles/beams hitting dirt, AI respecting ridges, and a one-battle float-precision soak at 1M-radius coordinates.
- Phase 4 note: surface Fusion battles are LOCATED in a persistent place (someone's base can be in the blast radius), not an instanced stage — a design decision to make deliberately when base combat lands.

## BUILD STATUS — updated 2026-08-03 (in-session)

| Step | Status | Notes |
|---|---|---|
| 1. `Tier.Ground` in PlanetSurfaceMacro (EnterGround/ExitGround) | ✅ DONE | dev [G] bridge on the macro chart still in — remove when zoom-drop lands |
| 2. Ground rig on native Draxxor (camera auto-wire) | ✅ DONE | planetCenter/planetRadius/landscape wired at EnterGround, never-silent fallback |
| 3. Precision check at ground zoom (1M radius) | ✅ DONE | play-tested by Aaron — drop lands on real terrain, no jitter reported |
| 4. `GroundContentSeeds` (game seed + A− player-seed grades) | ✅ DONE | determinism check PASS: 0 placement mismatches, 0 cap violations, grades differ per account |
| 5. GROUND button (micro-only) + `WorldTier.Ground` gates | ✅ DONE | chip hidden everywhere except the surface micro; SURFACE chip climbs back in-scene |
| 6. Zoom-floor drop entry + ground battle-exit gate | 🔶 REV 3 | hyper drop → ground SHIPPED (it IS the entry now); ground-side battle-exit block rides with combat parity |
| 7. Fleet descent + terrain-following hover | ✅ DONE | exact fleet group handed off (no re-resolve); opens at 150 m over terrain, ShipTerrainFollow from spawn; ▼/▲ bands attach/detach it |
| 8. Seeded stones (collect + per-player cloud persistence) | ⬜ TODO | seeds exist (StoneSet); spawner + SalvageItem collect + PlayFab collected-set pending |
| 9. Half-buried asteroids (mineable, per-player A− grades) | 🔶 CORE DONE | ~196 rocks per 6×6 km field, sink law, MinableRockFactory stack, per-player capped site grades; per-player DEPLETION persistence pending |
| 10. Micro-visibility pass (asteroids from surface micro) | ✂ OBSOLETE (rev 3) | the ground IS the micro — the real asteroids are already in the view |
| 11. Base building + land claim binding | ⬜ TODO | existing stack, mostly wiring |
| 12. Combat parity + final verification (terrain-identity test, docs) | ⬜ TODO | master_to_do.md cross-links land here |

Fixes shipped from Aaron's play tests: bridge-fleet masquerade (override group id + never-silent fallback warning), cruise-shell-high arrival (150 m ground band), invisible rocks (density retune 1° → 0.05° cells + landscape-readiness wait before seeding).


*Drafted 2026-08-03 from Aaron's brief + `Design_Documents/ground_tier_plan.md` (approved 2026-08-03). **Rev 2 (Aaron, same day): the ground you land on IS the terrain seen from the surface micro — "we are not loading another map, we are landing on what we see." This supersedes the approved doc's "generic Draxxor terrain patch" scope cut and reshapes WP1/WP2/WP5.***

## 0. The brief, restated

The fourth and final level of the world, where base building and planet-side mining live:

**Sector → Low Orbit → Surface macro → Surface micro → GROUND**

Aaron's requirements this plan must satisfy:

1. **THE SAME TERRAIN (rev 2, top priority):** dropping to ground lands on exactly the terrain visible from the surface micro — same planet, same heightfield, same spot. No separate map is loaded.
2. Use the designed planet — **Rubicon / Draxxor** (`Rubicon_surface`, native Draxxor prefab) — not the `Planet_01_surface` test scene. Planet_01_surface stays untouched as the reference rig.
3. **Stones + landed asteroids are placed by the GAME seed** — every player sees the same rocks in the same spots.
4. **Ore quality comes from the PLAYER seed**, capped at the on-planet grade cap. **DECIDED (Aaron 2026-08-03): the cap is A−, matching canon** (`world_resource_geography.md` / `BiomeZoneSchema`).
5. Ground is reachable **only from the surface micro** (you must already be down on the planet, in micro).
6. It gets **its own drop button** — not just the zoom-floor prompt.
7. The **half-buried asteroids are visible from the surface-level micro scene** — both from the air and from the ground — before you ever drop to the ground tier.
8. Combat scene end to end ("treat it like a micro scene") — full tactical stack, whole fleet descends together.

---

## 1. Architecture decisions

### 1.0 THE decision: ground is a tier of `Rubicon_surface`, not a new map

Requirement #1 is guaranteed **by construction**, not by matching: the ground tier lives **inside `Rubicon_surface`**, on the **same native Draxxor** (`SgtSphereLandscape`) the micro already flies over. The planet object never unloads. You descend on the terrain under the camera — literally landing on what you see.

Why this is the right call (and low-risk) in this codebase:

- `PlanetSurfaceMacro` already runs **two tiers in one scene** (`Tier.Macro` / `Tier.Micro`, `EnterMicro()` hands off to the held-back micro layer). Ground is the third: **`Tier.Ground`**. Same established pattern, one more state.
- The ground rig components are **already landscape-native**: `GroundBuildOrbitCamera` has an `SgtSphereLandscape landscape` field with analytic height + raycast floor; `GroundHover` queries `landscape.GetLocalPoint(...)`; `PlanetSurfaceContext` exposes radius/terrain queries. They were built for exactly this planet type.
- It **deletes the two worst risks** of the scene-swap design: the `Consume()`-before-`Start()` handoff-ordering trap goes away (same scene → direct method call, no static payload), and the "two scenes compute terrain independently and drift" risk cannot exist (there is only one terrain).
- Cross-tier asteroid visibility (#7) becomes trivial: the asteroids are spawned **once** on the planet and are simply *there* in micro and ground alike — not rendered twice from a shared seed.

**Heavy-stack loading:** the ground tier's extra content (full tactical combat stack, base-build UI) loads **additively** (`LoadSceneMode.Additive` from a lightweight `Rubicon_ground_stack.unity` content scene, unloaded on ascent) so `Rubicon_surface` doesn't carry it at boot. Additive load keeps the planet resident — the map never swaps. If profiling shows the stack is light enough, skip the additive scene and just hold the objects inactive like the micro layer already is.

**What happens to `Planet_01_surface` and the doc's "new `Rubicon_ground` scene":** Planet_01_surface remains the reference/test bed (unchanged). The "new scene built from its rig" becomes "its **rig components** mounted in `Rubicon_surface`'s ground tier" — same reuse, no map load. Update `ground_tier_plan.md` to record this supersession (rev 2 note + Aaron's words).

**Planet size (Aaron 2026-08-03): the ground tier runs on the native 1M Draxxor** — the same instance the surface macro mounts at the origin (`SurfaceNativeDraxxor`), consistent with the other levels. The 5M "Earth-sized" prefab stays what it is today: sector-diorama scenery, never the gameplay surface. **Watch item (not a blocker):** ground-level camera/physics at 1M radius (~6 cm float epsilon at the surface) is exactly what `GroundBuildOrbitCamera`'s dynamic clip planes + analytic-height safety floor were built for, but WP1 includes a precision check (jitter at ground zoom, collider raycast stability) before anything else is layered on. Fallback if precision fails: keep the tier in-scene but re-origin the planet transform on descent (float-origin shift), invisible to the player and still the same terrain object.

### 1.1 One deterministic content module

Placement logic lives in a pure, static module — scene-free so it's unit-testable, and so the game seed contract is in one file:

```
Assets/Scripts/Macro/Ground/GroundContentSeeds.cs   (new, pure functions, no scene refs)
Assets/Scripts/Macro/Ground/GroundAsteroidField.cs  (new, spawner)
Assets/Scripts/Macro/Ground/GroundStoneField.cs     (new, spawner)
```

- `GroundContentSeeds` — all hashing in one place (pattern: `SandboxBackdropDresser.WorldSeed(bodyName, chartFocus)`, promoted out of the dresser rather than copy-pasted a fourth time):
  - `AsteroidSet(bodyId, latLongCell)` → deterministic list of `(id, lat, lon, radius, rotation, categoryIndex)` from **game seed ⊕ body ⊕ cell**.
  - `StoneSet(bodyId, latLongCell)` → small collectible scatter, same hash family.
  - `OreGrade(alchemySeed, materialId, bodyId, asteroidId)` → byte grade, **clamped to the on-planet cap**. This is exactly the canon model in `world_surface_gathering.md` §Principle 4 (`hash(alchemySeed, materialId, bodySeed, position)`) — we implement the doc, nothing new is invented.
- `GroundAsteroidField.Spawn(bodyId, cell)` spawns each asteroid **once** on the native Draxxor: real `MinableRockFactory` construction (mesh, rigidbody, `TacticalHitbox`, `CollisionDamage`, `MacroAsteroidYield`). Visible from the micro's altitude and mineable at ground level — one object, both tiers. (If micro-altitude perf wants it, the physics/damage stack can sleep until `Tier.Ground` activates — visibility never changes, only interactivity.)

"Game seed" today is implicit — `WorldSeed(bodyName, pos)` is already identical for every player because it hashes authored names/positions. v1 keeps that (zero server work). If a title-level seed is wanted later, inject one int from PlayFab Title Data into `GroundContentSeeds` and every hash shifts together.

### 1.2 Half-buried placement

Sink each asteroid's center to `terrainHeight(lat,lon) − radius × 0.5` so roughly half protrudes, with terrain height from the **live landscape query** (`SgtSphereLandscape.GetLocalPoint()` — the same source `GroundHover` and `SurfaceResourceField` already use). One formula, one terrain, one object — the silhouette seen from the micro *is* the rock you land next to.

### 1.3 Player-seed quality, grade-A cap

- The player seed **already exists**: `PlayerProfile.alchemySeed` (`Assets/Scripts/Networking/PlayerProfile.cs`), already used for grade checksums and the scanner (`ResourceScannerPanel`).
- Grade resolution happens **at extraction**, per canon — the asteroid prop itself is grade-less and identical for everyone; when a player mines it, `OreGrade(...)` stamps the yield. Hook point: the existing `MacroAsteroidYield` mining flow, where the drop list is rolled → clamp grade there.
- The clamp is one constant in `GroundContentSeeds` (`OnPlanetGradeCap`) = **A−** (decided, matches canon).
- Mined-out state is **per-player** (everyone sees the asteroid; you deplete *your* asteroid). v1: per-player mined-tonnage map keyed by `asteroidId`, persisted with the collected-stones set (§1.5).

### 1.4 Access: WorldTier.Ground + a dedicated button

- Extend `WorldTier` (`FleetTierNav.cs`): `{ Sector, LowOrbit, Surface, Ground }`.
- `TierNavToolbar` gets a **GROUND chip** (pattern: existing MAP / SURFACE / LOW ORBIT / SOLAR SYSTEM chips). Gate in `CanView`:
  - enabled **only** when `CurrentTier() == Surface` **and** the surface scene is in **micro** (expose `PlanetSurfaceMacro.IsMicro` — the class already tracks `_tier`), otherwise greyed with a reason string ("Drop to the surface micro first." / "Enter micro to descend to ground."), same UX as the existing gates.
- The chip calls `PlanetSurfaceMacro.EnterGround()` directly — same-scene tier switch, no scene load, no handoff payload. The camera descends from where it is (the `FrameMacroArrival`-style hand-in that micro arrival already uses), so the player watches the terrain they were looking at come up to meet them.
- **DECIDED (Aaron 2026-08-03): button + zoom drop.** The zoom-floor `HyperspaceDropPrompt.DropOverride` route also points at `EnterGround()` from micro — consistent with every other tier.
- **Exit**: ESC/M climbs back to the surface micro (tier switch back + additive stack unload), with the engagement-blocks-transition check reused verbatim ("⚠ IN BATTLE" — living hostiles block the climb, same doctrine as the sandbox).

### 1.5 Fleet descent + persistence

- **Whole fleet descends together**: ships spawn just off the ground at the descent point, spaced by measured hull bounds (`SpawnHandoffLine` pattern), built from **real build records** via `NpcShipSpawner` so damage persistence (`ShipRecordLink`) rides along automatically. Because this is same-scene, the fleet records come straight from the live micro fleet — no static payload.
- **Per-player cloud state (v1, small):** collected-stone ids + per-asteroid mined tonnage → PlayFab (same store as `PlayerProfile`). Base persistence stays server-side **later** per the approved v1 scope cut (`SurfaceBaseStore` in-memory bridge, 6.9.A.tile.9).

---

## 2. Build order (work packages)

### WP1 — Ground tier mounted in `Rubicon_surface` (1 day)
1. `Tier.Ground` state in `PlanetSurfaceMacro` + `EnterGround()` / `ExitGround()` (pattern: existing `EnterMicro`).
2. Mount the Planet_01_surface rig components against the **native Draxxor**: `SurfaceFleetSpawner` (ground mode), `GroundBuildOrbitCamera` with its `landscape` field pointed at Draxxor's `SgtSphereLandscape` (carry over `planetCenter` / `planetRadius` / **`cruiseShellHeight`** semantics), held inactive until `EnterGround()`.
3. `Rubicon_ground_stack.unity` additive content scene (tactical stack + base UI) + Build Settings entry — or inactive-objects variant if profiling says it's light.
4. **Precision check at ground zoom on the 1M-radius native planet** (camera jitter, raycast floor stability). Decide float-origin fallback now, not later.

**Done when:** from surface micro, `EnterGround()` (dev key) descends onto the exact terrain under the camera; ESC climbs back; `Planet_01_surface` untouched.

### WP2 — Access: button + tier gates (½ day)
1. `WorldTier.Ground` + `TierNavToolbar` GROUND chip + `CanView` gates + `PlanetSurfaceMacro.IsMicro`.
2. Chip → 5s transit ring (`BeginTransitThen` pattern, same feel as every tier change) → `EnterGround()` at the current camera focus lat/long.
3. Battle-block on exit; chip greyed with reasons from macro, orbit, sector, map.

**Done when:** GROUND button works only from surface micro; every other tier shows the grey reason; ESC returns to micro with camera continuity.

### WP3 — Terrain-following hover (½ day)
Fleet spawns at `terrainHeight + hoverHeight` (derived from `cruiseShellHeight`); per-frame landscape query/raycast holds hover altitude as terrain rises/falls under flight (extends the right-click hold-altitude flight already in `SurfaceFleetSpawner`; `SurfaceAltitudeBands.Descend` handles the drop-to-base-level band; `GroundHover`'s landscape branch is the height source).

**Done when:** ships flown across a ridge keep constant clearance; no terrain clipping at speed.

### WP4 — Seeded content (1½–2 days)
1. `GroundContentSeeds` (hashing + grade clamp + unit-testable determinism).
2. `GroundStoneField` — per-cell stones (game seed ⊕ body ⊕ cell); fly-near collect into cargo via the `SalvageItem` pattern; collected ids persisted per player (stones stay gone *for you*).
3. `GroundAsteroidField` — half-buried `MinableRockFactory` rocks on the native Draxxor, mining through the existing `MacroAsteroidYield` flow, `OreGrade` clamp at extraction, per-player depletion.

**Done when:** two different machines with the same body/cell show identical rock layouts; two different accounts mine different grades (≤ cap) from the same asteroid; relog keeps your collected/mined state.

### WP5 — Asteroids visible from the surface micro (¼ day — mostly verification now)
The asteroids are the **same objects** in the same scene, so micro visibility is automatic. This WP is: spawn radius/LOD tuning so the field around the camera's cell(s) is populated while in micro (air and ground views), a perf pass at micro altitude (sleep physics until `Tier.Ground` if needed), and sight-check that half-buried silhouettes read at micro zoom.

**Done when:** an asteroid spotted from the surface micro — from the air or from the ground — is the very object you mine after pressing GROUND. Position, size, rotation identical because it never despawned.

### WP6 — Bases + land claim (1 day, mostly binding)
Bind the existing stack to the native Draxxor ground: `BaseBuildPanel` / `BaseDroneFleet` / `SurfaceTilePlacer` + `SurfaceBaseAnchor` (claim radius = the existing `claimRadiusMetres`; the Deployment Beacon from 6.9.A.tile.beacon replaces first-foundation-as-claim when it lands). The α1.7b repair-queue construction-drone speed factor plugs in here. Base persistence: in-memory bridge for v1 per the approved scope cut.

**Done when:** claim → place foundation → drones build, drawing from base storage; stones gathered by `AutoGatherWatchdog`/drone flow feed construction.

### WP7 — Combat parity pass (½ day)
Verify the full micro tactical stack at ground tier: weapons, targeting, ship cards, AI, minimap, damage persistence via `ShipRecordLink`, wreck salvage. Mostly free (it rides in with `NpcShipSpawner` + the sandbox control stack) — this WP is the checklist, not new code.

### WP8 — Verification + docs (½ day)
- Determinism test: dump `AsteroidSet`/`StoneSet` for N cells on two seeds/accounts → same-game-seed identical, grades differ per account, never > cap. (Editor menu-item test.)
- **Terrain-identity test (rev 2's acceptance test):** screenshot a landmark from micro altitude → drop to ground at that spot → the landmark and asteroid silhouettes match 1:1.
- Update `ground_tier_plan.md` (record the rev-2 supersession of the terrain-patch cut) + `master_to_do.md` Phase 4/6.9 cross-links; note bridges added (grade-cap constant, in-memory base store).

**Suggested sequence:** WP1 → WP2 → WP3 → WP4 → WP5 → WP6 → WP7 → WP8. WP4's seed module can be written in parallel with WP1–2 (it's scene-free by design). Total ≈ 5–6 working days.

---

## 3. Determinism spec (the contract)

| Thing | Seed inputs | Same for all players? | Notes |
|---|---|---|---|
| Asteroid position / size / rotation / category | game seed ⊕ bodyId ⊕ cell ⊕ index | **Yes** | ONE object on the native Draxxor — seen from micro, mined at ground |
| Stone scatter | game seed ⊕ bodyId ⊕ cell ⊕ index | **Yes** | collected-set is per-player |
| Ore grade of an asteroid's yield | `alchemySeed` ⊕ materialId ⊕ bodyId ⊕ asteroidId | **No — per player** | clamped to on-planet cap **A−** (decided, matches canon) |
| Depletion / collection state | player account state (PlayFab) | No | cloud-persisted |

---

## 4. Open questions for Aaron (none block WP1–3)

*(Decided 2026-08-03: grade cap = A− matching canon; entry = GROUND button + zoom-floor drop.)*

1. **Asteroid density**: rough target per cell / per screen? (TUNE value, but a starting number helps.)
2. "Asteroids that **hit** the planet": v1 ships a static seeded set. Do you want a seeded **impact schedule** as a follow-up — new asteroids appearing on a cadence, same time+place for all players (pure function of `CelestialClock.Now()` epoch, the `MaxDiscoveredGoods` pattern)? Fits the fantasy; costs one extra hash input.
3. Should the half-buried asteroids also read from the **surface MACRO** (zoomed-out globe), or is micro-only visibility the intent? (Brief says micro; macro would just be markers.)

## 5. Risks / bridges ledger

- **Ground-scale precision on the 1M-radius native Draxxor** (decided: same 1M as the other levels; the 5M Earth-sized prefab remains diorama scenery only) — the one real technical risk of rev 2. `GroundBuildOrbitCamera` already ships dynamic clip planes + an analytic-height safety floor for exactly this; WP1 step 4 proves it at ground zoom before anything stacks on top. Fallback: in-scene float-origin shift on descent (still the same terrain object — requirement #1 holds).
- **Additive-stack lifecycle** — the tactical/base stack must fully unload on ascent (no orphaned combatants/UI in micro). Checklist item in WP2/WP7.
- **Base persistence in-memory** (approved cut; 6.9.A.tile.9 lands PlayFab store).
- **Grade cap constant** duplicated from canon docs until a shared `WorldResourceRules` home exists — leave a `// BRIDGE` pointing at `world_resource_geography.md`.
- ~~Generic terrain patch ≠ drop-spot terrain~~ — **eliminated by rev 2** (same terrain by construction).
- ~~`Consume()`-before-`Start()` handoff ordering~~ — **eliminated by rev 2** (same scene, direct call; no static payload).
- ~~Two spawners drifting on sink math~~ — **eliminated by rev 2** (one object, spawned once).

## 6. File touch list

**New:** `Scripts/Macro/Ground/GroundContentSeeds.cs` · `GroundAsteroidField.cs` · `GroundStoneField.cs` · `Scenes/Planets/Rubicon_ground_stack.unity` (additive content, optional per WP1 profiling) · editor determinism-dump test.
**Modified:** `PlanetSurfaceMacro.cs` (`Tier.Ground`, `EnterGround`/`ExitGround`, `IsMicro`) · `FleetTierNav.cs` (`WorldTier.Ground`) · `TierNavToolbar.cs` (GROUND chip + gates) · `SandboxBackdropDresser.cs` (WorldSeed promoted/shared) · `MacroAsteroidYield` mining flow (grade clamp hook) · `PlayerProfile`/PlayFab store (collected/mined maps) · Build Settings · `ground_tier_plan.md` (rev-2 supersession note) / `master_to_do.md`.
**Untouched by design:** `Planet_01_surface.unity` (reference rig only — components reused, scene never loaded in the Rubicon flow), `MinableRockFactory`, `NpcShipSpawner`, base-build stack internals.
