# NPC Auto-Arbitrage — Trading Posts as Autonomous Market Agents

This document is the canonical design for the **NPC auto-arbitrage system** — the mechanism that makes trading posts behave as autonomous economic agents that detect their own stock shortages, place buy orders against the DOM at other hubs, and dispatch AI transport ships to physically move the goods between locations.

The system serves four simultaneous design goals:

1. **NPC seed liquidity.** New markets bootstrap autonomously — empty hubs detect their shortage and begin sourcing, no admin intervention needed.
2. **Self-maintaining regional pricing.** The admin's per-hub floor/ceiling values (see [`./economy_exchange_pricing.md`](./economy_exchange_pricing.md) §5 "Regional Pricing Doctrine") are *enforced* by the NPC system actively moving goods from cheap-source hubs to expensive-destination hubs.
3. **Steady pirate prey.** AI transport ships traveling predictable routes are recurring targets — losing one doesn't break the supply chain (the hub just sends another), so piracy generates *ongoing* income rather than one-off windfalls.
4. **Coexistence with player Transporters.** AI handles routine commodity flow; players handle high-value cargo, player-to-player contracts, contraband, time-critical runs. Each fills a niche the other can't.

---

## 1. Per-Hub Stock Targeting

Every trading post tracks **target stock levels** for every commodity it handles. The targets are admin-tunable in PlayFab title internal data, set with regional logic (a gas-planet hub targets large gas reserves and small metal reserves; a refinery hub targets large refined-goods reserves; etc.).

```
HubStockLevel  (one per (hubId, itemId), in PlayFab title internal data)
  hubId               : string
  itemId              : string
  targetStock         : long       // ideal amount to hold
  replenishThreshold  : long       // when currentStock drops below this, trigger replenish
  replenishOrderSize  : long       // how much to order per replenish event
  currentStock        : long       // updated in real time
  maxStock            : long       // ceiling — won't accept inbound past this
```

The stock model is the NPC equivalent of a player's inventory at the hub. NPC stock fills player asks (AI is the buyer of last resort when no player wants the commodity) and fills player bids (AI is the seller of last resort when no player wants to sell).

**Visibility:** current stock levels are **publicly readable** at every Bank Terminal — it's market intel any player can see. This prevents the asymmetric-information abuse where a single player has private knowledge that hub X is about to crash. Everyone sees stock; the question is who acts first.

**Target levels are NOT publicly visible** — only admins (and the AI itself) know the trigger thresholds. Players have to *infer* from observed restock patterns when a hub is about to source.

---

## 2. The Restock Cycle

A scheduled CloudScript job runs at every **Weekly Economy Tick** (per [`./economy_obligations.md`](./economy_obligations.md) §6 — same job that handles taxes / loans / storage fees). For every `(hubId, itemId)` pair:

1. **Check stock.** If `currentStock < replenishThreshold`, the hub is **under-stocked** and needs to source.
2. **Compute order.** The hub wants to acquire `replenishOrderSize` units to push back toward `targetStock`.
3. **Scan source hubs.** The system queries the DOM for the cheapest available Ask across all hubs that hold this commodity. Sources are ranked by:
   - Lowest Ask price
   - Shortest physical transit distance from source to destination
   - Faction compatibility (FED hubs source from FED-affiliated hubs preferentially; ICE from ICE)
   - Cargo class (Restricted Ordnance never auto-arbitrages — those routes require player smugglers)
4. **Place buy order.** The system places a **market buy** on `market.<itemId>.<destinationHub>` for the needed quantity. The order fills against existing player Asks AND/OR against the invisible-hand ceiling at the destination hub (creating immediate phantom liquidity if no player Asks exist).
5. **Dispatch AI transport.** The system spawns an AI transport ship at the source hub to physically carry the goods. The transport's route is `source → destination`, ETA computed from the transit distance and the transport's hull class.

The order placement and the AI dispatch happen atomically — if the buy can't be filled (no Asks AND no invisible-hand response), no transport is dispatched. If the buy fills but the AI dispatch fails (e.g., source hub destroyed), the order rolls back.

**Why the buy goes through the DOM rather than direct inventory transfer:** because the existing DOM machinery already handles per-hub escrow, currency settlement, price discovery, and matching. Reusing it means NPC orders are indistinguishable from player orders to the matching engine — same code paths, no special-cased NPC logic. The buy is just a market order with `playerId = NPC_<hubId>`.

---

## 3. AI Transport Ships

The NPC transport itself is a **server-spawned ship** with these properties:

- **Hull class:** scaled to cargo volume. Small orders → Light Hauler; medium → Heavy Freighter; large alliance-grade orders → Bulk Hauler. The system picks the appropriate hull at dispatch.
- **PD loadout:** scaled by route risk. Hubs in FED/ICE core space dispatch unarmed haulers. Routes through contested or fringe space dispatch escorted convoys (Light Hauler + 1-2 escort Frigates). Routes through known piracy zones may dispatch Armed Haulers with Iron Dome coverage. Admin tunable per route.
- **Cargo:** the goods purchased via the DOM at source hub. The cargo sits in the transport's hold during transit and is **lootable on destruction**.
- **Behavior:** travels the straight-line route between source and destination at hull-class speed. Does not deviate. Fires PD on incoming threats. Will not engage in offensive combat — the AI transport's job is to survive, not to fight back.
- **Vulnerability:** can be destroyed by player pirates. On destruction, cargo drops as a recoverable wreck (looted same way as player ship loot).

**On successful arrival:** transport reaches destination hub, cargo unloads into the hub's `currentStock` for that commodity. Transport despawns.

**On destruction / loss:** transport ship lost. Cargo wreck remains briefly for player salvage. The destination hub's `currentStock` is *not* replenished. At the next Weekly Economy Tick, the hub's threshold check will trigger another restock attempt — this time spending more on PD escort if the route has accumulated recent losses (the system learns).

### Schema

```
AITransport  (server-side runtime state)
  transportId       : string
  sourceHubId       : string
  destinationHubId  : string
  hullClass         : enum { LightHauler, HeavyFreighter, ArmedHauler, BulkHauler }
  escortCount       : int
  cargoManifest     : CargoManifest
  cargoValue        : long      // for loot/insurance accounting
  position          : Vector3   // current location, ticked per simulation tick
  etaUtc            : long
  status            : enum { Dispatched, InTransit, Arrived, Destroyed }
```

---

## 4. Stock Flow Mechanics

How goods actually flow through the system across all hubs:

**The cheap-source / expensive-destination logic emerges naturally:**

A gas-planet hub has admin-set high `targetStock` and low `floorPrice` for gases — it expects to hold a lot and sell cheap. Player miners with gas cargo find this hub a poor seller (low price) and prefer to sell at distant hubs (high price). Result: gas accumulates at the gas-planet hub.

An inner-system hub has low `targetStock` and high `ceilingPrice` for gases — it doesn't expect to hold much, and what it does hold is expensive. Player consumers buy cheap from the source hub or pay premium here. Result: gas chronically below threshold at the inner-system hub.

The auto-arbitrage system detects the inner-system hub's shortage and sources from the gas-planet hub. AI transports flow gas inward; gas-planet hub's stock decreases; gas-planet hub's `currentStock` may eventually need replenishing too (from mining — see below).

**Where does new supply come from at the source end?**

Two paths:

1. **Player mining.** Player miners sell raw materials at the cheap-source hub for the local floor price. This refills `currentStock` at the gas-planet hub as the AI drains it. Players who mine at the source hub provide the upstream supply that powers the auto-arbitrage flow.

2. **Admin-simulated production at "production hubs."** Some hubs are designated **production hubs** with effectively infinite supply at the floor price — typically lore-justified as "the gas planet itself is the supply." Admin sets these hubs' `currentStock` to auto-refill from a virtual source equal to the floor's invisible-hand. This is the canonical bootstrap for early-game economies before player mining can sustain demand.

In practice, both happen. Production hubs guarantee the system never seizes; player mining displaces NPC production as the economy matures. Admin can tune the balance per commodity (gas might stay NPC-produced even endgame because the lore says "gas planets are inexhaustible"; rare metals shift entirely to player mining as the player base grows).

**Selling at NPC asks:**

The destination hub holds inventory it bought via auto-arbitrage. That inventory is **available for player buyers** at the local ceiling price (or whatever price market dynamics push it to). When a player buys a gas at the inner-system hub, they're buying from NPC stock that arrived via AI transport. The hub's `currentStock` decreases; if it drops below `replenishThreshold` again, the cycle repeats.

This means the player buyer at the destination hub is effectively *paying for the arbitrage opportunity that the AI just performed*. The spread between source floor and destination ceiling is the AI's "profit" — but the AI doesn't keep it; the spread is **burned** as a currency sink (the AI bought low and sells high; the difference disappears, contributing to deflationary pressure that balances new currency mintings).

---

## 4.5 NPC Miners — the supply side of the NPC economy

Auto-arbitrage moves goods *between* hubs. But goods have to enter the system somewhere — and "production hubs with admin-simulated infinite supply" is the cheap fallback. The richer answer is **NPC miners**: faction-employed (or alliance-employed) AI mining ships that physically extract raw materials from belts and gas clouds, then haul their cargo to nearby hubs to sell into NPC stock.

NPC miners are the **upstream of the auto-arbitrage system** — they replace the lore-handwave "hub has infinite gas because lore" with "five FED mining contractors are working the local belt around the clock, each cycling 8 hours." More realistic, more attackable, more interactive.

### Mechanics

```
NPCMiner  (server-side runtime state)
  minerId            : string
  factionId          : string         // FED / ICE / alliance owner
  spawnSectorId      : string
  miningSite         : Vector3        // specific position within the sector
  destinationHubId   : string         // where they sell their cargo
  hullClass          : enum { LightMiner, MediumMiner, HeavyMiner }
  cargoCapacityKg    : float
  currentCargoKg     : float
  miningRateUnitsPerTick : float
  escortCount        : int            // 0 in core space; 1-2 in contested; full convoy in hostile
  state              : enum { Spawning, Mining, Returning, Selling, Despawning }
  cycleStartedUtc    : long
```

**Lifecycle:**

1. **Spawn.** Admin configures per (sectorId, commodityId) how many concurrent NPC miners a site supports. At the Weekly Economy Tick (or faster — a per-day cycle works better for mining), under-saturated sites spawn new miners. Spawning happens at the site itself; the miner appears flying toward the asteroid / gas cloud.
2. **Mine.** The miner runs its mining laser / extraction beam on the local commodity for a configured duration (typically 4-12 in-game hours). Cargo accumulates at `miningRateUnitsPerTick`. The miner is **vulnerable during this phase** — stationary, attached to the resource, easy target for pirates.
3. **Return.** When cargo reaches capacity (or a max-time cap is hit), the miner disengages from the site and flies to its `destinationHubId`. The route is straight-line, same as NPC transports. Vulnerable during transit too.
4. **Sell.** At the hub, the miner posts its cargo as a sell order on the local DOM at the hub's current ask price (or the floor, whichever is higher). The order fills against any player buy orders + the invisible-hand floor, replenishing the hub's `currentStock`.
5. **Despawn (or re-cycle).** Per admin config, the miner either despawns at the hub (returning the slot for a fresh spawn at the site next tick) OR flies back to the site to mine another load. Re-cycling is cheaper to run; despawn-and-respawn is more flexible for tuning.

### NPC miner owners

Three owner types, same NPC-miner mechanic:

- **FED mining contractors.** NPC ships selling to FED hubs at the local floor price.
- **ICE military extraction crews.** Armed mining ships (Tungsten for railguns, Uranium for warheads) with escort patrols built in.
- **Alliance mining ops.** Alliance-owned hubs deploy NPC miners on alliance-controlled belts; alliance treasury collects the difference between mining cost and hub sale price.

In-universe framing (non-canon) → [`../lore/lore_world_framing.md`](../lore/lore_world_framing.md#npc-arbitrage-miners--why-theyre-there).

### Coexistence with player miners

NPC miners compete with players for the same belts. Three competitive dynamics:

1. **Price competition at the hub.** NPC miners sell at hub-floor price; player miners selling at the same hub also get hub-floor price. When NPC saturation is high, hub stock fills up and floor drops (or players have to sell elsewhere). When NPC miners are getting destroyed by pirates and supply is thin, prices rise — player miners get better rates.
2. **Site competition.** A belt has limited extraction capacity per tick. NPC miners take a share; player miners compete for the remainder. Larger belts support more concurrent miners.
3. **Attackability.** Player miners can attack NPC miners. **There are consequences:** attacking a FED mining contractor in FED space triggers patrol response; attacking an alliance NPC miner in alliance space triggers alliance patrol response; attacking an Outlaw-fringe NPC miner is usually safe. Looted cargo carries no `stolenFrom` tag (NPCs aren't "real players" for provenance purposes) but FED/ICE may still treat the *miner* as a victim and flag the attacker.

### Permit interaction

In alliance-controlled territory, NPC miners face the same permit rules as players. Three configurations admins can pick:

- **Alliance-deployed NPC miners** — alliance-owned, permit-exempt (the alliance owns them).
- **Faction-licensed NPC miners with permit** — alliance has issued the faction a permit; FED/ICE miners can work the belt without patrol intervention.
- **Faction-licensed NPC miners without permit** — alliance hasn't licensed the faction; if FED spawns miners there anyway, alliance patrols treat them as poachers same as player non-permit miners. Lore: tense diplomatic friction.

This means alliances can **selectively cut off the NPC supply chain** in their territory by denying faction permits — forcing the upstream supply to flow only through alliance-deployed or player miners. Strategic lever for alliance economic warfare.

### Schema integration

NPC miners feed the same `currentStock` field that the auto-arbitrage system reads. From the destination hub's perspective, an NPC miner selling its cargo is indistinguishable from an AI transport delivering cargo — both increment `currentStock`. The hub doesn't care where supply came from; it just cares about its stock level relative to threshold.

This means the **NPC miner → NPC transport → distant hub** chain is one coherent flow:
- NPC miner at gas planet belt extracts gas → sells to gas-planet hub → gas-planet hub stock fills
- Inner-system hub drops below gas threshold → auto-arbitrage triggers → AI transport dispatches to gas-planet hub
- AI transport buys from gas-planet hub stock (which the miner filled) → flies to inner-system hub → unloads

Two NPC steps, one player intervention point at each (mining, transport), one pirate intervention point at each. The whole chain runs autonomously if no players interact; players can plug in at any step to mine, haul, attack, or trade.

### Recurring prey, layer 2

NPC miners are **a second tier of recurring pirate prey** distinct from NPC transports:

| Target | Where | Cargo | PD profile |
|---|---|---|---|
| **NPC miner (stationary, mining phase)** | At the belt itself | Whatever they're mining, partial-cycle | Usually unescorted in core space; escorts in contested |
| **NPC miner (returning, transit phase)** | Route from belt to hub | Full load of raws | Same |
| **NPC transport (transit)** | Hub-to-hub route | Bulk commodity from auto-arbitrage | Variable — admin-tuned by route risk |

Pirates choose: hit miners (easier target, smaller cargo) or transports (harder target, bigger cargo). Each has different escort doctrine and different ambush tactics. **Mining sites become canonical low-tier piracy hunting grounds** — pirates who can't yet take on escorted transport convoys can still earn at mining ambushes.

### Admin tuning

- `(sectorId, commodityId) → maxConcurrentMiners` — how many NPC miners a site supports
- `(sectorId, commodityId) → spawnFrequency` — how fast destroyed miners replace
- `(commodityId) → npcMiningRate` — extraction speed per miner (higher = faster supply; lower = more dependence on player miners)
- `(routeId) → npcMinerEscortCount` — PD scaling for returning miners on this route
- Per-hub: `hubId → preferredNpcDestinations` — which NPC miners prefer to sell at this hub vs. alternatives

Single-dial-per-knob, same pattern as the rest of the NPC economy.

---

## 5. Piracy Integration — the recurring prey loop

AI transports are **the canonical recurring pirate target**. The design is:

- Routes are predictable (source-to-destination, straight line, on a schedule).
- Visibility is partial — players don't see the AI's *internal* schedule, but they can infer from public stock levels (a hub depleting below threshold means a transport is incoming within ~1 week).
- **Supply-Chain Tap (T3 hacking) reads AI transport manifests** — same data source as alliance shipment manifests, with `posterPlayerId = NPC_<hubId>` and `haulerPlayerId = AI_TRANSPORT`. Pirates with Tap intel can intercept AI transports precisely the same way they intercept player convoys.
- Loss of an AI transport is **not a system catastrophe** — the destination hub just dispatches another at the next tick, possibly with stronger PD escort if the system tracks repeated losses on the route. The supply chain self-heals, but each loss is a one-off pirate windfall.

**Why this is load-bearing for pirate gameplay:**

Without recurring NPC prey, the only attackable targets are player Transporters, which puts the pirate economy fully dependent on player activity in target zones. With NPC transports as a baseline prey source, **pirates have a guaranteed income floor** that doesn't require players to be on those routes. This makes piracy viable as a primary livelihood, not just opportunistic raiding.

The cargo from a destroyed AI transport drops as **standard wreckage** — player loot follows normal salvage rules (Salvage Beam, scrap metal yield, intact items recoverable). Pirates fence the loot at black markets (no faction tax + accepts stolen-tagged goods).

---

## 6. Coexistence with Player Transporters

The AI system handles **routine commodity flow** — predictable bulk hauls of raw materials and Tier 2 refined goods between known hubs. Player Transporters retain four distinct niches the AI doesn't serve:

| Cargo type | AI auto-arbitrage | Player Transporters |
|---|---|---|
| Raw commodities (Iron, Gas, Silicates) | ✓ Primary | Optional / arbitrage edge cases |
| Tier 2 refined goods (Steel, Synthetic Polymer) | ✓ Primary | Same |
| Tier 3 components (Hyper-Lattice, Stealth Coating) | Partial — only between FED/ICE hubs | ✓ Primary, especially to alliance hubs |
| Tier 4 exotic / capital components | ✗ Never | ✓ Exclusive |
| Bespoke / Forged items | ✗ Never | ✓ Exclusive (per [`./economy_freight_contracts.md`](./economy_freight_contracts.md)) |
| Contraband / restricted ordnance | ✗ Never (FED/ICE-affiliated AI won't carry illegal cargo) | ✓ Exclusive (smuggler livelihood) |
| Stolen goods (`stolenFrom` tag) | ✗ Never | ✓ Black-market routes |
| Time-critical / rush deliveries | ✗ AI operates on weekly tick | ✓ Player contracts with tight deadlines |
| Player-to-player named-recipient | ✗ Never | ✓ Direct contracts |

**The AI competes with players only on routine commodity bulk hauls.** Everywhere else, player Transporters have an exclusive niche. And even on routine hauls, players can compete by **undercutting the AI's effective rate** — a player who's willing to haul gas from gas-planet to inner-system for less than the AI's emergent spread (because they have a faster ship, or they're already going that way) wins business from posted contracts that route around the AI.

---

## 7. Tuning Levers (admin)

The auto-arbitrage system exposes several admin knobs per hub or per route:

- `HubStockLevel.targetStock` / `replenishThreshold` / `replenishOrderSize` per (hubId, itemId)
- `HubStockLevel.maxStock` — prevents over-buying
- Route-level PD scaling: which routes deserve escorted AI convoys vs. unarmed haulers (affects AI survivability vs. pirate income)
- Production hub designation: which hubs auto-refill at floor price as if mining was bottomless
- Admin override: pause / resume / force-trigger restock for a given hub-commodity pair

If a route is too lucrative for pirates (haulers destroyed too often, supply not getting through), admin increases PD escort scaling. If pirates aren't getting enough prey, admin reduces escort. If a hub is over-stocking on a commodity nobody wants, admin lowers `targetStock`. Single-dial-per-knob tuning.

---

## 8. Why This Design

- **NPC seed liquidity is solved as a side effect.** Day-1 hubs with zero inventory are below threshold immediately; the system begins sourcing on the first Weekly Economy Tick. No special bootstrap logic needed.
- **Regional pricing becomes self-enforcing.** Admin sets the band; the AI flow naturally moves goods to maintain the spread. Player arbitrage layers on top but doesn't need to do all the work.
- **Pirates get a recurring income source.** AI transports are predictable, lootable, and self-replacing. Piracy becomes viable as a livelihood, not just opportunistic.
- **Player Transporters retain exclusive niches.** AI never takes the high-value, contraband, time-critical, or bespoke work. Player Transporters have plenty to do; the AI just handles the boring bulk flow.
- **The currency sink emerges naturally.** The spread between source floor and destination ceiling — what would be the AI's "profit" if it were a player — disappears into the burn pool, providing steady deflationary pressure that balances new currency entering the economy.
- **Markets never fully seize.** Even in low-population periods or contested zones where players aren't trading, the AI keeps goods flowing at a reduced volume. The economy has a heartbeat regardless of human activity.

---

## 9. Locked Design Decisions

The original open-questions list resolved as follows:

### 9.1 Cross-faction sourcing — NO

**FED hubs never source from ICE hubs. ICE hubs never source from FED hubs.** The auto-arbitrage source-scan filters strictly by faction alignment — implemented as a **territory-bubble check** (see [`../world/world_territory_bubbles.md`](../world/world_territory_bubbles.md)): a candidate source hub is only eligible if it falls within the requesting faction's territory bubbles. FED and ICE anchor bubbles are non-overlapping by design, so cross-faction sourcing fails the territory check geometrically.

**Strategic implication:** if a FED hub runs critically low on a commodity that's only abundant in ICE space, the NPC system **cannot** restore supply. The shortage persists at the FED hub until either (a) a FED-affiliated source begins producing it, (b) the admin manually intervenes, or (c) **player smugglers haul the commodity across the faction line** for the now-extreme price differential.

This is **deliberate economic warfare leverage**. ICE has commodity X in abundance, FED can't reach it through legitimate channels, the gap widens until it's worth a smuggler's risk to run a cross-faction freight contract. The cross-faction trade route becomes a player-driven smuggling layer that the NPC system explicitly *cannot* compete with.

Alliances inherit this restriction by their own faction alignment:
- FED-aligned alliance hubs source from FED NPC supply only.
- ICE-aligned alliance hubs source from ICE only.
- **Neutral / Outlaw-aligned alliances** opt out of faction-side NPC sourcing entirely; they're on their own (player Transporters, alliance mining ops, or accepting persistent shortage).

### 9.2 Alliance-hub participation — opt-in

Alliance-owned hubs are **opt-in** to the auto-arbitrage system, per commodity. New per-hub config field:

```
allianceHub.npcArbitrageOptIn : Dictionary<commodityId, bool>
```

Defaults to `false` for every commodity. Alliance leadership explicitly enables auto-arbitrage on the commodities they want stable NPC supply for.

**Tradeoffs the alliance faces:**

- *Opt-in for commodity X* → stable NPC supply at the hub, AI transports auto-deliver when stock drops below threshold. But: hub stock levels become **publicly readable** (the same as faction hubs), exposing the alliance's logistical state to competitors and hackers. Also accepts NPC transport traffic at the hub (more lootable targets for pirates near alliance space).
- *Opt-out for commodity X* → alliance retains full information control; no NPC traffic. But: the alliance is fully responsible for supplying that commodity through alliance mining ops, member effort, or player Transporter contracts.

Most alliances opt-in selectively — bulk commodities yes (stable supply matters more than secrecy), strategic commodities no (Tier 4 components, refined alloys for capital hulls — supply through controlled channels only).

### 9.3 Adaptive PD escalation — auto-learn from losses

The system **auto-tunes escort strength per route** based on observed losses. This replaces the "admin manually tunes every route" model with a learning feedback loop.

**Mechanism:**

```
routePDState  (per (sourceHubId, destinationHubId))
  baselineEscortCount       : int      // admin-set floor
  currentEscortCount        : int      // dynamic, what the system actually dispatches
  lossesInWindow            : int      // count over rolling 30-day window
  lossesThreshold           : int      // admin-tunable, default 3
  escalationStep            : int      // how much to add per threshold breach, default 1
  deescalationCooldown      : long     // time in low-loss state before de-escalating
```

**Behavior:**

- At every Weekly Economy Tick, the system reviews each route's losses over the last 30 days.
- If `lossesInWindow >= lossesThreshold`: `currentEscortCount += escalationStep`, up to an admin-configured ceiling.
- If `lossesInWindow == 0` and `deescalationCooldown` has elapsed since the last escalation: `currentEscortCount -= 1`, down to `baselineEscortCount`.
- Escort scaling affects both AI transports AND returning NPC miners on that route.

**Pirate-side implications:**

- Pirates who farm a route too aggressively will see escorts scale up — eventually past the point of profitable raiding.
- Pirates who **moderate their hunting** keep escort levels low and maintain a sustainable raiding pace. This is intentional emergent gameplay: the smart pirate doesn't kill every transport, they thin the herd.
- Admin tuning still applies — admin can hard-cap escalation, force-reset levels, or override per-route. Auto-learning sits *on top of* admin-set baselines.

**Lore framing** (non-canon) → [`../lore/lore_world_framing.md`](../lore/lore_world_framing.md#npc-arbitrage--escort-auto-scaling).

### 9.4 Mining Outpost integration — no direct AI ↔ outpost link

**The NPC auto-arbitrage system never buys directly from a Mining Outpost.** Outposts are not trading hubs and they're not DOM-addressable. Goods flow through trading hubs only.

The outpost-to-AI pipeline works in two distinct steps:

1. **Outpost output → trading hub:** the outpost's owner (alliance or player) is responsible for physically hauling extracted / refined goods from the outpost to a trading hub. This is normal player Transporter work — a freight contract, an alliance supply run, or the owner hauling personally.
2. **Trading hub → AI fill:** once the goods are listed on the hub's DOM as sell orders, the auto-arbitrage system can match those listings the same way it matches any other player ask. The NPC market-buy doesn't know or care that the listed goods originated at an outpost.

In short: **outposts produce, players haul, hubs distribute.** This preserves the canonical rule that *all trading goes through trading posts* and means outposts integrate cleanly into the system without any special outpost-to-AI plumbing.

A side benefit: outposts in remote locations (alliance space, fringe regions) require their owners to actually run the haul. There's no "set up an outpost and let NPCs come buy from it" autopilot — the outpost is a production asset, not a market endpoint.

---

## 10. Still-Open Design Questions

5. **Visibility of AI schedule.** Currently the design has public hub stock levels (visible at any Bank Terminal) and hidden internal restock schedules. But because stock dropping below `replenishThreshold` deterministically triggers a restock, a player watching public stock data can effectively predict AI transports without hacking — which arguably makes Supply-Chain Tap intel on AI traffic less valuable.

   Options worth considering:
   - **Keep current design.** Public stock = inferable schedules. Treats it as a feature: low-tier pirates target NPC traffic by watching stock, high-tier pirates target player traffic via hacking. Tiered prey, tiered intel cost.
   - **Hide stock levels too.** Stock becomes T2-hacking-readable. Public board shows only "available / low / out" coarse states. Restores Supply-Chain Tap as the primary AI-traffic-prediction tool.
   - **Hybrid: hide thresholds but show stock.** Players see stock numbers but don't know the trigger thresholds, so they have to *guess* when a restock will fire. Approximate prediction without certainty.

   Defer to playtest data — pick the option that produces the right pirate-vs-trader balance once player behavior reveals which way the system tilts.
