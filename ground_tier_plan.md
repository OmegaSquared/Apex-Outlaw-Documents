# α1.8 — THE GROUND TIER (Final Level)

*Plan approved by Aaron 2026-08-03. Build not started — this document is the source of truth for the next session.*

> **⚠ SUPERSEDED 2026-08-03 (same day, in-session) — BUILT, with two approved pivots.**
> The build shipped against [`ground_tier_implementation_plan.md`](./ground_tier_implementation_plan.md)
> (rev 3), which now carries the live status table and is the source of truth. What changed
> from THIS document:
> - **Rev 2:** no separate `Rubicon_ground` scene — the ground tier lives IN-SCENE inside
>   `Rubicon_surface` on the native 1M Draxxor ("we are landing on what we see"). The
>   "generic terrain patch" scope cut is void; terrain identity holds by construction.
> - **Rev 3:** the CombatSandbox surface micro is RETIRED — **the ground IS the surface
>   micro**. Dropping out of hyper on the surface chart descends to the 150 m floor; battles
>   are fought there. The α1.6i `DropToMicro` path is dormant pending deletion after soak.
> - Grade cap decided **A−** (matches canon); entry = GROUND button + zoom drop; the drop is
>   a FLEET action (no fleet, no ground); ships hold 150 m terrain-following altitude.

## What it is

The fourth and final level of the world, directly above the terrain:

**Sector → Low Orbit → Surface chart → Surface micro → GROUND**

- Entered **only from the surface micro** (you must already be on the planet).
- The **whole fleet descends together**, ships spawn spaced apart just off the ground.
- Ships **adjust to the ground level** — they hold hover altitude over the terrain as it rises and falls. Reference for the level and altitude: **`Scenes/Planets/Planet_01_surface.unity`** (its cruise shell height).
- **This is a COMBAT scene** ("there will be battles so treat it like a micro scene") — full tactical stack: weapons, targeting, ship cards, AI, damage persistence.
- This is where **bases are placed** and **mining happens**.

## Approved decisions

1. **New `Rubicon_ground` scene**, built from Planet_01_surface's rig. Planet_01_surface stays untouched as the reference/test bed.
2. **Whole fleet descends** — not one ship — and the tier is combat-capable end to end.

## What already exists (reuse, don't reinvent)

| Piece | Where | Provides |
|---|---|---|
| Ground rig | `Planet_01_surface.unity` | SurfaceFleetSpawner (cruise-shell park + right-click hold-altitude flight), GroundBuildOrbitCamera (planetCenter / planetRadius / **cruiseShellHeight**), base-build UI (BaseBuildPanel, BaseDroneFleet, BasePartInspectPanel) |
| Mineable rocks | `MinableRockFactory` / `MiningSandbox` | rock construction: mesh, rigidbody, TacticalHitbox, CollisionDamage, MacroAsteroidYield |
| Seeding | `SandboxBackdropDresser.WorldSeed(bodyId, pos)` | deterministic placement pattern |
| Ship spawns | `NpcShipSpawner` | real build records → tactical ships; damage persistence (ShipRecordLink) rides along automatically |

## Build order

1. **Scene** — `Rubicon_ground`: Draxxor terrain patch + rig copied from Planet_01_surface. Add to Build Settings.
2. **Descent** — drop-prompt at the surface micro's zoom floor (same pattern as every tier). Handoff carries body + lat/long + fleet records (MacroCombatHandoff-style — REMEMBER: the bootstrapper's `Consume()` runs before dresser `Start()`, and payload NAME conventions matter). Fleet spawns on the cruise shell spaced by measured hull bounds (SpawnHandoffLine pattern). Exit key climbs back to the surface micro/macro.
3. **Terrain-following hover** — spawn at `terrainHeight + hoverHeight` (from cruiseShellHeight); flight holds altitude via per-frame terrain raycast.
4. **Seeded ground content**
   - **Small collectible rocks**: per terrain cell, seeded by **GAME seed ⊕ body ⊕ cell** — every player sees the same rocks in the same spots. Fly near to collect into cargo (SalvageItem pattern). Per-player collected-set persisted to the cloud so they stay gone for you.
   - **Half-buried asteroids**: position / size / rotation from the **GAME seed**; center sunk at `terrainHeight − radius × 0.5` so roughly half protrudes. **Ore QUALITY / grade from the PLAYER seed** (playerId hash ⊕ asteroidId) — everyone sees the same asteroid, each player mines their own quality. Mining uses the existing MacroAsteroidYield flow.
5. **Bases** — bind the existing BaseBuildPanel / drone stack to this scene's ground. (The repair queue's construction-drone speed factor from α1.7b plugs in here.)
6. **v1 scope cuts** — generic Draxxor terrain tagged with lat/long (exact terrain match to the drop spot is a follow-up, same as the surface micro backdrop); base persistence server-side comes in a later α slice.

## Related docs

- Project memory: `ground-tier-plan`, `fleet-spaces-travel`, `damage-repair-spec`
- `Design_Documents/meta/master_to_do.md` — Phase 4 / 6.9 entries this connects to
