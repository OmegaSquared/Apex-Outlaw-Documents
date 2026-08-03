# Social — Category Overview

This category covers **how players interact with each other and with the game's surfaces**: the alliance/guild systems on the player side, and the menu/UI hierarchy on the harness side. Chat (Photon Chat: Global / Sector / Planet / Alliance) is referenced from here but lives architecturally in [`../architecture/`](../architecture/architecture_overview.md).

## Key concepts

- **Alliances are the primary social unit.** Guilds are smaller / informal; alliances are the entities that can claim factions, anchor citadels, control planets, and route taxes. **Membership is uncapped** — alliances scale from 3-pilot crews to 1,000+-pilot coalitions in a single record. Above 50 members, alliances can hold a faction claim; above ~500, they typically subdivide into **Squadrons** (first-class subdivisions with their own rosters, sub-vaults, and citadel access lists) so the org chart stays legible.
- **Eight-rank ladder + permission matrix.** Founder → Vice-CEO → Director → Squad Captain → Officer → Member → Initiate → Reservist. Each rank has a default permission set (recruit / kick / wardec / vault / planet-toll / etc.); per-member overrides handle the edge cases. Director-tier authority is split by **department** (Military / Industrial / Diplomatic / Treasury / Recruitment) so big alliances don't end up with "every Director can do everything." See [`social_alliance_guild.md`](./social_alliance_guild.md) §2.
- **Wardecs gate PvP in high-sec.** Outside of declared wars, FED Police break up unprovoked aggression in high-sec sectors. Alliance-vs-alliance war declarations open those sectors up between the two parties.
- **Alliances are mortal.** Formal mutual war can end in **tag retirement** — a dead alliance's name is permanently retired from the server, never reusable. Canon: [`social_war_doctrine.md`](./social_war_doctrine.md). Mutual consent + cease-fire fragility + simultaneous-bubble victory criteria together make this a coordinated commitment rather than casual griefing. The CEO at the time of disband is permanently awarded the **Warlord** title.
- **Players collect earned titles.** Gameplay actions unlock titles across 12 categories — Trader, Warrior, Ace Pilot, Marauder, Scholar, Warlord, Apex Outlaw, and ~50 more. One is selectable as the **active title** displayed next to the player's name across all UI surfaces. Canon: [`social_titles_doctrine.md`](./social_titles_doctrine.md). Titles are earned via stat thresholds — never purchased, never admin-gifted.
- **Alliance permits gate surface entry (Phase 6.9 canon).** An alliance owning a base on a planet implicitly grants all alliance members the right to drop into Scene 3 (Surface) at that planet. Non-allied attackers must defeat planetary defenses (Scene 2 orbital structures) before the permit gate opens. Server-side enforced via `PlanetSurfacePermitCheck` CloudScript. See [`../world/world_surface_scene.md`](../world/world_surface_scene.md).
- **UI uses Michsky Shift SCI-FI.** All macro-game UI is built on the Shift asset — tab-based hierarchy, drag-and-drop hardpoints, render-texture ship visualizers. Don't roll bespoke UI when a Shift component fits.
- **The HUD is split.** A persistent `GlobalHUD` carries identity (commander, credits, settings, nav). Sector view adds its own surfaces below — fleet roster, fleet launcher dock, range rings, gate-spool overlays.

## Docs in this category

| Doc | Purpose |
|---|---|
| [`social_alliance_guild.md`](./social_alliance_guild.md) | Alliance & guild mechanics — wardecs, alliance vault, automatic taxation, citadel ownership. |
| [`social_war_doctrine.md`](./social_war_doctrine.md) | Formal alliance war doctrine — private marking, mutual-war consent gate, two-phase escalation (cease-fire fragility), disband conditions (defenses + simultaneous bubble), tag retirement (permadeath), member dispersal, killed-alliances counter. |
| [`social_titles_doctrine.md`](./social_titles_doctrine.md) | Earnable player titles — Trader, Warrior, Ace Pilot, Pirate, Warlord, Apex Outlaw, and ~50 more across 12 categories. Players collect every title they earn; one is shown next to their name as the active display. Mix of one-shot achievements, cumulative thresholds, and ongoing leaderboard slots. |
| [`social_menus_ui.md`](./social_menus_ui.md) | Menus & UI layout — Shift SCI-FI tab hierarchy, HUD split, drag-and-drop conventions. |

## Where this category sits in the build order
UI infrastructure is **Phase 2** of [`meta/meta_roadmap.md`](../meta/meta_roadmap.md) — Dashboard, Shipyard, Sector HUD. Alliance/guild mechanics land in **Phase 5** alongside the rest of the MMO scaling work; the deep alliance-controls-planet system is **Phase 5.5**.
