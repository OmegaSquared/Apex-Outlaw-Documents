# Player Titles Doctrine — Earned Tags & Identity TDD

This doc owns the **player title system** — earnable tags awarded by gameplay actions that mark a player's reputation, role, and history. Players have a personal collection of every title they've ever earned; one is selectable as the **active title** displayed next to their name across all UI surfaces.

Pairs with [`social_alliance_guild.md`](./social_alliance_guild.md) (alliance ranks, which are orthogonal to titles), [`social_war_doctrine.md`](./social_war_doctrine.md) (the **Warlord** title is canonized there but is a member of this system), and [`../economy/economy_overview.md`](../economy/economy_overview.md) (Forger / Maker titles tie into the Maker's Mark canon).

---

## 0. Design philosophy

Titles are **earned identity markers** that reflect how a player has actually played the game, not how they've been ranked by an algorithm or rewarded by admins. Three principles:

1. **Earned, not bestowed.** Every title is unlocked by a gameplay action / stat threshold. No admin curation. No purchasable titles.
2. **Collected, not consumed.** Players never lose a title they've earned (with one exception — ongoing-decay titles documented below). The collection is a permanent record of "what I've done in this universe."
3. **One active at a time.** Only one title displays next to the player's name publicly. The player chooses which one to fly. This forces self-presentation — what do you want others to know about you?

The system rewards diverse play (collect across categories), signature play (a player known as "Trader" or "Pirate"), and rare achievement (single-shot honorifics like Apex). The active-title slot is the player's *answer* to "who are you in this universe?"

---

## 1. Title catalog

Titles are organized into categories. Most titles are **earnable by anyone** through the relevant gameplay; a few are **rare / one-shot** (Apex, Warlord) that mark exceptional moments.

### 1.1 Combat / PvP

| Title | Earned by |
|---|---|
| **Ace Pilot** | K/D ratio ≥ threshold sustained over N engagements (ongoing) |
| **Warrior** | Cumulative combat engagements ≥ threshold |
| **Sentinel** | Defensive kills (defending fleet / base / planet) ≥ threshold |
| **Hunter** | Bounty contracts completed ≥ threshold |
| **Duelist** | 1v1 victories ≥ threshold |
| **Capital Killer** | Capital-class ships destroyed ≥ threshold |
| **Sniper** | Long-range kills with spinal / missile weapons ≥ threshold |
| **Avenger** | Kills against players who killed your alliance-mates ≥ threshold |
| **Untouchable** | Average ship lifetime ≥ N hours (ongoing) |
| **Survivor** | Lowest deaths-per-engagement ratio (ongoing leaderboard slot) |
| **Berserker** | Multi-kill in single combat instance |

### 1.2 Trade / Economy

| Title | Earned by |
|---|---|
| **Trader** | Total profit from price-arbitrage trades ≥ threshold |
| **Space Trucker** | Cumulative cargo volume transported / hauler contracts ≥ threshold |
| **Magnate** | Top N% of credit accumulation (ongoing leaderboard slot) |
| **Tycoon** | Top market-share holder in a specific commodity (ongoing) |
| **Smuggler** | Successful contraband runs ≥ threshold |
| **Black Marketeer** | High transaction volume on black-market terminals |
| **Profiteer** | Highest per-trade margin recorded |
| **Convoy Captain** | Successful escorted hauls survived vs pirate attacks ≥ threshold |
| **Quartermaster** | Alliance vault contributions ≥ threshold |

### 1.3 Industry / Production

| Title | Earned by |
|---|---|
| **Forger / Maker** | Items forged (ties into Maker's Mark canon — [`../economy/economy_overview.md`](../economy/economy_overview.md)) ≥ threshold |
| **Master Forger** | Number of high-grade items in forge history |
| **Apex** | First-ever Flawless-grade output of a specific resource (one-shot, server-wide event) |
| **Refiner** | Refining throughput ≥ threshold |
| **Engineer** | Recipes mastered ≥ threshold (collection completion) |
| **Industrialist** | Production volume at base facilities ≥ threshold |

### 1.4 Mining

| Title | Earned by |
|---|---|
| **Prospector** | Total resources mined ≥ threshold |
| **Belt Hawk** | Sustained mining volume in specific belts |
| **Driller** | Deep-mining operations (sub-ice oceans, dense asteroids) completed |
| **Mineralogist** | Variety of resources mined (collection completion) |
| **Mother Lode** | First to discover an apex-grade resource at a specific body (rare, per-body unique) |

### 1.5 Research / Exploration

| Title | Earned by |
|---|---|
| **Scholar** *(or "Theorist", "Researcher")* | Alchemy Matrix progression milestones |
| **Scout** | First-to-find a body / anomaly / wreck |
| **Pathfinder** | Jump-gate routes discovered |
| **Cartographer** | Sectors fully mapped (FOW coverage milestones) |
| **Alchemist** | Top tier in Alchemy research |
| **Sage** | Alliance research contributions ≥ threshold |
| **Pioneer** | New planets settled / outposts founded |

### 1.6 Outlaw / Piracy

| Title | Earned by |
|---|---|
| **Marauder** *(or "Raider", "Pirate")* | Piracy events / freighter takedowns |
| **Reaver** | Ships destroyed in raids |
| **Cutthroat** | Assassination contracts completed |
| **Plunderer** | Cargo value stolen ≥ threshold |
| **Black Sail** | Sustained Outlaw faction reputation tier |

### 1.7 Mercenary

| Title | Earned by |
|---|---|
| **Hired Gun** *(or "Soldier of Fortune")* | Mercenary contracts completed |
| **Free Lance** | Service with ≥ N different alliances |
| **Contract Killer** | High-bounty target eliminations |
| **Veteran** | Long active service / battle survival composite |

### 1.8 Alliance / Social / Politics

| Title | Earned by |
|---|---|
| **Warlord** | CEO of alliance that successfully disbanded another (canon: [`social_war_doctrine.md`](./social_war_doctrine.md) §8.2) |
| **Diplomat** | Truces / NAPs / cease-fires negotiated ≥ threshold |
| **Founder** | Started ≥ N alliances |
| **Recruiter** | New players brought into your alliance |
| **Saboteur** | Hacking / intel operations completed |
| **Spymaster** | Hacking-module usage at scale |
| **Whisper** | Successful covert ops (sensor-shielded, undetected) |

### 1.9 Faction Standing

| Title | Earned by |
|---|---|
| **Iron Veteran** | Top tier ICE standing |
| **Federation Hero** | Top tier FED standing |
| **Notorious** | High public bounty placed on YOU by others (ongoing) |
| **Hunted** | Multiple bounties active on your head |

### 1.9.A The Apex Family — server-wide top-warlord titles (transferable + leased)

The **Apex** title family is a special class of titles tied to the alliance currently holding the **#1 spot on the server's killed-alliances leaderboard** (per [`social_war_doctrine.md`](./social_war_doctrine.md) §8). The Apex alliance is "the reigning warlords of the server." Every member of that alliance carries an **Apex-tier title** by virtue of membership.

**Apex titles are temporary and transferable** — they cannot be permanently earned, only **leased** while criteria hold:

1. The player must be an **active member** of the alliance currently holding #1 on the killed-alliances leaderboard.
2. The alliance must continue to hold #1.

When either condition fails — the player leaves the alliance, OR the alliance is dethroned from #1 — the active Apex title is **immediately revoked by the server**. The player can no longer display it.

| Title | Awarded to | Lifecycle |
|---|---|---|
| **Apex Warlord** | CEO / Founder of the #1 alliance | Active while alliance is #1 AND player is CEO |
| **Apex Vanguard** | Vice-CEOs of the #1 alliance | Active while alliance is #1 AND player is Vice-CEO |
| **Apex Outlaw** | Any other Member-rank or above of the #1 alliance — **the game's namesake title** | Active while alliance is #1 AND player is on the roster |

**Apex Outlaw is the namesake title of the game.** The catch-all variant for non-leadership members of the reigning alliance. When the server speaks of "the Apex Outlaws," they mean the members of the alliance currently sitting at the top of the killed-alliances board.

#### Permanent commemoration — the **Former APEX** title

When an active Apex-tier title is stripped (player leaves, or alliance loses #1), the player **instantly and permanently unlocks** the **Former APEX** title (also "Apex Veteran") in their personal collection.

- **Former APEX is a one-shot achievement** in the canonical lifecycle sense (§2.1). Once awarded, it can never be revoked.
- It goes into the player's Title Collection alongside every other title they've earned.
- It can be set as the active title, displaying "⟨Former APEX⟩ PlayerName" — instantly communicating to the server "I once stood at the absolute summit of the PvP hierarchy, even if I'm not there now."
- This bridges the canonical tension between "titles are collected, not consumed" (§0) and the temporary/leased nature of active Apex titles. The crown itself is constantly fought over and transferred; **the prestige of having worn it stays with the player forever.**

This means Apex membership leaves **two parallel marks** on a player's title history:
1. The active Apex title (Warlord / Vanguard / Outlaw) while they're in the reigning alliance — temporary, displayed in the present tense.
2. The permanent **Former APEX** in their collection — historical record of the time when they were Apex, available to display indefinitely.

#### Apex stacking with other titles
Apex titles **stack with** other earned titles in the player's collection. A player can be:
- Apex Warlord (current — reigning CEO) + Warlord (permanent — from past alliance disbands they led)
- Apex Outlaw (current — reigning member) + Trader + Ace Pilot + Forger (cumulative permanents from gameplay)

They can only **display one active title at a time** per §3.1. The player chooses which to fly. Apex titles will typically take precedence in self-presentation since they signal current top-tier status, but a player can choose to fly something else if they want (e.g. flying "Forger" instead of "Apex Outlaw" because they're known as an industrialist first).

### 1.9.B War-derived survivor + conqueror titles

When an alliance is disbanded through mutual war, two complementary commemorative titles are awarded:

| Title | Awarded to | Lifecycle |
|---|---|---|
| **Survivor of [TAG]** | Every roster member of an alliance whose tag has been retired through disband. The [TAG] is the dead alliance's tag (carved permanently into the title's display name). | Permanent — players carry their dead alliance's name with them as a badge of having survived its end. One per disband event, accumulates if a player survives multiple. |
| **Conqueror of [TAG]** | Every Member-rank-or-above of the alliance that successfully executed the disband. Distinct from the CEO-only **Warlord** title — this is the broader participation honor. | Permanent — each war's victors carry the dead alliance's tag as their trophy. Accumulates across kills. |

These titles **turn surviving players into walking extensions of the Memorial Wall** (per [`social_war_doctrine.md`](./social_war_doctrine.md) §8.1). The wall records the dead alliance; the players carry the dead alliance's tag personally — either as Survivor (you outlived it) or Conqueror (you killed it).

#### Title-text examples
- Player Vex was in the dead alliance "DAWN" — earns **Survivor of DAWN**, displayable forever.
- Player Sera was in the killing alliance — earns **Conqueror of DAWN**, displayable forever.
- A player who's been on both sides of multiple wars might display **Conqueror of DAWN** today, **Survivor of RAVENS** tomorrow.

Format placeholder: ⟨Survivor of DAWN⟩, ⟨Conqueror of DAWN⟩ — exact glyph / styling is UI authoring detail.

### 1.10 Exploration / Frontier

| Title | Earned by |
|---|---|
| **Frontiersman** | Activity in deep outer system (post-frost-line zone) |
| **Wanderer** | Visited N% of system bodies |
| **Vanguard** | First to enter newly-opened region (e.g. a new system at launch) |
| **Castaway** | Survived stranded / shipwreck events |

### 1.11 Salvage / Wreckage

| Title | Earned by |
|---|---|
| **Salvor** | Volume of wreck-loot recovered |
| **Wreckmaster** | Largest single salvage haul |
| **Boneyard Crew** | Time spent in the Fleet Graveyard *(promotes from [`../world/future_ideas.md`](../world/future_ideas.md) when Fleet Graveyard lands)* |

### 1.12 Legacy / Meta

| Title | Earned by |
|---|---|
| **Living Legend** | Composite stat — combined top-tier in multiple categories |
| **Survivor** | Oldest active character on the server |
| **Pacifist** | Zero kills + high economic activity (ongoing) |
| **Iron Will** | Returned to active play after a long inactivity period ("comeback player") |

---

## 2. Earning mechanics

### 2.1 Title states

Each title falls into one of three lifecycle states:

| State | Behavior |
|---|---|
| **One-shot achievement** | Awarded when criteria first met, **permanent**, never revoked. Example: Apex (first-ever Flawless of a resource), Warlord (disbanded an alliance), Vanguard (first to enter new region). |
| **Cumulative threshold** | Awarded when a counter crosses a threshold, **permanent** once unlocked. Example: Warrior (combat engagements), Trader (profit total), Prospector (resources mined). |
| **Ongoing / leaderboard** | Held while criteria remain true; **can drop off** if stats slip. Example: Ace Pilot (K/D ratio), Magnate (credit leaderboard rank), Pacifist (zero kills). |

### 2.2 Ongoing titles + decay
Some titles reflect *current* state, not lifetime achievement. These can be **lost** when stats slip:

- **Ace Pilot** — K/D below threshold strips the title.
- **Pacifist** — first kill strips the title.
- **Magnate / Tycoon** — falling out of the leaderboard slot strips the title.
- **Survivor** (oldest character) — automatically transfers to whoever currently holds the slot.

For these, the player's collection retains a **historical record** ("Held Ace Pilot from 2026-05-04 to 2026-08-12") — they earned it for that period, even after losing the active flag.

### 2.3 Cumulative titles + tiers
Some cumulative titles have **tiered variants** based on counter depth:

- **Warlord (1 kill)** → **Warlord (3 kills)** → **Warlord (10 kills)** — same title, counter exposed in display.
- **Trader** → **Master Trader** → **Grand Trader** at higher thresholds.
- Tier names are TBD per category.

### 2.4 Mutual exclusion
Some title pairs cannot coexist as **earned**:

- **Pacifist** and **Warrior** — earning Warrior auto-clears Pacifist from collection. Earning Pacifist again later requires re-meeting its criteria with zero kills since the strip.
- **Federation Hero** and **Apex Outlaw** at the same time — faction-standing exclusion. You can't be top-tier both.

Most title pairs are **non-exclusive** — you can be Trader AND Warrior AND Scholar simultaneously.

---

## 3. Display rules

### 3.1 Active title (the one displayed publicly)
- Each player has **one active title slot**.
- Active title appears as a **prefix** next to the player's name across all UI surfaces:
  - Chat handles (Global / Sector / Planet / Alliance chat)
  - Fleet roster
  - Alliance member list
  - Combat logs and damage notifications
  - Market listings (seller name)
  - Profile cards
- Format placeholder: **"⟨Title⟩ PlayerName"** — e.g. "⟨Warlord⟩ Vex", "⟨Ace Pilot⟩ Sera". Specific glyph / color treatment is UI authoring detail.
- Player selects the active title from their earned collection. Can change anytime — no cooldown.
- **No title** is also valid — a player can fly with no active title (just their name). Default state for new players who haven't earned anything yet.

### 3.2 Title collection (private profile, public view)
- Player's profile shows their **full earned collection** with dates earned.
- Other players viewing your profile see all your earned titles, not just the active one. The active one is highlighted.
- Collection is **public information** — anyone can see what you've earned. Privacy of stats themselves (per-title detailed counters like exact kill count) is a separate question — see §6.

### 3.3 Display rules for special titles
- **Warlord** has its own display contract per [`social_war_doctrine.md`](./social_war_doctrine.md) §8.2 — it can be the active title OR shown alongside (TBD UX decision in §6).
- **Apex** is similarly special — first-ever Flawless of a resource is a server-wide event, possibly with broader recognition than just a prefix tag. Could pin to the player's profile permanently.

---

## 4. Faction-coded variants (open design)

Some titles could have **faction-flavored variants** based on the player's standing or alliance affiliation:

- **Federation Trader** / **Iron Trader** / **Outlaw Trader** — Trader title carries a faction tilt based on where the trader does most of their business.
- **Federation Warlord** / **Iron Warlord** / **Outlaw Warlord** — Warlord variants per the conqueror's faction alignment.

Pros: lore flavor, faction loyalty signaling, makes the title feel different across players.
Cons: triples the number of title states, complicates the UI, raises balance questions (does an "Iron Trader" carry different in-game perks than a "Federation Trader"?).

**Default for v1: no faction variants.** Titles are faction-neutral. Faction-coded variants are a stretch goal — see §6 open questions.

---

## 5. Schemas

### 5.1 PlayerProfile additions
```
titles: List<TitleRecord>           // collection of every title earned
activeTitleId: string?              // currently displayed title (null = no title shown)
```

### 5.2 TitleRecord
```
TitleRecord {
  titleId: string                   // canonical id, e.g. "trader" / "ace_pilot" / "warlord"
  awardedAtUtc: string              // when first earned
  currentTier: int                  // 1, 2, 3... for tiered titles (Warlord 1 = 1 kill, Warlord 3 = 3 kills)
  isActive: bool                    // true while criteria remain met (relevant for ongoing titles)
  lostAtUtc: string?                // populated when an ongoing title is lost; null while active
  history: List<TitleEvent>         // detailed earn / lose / re-earn log
}

TitleEvent {
  eventType: "Awarded" | "Lost" | "TierUp" | "Reawarded"
  atUtc: string
  tier: int                         // tier at the time of the event
  context: string                   // optional metadata (war id for Warlord, resource for Apex, etc.)
}
```

### 5.3 Apex alliance tracking (server-side, dynamic)
```
ApexAllianceState {
  currentApexAllianceId: string?    // alliance holding #1 on killed-alliances board
  apexHeldSinceUtc: string?         // when the current Apex alliance took the crown
  apexHistory: List<ApexHolderRecord>  // every alliance that has ever held Apex
}

ApexHolderRecord {
  allianceId: string
  allianceTag: string               // captured at award time
  heldFromUtc: string
  heldUntilUtc: string?             // null while currently Apex
  killedAlliancesCountAtAward: int  // their kill count when they took the crown
}
```
Server recomputes the Apex holder whenever any alliance's killed-alliances counter increments. If the increment pushes them past the current holder, the Apex flag transfers. Stripping + re-granting Apex titles to roster members happens server-side via CloudScript on the transfer event.

### 5.4 Memorial Wall inscription
```
MemorialWallEntry {
  warId: string                     // FK → AllianceWarRecord
  defeatedAllianceTag: string       // permanent — the dead tag
  victorAllianceTag: string         // permanent — the killer's tag at time of kill
  inscribedAtUtc: string
  defeatedMemberCountAtDisband: int
  inscriptionText: string           // pre-rendered: "[Defeated Tag] — Destroyed by [Victor Tag] on [Date] (Member Count: N)"
}
```
The wall is stored as a list of these entries, sorted chronologically. Visible in the in-world Memorial Wall UI at faction capitals.

### 5.5 Title catalog (server-side, static)
```
TitleDefinition {
  id: string
  displayName: string
  category: enum                    // Combat | Trade | Industry | Mining | Research | Outlaw | Mercenary | Alliance | Faction | Exploration | Salvage | Legacy
  description: string               // human-readable earning criteria
  lifecycle: "OneShot" | "Cumulative" | "Ongoing"
  tiers: List<TierThreshold>?       // only for tiered titles
  exclusiveWith: List<string>?      // titles that auto-strip when this is earned
  evaluator: string                 // server-side evaluator function id (TBD per title)
}

TierThreshold {
  tier: int
  threshold: int | float            // counter value required
  displayName: string               // optional tier-specific name e.g. "Master Trader"
}
```

The catalog ships as PlayFab title-data; player records reference catalog ids. Evaluation logic lives in CloudScript handlers triggered by relevant game events (combat resolution, trade completion, etc.).

---

## 6. Open design questions

1. **Title decay thresholds.** What's the exact K/D ratio for Ace Pilot? How many combat engagements for Warrior? Each title needs a tunable threshold — the catalog defines these.
2. **Tier ladder per cumulative title.** Most cumulative titles probably want 3 tiers (e.g. Trader / Master Trader / Grand Trader). Specific thresholds TBD.
3. **Ongoing leaderboard slot count.** "Survivor" (oldest character) is one slot. Is Magnate one slot or top-10? Affects how exclusive the title feels.
4. **Privacy of underlying stats.** Earning Trader requires a profit threshold — is the exact profit number public to other players viewing your profile, or just the title? Could matter for griefing (high credit balance attracts hunters).
5. **Faction-coded variants** (per §4). Ship v1 with neutral titles only, or invest in faction variants from launch?
6. **Warlord display interaction.** Should Warlord override the active title slot (always shown), share the slot, or be a *second* prefix slot? UX call.
7. **Apex display.** Same question — Apex is server-event-rare. Profile pin, active prefix override, or normal title?
8. **Title visibility in combat logs.** When a damage event fires, do we render "⟨Warrior⟩ Vex" or just "Vex" in the floating combat text? Active titles in logs add lore + recognition but spam the screen.
9. **Renaming titles per design feedback.** "Pirate" → "Marauder" / "Raider" — pick the canonical Latin-flavored name set. (Aaron's instinct: lean Latin where possible to match the body-naming canon.)
10. **Title collection cap.** Should there be a maximum collection size, or unlimited? Unlimited is cleanest; cap forces hard choices.
11. **Cross-server title persistence.** If Apex Outlaw eventually runs multiple shards / servers, do titles travel with the player, or are they per-server?
12. **Auto-grant for legacy players** if titles ship after launch. Players who already passed thresholds before titles existed — retroactive award based on existing stats? Or only forward-looking?
13. **Apex rank coverage.** Currently three rank-tier variants: Apex Warlord (CEO), Apex Vanguard (Vice-CEO), Apex Outlaw (Member+). Should Officer / Director / Squad Captain rank variants exist too (e.g. "Apex Officer", "Apex Director", "Apex Captain"), or stays as the three? Adds vocabulary but multiplies the title set.
14. **Tied Apex alliances.** If two alliances are tied at the same killed-alliances count, who's #1? First to reach the count? Most recent kill? Both hold Apex simultaneously? Affects how the "reigning" alliance is rendered.
15. **Apex revoke timing.** Is the active Apex title stripped instantly when the player leaves the alliance, or with a grace period (e.g. 24h)? Instant is cleaner but feels punitive if a player is briefly switching alliances during a leadership transition.
16. **Survivor / Conqueror eligibility.** What's the minimum tenure in an alliance before its disband qualifies you for "Survivor of [TAG]" or "Conqueror of [TAG]"? Otherwise people could join an alliance the day before a war ends and collect titles cheaply.
17. **Display naming of war-derived titles.** "Survivor of DAWN" / "Conqueror of DAWN" — does the [TAG] always appear in the displayed title text? Or just in the underlying record (display shows "Survivor", hovering shows the TAG)? Affects screen real estate.
18. **Apex history visibility.** Is the full `apexHistory` list public (any player can see "DAWN was Apex from 2026-05-04 to 2026-08-12, then displaced by RAVENS"), or alliance-restricted?

---

## 7. Where this fits in the build order

Title doctrine depends on the underlying stats systems being in place:

- **Combat resolution** ([`../combat/combat_overview.md`](../combat/combat_overview.md), Phase 4) → K/D, kill counts, ship-class kill tracking.
- **Economy** ([`../economy/economy_overview.md`](../economy/economy_overview.md), Phase 5) → trade profit, market-share, smuggling.
- **Alliance system** ([`social_alliance_guild.md`](./social_alliance_guild.md), Phase 5.3) → Founder, Recruiter, Quartermaster.
- **War doctrine** ([`social_war_doctrine.md`](./social_war_doctrine.md), Phase 6.x) → Warlord (already canonized there).
- **Hacking / intel** ([`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) Hacking chain, Phase 5+) → Saboteur, Spymaster, Whisper.
- **Mining** ([`../economy/economy_scanning_extraction.md`](../economy/economy_scanning_extraction.md), Phase 3) → Prospector, Belt Hawk, Mineralogist.

The doc captures the design now so each subsystem can wire title evaluators as it ships. Title catalog can launch incrementally — early titles (Trader, Warrior, Prospector) ship with their underlying systems; later titles (Whisper, Warlord) wait for their dependencies.

---

## 8. Why this design (recap)

1. **Earned identity** — players define themselves by what they've actually done, not what they've bought or been gifted.
2. **Permanent collection** — a player's title history is part of their character's biography.
3. **One active slot** — forces self-presentation. The player's chosen face to the world.
4. **Diverse play rewarded** — collecting across categories is encouraged but not required. A specialist can fly one signature title; a generalist can collect dozens and pick situationally.
5. **Rare titles carry weight** — Apex, Warlord, first-ever Flawless of a resource — these become whispered legends among players.

Titles are the **personality layer** of Apex Outlaw player identity, sitting alongside ranks (organizational) and faction standing (political). Three orthogonal axes that make every player legible to every other player at a glance.
