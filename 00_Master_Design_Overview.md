# Master Design Overview & Project Index

> **⚠ Setting note (updated 2026-06-22 — penal-colony premise):** The game is set in the **Helion** star system — a fresh, barely-settled frontier reached through one colossal jump gate (the **Custos Gateway**) from an overpopulated **Sol**. The Federation uses Helion as a combined colony and **penal dumping ground**: it exiles surplus population and convicts through the gate, and the player starts as one of those exiles. Canonical factions: **FED** (Federation, homeworld Concordia/Sol authority, blue — the distant warden), **ICE** (Iron Core, homeworld Ferrum, iron-red — renegade exiles who run the colony from the inside), and the **Outlaws** as the third pole (no central authority). Full premise: [`lore/lore_story_bible.md`](./lore/lore_story_bible.md). Legacy faction labels ("Martian Republic", "Belt", "PACT") in older sections are **placeholders** being phased out — do not introduce new content using the legacy names. *(Naming history: the Federation faction was briefly renamed PACT (2026-05-03) and reverted back to "Federation" with tag "FED" on 2026-05-16. Legacy `"PACT"` strings in PlayFab data are handled by the [`Common/FactionId.cs`](../Assets/Scripts/Common/FactionId.cs) normalization shim.)*
>
> **⚠ Celestial registry as canon (2026-05-04):** Body and POI placement is **not** hand-authored in `SolarSystem.unity` anymore — the canonical source is the `CelestialRegistry` PlayFab title-data key (mirrored locally at `Assets/GameData/Celestial/seed.json`). New bodies and POIs are added by editing the registry, not by hand-baking into the scene. See [`architecture/architecture_plan.md`](./architecture/architecture_plan.md) §1.5 for the design and [`meta/master_to_do.md`](./meta/master_to_do.md) Phase 6.0 for status.
>
> **⚠ Territory as bubble geometry (2026-05-16):** Faction / alliance territory is measured the same way the jump-gate network is — as **bubble radii centered on owned anchors** (faction capitals, alliance citadels, StatComs). A point is "in PACT space" iff it falls inside any FED-owned anchor's bubble. Emergent space types (lawless, core, patrolled, contested) drop out of bubble overlap. No hand-authored sector-ownership lists. Canon: [`world/world_territory_bubbles.md`](./world/world_territory_bubbles.md).
>
> **⚠ Three-scene world model (2026-05-29 — Phase 6.9 canon):** The world view splits into **three Unity scenes** — Solar (Scene 1, existing sector map = hyperspace), Low Orbit (Scene 2, NEW; 3D Planet Forge planet with capital ships + orbital structures), and Surface (Scene 3, NEW; permit-gated, non-capital, activity-noise radar stealth). Old 2D rotating planet view (`Planet_avernus.unity`, `Planet_praedo.unity`) is **retired**; Helion unified-world is **also retired**. FOW splits into **three scopes**: my-client (narrow, renders), server-side (wide, predicts encounters + spawns Fusion runners), their-client (asymmetric). Canon docs: [`world/world_low_orbit_scene.md`](./world/world_low_orbit_scene.md) (Scene 2), [`world/world_surface_scene.md`](./world/world_surface_scene.md) (Scene 3), [`combat/combat_fog_of_war.md`](./combat/combat_fog_of_war.md) (three-FOW model + activity-noise), [`architecture/architecture_overview.md`](./architecture/architecture_overview.md) (full architecture). Meta-plan: `~/.claude/plans/if-i-was-going-mutable-parnas.md`.

## Welcome to the Game Design Document (GDD)
This folder is the complete, canonical blueprint for **Apex Outlaw** — a sandbox space MMO set in the post-Earth Helion system. The architecture is hybrid: **PlayFab** handles the slow-paced macro game (sector & planet maps, inventory, crafting, travel), and **Photon Fusion** handles short-lived tactical event instances. **Combat instances are capped at 3v3 active combatants + up to 10 spectators (16 players max per instance).**

Progression is **lateral and gear-dependent** — no character XP. Specialization is by gear and territory: Researchers, Miners, Transporters, Pirates, Mercenaries operate inside a chained economy gated by the **12,345 Alchemy Matrix** (per-player procedural resource heatmaps).

---

## How this folder is organized

The docs are split into **twelve categories**. Each category folder has an `<category>_overview.md` that gives a one-page orientation and links to the detail docs. Start at the overview for any unfamiliar area. Categories 1–11 are **canon**; the **Lore** category (12) is **draft / non-canon** — the story is still up in the air, so mechanics docs never depend on it.

| # | Category | Overview | Covers |
|---|---|---|---|
| 1 | **Architecture** | [`architecture/architecture_overview.md`](./architecture/architecture_overview.md) | Hybrid PlayFab/Fusion split, backend, network flow, data schemas |
| 2 | **Economy** | [`economy/economy_overview.md`](./economy/economy_overview.md) | 12,345 Alchemy heatmap & tech tree, universal DOM exchange (Bid/Ask, Maker/Limit/Stop, hidden floors), freight contracts, NPC auto-arbitrage, faction loans + planet tax + resource permits, black market + clean-goods doctrine, repair, monetization, trade |
| 3 | **Combat** | [`combat/combat_overview.md`](./combat/combat_overview.md) | "Navy battle in space" doctrine (kinetic-first, lasers-as-PD, four-pillar PD), tactical mechanics, damage/aggro math, missiles, fog of war, minimap |
| 4 | **Ships** | [`ships/ships_overview.md`](./ships/ships_overview.md) | Hull/weapon schemas, ship classes, Transporter family + Mining Outposts, naval close-combat (ramming, four-mechanism tow), hacking modules, ship AI, weapon catalogs |
| 5 | **World** | [`world/world_overview.md`](./world/world_overview.md) | Sector map & rules, territory bubbles, faction sovereignty/ownership, NPC AI, audio/VFX |
| 6 | **Progression** | [`progression/progression_overview.md`](./progression/progression_overview.md) | Dossier & infamy |
| 7 | **Social** | [`social/social_overview.md`](./social/social_overview.md) | Alliance/guild mechanics, menus & UI |
| 8 | **Pipelines** | [`pipelines/pipelines_overview.md`](./pipelines/pipelines_overview.md) | Canonical schema-driven authoring pipelines (the six-stage pattern + per-content-type docs for base parts, ships, weapons, recipes, resources, containers, contracts, celestial) |
| 9 | **Meta** | [`meta/meta_overview.md`](./meta/meta_overview.md) | Roadmap, todo list, color/text reference |
| 10 | **Ground Base** | [`ground_base/ground_base_overview.md`](./ground_base/ground_base_overview.md) | Surface base building, production tech tree (mine→smelter→forge→assembly), parts & supply chain, build-order gating, wiring |
| 11 | **Code Map** | [`code_map/code_map_overview.md`](./code_map/code_map_overview.md) | Where the code actually lives — per-system maps of key files, entry points, singletons, cross-system handoffs, legacy traps. Read the relevant map before touching an unfamiliar system. |
| 12 | **Lore** *(draft / non-canon)* | [`lore/README.md`](./lore/README.md) | World-fiction only — story bible, art & narrative direction, naming glossary, extracted in-universe framing. Subject to change; mechanics never depend on it. |

---

## Quick links by topic

- **"How do I add new gameplay content?"** → [`pipelines/pipelines_overview.md`](./pipelines/pipelines_overview.md) *(canonical schema-driven pipeline pattern + per-content-type docs)*
- **"How do I add a new base part?"** → [`pipelines/pipeline_base.md`](./pipelines/pipeline_base.md) *(the reference pipeline shape)*
- **"How do I build out a ground base?"** → [`ground_base/ground_base_overview.md`](./ground_base/ground_base_overview.md) *(supply chain, production tech tree, built-vs-todo board)*
- **"Where does this code go?"** → [`architecture/architecture_plan.md`](./architecture/architecture_plan.md) §3.0 *(What Runs Where)*
- **"Where does this code LIVE?"** → [`code_map/code_map_overview.md`](./code_map/code_map_overview.md) *(per-system maps: key files, entry points, singletons, traps)*
- **"How do menus / the nav bar / UI work?"** → [`architecture/architecture_ui_framework.md`](./architecture/architecture_ui_framework.md) *(three UI layers, registry-driven nav bar, `GameMenuBase`, USS, the full menu master plan)*
- **"What's the cap on a Fusion instance?"** → [`world/world_sector_rules.md`](./world/world_sector_rules.md) §1
- **"How do I add a weapon?"** → [`ships/ships_weapon_schema.md`](./ships/ships_weapon_schema.md) + [`ships/ships_weapons_armaments.md`](./ships/ships_weapons_armaments.md)
- **"How do markets / DOM work?"** → [`economy/economy_exchange_pricing.md`](./economy/economy_exchange_pricing.md) *(universal order book, bespoke listings, maker's mark, repair, black market, regional pricing, 60-day retention)*
- **"How does the Transporter role earn?"** → [`economy/economy_freight_contracts.md`](./economy/economy_freight_contracts.md) *(contract lifecycle, Hauler Profile reputation, alliance shipment manifest)*
- **"How do faction loans / planet tax / resource permits work?"** → [`economy/economy_obligations.md`](./economy/economy_obligations.md) *(reputation-gated borrowing, weekly tick, three-tier NPC enforcement including unwinnable default raids)*
- **"How does the NPC economy keep markets liquid?"** → [`economy/economy_npc_arbitrage.md`](./economy/economy_npc_arbitrage.md) *(autonomous trading posts, AI transports, NPC miners, adaptive escort)*
- **"What's the combat doctrine?"** → [`ships/ships_weapons_armaments.md`](./ships/ships_weapons_armaments.md) §0 *("Navy Battle in Space" — kinetic-first, lasers-as-PD, four-pillar PD)*
- **"Is this player in faction space?"** → [`world/world_territory_bubbles.md`](./world/world_territory_bubbles.md) *(bubble-radius territory model, `FactionId.IsFederation()` normalization shim)*
- **"What does Low Orbit (Scene 2) look like?"** → [`world/world_low_orbit_scene.md`](./world/world_low_orbit_scene.md) *(3D Planet Forge planet, RTS ship control, orbital structures, server-FOW Fusion spawn)*
- **"What does Surface (Scene 3) look like?"** → [`world/world_surface_scene.md`](./world/world_surface_scene.md) *(3D-placed surface bases, permit gate, activity-noise radar stealth)*
- **"How does FOW work in the three scenes?"** → [`combat/combat_fog_of_war.md`](./combat/combat_fog_of_war.md) *(three-scope model — my-client / server / their-client, activity-noise base reveal)*
- **"What am I supposed to be working on?"** → [`meta/master_to_do.md`](./meta/master_to_do.md)
- **"What's the development order?"** → [`meta/meta_roadmap.md`](./meta/meta_roadmap.md)
- **"How does faction sovereignty / planet ownership work?"** → [`world/world_faction_sovereignty.md`](./world/world_faction_sovereignty.md) *(canon — ownership model, claims, planetary defense, 50% control, residency, tax)*
- **"What's the lore for X?"** → [`lore/README.md`](./lore/README.md) *(draft / non-canon — story bible, glossary, framing)*

---

*"Everything in this folder is canon **except the `lore/` category, which is draft / non-canon**. Always reference these documents before writing new C# logic."*
