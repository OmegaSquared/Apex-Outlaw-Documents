# Freight Contracts — the Transporter Role's Gameplay Loop

This document is the canonical design for the **freight contract system** — the formal mechanism by which one player commissions another player to physically move cargo from one location to another for payment. Contracts are the Transporter role's primary gameplay surface: without them, Transporters can only do speculative arbitrage hauls; with them, Transporters can be *hired* to deliver freight on commission, which is the canonical livelihood of the role.

Contracts are also the **structured form** of the data that Supply-Chain Tap (T3 hacking) reads as the "alliance shipment manifest." Until now, that manifest has been hand-wavy; with contracts as a real schema, the manifest is a concrete query against the contract store.

---

## 1. What a Contract Is

A **Freight Contract** is a posted job with this structure:

> "Pick up *cargo* at *origin hub* and deliver it to *destination hub* by *deadline*. Payment is *amount* in *currency*. Hauler must post *collateral* on claim."

Both the **cargo** and the **payment** are escrowed by the system at the moment the contract is posted — the cargo physically sits at the origin hub in contract escrow; the payment is held in a system wallet. Neither moves until the lifecycle resolves.

### Visibility — three contract scopes

- **Open Contract** — visible to any hauler at any Bank Terminal. Filterable by route, payment, cargo class, hauler-reputation-required. The default.
- **Direct Contract** — addressed to a specific named hauler. Only they can claim. Used when the poster has a preferred hauler (personal trust, alliance member, repeat business).
- **Alliance Contract** — restricted to members of a named alliance. Visible only on the alliance's internal contract board. Used for alliance supply chains — alliance treasury pays a member-hauler to run an internal route.

A contract can be additionally tagged **Contraband** — must originate AND deliver at black markets. Higher pay reflects the risk. Mainstream haulers (those whose Hauler Profile reads as faction-aligned with FED/ICE patrol respect) will typically avoid these; Outlaw-affiliated haulers specialize in them.

---

## 2. Contract Lifecycle

Six canonical states with strict transitions.

```
  [posted] ──claim──▶ [claimed] ──pickup──▶ [in_transit] ──deliver──▶ [delivered] ──pay──▶ [closed]
      │                   │                       │
      │                   │                       └──fail──▶ [failed]
      │                   │
      │                   └──hauler_default──▶ [failed]
      │
      └──poster_cancel──▶ [cancelled]
```

### Posted

Poster creates the contract. At post time, atomically:
- **Cargo escrow:** the cargo physically moves from the poster's local inventory at the origin hub into a contract-specific escrow keyed by `contractId`. Poster cannot withdraw it except by cancelling the contract.
- **Payment escrow:** the payment amount moves from the poster's wallet into system escrow. Same — held until lifecycle resolves.
- **Listing fee:** small admin-tunable fee (`contract.listingFeePercent`, default 1% of payment) is debited from the poster as a sink. Discourages spam-posting low-value or impossible contracts.

A posted contract is visible on the appropriate board (Open / Direct / Alliance) and remains posted until claimed or until the **post deadline** expires (default 7 days). If post deadline expires unclaimed, the contract auto-cancels and both escrows return to the poster.

### Claimed

A qualifying hauler claims the contract. At claim time:
- If the contract requires **collateral**, the hauler's collateral moves from their wallet into escrow. (Collateral is the poster's protection against hauler default; on success it returns, on failure it forfeits to the poster.)
- The hauler's `Hauler Profile` reputation must meet the contract's minimum threshold (if set by the poster). Sub-threshold haulers are rejected at claim.
- The contract transitions to `claimed` and is hidden from other haulers.

The hauler now has until the **delivery deadline** to complete the run. Until they physically pick up the cargo, they're in `claimed` status but not yet `in_transit`.

### In Transit

The hauler is physically at the origin hub and collects the cargo from the contract escrow into their ship's cargo (or onto their Crate-Push Rail for crate-based cargo). At pickup:
- The cargo leaves contract escrow and enters the hauler's local inventory.
- Contract transitions to `in_transit`.
- The cargo carries a **contract-bound flag** during transit: the hauler can't list it on the DOM, can't sell it directly, can't repurpose it. It must be delivered to the named destination to clear the flag.
- The contract data is added to the **alliance shipment manifest** (or the poster's personal manifest) that Supply-Chain Tap can read — see [`./economy_exchange_pricing.md`](./economy_exchange_pricing.md) hacking chain references.

The cargo in transit is vulnerable to combat loss. If the hauler is destroyed and the cargo lost, the contract enters the `failed` state at the next delivery-check.

### Delivered

The hauler arrives at the destination hub and offloads the cargo into the contract's destination escrow. Server validates:
- All cargo specified in the contract is present (item-by-item match against the contract's cargo manifest).
- Cargo integrity is intact (checksums match — no swapped, tampered, or partial items).
- Delivery is within the deadline (server-side clock comparison).

On valid delivery, the contract transitions to `delivered`. The cargo sits in the destination escrow until the *poster* (or the poster's recipient) collects it from their pickup queue at the destination hub.

### Closed

Payment is released from escrow to the hauler's wallet on delivery. Collateral returns to the hauler's wallet. Both parties tick up in reputation:
- **Hauler Profile** — +1 contract completed, on-time delivery rate updated, cargo value delivered added to lifetime, optional bonus reputation if delivered ahead of deadline.
- **Poster reputation as a customer** — separate sub-metric, less prominent. Reliable posters who pay fairly accumulate good standing as freight customers; deadbeat posters get flagged by haulers and avoided.

Contract record retains for 60 days for audit (per data retention canon, [`./economy_exchange_pricing.md`](./economy_exchange_pricing.md) §10), then aggregates into both parties' rolling stats and is deleted.

### Failed

Three failure paths, all converging on `failed`:

- **Deadline missed.** Server-side check at deadline-passed. If contract isn't `delivered`, it fails. Hauler forfeits collateral to poster; cargo (if still in transit / origin escrow) is returned to the poster's origin pickup queue.
- **Cargo lost in transit.** Hauler ship destroyed with contract-flagged cargo aboard. Contract fails at the next server tick. Same forfeit + return rules.
- **Hauler default.** Hauler explicitly cancels their claim before pickup. Collateral forfeited; cargo returns to poster. Hauler reputation takes a hit (default rate is a tracked stat — chronic defaulters end up unable to claim high-value contracts).

Failed contracts also retain 60 days before aggregating + deleting.

### Cancelled

Poster cancels a contract *before* it's claimed. Cargo + payment both return to the poster. Listing fee is forfeited (already paid at post-time; non-refundable). Cancellation is impossible once a hauler has claimed — at that point the only paths are completion, mutual agreement to release (handled as a special edge case requiring both parties' confirmation), or failure.

---

## 3. Hauler Profile — reputation as a service economy

Mirror of `MakerProfile` for hauler reputation. Every player has a profile tracking their delivery work, regardless of whether they actively haul.

```
HaulerProfile (server-side aggregate, updated by the 60-day retention rollup)
  totalContractsCompleted     : int
  totalContractsFailed        : int
  onTimeDeliveryRate          : float
  totalCargoValueDelivered    : long   // sum of payment across all completed contracts
  averagePaymentPerHaul       : long
  defaultRate                 : float  // % of claimed contracts that hauler defaulted on
  routeSpecializations        : List<RouteRoute>  // hub→hub pairs they run most
  cargoSpecializations        : List<string>      // itemId families they haul most
  contrabandRunsCompleted     : int    // visible on the profile — being a known smuggler is intel
  blocklist                   : List<playerId>    // posters this hauler refuses to work for
```

**Discovery — Hauler Directory UI:**

Contract posters can browse a "Find Haulers" directory at any Bank Terminal, filtering by:
- Minimum on-time rate
- Cargo specialization (looking for someone who runs Tier 4 modules specifically)
- Route specialization (looking for someone who runs Avernus → Ferrum frequently)
- Reputation tier
- Faction alignment (mainstream haulers won't take contraband; contraband haulers may not be welcome at FED hubs)

A poster can then issue a **Direct Contract** to a specific named hauler from the directory — same as MakerProfile's "follow" / "browse listings" UX.

**Why this design:**

- Haulers compete on reputation, not just price. A new hauler with no history undercuts on price to build profile; a veteran charges premium because they have a verified track record.
- Reputation is **emergent from data**, not awarded (same doctrine as MakerProfile). No admin-curated "best haulers" list. The data IS the reputation.
- Cargo and route specialization let players build niche identities. "The Avernus-Ferrum gas-cylinder specialist" is a recognizable role someone can grow into.

---

## 4. Contract Pricing & Risk

Contract payment is set by the poster. Market forces determine what clears — high-paying contracts get claimed fast, lowball contracts sit unclaimed until they auto-cancel.

**Honest pricing guideline (admin-facing only — players figure this out themselves):**

```
fairPayment ≈ baseHaulCost + riskPremium + timePremium + collateralOpportunityCost
```

Where:
- **baseHaulCost** — distance + cargo mass + fuel + ammo provisioning. Roughly known per route.
- **riskPremium** — proportional to the cargo value × probability of pirate ambush on the route. High for contraband or hot-zone routes; low for safe inner-FED runs.
- **timePremium** — bonus for tight deadlines; haulers can charge more for rush jobs.
- **collateralOpportunityCost** — if the contract requires collateral, the hauler is locking up that capital for the haul duration; the payment should compensate.

A poster who lowballs (offers payment well below fair) will find their contract unclaimed. A poster who overpays gets fast claims but loses margin. Market equilibrium emerges.

**Collateral mechanics:**

- Collateral is **optional but recommended** for high-value cargo.
- The collateral protects the poster: if the hauler defaults or loses the cargo, the poster collects the collateral as compensation for the loss.
- Typical collateral ratio: 25-50% of cargo value. A 100,000 FED cargo might require 30,000 FED collateral.
- High-reputation haulers (low default rate, high on-time rate) sometimes negotiate zero-collateral contracts based on reputation alone. This is a privilege earned through history, not a baseline right.

---

## 5. Integration with Existing Canon

The contract system isn't a standalone — it integrates with most of the rest of the economy.

**Supply-Chain Tap (T3 hacking):**
The alliance shipment manifest that Supply-Chain Tap reads is **the contract store filtered by alliance affiliation and status `in_transit`**. Every active contract with an alliance as poster, destination, or origin appears on the alliance's manifest. Pirates use this intel to plan ambush points along the predicted route. The contract's `originHub`, `destinationHub`, and `deadlineUtc` give pirates a time-window for the intercept; the cargo manifest (what's being shipped, in counts not grades) gives them the value calculation for whether the haul is worth attacking.

**Bulk Hauler / Heavy Freighter doctrine:**
Bulk Hauler convoy doctrine (always-convoyed, escort frigates, Iron Dome cover) emerges as a *response* to contracts being readable through Supply-Chain Tap. A high-value Bulk Hauler contract is a known target the moment it's posted, so posters / haulers price escort fees into the payment.

**Iron Dome / PD doctrine:**
A hauler's PD loadout (whether they fit Iron Dome, Talos, MGs, Flak) is *visible* on their Hauler Profile via past loadout snapshots from combat-record metadata. Posters can prefer haulers who run PD-equipped configurations for risky routes.

**Stealth missile attacks:**
A pirate group that has Supply-Chain Tap intel on an inbound convoy + Stealth Missile inventory + Aggressive Tractor for capture-and-tow can target high-value contract cargo specifically. The contract value gives them their go/no-go threshold (is the haul worth a Stealth Missile?).

**Black market routing:**
Contraband contracts route through black markets at both ends. They don't appear in the standard Open Contract pool — they're discoverable only at black-market Bank Terminals. The Outlaw / smuggler hauler economy clears here.

**Maker's Mark + Bespoke listings:**
A poster shipping a unique bespoke item (one Forged ship being moved to a new owner) declares the specific item by `instanceId` in the contract cargo, not by category. The hauler delivers *that exact instance*; the contract escrow holds the actual `PartInstance` with its maker's mark intact.

**Faction Standing:**
A hauler with high FED standing can take FED-paying contracts and pass through FED space without patrol harassment. A hauler with negative FED standing can't even claim FED-affiliated contracts because FED patrols would attack them on the route. The Faction Standing layer gates *who can haul what to where*.

**Insurance (future canon):**
When insurance lands, it integrates here — a poster can buy contract insurance that pays out if cargo is lost. A hauler can buy hauler insurance that covers their own ship-loss risk. Both are layered on top of the contract.

---

## 6. Schema Sketch

```
Contract
  contractId           : string (UUID)
  status               : enum { Posted, Claimed, InTransit, Delivered, Closed, Failed, Cancelled }
  posterPlayerId       : string
  haulerPlayerId       : string?    // null until claimed
  scope                : enum { Open, Direct, Alliance }
  scopeTargetId        : string?    // hauler playerId for Direct; allianceId for Alliance; null for Open
  contraband           : bool       // true forces black-market origin + destination
  originHubId          : string
  destinationHubId     : string
  cargoEscrowKey       : string     // points to per-contract container holding the goods
  cargoManifest        : CargoManifest  // declared items + counts at post time
  payment              : { currency, amount }
  collateralRequired   : { currency, amount }?  // optional
  collateralEscrowKey  : string?    // null until claimed
  minHaulerReputation  : float?     // optional threshold
  postedUtc            : long
  postDeadlineUtc      : long       // auto-cancels if not claimed by this time
  claimedUtc           : long?      // null until claimed
  deliveryDeadlineUtc  : long       // auto-fails if not delivered by this time
  pickedUpUtc          : long?
  deliveredUtc         : long?

CargoManifest (declared at post time, verified at delivery)
  resourceLines : Dictionary<resourceId, qty>
  instanceLines : List<string>     // specific instanceIds for bespoke / unique items

HaulerProfile  (server-side aggregate, per-playerId)
  ...fields per §3 above...
```

CloudScript handlers:
- `ContractPost(payload)` — creates contract, escrows cargo + payment, debits listing fee
- `ContractCancel(contractId)` — poster cancel before claim; returns escrows
- `ContractClaim(contractId)` — hauler claim; locks collateral
- `ContractPickup(contractId)` — hauler at origin, cargo moves to hauler inventory + flagged
- `ContractDeliver(contractId)` — hauler at destination, cargo moves to destination escrow, validates, transitions
- `ContractCollectDelivery(contractId)` — poster collects delivered cargo from destination pickup queue
- `ContractAutoTick` — runs on Weekly Economy Tick (and a faster intra-week tick for deadline expiry) — auto-cancels stale posts, auto-fails missed deadlines

All escrows live as `ContainerInstance` records with `containerType = ContractEscrow` (new enum value).

---

## 7. Open Design Questions

Flagged but not yet decided:

1. **Multi-leg contracts.** "A → B → C" with stops. Adds significant complexity. Default position: not in v1; defer until single-leg contracts prove out.
2. **Subcontracting.** A claimed hauler hires another hauler for the actual run. Adds another layer of reputation + payment splits. Defer.
3. **Partial delivery.** Hauler delivers some of the cargo, loses the rest. Partial payment with proportional collateral forfeit? Or all-or-nothing? Default position: all-or-nothing for v1.
4. **Contract auction.** Instead of fixed payment, posters list a contract and haulers bid down the price. More market-y but more complex UX. Defer.
5. **Insurance integration.** Out of scope for v1 — insurance is its own pending canon. Contracts assume the hauler eats their own risk unless they buy a separate insurance product.

---

## 8. Why This Design

- **The Transporter role finally has a job mechanism.** Speculative haul-arb is for veterans; contracts are how new Transporters get into the role and how working Transporters earn steady livelihood.
- **Contracts are the canonical Supply-Chain Tap data source.** What was hand-wavy "alliance shipment manifest" becomes a concrete contract-store query.
- **Reputation creates a real service economy.** Haulers compete on history, not just price. A high-rep Hauler Profile is a player-earned identity that travels across alliances and economic cycles.
- **Failure modes are calibrated.** Forfeit-on-default protects posters; reputation drag punishes chronic failures; ahead-of-deadline bonuses reward excellence. The system has both stick and carrot.
- **Integration with existing canon is end-to-end.** Contracts touch Supply-Chain Tap, Iron Dome doctrine, Stealth Missiles, Maker's Mark transfers, black markets, repair, storage fees, currency exchange, and Faction Standing — and the integration works without retcons because the underlying primitives were designed compositionally.
