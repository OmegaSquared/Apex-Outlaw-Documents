# Alpha Roadmap — Apex Outlaw

> **Goal:** Get the game to a **testable alpha** — a buildable client that ~10 invited testers can run, log into with persistent accounts, play through one mining loop and one combat loop, see each other on the map, and submit bugs. Not feature-complete. Not balanced. Stable enough to find real bugs.

> **Relationship to other roadmaps.** [`meta_roadmap.md`](meta_roadmap.md) is the full development plan and [`master_to_do.md`](master_to_do.md) is the granular checklist of every system the game will eventually have. This document is the **alpha-specific subset** — it picks the minimum playable slice from those lists and orders it in a build path. Items marked **[DEFER]** are deliberately scoped out of alpha, not forgotten — they live in `master_to_do.md` for post-alpha phases.

---

## Definition of "testable alpha"

A tester invited via Discord can install a build, sign in with credentials we issue them, and do the following without crashing — submitting bug reports back to us as they go:

1. **Log in** with a real account (no more mock auth). Credentials persist across sessions.
2. **See the world.** Sector map renders the live PlayFab celestial registry; gates, planets, and belts are visible and labeled.
3. **Travel.** Click a jump gate → fleet moves → arrive in a new sector with state preserved server-side.
4. **Earn something.** Click a belt rock → extract ore → ore lands in cargo → sell at a faction hub → credits go up.
5. **Spend something.** Buy a module at a hub → it lands in inventory → fit it to a ship in the Shipyard.
6. **Fight something.** Get ambushed by an NPC pirate (or duel another tester) → damage persists across re-login.
7. **Repair.** Pay credits at a hub → durability restored → re-deploy.
8. **Chat.** Type in a global channel; another tester sees it.
9. **Quit and resume.** Re-login the next day — fleet is at the last sector, credits and cargo intact.

That's the bar. **Everything else is post-alpha.**

---

## What we leverage (built, mostly working)

| System | % done | Alpha role |
|---|---|---|
| Inventory + recipes (slice 1 + 2) | ~70% | Keep — graded stacks, mass caps, container model. |
| Sector map (Vesperion) + FOW client | ~75% | Keep — celestial registry, gate visuals, scanner panel. |
| Shipyard drag/drop UI | ~60% | Finish PlayFab write-back (α2.4). |
| Combat (Fusion: flight + weapons + damage) | ~65% | Finish state writeback + server authority. |
| Resource Scanner Toggle | shipped | Keep — flashing belt-rock markers already work. |
| CelestialRegistry + `CelestialClock` | shipped | Keep — two clients sync to the second. |
| Planet view + low-orbit camera | ~50% | Render-only for alpha; base persistence deferred. |
| Schemas + CloudScript bundle | shipped | Keep — inventory / recipes / scanning handlers live. |

## What we explicitly defer (DO NOT BUILD IN ALPHA)

Tracked here so we don't drift into them. Every entry below stays in [`master_to_do.md`](master_to_do.md) for its appropriate post-alpha phase.

- **Alliance system** ([`../social/social_alliance_guild.md`](../social/social_alliance_guild.md)) — 8-rank ladder, departments, squadrons, treasury, wars, alliance vaults. Massive scope. Alpha runs solo-player + NPC + small-group chat only.
- **DOM order book exchange** ([`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md)) — Alpha uses a flat hub price table (`floorPrice`/`ceilingPrice` per item per hub). Real Bid/Ask/Limit/Stop is post-alpha.
- **Faction loans, permits, planet tax** ([`../economy/economy_obligations.md`](../economy/economy_obligations.md)) — Out. Only the universal 3% Escrow is enforced; FED 35% trade tax stubs at 0 for alpha.
- **Base building persistence** — Low-orbit base placement stays visual-only. Storage = ship cargo + hub vault, period.
- **Hacking module suite** — Out. The whole chain depends on alliance data that doesn't exist yet.
- **Maker's Mark UI / MakerProfile aggregation** — Stamps land via the existing slice-3a forge, no profile pages.
- **NPC mining + NPC auto-arbitrage** ([`../economy/economy_npc_arbitrage.md`](../economy/economy_npc_arbitrage.md)) — Out. Markets are populated by admin-seeded `HubStockLevel` only.
- **Manufacturing tech tree beyond Tier-2** — Tier-1 raws + the 14 existing Tier-2 recipes are enough. Tier-3+ deferred.
- **Mining-Op Fusion instance** (Phase 4.2d) — Mining stays macro. `MacroMiningBridge.cs` is the alpha surface; Fusion promotion is post-alpha.
- **Multiple star systems** — Alpha ships **one system scene (Vesperion)** plus existing planet scenes (Concordia, Ferrum if built, Avernus). No new star systems.
- **Repair Recipes / Golden Towing** — Out. Repair is a flat credit cost at a hub.
- **Capital ships, mass driver, towing, ramming, close-combat naval** — Out.
- **Black markets, contraband, laundering, stolen-goods tracking** — Out.

If you're tempted to build any of the above for alpha, stop. Move it to a post-alpha entry in [`master_to_do.md`](master_to_do.md) and keep going.

---

## Alpha Phases — build order

Phases are sequential. Don't start phase N+1 until phase N's exit criteria are met.

### α0 — Production Foundation (~1 week)
**Goal:** The build can be handed to a tester who isn't us, on a machine that isn't ours.

- [ ] **α0.1 Real PlayFab auth.** Promote `PlayFabManager` past the dev stub. Email/password registration via `RegisterPlayFabUser`; login via `LoginWithEmailAddress`. Session ticket cached locally. Auto-relogin on launch. Hide any "skip login" path behind a build flag.
- [ ] **α0.2 CloudScript deploy automation.** Editor menu `Apex Outlaw → CloudScript → Push Revision` using `PlayFabAdminAPI` to upload the deploy bundle. Today it's manual paste-into-GameManager (per [`master_to_do.md`](master_to_do.md) §3.A3) — a recurring footgun.
- [ ] **α0.3 Title-data export pipeline.** Editor menu pushes `RecipeCatalog`, `ResourceCatalog`, `AnomalyCatalog`, `CelestialRegistry`, `CelestialEpoch` from local assets to PlayFab title data. Kills three hardcoded mirror bridges in `cloudscript/recipes.js`, `inventory.js`, `scanning.js` simultaneously.
- [ ] **α0.4 Build pipeline.** Document the editor-driven Windows player build. No CLI yet. Tester install: ship a `.zip`, expect they unzip + run.
- [ ] **α0.5 Crash + log capture.** Unity Cloud Diagnostics (or equivalent) — every crash uploads with stack + recent log. Required on day one of alpha.
- [ ] **α0.6 Bug-submit UI.** F8 (or pause-menu button) opens a small form: title, description, auto-attach last 200 log lines + screenshot, POST to a Google Form or webhook. Bar is "we can iterate on bugs without telephone in Discord."

**Exit criteria:** Aaron + one external tester each register a new account from a built executable, log in, see the dashboard, submit a fake bug, see it land in our intake.

---

### α1 — Persistent Macro Loop (~1 week)
**Goal:** Travel is server-authoritative. Where you log out is where you log back in. State across two clients agrees.

- [ ] **α1.1 Gate-jump CloudScript handler.** `GateJump(sourceGateId, targetGateId)` — server validates bubble reachability via the canonical `JumpGateNetwork` rules, updates `PlayerProfile.currentSectorId` + `currentPosition`, returns target scene id. Client loads scene on success.
- [ ] **α1.2 Resume-at-last-sector.** On login, `PlayerProfile.currentSectorId` determines the scene to load, not a default.
- [ ] **α1.3 Fleet state authoritative.** `PlayerFleet` lives on PlayFab — position, ship list, cargo, durability all server-side. Client reads are cached but never authoritative.
- [ ] **α1.4 Logout auto-travel** — on logout, fleet auto-travels to nearest safe spot (faction hub or jump gate). In transit = vulnerable (huntable); on arrival = safe + idle. Persists in PlayFab. Canon for Phase 6.7.E, but we need the safe-arrival behavior in alpha so logouts don't strand testers in lawless space.
- [ ] **α1.5 Sector view fleet roster** ([`meta_roadmap.md`](meta_roadmap.md) Phase 2.5.1) — bottom transparent bar listing launched fleets. Alpha-critical UX: "see your fleet on the map."
- [ ] **α1.6 Top-bar live credits + commander name.** Already partly built; finish the PlayFab subscription so credits update on every server response.

**Exit criteria:** Two testers each log in, jump through three gates, log out, log back in, find themselves at the same gate they ended at. Credit balances persist accurately.

---

### α2 — Economic Loop MVP (~1.5 weeks)
**Goal:** Player mines ore, hauls to a hub, sells it, buys a module, fits it. Real currency moves through real handlers.

- [ ] **α2.1 Mining loop closure.** Click belt rock on sector view → `MacroMiningBridge` opens timer panel → 60-second extract (alpha-shortened; canon is 5 min) → ore lands in cargo as a `GradedStack`. Use existing `MacroMiningSession` bridge code as the surface; wire it cleanly to PlayFab writes. **Mining Fusion instance stays deferred.**
- [ ] **α2.2 Hub buy/sell.** Each faction hub has a static stock list (admin-seeded `HubStockLevel`). Player at a hub opens a Trade panel; sells stacks at `floorPrice`, buys at `ceilingPrice`. **No DOM, no orders, no listings.** Direct atomic swap; 3% Escrow tax burns to currency sink.
- [ ] **α2.3 Cargo enforcement.** Ship `cargoCapacityKg` finally honored — overweight pickups reject. Container math from slice 1 is live; enforce in UI feedback.
- [ ] **α2.4 Module fitting writeback** ([`meta_roadmap.md`](meta_roadmap.md) Phase 2.4) — drag-drop in Shipyard calls `EquipModule` CloudScript handler that mutates `ShipInstance.hardpoints` server-side.
- [ ] **α2.5 Resource Scanner Toggle integration.** Already shipped — smoke-test after α0 title-data migration. Likely 30 min, not a build task.
- [ ] **α2.6 Starter credits + starter fleet.** New accounts spawn with 1 Frigate, 2 Light weapons, 500 PACT credits, 0 cargo. Authored as a PlayFab CloudScript `OnPlayerCreated` handler — closes the existing C# hardcoded starter-inventory bridge ([`master_to_do.md`](master_to_do.md) Phase 1.5).

**Exit criteria:** Tester mines 100kg of Iron, hauls to Concordia, sells for X credits, buys a Light Pulse Laser, fits it to their frigate. All values match across two open clients.

---

### α3 — Combat Loop MVP (~2 weeks)
**Goal:** Two players (or 1 player + 1 NPC) engage in a Fusion combat instance. State writes back. Damage persists across re-login.

- [ ] **α3.1 FleetSnapshot bridge.** Per [`../architecture/architecture_data_schemas.md`](../architecture/architecture_data_schemas.md) §6 — when combat triggers, PlayFab assembles `FleetSnapshot` with pre-resolved stats and hands it to Fusion. Fusion does not call PlayFab during the fight.
- [ ] **α3.2 Combat trigger handler.** Two routes: (a) player attack on a visible target on the sector map, (b) NPC pirate ambush in hostile-rated space. Both fire `StartCombatInstance(playerIds[], encounterId)` CloudScript handler, returns a Fusion room ticket.
- [ ] **α3.3 3v3 + 10-spectator cap enforcement** ([`meta_roadmap.md`](meta_roadmap.md) Phase 4.2a/b). Hard at 16 seats. Late combatants spectate; spectator slots overflow with "fight is full" macro message.
- [ ] **α3.4 End-of-combat writeback.** When the Fusion instance ends: server resolves loser/winner, applies durability damage + module losses to canonical `ShipInstance` records via `ResolveCombatResult` CloudScript handler. Fusion tears down. Client returns to sector view with a damaged ship.
- [ ] **α3.5 Server-authority hardening — subset of [`meta_roadmap.md`](meta_roadmap.md) Phase 4.5.** Promote `TacticalHitbox` to `NetworkBehaviour` (4.5.1). Damage RPC server-resolved (4.5.2). Audit `[Networked]` writes for authority gates (4.5.3). **Required for alpha** because external testers will probe for cheats.
- [ ] **α3.6 FOW server filtering — subset of [`meta_roadmap.md`](meta_roadmap.md) Phase 4.6.** Author the two minimum `SensorSchema` assets (4.6.1: omni turret + directional internal). Implement `TacticalFleetVision` aggregator (4.6.2). Server-side transform filtering (4.6.3). Without 4.6.3, any modded client wallhacks the moment alpha opens.
- [ ] **α3.7 Repair at hub.** Flat-credit repair restores `currentDurability`. No tiered facilities, no queue, no Repair Recipes. Dock + pay = full bars. Cost: `(1 - dur/max) * baseRepairCost * gradeMultiplier`.

**Exit criteria:** Two testers spawn into a 1v1, fight, one wins, both log out, log back in. The loser's ship is damaged. The winner pays to repair theirs and re-deploys.

---

### α4 — NPC Content (~1.5 weeks)
**Goal:** The world has hostile and friendly NPC ships. Solo testers have something to fight. Safe sectors feel safe.

- [ ] **α4.1 NPC pirate spawner.** Lawless / Outlaws-controlled / contested sectors get random pirate spawns at low density. NPC ships use existing `ShipSchema` + minimal `ShipAI`. Doctrine: engage if player is in range + alone + lower-rated; flee if outnumbered.
- [ ] **α4.2 NPC patrol spawner.** FED Police in FED core; ICE Garrison in ICE core. Idle most of the time; respond to hostile acts (player firing on a hub or another player in patrolled space). Minimum viable: 2-ship patrol response within 30s of any hostile act in faction core.
- [ ] **α4.3 Pirate loot drops.** Defeated pirate → wreck with ungraded scrap + maybe one low-grade module. Simple loot list, no Golden Towing. Player loots via "Loot Wreck" sector-view click.
- [ ] **α4.4 NPC AI doctrine — minimum viable.** Engage range, kite distance, weapon trigger. Just enough that combat isn't trivially gamed. Defer alliance-grade doctrine, escort scaling, threat learning to post-alpha.
- [ ] **α4.5 Faction standing skeleton.** Just enough to gate patrol response: `PlayerProfile.reputations[factionId] : int` field. Not exposed to UI yet, not used to gate access.

**Exit criteria:** A solo tester logged into Vesperion gets ambushed by a pirate within ~15 minutes of play. A tester who attacks a hub in Concordia gets jumped by FED Police within 30 seconds.

---

### α5 — Social MVP (~1 week)
**Goal:** Testers can find each other.

- [ ] **α5.1 Photon Chat integration.** Three channels: Global, Sector (auto-joined based on current sector), Private (DM by player name).
- [ ] **α5.2 Chat UI.** Bottom-left collapsible panel. Tabbed channels. Mute/block. No alliance/squadron channels yet.
- [ ] **α5.3 Player presence on sector map.** Other testers in the same sector show as dots/icons (subject to FOW from α3.6). Click → "Hail" opens DM.
- [ ] **α5.4 Friend list.** Add/remove by player name; persisted in `PlayerProfile.friends`. Online/offline status visible.
- [ ] **α5.5 Naïve matchmaking.** "Find Sparring Partner" button on the dashboard pulls online tester names; pick one → both opt in → server spawns a 1v1 combat instance with both fleets. **BRIDGE: remove when matchmaking proper ships.** Throwaway tester convenience.

**Exit criteria:** Two testers chat globally, locate each other in the same sector, hail, accept a sparring match, fight.

---

### α6 — Stabilization & Tester Onboarding (~1 week)
**Goal:** Polish rough edges so first-impression bugs aren't system-design bugs.

- [ ] **α6.1 First-run tutorial overlay.** 5-7 hint pop-ups on first login: "this is your sector map", "click a gate to travel", "click a belt rock to mine", "open the trade panel at a hub", "right-click a target to engage." No tutorial mission — just signage.
- [ ] **α6.2 Tester onboarding doc.** `ALPHA_TESTER_GUIDE.md` shipped in-build: known issues, how to submit a bug, the 10-minute "what to try first" loop, expected downtime windows.
- [ ] **α6.3 Performance budget pass.** 60fps minimum on a mid-range 2024 laptop in Vesperion with 5+ launched fleets + 2 NPC patrols + asteroid belt visible. Profile and fix obvious offenders.
- [ ] **α6.4 Telemetry dashboard.** PlayFab events for: login, gate jump, combat start/end, mining session, hub trade, crash. Lets us see what testers actually do.
- [ ] **α6.5 Audio pass — minimum viable.** Engine hum, weapon fire, hit, explosion, UI clicks, ambient sector music. Alpha without any audio feels broken.

**Exit criteria:** A tester who's never seen the game launches the build and completes the alpha core loop end-to-end in under 30 minutes without asking a question on Discord.

---

### α7 — Closed Alpha Test Run (rolling)
**Goal:** Iterate with real testers.

- [ ] **α7.1 Recruit ~10 testers.** Discord channel, NDA-lite invite.
- [ ] **α7.2 Cadence.** Weekly client build drops. CloudScript hot-patches as needed (no client patch required).
- [ ] **α7.3 Weekly retro.** What broke, what was fun, what was confusing. Triage to `master_to_do.md` post-alpha phases.
- [ ] **α7.4 Server-side reset capability.** Editor menu `Apex Outlaw → PlayFab → Reset Tester Account` for unsticking testers without destroying telemetry.
- [ ] **α7.5 Exit criteria for alpha → beta.** (a) alpha loop stable across 100+ player-hours, (b) no P0 crashes in last two weeks, (c) we've decided which beta scope to enter (post-alpha doc outlines beta based on alpha learnings).

**Exit criteria for the alpha phase as a whole:** Aaron is confident enough in the build to expand from 10 testers to 50+ without us being the bottleneck on every bug report.

---

## Total alpha effort estimate

| Phase | Effort | Cumulative |
|---|---|---|
| α0 — Production foundation | 1.0 wk | 1.0 |
| α1 — Persistent macro loop | 1.0 wk | 2.0 |
| α2 — Economic loop MVP | 1.5 wk | 3.5 |
| α3 — Combat loop MVP | 2.0 wk | 5.5 |
| α4 — NPC content | 1.5 wk | 7.0 |
| α5 — Social MVP | 1.0 wk | 8.0 |
| α6 — Stabilization | 1.0 wk | 9.0 |
| α7 — Closed alpha run | rolling | — |

**~9 weeks of focused solo work** to alpha-ready, plus rolling iteration during α7. With one part-time collaborator on art/audio, alpha tester guides, and bug triage, the effective timeline halves.

---

## Risks (sequence-critical)

1. **PlayFab auth (α0.1) gates everything.** If real auth slips, every later phase slips. **Mitigation:** ship α0.1 first; refuse to skip ahead.
2. **Combat writeback (α3.4) is the highest-risk delta** from the current state. State has to survive Fusion teardown, mid-fight network drops, and concurrent edits. **Mitigation:** lean on the existing `FleetSnapshot` design in [`../architecture/architecture_data_schemas.md`](../architecture/architecture_data_schemas.md) §6; don't invent a new pattern.
3. **Server-authority hardening (α3.5) cannot ship after testers start playing.** A modded-client damage exploit in week one of alpha would force a tester wipe. **Mitigation:** ship 4.5.1 + 4.5.2 + 4.5.3 before any external tester gets a build.
4. **Scope creep is the biggest risk.** "Just add alliances", "just add the DOM", "just add bigger ships" — each will torpedo the timeline. **Mitigation:** rigid adherence to the **DEFER** list above. Anything not on this roadmap is a post-alpha entry, full stop. Run any temptation through the CLAUDE.md "no throwaway code" + "live data or tracked TODO" filters before accepting it.
5. **NPC AI tuning (α4.4).** Too aggressive → testers can't play; too passive → world feels empty. **Mitigation:** ship with admin-tunable density/aggressiveness; tune live during α7.
6. **Title-data export pipeline (α0.3).** Three bridges (recipes, inventory mass-cap, scanning anomaly catalog) all gate on this single piece of infra. Worth doing carefully so we don't have to revisit. **Mitigation:** treat α0.3 as one task that closes three bridges — design the export contract first, then implement.

---

## Non-goals at alpha (post-alpha tracked separately)

- Cross-system travel (multiple star systems).
- Capital ships and capital battles.
- Heavy cannons, mass driver, capital weapons.
- Anything black-market, contraband, or piracy-doctrine.
- Crate-Push Rails, towing, naval close-combat, ramming.
- Hauler Profile reputation / Maker's Mark UI / MakerProfile aggregation.
- Faction wars, sovereignty flips, planet capture.
- Mobile / Steam Deck builds.

These belong in [`master_to_do.md`](master_to_do.md) under their existing post-alpha phases, not in this document.

---

## Bridge code introduced in alpha (must be removed before beta)

Per CLAUDE.md "Building durably — no throwaway code", every scaffold added during alpha is tracked here and code-flagged with `// BRIDGE:` for grep-ability.

- [ ] **`HubStockLevel` admin-seeded stock list** (α2.2) — flat price table; remove when DOM order book ships (`master_to_do.md` Phase 5+ Economy).
- [ ] **60-second mining extract** (α2.1) — alpha-shortened tick; restore to 5-min canon when mining-op Fusion instance lands (Phase 4.2d).
- [ ] **Flat-credit repair** (α3.7) — no facility tiers, no Repair Recipes; replace when full repair system ships (`master_to_do.md` Phase 5+ Economy → Repair system).
- [ ] **Naïve matchmaking "Find Sparring Partner"** (α5.5) — throwaway dashboard button; replace when real matchmaking ships post-alpha.
- [ ] **Tutorial hint pop-ups** (α6.1) — placeholder onboarding; replace with a proper first-run tutorial mission post-alpha.
- [ ] **Faction standing field without UI** (α4.5) — `PlayerProfile.reputations` is written but not surfaced; close when Phase 5+ standing UI ships.

---

## Living doc

When an alpha phase ships, mark its exit-criteria check-box, log the date, note any scope changes. When all phases ship, archive this and write `Beta_roadmap.md`.

*Created 2026-05-21.*
