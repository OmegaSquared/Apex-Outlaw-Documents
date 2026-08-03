---
status: canon
phase: "6.9"
last-reviewed: 2026-06-07
supersedes: "[[architecture_helion_scene_checklist]]"
tags: [architecture]
---

# Architecture — Category Overview

The technical backbone of Apex Outlaw. This category covers the hybrid PlayFab + Photon Fusion runtime split, how data flows between them, and the canonical C# data shapes the rest of the project consumes.

## The hybrid runtime in one paragraph

The game is split into **two runtimes** with a hard scope boundary. The **macro game** (sector maps, planet maps, shipyard, alchemy lab, market, inventory, fleet loadouts, all travel) runs on **PlayFab** with **lazy timestamp evaluation** — no 24/7 ticks, no Fusion runner. The **micro game** is short-lived **Photon Fusion event instances** spawned on demand for the only two interactions that need real-time authority: **combat encounters** and **mining ops**. Combat instances are hard-capped at **3v3 + 10 spectators (16 players max)**. Fusion is torn down at event end and canonical state flows back to PlayFab.

> **If a system isn't combat or a mining op, it does not get a Fusion runner.** That single rule prevents most architectural mistakes in this project.

## The three-scene world model (Phase 6.9 — canon as of 2026-05-29)

The macro world splits into **three Unity scenes**, each with its own scope, controls, and gameplay rules. The 2D rotating planet view (`Planet_<bodyId>.unity`) is **retired** — Helion is also superseded. See the meta-plan at `~/.claude/plans/if-i-was-going-mutable-parnas.md` for the full architecture.

| Scene | Role | Gameplay scope |
|---|---|---|
| **Scene 1 — Solar** | Existing sector-map view; **also represents hyperspace** | Fleet pointers, jump-gate nav, planet POIs render as 3D Planet Forge thumbnails (NEW). No Fusion in this scene — pure PlayFab macro. |
| **Scene 2 — Low Orbit** | 3D Planet Forge planet curving below | All fleet sizes welcome (capitals stay here). Orbital structures (docks, citadels, satcom, planetary defense, jump gates). Real 3D RTS ships via `TacticalFlightEngine` + `TacticalSelectionManager`. Fusion runners spawn per-engagement-cluster. Canon: [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md). |
| **Scene 3 — Surface** | Same Planet Forge planet at low altitude | **Permit-gated entry** (own base / allied / defenses defeated). Capital ships excluded. Surface bases at 3D (lat, lon), always rendered, radar-gated by activity noise. Canon: [`../world/world_surface_scene.md`](../world/world_surface_scene.md). |

Transitions:
- **Solar → Low Orbit:** voluntary planet entry, `SceneManager.LoadScene("LowOrbit")` with body ID handoff.
- **Solar → blank space combat:** interception (attack timer matures in Solar) drops into the existing `shipmanagerTestFleet.unity`-style sandbox. NOT Low Orbit, NOT Surface — pure interstellar combat.
- **Low Orbit → Surface:** permit-gated transition, capitals filtered out.

## Key concepts you should know

- **Lazy evaluation** — Macro state advances on read, not on a server tick. `Progress = (CurrentTime − DepartureTime) / (ArrivalTime − DepartureTime)`.
- **The Double-Schema** — Static blueprints (ScriptableObjects / JSON) define *what a thing is*; per-player instances store only `ModuleID + ResearchValue + Checksum`. The server recomputes stats authoritatively via `Mathf.Lerp(min, max, quality / 12345)`.
- **FleetSnapshot bridge** — When a combat or mining event starts, PlayFab bundles a `FleetSnapshot` with **pre-resolved stats** and hands it to Fusion. No formula crosses the boundary.
- **DOTS is not the combat sim.** Photon Fusion `[Networked]` state is the authoritative simulation. Unity DOTS in this project is currently a *visual subsystem only* (damage event accumulation → GPU shader arrays).
- **Fusion clusters, not Fusion per planet.** Each Fusion runner is hard-capped at **16 players (3v3 + 10 spectators per CLAUDE.md canon)**. Many parallel runners can coexist per planet — one per active engagement cluster. Most fleets at any planet are NOT in Fusion; they're in PlayFab macro state. Server-side `ServerFowMatcher` spawns runners proactively when wide-FOW circles overlap. See [`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md).
- **Three FOWs, three jobs.** Visibility is not one shared map:
  1. **My-client FOW** (narrow) — what THIS player's client renders.
  2. **Server-side FOW** (wide) — what the SERVER tracks; proactively predicts encounters and pre-spawns Fusion runners.
  3. **Their-client FOW** (narrow, asymmetric) — what the OTHER player's client renders.
  A ship can be networked by Fusion without appearing on the enemy's narrow client FOW — stealth ambush mechanics fall out of this naturally. Full doc: [`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md).
- **Activity-noise radar stealth (Surface).** Surface bases are **always physically rendered in 3D**. They appear as HUD/minimap markers for enemies only when generating noise (smelter, forge, drone build) that nearby enemy sensors detect. Silent = off-radar, NOT invisible. Visual scouting is a valid counter-strategy.
- **Helion unified world is RETIRED.** The previous Phase 6.7 attempt at a single continuous world is superseded by the three-scene model. Some Phase 6.7 mesh-FOW concepts (`syncRadius` per fleet) remain valid — the new server-FOW matcher reuses the same `SensorSchema` math.

## Docs in this category

| Doc | Purpose |
|---|---|
| [`architecture_plan.md`](./architecture_plan.md) | The foundational blueprint — runtime split, "What Runs Where" cheat sheet, factions, alchemy mechanic at a glance, double-schema. **Start here.** |
| [`architecture_backend_network.md`](./architecture_backend_network.md) | Backend & network TDD — PlayFab schema layout, lazy-eval handlers, CloudScript validation, Fusion instance lifecycle. |
| [`architecture_network_flow.md`](./architecture_network_flow.md) | Sequence diagrams for the macro ↔ micro hand-off — login, sector entry, combat entry, event end, state writeback. |
| [`architecture_data_schemas.md`](./architecture_data_schemas.md) | Global C# data shapes — `ItemSchema`, `ShipSchema`, `WeaponSchema`, `PlayerProfile`, etc. The "source of truth" structs. |
| [`architecture_ui_framework.md`](./architecture_ui_framework.md) | **UI & menu system** — the three UI layers (launcher / menus / HUD), `GlobalNavBar` as a registry-driven view, `GameMenuBase` + `MenuRegistry`, USS theming, scene-scoping, the full menu master plan + backend-pairing sequence. *(DRAFT — supersedes the Shift-uGUI framing of [`../social/social_menus_ui.md`](../social/social_menus_ui.md) on approval.)* |
| [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md) | **Scene 2** canon — Low Orbit gameplay, orbital POIs, RTS ship controls, server-FOW Fusion spawn. |
| [`../world/world_surface_scene.md`](../world/world_surface_scene.md) | **Scene 3** canon — Surface gameplay, permit gate, 3D-placed bases, activity-noise radar stealth. |
| [`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md) | Three-FOW model, `ServerFowMatcher` encounter prediction, activity-noise base reveal. |

## Where this category sits in the build order
Architecture work is **Phase 1** of [`meta/meta_roadmap.md`](../meta/meta_roadmap.md) — the foundation that everything else stacks on. Schemas land first ([`architecture_data_schemas.md`](./architecture_data_schemas.md)), then the PlayFab/Fusion split is wired ([`architecture_backend_network.md`](./architecture_backend_network.md)), then everything else.
