# Unified Fleet Classification Index

A doctrinal taxonomy of every vessel and fixed installation in Apex Outlaw, ordered by operational role and combat tonnage. This document is the **strategic reference** — a shared vocabulary for design, lore, AI behavior, and UI labels. It is **not** the gameplay-mechanic source of truth.

For hardpoint counts, mass, HP, and turn-rate constraints see [ships_hulls_classes.md](./ships_hulls_classes.md). For C# struct shape see [ships_schema.md](./ships_schema.md). For weapon fitments see [ships_weapons_armaments.md](./ships_weapons_armaments.md). When a class appears in both this doc and the hulls doc, the hulls doc wins on numbers.

> Status: design canon. Several entries (Mothership, Super-Dreadnought, StatCom, Siege Monitor) are forward-looking — they describe the intended fleet endgame and are not yet schema-backed.

---

## 1. How To Read This Index

Every entry follows the same shape:

- **Role** — one-line tactical purpose.
- **Operational Context** — how the class is actually fielded across the Helion frontier, with faction flavor (FED polish, ICE/Iron-Core brutalism, Outlaw scrap).
- **Crew & FTL** — typical manning and whether the hull can transit Jump Gates under its own power.
- **Counters** — what reliably kills it.

Faction shorthand throughout: **FED** = Federation (Sol authority / Concordia), **ICE** = Iron Core (Ferrum), **OUT** = Outlaws / belt syndicates. *(Legacy "MAR / Martian Republic" and "BLT / The Belt" labels still appear in older entries below — they map to ICE and Outlaws respectively, pending a full sweep.)*

---

## 2. Combat Vessel Hierarchy

*Smallest to largest. The line between "strike craft" and "warship" is FTL capability — anything below Corvette is parasitic on a carrier or station.*

### A. Strike Craft & Unmanned Platforms

#### Probe / Satellite
- *Role:* Unmanned, sensor-focused recon platform.
- *Operational Context:* Cheap, expendable eyes. FED probes are sleek, network-aware, and feed directly into CONCORD response triggers. MAR probes are armored brick-and-antenna assemblies meant to survive being shot at. BLT probes are stolen FED hulls with the IFF clipped off, dropped at jump-gate ingress points to spot incoming convoys. Possesses **no offensive armament** — its job is to live long enough to phone home. Strong synergy with the [StatCom](#5-the-statcom--sector-map-fow-extender) since a probe-pinged contact propagates across the alliance map.
- *Crew & FTL:* Unmanned. No FTL — deployed from a carrier or anchored to a station.
- *Counters:* Any weapon. The threat is what it has *already reported*, not the probe itself.

#### Drone
- *Role:* Autonomous, expendable combat unit.
- *Operational Context:* Deployed in swarms to saturate point-defense and spot for heavier hulls. FED drones run tight networked formations under a parent carrier's link. MAR drones are dumb but armored — built to take a hit and keep ramming. BLT drones are improvised: half are repurposed mining utility frames bolted to a torpedo. The *Heavy Fighter swarm* described in `ships_hulls_classes.md` is the player-flown analogue; drones are its NPC cousin.
- *Crew & FTL:* Unmanned. No FTL.
- *Counters:* Flak batteries, AOE weapons, and any E-War platform that severs the parent network link.

#### Interceptor
- *Role:* High-speed strike craft tasked with running down fighters and missile salvos.
- *Operational Context:* See [Hulls TDD §A](./ships_hulls_classes.md#a-striker-craft-fighters--interceptors). Doctrinally, the Interceptor is the *chase asset* — its job is to catch a fleeing Transporter or thin a missile wave before it hits the cruiser line. BLT Interceptors are the iconic Outlaw silhouette: stripped frame, oversized engine, paper armor.
- *Crew & FTL:* 1 pilot. No FTL — Jump-Gate transit only when latched to a parent.
- *Counters:* Flak, tracking-bonused Frigates, and its own paper armor — one good hit ends the run.

#### Fighter
- *Role:* Primary tactical strike unit; the maneuverable mid-line of any carrier wing.
- *Operational Context:* Versatile, expected to dogfight, escort bombers, and run combat air patrol around capital hulls. FED fighter doctrine emphasizes wing cohesion and energy efficiency; MAR fighters are heavier and trade agility for survivability; BLT fighters are whatever was on the deck this morning. The Heavy Fighter from [Hulls TDD §A](./ships_hulls_classes.md#a-striker-craft-fighters--interceptors) is the canonical player hull.
- *Crew & FTL:* 1 pilot. No FTL.
- *Counters:* Interceptors, point-defense lasers, dedicated anti-fighter Frigates.

#### Bomber
- *Role:* Heavy ordnance delivery against capital ships.
- *Operational Context:* Sacrifices speed and agility for torpedo / heavy-missile capacity. A bomber wing is the standard answer to a Battleship that has out-ranged its escorts. FED bombers fly tight, escorted runs; MAR bombers are slow, armored, and willing to absorb flak; BLT bombers are converted gunships with crude torpedo racks welded under the keel. Vulnerable until launch — this is why escorting Fighters exist.
- *Crew & FTL:* 1–3 crew. No FTL.
- *Counters:* Interceptors during ingress, point-defense at terminal phase, E-War to break torpedo locks.

#### Gunship
- *Role:* Heavy point-defense and short-range anti-surface.
- *Operational Context:* Sub-FTL hull bristling with autocannons and flak. Acts as a perimeter guard for stations, jump gates, and capital line ships. FED Police Fleets field gunship variants in High-Sec — the "second wave" after the invincible CONCORD response. MAR uses them as static defense in low-orbit installations. BLT modifies them into *Q-Ship* hulls (see §3).
- *Crew & FTL:* Small crew (4–8). No FTL — must be hauled to its station of duty.
- *Counters:* Long-range Destroyers, bombers, and any hull that can out-range its flak envelope.

### B. FTL Warships — Light Line

#### Corvette
- *Role:* Patrol and screening — the smallest hull rated for independent jump-gate transit.
- *Operational Context:* The minimum credible warship. Fast, cheap, and the standard FED High-Sec patroller. MAR uses Corvettes as raiding pickets; BLT uses them for piracy where a Frigate would be conspicuous overkill. Often a player's first taste of capital combat doctrine because it can actually leave its home sector.
- *Crew & FTL:* 8–16 crew. FTL-capable.
- *Counters:* Frigates and Destroyers — anything that out-ranges the Corvette's small hardpoints.

#### Frigate
- *Role:* Versatile escort and long-range scout.
- *Operational Context:* See [Hulls TDD §B](./ships_hulls_classes.md#b-escorts-frigates--destroyers). Doctrinally the most adaptable warship in the index — fitted as anti-fighter screen, electronic-warfare platform, scout-with-sensor-mount (see [../combat/combat_fog_of_war.md](../combat/combat_fog_of_war.md) for the directional/turret sensor split), or convoy escort.
- *Crew & FTL:* 20–40 crew. FTL-capable.
- *Counters:* Destroyers, swarms of fighters, and dedicated E-War that nullifies its utility role.

#### Destroyer
- *Role:* Fast escort and anti-capital screen.
- *Operational Context:* See [Hulls TDD §B](./ships_hulls_classes.md#b-escorts-frigates--destroyers). Used to break up enemy fighter formations and to deliver high-tracking medium weapons (Plasma Casters, Railguns) onto cruiser-class targets. Classic FED line composition: a Heavy Cruiser flanked by two Destroyers and a Frigate.
- *Crew & FTL:* 60–120 crew. FTL-capable.
- *Counters:* Heavy Cruisers in a stand-up fight; bombers if its escort screen is dropped.

#### Stealth Frigate *(new)*
- *Role:* Cloak-capable scout and assassin.
- *Operational Context:* BLT speciality — a Frigate hull stripped of redundant systems and re-fit with a low-emission cloaking suite. Used to ferry probes deep into hostile space and to drop in for opportunistic torpedo strikes on AFK Freighters. FED variants exist as "Recon Cruisers" (a misnomer — they're frigate-tonnage), tightly licensed and rare. MAR explicitly does not field this class — Martian doctrine considers cloaking dishonorable.
- *Crew & FTL:* 12–20 crew. FTL-capable.
- *Counters:* Sensor-bonused Frigates, area-effect weapons that don't need a target lock, and any decloaking E-War module.

### C. Mid-Line — Cruisers

#### Battlecruiser
- *Role:* Strike platform — battleship-grade weaponry on a cruiser-sized hull.
- *Operational Context:* The "glass cannon" of the doctrine. Fits Large weapons normally reserved for Heavy Cruisers, but with cruiser-tier armor and reactor headroom. FED Battlecruisers are precision strike pieces; MAR doesn't really build them (Martian engineers consider the design philosophy unsound); BLT loves them — strap a Capital weapon to a stolen cruiser hull and run before anything bigger arrives.
- *Crew & FTL:* 200–400 crew. FTL-capable.
- *Counters:* Battleships in a sustained fight; any hull fast enough to dictate range.

#### Light Cruiser
- *Role:* Multi-purpose capital — independent long-range operations.
- *Operational Context:* The flagship of small alliances. Capable of solo deployments deep into Null-Sec, fleet-up duty as an anchor for a destroyer wing, and short-duration logistics work. FED Light Cruisers run the bureaucratic patrols across multiple systems; MAR Light Cruisers are heavily armored "tonnage taxis" for elite ground troops; BLT Light Cruisers are converted civilian liners with welded gun decks.
- *Crew & FTL:* 300–500 crew. FTL-capable.
- *Counters:* Heavy Cruisers, Battlecruisers, and any force that can pin it before it warps off.

#### Heavy Cruiser
- *Role:* Fleet backbone — the standard line ship.
- *Operational Context:* See [Hulls TDD §C](./ships_hulls_classes.md#c-capital-class-cruisers--dreadnoughts). The hull most alliances build their fleet doctrine around. Requires Frigate escort to avoid being swarmed; requires logistics support on long deployments.
- *Crew & FTL:* 600–900 crew. FTL-capable.
- *Counters:* Bombers, swarms of Heavy Fighters, and Battleships at long range.

#### Missile Cruiser *(new)*
- *Role:* Long-range torpedo and missile platform.
- *Operational Context:* A Light Cruiser hull re-purposed around a torpedo bay. Sits at extreme range and lobs ordnance over the line. FED variant carries guided "Lance" torpedoes with mid-flight retargeting; MAR variant uses dumb-fire heavy missiles that can't be jammed once launched; BLT variant is a Mobile Refinery with the lab ripped out and a torpedo rack bolted in. Strong against capital hulls; useless if its lock is broken by E-War.
- *Crew & FTL:* 250–400 crew. FTL-capable.
- *Counters:* Frigates rushing the line, Jammers, and point-defense walls.

### D. Capital Class

#### Carrier
- *Role:* Strike-craft command platform.
- *Operational Context:* Mobile hangar housing wings of fighters, bombers, and drones. Cannot meaningfully duel another capital one-on-one — its threat is its strike wing. FED Carriers are the doctrinal core of fleet projection; MAR Carriers are rare and heavily armored; BLT "Carriers" are usually converted Heavy Freighters with hangar racks welded inside the cargo bay.
- *Crew & FTL:* 1500–3000 crew. FTL-capable.
- *Counters:* Battleships at range, Stealth Frigates striking the hangar deck, and any tactic that forces it to engage without its wings deployed.

#### Assault Carrier *(new)*
- *Role:* Frigate-Carrier hybrid — deploys drones, not fighter wings.
- *Operational Context:* A smaller, faster Carrier that trades fighter capacity for drone command links and a respectable medium weapon battery. Useful for alliances that can't crew a full-scale Carrier wing. Common BLT design — the deck handles drones recovered from kills, refits them, and re-deploys.
- *Crew & FTL:* 400–700 crew. FTL-capable.
- *Counters:* Anything that severs the drone control link (E-War) or out-ranges its medium guns.

#### Battleship
- *Role:* Frontline heavy combat — the anchor of the battle line.
- *Operational Context:* Massive, heavily armored, designed for sustained bombardment. Where a Heavy Cruiser is the *backbone*, a Battleship is the *hammer*. FED Battleships are gleaming standard-pattern hulls maintained at fleet bases; MAR Battleships are slab-sided, brutalist, and intentionally ugly; BLT does not build Battleships — it steals them.
- *Crew & FTL:* 2000–4000 crew. FTL-capable but slow to spool.
- *Counters:* Bomber wings, Dreadnought spinal weapons, swarms of Heavy Fighters at point-blank range.

#### Dreadnought
- *Role:* Overwhelming firepower — siege of capital fleets and Citadels.
- *Operational Context:* See [Hulls TDD §C](./ships_hulls_classes.md#c-capital-class-cruisers--dreadnoughts). Alliance prestige hull, deployed only for declared operations (a Wardec siege is the canonical use case — see [../social/social_alliance_guild.md §3](../social/social_alliance_guild.md)). Famously vulnerable to E-War and torpedoes; never fielded without a Frigate screen.
- *Crew & FTL:* 4000–7000 crew. FTL-capable but extremely slow.
- *Counters:* Bombers, mass torpedo strikes, E-War stripping its weapon timing.

#### Siege Monitor *(new)*
- *Role:* Capital-grade spinal weapon on a slow, fortress-like hull. Anti-Citadel specialist.
- *Operational Context:* Cheaper than a Dreadnought, half the speed, mounted around a single oversized weapon. Cannot meaningfully maneuver in a fleet engagement — it's a fixed asset that gets *delivered* to the siege site by tugs and escorts. FED variant is the official Wardec Citadel-cracker. MAR variant doubles as a static defense platform between deployments. BLT does not field this hull.
- *Crew & FTL:* 1500–2500 crew. FTL-capable but reliant on escort.
- *Counters:* Fast hulls that close inside its tracking arc, bombers, and any force that destroys its escort first.

#### Super-Dreadnought
- *Role:* Strategic weapon platform — the pinnacle of conventional fleet engineering.
- *Operational Context:* One per major alliance, if any. A Super-Dreadnought is doctrine-defining — its presence in a sector reshapes the strategic map and triggers automatic Federation diplomatic interest. Forward-looking design: this hull is reserved for endgame alliance content and is not yet present in the [Hulls TDD](./ships_hulls_classes.md). FED licenses one per Sector Admiralty; MAR builds them on principle even when they can't crew them; BLT has never fielded one and it would be Federation-priority-one if they did.
- *Crew & FTL:* 8000+ crew. FTL-capable but slower than a Dreadnought; relies entirely on escort and StatCom intel.
- *Counters:* A coordinated Wardec response with multiple Dreadnoughts and a Carrier wing — nothing solo.

#### Titan / Flagship
- *Role:* Fleet command and coordination — strategic heavy lift.
- *Operational Context:* Massive command asset incorporating onboard logistics, repair docks, and strategic comms. Functions less as a damage-dealer and more as a *moving headquarters* for an alliance fleet. The Titan is the only mobile hull capable of housing a full forward operations staff. Forward-looking; ties into the alliance leadership flow described in [../social/social_alliance_guild.md §1](../social/social_alliance_guild.md).
- *Crew & FTL:* 10,000+ crew. FTL-capable but slowest in the index.
- *Counters:* Whole-fleet engagement; it is not killed in a duel.

#### Mothership
- *Role:* Mobile strategic base — capable of building, launching, and hosting full sub-fleets.
- *Operational Context:* The largest hull in the classification. A Mothership is effectively a mobile Citadel — internal hangars, refineries, hospital decks, and small-craft construction. The nucleus of a deep-space alliance presence. Forward-looking and likely a single-digit population in the entire game world. Conceptually overlaps with the StatCom (it provides the same alliance-wide intel in its zone) but is a *combat-survivable* version of that role.
- *Crew & FTL:* 15,000+ crew. FTL-capable; transit is itself a strategic event.
- *Counters:* Nothing reliably solos a Mothership; its destruction is a multi-alliance coordinated effort.

---

## 3. Strategic & Specialized Assets

*Non-line-of-battle hulls. They don't anchor a fleet — they enable one.*

### Support Class — Tenders, Tankers, Hospital Ships
- *Role:* Field repair, refueling, and crew recovery.
- *Operational Context:* Long-deployment alliances live and die by their Tender wing. FED runs centralized "fleet train" doctrine — Tenders accompany the line ship at all times. MAR keeps repair work close to fixed installations. BLT cannibalizes captured wrecks instead of running formal Tenders, which is why their long campaigns collapse fast.
- *Counters:* Soft targets. Killing the Tender wing is how you break a sustained capital deployment.

### Electronic Warfare — Jammers & AWACS
- *Role:* Sensor manipulation, stealth detection, jammer screen, cyber-offense.
- *Operational Context:* The companion class to the [FoW system](../combat/combat_fog_of_war.md). An AWACS-fit Frigate dramatically extends fleet vision via the directional-cone sensor mount; a Jammer-fit Frigate denies enemy targeting (the `eccmStrength` field is the resistance lever). Heavy E-War is what neutralizes a Dreadnought before its spinal weapon cycles.
- *Counters:* Anti-radiation missiles, sensor-bonused scouts that decloak the jammer source.

### Defensive Monitor
- *Role:* Slow, heavily-armed, anchored. Defends fixed locations and chokepoints.
- *Operational Context:* Distinct from the Siege Monitor — this hull doesn't *go anywhere*. Used to fortify Outposts, jump-gate approaches, and Citadel docking corridors. FED stations are surrounded by a ring of these.
- *Counters:* Long-range bombardment from outside its weapon envelope.

### Q-Ship
- *Role:* Deceptive vessel disguised as a civilian freighter.
- *Operational Context:* A BLT and FED counter-piracy specialty. Looks like a slow Heavy Freighter on the sector map; opens fire when a pirate closes to boarding range. FED runs licensed Q-Ship operations as anti-piracy bait in Low-Sec; BLT runs *reverse* Q-Ships — false-flag warships disguised as freighters used for ambushes inside an enemy convoy. MAR considers the entire concept dishonorable.
- *Counters:* Sensor-bonused scouts that read mass-to-signature mismatches before engagement.

### Salvage Tug
- *Role:* Wreck recovery and capital-asset towing.
- *Operational Context:* See [Hulls TDD §D](./ships_hulls_classes.md#d-industrial--support-class-non-combat). The only hull that can latch onto a capital wreck and harvest Golden Logic without engine damage. Doctrinally a *post-battle* asset — it arrives once the firing has stopped.

### Mobile Refinery
- *Role:* Deep-space ore processing.
- *Operational Context:* See [Hulls TDD §D](./ships_hulls_classes.md#d-industrial--support-class-non-combat). Bypasses the 35% Federation tax (canonical number — see [../economy/economy_trade.md](../economy/economy_trade.md)) but broadcasts a massive radar signature, making it a high-priority pirate target.

### Mining Barge *(new)*
- *Role:* Dedicated ore extraction platform.
- *Operational Context:* Distinct from a Heavy Freighter — the Barge *cuts* the rock, the Freighter *moves* it. Heavy hardpoints are mining lasers, not weapons. FED Barges run in protected Hub fleets; MAR Barges are armored to survive pirate ambushes; BLT Barges are stolen FED hulls running unlicensed in Null-Sec. A standard mining op pairs one Barge, two Freighters, and at least one Frigate escort.
- *Counters:* Anything. Barges have no real combat fit and rely entirely on escort.

### Transporter Hull Family (Light Hauler, Heavy Freighter, Armed Hauler, Bulk Hauler)

The Transporter role's hull family. All four variants share one defining trait: they fit a **Crate-Push Rail** module (see [`./ships_weapons_armaments.md`](./ships_weapons_armaments.md) §D) and push external crates rather than relying solely on internal cargo. This makes Transporter cargo *visible from the outside*, which interacts directly with the color-coded Crate doctrine (red = explosive, yellow = explosive gas — see [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) "External Crates"). Visible cargo is also what makes Cargo Sniffer (T2 hacking) and Supply-Chain Tap (T3 hacking) so doctrinally important against this role.

- **Light Hauler:**
  - *Role:* Single-pilot short-haul cargo.
  - *Operational Context:* Frigate-tonnage, M-class Crate-Push Rail (2-4 crates), single defensive turret hardpoint (typically Machine Gun or Flak), no PD beyond that. Fast for a hauler — fits a single Crate-Push Rail and prioritizes thrust over capacity. The "I'm running one delivery before the gate closes" hull. Common across all factions; BLT variants are stripped frames pushed by oversized engines, FED variants are licensed couriers, MAR variants run armored.
  - *Counters:* Anything with a Sensor Probe and a Stealth Missile launcher.

- **Heavy Freighter:**
  - *Role:* Bulk transport — the prime piracy target across the entire game.
  - *Operational Context:* See [Hulls TDD §D](./ships_hulls_classes.md#d-industrial--support-class-non-combat). L-class Crate-Push Rail (6-8 crates), single defensive turret, slow as a moon. The "we both know I can't outrun you" hull — Transporters in this hull-class survive on convoy escort doctrine, not their own guns. Visible crate loadout makes them especially vulnerable to selective targeting: if a Heavy Freighter is pushing a red Explosive Crate, careful pirates do everything possible to disable the hauler without hitting the crate.
  - *Counters:* Anything. Heavy Freighters rely entirely on escort and crate-hazard intimidation for survival.

- **Armed Hauler (Q-Adjacent):**
  - *Role:* Self-defending freight hauler — willing to trade some crate capacity for combat capability.
  - *Operational Context:* Same tonnage as Heavy Freighter, but the rail is downsized to M-class (4-6 crates) to free hardpoints for **multiple defensive turrets**: typically two-to-four Machine Guns, one Flak Battery, optionally a Pulse Laser PD turret on higher-tier variants. Some Armed Haulers fit an Iron Dome Interceptor for convoy-cover capability, becoming the *mobile PD anchor* of a Transporter convoy rather than just protecting themselves. Doctrinally what most Transporter players actually fly once they can afford it — the Heavy Freighter's "all cargo, no guns" is too vulnerable in contested space. Distinct from a [Q-Ship](#q-ship-deception-counter-piracy): an Armed Hauler is openly armed; a Q-Ship hides its guns until ambushed.
  - *Counters:* Mass attack that overwhelms PD; stealth missiles that slip through; coordinated tractor + pusher kidnap from outside PD bubble range.

- **Bulk Hauler:**
  - *Role:* Capital-tonnage long-haul transport — alliance supply trains.
  - *Operational Context:* Battleship-class tonnage, XL-class Crate-Push Rail (12+ crates), no primary weapons, fits multiple defensive turrets but cannot reasonably defend itself solo. **Always travels in convoy** with escort frigates / cruisers / armed haulers. The "alliance supply train" hull — moves materials between alliance citadels, between systems, in volumes that justify capital risk. Almost never seen flown solo in contested space; if you see one alone in null-sec, it's bait or a courier mistake. Doctrinally the primary target of Supply-Chain Tap blockade ambushes — losing a Bulk Hauler is a strategic alliance-level loss, not just a player-level inconvenience.
  - *Counters:* Pre-positioned blockade with Iron Dome saturation, Stealth Missile single-target disable, then Pusher Prow capture for tow-and-loot. Killing a Bulk Hauler outright is wasteful; capturing it intact is the high-value outcome.

---

## 4. Stations & Fixed Installations

*Static infrastructure. Some are Federation-owned (cannot be destroyed), others are alliance-deployable (vulnerable during a Wardec).*

### Outpost
- *Role:* Small modular station — a beginner alliance footprint.
- *Operational Context:* Cheaper than a Citadel, less defensive grid, no capital construction. The first thing a young alliance plants in a contested system. Provides docking, basic refining, and a member-only market terminal. Fit it with Defensive Monitors or it dies the first time a Wardec is declared.

### Citadel
- *Role:* Alliance home base — full power grid, capital docking, automated defenses.
- *Operational Context:* See [../social/social_alliance_guild.md §3](../social/social_alliance_guild.md) and [../ground_base/progression_base_building.md](../ground_base/progression_base_building.md). The Citadel is the canonical alliance asset and is documented in those docs — this index does not redefine it.

### Refinery Platform
- *Role:* Alliance-shared 0%-tax ore processing.
- *Operational Context:* The Citadel's economic complement. Members refine here instead of paying the 35% Federation tax at a Hub. A profitable Refinery Platform is also the most common Wardec target — destroying it is a direct economic strike.

### Shipyard / Drydock
- *Role:* Capital ship construction and repair.
- *Operational Context:* The only place Battleships, Dreadnoughts, and larger hulls can be built. FED Shipyards are Hub-attached and licensed; alliance Shipyards must be built adjacent to a Citadel. A Shipyard under siege is the doctrinal trigger for deploying a Siege Monitor.

### Jump Gate (Precursor Ring)
- *Role:* Ancient FTL transit ring fixed beside every major Helion body. **Not faction infrastructure** — the precursor mechanism predates FED and ICE both.
- *Operational Context:* See [../lore/lore_story_bible.md](../lore/lore_story_bible.md) §5. The gate network is **dynamic** — each gate's destination set is whatever other gates currently fall inside its bubble radius, recomputed live from orbital positions. FED and ICE *patrol* the gates around their controlled bodies, but cannot own or destroy them; the ring itself is older than human Helion. Listed here for completeness because every fleet doctrine begins and ends with gate transit and **timing the orbital windows** is a real planning skill.

### Mining Outpost (Pushable / Deployable)
- *Role:* Forward mining infrastructure — a deployable structure pushed into an asteroid belt or remote resource site by a Pusher Prow–equipped hauler.
- *Operational Context:* Mining Outposts are the **mobile economic counterpart to the Alliance Citadel**. They aren't ships and they aren't fixed installations — they're *deployable structures* manufactured at a Shipyard / Drydock, towed to their working location with a Pusher Prow (see [`./ships_weapons_armaments.md`](./ships_weapons_armaments.md) §3.2 "Four-Mechanism Tow-Class"), and anchored in place at a chosen asteroid belt or remote sector. Once deployed, an Outpost auto-mines the local belt with onboard Mining Lasers, stores yield in attached external crates, and ships nothing on its own — it's the alliance / player's responsibility to schedule a hauler pickup. Outposts are vulnerable to attack while deployed; destroying one is a direct economic strike, but a defended Outpost can re-anchor or be re-towed to a safer belt as the strategic situation changes.
- *Three doctrinal variants:*
  - **Standard Mining Outpost** — onboard Mining Laser bank + storage. Cheapest. No defenses. Pure economic asset for alliance / wealthy-player extraction in safe space.
  - **Refining Outpost** — Standard + onboard Refinery. Refines raw ore on-site, dramatically reducing the mass a hauler has to ship back (refined metals are much denser than raw ore). Doctrinal fit: long-distance belts where the round trip cost otherwise eats the yield. The on-site refinery also produces the **byproducts** (Gold, Silver) directly at the Outpost, which means an attacker who captures or destroys a Refining Outpost loses not just current cargo but the *next* refining cycle's precious-metal trickle too.
  - **Fortified Outpost** — Standard + PD turrets + light defensive guns + an Iron Dome socket. Can survive a casual raid; cannot survive a fleet assault. Doctrinal fit: contested-territory mining, alliance border belts. Distinct from an Alliance Citadel — Citadels are large fixed war assets, Outposts are mobile and primarily economic. A Fortified Outpost under serious attack is meant to be re-towed *away*, not held to the last bolt.
- *Pushing & repositioning:* A Bulk Hauler or a dedicated Outpost Tug (Salvage Tug variant) can push an Outpost between deployment sites using a Pusher Prow. Repositioning is *slow* — Outpost mass is capital-tier, and the tug applies its full thrust to drag it. An Outpost in transit is helpless: no mining yield, no defenses online (the systems power down during tow). Repositioning is a strategic-window decision.
- *Counters:* Stealth Missile alpha-strike before defenses spool up; Aggressive Tractor + Pusher Prow capture-and-tow to a friendly anchorage (a captured Outpost is enormously valuable); Quantum Jammer in the access lane to trap the relief fleet on the wrong side of a jump gate while pirates strip the Outpost.

### StatCom (Strategic Communications Array) *(new — see §5)*
- *Role:* Alliance-deployable sensor relay that expands the **sector-map fog-of-war** for every member of the owning alliance.

---

## 5. The StatCom — Sector-Map FoW Extender

> Status: design only. No schema yet. Numbers below are placeholders to be tuned during the systems pass.
>
> **Implementation tie-in (Phase 6.7):** The StatCom is the canonical sync hub for the **Helion mesh-network FOW** — it's a node with a giant `syncRadius` that anchors a wide sync cluster. Multiple StatComs union via the mesh-cluster math in [`MacroSyncMesh`](../../Assets/Scripts/Macro/MacroSyncMesh.cs). The "blinding the enemy alliance" Wardec play emerges naturally: destroying a StatCom collapses its node from the graph, splits the cluster, and shrinks every member's pooled FOW. No special-case logic. See [`../meta/master_to_do.md`](../meta/master_to_do.md) Phase 6.7.

The StatCom is the headline new fixed installation in this index. It is the alliance-scale, deployable, intel-focused evolution of the *Comms Array / Sub-Space Relay* base module described in [../ground_base/progression_base_building.md](../ground_base/progression_base_building.md). The base-module Comms Array pulls **market data** across a few jumps; the StatCom pushes **enemy and traffic intel** to every member of the owning alliance.

### What it does

- Reveals NPC traffic, jump-gate ingress events, and signature pings within a coverage radius `R` (TBD, expressed in jumps) on the **strategic sector map** — not in tactical-instance combat.
- Coverage is broadcast to every online member of the owning alliance and persists as long as the StatCom is operational.
- Multiple StatComs **stack by union**, the same pattern used for fleet vision in [../combat/combat_fog_of_war.md](../combat/combat_fog_of_war.md). No diminishing returns at this layer — the strategic map is a coarser-grained signal than tactical FoW, so coverage simply OR's together.

### What it does not do

- It does **not** provide tactical-instance vision. Tactical FoW is governed entirely by [../combat/combat_fog_of_war.md](../combat/combat_fog_of_war.md) (per-ship baseline + sensor mounts + fleet union). A StatCom does not extend a fleet's combat FoW circle.
- It does not generate market intel — that remains the job of the Comms Array base module.
- It does not provide vision to allied alliances. Each alliance maintains its own StatCom union; vision-sharing across alliance boundaries is a deliberate non-feature.

### Vulnerability and Wardec interaction

- A StatCom is visible on the strategic map to enemies in the same sector. It is a fixed installation — slow to deploy, high HP, but cannot maneuver.
- Outside of a Wardec, a StatCom enjoys the same High-Sec protections as any alliance asset. Inside a Wardec (see [../social/social_alliance_guild.md §3](../social/social_alliance_guild.md)), it becomes a legal target — destroying one collapses that bubble of intel, and "blinding the enemy alliance" is itself a doctrinal early move in any Wardec.

### Open questions (deferred to schema work)

- Exact coverage radius `R` (in jumps).
- Build cost in Federation Credits, raw materials, and crewing requirements.
- Reinforcement timer behavior — does a StatCom enter a reinforcement window like a Citadel, or does it fall in one fight?
- Whether a destroyed StatCom leaves a wreckable asset (Golden Logic recoverable by [Salvage Tug](#salvage-tug)) or simply vanishes.
- Whether a StatCom can be disrupted (rather than destroyed) by E-War — a `Jammer`-fit Frigate sitting next to one might temporarily collapse coverage without committing to the kill.

---

## 6. Cross-Reference Table

| If you want to know… | See |
|---|---|
| Hardpoint counts, mass, HP, turn rates | [ships_hulls_classes.md](./ships_hulls_classes.md) |
| Ship C# struct layout | [ships_schema.md](./ships_schema.md) |
| Weapon catalog and tier | [ships_weapons_armaments.md](./ships_weapons_armaments.md), [ships_weapon_schema.md](./ships_weapon_schema.md) |
| Tactical-instance vision math | [../combat/combat_fog_of_war.md](../combat/combat_fog_of_war.md) |
| Sector zoning and combat instance cap (3v3 + 10 spectators) | [../world/world_sector_rules.md](../world/world_sector_rules.md) |
| Citadel ownership, Wardec rules | [../social/social_alliance_guild.md](../social/social_alliance_guild.md) |
| Base modules (incl. Comms Array) | [../ground_base/progression_base_building.md](../ground_base/progression_base_building.md) |
| Federation tax, Hub pricing | [../economy/economy_trade.md](../economy/economy_trade.md) |
| Lore for Jump Gates and factions | [../lore/lore_story_bible.md](../lore/lore_story_bible.md) |
| NPC fleets and Pirate behaviors | [../world/world_npc_ai.md](../world/world_npc_ai.md) |
