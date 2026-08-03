# MMO Weapons & Armaments Bible

This document details the classes, sizes, mounting types, and resource dependencies for ship weapon systems. All weapons adhere strictly to the "Double-Schema" model, where player-crafted weapons (via the Alchemy Matrix) can drastically outperform standard Federation "Store-Bought" tech.

## 0. Combat Doctrine — "Navy Battle in Space"

Apex Outlaw combat is designed to feel like **a naval engagement, not an aerial dogfight**. Capital ships slug it out at range with heavy kinetic guns and missile salvos; destroyers and frigates screen the line; carrier-style hulls launch fighter/drone wings; close-in defense layers (PD lasers, machine guns, flak, interceptor missiles) shoot down incoming threats; and desperate close engagements end in ramming.

**Primary weapons are kinetic-first.** Big naval guns (autocannons, railguns), missiles, and torpedoes do the killing. Plasma and Ion are heavy energy specialties — slower, niche, expensive — not the default. **Lasers are not primary weapons.** Lasers exist as **point-defense and anti-small-target** modules — they shoot down missiles, drones, and small fighters; they don't slug capital ships. Machine guns play the same anti-fighter / anti-drone role as their wet-navy CIWS counterparts.

This doctrine is *load-bearing across the whole design*: it's what justifies the three-pillar PD system, the kinetic-heavy Tier 2/3 ammunition chains, the existence of ramming and blockade equipment, and the Tier 4 capital weapons being the only "decisive" energy weapons in the game. If you find yourself proposing a primary-energy-laser weapon, you're drifting away from canon — push back to whichever pillar (PD, kinetic primary, specialty energy) it actually belongs in.

---

## 1. Weapon Sizes (Hardpoint Classification)
Ships are limited by mass, reactor output, and physical hardpoint sizes. Fitting a massive gun on a small ship is impossible due to recoil, energy draw, and sheer size.

- **Small (S) | Point-Defense & Interceptors**
  - High fire-rate, extremely fast tracking rotation.
  - Very low energy cost; negligible heat generation.
  - *Primary role:* Shooting down incoming missiles/torpedoes or skirmishing with agile light-fighters.
- **Medium (M) | Cruisers & Frigates**
  - The standard backbone of fleet combat. Moderate tracking speed.
  - Balanced heat and energy draw.
  - *Primary role:* Stripping shields and cracking standard armor plating.
- **Large (L) | Artillery & Battleships**
  - Extremely slow tracking rotation. Devastating damage.
  - Massive heat generation requiring dedicated Alchemy cryo-coolants to fire continuously.
  - *Primary role:* Punching through heavy capital armor or bombarding Citadels. 
- **Capital (XL) | Spinal Mounts**
  - Built directly into the spine of Dreadnoughts (Mars/Federation flagships).
  - Rotation is tied entirely to the ship's physical turn rate (`TurnSpeed`). 
  - Firing an XL weapon often temporarily disables the ship's main thrusters and shields due to immense capacitor drain.

---

## 2. Mounting Types
How the weapon physically tracks a target.

- **Fixed Mounts:**
  - `TrackingArc: 0°`
  - Cannot rotate. The pilot must aim the entire ship nose directly at the target.
  - *Trade-off:* Highest base damage and lowest energy cost in their size class.
- **Gimbaled Mounts:**
  - `TrackingArc: 30° - 45°`
  - The barrel can pivot slightly, allowing for "Smart Targeting" to assist in leading fast-moving targets.
  - *Trade-off:* Lower damage than Fixed, but much higher accuracy during evasive maneuvers (Strafing).
- **Turreted Mounts:**
  - `TrackingArc: 360°`
  - Autonomous or multi-crew turrets that can fire independently of the ship's facing direction.
  - *Trade-off:* Lowest base damage, highest mass overhead, and consumes significant capacitor energy to power the rotation motors.

---

## 3. Damage Types & Alchemy Paradigms

### A. Kinetic Path (Primary Weapons — ICE, Outlaw, BLT)
*Requires physical ammunition. High Hull Damage. Low Shield Damage. **This is the primary weapon doctrine for the game** — most kills in most engagements are kinetic.*
- **Naval Autocannons:** (M/L) Heavy rotary cannons — the workhorse capital primary. Sustained fire of AP Steel / API rounds. ICE doctrine staple; BLT scrap-fits run looted variants. Uses standard *Steel* and *Titanium* feedstock.
- **Railguns:** (M/L) Slow, high-velocity sniper weapons. High penetration. Capital-range engagement. Requires *Super-Conductors (Copper+Carbon+Lithium)* and ultra-dense *Tungsten* slugs.
- **Heavy Cannons / Naval Guns:** (L/XL) Slow-firing capital primaries that lob HE Shells or Tungsten Penetrator rounds at line-of-battle range. The "broadside" weapon doctrinally — multiple Heavy Cannons on the same fire arc let a capital hull deliver a coordinated salvo each cooldown cycle. ICE Battleship signature loadout.
- **Machine Guns:** (S) Light high-ROF kinetic anti-aircraft. Standard ammo is **Machine Gun Drums** (Steel + Sulfur, cheaper than AP Steel Rounds). Engages fighter-class ships, drones, missile bodies, and incoming bomblets at short range. **One of four point-defense modules** — see [§3.1 Point-Defense Doctrine](#31-point-defense-doctrine-four-pillar-pd). Distinct from Autocannons: MGs sacrifice damage and reach for hit-rate and ROF, optimized purely for anti-small-target rather than dual-purpose use.
- **Flak Batteries:** (S) Turreted close-range explosive shrapnel to counter incoming ordnance or swarm tactics. **One of four PD modules** — burst-round / shrapnel answer to incoming missile clouds. Cheap per intercept, mediocre hit rate against single targets but high effective area coverage. See [§3.1 Point-Defense Doctrine](#31-point-defense-doctrine-four-pillar-pd).

### B. Energy Path — Specialty Heavy (FED Core, Capital Niche)
*Draws directly from the Capacitor. Devastates Shields. Melts Hull slowly. **This is a specialty doctrine, not a primary one** — energy weapons are slower, expensive, and capital-niche. The bulk of fleet damage flows through Kinetic; Energy is what cracks shields or finishes a wounded capital.*
- **Plasma Casters:** (S/M/L) Fires bolts of superheated gas. Extremely high Heat generation. Requires *Helium-3* and *Hydrogen*. A ship generating too much heat might melt its own systems if not vented. **Doctrinal role:** anti-shield primary on cruiser-class hulls; capital-scale variants exist but pair badly with Slow-Bank capacitors because of the heat curve.
- **Ion Beams:** (M/L) Continuous particle-stream weapon — described as "laser-like" but technically an electromagnetic ion stream, which is why it's classed Energy primary rather than PD-laser. Perfect accuracy instantly, but requires the target to remain in the beam. Uses rare *Neon* and *Silicates*. Devastates shields, heavily mitigated by standard armor. **Doctrinal role:** anti-shield specialty — pairs with a kinetic primary to strip shields then crack hull.

**Lasers are NOT in this section.** Pulse Lasers, UV Lasers, IR Lasers, X-ray Lasers, and Talos Laser Arrays are all **point-defense / anti-small-target** modules — they shoot down missiles, drones, and small fighters, not capital hulls. See [§3.1 Point-Defense Doctrine](#31-point-defense-doctrine-four-pillar-pd) for the full PD laser pillar. The one apparent exception is the Tier 4 **X-ray Laser** spinal mount; even that is a *penetration* weapon (bypasses shields and armor for internal damage) rather than a bulk-damage primary, and lives doctrinally closer to the Antimatter Lance exotics than to a primary energy weapon.

### C. Tactical & Explosive Path (Heavy Support)
*Ammunition-heavy, devastating alpha-strike potential but easily countered by Point Defense.*
- **Missile Racks:** (S/M/L) "Smart" fire-and-forget tracking. Can be evaded, jammed with E-war, or shot down by Small Autocannons.
- **Torpedo Toruses:** (L/XL) Slow, unguided (or poorly guided) bunker-busters designed to crack Alliance Citadels or Capital Hulls. Requires *Uranium* and *Sulfur* payloads.
- **Iron Dome Interceptor:** (M/L) Dedicated **interceptor-missile point-defense** module — launches small autonomous Interceptor Missiles (see [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) "Point-Defense Ammunition") at incoming threats. **Engages multiple targets simultaneously** — the launcher cycles through tracked threats and fires an interceptor at each. Works against *all* projectile types: kinetic shells, missiles, torpedoes, fighters, even cluster bomblets after they fragment. **Tradeoffs:** Interceptor Missile ammo is expensive per intercept (much more than Flak shells, more than Talos's UV cells), but the simultaneous-engagement capability lets a single Iron Dome cover an entire convoy / fleet formation. Doctrinally one of three PD modules — see [Flak Batteries](#a-kinetic-path-mars--belters) (kinetic PD) and [Talos Laser Array](#b-energy-path-federation-core) (energy PD). Standard fit on Heavy Freighters, Mobile Refineries, and any hull that needs area defense rather than self-defense.

### D. Industrial & Utility Modules (Non-Weapon)
*Mount on the same physical hardpoints as combat weapons but cannot deal damage to ships. They fire a sustained beam at a non-ship target (asteroid, wreck, derelict, friendly ship) to perform an industrial action. Output volume and quality scale with the module's grade.*

- **Mining Laser:** (S/M/L) Fires a continuous extraction beam at a vein-typed asteroid. Output is units-per-second of the asteroid's raw material; rate and yield-per-tonne scale with grade. Larger sizes punch deeper into harder rock — Large Mining Lasers are required for dense ore bodies (e.g. Titanium-rich roids). See [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) Tier 1 for the vein-typed material list.
- **Salvage Beam:** (S/M/L) Counterpart to the Mining Laser, but targets *wreckage* — destroyed ships, derelicts, abandoned station fragments, junkfields. Output is **Scrap Metal** (single raw resource, see [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) Tier 1 "Salvage-sourced"). Per-tick yield scales with the wreck's original mass class — a Battleship wreck yields more Scrap-per-second than a Frigate wreck. The actual metal mix that comes out of Scrap is decided later at refining time, not at the salvage moment. The Salvage Beam itself only produces ungraded Scrap Metal stacks.
- **Tractor Beam:** (S/M) *Forward-looking, not yet authored as a module.* Pulls wrecks / asteroid fragments toward the salvager without breaking them up. Doctrinally paired with a Salvage Tug — see [`./ships_class_index.md`](./ships_class_index.md#salvage-tug).
- **Crate-Push Rail:** (M/L/XL) Structural rail system mounted on the hauler's bow / sides that **holds external crates** for transit. The hauler's thrusters push the crates rather than carrying them in internal cargo. The rail is what makes Transporter doctrine work — a hauler with one Crate-Push Rail (M) carries 2-4 crates externally; an L-rail Heavy Freighter carries 6-8; a XL-rail Bulk Hauler carries 12+. Distinct from the Pusher Prow (§3.2) — Pusher Prow pushes *ships*, Crate-Push Rail holds and pushes *cargo containers*. Crates on the rail are exposed to enemy fire (the whole point — see [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) "External Crates" doctrine) and can be jettisoned in emergencies. A hull can fit one Crate-Push Rail; combined crate mass counts against the hauler's total tow / push thrust budget. Doctrinally the defining utility module for the Transporter role — without one, you're carrying cargo internally and capped at hull cargo capacity; with one, you're a "convoy of one" pushing your own freight train.

**Hacking & Intel Modules (read-only — see [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) "Hacking & Intel Chain" for the manufacturing chain):**

- **Sensor Probe:** (S/M) Consumes a Signal Decoder Array per scan. Pings a single target ship at close range; on success, the hacker's UI shows the target's full equipped-modules list (weapons, engines, armor, capacitor, reactor). Detectable — the target sees a "scan event" warning and the hacker's identity. Tier 2.
- **Cargo Sniffer:** (S/M) Consumes a Signal Decoder Array per scan. Same range / detection profile as Sensor Probe but reads a transporter's current packing slip (resource stacks and module instances by `itemID`). Does NOT reveal Alchemy Matrix peaks or grade — only the count and identity of what's in cargo. Tier 2.
- **Signal Tap:** (M/L) Consumes a Phantom Relay per session. Passive — undetectable to the alliance being tapped. Captures alliance chat traffic in a sector-wide radius for the session's duration; messages appear in the hacker's intel log on a decryption delay. Tier 3.
- **Notice Board Decryptor:** (M/L) Consumes a Phantom Relay per session. Passive — undetectable to the alliance being tapped. Reads the target alliance's public notice board (announcements, member calls, contract postings). Slower per-read than Signal Tap because the board is bulk-encrypted at write time. Tier 3.
- **Supply-Chain Tap:** (M/L) Consumes a Phantom Relay per session. Passive — undetectable. Parses alliance chat + notice + sector-passive logistics traffic into a structured **inbound/outbound shipment manifest**: sender, receiver, cargo (count + itemID, no grade), origin sector, destination sector, ETA, predicted route. **This is the canonical blockade-enabler** — the hacker reads the manifest, the pirate fleet sets up the intercept along the predicted route, and the convoy gets hit before it ever reaches the alliance. Tier 3.
- **Roster Sniffer:** (M/L) Consumes a Phantom Relay per session. Passive — undetectable. Reads the target alliance's **membership roster + rank structure**: member playerId / display name, rank title, rank tier index, last-seen timestamp, last-seen sector. Roster accuracy improves the more chat traffic the relay captures (member metadata is reconstructed from chat headers). **The "who's who" enabler** — once a hacker has roster intel, all other modules (Sensor Probe, Cargo Sniffer, Supply-Chain Tap) can be filtered to track specific high-rank named members rather than scanning the whole alliance blindly. Tier 3.
- **Transaction Ledger Tap:** (M/L) Consumes a Phantom Relay per session. Passive — undetectable. Reads a target member's **recent transaction history** captured during the relay session: market buys / sells, contract completions, credit transfers, alliance armory draws. Limited scope by design — only transactions whose metadata leaks during the session are visible. Cannot see balance, deep history, or proxy-routed transactions. **Drives target-selection for blockades and bounties** — identifies who's rich, who's running contraband, who's been buying specific gear. Tier 3.
- **Combat Record Tap:** (M/L) Consumes a Phantom Relay per session. Passive — undetectable. Reads a target player's **recent combat engagements** captured from intercepted combat-report traffic: timestamp + sector + opponent IDs + ship-class matchups + outcome (kill / loss / disengagement) + weapons used. Limited scope — only engagements whose reports leak during the relay session are visible. Cannot see lifetime W/L ratios or aggregate kill counts (those require Tier 4 Member Dossier). **Drives target-selection for combat planning** — distinguishes paper tigers from real threats before committing a fleet. Player combat statistics are otherwise **private state** even from alliance leadership; hacking is the only external read path. Tier 3.
- **Tech Tree Spy:** (L) Consumes a Quantum Backdoor per use. Single-use consumable. Produces a one-time transcript of the target alliance's current tech-tree state (unlocked researches and their grade ceilings, including 12,345 peaks where present). Detectable *after the fact* — the target alliance sees an "internal data access event" log naming the sector + data category, but not the specific hacker. Tier 4.
- **Privilege Ledger Decryptor:** (L) Consumes a Quantum Backdoor per use. Single-use consumable. Produces a one-time readout of the target alliance's **rank-based privilege table** — which equipment each rank tier is permitted to draw from the alliance armory, special-issue gear allocated to officers, hidden contracts tied to specific named members. Reveals the **power asymmetry inside the alliance** between top-tier and low-tier members. Doctrinally complements Roster Sniffer: Roster tells you the org chart, Privilege Ledger tells you the salary table. Detectable on the same "internal data access event" log as Tech Tree Spy (different data-category tag). Tier 4.
- **Member Dossier Decryptor:** (L) Consumes a Quantum Backdoor per use. Single-use consumable, **per named member targeted**. Produces a one-time deep-dive readout of one specific player across both economic and combat axes: full historical transaction ledger (deep, not session-scoped), past loadout snapshots indexed by engagement timestamp, current credit balance, active contract list, alliance armory draws over time, AND **lifetime combat record** — total fights, win/loss ratio, kill counts by ship class, named-opponent kill counts (rivalries surface here: "Velkov 7 — Smith 2"), highest-grade kill, fleet engagement participation. Combat stats are otherwise purely private; even alliance leadership doesn't see non-member combat stats. **The apex single-target intel** — used to decide whether to recruit, defect to, bait, ambush, or bounty a named player. Detectable on the same internal-data-access-event log; target sees they were dossier'd but not by whom. Tier 4.

These modules mount on the standard `Weapon` hardpoint class. The hull's slot must accept industrial / e-war classes — frontline combat slots reject them, intel hulls (recon Frigates, Q-Ships, smuggler builds) accept them. Slice 2/3 of the inventory plan formalizes the `componentClass` filter.

These modules share the **Weapon hardpoint class** (drop them onto the same hardpoints as combat weapons), but the hull's hardpoint slot must accept them — a frontline Frigate's combat-only hardpoint won't take a Mining Laser, while a Mining Barge's "Industrial" hardpoint will reject combat weapons. The acceptance rule is a `componentClass` filter on the [`HardpointSlot`](../../Assets/Scripts/Schemas/ShipSchema.cs) — see Slice 2/3 of the inventory plan for the schema work.

### E. The Outlaw Arsenal (Black Market / Illegal Tech)
*Banned by the Federation. Exceedingly rare, utilizing unpredictable physics.*
- **Gravity Well Generators (Tethers):** (Utility) Fires a local distortion field that anchors a target's velocity, preventing warp-escape.
- **Singularity Coils:** (XL) Fires a localized micro-black hole that pulls nearby fighters into its trajectory before collapsing. Requires *Dark Matter* and *Metallic Hydrogen*.
- **Antimatter Lances:** (L) An energy weapon that deals pure, unmitigated damage to BOTH Shields and Hull equally, but carries a 5% chance per shot to critically overload the user's reactor.

---

## 3.1 Point-Defense Doctrine (Four-Pillar PD)

Every projectile-heavy fleet engagement is decided as much by PD as by primary weapons. The four canonical PD pillars are intentionally non-redundant; each covers a niche the others can't, and most fleet doctrines mix two of them to plug each other's gaps.

| Pillar | Module | Tier | Cost per Intercept | Hit Rate | Engagement Profile | Covers |
|---|---|---|---|---|---|---|
| **Kinetic — Burst** | Flak Batteries | T2 | Cheap (Steel + Sulfur shells) | Mediocre per shot, high area coverage | Self-defense bubble, area shrapnel | Missile clouds, bomblet swarms |
| **Kinetic — High-ROF** | Machine Guns | T2 | Cheap (Machine Gun Drums) | High per shot, single-target | Anti-fighter, anti-drone, can hit small missiles | Fighter-class ships, drones, missile bodies in flight |
| **Energy (Laser PD)** | Pulse Laser Turret / Talos Laser Array | T2 / T3 | Moderate (Pulse Laser Cells) / High (UV Laser Cells) | High to near-perfect | Lightspeed beam, single target at a time | Missiles, drones, fighters — *not* energy weapons |
| **Interceptor Missile** | Iron Dome Interceptor | T3 | Highest (Interceptor Missiles) | High, smart guidance | Area defense over a fleet / convoy, **multiple simultaneous targets** | All projectile types — kinetic, missile, torpedo, cluster bomblets, fighter swarms |

**Laser PD modules (specifically — this is where Pulse / UV / IR / X-ray cells get consumed):**
- **Pulse Laser Turret:** (S) Anti-fighter laser CIWS — autonomous turret that targets fighter-class ships and drones. Consumes Pulse Laser Cells. Mid-range anti-small-ship; the laser equivalent of the Machine Gun pillar's role.
- **UV Laser PD ("Talos Laser Array"):** (S/M) Dedicated anti-missile laser. Consumes UV Laser Cells (or Neon-bias UV alt). Near-perfect intercept of incoming missiles thanks to UV-spectrum tracking + Hyper-Lattice sensor coupling. Heavy reactor draw; capital-class fit.
- **IR Laser PD:** (S/M) Heat-saturating PD — instead of vaporizing the missile, pumps so much heat into its guidance package that the missile loses lock and tumbles. Consumes IR Laser Cells. Effective against guided ordnance only — useless against dumb kinetic shells. Specialty fit for hulls expecting heavy missile barrage.
- **X-ray Laser Spinal:** (L/XL) The lone capital-tier laser — penetration weapon, not bulk damage. Bypasses shields and outer armor for direct internal damage on one target per shot. Doctrinally an *exotic capital weapon*, not a PD module; placed here because it's the only laser type that points outward at capital hulls rather than inward at incoming threats.

**Doctrinal fits:**
- **Interceptors / dogfighters** fit Machine Guns + Flak — cheap ammo, light reactor draw, single-ship self-defense.
- **Cruisers / Frigates** fit Machine Guns + Pulse Laser Turrets — covers both fighters and small missile barrages.
- **Capital combat hulls (Battleships, Dreadnoughts)** fit UV Laser PD (Talos) + Flak — the Slow-Bank capacitor + Fusion reactor feed the laser, Flak covers swarm missiles.
- **Logistics hulls + fleet command** fit Iron Dome — area coverage over an entire convoy is the only PD doctrine that protects multiple soft targets simultaneously.

**No PD pillar covers everything.** Energy primary weapons (Plasma Casters, Ion Beams) and the Tier 4 Antimatter Lance fundamentally cannot be intercepted — they're lightspeed or near-lightspeed beams. The countermeasures for those are armor (Reactive / Ablative / Polymer-Ceramic), shields, and signature suppression (Stealth Coating), not point defense. This is a deliberate doctrine boundary: **PD beats projectiles; armor / stealth beats beams**.

**Implications for the Supply-Chain Tap blockade loop:** A convoy with no Iron Dome is critically vulnerable to a missile-launching ambush, because Flak / MG / Laser PD can't cover multiple soft targets simultaneously. Pirates reading a Supply-Chain Tap manifest will preferentially target convoys without escort, OR convoys whose escort can't field area PD. Iron Dome is the canonical anti-blockade technology; alliance logistics doctrine should plan for Iron Dome coverage on every scheduled convoy that's been potentially leaked through the Tap.

## 3.2 Naval Close-Combat & Blockade

When the long-range slugging match collapses into a close-quarters engagement, or when a fleet wants to deny territory rather than fight for it, a different set of modules comes into play. These are *not* primary weapons — they're tactical specialty equipment that exists to make naval-style close engagements and blockade scenarios feel weighty.

**Ramming:**
- **Ramming Spike / Reinforced Prow:** (L/XL nose-mount) Hardened impact prow that turns the ship itself into a kinetic weapon at point-blank range. Material chain: Tungsten + Ferro-Titanium + Stainless Alloy → **Reinforced Prow Plate** (Tier 3 component) → Ramming Spike module. **Tradeoffs:** colliding deals enormous damage to the target *and* significant self-damage; the Spike just shifts the damage ratio in the rammer's favor (e.g. 80% damage to target, 20% to self, vs. baseline 50/50). Doctrinally Outlaw / desperate / "I'm not surviving this engagement anyway" tech. ICE Battleships occasionally fit reinforced prows for line-of-battle close work.

**Four-Mechanism Tow-Class (Friendly + Hostile Variants):**

Moving another ship through space — whether for rescue, salvage, kidnapping, or formation disruption — uses one of four distinct mechanisms. Each has different range, speed, vulnerability, and cost characteristics. Every tow module has both **friendly mode** (cooperative target, no resistance) and **hostile mode** (target tries to break free; lock strength becomes the limiting factor).

| Module | Tier | Mechanism | Range | Tow Speed | Vulnerability | Best For |
|---|---|---|---|---|---|---|
| **Tow Cable Winch** | T2 | Physical grapple + reinforced cable | Close (fire grapple at contact range, cable extends ~1 hull-length after attachment) | Slow (cable drag + winch RPM) | **Cable can be severed by enemy fire**; cable also fails under extreme yaw / pitch shear from a struggling hostile target | Disabled-ally rescue, wreck towing, low-cost hostile drag of a weaker hull |
| **Tractor Beam (Industrial)** | T2/T3 | Gravity-field tractor, smooth pull | Medium (sustained beam at moderate range) | Moderate | Continuous capacitor drain; can be jammed by ECM modules; beam breaks if line-of-sight is lost | Asteroid / wreck salvage (existing canon — see [§D Industrial & Utility Modules](#d-industrial--utility-modules-non-weapon)) |
| **Tractor Beam (Aggressive)** | T2/T3 | Gravity-field, hostile-target lock | Medium | Moderate | Same as industrial + hostile target's thrusters can resist the pull (lock-strength vs. target-thrust contest) | Pull a freighter out of formation so the fleet pours fire into an immobilized target |
| **Pusher Prow** | T3 | Physical contact push from a flat/curved reinforced bow | Contact only (must remain in contact through the maneuver) | **Fast** — uses the pushing ship's full thrust applied directly to the target | Requires the tug to stay in contact and aligned; hostile targets spin/maneuver to break alignment; consumes the tug's own thrust budget so the tug can't dodge while pushing | Salvage tug nudging capital wrecks toward a refinery; **aggressive shove** to push a target into a mine field, into a kill zone, or away from a jump gate |

**Pusher Prow** is built on the same Tier 3 **Reinforced Prow Plate** material as the Ramming Spike — but the module configuration is different. A Ramming Spike is a sharp point that maximizes damage at impact; a Pusher Prow is a flat or curved surface that maximizes contact area and force transfer without damaging the target (much — there's still some scrape damage on hostile pushes). A hull can only fit one bow-mount module at a time: Ramming Spike OR Pusher Prow, not both.

**Doctrinal use of the four-mechanism class:**

- **Tow Cable Winch** is the *cheap default* — every freighter, salvage tug, and rescue frigate should fit one. Low cost, simple deployment, but the cable severability means it's not suitable for fights against well-armed targets.
- **Industrial Tractor Beam** is the *salvage standard* — wreck recovery, asteroid moving, debris cleanup. Existing canon.
- **Aggressive Tractor Beam** is the *pirate formation-buster* — used in conjunction with Supply-Chain Tap blockade intel to pull priority targets out of their convoy's PD bubble.
- **Pusher Prow** is the *capital-asset mover* — when a Tractor Beam doesn't have enough lock strength to move a Battleship-mass hulk, or when you need to push a captured ship *somewhere specific* (into a mine field, off course, toward a forced anchorage). Also doctrinally fit on **Salvage Tugs** as their primary working tool, since the Tug's hull is mass-tuned to push capital wrecks and the Tractor Beam falls off at that mass class.

A real salvage fleet doctrine typically fits **all four** — cable for cheap recovery work, industrial tractor for asteroid handling, aggressive tractor for hostile targets the operator wants intact, pusher for capital-scale hulks. The four mechanisms are non-redundant.

**Blockade & Area Denial:**
- **Proximity Mines:** (S/M) Deployable munition — dropped into space at a fixed location, drifts on local orbital mechanics, detonates on proximity to any non-friendly ship signature. Friend/foe IFF keyed to the mine-layer's alliance. **The canonical blockade tool** — used to seal jump-gate transit lanes and force enemies onto predictable routes where ambush fleets are waiting. Mine variants: Kinetic Mine (cheap, dumb HE), EMP Mine (disables ship systems briefly), Nuclear Mine (capital-killer, see [§3.3 Restricted Ordnance](#33-restricted-ordnance) implications below).
- **Mass Driver Boulder:** (XL ammo) Cheap kinetic blockade-bomb — a refined Tungsten or Iron mass accelerated to high speed and thrown into a transit corridor. No guidance, no warhead, just mass + velocity. Used by Outlaw blockade fleets to choke trade lanes without the cost of real ordnance. Doctrinally the "we don't have missile production but we have mining lasers and a cheap accelerator" weapon.
- **Stealth Missile:** (M/L) High-cost stealth-coated missile variant — the missile body wears a Tier 3 Stealth Coating skin, dramatically reducing radar signature and making it very hard for PD systems (especially Iron Dome and Talos) to lock onto. **Stealth missiles are expensive across the board** — see [§3.4 Stealth Cost Doctrine](#34-stealth-cost-doctrine) for the deliberate cost gating. Pairs with any standard warhead (HE, Thermite, Penetrator, etc.) for "PD slips past, alpha-strike lands" gameplay.

## 3.3 Restricted Ordnance

The intersection of weapons and faction law. **Possession** of any item listed below in FED core space triggers an immediate hostility flag; ICE permits some with military license; Outlaw belts unregulated. Restricted ammo / mines / warheads are listed here as a doctrinal reminder, *not* as a separate manufacturing chain — their recipes live in the standard ammunition or specialty trees.

- Depleted Uranium Slug (cannon round)
- Nuclear Warhead (missile / mine variant)
- Nuclear Mine (proximity mine variant of above)
- Antimatter Warhead (missile variant)
- Antimatter Lance (capital energy weapon)
- Quantum Jammer (e-war module)

**Smuggling these creates the transporter risk loop.** A Transporter carrying restricted ordnance from an Outlaw fabricator to an ICE military client is a high-value target precisely *because* the cargo is restricted — FED bounty hunters and FED-aligned pirates can attack them with legal cover.

## 3.4 Stealth Cost Doctrine

Stealth is **expensive across the board by design** — it's the most strategically valuable property in the game (intel suppression, ambush positioning, blockade-evading transport) and the economy is tuned to make sure stealth is never a casual fit. Three rules:

1. **Stealth Coating** (Tier 3) is gated behind both a specialty Tier 2 input (RAM Pigment, which only comes from Carbon + Methane) AND a Tier 3 substrate (Polymer-Ceramic Composite). Two separate refining steps before you can produce one unit of stealth hull skin.
2. **Phase Cloak Field** (Tier 4) requires Dark Matter — the rarest endgame raw. There is no "discount cloak"; covert active stealth is endgame-only.
3. **Stealth Missiles** (Tier 3 specialty ammo) consume a full Stealth Coating unit per missile body. This means each stealth missile costs roughly *4x* a standard HE missile in material terms — RAM Pigment + Polymer-Ceramic refining + Stealth Coating coating step + missile body assembly + standard warhead. Doctrinally these are reserved for high-priority targets where one missile MUST slip through PD; a fleet does not spam stealth missiles like standard HE.

This cost ceiling is intentional: stealth materials should feel like *currency* the player saves up for, not a baseline expense. Tuning that drifts toward cheap stealth breaks ambush gameplay, scout balance, and Transporter risk economics simultaneously — push back on any recipe proposal that lowers stealth material cost without a paired strategic justification.

---

## 4. The Manufacturing Loop (Store-Bought vs Forged)

- **Store-Bought Tier (Value ~2,500):** A Federation "Standard Railgun (M)" purchased from a Hub City for Credits. It works reliably, has fixed stats, and is easily replaced if you die.
- **Forged Tier (Value ~12,345):** An "Alchemist Railgun (M)" crafted by a player who discovered a `12,345` peak for Super-Conductors and Tungsten. 
  - *Result:* The Forged Railgun deals 200% more damage, tracks 30% faster on a gimbal, and generates 50% less heat than the Store-Bought version. 
  - *Risk:* If you equip this weapon and die to a Pirate, they can **Tow** your wreck, recover the Forged Railgun *itself* into their inventory, and (with luck) roll its **Repair Recipe** to keep refurbishing it forever. They cannot manufacture additional copies — that path stays locked behind your Seed — but you have just lost a masterpiece you may never re-forge. See [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md) §4 for the canonical loot rule.
