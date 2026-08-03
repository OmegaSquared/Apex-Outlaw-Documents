---
status: active
phase: 4
last-reviewed: 2026-06-21
supersedes: []
---

# Universal Speed Governor — Hyper Cruise, Combat Bubbles & Battle Tiers

**Status:** canon. Generalizes the v1 surface-only implementation (Aaron 2026-06-12,
`Planet_01_surface`) into ONE governor that runs in **every** scene — deep space (Solar)
and around planets (Low Orbit / Surface) — over a pluggable movement surface. The PvP
battle-server handoff is Phase 4; everything below it is buildable on the current macro
layer.

## The one-sentence model

**Zoom level *is* travel mode.** Zoomed out = hyper cruise (cheap, local, strategic);
zoomed in = sub-light tactical (where fights happen). A **hostile** contact while cruising
auto-drops you out of hyper and snaps the camera in — and *that* is where a battle begins.
Whether a battle *server* spins up depends on who's in the bubble (see Battle Tiers).

This is universal: the only thing that changes between open space and a planet is the
**surface** the rule runs on — flat out in space, curved around a planet.

## Why

Travel must be FAST, combat must be SLOW, and the switch between them is the
server-relevant event: sub-light is a (potential) Fusion combat server's domain; hyper is
local/cheap movement that never touches Fusion. Coupling that switch to camera zoom makes
it legible to the player — you can see your travel mode by how far you're zoomed.

## Core rules

### 1. Zoom = speed mode (zoom is master)
- The camera's tiered zoom already splits into an **orbital/strategic band** (far) and a
  **tactical band** (near) — e.g. the Low Orbit camera's ~18 km boundary
  ([`world_low_orbit_scene.md`](../world/world_low_orbit_scene.md)).
- **Zoomed out (strategic band):** hyper cruise allowed.
- **Zoomed in (tactical band):** hyper **force-denied** (added as a restriction). This is
  the "zoomed-in = not in hyper" rule.
- Because hyper can only run while zoomed out, "in hyper ⟹ zoomed-out view" follows
  automatically — no separate rule.
- **Auto-transitions:** issuing a long cruise order eases the camera OUT into the strategic
  band; a hostile contact / bubble **snaps** the camera IN to the tactical band (you are
  pulled out of warp to fight). The player regains manual zoom control once no bubble
  overlaps them.

### 2. Hyper cruise
While in the strategic band AND not restricted, ships fly at `hyperFactor` × normal speed
(current: 16×, surface). Hyper ramps in over ~2 s and drops **instantly** when restricted.
Hyper ships are identified by the `HYPER` tag on the fleet card (+ optional ion ribbon).

### 3. Restrictions — hyper denied (sub-light enforced) when:
- a combat bubble overlaps the ship,
- the camera is in the **tactical band** (rule 1),
- the ship is inside **any base's claim zone** (not just its own — running into a base area
  throws an automatic slowdown),
- a fight is active for that fleet,
- the ship is landed / has no movement order.

### 4. Combat bubbles (hostile-only)
When two fleets of **different, mutually-hostile owners** close within warning range
(current: 2,500 m) a bubble forms:
- **Center** = halfway point between the contacts, **projected onto the active surface**.
- **Radius** = base 600 m + 6 m × total ship PARTS inside (a battleship inflates it far
  more than a fighter).
- Both sides get a **CONTACT warning** that fires PAST visual FOW (you learn a fleet is
  near before you can see it).
- More hostile owners entering → parts join the count → bubble **grows**.
- **Lock:** past 500 parts the bubble closes; owners not already inside are pushed back at
  the rim and cannot enter.

**Friend-or-foe gate (new, critical).** Only **hostile** contact forms a bubble / drops
hyper. Allies (same alliance — faction IS an alliance, see
[`world_story_lore.md`](../world/world_story_lore.md) §3) fly past each other at hyper
freely. Without this, allies perma-interdict each other and a single cheap NPC could pin a
capital fleet forever. Pair with a short **post-drop cooldown** so a fleet can't be
chain-interdicted.

## Movement surface abstraction (the "universal" part)

Do **not** write a space version and a planet version. The governor reads from one
`IMovementSurface` so the same hyper/bubble/zoom code runs everywhere:

| Concept | Flat (deep space) | Spherical (around a planet) |
|---|---|---|
| Distance metric | planar (XZ) Euclidean | great-circle (geodesic) on the shell |
| "Up" for rings | world +Y | radial from planet center |
| Bubble center projection | onto the flat plane | onto the shell sphere |
| Rim pushback | planar | along the geodesic toward the rim |
| Provider | new `FlatMovementSurface` | existing `PlanetSurfaceContext` (already orients bubble rings radially) |

At small radii geodesic ≈ planar, but authoring the abstraction up front keeps the planet
and space behaviors from drifting into two code paths. The curved flight shell (see
[`world_orbital_shield_gates.md`](../world/world_orbital_shield_gates.md) / low-orbit) is
the spherical surface; deep-space sectors supply the flat one.

## Battle tiers (what happens after the drop)

Contact → drop → zoom-in → a battle begins. Which kind depends on who is in the bubble:

- **Tier 0 — Cruise.** No hostile contact. Hyper, strategic zoom, no server. Default.
- **Tier 1 — PvE (vs NPC), no battle server.** A player vs only NPC fleets in the bubble.
  **No Fusion runner.** The client renders a local tactical fight (`TacticalFlightEngine`
  runs locally), but the **outcome is resolved authoritatively server-side** — CloudScript
  resolves the `FleetSnapshot` vs the NPC roster (deterministic / seeded so the server can
  verify). Per the hard rule, the client never decides loot/losses. PvE is the easiest
  cheating surface; keep resolution on PlayFab.
- **Tier 2 — PvP, battle server.** Two or more **player** owners in the bubble → spin up a
  **Fusion combat instance** (lazy, in-place — no scene swap), hand off each fleet via
  `FleetSnapshot` (architecture_data_schemas §6), cap 16 players/runner. This is the only
  tier that uses Fusion. **Phase 4.**
- **Promotion (Tier 1 → Tier 2).** A player is mid-PvE (local, no server) and a second
  player enters the bubble. The local skirmish must **upgrade live** to a Fusion instance:
  spawn the runner, inject both players' fleets (and the contested NPCs) via `FleetSnapshot`,
  hand authority to Fusion. This is the trickiest path in the design — spec it explicitly,
  don't discover it. **Phase 4.**

## Planet base zones

Entering **any** base's claim radius forces sub-light (rule 3). v1 already does this for the
player's *own* base; generalize to all bases so flying into a contested base area drops you
out of hyper the same way a fleet contact does. On a planet this zone is a spherical cap on
the shell; in space (stations) it's a flat disc — same `IMovementSurface` handles both.

## Phasing & bridges

**Buildable now (macro layer, no Fusion):**
- The universal governor + `IMovementSurface` (flat + spherical).
- Zoom ↔ speed-mode coupling (tactical band denies hyper; cruise auto-zooms out; contact
  snaps in).
- Friend-or-foe gating + post-drop cooldown.
- Base-zone slowdown for all bases.
- Tier 1 PvE *visual* fight locally, with the **outcome bridged** (`// BRIDGE: PvE outcome
  resolution — replace local result with CloudScript-authoritative resolution`).

**Phase 4 (combat):**
- Tier 2 PvP Fusion runner spawn + `FleetSnapshot` handoff (hooks exist:
  `MacroCombatBridge` stub, `FusionCombatServer`).
- Tier 1 → Tier 2 promotion hand-off.
- `ServerFowMatcher` server-side hostile detection (replaces client-side proximity scan for
  the multiplayer case).

All bridges tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md) "Bridge code to
remove", Phase 4.

## Implementation map

**v1 (implemented, surface-only):**
- `TacticalFlightEngine.hyperBoost` (terminal-velocity multiplier) + `ownerId`.
- `SurfaceHyperDrive.cs` — `HyperDriveGovernor` (engage/disengage) + `CombatBubbleManager`
  (pair detection, midpoint bubbles, parts-driven radius, 500-part lock, rim pushback,
  contact warnings, in-world ring). `DrawBubbleRing` already orients radially via
  `PlanetSurfaceContext`.
- Card tag: `FleetRosterHUD` ETA line shows `HYPER` while boosted.

**Generalization (v1 LANDED 2026-07-06 — `Assets/Scripts/Tactical/SpeedGovernor.cs`):**
- `SpeedGovernor` (scene-agnostic singleton, `Ensure()`) parameterized by an `IMovementSurface`
  (`FlatMovementSurface` for space/sandbox, `SphericalMovementSurface` for a planet shell) —
  DONE. Hyper-cruise (`hyperBoost` ramp gated on a move order + `!IsRestricted`), hostile-only
  combat bubbles by `ownerId` (`AreHostile` hook), parts-driven radius, in-world ring. Wired into
  `CombatSandbox` (flat surface, ships tagged `ownerId` T0/T1 per team). **Verified:** a hostile
  entering warning range forms a bubble and both ships drop sub-light. Remaining: camera zoom↔
  speed-mode coupling, post-drop cooldown, base-zone slowdown, the battle-tier dispatch (PvE-local
  / PvP-Fusion / promotion), and porting the surface scene off `SurfaceHyperDrive` onto this.
- Add the camera-band hook: the active camera reports `IsTacticalZoom` → feeds `IsRestricted`.
- Friend-or-foe via `ownerId` + alliance lookup; cooldown timer per fleet.
- Battle-tier dispatcher: count distinct **player** owners in a locked bubble → Tier 1 vs
  Tier 2; wire Tier 2 / promotion to the Fusion handoff when Phase 4 lands.

## Open questions

- Exact tactical-band zoom threshold per scene (Solar vs Low Orbit vs Surface) — reuse each
  camera's existing tier boundary or define a shared one?
- Cooldown duration + whether a fleet fleeing a lost fight can re-hyper immediately.
- PvE resolution model: deterministic closed-form (`FleetSnapshot` vs NPC stats) vs
  seeded-sim the server re-runs. Affects how "fair" PvE feels vs how cheap it is to verify.
- Promotion fairness: does the NPC fight's current state carry into the Fusion instance, or
  does Tier 2 start fresh when the second player arrives?

## See also

- [`combat_overview.md`](combat_overview.md) — combat category index
- [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md) — seamless zoom, in-place Fusion spawn, FOW matcher
- [`../world/world_orbital_shield_gates.md`](../world/world_orbital_shield_gates.md) — the curved flight shell (spherical surface)
- [`../architecture/architecture_data_schemas.md`](../architecture/architecture_data_schemas.md) §6 — `FleetSnapshot` macro→Fusion bridge
- [`../world/world_story_lore.md`](../world/world_story_lore.md) §3 — faction = alliance (friend-or-foe ownership)
- [`combat_fog_of_war.md`](combat_fog_of_war.md) — FOW; contact warning must stay earlier than visual reveal
