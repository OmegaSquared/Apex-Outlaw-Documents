# MMO Architecture Plan & Development To-Do List

> **Phase 6.9 three-scene update (2026-05-29):** This plan still describes the canonical Macro/Micro split correctly. The expansion: the macro layer's *spatial* model is now three Unity scenes — **Solar** (Scene 1, sector map = hyperspace), **Low Orbit** (Scene 2, 3D Planet Forge planet), and **Surface** (Scene 3, permit-gated low altitude). Scenes 2 and 3 are still macro by default (PlayFab lazy-eval); Fusion runners spawn **per engagement cluster** inside them when the server-side wide FOW (`ServerFowMatcher`) detects fleet contact. Hyperspace combat (interception in Solar) drops into the existing blank-space combat sandbox (`shipmanagerTestFleet.unity` pattern). Canon: [`architecture_overview.md`](./architecture_overview.md), [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md), [`../world/world_surface_scene.md`](../world/world_surface_scene.md).

## Architecture Overview
This game uses a **Hybrid Architecture (Macro-Mono vs. Micro-ECS)** designed to scale infinitely while keeping fixed costs near zero, separating UI/Management from high-performance simulation.

1. **The Macro Game: Management & UI (MonoBehaviours & ScriptableObjects)**
   - **System:** Standard Unity C# + PlayFab (or AWS Serverless / Nakama)
   - **Role:** This handles ~80% of the game: The Shipyard, Alchemy Lab, Market Hub, Inventory, and Fleet Loadouts.
   - **Method:** Built using traditional Unity patterns (MonoBehaviours, ScriptableObjects, JSON serialization). Uses "Timestamping & Lazy Evaluation" for server calls—the server only wakes up and performs math when a player starts or finishes an action (like mining). No 24/7 ticking loops.

2. **The Micro Game: Event Instances (Photon Fusion + Visual ECS)**
   - **System:** Photon Fusion (authoritative) + Pure C# Structs / DOTS for visual data crunching.
   - **Role:** Short-lived, on-demand **event instances** spawned for the only two interactions that need real-time authority: **combat encounters** and **mining ops**.
   - **Combat instance cap:** **3 vs 3 active combatants + up to 10 spectators (16 players max per Fusion instance).** Spectators see the fight but cannot fire, take damage, or contribute fleet stats. A sector may host more than one combat instance if traffic warrants it.
   - **Mining-op instance cap:** TBD — sized separately from combat. Mining ops are not battles and don't share the 3v3 model.
   - **Scope boundary (important):** Fusion is **NOT** used for sector maps, planet maps, travel, shipyard, market, or any macro browsing. Those are PlayFab macro state. A Fusion runner only ignites at event entry and is torn down on event exit.
   - **Method:** Combat and physics logic (strafing, firing arcs, towing, Jammers) run in Fusion's tick simulation; Unity GameObjects are strictly "Visual Puppets" that only listen to networked state to draw exhaust or laser effects.

3. **Social & Communications (Real-Time Pub/Sub)**
   - **System:** Photon Chat (or Vivox)
   - **Role:** Handles low-latency messaging separating players into different channels based on location or social groups.

---

## 1. World & Narrative Logic
- **The Setting:** The persistent **Helion** star system. Bases orbit moons or small planets to minimize gravity-well complexities and maximize tactical variety.
- **The Factions** (canonical — see `../lore/lore_story_bible.md` §3 for full lore):
  - **FED — Federation** (homeworld Concordia, color blue): Tax-and-registry bureaucracy controlling the largest cluster of registered trade hubs in the inner system. Levies the 35% registered-hub trade tax.
  - **ICE — Iron Core Empire** (homeworld Ferrum, color iron-red): Industrial military rival, locked in cold war with FED over Discordia and the inner system.
  - **The Outlaws** (belters, smugglers, pirates): Players and NPCs operating outside both factions' jurisdiction; concentrated in the belts and outer system (Latro, Praedo, deep belts).
- **The Jump Gate Network (dynamic — no central hub):** Every planetary body hosts its own jump gate. Each gate has a **bubble radius** (1,500–8,500 units depending on the body); a gate connects to another whenever that other gate's *current world position* falls inside the source's bubble. Because every body orbits per the `CelestialOrbiter` / `CelestialClock` system (deterministic function of `now − epoch`), the connection graph is **recomputed every frame from live positions** — routes open and close as planets drift. A few pairs are effectively permanent (the Castor ↔ Pollux twin asteroids; the Custos gateway with its 8,500-unit bubble), but most are **windows of opportunity**: a route to a distant sector may exist for ~30–45 minutes, then close until the orbital geometry realigns. Implementation: `JumpGateNetwork.BubbleReaches` + `PredictDisconnectSeconds` (`Assets/Scripts/Macro/JumpGateNetwork.cs`).
- **Faction sovereignty:** Player alliances of **50+ members** can formally claim FED or ICE for two-way defense + tax. Planetary Defense platforms can be defeated; defeat triggers AI-base respawn elsewhere in Helion. See `../world/world_faction_sovereignty.md` §4 and `../meta/master_to_do.md` Phase 5.5.

---

## 1.5 Celestial Layer — Parents, Children, Time-Anchored Positions

The body and POI layer is split into **Celestial Parents** (anything that hosts orbiters — the star, planets, moons, named asteroids) and **Celestial Children** (POIs orbiting a parent — jump gates, stations, defenses, alliance-built shipyards). Both live in PlayFab title data as a single `CelestialRegistry` blob; the client reads it on boot via `CelestialRegistryClient` and the `CelestialSpawner` instantiates the scene tree from the registry. Per the canonical plan at `~/.claude/plans/in-the-solar-system-moonlit-simon.md` and `../meta/master_to_do.md` Phase 6.0.

- **Time anchor:** Every body's position is a pure function of `(UtcNow − CelestialEpoch)`. Glacies (outermost planet) is anchored to one real day per orbit (86,400 s); sibling planets scale via Kepler's third law (`T = K · r^1.5`). Moons orbit their host with authored periods. Two clients running side-by-side see the same body at the same XZ at the same wall-clock second — no per-frame angle accumulation, no `Time.deltaTime` drift.
- **Source of truth:** PlayFab title-data keys `CelestialEpoch` (the ISO-8601 epoch) and `CelestialRegistry` (the full parent + child JSON dataset). See `architecture_backend_network.md` §6 for the schema and authority model. Local `Resources/CelestialSeed.json` is a BRIDGE fallback for dev workflows where PlayFab hasn't been seeded yet — flagged for removal in `../meta/master_to_do.md` Phase 6.0.
- **Static + dynamic POIs:** Admin-baked POIs (jump gates, NPC stations, ancient ruins) and alliance-built POIs (shipyards, defenses, trading hubs) live in the same registry, distinguished by the `source` field. Alliance construction goes through CloudScript handlers `AllianceConstructPOI` / `AllianceDemolishPOI` (canonical source: `cloudscript/celestial_alliance_pois.js`).
- **Ownership model — faction = AI alliance:** A faction (FED, ICE) is just an alliance whose decisions are driven by AI instead of player officers. Every body and every POI carries a single `ownerId` string — `"FED"` / `"ICE"` for the AI alliances, an alliance UUID for player alliances, empty for unowned. There is no "faction ownership vs. alliance ownership" split in code. A player alliance can take a planet from FED (or vice versa) with no special-case logic — it's the same `controllingOwnerId` field changing value. Schema migration tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md) Phase 6.0.SCHEMA. Canon: [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) §3.
- **Sector ↔ solar map sync:** Each sector scene auto-attaches a `CelestialSectorAnchor` that exposes the host parent's current solar-system position via the same evaluator the SolarSystem map uses. Sector internal layout stays scene-authored — only the parent's apparent system position is shared.
- **Visual standard:** Every Celestial Parent renders a `CelestialParentLabel` watermark — large semi-transparent name centered on the body, with the faction tag prefixed in faction color (`[ICE] Ferrum`, `[FED] Concordia`). POI children keep the small `SolarSystemBodyLabel` style.

Key files:
- `Assets/Scripts/Schemas/Celestial/` — registry schemas
- `Assets/Scripts/Macro/Celestial/` — runtime client, clock, evaluator, spawner, parent label, sector anchor, POI construction
- `Assets/Editor/Celestial/` — seeder + MacroOrbiter migrator
- `Assets/GameData/Celestial/seed.json` — canonical seed dataset

---

## 2. The "Alchemy" Research Matrix (The Core Mechanic)
- **Unique Seeds:** Every player has a hidden, unique seed. Coords for high-value tech cannot be shared between players.
- **The Heatmap:** Every element (Iron, Helium, etc.) has a 10,000 x 10,000 matrix. 95% is "junk" (low values), while 5% contains "Peaks" up to a hidden value of 12,345.
- **Distraction Nodes:** "False peaks" (around 1,000 value) are common to trick players into thinking they’ve found the best spot.
- **Synthesis (The Alchemy):** Unlocking materials like Steel requires combining peaks from Iron and Carbon. Once Steel is unlocked, it generates its own unique heatmap for the player to explore.
- **Cumulative Quality:** The final stats of a weapon (Damage, Accuracy, Heat) are determined by the "Global Best" value the player has discovered for the required materials.

---

## 3. Technical Architecture (Serverless/Hybrid)

### 3.0 What Runs Where (cheat sheet)
| System | Runtime | Notes |
|---|---|---|
| Sector map (navigation, body selection, chain travel) | **PlayFab (lazy)** | No Fusion, no per-frame ticks. |
| Planet map (orbital view, base placement, low-orbit browsing) | **PlayFab (lazy)** | Macro layer only. |
| Shipyard / Alchemy Lab / Market / Inventory / Fleet Loadouts | **PlayFab (lazy)** | Standard Mono + ScriptableObjects. |
| Travel between sectors / bodies | **PlayFab (lazy)** | Timestamp commit + server validation. |
| **Combat encounter** | **Photon Fusion (event instance)** | Spawned on demand. **3v3 combatants + up to 10 spectators (16 max).** |
| **Mining op** | **Photon Fusion (event instance)** | Same architectural slot as combat. Cap TBD (not bound to 3v3). |
| Chat (Global / Sector / Planet / Alliance) | **Photon Chat** | Pub/sub, separate from Fusion. |

> If a feature is not "combat" or "mining op," it does not get a Fusion runner.

- **Macro-Scale: Lazy Evaluation:** The server does not run constant 24/7 loops. It uses Timestamps (UNIX) to calculate mining yields and travel progress only when a player interacts or logs in.
  - *Formula:* `Progress = (CurrentTime - DepartureTime) / (ArrivalTime - DepartureTime)`
- **Micro-Scale: Fusion Event Instances:** For combat encounters and mining ops, Fusion's authoritative tick simulation handles projectiles, rigidbodies, and weapon arcs. The client renders visual puppets driven by `[Networked]` state.
- **Event Instances & Sector Zoning:** Sectors and planets are PlayFab macro constructs — they are *not* Photon rooms. A Fusion room is spawned only when an in-sector event (combat encounter, mining op) triggers. One sector may host zero or many concurrent Fusion instances. **Combat instances are hard-capped at 3v3 active combatants + up to 10 spectators (16 players total).** Mining-op cap is sized separately (TBD).
  - *Sector transitions* (chain-mining traversal, deep-space crossings) are handled as **PlayFab travel commits** — no Fusion handoff, no sub-server load, just a server-validated state change with a new sector context.
- **The Backend Bridge:** PlayFab handles authentication, player data (JSON), and the "Discovery Seed." **Only at event entry** (combat or mining op, never sector entry) are static JSON/ScriptableObject loadouts bundled into a `FleetSnapshot` and handed to Photon Fusion. When the event ends, the canonical state flows back to PlayFab. GameObjects act as visual renderers for the networked state.

---

## 4. Item & Weapon Schema
To allow for balancing and security, the system uses a **Double-Schema** approach:
- **Blueprint JSON (Static):** Defines what a weapon is (base damage, fire rate, prefab).
- **Instance JSON (Dynamic):** Defines a specific ship's loadout (Module ID, Level, Research Value, Condition).
- **Harden Logic:** The server never trusts the client's stat claims. It re-calculates damage based on the `ModuleID` + the player’s `ResearchValue` stored in the database.

---

## 5. Economy, Player Roles, & Security
- **The Player Ecosystem (Play Your Way):** The complex Alchemy/Research system is **100% optional**. The economy is designed and balanced around specialized, interacting roles where no single player has to do everything:
  - **The Researcher (Alchemist):** Spends time scanning heatmaps, finding 12,345 peaks, and synthesizing top-tier tech. They don't have to fight; they sell their blueprints/modules for massive profits.
  - **The Miner:** Equips industrial lasers to harvest raw ore from asteroid clusters. They don't research; they bulk-sell raw materials to Researchers, Hub Cities, or Alliances.
  - **The Transporter / Smuggler:** Buys cheap ore in one sector and flies it through dangerous terrain to sell at a premium in a scarce Hub. They risk their cargo but never touch a mining laser or lab.
  - **The Pirate / Privateer:** Equips combat ships to interdict Transporters and Miners. They scavenge dropped cargo/scrap and sell it on the Black Market. 
  - **The Private Mercenary:** Hired by Transporters as heavily armed escorts to deter Pirates. 
- **The Market (Tech Commody):** 
  - Players can sell resources, raw components, or **finished, fully researched parts**.
  - A Pirate or Miner can simply amass credits and purchase a "Masterwork (12,345) Railgun" directly from the market, completely bypassing the need to interact with the Research matrix.
  - Players can sell resources or finished parts. 
  - The buyer does not see the recipe or the coordinates of the seller's peak.
  - A universal **3% Escrow Fee** applies to all trades (Market and Private) as a permanent money sink to control inflation.
- **Private Transactions (P2P Trade):**
  - **Logic:** Direct Item-for-Credit or Item-for-Item swaps (mercenary contracts, barter).
  - **Taxation:** Low (2%) registration fee compared to the Federation's high sales tax.
  - **Enforcement & Transport:** 
    - **Physical Hand-Off (0 Credits, Max Risk):** Meet in space, eject cargo. Vulnerable to piracy.
    - **Private Freight (5% Fee, Medium Risk):** Hire an NPC Freighter to transport the item. No insurance.
    - **Personal Run (0 Credits, High Risk):** Seller manually flies the item to the buyer's localized base. Susceptible to "Sting Operations" (where the buyer is actually a pirate waiting to ambush).
- **Sector Hubs & Dynamic Pricing:**
  - **Logic:** Each sector contains a "Hub City" (NPC Economic Center) with a local inventory.
  - **Scarcity:** NPC buy/sell prices fluctuate based on supply. `Price = BaseValue * (CurrentStock / TargetStock)`. Delivering "Local" resources pays poorly; delivering "Exotic" resources pays a premium.
  - **Escrow & Logistics:** Hubs serve as the start/end points for all NPC-Escorted Transports. The 3% Escrow Fee applies to all Hub transactions.
- **Inter-Alliance Trade & Standing:**
  - **Diplomatic Tiers:** Leaders set Standing (Ally, Neutral, Rival, Hostile) for other Alliances.
  - **Dynamic Premiums:** Standing determines the price hike (+0% to +300%) applied to Alliance Market listings for outsiders.
  - **Treasury Income:** All "Standing Premiums" are deposited directly into the Selling Alliance's Vault to fund base upgrades.
  - **Embargoes:** Hostile status completely blocks market access, forcing enemies to rely on the Black Market or Spies.
- **Anti-Hack Measures:**
  - **Authoritative Server:** PlayFab CloudScripts validate every move.
  - **Checksums:** High-value items are "signed" with a hash. If a player edits the JSON value, the hash breaks and the item becomes invalid.
  - **ETA Verification:** The server rejects any "Arrival" signal that happens faster than the ship's theoretical maximum speed.

---

## 6. Real-Time Combat & Chat Integration
- **PvP/PvE Rules (Photon):** Combat instances track real-time firing arcs, cooldowns, and ammo types (as defined in the `UnifiedShipSchema`).
- **Chat Systems (Vivox/Photon):**
  - **Global Chat**
  - **Sector Chat** (Dynamic based on current location)
  - **Planet Chat** (Orbit/Hub specific)
  - **Alliance Chat** (Encrypted/Private)

---

## 7. Resource & Gathering Mechanics
- **Mining Events (The Gold Rush):** Asteroids act as dynamic, high-stakes events rather than infinite nodes.
  - *Drifting Comets:* High-yield comets move through sectors, forcing players into dangerous territory to mine.
  - *Active Mining:* "Cracking" an asteroid creates a radar signature that attracts Outlaws/Pirates.
- **Resource Depletion:** Asteroids can be mined dry (turning into husks), but regions like Saturn's rings regenerate via "Orbital Resupply."
- **Space Clouds as Terrain:**
  - *Silicate Dust (Asteroid Belt):* Reduces radar range.
  - *Plasma Storms (Jupiter Orbit):* Randomly disables weapon systems or shields.
  - *Cryo-Clouds (Pluto/Neptune):* Drains ship energy.

---

## 8. Special & Utility Modules (Electronic Warfare)
- **The "Jammer" Mechanic (E-War):** Disrupts enemy UI directly based on Alchemy research values.
  - *Low-Value Jammer (Value ~1,000):* Causes the enemy's targeting arc to flicker for barely 1 second.
  - *Masterpiece Jammer (Value ~12,345):* The enemy's screen goes completely "Static," blinding them. They lose their firing arcs, shield display, and minimap for 15+ seconds.
- **Counter-Play (ECCM):** Defensive Sensors can be manufactured to combat Jammers. If the target's Sensor Value exceeds the attacker's Jammer Value, the jamming attempt fails or the duration is severely reduced.
- **Utility Builds:** A player can forego damage entirely to build a pure support/disruption ship containing:
  - **Module 1: Jammer** (Blinds the enemy)
  - **Module 2: Gravity Tether** (Prevents escape)
  - **Module 3: Energy Siphon** (Disables enemy weapons)

---

## 9. Infrastructure & Bases
- **Public Cities:** Act as safe-zone hubs in every sector. Offer Refining/Manufacturing services but with a High Federation Tax (35%).
- **Alliance Citadels:** Multi-player structures. The central focus of Alliance defense and research. Allows for "Zero-Tax" refining and Joint Projects.
- **Mobile Support Ships:** Players can build "Repair Bays," "Refinery Ships," and "Tankers." Vital for deep-space operations.
  - *Mobile Repair:* Field repairs for hulls and modules. Speed/Efficiency tied to 12345 Nanite peaks.
  - *Refinery Ships:* Allows field-refining to avoid City Taxes (35%), but is vulnerable to Interdiction.

---

## 10. Scavenging & Theft (The Golden Logic)

> **Canonical scope rule (matches [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md) §4):** Stealing a component means you get *that component*. You can fit it, repair it, or sell it intact. You **cannot manufacture additional copies** — manufacturing requires the Matrix Scanner research path keyed to your own Seed. "Golden Logic" is the **Repair Recipe** unlocked alongside the loot, not a manufacturing blueprint. Pure-combat players who never research are permanent customers of the wreck-market and the open market.

- **Stolen modules:** Intact loot pulled off a wreck during deconstruction. They go straight into the looter's inventory, fittable / sellable / repairable.
- **The "Golden Logic" (Repair Recipe):** Documents the *maintenance ratios* of an enemy module so refurbishment cycles consume the right raw materials and restore Condition cleanly. Does **not** unlock manufacturing; does **not** reveal the opponent's Seed. The lore name persists from early-access misinformation.
- **The Towing Mechanic:** Wrecks emit a "Distortion Field" (Pirate Beacon) visible on the Sector Map when tethered, creating high-stakes escort missions.
- **The Scavenge Loop:**
  - **Field Strip:** Done via Mobile Scrapper in deep space. *Time: 15m. Reward: Resources/Scrap only — no intact modules, no Repair Recipes. Risk: Medium.*
  - **Forensic Decon:** Done at a Sector City. *Time: 1h. Reward: intact stolen modules + 1% chance per module to learn its Repair Recipe. Risk: High (The Tow).*
  - **Citadel Decon:** Done at an Alliance Base. *Time: 1h. Reward: intact stolen modules + 2% chance per module to learn its Repair Recipe. Risk: High (The Tow).*
- **Joint Probability:** Large ships with multiple modules offer a significantly higher cumulative chance of dropping a Repair Recipe (e.g. 20 modules at Citadel = ~33.2% chance of at least one recipe). Note this is a recipe roll, not a manufacturing-blueprint roll.

---

## 11. Development & Tech Tree Progression
- **Mined Resources (Primary Extraction):**
  - **Tier 1 (Inner Planets/Moons):** Iron (Fe), Copper (Cu), Aluminum (Al), Silicates (Sand), Helium-3, Carbon (C).
  - **Tier 2 (Asteroid Belt):** Nickel (Ni), Tungsten (W), Titanium (Ti), Sulfur (S), Platinum (Pt), Gold (Au), Silver (Ag). *(Gold and Silver are directly mineable currency-grade ore — players can mine money.)*
  - **Tier 3 (Gas Giants/Rings):** Hydrogen (H), Nitrogen (N), Methane (CH4), Water Ice (H2O), Lithium (Li), Cobalt (Co).
  - **Tier 4 (Outer Rim):** Uranium (U), Plutonium (Pu), Iridium (Ir), Dark Matter.
- **Manufactured Resources (Alchemy Synthesis):**
  - **Steel:** Iron + Carbon (Heavy Armor)
  - **Ferro-Titanium:** Iron + Titanium (Elite Tank Hulls)
  - **Stainless Alloy:** Steel + Nickel (Radiation Shielding)
  - **Super-Conductor:** Copper + Carbon + Lithium (High-Speed Railguns)
  - **Carbon-Fiber Glass:** Silicates + Carbon (Advanced Bridge Cockpits)
  - **Thermal Paste:** Silicates + Helium-3 (Weapon Cooling)
  - **Cryo-Coolant:** Nitrogen + Water Ice (High-Fire-Rate Weapons)
  - **High-Velocity Plasma:** Helium-3 + Hydrogen (Energy Weapon Ammo)
  - **Metallic Hydrogen:** Hydrogen + Extreme Pressure Lab (Endgame Propulsion)
  - **Void-Steel:** Steel + Dark Matter (Legendary Armor)
  - **Singularity Coil:** Super-Conductor + Metallic Hydrogen (Railgun Core)
  - **Antimatter Fuel:** Hydrogen + Particle Accelerator (Infinite Range)
- **The Alchemy Web:** Research is non-linear. Synthesizing two "parents" (e.g., Iron + Carbon = Steel) creates a new "child" heatmap matrix for the player to probe and map based on their unique seed.

---

## 12. Alchemy Lab Progression
- **Lab Tiering:** Upgrading the lab (at a City or Citadel) increases your "Research Precision" to find peaks faster and unlocks more dangerous elemental combinations.
  - *Tier 1 Foundry:* Basic synthesis (Steel).
  - *Tier 3 Cryo-Physics:* Unlocks plasma and advanced cooling.
  - *Tier 5 Singularity Chamber:* Outlaw-exclusive tech, highly illegal in Federation space.

---

## 13. Weapons Catalog & Crafting (Buy vs. Manufacture)
- **Store-Bought Tier (Value ~2,500):** Federation/Mars standardized weapons. Reliable, decent stats, easy to repair, but capped in performance.
- **Manufactured Tier (Custom Forged):** Created using the player's 12345 research peaks. Can drastically outperform store bought weapons.
  - **Kinetic Path:** High hull damage, low shield damage (Autocannons, Railguns). Needs Steel, Tungsten.
  - **Energy Path:** High shield damage, requires cooling (Plasma, Ion). Needs Neon, Hydrogen.
  - **Tactical Path:** Burst damage, long range. Needs Aluminum, Sulfur, Uranium.
  - **Outlaw Weapons:** Banned tech like "Singularity Beams" or "Gravity Well Generators" requiring Dark Matter and Antimatter.

---

## 14. UI & Menu Requirements
*Because 80% of the game relies on macro-management, the interfaces must feel like a high-tech command center.*

- **1. The Command Deck (Main HUD):**
  - **Sector Map (Center):** 2D/3D map of the current solar system sector, ships, planets, and asteroids.
  - **Flight Nav-Computer (Side):** Calculates ETA, fuel cost, and executes PlayFab lazy movement math.
  - **Comms Terminal:** Photon/Vivox chat channels (Global, Sector, Alliance, System Logs).
  - **Fleet Status:** Active fleet HP, shields, and cargo capacity.
- **2. The Shipyard / Garage:**
  - **Hull Carousel & Blueprint Grid:** Visual top-down/isometric slots for modules.
  - **Arsenal List & Analytics Board:** Drag-and-drop modules; dynamically calculates Power, Mass, DPS, and Firing Arcs based on 1-12345 values.
- **3. The Alchemy Lab (Research UI):**
  - **Matrix Scanner:** 10,000x10,000 coordinate grid for probing heatmap peaks.
  - **"Best Found" Ledger:** Tracks the highest values discovered (e.g., Iron: 11,200).
  - **Synthesis Crucible:** Combines "Parent" resources to unlock "Child" recipes.
- **4. The Sector City Hub (Market UI):**
  - **Trade Terminal & Dynamic Price Ticker:** Visually graphs the `CurrentStock / TargetStock` scarcity modifier.
  - **Private Contracts (P2P):** Lists direct-to-player trades (displays 3% Escrow fee).
  - **Refinery Queue:** Processes raw ore (displays 35% Federation Tax).
- **5. Alliance Citadel Management:**
  - **Diplomatic Ledger:** Sets standings (Ally, Rival) and Market Price Premiums (+0% to +300%).
  - **Golden Logic Library:** The shared **Repair Recipe** book — *maintenance* ratios for stolen / looted gear. Pooled across alliance members, gated by rank per [`../social/social_alliance_guild.md`](../social/social_alliance_guild.md). Does not include manufacturing recipes (those stay with the original Researcher's Seed).
  - **Joint Upgrade Tree:** Shared resource dumping for base defense and lab upgrades.
- **6. The Scavenger / Deconstruction UI:**
  - **Towing Status:** Blinking warning: "Tether Active - Signature Broadcasted."
  - **Autopsy UI:** Toggles between *Field Strip (15m, safe — scrap only)* and *Deep Decon (1h, intact modules + Repair Recipe roll)*.
  - **Scavenge Report:** The final loot pop-up showing if the 1%/2% joint probability logic was successfully hit.
- **7. The Tactical Arena (Photon Combat UI):**
  - **Real-Time Overlays:** Firing cones and min/max ranges painted in 3D space.
  - **Electronic Warfare (E-War):** "Jammed" status completely hides the minimap, glitches the UI with static, and obfuscates enemy health.

---

## Suggested Next Steps for Development
- [ ] **Phase 1: The Foundation (Source of Truth)**
  - [ ] 1.1 Unified Database/Schema: Map the `ShipSchema`, `ModuleSchema`, and `FleetSchema`. These C# structures must be perfectly defined first, because they act as the "Bridge" between the Mono UI, PlayFab Server, and ECS Combat instances.
  - [ ] 1.2 The Matrix: C# Noise/Seed logic for 12,345 Heatmaps.
  - [ ] 1.3 The Alchemy Engine: Math for combining/ratio discovery.
  - [ ] 1.4 ECS Relationship Scavenge Logic: Implement the `TetheredTo` relationship for towing, and the `KnowsRepairRecipe` relationship for Alliance Golden Logic. Note: this is *repair* knowledge (maintenance ratios), not manufacturing — manufacturing stays with the originating Researcher's Seed (see [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md) §4).
- [ ] **Phase 2: The Lab:** Alchemy/Synthesis UI & Recipe discovery logic.
- [ ] **Phase 3: The Hubs:** Sector City logic, local scarcity pricing, and docking.
- [ ] **Phase 4: Trade & Tax:** 3% Escrow, 30% Fed Tax, and Alliance Standing Premiums.
- [ ] **Phase 5: Logistics:** NPC Escorts, Player Interdiction, and the Bluffing UI.
