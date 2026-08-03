# Obligations, Loans & Licenses — the Governance Layer of the Economy

This document is the canonical design for the three mechanics that bind players to faction/alliance authority through ongoing economic relationships:

1. **Faction Loans** — borrow capital against reputation, repay or default.
2. **Planet Tax** — weekly tax to the planet's owner (faction or alliance).
3. **Resource Permits** — license to harvest in alliance-controlled territory.

All three share a common pattern: a **recurring or one-time obligation** between a player and a governing body, with **escalating NPC enforcement** if the obligation goes unmet. The enforcement is what makes the obligations bite — without server-spawned consequence fleets, players would just ignore the systems. Together these mechanics turn faction / alliance affiliation from a cosmetic tag into a real lifestyle: FED citizens pay taxes and obey permit law in exchange for loans and protection; Outlaws have no taxes and need no permits but also have no banks, no DOM access, and no NPC defenders.

---

## 1. Faction Standing — the prerequisite layer

Every player has a numerical **standing** with each major faction (FED, ICE) and every alliance they've interacted with. Standing values:

- Range from **-10,000 (sworn enemy)** to **+10,000 (decorated ally)**.
- Start at **0 (neutral)** for every new player against every faction.
- Change based on actions: completing faction contracts raises standing, attacking faction members lowers it, paying taxes on time raises it slightly over time, defaulting on a loan tanks it.

Standing **gates** the obligation systems below — a player with -2,000 FED standing cannot take a FED loan; a player with +5,000 ICE standing gets favorable ICE loan terms; an Outlaw with -8,000 FED standing is *shoot-on-sight* in FED patrols regardless of any other status.

The full standing system is a forward-looking topic — flagged here as a dependency, deferred to a future canon doc. For this doc, assume standing exists and is queryable per `(playerId, factionId)`.

---

## 2. Faction Loans

Players can borrow capital from a faction's bank if their standing is high enough. Use cases: capital ship investment, restocking ammunition for a major operation, paying off debts to another faction.

### Loan terms

- **Eligibility:** minimum standing requirement (admin-tunable, default +1,000 for any loan).
- **Maximum principal:** scales with standing (admin-tunable curve; default rough rule = `standing * 10` FED credits, so +5,000 standing → up to 50,000 FED loan).
- **Interest rate:** admin-set per faction. Default 8% APR for FED, 12% APR for ICE (ICE is the harder-money lender, lore-justified by Iron Core's industrial discipline). Compounds weekly.
- **Loan currency:** in the faction's own fiat. FED loans pay out FED credits; ICE loans pay out ICE credits.
- **Term:** open-ended. Players pay weekly minimum (5% of remaining balance) and may prepay in full at any time.

### Repayment

- A weekly payment of `remainingBalance * 0.05` is auto-debited from the player's faction-currency wallet at every weekly tick.
- If the wallet doesn't have enough currency to cover the auto-debit, the loan moves to **delinquent** status (see escalation below).
- Players can manually pay extra at any time, reducing principal directly.
- Standing rises slowly with consistent on-time payment — completing a loan in full grants a meaningful one-time standing bonus.

### Non-payment escalation

Three-tier escalation that's deliberately slow and forgiving up front, catastrophic at the end:

1. **First missed week — Late Fee.** A flat 10% penalty is added to the remaining balance. No further consequences yet. The player is notified by in-game message: "Your FED loan is overdue. A 10% fee has been applied."
2. **Continued non-payment — Grace Period (2 more weeks).** Late fee compounds weekly at the same 10%. Player standing begins to drop slowly. No physical consequence.
3. **Default — Overpowered Fleet Raid.** After three total missed payments, the faction marks the loan defaulted and dispatches a server-spawned **NPC raid fleet to the player's base**. The fleet is **scaled to be unwinnable** — adequate to overwhelm even a well-defended base. The fleet raids the base for resources / cargo / ship inventory equal to the **full remaining loan balance + accumulated fees**, plus a punitive surcharge (default 25% on top). Loan is marked closed; player standing with the faction craters (typically -3,000); player is locked out of further loans from that faction for 60 in-game days.

The "unwinnable raid fleet" is load-bearing on the design: if defaulters could fight off the collection raid, the entire loan system becomes a free-money exploit (borrow, default, kill the raid). The fleet has to be scaled to **always win**. Lore-cover: a faction-deployed enforcement fleet is the army of an entire nation-state, not a single squad — of course it wins.

If the player's base doesn't hold enough resources to cover the debt, the raid fleet takes what's there and the remainder is forgiven (but the standing penalty applies in full). Players cannot dodge the consequence by emptying their base — the standing damage is the floor.

---

## 3. Planet Tax

Every player who maintains a base on a planet owes weekly tax to the planet's owner. The owner is a **faction** (FED-owned planets like Concordia, ICE-owned like Ferrum) OR an **alliance** (player-controlled planets in alliance space).

### Assessment

- Tax owed = a function of the player's base footprint on the planet: number of base modules × module tier × an admin-tunable per-planet rate.
- Default rates: FED core planets 100 FED/week base, ICE core 80 ICE/week, alliance-owned variable (alliance sets the rate, capped at 25% per existing canon — see [`./economy_overview.md`](./economy_overview.md) key constants).
- Tax is assessed at every weekly tick. Players see an upcoming-tax notice in their dashboard before the tick.

### Payment

- Auto-debited from the player's wallet in the planet owner's currency at the weekly tick.
- Players can pre-pay multiple weeks in advance (useful before going dark / AFK for a stretch).
- Paying on time gives a small standing tick-up with the planet's owner.

### Non-payment escalation

Same three-tier pattern as loans, scaled differently:

1. **First missed week — Late Fee.** 20% penalty added to the owed amount.
2. **Grace Period (1 more week).** No additional fee, but a tax-collector notice is posted.
3. **Tax Collector Raid.** After two missed weeks, NPC tax collectors are dispatched. **These are defeatable** — they're scaled to be a meaningful fight but not unwinnable, unlike the loan-default fleet. If the player wins the fight, the tax is uncollected this cycle but the obligation persists (and a worse fleet comes next week). If the collectors win, they take **resources due plus a surcharge** (typical 50% over owed amount — "and more sometimes" per design intent), and the player's standing with the planet owner takes a meaningful hit.

The tax-collector fleet being defeatable is a deliberate contrast with the loan-default fleet. Loans are **opt-in debt** — the player consciously took on the obligation, so the default consequence is absolute. Tax is **passive obligation** — the player might be missing payments because of accident, attack, or temporary cash flow problems, so the consequence is firm but survivable.

### Alliance-owned planets vs. faction planets

When an alliance owns a planet, the alliance leadership sets:
- The tax rate (within the 25% non-member ceiling)
- Whether tax is owed in FED, ICE, Gold, or a combination
- The grace period before tax collectors are dispatched
- Optional tax exemptions for ranked alliance members (alliance privileges — see [`../social/social_alliance_guild.md`](../social/social_alliance_guild.md))

This is one of the load-bearing reasons alliance leadership matters: an alliance can fund its own treasury by taxing the players living on its planet, and the tax-collector enforcement is what makes the tax actually flow rather than being optional.

---

## 4. Resource Permits

Alliances control territory — specific sectors, asteroid belts, gas clouds. By default, **only alliance members can harvest resources in alliance territory** without consequence. Non-members can be granted access by buying a **Resource Permit** from the alliance.

### Permit structure

A permit is a server-side record:

```
ResourcePermit
  permitId          : string
  issuingAllianceId : string
  holderPlayerId    : string
  sectorIds         : List<string>     // which sectors the permit covers
  resourceScope     : enum { All, MetalsOnly, GasesOnly, SpecificItem }
  expiresUtc        : long
  costPaid          : { currency, amount }
```

### Issuance

- Alliances post permits to the DOM as listings — same mechanics as commodity listings (price, currency, quantity available).
- Buyers purchase like any other DOM transaction.
- Alliance treasury receives the payment; permit is bound to the buyer's playerId and active until expiry.
- Some permits are non-transferable (single-use); some can be resold on a secondary market.

### Enforcement

When a player attempts to harvest resources in an alliance-controlled sector:
1. **Permit check.** Server checks for a valid permit covering this sector + this resource scope.
2. **Member check.** If no permit, server checks whether the player is a member of the controlling alliance.
3. **If neither:** the alliance's standing **patrol fleet** in that sector is alerted. Patrols are scaled to be defeatable but meaningful — a single Frigate poacher can usually outrun them; a fleet of poachers will get a real fight.
4. **Combat:** patrol engages the poacher. If poacher wins, they keep mining (but a stronger patrol may show up later). If patrol wins, poacher loses their cargo + suffers an insurance hit + takes a standing penalty with the alliance.

Players can buy a permit **retroactively** to clear an in-progress violation, at a 2× penalty rate. This is the "I didn't realize this was alliance space, my apologies" path — the alliance gets paid more, the poacher avoids the fight.

### Permit doctrine

- **Permits are a meaningful alliance revenue stream.** A well-controlled alliance with valuable belts can fund its treasury entirely from permit sales.
- **Permits create a "poaching" gameplay loop for Outlaws.** Outlaws who refuse to buy permits face patrol risk every time they mine in alliance space. The risk is the price; some Outlaws prefer fighting patrols to paying alliances.
- **Permits are temporary.** Default 7-day expiry. This creates recurring permit-purchase events, which keeps the alliance economy flowing.
- **Permit pricing is alliance-set.** Alliances compete with each other on permit price to attract miner customers. An alliance pricing permits too high drives miners elsewhere; one pricing too low under-funds its treasury.

---

## 5. NPC Enforcement Doctrine

The three obligation systems above each rely on server-spawned NPC fleets to enforce consequences. There are three distinct enforcement tiers, intentionally non-overlapping:

| Tier | Spawned by | Win condition for player | Scaling |
|---|---|---|---|
| **Patrols** | Alliance / faction standing security in their territory | Defeatable with adequate fleet | Scaled to sector threat level; stronger fleets in higher-value sectors |
| **Tax Collectors** | Planet owner after 2 weeks of unpaid tax | Defeatable but obligation persists; future collectors come stronger | Scaled to tax owed × debt-age multiplier |
| **Default Raid Fleet** | Faction bank after 3 weeks of unpaid loan | **Unwinnable** — scaled to overwhelm any base defense | Scaled to loan balance + always-superior-to-defender bonus |

The unwinnable-default-raid is the keystone. Without it, the loan system becomes a free-money exploit. With it, taking on a loan is a real risk decision — the player is consciously betting that they'll be able to repay, with catastrophic consequences if they can't.

**Lore framing** (non-canon) → [`../lore/lore_world_framing.md`](../lore/lore_world_framing.md#obligation-enforcement--diegetic-framing) — all three tiers are diegetic enforcement, not "the game is mad at you."

---

## 6. Schema sketch

```
PlayerProfile
  ...existing fields...
  reputations  : Dictionary<factionId, int>   // standing per faction / alliance
  loans        : List<Loan>
  permits      : List<ResourcePermit>
  // Planet tax obligations are derived state, computed from base presence; no field.

Loan
  loanId             : string
  lenderFactionId    : string
  principal          : long
  interestRate       : float       // APR, compounds weekly
  originatedUtc      : long
  weeklyPaymentDue   : long
  remainingBalance   : long
  accruedFees        : long
  missedPayments     : int         // 0 / 1 / 2 / 3 → triggers escalation
  status             : enum { Current, Delinquent, Default, Closed }

ResourcePermit
  permitId            : string
  issuingAllianceId   : string
  holderPlayerId      : string
  sectorIds           : List<string>
  resourceScope       : enum { All, MetalsOnly, GasesOnly, SpecificItem }
  expiresUtc          : long
  costPaid            : { currency, amount }
```

CloudScript handlers:
- `LoanApply`, `LoanRepay`, `LoanPrepayFull`
- `TaxPay`, `TaxPrepay`
- `PermitPurchase`, `PermitCheck` (called by harvesting handlers)
- Scheduled job: `WeeklyEconomyTick` — runs auto-debits, applies fees, marks delinquencies, dispatches enforcement fleets at threshold

All currency movements feed the existing currency-state mintings / burnings — late fees burn; payments transfer; raid-fleet collections destroy the player's resources (sink) while the loan principal is marked recovered.

---

## 7. Why this design

- **Faction affiliation becomes a real economic relationship.** FED citizens pay taxes, can borrow, get permits — and bear the cost of breaking faith. Outlaws skip all of it but lose the upside. The choice is meaningful.
- **Recurring obligations create natural rhythms.** Weekly tax + weekly loan payment + recurring permit purchases mean players have *predictable demand* for currency every week, which keeps the DOM markets active even when nothing dramatic is happening.
- **NPC enforcement is the consequence that makes the system real.** Without it, all three mechanics are honor-system suggestions. With it, the obligations bite — and the differing severity (defeatable patrols vs. unwinnable default raids) creates a calibrated risk ladder.
- **Alliance leadership matters mechanically.** Setting tax rates, permit prices, and enforcement strength is the *job* of alliance leadership. A well-run alliance is one that prices these correctly and enforces them consistently; a poorly-run alliance hemorrhages members and treasury.
