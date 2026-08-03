# View Tiers — One Simulation, Two Presentations

**Status:** CANON (Aaron 2026-07-15) · **Prototype host:** Helion (the live system map)
**Supersedes:** the macro→combat scene-handoff model (MacroCombatBridge → CombatSandbox as a destination).

---

## 1. The doctrine

There is **one simulation** of the world: fleet positions, orbits, time, FOW,
gates, patrols. The zoom level never changes *what is true* — only *how it is
drawn*. There is no second copy of the world, no scene handoff, no roster
freeze. Every seam bug we fought (handoff desync, roster locks, revolving-door
gates) lived at the old macro/micro stitch; this doctrine removes the stitch.

Two presentation tiers sit on top of that single simulation:

| | **MAP tier (macro)** | **WORLD tier (micro)** |
|---|---|---|
| Camera | top-down orthographic | perspective, low over the action |
| Fleets | one marker per fleet (chevron / ship-model icon) | the actual ships, per-record assembled builds |
| Speed | **HYPER SPEED** — strategy pacing, compressed | combat/flight pacing (SpeedGovernor floor) |
| Art language | flat cartographic: dashed orbits, annulus ring bands, labels, FOW tint | full 3D: SGT atmosphere, SgtRing, landscapes, exhaust FX |
| Combat | never resolved here | **fights happen here, in place** |
| Purpose | command: routes, gates, logistics, threat picture | presence: flying, mining, fighting |

The player moves between tiers with the mouse wheel (and M-key view cycling
inside the map tier). Crossing the threshold swaps PRESENTATION ONLY.

## 2. Why not all-SGT everywhere

SGT is a perspective-camera rendering toolkit. Under the stylized top-down
ortho map rig it is 0-for-3 (skybox sphere floods, skybox mesh floods, SgtRing
draws nothing — 2026-07-15). The flat map style is cheap, readable, and IS the
product at command range: it's a live starmap. SGT earns its keep exactly
where the micro tier lives. **Rule: cartographic assets above the threshold,
SGT assets below it.** Concrete example (canon): Rubicon's ring is layered
MacroAnnulusFill bands on the map; it becomes a real SgtRing only in the
zoomed-in perspective tier / orbit scenes.

## 3. Hyper speed & the fleet dissolve (Aaron 2026-07-15, clarified)

- Map tier: fleets move at the speed they have NOW — that IS hyper speed.
  No new multiplier, no time compression. MacroFlightController owns movement.
- **Zooming in = dropping out of hyper.** The fleet GROUPING DISSOLVES: the
  marker is replaced by the fleet's member ships as individual, real,
  per-record assembled builds. There is no fleet entity at this tier — you
  select and command SHIPS, and it feels and plays like CombatSandbox
  (same tactical flight, selection, weapons, AI), just in place in Helion.
  TacticalFlightEngine owns movement.
- **Zooming out = re-forming the fleet** and jumping back to hyper: ships
  collapse back into the fleet marker (fleet position = ship centroid),
  member state (hull damage, ammo) writes back to the fleet's ship records.
- **Engagement blocks the re-form:** a fleet in weapons/contact range of a
  hostile cannot regroup/re-enter hyper until disengaged. You cannot
  hyper-speed out of a battle; you cannot hyper-speed through one.
- Speed governance is therefore STRUCTURAL: each tier has its own movement
  system; the tier switch swaps which one is live. SpeedGovernor remains the
  micro-tier pacing clamp.

## 3b. The world-tier RENDER BUBBLE (Aaron 2026-07-15)

The world tier does NOT render the whole system in SGT fidelity. Only things
NEAR the ship come from the SGT world: the local planet/moon body, its ring
and belt rocks, nearby ships, stations, gates. Beyond the bubble radius,
bodies stay as cartographic impressions (distant discs / lights) or cull
entirely. One bubble radius constant governs dissolve (B5), SGT dressing, and
belt-rock streaming. This is also the future floating-origin seam: the bubble
is what gets rebased, the far field never needs precision.

## 4. The threshold

- View 1 free-zoom now spans ortho 15–520 in Helion.
- **Marker→ships swap: ortho ≤ ~60** (tunable constant, one place). Below it,
  MacroFleetVisualizer switches to ship-model mode (already built: geometry-
  only clones, single-marker contract) and then to true per-ship spawns as the
  micro tier matures. Above it, chevron/icon markers.
- Perspective blend (later phase): below ~ortho 30 the camera pitches from 90°
  top-down toward a low perspective angle and SGT dressing fades in.
- Hysteresis: swap thresholds differ by ~10% on the way in vs out so the
  presentation never flickers at the boundary.

## 5. What survives, what retires

- **Survives untouched:** Helion scene (world truth), JumpGateNetwork, FOW,
  MacroFleet/flight controllers, patrol AI, ship-record assembly
  (NpcShipSpawner), power/vitality derivation.
- **Evolves:** MacroFleetVisualizer (mode swap becomes zoom-driven),
  VesperionViewController (owns the threshold + hysteresis), SpeedGovernor
  (gains the engagement-revokes-hyper rule at map tier).
- **Retires:** CombatSandbox as a *destination* (stays as a test bench);
  MacroCombatBridge scene handoff; the notion of a separate "combat scene."

## 6. Migration phases

1. **P1 — threshold swap (BUILT 2026-07-15):** zoom-driven marker↔ship-model
   icon swap for all fleets in Helion (ViewTierController, ortho 60/68
   hysteresis) + ViewTier.Current/HyperSpeedActive statics. Placeholder for
   the real dissolve.
2. **P2 — the fleet dissolve:** below the threshold the fleet entity retires
   and its member ships spawn as real per-record builds at the fleet's
   position (the CombatSandbox spawn path, relocated in-scene), with sandbox
   tactical controls; zoom-out regroups them into the fleet and writes state
   back to the records. This replaces P1's model-icon.
3. **P3 — combat in place:** weapons/AI/damage live in the world tier;
   engagement blocks regroup; CombatSandbox handoff deleted (sandbox stays a
   test bench). SGT dressing (SgtRing, atmosphere) + camera pitch blend land
   here or alongside P2.
4. **P4 — scale/precision:** SGT floating-origin math if/when micro-tier
   distances demand it.

## 7. Implementation checklist (full breakdown, 2026-07-15)

**DONE**
- [x] Canon doc + doctrine (this file)
- [x] P1 ViewTierController: zoom threshold 60/68 w/ hysteresis, marker↔ship-model icon swap, ViewTier.Current / HyperSpeedActive / Changed event

**A. HUD layout split (per-tier layouts, Aaron 2026-07-15)**
- [ ] A1. ViewTierHudLayout: MAP tier hides the radar minimap (SurfaceMinimapHUD), drone queue (DroneStatusHUD), FLEET/DRONES tabs (CommandBarTabs) — those are micro menus. WORLD tier hides the sync/connection chips (MacroSyncMenu) and map-view switching.
- [ ] A2. Gate the M-key view cycle (VesperionViewController.Cycle) to MAP tier only — in micro you zoom out, you don't switch charts.
- [ ] A3. Decide remaining chips per tier: SectorContextHUD, BodyProximityHUD, fleet roster strip, top command bar.

**B. P2 — the fleet dissolve**
- [ ] B1. Dissolve: crossing the threshold replaces the fleet marker with per-record REAL ship spawns (CombatSandbox spawn path relocated: FleetShip.recordId → NpcShipSpawner assembled builds) in formation at the fleet position.
- [ ] B2. Suspend the MacroFleet entity while dissolved (marker hidden, MacroFlightController paused; the fleet record stays the source of truth).
- [ ] B3. Sandbox tactical controls in Helion: per-ship selection, marquee, move orders (the CombatSandbox/Mining selection stack).
- [ ] B4. Regroup on zoom-out: ships collapse to centroid → fleet re-forms → hull/ammo state writes back to ship records → macro flight resumes.
- [ ] B5. Dissolve bubble: only fleets near the camera dissolve; distant fleets stay markers even in world tier.
- [ ] B6. Scale bubble: define world-tier local scale (tactical ship sizes vs map units — MacroSceneScale bridge).
- [ ] B7. Transition polish: fade/blend, no flicker at the boundary (hysteresis already in).

**C. P3 — combat in place**
- [ ] C1. Weapons / combat AI / damage (SandboxCombatAI stack) live in the world tier.
- [ ] C2. Engagement rule: hostile contact BLOCKS regroup (no hyper-out of a fight) and forces nearby fleets to dissolve on approach.
- [ ] C3. Damage writeback: ship loss / part severing → fleet records → PlayFab (hooks into salvage, severed-part RE, and INSURANCE claims).
- [ ] C4. Retire the MacroCombatBridge scene handoff; CombatSandbox becomes a pure test bench.

**D. SGT dressing for the world tier**
- [ ] D1. Camera pitch blend below a low threshold (top-down ortho → low perspective) — SGT only works under perspective.
- [ ] D2. SgtRing for Rubicon in world tier; flat annulus bands fade out as it fades in.
- [ ] D3. Atmosphere/sky + sun light + starfield configured for the perspective view.
- [ ] D4. Body LOD: map disc ↔ CW/SGT body for planet + moons at the same threshold.

**E. Supporting systems**
- [ ] E1. Micro radar: SurfaceMinimapHUD fed by per-ship sensor profiles (radar/sonar) in world tier.
- [ ] E2. FOW semantics at world tier (per-ship reveal bubbles vs fleet bubble).
- [ ] E3. Performance pass: belt rocks + SGT + per-ship builds active together.
- [ ] E4. Exit/save semantics while dissolved (records are truth, so implicit regroup on scene exit — verify).
- [ ] E5. Long-term: do the separate orbit scenes fold into the world tier? (open)

## 7a. The macro world IS the micro background (Aaron 2026-07-15, CANON)

Loading a micro scene dresses its sky from your MACRO position — an extremely
zoomed-in view of the map itself. Over a planet (not in its orbit/surface
scene): the planet fills the background. In the ring: you are among the
asteroids. Near the jump gate: a massive gate looms. Nothing is invented for
the backdrop; it is the map seen from inside. (The parked stage-dresser code
in ViewTierMicroStage.BuildStage — planet backdrop placed by map bearing —
is the seed of this, relocated INTO the sandbox scene.)

**Asteroid determinism tiers:**
- MASSIVE asteroids: exist on the macro map itself — everyone sees them at
  chart level.
- ACTUAL asteroids in micro: generated from a GLOBAL seed — every player at
  the same location sees the SAME rocks in the same places (determinism
  replaces sync; MacroAsteroidBelt's seeded streaming is the kindred code).
- SMALL debris: random per instance — cosmetic filler.
- CONTENTS of an asteroid: driven by that asteroid's INDIVIDUAL seed — what
  is inside is its own discovery (pairs with scan/assay gameplay).

**The system GRID (Aaron 2026-07-15):** the ENTIRE solar system is overlaid
with a grid of player-readable coordinates — every position referenceable
("wreck at K-12", "meet me at F-4"). The grid is the language of navigation,
exploration and player communication: seeded junk lives at grid coordinates,
red rings get called out by cell, trade meetups happen at named squares. HUD
shows the current cell at all times on the chart; micro scenes inherit their
parent cell. (Kindred code: quadrant system + MacroSectorContext /
SectorContextHUD — the grid formalizes and supersedes them.)

**Seeded space junk & wreckage (Aaron 2026-07-15):** the game's scale is
MASSIVE, and the world seed sprinkles it — RARELY — with harvestable junk:
debris, wreckage, derelicts, all placed by the global seed so every player's
universe agrees. Detection is sensor-gated: LARGE objects show on macro
radar; SMALL ones only on radar inside the micro world. You stumble across
them by flying with your eyes open, not by quest marker. The long game:
MASSIVE ship wreckage seeded into deep space carrying FINDABLE TECH — wreck
parts feed the reverse-engineering/crucible pipeline (severed-sample rules),
so exploration is directly profitable. Rare enough to stay special.

## 7b. Multiplayer presence & instancing (Aaron 2026-07-15, CANON)

- **Micro never removes you from the world.** A player who drops into a micro
  scene leaves their fleet marker ON the macro map at its position — other
  players see it inside their FOW. Parked fleets ride their planet's
  reference frame (float with the orbit): a fleet "at Rubicon" stays at
  Rubicon.
- **Scene interactions broadcast.** Interacting with an object that loads a
  scene (mining an asteroid, a fight, a boarding) pins the fleet to that
  object and draws a RED ACTIVITY RING around it on the macro map — the same
  visual language as a combat ring. Mining is LOUD: everyone nearby knows
  someone is working that asteroid, while the player is inside the mining
  scene.
- **Instancing escalation.** The interaction scene runs as a PLAYFAB-backed
  single-player instance by default. When another player enters the red
  ring, it SILENTLY converts to a FUSION session — no loading screen, no
  announcement. The red ring is a broadcast, an invitation, and a warning at
  once. (The existing red-ring lock + MacroCombatBridge engagement flow are
  the seeds of this; Fusion conversion is the Phase-4 networking milestone.)
- **Encounter spawn geometry (Aaron 2026-07-15).** WHO creates vs joins the
  ring decides where ships start:
    · A fight that CREATES the ring (a direct attack) starts both sides
      FAIRLY CLOSE — beyond visual range, but close; the fight is on.
      (The sandbox's existing ~2.6 km dark-start spacing is this rule.)
    · A player JOINING an existing scene spawns QUIETLY AT THE EDGE of the
      red ring — no fanfare, no reveal — and must approach and FIND the
      occupant. Joining is a hunt, not an ambush spawn.
    · **The ring GROWS with every joiner** (fight or mining scene alike):
      each join expands the red ring, and the NEXT joiner spawns at the new,
      larger edge — progressively farther out. Ring size on the macro map
      therefore broadcasts the SCALE of what's happening inside, and big
      brawls are naturally harder to third-party (longer approach, more
      warning for those already fighting). Kindred mechanic already in
      code: the SpeedGovernor combat bubble scales its radius by part count
      (metresPerPart) — same principle, ready to drive the ring radius.

## 8. Open questions

- Time compression vs speed multiplication at map tier (current lean: speed
  multiplication only; world clock stays 1:1 so orbital state never forks).
- Do moons/planets also get LOD swaps (disc icon ↔ SGT body) at P2? (Lean: yes,
  same threshold constant.)
- Multi-fleet battles: when two fleets engage far from the player's camera,
  the sim resolves at world pacing regardless of who is watching (no
  observer-dependent outcomes).
