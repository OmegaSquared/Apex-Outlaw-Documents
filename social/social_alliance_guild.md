# MMO Alliance & Guild Mechanics TDD

> **Phase 6.9 alliance asset model (added 2026-05-29):** Alliance-owned orbital structures (citadels, satcom, planetary defense platforms, docks, ring stations) live as **3D prefabs in Scene 2 (Low Orbit)** of their host body, spawned by `CelestialSpawner` from registered orbital POIs. Alliance membership at a body **implicitly grants surface permits** to drop into Scene 3 (Surface) — non-allied attackers must defeat planetary defenses (orbital structures owned by the alliance) before the permit gate opens. Server-side enforced via `PlanetSurfacePermitCheck`. Canon: [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md), [`../world/world_surface_scene.md`](../world/world_surface_scene.md).

## 1. Membership Scale

**Alliance membership is uncapped by design.** There is no hard ceiling on roster size — a player alliance can grow from 3 founders to thousands of pilots within a single PlayFab record. The only limits are operational: PlayFab payload size on the alliance roster blob (mitigated by sharding the roster across child documents once an alliance crosses ~500 members) and the human cost of running a large org.

> **Why uncapped?** Sovereignty fights in Apex Outlaw need to support coalition-scale play. Capping membership would force coalitions to fracture into multiple alliances and reinvent every coordination tool through Discord. Indefinite membership + first-class **roles, ranks, and squadrons** lets the org chart grow at the same rate the roster does.

### 1.1 Practical scaling tiers (no enforcement, just rough naming)
- **Crew** (≤ 10) — solo + close friends. Effectively a guild.
- **Wing** (10–50) — small alliance. Below the 50-member floor that gates faction claims (see §4 / [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) §4.1).
- **Alliance** (50–500) — formal alliance. Eligible for faction claims, planet control, the full citadel/treasury system.
- **Coalition** (500+) — multi-squadron mega-alliance. Roster-sharding kicks in; mandatory use of the Squadron subdivision system (§3) to keep the org chart legible.

These names are flavor, not gates. The only hard threshold in code is the **50-member faction-claim floor**.

---

## 2. Ranks & Roles

The alliance ladder is **eight ranks deep**. Each rank carries a default permission set; alliance leadership can override individual permissions per-member ("custom title" promotions and demotions) without changing rank.

### 2.1 The rank ladder (highest → lowest)

| # | Rank | Cap | Purpose |
|---|---|---|---|
| 1 | **Founder / CEO** | Exactly 1 | Singleton owner of the alliance record. The only role that can dissolve the alliance, transfer founder status, or unilaterally drop a faction claim. |
| 2 | **Vice-CEO** | Up to 3 | Full operational authority short of dissolving the alliance. Designed for time-zone coverage and succession planning. |
| 3 | **Director** | Unlimited | Department heads — typically one per division (Military, Industrial, Diplomatic, Treasury, Recruitment). Set sub-policy within their department. |
| 4 | **Squad Captain** | Unlimited | Leads a named **Squadron** (§3). Manages roster, vault sub-account, and citadel access *within their squadron*. |
| 5 | **Officer** | Unlimited | Junior leadership. Can recruit Initiates, lead ops within a squadron, kick Initiates and Members from their own squadron, and read most alliance data. |
| 6 | **Member** | Unlimited | Full standing. All standard alliance benefits — citadel docking, alliance vault deposits, alliance chat, ship-replacement program eligibility. |
| 7 | **Initiate** | Unlimited | Probationary. Limited access — can dock and chat but cannot withdraw from the vault, cannot read intel, cannot vote in proposals. |
| 8 | **Reservist** | Unlimited | Honorary / inactive. Kept on the roster for historical recognition, but has no operational permissions and does not count toward squadron quotas or treasury cuts. |

> **Custom titles vs. rank.** The above are the *permission ranks*. A member's *display title* (e.g. "Iron Cross", "Smuggler King", "Veteran of Discordia") is freely set by the CEO/Vice-CEOs and is purely cosmetic. Title and rank are independent fields on the member record.

### 2.2 Permission matrix

Permissions are evaluated server-side in PlayFab CloudScript on every alliance action. The matrix below is the **default** for each rank; per-member overrides live in a `customPermissions` map on the member record.

| Permission | CEO | Vice-CEO | Director | Squad Capt. | Officer | Member | Initiate | Reservist |
|---|---|---|---|---|---|---|---|---|
| Dissolve alliance | ✔ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ |
| Transfer Founder | ✔ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ |
| Promote to Vice-CEO | ✔ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ |
| Promote to Director | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ |
| Promote to Squad Captain | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ | ✘ |
| Promote to Officer | ✔ | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ |
| Promote to Member (out of Initiate) | ✔ | ✔ | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ |
| Recruit Initiates | ✔ | ✔ | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ |
| Kick Initiates | ✔ | ✔ | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ |
| Kick Members | ✔ | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ |
| Kick Officers / Squad Captains | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ | ✘ |
| Kick Directors | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ |
| Declare Wardec / accept ceasefire | ✔ | ✔ | Diplo only | ✘ | ✘ | ✘ | ✘ | ✘ |
| Hold / drop faction claim (FED/ICE) | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ | ✘ | ✘ |
| Set alliance-wide tax rate | ✔ | ✔ | Treasury only | ✘ | ✘ | ✘ | ✘ | ✘ |
| Set planet non-member toll (when controlling) | ✔ | ✔ | Treasury only | ✘ | ✘ | ✘ | ✘ | ✘ |
| Anchor / un-anchor a Citadel | ✔ | ✔ | ✔ | ✘ | ✘ | ✘ | ✘ | ✘ |
| Construct / demolish alliance POI | ✔ | ✔ | ✔ | ✔ (within squadron) | ✘ | ✘ | ✘ | ✘ |
| Withdraw from main Alliance Vault | ✔ | ✔ | Treasury only | ✘ | ✘ | ✘ | ✘ | ✘ |
| Withdraw from squadron sub-vault | ✔ | ✔ | ✔ | ✔ (own squadron) | ✘ | ✘ | ✘ | ✘ |
| Deposit to vault | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✘ |
| Approve planet-residency grant | ✔ | ✔ | Diplomatic only | ✘ | ✘ | ✘ | ✘ | ✘ |
| Read Golden Logic Library (intel) | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✘ | ✘ |
| Issue ship-replacement payout | ✔ | ✔ | Treasury / Military | ✔ (within squadron, capped) | ✘ | ✘ | ✘ | ✘ |
| Dock at alliance Citadels | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| Read alliance chat | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| Read squadron chat (own squadron) | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✘ |

> "Diplo / Treasury / Military only" means the permission applies to a Director only when their `directorDepartment` matches. Departments are: `Military`, `Industrial`, `Diplomatic`, `Treasury`, `Recruitment`.

### 2.3 Department modifiers (Director-tier only)

A Director's department selects which slice of CEO authority they exercise. This avoids the "every Director can do everything" sprawl that breaks at coalition scale.

- **Military** — wardecs (with Vice-CEO co-sign), ship-replacement payouts, fleet doctrine.
- **Industrial** — citadel construction priority, refinery rates, manufacturing queues.
- **Diplomatic** — wardec acceptance, NAP / blue-list management, planet-residency grants.
- **Treasury** — vault withdrawals from main, tax rates, planet toll rates.
- **Recruitment** — Initiate → Member promotions in bulk, recruitment posting on the public Alliance Board, kick-for-inactivity sweeps.

A single member can hold multiple departments (a small alliance might have one Director wearing all five hats); a coalition-scale org typically has several Directors per department.

---

## 3. Squadrons (the subdivision unit for large alliances)

Above 50–100 members, a single flat roster becomes ungovernable. Apex Outlaw alliances solve this with **Squadrons** — first-class subdivisions of the alliance, each with their own:

- **Roster slice** — every member belongs to exactly one squadron (default: a system-managed `"Unassigned"` squadron).
- **Squad Captain** — the squadron's commanding officer.
- **Vault sub-account** — squadron-level credit pool, fed by squadron operations and supplemented by main-vault transfers.
- **Citadel access list** — squadrons can be granted dock-only / build-permitted / read-only access to specific alliance citadels.
- **Squadron chat channel** — Photon Chat channel scoped to the squadron.
- **Squadron tag** — appears in member records and on overlay HUDs (e.g. `[OUTLW][2nd Recon]`).

**Squadrons do not split the alliance** — wardecs, faction claims, planet control, and faction tax routing all happen at the alliance level. Squadrons are the **delegation primitive** that makes a 1,000-pilot roster legible: a Director sets policy, a Squad Captain executes it inside their unit, an Officer leads ops on the line.

A player can transfer between squadrons subject to the receiving Squad Captain's approval (or any Officer in that squadron). Squadron creation, renaming, and dissolution require Director-tier authority.

---

## 4. The Alliance Vault & Taxation

Alliances require massive sums of credits to maintain Citadel power grids, automated defenses, and ship-replacement programs. Managing this manually is impossible — it's automated through the **two-tier vault system**.

### 4.1 Two-tier vaults
- **Main Alliance Vault** — single PlayFab record holding the alliance treasury. Withdrawals require CEO / Vice-CEO / Treasury Director per the matrix.
- **Squadron Sub-Vaults** — one per squadron, fed by squadron-level operations and main-vault transfers. Withdrawals are scoped to the owning Squad Captain (or higher), capped per-day to a Director-set limit.

This split prevents a single rogue Squad Captain from draining the alliance, while keeping squadron operations responsive without escalating every fuel run to the CEO.

### 4.2 Automatic taxation
- **Alliance tax rate:** CEO / Vice-CEO / Treasury Director sets a percentage (typical range 5–15%). 
- **Execution:** Whenever a member kills a bounty, cashes a private contract, or sells ore to a Hub City, the standard FED/ICE tax applies first, *then* an additional alliance % is skimmed and deposited into the appropriate vault (main or squadron, configurable per stream).
- **Initiates pay too** but cannot withdraw — this is by design (skin-in-the-game probation).
- **Reservists are exempt** — they're honorary, not contributing to ops.

### 4.3 Payouts
- **Ship-replacement program (SRP):** Directors (Military / Treasury) and Squad Captains (within their squadron, within a daily cap) can issue payouts to compensate members for ships lost during sanctioned ops. SRP claims are logged in the alliance ledger and visible to anyone with the read-vault permission.
- **Project bounties:** Directors can flag specific objectives ("destroy this defense platform", "deliver this contract") with payout amounts. First member to complete the objective claims the bounty automatically via CloudScript.

---

## 5. High-Stakes Diplomacy (The Wardec)

How do Alliances fight without the High-Security Police executing them?

- **The War Declaration:** A CEO, Vice-CEO, or Military Director (with Vice-CEO co-sign) can pay a massive fee of credits to FED to issue a formal `Wardec` against a rival alliance.
- **The Timer:** Both alliances receive a highly visible 24-hour warning: *"War is Imminent."*
- **The Lethal Loophole:** After 24 hours, the two alliances flag `Hostile` to each other. For the next 7 days, members of these alliances can fire upon each other in **FED High-Security space (0.8 – 1.0)** without the invincible Police Fleets spawning over them.
- **The Economic Impact:** During a Wardec, Citadel Market Premiums between the two parties jump to 500%, freezing trade.
- **NAP / Blue list:** The Diplomatic Director (or higher) can register **Non-Aggression Pacts** and **Blue lists** with other alliances. NAP partners cannot be wardec'd without a 7-day cooling-off period; Blue-listed alliances are treated as friendly for fire-control HUD purposes.

---

## 6. Open threads
- **Roster sharding ≥ 500 members.** PlayFab's per-document size limit makes a flat roster unworkable past ~500 members. Sharding the roster across squadron-named child documents is the planned solution; the read-side aggregator is open work (see [`../meta/master_to_do.md`](../meta/master_to_do.md) Phase 5.3).
- **Cross-squadron permission inheritance.** The matrix above is per-rank; the open question is whether a Director's department permissions cascade automatically to Squad Captains in the same department, or whether each Squad Captain's permissions are independent. Default leans toward independent — overrides via the `customPermissions` map handle the rare cascade need.
- **Audit log retention.** Every promotion / demotion / vault withdrawal / wardec action writes to the alliance audit log. Open question: how long to retain (current placeholder: 90 days) and who can read (current placeholder: any rank ≥ Officer).
