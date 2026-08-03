# Exchange & Pricing — Universal DOM Market

This document is the canonical pricing mechanism for **every market in Apex Outlaw**. Currency exchange, commodity trading, module sales, even alliance armory bulk buys — all of them use the same underlying system: a **Level-2 Depth-of-Market order book** with Bid / Ask sides, three order types, a matching engine, and a **hidden admin-controlled price floor/ceiling** that acts as the invisible market-maker.

The single-system design is deliberate. A player who learns how to trade FED credits for Gold uses the exact same UI, order types, and mechanics to trade Iron Ore for credits or to flip a Forged Railgun on the resale market. One system, one mental model, infinite markets.

---

## 1. What the player sees — the Order Book (Level-2 DOM)

Every market is a **two-sided order book**, just like real commodity / forex / stock exchanges:

```
            BID (buyers)        |        ASK (sellers)
            ─────────────       |        ─────────────
            qty   price         |        price   qty
            ─────────────       |        ─────────────
            5,000  482           |        489  3,200
            2,400  481           |        490  1,800
              800  478           |        492    700
                                ...
            Last Trade: 485 FED / Gold       Spread: 7
```

**Bid side** = outstanding buy orders, sorted highest-price-first (the best price a buyer is willing to pay sits at the top).
**Ask side** = outstanding sell orders, sorted lowest-price-first (the best price a seller is willing to accept sits at the top).
**Spread** = lowest Ask − highest Bid. Tight spreads mean a liquid market; wide spreads mean illiquid.
**Last Trade** = price of the most recent executed trade. Drives the chart / ticker display.

Each row aggregates volume at that price level — multiple players sitting at price 482 with various quantities are summed into the single visible row.

This is identical in shape to a Level-2 quote from a commodity broker. Players who've traded real markets recognize it instantly; players who haven't can learn it once and apply it across every market in the game.

---

## 2. Order types

Three order types cover the vast majority of trading strategies. They're the canonical commodity-market triad.

### Market Order
**"Buy / sell at whatever price is best, right now."**
- Executes immediately against the best available counter-orders.
- Walks the opposite side of the book, consuming volume at each price level until the order is filled.
- **Risk:** in a thin market, a large market order can "walk the book" and execute at progressively worse prices (slippage). Bad for big trades; fine for small ones.
- **Use case:** "I need 100 Steel right now, don't care about exact price."

### Limit Order
**"Buy / sell at this exact price or better — wait if you have to."**
- Player specifies price + quantity.
- Order goes into the book at the specified price; sits there until either filled by a counter-order or cancelled by the player.
- A buy limit at 480 will only fill if/when the Ask side drops to 480; a sell limit at 490 will only fill if/when the Bid side rises to 490.
- **Risk:** never fills if the market doesn't reach your price.
- **Use case:** "Buy 1000 Iron Ore but only if it drops to 50 FED / unit."

### Stop Order
**"Watch the price — when it crosses X, convert to a market order."**
- Triggered by the last-trade price reaching the stop level.
- On trigger, converts to a market order and executes immediately at whatever price is currently available (with full slippage risk).
- **Two flavors:**
  - **Stop-loss** (for sells): trigger when price *drops to* the stop. "If Steel falls to 60, sell my position before it falls further."
  - **Stop-buy** (breakouts): trigger when price *rises to* the stop. "If Stealth Coating rises to 5,000, buy before it spikes further."
- **Use case:** unattended risk management. A miner heading into a dangerous belt can place a stop-loss on their cargo so it auto-sells if prices crash during the mining run.

### What we deliberately don't include (yet)
- **Stop-Limit** (stop trigger → limit order at specified price) — useful for slippage control but adds UI complexity. Defer until player feedback shows demand.
- **Trailing Stop** (stop level moves with the market) — same reasoning.
- **Iceberg / Hidden orders** — show only partial volume in the book. Defer until market manipulation becomes a real problem.
- **Conditional / OCO** (one-cancels-other) — defer.

---

## 3. The Matching Engine

When a new order arrives, the server runs **price-time priority** matching:

1. **Price priority** — best price wins. A buy order at 485 fills before a buy order at 484. A sell at 488 fills before a sell at 489.
2. **Time priority** — at the same price, oldest order fills first. First-come-first-served within a price level.

**Matching flow:**
- **Market buy** → walks the Ask side, taking lowest-price asks until quantity is filled.
- **Market sell** → walks the Bid side, taking highest-price bids until quantity is filled.
- **Limit buy at P** → check if any Ask at or below P exists; if yes, fill against it (taker pays the Ask price, not P); if no remaining quantity, the rest goes into the book at P on the Bid side.
- **Limit sell at P** → mirror image: fill against Bids at or above P; rest sits on the Ask side at P.
- **Stop order** → held off-book until triggered; when triggered, becomes a market order and matches as above.

**Partial fills** are first-class — a 1000-unit market buy might fill 600 at 489 and 400 at 490 if the book only has 600 at 489.

Every fill emits a `Trade` event with `(buyerId, sellerId, qty, price, timestamp)` for the chart, the trade history log, and for tax accounting (the 3% Escrow + 35% FED tax / ICE tariff still apply on top — see [`./economy_trade.md`](./economy_trade.md)).

---

## 3.5 Price Bands on Liquid Markets

For markets with established price history, the engine rejects orders that fall **too far outside the recent clear-price range**. This is the standard "price banding" rule used by real commodity / stock exchanges (NYSE Limit Up-Limit Down, CME price banding) — it prevents wild-distortion listings that would never legitimately clear and which players otherwise use to abuse the trading post as free storage.

The band complements the [Restocking Fee on Unsold Withdrawal](#restocking-fee-on-unsold-withdrawal-anti-storage-abuse) — the restocking fee makes parking *unprofitable*; the price band makes the most absurd parking attempts *impossible*. Together they close the storage-abuse loophole at both ends.

### When the band applies

- **Liquid markets only.** A market is liquid once it has accumulated meaningful trade history — default threshold: **at least 5 trades in the past 7 days**. Below threshold, the market is in "price discovery" mode and orders are unrestricted.
- **Fungible markets only.** Bespoke listings have no band — uniqueness justifies free pricing (a famous-maker premium might legitimately be 10× fungible value). The restocking fee remains the sole friction on bespoke parking.

### How the band is computed

For each liquid market, the engine maintains a **reference price** — a rolling clear-price average across recent fills. Default formula: volume-weighted average price across the **last 100 fills OR the last 7 days, whichever covers more trades**.

An admin-tunable band percentage (`market.priceBandPercent`, default **50%**) defines the legal range around the reference:

```
minLegal = referencePrice * (1 - priceBandPercent)
maxLegal = referencePrice * (1 + priceBandPercent)
```

So a market with reference price 500 FED and 50% band accepts orders between 250 and 750. Orders outside this range are **rejected at submission time** with an error envelope:

```
{ ok: false, err: "OUTSIDE_PRICE_BAND",
  referencePrice: 500, minLegal: 250, maxLegal: 750 }
```

The client UI surfaces the allowed range alongside the price input so players see the constraint before they hit submit:

```
List Iron Ore at: [   ___ ] FED
  Market reference: 500   Allowed band: 250 – 750
```

### Per-market admin overrides

The default 50% band is a global. Admin can override per market in PlayFab title internal data:

- **Currencies** typically run tight bands (±10–15%) — currency stability is a design goal.
- **Common commodities** run the default ±50% — wide enough for legitimate market shifts.
- **Exotic / Tier 4 modules** may run wider (±100%) — rare-item prices legitimately swing harder.

### What the band doesn't do

- **Doesn't replace the restocking fee.** Both apply — band-compliant listings that still go unsold still incur the withdrawal fee.
- **Doesn't affect the invisible hand.** The hidden floor/ceiling (see §4) operates *outside* the visible price-band system — when the hand intervenes, it's matching against player orders that already passed the band check. The band and the hand are independent layers.
- **Doesn't apply to bespoke listings.** Forged-provenance premium pricing requires free pricing latitude; bespoke listings remain unrestricted.

### Why this design

- **Storage abuse via absurd pricing is impossible**, not just unprofitable. A player can't list 100 Iron Ore at 999,999,999 FED to park them — the engine rejects the listing outright.
- **Market signals stay clean.** Visible book volume reflects real intent to trade, not parking. Spreads stay meaningful as a liquidity indicator instead of being inflated by junk listings at the extremes.
- **New / illiquid markets stay free** during price discovery. The band only kicks in once the market has enough trade history to establish a reference. This avoids the chicken-and-egg problem of "can't list because there's no reference price."
- **Single admin dial per market.** If a market is getting gamed, tighten the band. If a market is being too restrictive, loosen it. One value, immediate effect.

---

## 4. The Invisible Hand (Hidden Admin Floor/Ceiling)

This is the canonical "the game makes the market" mechanism. It is **invisible to players by design** — they will never see a Federation Treasury order in the book, never see an admin price-band announcement, never see a tooltip indicating "this trade was matched against the invisible hand". The mechanic exists to:

1. **Provide a liquidity floor** — in markets with no player counter-parties, the invisible hand still trades, so the economy never seizes.
2. **Cap inflation / deflation** — keep currencies and commodities in designer-acceptable bands so the game stays balanced.
3. **Absorb shock** — sudden dumps (alliance collapse, market crash) or sudden squeezes (cartel manipulation) are dampened by the hand stepping in.

### Mechanism

For every market, admin sets two values in PlayFab title internal data:

```
market.<marketId>.floorPrice    // hand will buy unlimited at this price
market.<marketId>.ceilingPrice  // hand will sell unlimited at this price
```

The matching engine treats these as **phantom counter-parties**:

- If a player submits a **sell** order at or below `floorPrice`, and no player Bids exist at that level, the engine matches against the phantom buyer at `floorPrice`. The hand absorbs the seller's inventory; FED credits are minted from thin air and paid to the player.
- If a player submits a **buy** order at or above `ceilingPrice`, and no player Asks exist at that level, the engine matches against the phantom seller at `ceilingPrice`. The hand delivers the goods (also minted from thin air, or drawn from a virtual treasury); FED credits are paid to the hand and effectively burned.

The phantom orders **never appear in the visible book**. From the player's perspective:
> "My limit sell at 450 filled but the book showed no Bids below 478. Weird. Must have been a whale order that came in and out fast."

This is the load-bearing illusion. **Players must not be able to tell when they've traded against the hand**, because the moment they can, they game the floor (front-run it, exploit it, force the hand to defend against deliberate attacks).

### What the hand is, lore-wise

In-universe framing (non-canon) → [`../lore/lore_world_framing.md`](../lore/lore_world_framing.md#the-invisible-hand-floor--what-it-is-lore-wise). Mechanically: the hand is the game balancing itself, not a visible faction; players must not be able to tell when they've traded against it.

### Admin control

The floor/ceiling values live in PlayFab title internal data, write-restricted to admin-tag accounts (the same admin pattern as [`celestial_admin.js`](../../cloudscript/celestial_admin.js)). Admins adjust them by hand or via scheduled jobs — there is no player-visible mechanism. A future-design idea: data-driven adjustment based on rolling supply/inflation metrics. For now, manual.

### When admins should and shouldn't intervene

- **Should:** new markets with no player liquidity yet; runaway inflation in a currency; cartel-driven price manipulation; designed price bands for restricted goods (e.g. Uranium has a hard ceiling because the design intent is "this is expensive and rare, not free with a glitched recipe").
- **Should not:** routine trading; punishing players for finding legitimate arbitrage; reacting to single events (let the band absorb the shock, don't move the band in response).

---

## 5. Per-Market Structure

Every traded thing has its own DOM. The matching engine is the same; the market IDs are what scope them.

**Currency markets (the original ask):**
- `market.gold_to_pact` — Gold Ingots ↔ FED credits
- `market.gold_to_ice` — Gold Ingots ↔ ICE credits
- `market.pact_to_ice` — FED credits ↔ ICE credits (could be derived from the gold pairs, OR have its own book; current design preference is **own book** so players can arb the triangle, which adds gameplay depth)

**Commodity markets** (one per raw / refined material, one per region / hub):
- `market.iron_ore.pact_hub_concordia` — Iron Ore priced in FED credits at the Concordia hub
- `market.iron_ore.ice_hub_ferrum` — Iron Ore priced in ICE credits at the Ferrum hub
- **Regional price differences are intentional and admin-curated** — see the "Regional Pricing Doctrine" subsection below.

**Module markets** (per item, per grade, per hub) — this is where player-forged modules and ships get resold:
- `market.power_core_fusion_01.A.pact_hub_concordia` — Grade-A Fusion Reactors at the Concordia hub
- `market.power_core_fusion_01.B.pact_hub_concordia` — Grade-B Fusion Reactors at the same hub (different market entirely)
- `market.power_core_fusion_01.A.ice_hub_ferrum` — Grade-A Fusion Reactors at the Ferrum hub (regional price differences vs. Concordia → arb gameplay)

**Every distinct (itemID, grade, hub) tuple is its own market** — and within each, units are fungible. A seller listing a Grade-A Fusion Reactor doesn't list "their" specific instance; they list one unit at the Grade-A market, and the buyer receives an equivalent unit from the pool. Same mechanics as commodity wheat: "Grade-1 wheat" is fungible regardless of which farmer grew it. The grade IS the spec.

The market ID scheme is `market.<asset>[.<grade>].<location_or_pair>` — grade segment present only when the asset is graded (modules, ships, refined goods). Raw materials and currencies skip it.

### Regional Pricing Doctrine — proximity drives price

**Prices are deliberately different from one trading post to another.** This is the canonical mechanism that makes Apex Outlaw's geography economically meaningful — and it's the entire reason the Transporter role exists as a profitable specialty. The mechanism: admins set the invisible-hand **floor/ceiling values per hub with regional logic**, so a commodity is cheap near its source and expensive far from it. Players' DOM trading then closes the gap, but transport cost, risk, and time mean the gap never fully closes — and that *persistent spread* is the arbitrage gameplay.

**Concrete pattern — proximity to source = cheaper floor/ceiling:**

| Commodity | Cheap at | Expensive at |
|---|---|---|
| Hydrogen / Methane / Xenon gases | Hubs orbiting gas planets (Helium-3 belts, deep-atmosphere gas giants) | Inner-system rocky-planet hubs |
| Iron / Copper / Nickel / Tungsten ores | Hubs adjacent to metal-rich asteroid belts | Refined-industry hubs far from belts |
| Water Ice / Volatiles | Ice-field-adjacent hubs (outer system, comet belts) | Inner-system hubs |
| Silicates | Hubs near silicate-rich regolith bodies | Hubs in metal-belt regions |
| Tier 2/3 refined goods | Refinery-hub regions | Frontier / industrial-consumption hubs |
| Tier 4 exotics, restricted ordnance | Outlaw-adjacent fringe hubs (illegal-trade routes) | FED/ICE core hubs (where they're contraband) |

The admin's job is to set floor/ceiling values that reflect this regional logic — **cheap floor + low ceiling at the source hub, higher floor + higher ceiling at the destination hubs**. Players who haul commodity between them earn the spread, minus transport cost, minus blockade risk, minus the time they could have been doing something else.

**Why the spread is *persistent*, not closed by arbitrage:**

In a perfectly frictionless market, arbitrage would close the gap instantly — buy cheap, sell expensive, repeat until prices equalize. In Apex Outlaw, three frictions keep the spread open:

1. **Transport cost** — fuel, ammunition, crate manufacturing, hauler maintenance. Real currency cost per haul.
2. **Transport risk** — Supply-Chain Tap hackers leak the convoy schedule; pirates ambush; cargo is lost. The expected value of arbitrage has to exceed the expected loss to piracy.
3. **Transport time** — every haul is hours of player attention and ship downtime. The hauler could have been doing something else.

These three frictions are not bugs — they're what make the Transporter role *meaningful*. A player who masters route selection, escort doctrine, blockade evasion, and timing earns the spread. A player who does it sloppily loses to the frictions. **The spread is the wage of skill.**

**Doctrinal implications:**

- **Set floor/ceiling values with regional intent at market creation.** Don't default-to-global — every hub should have hub-aware pricing for every commodity from day one.
- **Iterate band values as routes get exploited.** If a single arbitrage route gets too profitable, narrow the ceiling at the destination (reducing the spread). If a route is being ignored, widen the spread to incentivize it.
- **Mining Outpost placement interacts with this directly.** An alliance that deploys a Refining Outpost (see [`../ships/ships_class_index.md`](../ships/ships_class_index.md) "Mining Outpost") near a gas-cheap hub is essentially manufacturing the spread for themselves — buy gas cheap locally, refine on-site into volatiles, sell the refined goods at higher hubs. The Refining Outpost is a vertically-integrated arbitrage facility.
- **Outlaw fringe hubs benefit from being the cheap end of restricted-ordnance trade routes.** Tier 4 exotics manufactured Outlaw-side are cheap at the Outlaw fringe but expensive (and dangerous to hold) in core space. The transporter who runs that route is the canonical smuggler.

**One emergent consequence worth flagging:** because each hub's prices are partially admin-set via floor/ceiling, **alliances that control hubs control regional pricing** by controlling which admin (or admin-equivalent alliance governance role) tunes those values. If alliance governance ever gets the power to adjust local floor/ceilings on alliance-owned hubs, that becomes a *significant* alliance-political lever — alliances would compete for hub control partly to optimize their pricing for their own members. Defer the alliance-side hub-pricing power to a future canon decision; flagged here so it stays on the design radar.

### Player-instance listing mechanics

When a player lists a graded module instance on the DOM, several things happen server-side:

1. **Eligibility check** — the instance must be at **full durability** to list. Damaged modules can't go to DOM. They must be repaired at a shipyard first OR sold via direct player-to-player trade (which is a separate system out of scope for this doc). This avoids a "used market" UI that would balloon market complexity.
2. **Checksum + grade validation** — the seller's instance has its `IntegrityChecksum` validated against `(itemID, grade, sellerPlayFabId, sellerAlchemySeed, pepper)`. Tampered instances are rejected; legitimate ones are accepted into escrow.
3. **Atomization to escrow** — the seller's `PartInstance` is moved from their inventory to a server-side market escrow keyed by `(marketId, sellerId, listingId)`. From the player's perspective the instance disappears from their inventory the moment the order goes live.
4. **Order goes into the book** — same as any other Sell order. Bid/Ask, price-time priority, partial fills.
5. **On fill: re-stamping for the buyer** — when a buyer's order matches, the matching engine destroys the escrowed instance and **mints a fresh instance for the buyer** with `(itemID, grade, buyerPlayFabId, buyerAlchemySeed, pepper)` — i.e. a freshly-checksummed instance signed for the buyer's account. The buyer can't replay the seller's instance against their own profile, and the checksum chain stays clean.
6. **On cancel** — if the seller cancels an unfilled listing, the escrowed instance is **re-stamped back to the seller** (in case `alchemySeed` rotated mid-listing) and returned to inventory.

Buyers have the full set of order types available:
- **Market buy** at the Grade-A Fusion Reactor market → "give me one now at lowest Ask"
- **Limit buy** → "I'll pay 50,000 FED for a Grade-A Fusion Reactor, wait until someone lists one at that price or lower"
- **Stop buy** → "If Grade-A Fusion Reactors break above 80,000 FED, auto-buy one (anticipating further spike)"

This means a player who wants a specific grade can simply place a buy order and wait — they don't need to manually browse listings. The market routes the inventory to them.

### Bespoke listings — one-of-a-kind instances

Not every sale is a commodity sale. A player can choose to list a specific instance as **bespoke** — preserving its unique configuration, naming, paint, fitted modules, and combat history rather than atomizing it into a fungible pool. This is the canonical path for selling **individually designed ships** with custom builds, famous combat records, or unique cosmetic / loadout combinations.

The seller chooses at listing time:
- **Fungible listing** → standard market (`market.power_core_fusion_01.A.pact_hub_concordia`). Atomizes into the pool. Lower price ceiling but immediate liquidity from any matching Bid.
- **Bespoke listing** → unique market (`market.bespoke.<instanceId>.<hub>`). Single-seller, single-unit market. Higher possible price for a desirable build, lower liquidity (only buyers specifically looking for *that* instance fill it).

This creates a real seller-side decision: commoditize for liquidity, or sell as one-off for premium pricing. A famous Battleship with a known combat record sells for far more bespoke than its fungible equivalent — but it might also sit unsold for months.

**Bespoke listing mechanics (differs from fungible in four ways):**

1. **No atomization.** The actual `PartInstance` (or `ShipInstance` with its full `equippedParts` dict) is what's listed — not a pool unit. The escrowed package carries the original name, paint, custom hardpoint configuration, and combat history metadata.
2. **Single-unit market.** Each bespoke listing creates its own market keyed by `instanceId`. The Ask side has exactly one order; the Bid side works normally (multiple buyers can compete with limit / market / stop orders).
3. **Whole-ship transfers include fitted modules by default.** If a Ship is sold bespoke, the buyer receives the hull plus every currently-fitted module as a single package — the way buying a used car includes whatever's in it. The seller can choose to **strip first** (remove specific modules back to inventory before listing) if they don't want to part with everything.
4. **On fill, the original instance transfers with re-stamped checksum.** Unlike fungible (where the instance is destroyed and a new one minted), bespoke transfers preserve the *exact* instance — same instanceId, same custom name, same combat history — but the IntegrityChecksum is re-signed for the new owner's `(playFabId, alchemySeed)`. The buyer inherits the ship's identity.

**Display differences:**

A fungible market shows aggregate book volume — players don't see individual sellers. A bespoke listing shows the full configuration card: ship name, hull class, current grade, every fitted module by name and grade, optional combat-record summary ("23 confirmed kills, lost zero engagements"), optional paint job, optional seller's note. It's a *product page*, not a row in a book.

The DOM UI exposes bespoke listings via a separate "Bespoke" tab — fungible markets and bespoke markets live side-by-side in the same Bank Terminal panel but with different display affordances.

**Why this design:**

It lets player-forged identity matter. A Researcher who spends months hunting the right Alchemy peaks to build "the perfect Frigate" can sell that specific frigate as a recognized one-off, not just as anonymous Grade-A inventory. The Forged-vs-Store-Bought economic identity (see [`./economy_alchemy_research.md`](./economy_alchemy_research.md) §4 and [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §4) extends naturally into the resale market. A Forged module commoditized in the fungible market is just a Grade-A unit; the same Forged module listed bespoke can sell for 5× or 10× the fungible price if its provenance is desirable.

### Maker's Mark — the forger's signature

Every player-forged item carries a permanent **maker's mark** identifying the original forger. The mark is stamped on the instance at forge time and persists through every subsequent resale — like a swordsmith's signature on a blade. A ship forged by Velkov, sold to a pirate, captured, looted, and resold three more times is still "Velkov's Frigate" — the buyers can see it; the bespoke listing displays it; the reputation accrues to Velkov for the rest of the ship's lifetime.

**Schema:**

Two immutable fields are added to `PartInstance` at forge time:

```
forgerPlayFabId    : string   // the player who actually forged this instance
forgerDisplayName  : string   // snapshot of their display name at forge time
```

Once set at forge, neither field is mutable — not by the forger, not by subsequent owners, not by admins under normal operations. The fields **survive resale checksum re-stamping** because they're part of the instance identity, not the owner identity. The integrity checksum's pepper covers them so they can't be hand-edited in a saved JSON.

**Display behavior depends on listing mode:**

- **Fungible listings** — maker's mark is **invisible to buyers**. The whole point of fungibility is anonymous commoditization. The mark still exists on the instance and the buyer inherits it, but the DOM doesn't surface it at sale time. (A buyer who later opens the instance's detail panel sees "Forged by: Velkov" — but they didn't pay a premium for it because they bought commodity.)
- **Bespoke listings** — maker's mark is **prominently displayed** on the listing card, with a clickable link to the forger's **MakerProfile**. Buyers paying bespoke prices are explicitly paying for the maker's identity, so the mark is a primary selling point.

**Reputation — emergent from data, not awarded:**

A `MakerProfile` for any player aggregates statistics across every item they've ever forged:

- **Total volume** — count of forged items in circulation
- **Grade distribution** — what fraction of their output is at each grade (a maker known for Grade-A+ output reads differently from one with bulk D-grade volume)
- **Specialization** — what item types they forge most (a player known for reactors vs. one known for weapons)
- **Sale-price premium** — average bespoke sale price relative to the fungible-market average for the same `(itemId, grade)`. This is the load-bearing reputation metric: a maker whose Grade-A Reactors consistently sell bespoke at 5× fungible price has demonstrably better reputation than one whose bespoke listings clear at fungible parity.
- **Downstream combat record** — items forged by this maker, when fitted on ships that fought, win-loss / kill metrics. (Requires combat-record metadata on instances — flagged as a dependency.)

Reputation **is not awarded by admin**. No designer-curated "famous makers" list, no badge system, no manual rank. Reputation is computed from the data and rises (or falls) on its own. A maker becomes famous by *making things people pay premium for and that perform well in fights*. The market signal IS the reputation.

**MakerProfile UI:**

A page accessible from any forged item's detail panel (click the mark → open profile) AND from a top-level "Famous Makers" browsable directory in the Bank Terminal trading panel. Each profile shows:

- Maker's display name + portrait
- Total volume + grade distribution histogram
- Top specializations
- Current open bespoke listings (with one-click "browse all by this maker")
- Sample notable items (highest-grade pieces, items with strong combat records)
- A "follow" toggle that pings the player when this maker posts new bespoke listings

**Why this design:**

- **Researchers and forgers get a real reputational surface.** Today their value is the *items* they make; with maker's marks, the value extends to *who they are* as a builder. A long-running Researcher accumulates a recognizable name over years of play.
- **Maker reputation is a player-driven discovery surface.** New players looking for "the best gear" can browse by maker reputation rather than wading through anonymous fungible listings. Veterans get recognized for excellence.
- **Sale-price premium is a self-balancing metric.** If a maker's bespoke listings stop clearing at premium, their reputation metric falls — they have to either reduce their bespoke prices (collapsing the premium) or improve their forging. The market enforces the standard, not an admin.
- **The mark survives resale, which means it survives combat.** A captured ship retains its maker's identity. This creates a small but real cultural surface — pirates know which forgers are worth stealing from, alliances know which forgers are worth allying with, and the *items themselves carry stories* across the player base.

### Goods at the trading post (physical-presence requirement)

**You can't list goods you don't have at the trading post.** Listings are not abstract IOUs — the seller must physically haul the goods to a Bank Terminal / hub before listing, and the goods sit in the trading post's escrow inventory during the entire listing lifetime. Same rule applies on the other side: the buyer collects the goods physically at the same trading post where the listing was placed.

**Listing flow:**
1. Seller flies their cargo / ship / module to the Bank Terminal at, say, Concordia hub.
2. Seller opens the DOM, picks the market (fungible or bespoke), submits a Sell order.
3. The matching engine transfers the goods from the seller's local inventory at that hub into a **per-hub escrow** keyed by `(marketId, hub, sellerId, listingId)`.
4. The goods are physically located at Concordia for the duration of the listing. From the seller's perspective they're gone from inventory but visible in "My Listings".
5. On cancel: goods return to the seller's local pickup queue at the same hub. If the seller isn't physically at Concordia at cancel time, they pick up next time they're docked there.

**Buy flow:**
1. Buyer's order matches an Ask in the Concordia book.
2. The escrowed goods are reserved for the buyer; payment debits the buyer's currency balance.
3. The goods are now in the **buyer's pickup queue at Concordia**, NOT teleported to the buyer's home. The buyer must travel to Concordia (or send a hauler) to collect.

**Why this is load-bearing:**

- **Hub control is economically meaningful.** A hub that's contested, blockaded, or destroyed becomes a graveyard of stranded listings. Alliances that control hub access *control market access*.
- **Transporters get an arbitrage loop for real.** Buying low at Hub A and listing high at Hub B requires physically hauling the cargo between them. The price gap and the haul risk are both real costs in the player's decision.
- **The Supply-Chain Tap blockade loop extends into purchases.** A player who market-buys from a remote hub creates an inbound shipment to their home; that shipment is intel for hackers and a target for pirates. **Buying creates risk, not just selling.**
- **Different hubs have different effective inventory.** A module that's plentiful in Concordia may be scarce in Ferrum. Regional supply asymmetry is what drives the inter-hub trade routes that make the game's geography matter economically.

The matching engine's per-market state already lives per `(itemId, grade, hub)` tuple (see [Per-Market Structure](#5-per-market-structure)), so this is a clean extension — the escrow inventory is keyed by the same hub, and "physical presence at the trading post" is a property of the underlying inventory location, not a new concept.

### Storage fees on parked goods (anti-storage-abuse)

Listings cost money to keep open. The trading post charges a **periodic storage fee** on every listed good for as long as it sits unsold — the system isn't free warehouse space, and pricing it accordingly prevents players from exploiting the trading post as parking inventory in escrow indefinitely.

**Mechanics:**

- An admin-tunable percentage **per economy tick** (weekly by default) is debited from the seller's wallet for every active listing, billed against the **fungible market value** of the listed goods.
- Default rates (admin-tunable per trading post in PlayFab title internal data):
  - **Mainstream faction hubs (FED / ICE core hubs, alliance citadels):** 0.5% / week of fungible market value
  - **Black market trading posts:** 0.1% / week of fungible market value (see [Black Market](#the-black-market) below — the storage-fee discount is one of two key advantages)
- The fee compounds weekly. A Grade-A Reactor with fungible market value 50,000 FED listed for four weeks at a mainstream hub accumulates 1,000 FED in storage fees; the same listing at a black market accumulates 200 FED.
- Fees are charged at the **Weekly Economy Tick** (see [`./economy_obligations.md`](./economy_obligations.md) §6) — same scheduled job that runs taxes and loan auto-debits.
- The **listing price** is irrelevant to the fee math — listing at 999,999,999 still costs storage fees against true fungible value. There's no way to game the fee down by absurd pricing.

**Payment:**

Storage fees auto-debit from the seller's wallet at the weekly tick. If the wallet doesn't hold enough currency to cover the fee:

1. **For fungible commodity listings:** the system auto-sells a portion of the listed goods at fungible market price to cover the shortfall. The remaining inventory stays listed.
2. **For bespoke listings:** the listing is frozen — no further fees accrue, but no buyer can fill it either, until the seller pays the back-owed fees and reactivates. This prevents bespoke listings from accidentally vaporizing themselves through auto-liquidation.
3. **For any listing where back-owed fees exceed the goods' total fungible value:** the listing is **forfeited** to the trading post operator. The goods become the trading post's, the listing closes. This is the hard backstop against truly abandoned listings.

**Where the fee goes:** burned. Storage fee revenue is removed from the economy as a currency sink, the same way taxes and the invisible-hand ceiling fills function. The cumulative storage fees provide steady deflationary pressure on the live currency supply.

**Display:**

The expected weekly storage cost is shown before the listing is placed:

```
List Grade-A Fusion Reactor at 50,000 FED?
  Storage fee:  ~250 FED/week (0.5% of fungible market value)
  [Confirm] [Cancel]
```

The seller's open-listings panel shows accumulated storage costs per listing, with a clear "running total since listing" so players can see what their parking is costing them.

**Why this design:**

- **Parking goods as free storage actively loses money over time.** A 50,000-FED-value listing parked at a mainstream hub for a year accrues ~26,000 FED in storage fees — over half the value of the goods. There is no scenario where parking is cheaper than just owning inventory.
- **Legitimate listings face only proportional cost.** A seller pricing fair and getting the listing filled within a week pays maybe 250 FED total — trivial relative to the trade value. The friction scales with how long indecision lasts.
- **Black market becomes the parking-friendly alternative.** Sellers who legitimately want long-term listings can route to black-market hubs at 1/5th the storage cost — at the price of also losing faction protection, hub safety, and accessibility (see below).
- **Hard backstop on abandoned listings.** Once back-owed fees exceed the goods' value, the listing forfeits. There's no permanently stuck "I forgot about this listing for two years" state polluting the books.

### The Black Market

A small number of **black market trading posts** exist on the system map. They function mechanically the same as any other Bank Terminal — DOM order book, all order types, the same matching engine — but they offer two specific advantages and several specific drawbacks that make them a deliberately niche choice for specific use cases.

**Advantages:**

1. **No faction transaction tax.** Trades at a black market avoid the 35% FED Federation tax, ICE military tariff, AND the 3% universal market escrow. A black market trade is the cheapest possible transaction in the game, fee-wise.
2. **Reduced storage fees.** 0.1% / week against fungible market value, vs. 0.5% at mainstream hubs. Five-times-cheaper parking for long-term listings.
3. **Accepts contraband, stolen goods, and Outlaw-doctrine items.** Three classes of listings that mainstream hubs reject outright are accepted here:
   - **Restricted ordnance** — Depleted Uranium, Nuclear Warheads, Antimatter, Quantum Jammer, etc. See [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §3.3.
   - **Stolen goods (contraband)** — items recovered from looted wrecks, captured cargo, or raid takings that still carry a `stolenFrom` provenance tag. **The tag is territory-dependent — see "Clean goods doctrine" below.** FED/ICE hubs reject any listing whose item carries this tag; black markets list them freely. Sellers who want to fence tagged stolen goods either run them to a black market OR pay the laundering fee (see below) to clear the tag and list them mainstream. **The original owner can see their stolen items appear on black market listings** — this is intentional intel surfacing, and a meaningful gameplay surface (a player whose Forged Fusion Reactor was stolen in faction-patrolled space can spot it on a black market, then trace the seller / hunt them down).
   - **Outlaw-doctrine items** — modules whose recipes require Outlaw labs (Gravity Well Generator, Singularity Drive, Antimatter Lance, Phase Cloak Field, etc.). These items are technically legal but politically charged; mainstream FED hubs may refuse to list them. Outlaw-doctrine items always have a clear home at black markets.

**Clean goods doctrine — territory determines whether loot carries a `stolenFrom` tag.**

The `stolenFrom` tag isn't applied to every piracy event — only when the act of piracy happens within **patrolled territory**. "Patrolled territory" is defined geometrically by **territory bubbles** centered on faction / alliance anchors — same primitive as the jump-gate network. See [`../world/world_territory_bubbles.md`](../world/world_territory_bubbles.md) for the full territory model. This is the territorial gameplay layer that makes geography matter for both pirates and victims.

| Where the piracy happens | Player victim's loot | NPC victim's loot |
|---|---|---|
| **FED-patrolled space** (FED core sectors) | `stolenFrom = victimPlayerId` — tagged, mainstream-blocked, requires black-market fence or laundering | No tag (NPCs have no provenance) — but patrol response triggers immediate hostility flag on the attacker |
| **ICE-patrolled space** (ICE core sectors) | `stolenFrom = victimPlayerId` — same | Same as above for ICE |
| **Alliance-controlled space with active patrols** | `stolenFrom = victimPlayerId` — alliance patrols count as witnesses | No tag; alliance hostility flag applies |
| **Outlaw belts / lawless space / neutral contested** | **No tag** — clean goods, sellable at any mainstream hub | No tag, no patrol response, no consequences |

**The strategic geography:**

- **Pirate in faction space →** loot is tagged → must fence via black market (15% launder fee) or sell at black market (no faction tax but no mainstream price either). Victim has visible intel and recovery path.
- **Pirate in Outlaw space →** loot is clean → sellable at FED/ICE/alliance hubs at full mainstream price. Victim has no recovery path; loss is final.

This creates **two distinct piracy doctrines**:

1. **Faction-space piracy** — higher-volume targets (more players, more transports, more wealth in core space), but loot is tagged. Pirates pay either the laundering fee or the black-market sell-side discount. Net margin is modest but volume is high. The victim has a recovery loop (Cargo Sniffer / Roster Sniffer to scan the black market for their items, bounty contracts, alliance recovery ops).
2. **Outlaw-space piracy** — lower-volume targets (fewer players willing to venture there), but loot is clean. Pirates sell at full mainstream price. Net margin is high per kill but kills are rarer. The victim has *no* recovery path — venturing into Outlaw space means accepting losses as final.

**The doctrine also makes Outlaw space genuinely dangerous to travel.** Players hauling valuable cargo through Outlaw belts know that if they're killed, their cargo is gone permanently — no black-market spotting, no recovery contract, no bounty hunter chasing the loot. This is the *real* cost of running a smuggler / Tier 4 contraband route through Outlaw space, and it's what makes the canonical "high-pay smuggler contract" actually feel risky.

**For victims with recovery loops:** stolen items appearing on black markets after faction-space piracy creates the canonical revenge gameplay arc — see your gear, hire bounty hunters, raid the seller. Outlaw-space losses don't generate this loop, but they also tell the victim *not to fly that cargo there again*. Both are valid teaching mechanics.

**Drawbacks:**

1. **Hidden location.** Black markets are *not on the standard map* — they don't appear in the sector map's known-bank-terminals list by default. A player has to **discover** the location through one of several paths: (a) being told the coordinates by another player who knows, (b) following an alliance-internal directive that reveals it, (c) running a discovery quest in Outlaw space, (d) pirating a courier carrying coordinate intel. Once known, the location is added to the player's personal map; it's not lost when the player relogs, but the *general player base* never gets a public listing.
2. **No legal recourse.** Trades at a black market have no faction insurance, no audit trail accessible to faction governance, no FED-bounty-hunter retrieval if the buyer's payment fails to clear (which it always does on the DOM, but lore-wise — there's no faction backing the contract). For purely DOM-mediated trades this rarely matters in practice; for adjacent gameplay like player-to-player side deals, it matters a lot.
3. **No FED/ICE patrol coverage.** Black markets live in lawless or Outlaw-controlled space. Travel to and from a black market is at the player's own risk; faction patrols don't escort, and Outlaw raiders treat trade-post-adjacent space as a hunting ground.
4. **Smaller liquidity.** Black market order books typically have less depth than mainstream hub books because fewer players know the location and bother traveling. Spreads are wider; market orders slip more. This is the natural consequence of obscurity, not a system-imposed penalty.
5. **Restricted-ordnance routing.** Because black markets don't enforce faction contraband law, they're the *only* legal venue for trading the items in [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §3.3 Restricted Ordnance (Depleted Uranium, Nuclear Warheads, Antimatter, Quantum Jammers). FED/ICE hubs reject restricted-ordnance listings outright; black markets accept them. This is doctrinally the *primary* use case for black markets — not tax evasion, but contraband legality.

**Contraband laundering service (black market only):**

Sellers who want to convert stolen goods into mainstream-tradeable inventory can pay a **launder fee** at any black market terminal:
- Fee: admin-tunable percentage (`market.launderFeePercent`, default **15%**) of fungible market value, payable in any currency.
- Effect: clears the `stolenFrom` provenance tag from the item. The item is now mainstream-tradeable.
- Risk: the laundering transaction itself is private (it doesn't appear in any public ledger), but the goods retain their underlying instance identity — a forensic player who saw the item's original `stolenFrom` mark *before* laundering could in theory recognize it later by its other immutable properties (maker's mark, custom name on bespoke ships, etc.). For commodity items the laundering is effectively perfect; for bespoke items it's only as good as the seller's ability to also strip identifying marks.
- **Natural laundering through refining.** Raw stolen ore that gets refined into refined metal loses the stolen tag — the output of a refining recipe is a freshly-stamped instance, not a re-stamped version of the input. This means stolen raw materials are easy to launder by simply processing them. Stolen finished goods (modules, ships) are much harder to launder cleanly.

**Why this design:**

- **Tax-free trading is a real prize that has to be earned.** Knowing where a black market is is privileged information; getting there is dangerous; market depth is thinner. The tax savings have to be substantial to be worth the cost — which means players who go through the trouble are usually doing high-value trades (big-ticket modules, capital ships, restricted ordnance), not routine commodity flow.
- **The storage discount is the long-term-listing escape hatch.** A player who legitimately wants to park a Forged bespoke ship hoping for the right buyer can route to a black market and pay 1/5th the storage. The discount makes long-tail listings viable instead of bleeding the seller out.
- **Contraband / restricted / Outlaw items get a single coherent home.** Without black markets, three distinct categories of "things mainstream hubs reject" have no legal place to clear — they'd have to be sold via direct player trades, which is much less efficient. The black market gives the smuggling economy a structural anchor.
- **Stolen-goods surfacing is a feature, not a bug.** Players seeing their looted gear appear on black market listings creates real, unscripted drama — recovery missions, revenge ops, bounty contracts. This is the kind of emergent gameplay that scripted content can't replicate.
- **Discoverability is the doctrinal cost.** A black market that everyone knows about is just another tax haven. A black market that requires player-to-player knowledge transfer is *valuable* to know — and that value is a social-trading-asset in itself ("I know where a black market is" becomes useful intel a player can sell).

### Repair System — restoring durability for resale

Combat degrades module durability. The DOM listing eligibility check requires **full durability** ([§5 "Player-instance listing mechanics"](#player-instance-listing-mechanics)). So a player who wants to resell a damaged module must repair it first. The repair system is the mechanic that closes that loop.

**Where you can repair:**

| Facility | Restrictions | Cost premium |
|---|---|---|
| **FED / ICE faction hubs (Shipyards, Repair Bays)** | Refuse items carrying `stolenFrom` provenance tag. Refuse restricted-ordnance items. | Standard rates |
| **Alliance citadels with repair modules** | Member discount; non-members pay 25% surcharge (matches the alliance non-member toll ceiling) | Standard ± alliance pricing |
| **Black markets** | Accept anything — stolen goods, restricted ordnance, Outlaw items | **20% premium** over mainstream rates (the black-market repair tax is the inverse of the no-transaction-tax advantage; faction hubs subsidize repair via tax revenue, black markets don't) |
| **Mining Outposts (Fortified variant)** | Limited capacity — emergency repairs only, can't restore to full durability, caps at ~80% | Standard rates within capacity |

**Repair cost formula:**

```
repairCost = (1 - currentDurability/maxDurability) * baseRepairCost * gradeMultiplier
```

Where:
- `currentDurability` / `maxDurability` — the item's current vs. schema-defined max
- `baseRepairCost` — admin-tunable per item type (`item.baseRepairCost`)
- `gradeMultiplier` — scales with grade tier (Grade Fl items cost more to repair than Grade F)

Payment is in the local hub's preferred fiat currency. Repair materials (a small amount of corresponding refined materials — Steel for hull modules, Super-Conductor for energy components, etc.) are consumed in addition to the currency cost, drawn from the player's local inventory at the hub.

**Repair speed:**

- **Queued repair** — default. Repair completes at the next Weekly Economy Tick. Cheap. Player can leave and come back; the module is ready when they next visit.
- **Express repair** — instant, available at premium rate (default 3× cost). For when the player needs the module *now* for an immediate engagement or listing.
- **Capital-class repairs** (Battleship hulls, capital module variants) always queue regardless of price tier — repair time scales with module mass, and capital repairs take real time at the shipyard.

**Repair eligibility — what can't be repaired:**

- **Destroyed instances** (durability = 0 from a combat-kill) cannot be repaired back. The instance is gone; the player loses it permanently. Repair restores from `1 ≤ durability < maxDurability`, not from zero.
- **Consumable ammunition** (Missile bodies, Warheads, Laser Cells, Plasma Bolts) is not repairable — these are single-use by design.
- **Tier 4 exotic single-use items** (Antimatter Cells, Quantum Backdoors) are not repairable — they're consumables by category.

**Schema:**

Persistent durability lives on `PartInstance` as a new field separate from the existing runtime state:

```
PartInstance
  ...existing fields...
  currentDurability    : float   // 0..maxDurability; persistent across sessions
  // (existing) runtimeHealth and runtimeDestroyed remain for combat-tick state
```

`maxDurability` is derived from the schema's existing `ItemSchema.durability` AnchorCurve, evaluated at the instance's grade. The repair handler `RepairInstance(instanceId, hubId, expressMode)` validates location, charges currency + materials, restores `currentDurability` to `maxDurability`, and re-stamps the integrity checksum (since the durability field is covered by the pepper).

**Why this design:**

- **Damaged goods get an exit path other than scrap.** Without a repair system, a player who takes 30% damage on a Forged Fusion Reactor has only two options: keep using it at reduced effectiveness, or scrap it for partial material recovery. Repair adds a third path: restore + sell. This is what completes the combat→damage→repair→resale loop.
- **The repair facility map mirrors the trading facility map.** Faction hubs offer mainstream repair; black markets offer contraband-friendly repair at a premium; alliance citadels offer member discounts; Mining Outposts offer emergency capacity. The same geographic considerations that drive trading also drive repair, which means the same Transporter doctrine applies (haul damaged goods to the right repair facility for the goods' status).
- **Repair-then-resell is a coherent profession.** A player who specializes in buying damaged goods cheap (from combat losses, salvage operations) and repairing them for resale at full price is doing a real arbitrage. The spread is the repair cost; the skill is finding undervalued damaged goods.
- **Capital-class repair time is a real strategic constraint.** A Battleship that takes serious damage in a fleet engagement can't be back in service the next day — it sits in dry dock at the shipyard. This means **fleet doctrine has to account for repair turnaround time**, which is a meaningful constraint that distinguishes capital combat from frigate skirmishes.

### Cross-currency buyer convenience (fiat ↔ fiat auto-conversion)

**The seller picks what currency they want to be paid in.** When listing, the seller selects one of:
- **FED credits**
- **ICE credits**
- **Gold Ingots**

Whatever the seller picks, that's exactly what they receive on fill. The seller doesn't worry about which currencies buyers have.

**If the buyer has the listed currency**, the trade is straightforward — debit buyer, credit seller, transfer goods, done.

**If the buyer doesn't have the listed currency** (e.g. listing is in FED, buyer only has ICE), the DOM shows the buyer the price **in both currencies** at current exchange rate:

```
Grade A Fusion Reactor — Concordia hub
Asked: 50,000 FED credits  (≈ 64,200 ICE credits at current rate)
```

If the buyer clicks Buy, the system executes the transaction **atomically as two linked orders**:
1. A market BUY for 50,000 FED on `market.pact_to_ice`, paid for with the buyer's ICE credits. Slippage from this conversion is **absorbed by the buyer** — they pay whatever ICE the actual fill required (might be 64,200, might be 64,800 if the book was thin).
2. The acquired 50,000 FED is delivered to the seller as their listed payment.

Either both legs execute or neither does — there's no partial state where the conversion succeeded but the goods purchase didn't. If the currency conversion can't be filled (e.g. the FED↔ICE book is too thin), the whole transaction aborts and the buyer is told to acquire FED manually first.

**Gold is excluded from auto-conversion.** Gold-priced listings require the buyer to have physical Gold Ingots in their inventory at the hub. Gold is a finite physical commodity, not a balance — it can't be conjured from a fiat conversion at buy time. A buyer who wants a gold-priced module must trade for the gold separately (via the `market.gold_to_pact` / `market.gold_to_ice` markets) and have the gold physically present *before* the goods purchase. This preserves gold's scarcity / hard-asset role.

**Why this design:**

- **Sellers don't have to think about currency strategy.** They pick what they want to be paid in based on what they personally need (FED for hub access, ICE for ICE-faction repairs, Gold for hard-asset storage). The system handles the rest.
- **Buyers don't have to manually trade currency before buying.** One click executes the full chain. This dramatically lowers the friction of inter-faction trading.
- **Slippage is the buyer's cost.** This is the right incentive — buyers with rare currency holdings pay more, naturally pressuring them to maintain balanced currency portfolios or accept the slippage tax as a convenience fee.
- **The FED↔ICE DOM has guaranteed organic demand.** Every cross-currency purchase generates trade volume on the currency DOM, keeping it liquid even when no one is actively trading currencies directly.

---

## 6. Access — What Requires Physical Presence vs. What Doesn't

Not all banking happens at a Bank Terminal. The access model splits cleanly along **what has to physically move** to make the transaction work: anything that's pure balance state (currency, market orders) is universally available; anything that needs goods to physically transfer requires presence at the relevant facility.

### Available anywhere — no Bank Terminal required

- **Fiat currency exchange (FED ↔ ICE).** Pure balance conversion between the two faction fiat currencies. Players can do this from any location, mid-flight, in deep space, in an Outlaw belt. Why: FED and ICE credits are pure balance state — nothing physical needs to move.
- **Viewing markets and placing orders.** A player can browse markets, read books, and place limit / market / stop orders for goods from anywhere — they can't always *list* (which needs physical goods to escrow) but they can buy.
- **Buying goods.** A player can market-buy or limit-buy goods from any location. The trade settles atomically — currency debits from the buyer's wallet, goods move from the seller's escrow into the **buyer's pickup queue at the trading post** where the listing lived. The buyer didn't have to be at the hub to *buy*. They will have to be at the hub to *collect* (see below). **Markets are reachable; goods are not.**
- **Cross-currency auto-conversion as part of a goods purchase.** Since both the underlying fiat exchange AND the goods purchase itself can now be initiated remotely, the whole transaction works from anywhere. Auto-conversion fires when the buyer's wallet lacks the listed currency; the two legs execute atomically; the goods land in the buyer's pickup queue.

### Requires physical presence at a Bank Terminal / Trading Post

- **Listing goods for sale.** The goods must physically be at the trading post when the listing is created (see [§5 "Goods at the trading post"](#goods-at-the-trading-post-physical-presence-requirement)). The seller hauls cargo to the hub first, then lists. Listing is a one-direction-only constraint — the goods have to be IN the hub to enter escrow.
- **Collecting goods from the pickup queue.** Goods you've bought (or unsold listings you've cancelled) sit in your **per-hub pickup queue**. Collecting them requires you (or a hauler you send) to be physically docked at that hub. The goods move from queue into your local ship cargo / base storage at pickup time.
- **Converting Gold to / from fiat.** Gold is physical commodity, not a balance. Converting Gold Ingots into FED or ICE credits requires the Gold to be **deposited at a Bank Terminal first**. The reverse (using fiat to buy gold) also requires the buyer to be at a Bank Terminal because the purchased gold has to materialize as physical inventory somewhere — that somewhere is the buyer's pickup queue at the bank.

### The pickup queue — buyer-side storage between purchase and collection

Every player has an implicit **pickup queue at every trading post they've ever transacted at**. The queue holds:

- Goods bought through the DOM, sitting until the buyer collects.
- Unsold goods returned from cancelled listings (when the seller wasn't at the hub at cancel time).
- Gold withdrawn from the bank, sitting until the player picks it up physically.

**The pickup queue incurs the same periodic storage fees as listed inventory** — 0.5% / week at mainstream hubs, 0.1% / week at black markets, against the fungible market value of the queued goods. This means **leaving purchased goods in the queue costs money over time**. A player who buys remotely and doesn't pick up for months will eventually see their purchase value erode to storage fees.

Same auto-recovery rules apply as for listings:
- Wallet insufficient at the weekly tick → commodity goods auto-liquidate a portion to cover; bespoke items freeze pending payment.
- Back-owed fees exceed goods' value → goods forfeit to the trading post.

**Why this design (buy-anywhere, pickup-at-hub):**

- **Market access is friction-free; goods transfer is the choice point.** A trader can spot a deal from anywhere and execute the buy instantly — they don't have to physically race to the hub to beat another buyer. Whoever submits the order first wins, regardless of location.
- **Pickup logistics become a deliberate gameplay decision.** Once you've bought, you decide *when* and *how* to collect. Send a fast Light Hauler now? Wait for a convoy with escort? Let it sit until you're already going that way? Each choice has different cost/risk tradeoffs.
- **The Transporter role gets a buy-side gameplay loop, not just sell-side.** A player can specialize in "pickup logistics" — getting hired by other players to fly out to remote hubs and collect their purchased goods. This is a new service-role that the Transporter family enables.
- **Storage fees apply symmetrically.** Sellers pay storage on unsold listings; buyers pay storage on uncollected purchases. The trading post is non-trivially-priced warehouse space in both directions.

### What this means for each space

- **FED / ICE core space:** Full DOM access everywhere — players in any sector can buy goods from any FED/ICE hub. Listing + collection require physical presence at the hub.
- **Mixed / contested space:** Same access rules; alliance-controlled hubs are reachable from anywhere for buy-side, accessibility for listing/collection depends on whether the player can safely dock.
- **Outlaw belts:** No banks at all means no DOM access from the Outlaw belt itself. **But** an Outlaw player can still buy from any FED/ICE/alliance hub remotely — the buy is universal, only the pickup requires going there. They'd need to fly to the hub to actually take possession. Many Outlaws may simply never collect; the goods sit in the pickup queue accruing storage until forfeited. Fiat exchange still works from anywhere as a pure balance op.

A future-design extension: **Portable Trading Terminals** as a Tier 3+ utility module that would let a hull *list* goods remotely at a transaction fee penalty (the current canon already allows buying remotely; the future extension would close the listing side). Defer — not in canon yet. Gold conversion stays gated to physical bank presence regardless.

---

## 7. Schema Implications

Brief sketch of the data model. Full implementation is currency-and-banking slice.

```
Order
  orderId       : string (UUID)
  marketId      : string
  ownerId       : string (playerId)
  side          : enum { Buy, Sell }
  type          : enum { Market, Limit, Stop }
  price         : float           // for Limit / Stop; ignored for Market
  qty           : int             // remaining unfilled quantity
  qtyFilled     : int
  status        : enum { Open, Filled, Cancelled, Triggered }
  placedUtc     : long
  triggerPrice  : float           // for Stop only
  triggerSide   : enum { Above, Below }  // for Stop only
```

```
Trade
  tradeId       : string
  marketId      : string
  buyerId       : string
  sellerId      : string          // may be "INVISIBLE_HAND" for phantom fills
  price         : float
  qty           : int
  executedUtc   : long
```

```
MarketState (one per marketId, in PlayFab title internal data)
  marketId       : string
  bidBook        : Order[]        // sorted desc by price, asc by placedUtc within price
  askBook        : Order[]        // sorted asc by price, asc by placedUtc within price
  lastTradePrice : float
  floorPrice     : float          // admin-set, hidden from clients
  ceilingPrice   : float          // admin-set, hidden from clients
```

**Server-authoritative:**
- All order placement / cancellation / matching goes through CloudScript handlers.
- The matching engine runs server-side per submission; a player cannot see the book state and then submit a doctored client-side fill.
- `floorPrice` / `ceilingPrice` are read by the matching engine but NEVER returned to clients in any response payload. Per CLAUDE.md "Don't trust the client" — leaking these values via any code path defeats the invisible-hand design.
- Trade history is queryable but throttled (rate-limited reads to prevent screen-scraping the entire history for analysis).

---

## 8. UI Requirements

Roughly what the Bank Terminal trading panel should show:

- **Market selector** — searchable list of currently-tradable markets (Currency / Commodity / Module tabs).
- **Level-2 DOM display** — Bid column / Ask column, price ladder, volume per level, last-trade marker.
- **Order entry form** — buy/sell, type (Market/Limit/Stop), price (greyed out for Market), qty, submit button. Form should pre-fill the limit/stop price to the current best Bid/Ask so one-click submission is reasonable.
- **My Open Orders panel** — list of player's own open / triggered orders with cancel buttons.
- **Trade history strip** — most recent N trades in this market, time + price + qty. Drives a tiny ticker chart.
- **Account summary** — player's balance in each currency, plus current holding qty of the traded commodity if applicable.

The UI is *deliberately busy* — a DOM should feel like a real trading terminal. Players who don't want to engage with it can use Market orders exclusively and treat the system as a simple buy/sell button; players who do engage get full commodity-trading depth.

---

## 9. What this replaces / supersedes

The previous canon at [`./economy_trade.md`](./economy_trade.md) described **scarcity-based hub pricing** — `currentStock / targetStock` formula determining prices. That model is **superseded** by the DOM model for trades involving actual exchange between players.

The scarcity formula is **retained for NPC seed pricing** — when a market first opens, or when the invisible hand sets floor/ceiling values, those defaults come from the scarcity model. So:
- New market opens → scarcity formula seeds floor/ceiling
- Players trade → DOM takes over
- Floor/ceiling slowly adjust as long-run scarcity shifts → admin (or future automated job) updates the band

`economy_trade.md` should get a "see also" pointer to this doc and a note that DOM has superseded the static-price model for live markets. Tracked in master_to_do.

---

## 10. Data Retention and Aggregation (60-day rolling)

PlayFab storage is finite and per-key write throughput is metered. A live MMO economy generates a huge volume of transient records — every DOM fill, every closed order, every weekly tax payment, every loan auto-debit, every hacking event. If retained indefinitely, the database grows without bound and we hit cost/performance walls fast.

**Canonical retention rule:** **Raw transaction records are deleted after 60 days.** Before deletion, a maintenance job rolls them up into long-lived aggregates that preserve the gameplay-meaningful signal without keeping every individual event.

### What gets pruned after 60 days

| Record type | 60-day retention | Aggregated into |
|---|---|---|
| `Trade` (DOM fills) | Yes | Per-(market, day) volume-weighted price summaries; MakerProfile stats |
| `Order` (closed orders — filled, cancelled, expired) | Yes | Per-player order-count totals + sale-price premium metric on MakerProfile |
| Loan payment history (individual weekly debits) | Yes | Per-(player, loan) "weeks paid / missed" counter; standing-history rollup |
| Tax payment history | Yes | Per-(player, planet) "weeks paid / missed" counter |
| Expired Resource Permits | Yes (deleted from active list at expiry, full record retained 60 days post-expiry for audit) | Per-(player, alliance) permit-purchase-count counter |
| Hacking event log (intel-access events, patrol-engagement events) | Yes | Aggregated into faction / alliance enforcement-stats; flagged hostile players retain reputation hit |
| Restocking / storage fee debits | Yes | Aggregated into per-player lifetime-fees-paid counter |

### What's retained indefinitely

- **MakerProfile aggregates** — total volume, grade distribution, specialization, average sale-price premium. These are the rolled-up reputation that survives the trade-record deletion.
- **Open orders** — orders sitting in a DOM book are *not* transient; they persist until filled or cancelled. 60-day retention applies only after the order moves to a closed status.
- **Active Loans** — open loans persist regardless of age. The 60-day rule deletes individual payment events but the loan itself stays until paid off or defaulted.
- **Active permits** — same as loans.
- **`PartInstance` and `ShipInstance` records** — player inventory is permanent. No retention rule on the items themselves.
- **Standing values per (player, faction)** — current state, not transactional. Persists forever.
- **Per-market daily VWAP summaries** — aggregated price history retained long-term for chart display. (Implementation: a daily roll-up job summarizes every trade in that market for the day into one summary record; the underlying trades are deleted at 60 days but the daily summary lives on.)

### Maintenance job

A scheduled CloudScript job runs **daily**:
1. For every transient record older than 60 days, compute its contribution to the corresponding aggregate (MakerProfile, market VWAP summary, player counter).
2. Update the aggregates in place.
3. Delete the raw record.

The job is idempotent — running it twice doesn't double-count — and tolerant of partial failures (interrupted runs resume from where they left off). It piggybacks on the Weekly Economy Tick infrastructure (see [`./economy_obligations.md`](./economy_obligations.md) §6) but runs daily because retention is by individual record age, not by weekly cycle.

### What this means for designers and implementers

- **No design surface should depend on raw-trade-history older than 60 days.** If a mechanic needs to query "every trade this player has ever made," it must read from the rolled-up aggregate, not the raw records.
- **Price-band reference calculations are well under retention.** Bands use last-100-fills or last-7-days, both << 60 days. Safe.
- **MakerProfile is the load-bearing aggregate.** If the rollup is broken or lossy, maker reputation rots silently. The maintenance job's correctness on this specific path is critical.
- **Audit / dispute flows are bounded.** A player who claims "I was wrongly charged 73 days ago" has no underlying record to verify — the raw data is gone, only the aggregated counter exists. Disputes have to be raised within the 60-day window. This is the same operational rule as real-world credit card chargeback windows; flag it in the player-facing trade-history UI so players understand the window.

---

## 11. Why this design

Three load-bearing reasons:

1. **One mental model across every market.** Currency exchange, commodity trading, module flipping all use the same DOM mechanics. Players learn it once.
2. **Player skill matters.** Smart limit orders, well-placed stops, and reading the book are real skills that distinguish a good trader from a bad one. This rewards the Researcher / market-savvy player archetype without requiring combat or mining skill.
3. **Designer control without designer visibility.** The hidden floor/ceiling lets the dev team manage the economy without breaking immersion. Players never feel "the game is interfering" because they can't see the interference — the band is just one more market dynamic to read around.
