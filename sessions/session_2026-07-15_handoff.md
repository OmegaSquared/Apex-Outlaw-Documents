# Session Handoff — 2026-07-15 (Helion v2 / View Tiers marathon)

**Read this first next session.** Canon lives in
`Design_Documents/world/world_view_tiers.md` (§3 dissolve, §3b render bubble,
§7a macro-as-background + grid + seeded junk, §7b presence + red rings).

## Where we are

- **Helion** (clone of Vesperion) is THE game system: Sun + **Rubicon** (red,
  goldilocks, ring belt r130–185, moons **Alea**/**Iacta**), gate
  `Rubicon_Neutral` offline on the inner circle (r85). Old Helion attempts =
  `*_Old`, disabled. LAUNCH SECTOR → Helion (legacy homes remap).
- **Macro↔micro loop WORKS**: chart max zoom-in (ortho **15.5**, Aaron-picked,
  persisted) → MacroCombatHandoff → **real CombatSandbox scene** with the
  player's recorded ships (side A, team 0) → **M/Esc returns** to Helion.
  Chevrons are REMOVED — markers are ship prefabs, hologram fallback.
- Aaron picked the sandbox max zoom-out LIVE: **distance 1951u**, direction
  (0, 1, -0.04), fov 60 — **NOT yet persisted in code** (was applied live only).

## ⚠️ Hard-won workflow rules

1. **NEVER compile / refresh scripts while Aaron is in play mode.** Domain
   reload wipes every static store (fleet, tier, hydration flags) — this WAS
   the "fleet store wipe bug" all along.
2. Play-mode component edits DO NOT persist — make scene changes in edit mode
   and SaveScene.
3. Playing Helion directly without MainMenu login = empty cloud stores = the
   handoff "glitches". (Fix #4 below removes this trap.)
4. read_console lies; `EditorUtility.scriptCompilationFailed` + big Editor.log
   tails are ground truth. Verify with my own A/B screenshots, never ask Aaron
   to eyeball what I can measure.

## Build backlog (in order)

**A. Queued micro-fixes (first compile window)**
1. Persist sandbox zoom-out: SandboxZoomLimiter fixed maxDist **1951**, entry
   frame = centroid + (0,1,-0.04)×1951; delete the computed seam math.
2. **M-only return**: remove the scroll-out-at-cap exit from SandboxZoomLimiter.
3. Graceful handoff failure: no ships → bounce ortho above worldExitOrtho +
   one HUD message (currently: silent retry stutter).
4. Dev auto-login: direct-play Helion kicks cached login + hydration.

**B. Finish the seam**
5. Background dresser INSIDE the sandbox: dress the sky from the handoff's
   map position (planet backdrop / in-ring rocks / giant gate). The parked
   `ViewTierMicroStage.BuildStage` code is the donor. This is
   "macro-as-background" made real.
6. M-return restores the exact chart camera position/zoom.

**C. The grid** (everything later keys off it)
7. World pos ↔ cell name ("K-12") math; HUD cell readout on the chart; micro
   scenes inherit parent cell. Supersedes MacroSectorContext/quadrants.

**D. Seeded world**
8. World-seed service (Title Data); hash(seed, cell) → contents.
9. Belt seeds onto the world seed; per-asteroid content seeds → scan/assay.
10. Rare seeded junk/wreckage per cell; radar-gated (large=macro, small=micro);
    wreck parts mint as SEVERED instances → crucible RE pipeline.

**E. Red rings & presence (pre-Fusion groundwork)**
11. Red activity ring on scene interactions; radius grows per joiner
    (reuse SpeedGovernor metresPerPart scaling); fleet pins to the object.
12. Spawn geometry: ring-creator fight = close (sandbox 2.6km dark start);
    joiner = ring EDGE, hunts inward.
13. Parked fleets ride their planet's reference frame.
14. PlayFab→Fusion silent conversion (Phase 4; keep scene state record-shaped
    for the migration seam).

**F. Standing debt**
15. Flight: cornering governor + hyper-cap audit in TacticalFlightEngine
    (~line 2236 hyperBoost inflates maxSpeed; brake zones sized off it; ships
    overshoot waypoints). Test with a SHIPYARD-BUILT corvette.
16. Rubicon surface reskin (still green test-planet terrain); Alea/Iacta
    PF+SGT surface+orbit scenes; hostile handoff template records;
    build-safe SGT material loads (now `#if UNITY_EDITOR`).

## Aaron's manual steps (pending)
- CloudScript **Push Revision** (player numbers, Helion/Planet_rubicon home).
- **DB wipe** → re-register as player **000001** (root admin) → starter kit,
  insurance, clean fleet all land fresh.
- Build a corvette in the Shipyard (starter kit has full parts) — the test
  article for the flight fix.
