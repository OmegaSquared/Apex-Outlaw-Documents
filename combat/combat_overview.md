# Combat — Category Overview

Real-time tactical combat happens inside short-lived **Photon Fusion event instances**. Combat is the only place authoritative physics matter, so the combat layer is the only place [`Networked]` state and tick-rate simulation are allowed.

## The combat instance in one paragraph

A combat instance is a Fusion runner spawned on demand by the macro layer when an engagement triggers. It accepts a pre-resolved `FleetSnapshot` for every participant (no formulas cross the boundary), runs authoritative tick simulation for flight, weapons, shields, capacitor, heat, and aggro, and at end-of-combat reports deltas back to PlayFab. **Hard cap: 3 vs 3 active combatants + up to 10 spectators (16 players max per instance).** Spectators see the fight but cannot fire, take damage, or contribute fleet stats.

## Key concepts

- **Three combat contexts (Phase 6.9 canon):**
  1. **Hyperspace intercept** — when a fleet in Solar (Scene 1) is caught by an attack-timer maturation, it drops into the existing blank-space combat sandbox (`shipmanagerTestFleet.unity` pattern). Pure interstellar combat with skybox + nearby-body backdrops. NOT Low Orbit, NOT Surface.
  2. **Low Orbit combat (Scene 2)** — when hostile fleets converge on a planet's orbital space and their server-side wide-FOW circles overlap, a `NetworkRunner` spawns for that cluster in-scene. Capitals can be present here.
  3. **Surface combat (Scene 3)** — same model as Low Orbit, but at surface altitude. Capitals are excluded (per the permit gate); only non-capital ships engage.
- **Authority is Fusion, not the client.** All damage application, shield/armor/hull math, capacitor drain, heat, and aggro live behind `HasStateAuthority` gates. Mod-resistant by design.
- **Damage-event accumulation → GPU shader arrays** is the *only* place Unity DOTS is in use right now (`Assets/Scripts/ECS/ShipDamageSystem.cs`). It's a visual subsystem, not the combat sim.
- **Three FOW scopes drive combat visibility.** My-client FOW renders ships; server-side wide FOW predicts encounters and pre-spawns Fusion runners; their-client FOW is asymmetric to mine. A ship can be networked without being rendered on the enemy's client — stealth ambush mechanics fall out of this naturally. See [`combat_fog_of_war.md`](./combat_fog_of_war.md).
- **Server-driven Fusion spawn.** `ServerFowMatcher` CloudScript detects fleet-encounter clusters proactively. Spawns one `NetworkRunner` per cluster (16-player cap each). Multiple parallel runners per planet are normal.
- **Signature & Minimap** drive both visibility and stealth play — a low-signature hull may not render as a dot at all on enemy minimaps. Surface bases additionally have **activity-noise radar stealth** (silent bases = off-radar but NOT invisible). See [`combat_minimap_signatures.md`](./combat_minimap_signatures.md).

## Docs in this category

| Doc | Purpose |
|---|---|
| [`combat_mechanics.md`](./combat_mechanics.md) | Flight engine, weapon firing arcs, e-war jammers, overheating, capacitor management. The high-level combat TDD. |
| [`combat_damage_aggro.md`](./combat_damage_aggro.md) | Shield → armor → hull math, armor curves, aggro / threat multipliers. |
| [`combat_tactical_scripts.md`](./combat_tactical_scripts.md) | Inventory of tactical-layer scripts (`TacticalFlightEngine`, `TacticalHitbox`, etc.) and their responsibilities. |
| [`combat_missile_system.md`](./combat_missile_system.md) | Missile fire-control, smart vs. dumb behavior, fog-of-war interactions. |
| [`combat_fog_of_war.md`](./combat_fog_of_war.md) | Sensor coverage volumes, fleet vision aggregation, jammer/nebula effects, spectator stream. |
| [`combat_minimap_signatures.md`](./combat_minimap_signatures.md) | Minimap rendering, hull signature curves, faction colors, dot-clustering. |

## Where this category sits in the build order
Combat is **Phase 4** of [`meta/meta_roadmap.md`](../meta/meta_roadmap.md). The Fusion layer is currently scaffolded — most of [`combat_mechanics.md`](./combat_mechanics.md) and [`combat_damage_aggro.md`](./combat_damage_aggro.md) is implemented; [`combat_fog_of_war.md`](./combat_fog_of_war.md) is a partial pass with the open work tracked in [`meta/master_to_do.md`](../meta/master_to_do.md) Phase 4.6. Server-authority hardening (Phase 4.5) is the immediate predecessor of any further combat content.
