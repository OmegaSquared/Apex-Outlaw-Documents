---
status: canon
last-reviewed: 2026-06-12
tags: [world, sovereignty, ownership, mechanics]
note: "CANON mechanics. Extracted 2026-06-12 from the old world_story_lore.md §3–§4 so the sovereignty SYSTEM lives in a design doc, not in the (draft) lore bible. The fiction around it lives in ../lore/lore_story_bible.md."
---

# Faction Sovereignty, Ownership & Defeat

This doc owns the **ownership and sovereignty system**: how the universe represents "who controls
this", how alliances claim factions, how planets change hands, and what happens when a faction is
beaten back. It is the canonical spec the Phase 5.5 / 6.0 implementation reads. The narrative
flavor (who FED/ICE *are*, why they fight) is non-canon and lives in
[`../lore/lore_story_bible.md`](../lore/lore_story_bible.md) §3.

## 3. Ownership model — a faction IS an alliance

> **Canonical model: a faction IS an alliance — the only difference is who runs it.** Player
> alliances are run by player officers; factions are run by AI. Every game system that asks "who
> controls this?" treats both as a single concept: an **owner** identified by an `ownerId` string.
> FED's ownerId is `"FED"`, ICE's is `"ICE"`, a player alliance's is its alliance UUID. Every POI,
> every planet, every territorial mechanic uses the same one-field ownership model — there is no
> "faction ownership vs. alliance ownership" split. This means a player alliance can replace FED on
> a planet (and vice versa) with no special-case code; it's just a different `ownerId` value taking
> control. Schema migration tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md)
> Phase 6.0.SCHEMA.

The three owner poles — **FED**, **ICE**, and the **Outlaws** (non-aligned) — plus player
alliances all resolve to the same `ownerId` field. Faction identity strings are normalized through
[`Common/FactionId.cs`](../../Assets/Scripts/Common/FactionId.cs) (legacy `"PACT"` → `"FED"`).

## 4. Faction Sovereignty, Alliance Claims & Defeat

The two great-power factions are not eternal. The political map can be redrawn — and at the highest
level of MMO play, *will* be.

### 4.1 Alliance claims a faction
A player alliance may **formally claim allegiance** to either FED or ICE — but only if it is large
enough to matter. **Minimum size: 50 members. There is no upper cap** — alliances can scale
indefinitely (see [`../social/social_alliance_guild.md`](../social/social_alliance_guild.md) §1) and
frequently grow into thousand-pilot coalitions managed via the Squadron subdivision system. Smaller
alliances (and solo commanders) can run faction missions and gain standing, but cannot hold the
formal claim that triggers the defense / tax cycle below. The 50-member floor is the gate that
separates "serious sovereignty player" from "casual flag-flier."

Once the size threshold is met, the claim is binding for a defined cooldown period and it is
two-way:

- **Defense pact (in):** While a faction is claimed, that faction's NPC fleets will come to the
  alliance's defense in faction-controlled space — responding to attacks on alliance citadels,
  reinforcing planetary defense, and intervening in skirmishes the alliance flags as critical. The
  bigger the threat, the heavier the response.
- **Tax obligation (out):** The alliance pays the standard faction tax (FED: 35% on Hub trade, ICE:
  equivalent on Ferrum-routed industrial trade) on top of the alliance's own internal cuts. The tax
  is non-negotiable — it is the price of the umbrella.
- **Betrayal cost:** Dropping a faction claim before its cooldown expires triggers a sharp standing
  crash with that faction (and its allies) and a temporary bounty open to everyone in the system.

### 4.2 Faction planetary defense
Each faction-controlled planet (Concordia, Ferrum) hosts **Planetary Defense** platforms in orbit —
currently two per planet, on a tight inner ring. They are individually targetable, individually
destructible structures. **They can be defeated.** While even one defense platform stands, hostile
alliances cannot enter PlanetView to land, dock, or station-trade on that planet.

### 4.3 Faction defeat & AI base respawn
A planet is "taken over" when a hostile alliance destroys **all** of that planet's Planetary Defense
platforms and then captures **every POI** in the planet's system (jump gate, station, stat con,
shipyard, etc.) per the sector-control doctrine. When this happens:

- **The faction does not vanish.** Faction defeat at the planet level does not delete FED or ICE
  from the universe.
- **AI bases respawn elsewhere.** The defeated faction relocates: new NPC bases — recovery citadels,
  exile shipyards, mobile command stations — spawn in other regions of the system (deep belts,
  Lagrange points, contested fringe sectors). Locations are weighted away from the captured system
  so the faction has room to regroup.
- **The umbrella shrinks.** Alliances claiming the defeated faction lose access to the captured
  planet's defense response and tax routing for that region until the faction reclaims a planetary
  holding.
- **Counter-attack timer.** Reclaim attempts spawn from the new AI bases on a doctrine-driven cadence
  (placeholder: 24–72h real-time), giving the holding alliance a window to fortify but ensuring
  permanent loss is impossible by attrition alone.

This loop — **claim → defend → tax → fight → defeat → respawn elsewhere → reclaim** — is the macro
political cycle of Apex Outlaw.

### 4.4 Alliance ownership of a planet (50% rule + residency)
Below the great-power faction layer is a finer-grained planet-level ownership system any alliance can
win — including alliances too small (< 50 members) to formally claim a faction.

- **The 50% rule:** When an alliance holds **more than 50%** of the players currently present on a
  planet (subject to a minimum-population floor and a short grace period to prevent flapping), that
  alliance becomes the planet's *controller*. The planet's display tag flips from its baseline
  faction tag (`[FED]` / `[ICE]` / nothing) to the alliance's tag, in the alliance's color, on the
  planet's body label and on every label in its system (moons, POIs, defense platforms).
- **Threshold mechanics:** Implemented authoritatively in PlayFab CloudScript via
  `PlanetControlSchema.controlThresholdFraction` (default 0.50) and gated by
  `controlAcquireGraceSeconds` / `controlLoseGraceSeconds` so a single player jumping in or out
  doesn't flip the tag.
- **Residency grandfathering:** **Players who were already on the planet at the moment of takeover
  may stay forever** — they are written into the planet's `grandfatheredResidentIds` set in
  `PlanetControlState`. Their existing homes, hangars, contracts, and bases are untouched. This
  avoids the "log in to find you've been evicted" griefing pattern.
- **New arrivals require permission:** Once an alliance controls the planet, any player who was *not*
  a grandfathered resident must be **explicitly granted access** by an alliance officer before they
  can land, dock, or station-trade on that planet. Granted ids are written to `grantedResidentIds`;
  revocation removes them. Members of the controlling alliance always have implicit access.
- **Control loss:** When the controlling alliance drops below the threshold (after the lose-grace
  window) or another alliance crosses 50% (after the acquire-grace window), control flips. The new
  controller snapshots their *own* grandfather set from the present population at takeover time.
  Previous grandfather and grant lists are cleared.

This rule is faction-agnostic: a non-aligned alliance can take a faction-controlled planet, in which
case the planet still shows the alliance tag (overriding `[FED]` / `[ICE]` until control returns to
baseline).

### 4.5 Non-member tax (controlling-alliance toll)
Once an alliance owns a planet they may **levy a tax on non-member transactions** that happen on that
planet (trade, docking, repair, refueling, station-services). Members of the controlling alliance pay
0%; everyone else — grandfathered residents, granted residents, transient visitors — pays the toll on
top of any baseline faction tax.

- **Officer-set rate:** alliance officers can adjust the rate from 0% upward, clamped server-side to a
  hard ceiling (`PlanetControlSchema.maxNonMemberTaxFraction`, default 25%) so the system can't be
  weaponized into 99% blockade tolls.
- **Stacks with the faction tax:** the controlling-alliance tax is on top of any FED / ICE faction
  tax already routed through the system per §4.1. The non-member toll is the alliance's slice; the
  faction tax is the umbrella's slice.
- **Visibility:** the current rate is publicly visible on the planet's info card so visitors can
  decide whether the markup is worth it before they land.
- **Revenue routes** to the controlling alliance's treasury via PlayFab CloudScript on each
  transaction. Receipts include the toll line so it's auditable.

### 4.6 Infrastructure layer (Celestial Children)
Every visible thing orbiting a body — jump gates, stations, stat cons, shipyards, military outposts,
refineries, planetary defense platforms, alliance-built citadels — is "infrastructure." Some is
precursor or FED/ICE legacy hardware (the jump gates, the great Concordia Hub, the Ferrum forge
stations). Some is being built and torn down right now by player alliances (a fresh Stat Con on
Discordia, a forward-deployed shipyard on a contested moon).

The data layer treats them uniformly — every POI is a `CelestialChildRecord` in the shared registry,
distinguished only by a `source` field (admin-baked vs. alliance-built) and an optional
`ownerAllianceId`. When an alliance constructs a new Stat Con on a planet they own, it appears on
every other player's map within seconds of the CloudScript handler returning. When the controlling
alliance demolishes it, it vanishes the same way. The architecture is "one source of truth, one spawn
pipeline." See [`../architecture/architecture_plan.md`](../architecture/architecture_plan.md) §1.5 and
[`../architecture/architecture_backend_network.md`](../architecture/architecture_backend_network.md) §6.
The in-fiction framing of this layer is non-canon — see
[`../lore/lore_story_bible.md`](../lore/lore_story_bible.md) §4.6.
