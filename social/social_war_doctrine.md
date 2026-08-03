# Alliance War Doctrine — Mutual War & Permadeath TDD

This doc owns the **formal alliance warfare system**: how wars start, how they escalate, how they end, and what happens when an alliance dies. The keystone mechanic that makes Apex Outlaw a real war game: **alliance tags can be permanently retired** through declared mutual war that runs to its conclusion.

Pairs with [`social_alliance_guild.md`](./social_alliance_guild.md) (alliance structure + ranks), [`../world/world_territory_bubbles.md`](../world/world_territory_bubbles.md) (territory ownership), and [`../combat/combat_overview.md`](../combat/combat_overview.md) (combat mechanics).

---

## 0. Design philosophy — why alliance mortality matters

In any alliance-vs-alliance sandbox, alliances need **mortality** for the game to feel like a real war game. If alliances are infinitely respawnable they're just brand names; if they can DIE then alliance identity carries weight. Apex Outlaw's war doctrine is built around this single thesis:

1. **Tag retirement is permanent.** A dead alliance's tag is gone from the server forever. No one can ever adopt it again. Names die.
2. **Mortality requires mutual consent.** Permadeath can never be triggered against an alliance that didn't accept the war. The mutual-declaration gate prevents grief-permadeath by large alliances against small ones.
3. **Wars escalate organically.** Multiple off-ramps exist (surrender / cease-fire / reparations), but abuse of cease-fires triggers escalation that closes the off-ramps. Eventually, one side either accepts losing or fights to disband.
4. **Killed alliances become reputation.** A public counter tracks "alliances retired by your alliance." Top killers become server-recognized warlords. Reputation is *earned*, not awarded.

The system rewards committed wars and punishes manipulation. Most wars end in negotiation; the wars that end in permadeath are the ones that truly went to the wall.

---

## 1. War declaration — private marking + mutual consent

War starts with **private alliance-on-alliance marking**, not a public broadcast.

### 1.1 Marking is a one-sided private flag
Any alliance with **wardec authority** (Diplomatic Director or higher, per [`social_alliance_guild.md`](./social_alliance_guild.md) §2.2) can privately mark another alliance as an enemy.

- The marked alliance shows up **RED in the marking alliance's HUD and scanners** — visual differentiation only.
- **The marked alliance is NOT notified** that they've been marked. Discovery happens through gameplay (you notice the other side's UI is showing you red, or you compare notes with allies).
- One-sided marking carries **no game consequence** by itself. No territory effects, no permadeath risk, no PvP rules change.
- Marking can be **withdrawn at any time**. Drops the alliance back to neutral display.

### 1.2 Mutual marking activates formal war
**When BOTH alliances have privately marked each other**, the formal war progression begins. This is the consent gate — both sides agreed.

- Trigger: server-side check fires when alliance B's marking of A is detected while A's marking of B is already active.
- On activation: war state becomes "active" for both alliances. The previous private flags formally bind.
- The system can choose to announce activation to both alliance leaderships (open design question — see §12).

### 1.3 Withdrawal during active war
Either side can **un-mark** the other during an active war. This drops the formal war back to a one-sided private flag on the OTHER side (if still active).

- Withdrawal is **not a free escape** — it's a unilateral pull-back. The other side can immediately re-mark, restoring war state.
- But withdrawal CAN end a war if the other side doesn't re-engage. Useful for "we don't want this fight anymore" exits when the other side is open to it.

---

## 2. War duration — no clock

**Wars do not expire on a timer.** Once mutual war is active, it lasts until one of these conditions ends it:

| Exit condition | Outcome |
|---|---|
| Losing side accepts a **truce / surrender** | Tag preserved (with terms — see §4) |
| Both sides agree to **mutual cease-fire** | Tag preserved on both sides, no winner |
| Losing side pays **reparations** | Tag preserved, alliance publicly weakened |
| One side meets **disband conditions** | Losing tag retired forever (see §6) |
| One side **withdraws their marking** | War drops back to one-sided flag |

Wars are open-ended by design. Aggressors choose the pace; defenders choose whether to engage. No game-imposed deadline pushes either side into rash action.

---

## 3. War Council Chat — leadership negotiation channel

When mutual war activates (§1.2), the system **spawns a private chat channel between the leadership of the two warring alliances**. This is the canonical place where truces, cease-fires, surrenders, reparations terms, and any other diplomatic move get hashed out.

### 3.1 When the channel exists
- Created automatically the moment mutual marking completes (war state becomes "active").
- Persists for the entire duration of the war, across both Phase 1 and Phase 2.
- Destroyed when the war ends — by truce / surrender / cease-fire / reparations / disband / withdrawal. Channel history is archived to the war record for post-war reference (audit trail, lore residue) but the live channel is closed.

### 3.2 Who's in it
Restricted to **leadership-tier ranks** on both alliances. Default membership:
- **CEO / Founder** of each alliance
- **Vice-CEOs** of each alliance (up to 3 per side)
- **Diplomatic Director** of each alliance (per [`social_alliance_guild.md`](./social_alliance_guild.md) §2.2 — diplomacy is their explicit portfolio)

Lower ranks (Squad Captains, Officers, Members) do **not** see the channel and cannot participate. This is intentional — diplomatic chatter has to stay at the level that can actually commit the alliance to terms. If a rogue Officer were on the channel, opposing leadership couldn't trust any message as binding.

CEO can grant temporary access to other ranks per-war via the `customPermissions` override (e.g. "trusted member acts as scribe / translator / observer"), but the formal **proposal authority** stays gated at CEO + Vice-CEO + Diplomatic Director.

### 3.3 What it's used for
The channel is both a free-form chat AND the host for **formal proposals**:

- **Free-form chat** — leadership of both sides can talk directly. Negotiate, threaten, posture, exchange intel, set up battles. This is the "smoke-filled room" of the war.
- **Formal proposals** — inline UI affordance lets a leader build and submit:
  - **Cease-fire proposal** (Phase 1 only — gone in Phase 2)
  - **Surrender proposal** — proposer offers / demands terms
  - **Reparations proposal** — proposer offers payment in exchange for war end
  - **Withdrawal notice** — one side announcing they're un-marking (formal courtesy, not strictly required)
- Each formal proposal is **acceptance-gated**: the receiving side must explicitly accept via the chat UI. Server validates authority (rank check) on accept.
- All proposals + acceptances + rejections are logged to the war record (§11.1 in the schemas section).

### 3.4 Privacy + persistence
- Channel is **completely private** to the participating leadership. The broader server, faction NPCs, and other alliances see nothing of the content.
- Messages persist for the war's duration. After the war ends, the full transcript is archived to the war record (read-only for that war's participants, optionally readable for historical research / lore).
- Members of either alliance who are not in the channel can see only the *outcome* of formal proposals (e.g. their alliance's info panel shows "Surrender offer pending from [enemy] — terms: X" if leadership chooses to broadcast it; otherwise members see only the war's high-level state).

### 3.5 Why this exists (design intent)
Without a dedicated leadership channel, negotiations would happen in Discord / external channels that the game system can't track. That would mean:
- No audit trail of what was offered and refused
- No formal proposal mechanism — terms have to be verbally re-typed and manually enacted
- No way for the server to validate that a "surrender" was actually offered by an authorized rank

The War Council Chat solves all three. It's the **formal diplomatic surface** of the war. Discord stays useful for general alliance chatter, but the binding negotiations live where the server can see them.

### 3.6 Open design notes (collected in §12)
- Should reading the chat transcript post-war be public, or restricted to participants? Affects lore residue value vs. privacy.
- Cross-language / translation support — international alliances likely speak different primary languages. UI consideration, not core mechanic.
- Should formal proposals carry an expiration timer (e.g. "this offer expires in 24h")? Or are they all open-ended until accepted / rejected / withdrawn?

---

## 4. Phase 1 — Normal war (all truce paths open)

In a freshly-declared mutual war, all off-ramps are available.

### 3.1 Surrender
Losing side accepts terms set by the winner. Tag preserved.

- Winning alliance proposes the terms (territory concessions, currency reparations, alliance demotion in standing, trade restrictions, etc.).
- Losing alliance accepts or rejects. Acceptance ends the war.
- Surrender terms can be **publicly visible** (alliance now lives under those terms — flagged in their info panel) for the duration agreed.

### 3.2 Mutual cease-fire
Both sides agree to stop fighting. No winner declared, no reparations. Tag preserved on both sides.

- Either side can propose a cease-fire; the other can accept.
- Cease-fire ends the formal war state. War-related effects (red display, war-stat tracking, sanctioned PvP zones) clear.

### 3.3 Reparations
Losing side **voluntarily** pays a negotiated cost in exchange for war ending. Tag preserved.

- Difference from surrender: losing side initiates, not winner. Useful when you're losing and want to end this before it gets worse.
- Payment can be currency, modules, territory, or any combination.

### 3.4 Cease-fire fragility (the abuse-prevention layer)
A cease-fire is **broken the moment any player from one side attacks any player from the other side.** Active war state resumes immediately.

- The system tracks every cease-fire violation against the offending alliance on a public **broken-cease-fire counter**.
- Counter is visible in the war info panel — accountability for who violated and how many times.
- A single accidental attack by a rogue member breaks the cease-fire. Alliance leadership has to control their roster, or the cease-fire breaks. This is intentional pressure to maintain discipline.

---

## 5. Phase 2 — Escalated war (after N broken cease-fires)

When the broken-cease-fire counter passes a threshold (TBD — likely **2 or 3**), the war **escalates**. Specific truce paths close.

### 4.1 What changes at escalation
- **No more cease-fires allowed.** The "we both walk away clean" path is permanently closed for this war.
- **Surrender + reparations remain available — but one side MUST formally accept losing.** Both-sides-walk-away outcomes are gone. Someone takes a hit.

### 4.2 Why escalation exists
Phase 1 prevents the "every war becomes permadeath" gameplay collapse. Phase 2 prevents the "we abuse cease-fires under truce flag forever" credibility collapse. The threshold catches alliances that game the cease-fire system and pushes them onto a one-way ramp toward consequence.

### 4.3 Phase 2 resolution paths
Three exits exist in Phase 2:

1. **Side A formally accepts losing terms** → War ends. Side A's tag preserved but weakened. Side B counted as victor.
2. **Side B formally accepts losing terms** → Same, roles reversed.
3. **Neither side accepts losing** → War continues until **disband conditions** are met (§6). One tag will die.

There is no other exit from Phase 2. **Escalated wars resolve in tag retirement when no side accepts losing.**

---

## 6. Disband conditions — the victory criteria for permadeath

Disband is the formal trigger that retires a losing alliance's tag forever. It requires **both** of the following simultaneously:

### 6.1 All defenses destroyed
Every alliance-owned defensive structure must be wreckage at the moment of disband evaluation:
- Defense platforms (Planetary Defense Alpha/Beta — per [`../lore/lore_story_bible.md`](../lore/lore_story_bible.md) §4.2)
- Fortified citadels and citadel anchors
- Planet-control infrastructure (Stat Cons, military outposts)
- Per the territory bubbles canon ([`../world/world_territory_bubbles.md`](../world/world_territory_bubbles.md)), every anchor that contributes to the losing alliance's territory must be destroyed.

### 6.2 Simultaneous member bubbling
Every **active** alliance member's fleet must be defeated in combat within a coordinated window:
- "Active" definition: TBD (likely "logged in within last 24h" or "last 7d" — open design question §12).
- "Bubbled" definition: fleet's primary combat ship destroyed or crippled to non-combat state, per the combat resolution canon in [`../combat/combat_overview.md`](../combat/combat_overview.md).
- "Coordinated window": all defeats must occur within a short timeframe (TBD — likely 30–60 minutes) to count as simultaneous.

### 6.3 Why this is hard
The simultaneity requirement is the design lever. It's the difference between "we slowly whittle them down" (which doesn't trigger disband) and "we wage a coordinated total assault" (which does). A large alliance cannot trivially permadeath a small one without committing real coordinated effort.

This filters disband events to genuine *wars of annihilation*, not casual grinding.

---

## 7. Tag retirement — what happens when disband triggers

When disband conditions are met:

1. **Server records the kill.** Winning alliance's "killed alliances" counter increments (§8). Public event broadcast to the server.
2. **Losing tag retired permanently.** No new alliance can ever adopt that exact tag again. Server-side validation rejects re-registration of retired tags.
3. **Alliance roster dissolves.** Member records are flagged as "ex-[TAG]" — they retain personal history of having been in that alliance, but lose alliance affiliation.
4. **Alliance-tier assets dissolve.** Shared vaults, alliance research, citadel claims, faction-claim status, treasury, audit logs — all alliance-owned resources are destroyed or transferred per the disband rules (TBD per §12 — who gets what).
5. **Members keep personal property.** Individual inventory, bespoke gear, bank holdings, ship records, personal standing — all preserved at the member level.

The former members can re-form as a new alliance under a different tag immediately. But the dead tag is dead.

---

## 8. The "killed alliances" counter — reputation as emergent property

Every alliance carries a **public killed-alliances stat**: count of tags the alliance has retired through war victories.

- **Server-wide leaderboard** of top killers (TBD format — could be alliance info card, faction registry, or dedicated UI surface).
- **Per-kill record** shows the dead alliance's name + date + member count at time of disband. Permanent record.
- **Reputation marker** — alliances with high kill counts become recognized warlords. Their wardec carries weight just by virtue of who's making it.

The kill counter is **earned reputation, not bestowed**. No admin curation. Top alliances are the ones who've actually fought wars to conclusion.

### 8.1 Memorial Wall (lore + UI)

A physical in-world Memorial Wall stands in each faction's capital, inscribed with the names of every alliance that has died in mutual war. Players can physically visit the wall — it's "visitable lore residue."

**Inscription format.** Each entry on the wall lists **both the fallen alliance AND the alliance that killed them.** The wall isn't just a graveyard; it's a public, in-world manifestation of the killed-alliances leaderboard (§8). The carved entry reads:

> **[Defeated Tag]** — Destroyed by **[Victor Tag]** on [Date] (Member Count: N)

Why both tags. A new player walking up to the wall and seeing the same Victor Tag carved into stone over and over instantly understands why that alliance holds the server's top Warlord standing — no UI menu required. The wall becomes a physical record of the server's biggest rivalries and conquests, not just a list of casualties.

Visiting the wall is the most authentic way to research enemy alliances' kill histories. Combined with the Warlord title prefix on individual players (§8.2), the disband event leaves both an **alliance-level grave** (the wall) and a **player-level brand** (Warlord title) — two parallel reputation surfaces fed by the same canonical disband record.

Access permission is still an open design call (§12 #12): public to all players, alliance-leadership-only, or admin-curated.

### 8.2 Warlord title (personal honorific for the conquering CEO)

When an alliance successfully disbands another alliance through the war doctrine, the **CEO/Founder of the winning alliance at the moment of disband** receives the permanent personal title **Warlord**.

- **Awarded to the individual, not the alliance.** The CEO at the time of disband owns this title forever. It travels with them even if they later leave the alliance, transfer Founder status, or join a different alliance.
- **Permanent.** Cannot be revoked, expired, or lost. Once awarded, it's part of that player's identity for the lifetime of their account.
- **Display.** Appears as a prefix on the player's name across all UI surfaces — alliance roster, chat handles, combat logs, leaderboards. Format placeholder: **"Warlord [Name]"** or similar (UI authoring detail).
- **Stacks via counter, not multiple titles.** A player who has personally disbanded multiple alliances doesn't accumulate multiple "Warlord" titles — they have **one** title, but their personal kill record shows the number of alliances they've personally killed (`personalAlliancesKilledCount`). UI can show "Warlord [Name] (3 kills)" or similar for high-kill warlords.
- **Only the CEO at the moment of disband.** Vice-CEOs and Directors who participated in the war effort do NOT get the title. The honor is for the leader who took the alliance to its definitive victory — the buck-stops-here recognition. (Open design call — see §12: should Vice-CEOs get a lesser title like "Warlord's Voice" or similar? Currently a no.)
- **Cross-alliance discoverability.** Other players seeing a Warlord prefix in chat / combat / market listings know they're dealing with someone who's personally conquered an alliance. Operational reputation marker.
- **Lore framing** (non-canon) → [`../lore/lore_world_framing.md`](../lore/lore_world_framing.md#warlord-title--formal-registration) — formal Warlord registration + possible faction-tinted variants.

The Warlord title makes the disband event meaningful at the **individual level**, not just the alliance level. A player who has been part of an alliance that killed another alliance has done something the broader server formally recognizes. **Killed alliances** is alliance reputation; **Warlord** is the CEO's personal reputation.

---

## 9. Member relocation — what happens to survivors

**Relocation is a CONSEQUENCE of disband, not an alternative path.** There is no "we'll relocate to save ourselves" option — that's what truce paths (surrender / cease-fire / reparations) are for.

When disband completes:

- Every surviving member is **randomized and spread out** across non-alliance-held planets in Helion (and future systems).
- Distribution is **server-side, individual, not as a group.** Members get scattered.
- Each member keeps personal inventory, bespoke gear, bank holdings.
- The forced individual dispersal prevents same-day regrouping under a new tag at the same location. Members have to find each other again.
- **Anonymity preserved.** The destroying alliance does not get a map of where the dispersed members went. Server randomization is opaque from the outside.

---

## 10. Bystanders + NPC factions

### 10.1 Player alliances NOT involved in the war
- Bystander alliances near combat zones don't get pulled in automatically.
- If a bystander attacks one of the warring sides, that's a separate aggression event — could trigger normal PvP / faction-patrol consequences, or could be the start of a NEW war declaration cycle.
- **Sanctioned PvP zones during active war** — TBD (open design question §12). Are the warring alliances' high-sec restrictions lifted versus each other? Currently FED Police break up unprovoked aggression in high-sec; war declarations probably override that, at least between the warring parties.

### 10.2 AI factions (FED, ICE)
- AI factions (FED, ICE) **cannot have their tags retired**. Per existing canon ([`../lore/lore_story_bible.md`](../lore/lore_story_bible.md) §4.3), defeated faction NPC bases respawn elsewhere in Helion — the faction itself never dies.
- A player alliance CAN go to war with FED or ICE in the broader gameplay sense, but the formal mutual-war-permadeath mechanic is **player-alliance-only**.
- AI factions instead use the existing **respawn-elsewhere** doctrine when their assets are destroyed (Phase 5.5.6 in [`../meta/master_to_do.md`](../meta/master_to_do.md)).

### 10.3 NAP / Blue-list interactions
- Existing NAP / Blue-list system (per [`social_alliance_guild.md`](./social_alliance_guild.md) §4) gates wardecs with a 7-day cooling-off period for NAP partners. **NAP partners cannot be privately marked** until the cool-off completes.
- Blue-list partners can be marked but the marker auto-prompts a "Are you sure? This breaks Blue-list" confirmation.

---

## 11. Schemas — sketch

### 11.1 War state record
```
AllianceWarRecord {
  warId: string                    // server-generated unique id
  aggressorAllianceId: string      // alliance that marked first
  defenderAllianceId: string       // alliance that mutually accepted
  declaredAtUtc: string            // when mutual marking completed
  phase: "Phase1" | "Phase2"       // escalation state
  brokenCeasefireCount: int        // tally for Phase 2 trigger
  brokenCeasefireEvents: List<CeasefireViolation>  // detailed log
  pendingProposals: List<Proposal>  // surrender / cease-fire / reparations
  endedAtUtc: string?              // null while active
  endReason: enum?                 // Surrender | Ceasefire | Reparations | Disband | Withdrawal
  victoriousAllianceId: string?    // populated on Surrender / Reparations / Disband
  defeatedAllianceId: string?      // populated on Surrender / Reparations / Disband
}
```

### 11.2 Alliance markings
```
AllianceMarking {
  markingAllianceId: string
  markedAllianceId: string
  markedAtUtc: string
  markedByPlayerId: string         // for audit
  withdrawnAtUtc: string?          // null while active
}
```
A row exists for every alliance-on-alliance marking. Two reciprocal rows = mutual war.

### 11.3 Retired tags (server-wide registry)
```
RetiredAllianceTag {
  tag: string                      // the dead tag (e.g. "DAWN", "REPER")
  retiredAtUtc: string
  retiredByWarId: string
  retiredByAllianceId: string      // the killer
  retiredAllianceFinalMemberCount: int
  retiredAllianceFoundedAtUtc: string
  retiredAllianceFinalTerritoryCount: int  // bodies controlled at time of disband
}
```
PlayFab title-data; checked on every new alliance creation to reject tag re-use.

### 11.4 Killed-alliances counter (on AllianceRecord)
```
killedAlliancesCount: int          // running total
killedAlliancesLog: List<KillRecord>  // detailed kill history
```

### 11.5 Warlord title (on PlayerProfile)
```
isWarlord: bool                      // permanent flag — true once awarded, never cleared
firstWarlordAwardedAtUtc: string?    // when the first kill happened
warlordAwards: List<WarlordAward>    // detailed kill history attributed to this player
personalAlliancesKilledCount: int    // length of warlordAwards, exposed as a UI counter
}

WarlordAward {
  warId: string                      // FK → AllianceWarRecord
  conqueredAllianceId: string
  conqueredAllianceTag: string       // captured at time of award (in case tag stays retired)
  awardedAtUtc: string
  allianceLedAtTime: string          // which alliance the player was CEO of when the disband fired
}
```
A player gets `isWarlord = true` the first time a `WarlordAward` lands on their profile, and stays Warlord forever after. The list of `warlordAwards` is the kill history; the title display can render "Warlord [Name]" or "Warlord [Name] ([n] kills)" depending on UI choice.

### 11.6 War Council Chat record
```
WarCouncilChat {
  warId: string                    // FK → AllianceWarRecord
  channelId: string                // Photon Chat channel id (or equivalent)
  participants: List<ParticipantBinding>  // playerId → { allianceId, rank, joinedAtUtc, leftAtUtc? }
  messageLog: List<ChatMessage>    // append-only; survives war end as archive
  formalProposalLog: List<Proposal>  // mirror of pendingProposals on AllianceWarRecord
  createdAtUtc: string
  archivedAtUtc: string?           // populated when the war ends + chat is closed
}

Proposal {
  proposalId: string
  warId: string
  proposerAllianceId: string
  proposerPlayerId: string         // must have wardec authority
  proposalType: "CeaseFire" | "Surrender" | "Reparations" | "Withdrawal"
  termsJson: string                // structured terms (territory, currency, restrictions, etc.)
  proposedAtUtc: string
  expiresAtUtc: string?            // optional, see §12 open question
  status: "Pending" | "Accepted" | "Rejected" | "Withdrawn" | "Expired"
  resolvedAtUtc: string?
  resolvedByPlayerId: string?      // must have wardec authority on receiving alliance
}
```

---

## 12. Open design questions

These need design resolution before the doctrine ships:

1. **Phase 1 → Phase 2 threshold.** How many broken cease-fires trigger escalation — 2, 3, or higher?
2. **Active-member definition** for disband condition §6.2. Logged in within 24h? 7 days? Affects how hard simultaneous-bubble is.
3. **Coordinated-window duration** for simultaneous bubbling. 30 minutes? 60? Affects coordination requirement for the attacker.
4. **Active-war visibility.** Once mutual marking activates, is the war state public to the server, or known only to the two alliances?
5. **Cease-fire acceptance authority.** Can any officer accept a cease-fire, or leadership only? Affects how easy rogue-attack griefing is.
6. **Cease-fire violation grace.** Is it any attack? Or only attacks above some damage threshold? Single-shot misclicks shouldn't void a truce.
7. **War-zone PvP rules.** Do active wars open high-sec sectors between the warring parties? FED Police behavior in active war zones?
8. **Disband asset distribution.** When tag retires, what happens to the alliance's territory anchors, vault contents, citadels? Transferred to winner? Destroyed? Returned to faction control?
9. **Splinter cooldown.** Can ex-members of a disbanded alliance immediately form a new alliance together? Or is there a cooldown enforcing geographic dispersal sticks?
10. **Cross-faction warring.** Can a FED-aligned alliance war an ICE-aligned alliance? Does it cost faction standing? Mutual war doctrine doesn't natively care about faction alignment; standing systems would layer on top.
11. **Reparations enforceability.** If a losing alliance agrees to pay reparations but then refuses to deliver, what's the mechanism? Auto-debit from vault? Forced disband? War re-ignition?
12. **Memorial Wall visibility.** Public to all players, alliance-leadership-only, or admin-curated?
13. **War Council Chat post-war transcript visibility** (per §3.4). After the war ends, is the archived chat readable only to the participants, openly readable for lore research, or admin-only?
14. **Formal proposal expiration timer** (per §3.6). Do proposals have a 24h / 48h / open-ended lifespan? Open-ended risks zombie offers; timed risks pressure-traps.
15. **War Council Chat translation support.** International alliances likely speak different primary languages. Built-in translation, manual external translation, or no support?
16. **Cross-alliance chat etiquette enforcement.** If one side spams insults or harassment, what's the moderation surface? Auto-cooldown, alliance leadership reports the other, server-level admin?
17. **Vice-CEO Warlord-tier recognition** (per §8.2). Currently only the CEO gets the Warlord title on disband. Should Vice-CEOs who participated receive a lesser title (e.g. "Warlord's Voice" / "Sworn Warlord")? Spreads the recognition; complicates the "single buck-stops-here" framing.
18. **Faction-flavored Warlord variants** (per §8.2 lore framing). Do FED-aligned Warlords carry a different display variant than ICE-aligned, or Outlaw-aligned? Could be e.g. "Federation Warlord," "Iron Warlord," "Outlaw Warlord" — adds lore flavor + faction loyalty signaling, but multiplies UI states.
19. **Warlord title fate on player account deletion.** If a Warlord player deletes their account or goes inactive permanently, does the title transfer to anyone (e.g. the alliance's current CEO), or just vanish with the account? Affects long-term lore residue.

---

## 13. Where this fits in the build order

This doctrine is **Phase 6.x social** in [`../meta/master_to_do.md`](../meta/master_to_do.md) — depends on:
- **Alliance system** ([`social_alliance_guild.md`](./social_alliance_guild.md), Phase 5.3) — ranks, roster, vault, territory.
- **Base building + defenses** ([`../ground_base/progression_base_building.md`](../ground_base/progression_base_building.md), Phase 6.8) — for disband-condition §6.1.
- **Territory bubbles** ([`../world/world_territory_bubbles.md`](../world/world_territory_bubbles.md), Phase 5+) — for ownership resolution.
- **Combat resolution** ([`../combat/combat_overview.md`](../combat/combat_overview.md), Phase 4) — for disband-condition §6.2 (bubble-state evaluation).

The war doctrine **cannot ship before** all four prerequisites are in place. But it can be designed in parallel — this doc locks the design so dependencies build toward it.

---

## 14. Why this design (recap)

The core thesis is captured in §0. Restated for emphasis:

1. **Mortality matters.** Without it, alliance identity is just branding.
2. **Mutual consent prevents grief-permadeath.** Both sides choose.
3. **Escalation prevents abuse.** Truces are fragile; gaming the system pushes you toward consequence.
4. **Killed-alliances counter is earned reputation.** No admin curation needed.
5. **Member dispersal is opaque.** Anonymity is the protection for survivors.
6. **No clock.** Wars run on player time, not server timers.

Together these layers make alliance warfare in Apex Outlaw structurally different from games where alliances are just brand names that can't really die. **Names get to mean something here because names get to die.**
                                                                                                                                                                                                