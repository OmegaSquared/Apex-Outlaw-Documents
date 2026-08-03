# World — Category Overview

The world category owns the **setting mechanics**: the Helion star system layout, sector rules, faction sovereignty/ownership, and the NPC doctrines that populate it. If a doc describes the place rather than a system mechanic, it lives here.

> **Lore split (2026-06-12):** the *narrative* — story bible, faction fiction, art/audio direction — moved out to [`../lore/`](../lore/README.md), which is **draft / non-canon**. World docs here are canon and must not depend on that lore being true.

## Helion in one paragraph

Apex Outlaw is set in the **Helion** star system — a fresh, barely-settled frontier reached through one colossal jump gate (the **Custos Gateway**) from an overpopulated **Sol**, which the Federation uses as a combined colony and penal dumping ground. *(Narrative premise is draft and lives in [`../lore/`](../lore/README.md); mechanics below do not depend on it.)* Two rival factions and a third pole partition the system: **FED** (Federation, blue, gate/registry authority; in-system face = Concordia customs) is the distant warden that exiles people in and skims the resource flow back to Sol; **ICE** (Iron Core, iron-red, homeworld Ferrum) is the dominant in-system power — renegade exiles who run the colony floor; the **Outlaws** (belters, smugglers, pirates) operate outside both. Mechanically FED and ICE are both claimable AI factions in a perpetual cold war. Most sectors have **no asteroids** — resource extraction concentrates in Asteroid Belt sectors and rare ring-bearing bodies, so chain-travel is part of the mining loop, not optional.

## Key concepts

- **Three-scene world model (Phase 6.9 canon)** — Solar (Scene 1, existing sector map = hyperspace), Low Orbit (Scene 2, NEW; 3D Planet Forge planet with all fleet sizes + orbital structures), Surface (Scene 3, NEW; permit-gated, non-capital ships only, activity-noise radar stealth). The old 2D rotating planet view is **retired**. Canon: [`world_low_orbit_scene.md`](./world_low_orbit_scene.md), [`world_surface_scene.md`](./world_surface_scene.md).
- **Sectors are PlayFab macro constructs**, not Photon rooms. A sector hosts zero or many concurrent Fusion combat instances; the sector itself is lazy-eval state.
- **Combat instance cap** — 3v3 + 10 spectators (16 max) per `NetworkRunner`. Multiple parallel runners per planet are normal — one per engagement cluster. See [`world_sector_rules.md`](./world_sector_rules.md) §1.
- **Inhabitable vs. hostile bodies** — Faction-core and environmentally hostile bodies are off-limits to player base-building; outer system + belts are player territory.
- **Jump Gate Network (dynamic — no central hub)** — Every planetary body hosts its own jump gate; each gate has a bubble-radius reach (1,500–8,500 units). A gate connects to another when that other gate's current world position falls inside its bubble. Because every body orbits deterministically (`CelestialClock` / `CelestialOrbiter`), the connectivity graph is recomputed every frame — routes open and close as planets drift. Most connections are transient windows of opportunity; only a few pairs are effectively permanent (the Castor↔Pollux twin asteroids, the Custos gateway). Implementation: `JumpGateNetwork.BubbleReaches` + `PredictDisconnectSeconds`. See [`world_sector_map.md`](./world_sector_map.md) §"Jump gate authoring canon".
- **Faction sovereignty** — Alliances of 50+ members can formally claim FED or ICE for two-way defense + tax. Planetary Defense platforms can be defeated; defeat triggers AI-base respawn elsewhere in Helion. Defeating planetary defenses also unlocks Low Orbit → Surface entry for non-allied attackers per the permit gate.
- **Solar System truth source** — `SolarSystem.unity` is hand-authored and canonical; sector builders mirror its patterns, not the other way around. See [`world_sector_map.md`](./world_sector_map.md) §"Jump gate authoring canon".

## Docs in this category

| Doc | Purpose |
|---|---|
| [`world_solar_map.md`](./world_solar_map.md) | Top-level Helion map: SystemView vs PlanetView, label rules, inline jump-gate timer chips, "Next 3 Departures" widget. |
| [`world_sector_map.md`](./world_sector_map.md) | Sector layout, jump-gate authoring canon, planet-orbit handoff (Scene 2 / Scene 3 transitions), fleet roster authority. |
| [`world_low_orbit_scene.md`](./world_low_orbit_scene.md) | **Scene 2 canon** — 3D Planet Forge planet, orbital structures, RTS ship control, server-FOW Fusion spawn. |
| [`world_surface_scene.md`](./world_surface_scene.md) | **Scene 3 canon** — surface zoom, permit gate, 3D-placed bases, activity-noise radar stealth. |
| [`world_planet_authoring.md`](./world_planet_authoring.md) | Canon recipe for adding a planet to a solar system (orbit rings, entry POI, jump gates, view-mode contract). Avernus = reference build. **Scene 1 / Solar view layer.** |
| [`world_resource_geography.md`](./world_resource_geography.md) | Helion expansion plan + resource-to-zone map. Frost-line geography, extraction-channel catalog, phased rollout (Main Belt → Goldilocks → gas giants → outer cold). |
| [`world_surface_gathering.md`](./world_surface_gathering.md) | Planet-side gathering loop — biome → deposit → harvest → crate → forge. On-planet A− grade cap, drone-gather (now) vs miner-scan (future) discovery split, biome system, deposit scatter. |
| [`future_ideas.md`](./future_ideas.md) | Designed-but-deferred system features (Fleet Graveyard, Generation Ship, Sun-Grazer Comet, Hollow Moon, Rogue Planet, etc.). Promotes to canon as dependencies land. |
| [`world_sector_rules.md`](./world_sector_rules.md) | Security tiers (high-sec / null-sec), instance caps, instance spilling. |
| [`world_faction_sovereignty.md`](./world_faction_sovereignty.md) | **Canon mechanics** — ownership model (`ownerId`), faction claims (50-member gate), planetary-defense defeat, the 50% planet-control rule, residency, non-member tax. Extracted from the old story-lore doc. |
| [`world_npc_ai.md`](./world_npc_ai.md) | NPC doctrines — Pirate flee logic, FED Police death fleets, ICE Garrison, NPC freighters. |
| → *narrative lore* | Moved to [`../lore/`](../lore/README.md) (draft / non-canon): story bible, art & narrative direction, glossary, extracted in-universe framing. |
| [`world_audio_vfx.md`](./world_audio_vfx.md) | Audio/VFX guidelines — vibration audio in vacuum, flash explosions, no fiery plasma. |

## Where this category sits in the build order
Sector and lore docs are referenced from **Phase 1 onward** — sector schema seeding lands in Phase 2.5 ([`meta/master_to_do.md`](../meta/master_to_do.md)), and the faction-claim / planet-control systems anchor Phase 5.5. Art and audio guidelines apply continuously and don't gate code.
