# Territory Bubbles — Faction & Alliance Control Geometry

This document is the canonical definition of **faction and alliance territory** in Apex Outlaw. Territory is measured the same way the jump-gate network is measured: as **bubble radii** centered on owned anchors. Connectivity (or coverage) is computed each frame from the current geometric overlap of those bubbles, not from hand-authored sector ownership lists.

This is the same primitive that drives the gate-network connectivity model (per [`../../CLAUDE.md`](../../CLAUDE.md) "Don't author sector gates as chain-neighbor pairs"). The two systems share the math: a point is inside a gate's reachable destination set if it falls within any other gate's bubble; analogously, a point is inside a faction's patrolled territory if it falls within any of that faction's anchor bubbles.

---

## 1. Anchors

A **territory anchor** is any owned facility that projects a control bubble:

| Anchor type | Owner | Default bubble radius (admin-tunable) |
|---|---|---|
| Faction capital (Concordia for FED, Ferrum for ICE) | Faction | Large — covers the entire home system core |
| Faction outpost / minor hub | Faction | Medium |
| Faction patrol relay (StatCom variant) | Faction | Medium-large (extends reach into otherwise-uncovered space) |
| Alliance citadel | Alliance | Medium |
| Alliance outpost / minor structure | Alliance | Small-medium |
| Alliance StatCom (sensor relay — see [`../ships/ships_class_index.md`](../ships/ships_class_index.md) §StatCom) | Alliance | Medium — doubles as a territory projector |

Player bases on a planet **do not** project territory bubbles. A player can live on a planet without their personal presence claiming any space. Territory is a faction/alliance institutional concept, not a per-player one.

```
TerritoryAnchor (server-side, lives in PlayFab title internal data)
  anchorId           : string
  ownerId            : string   // factionId or allianceId
  ownerType          : enum { Faction, Alliance }
  position           : Vector3
  bubbleRadius       : float    // server-tunable per anchor
  tier               : enum { Core, Patrol, Fringe }   // affects enforcement intensity
  active             : bool     // false if anchor is currently disabled (destroyed, contested)
```

---

## 2. Querying Territory

The fundamental server-side check:

```
isInTerritory(point: Vector3, ownerId: string) : bool
  for each active anchor where anchor.ownerId == ownerId:
    if distance(point, anchor.position) <= anchor.bubbleRadius:
      return true
  return false
```

For multi-owner queries:

```
territoriesContaining(point: Vector3) : List<(ownerId, ownerType, tier)>
  // Returns every owner whose anchor bubble covers this point.
  // An empty list means the point is in lawless / Outlaw space.
  // A list with > 1 entry means contested space (multiple claims).
```

Both queries run in constant time relative to the anchor count (a few hundred globally at most) and can be cached per-tick. CloudScript handlers that need territory information call these helpers; no caller hand-authors sector ownership.

---

## 3. Emergent Space Types

The bubble geometry naturally produces four space categories without hand-authoring:

| Configuration | Result | Examples |
|---|---|---|
| No anchor bubble covers the point | **Lawless / Outlaw space** — no patrol, no claim | Deep Outlaw belts, far-fringe sectors, dead space between systems |
| Exactly one anchor bubble covers, tier = Core | **Faction core space** — full patrol, strict enforcement | Inside Concordia capital bubble |
| Exactly one anchor bubble covers, tier = Patrol or Fringe | **Faction patrolled space** — patrol present but weaker | Outer edges of FED control, fringe outposts |
| Multiple anchor bubbles from different owners cover | **Contested space** — overlapping claims; enforcement is partial / ambiguous | FED-ICE border zones, alliance-faction overlap regions |

**Contested space** is the most interesting emergent category. It produces:

- **Mixed `stolenFrom` behavior** — if FED and an alliance both claim a point and the alliance is FED-aligned, the tag fires; if the overlapping owners are *adversarial* (FED + Outlaw-aligned alliance), the territorial witness is ambiguous and admin policy decides (default: takes the more permissive answer — no tag — making contested space attractive to pirates).
- **Mixed patrol response** — if a FED-aligned alliance and FED both have anchors covering a point, both might respond to an attack; if a hostile alliance overlaps FED space, only FED responds and the alliance treats the attack as someone else's problem.

---

## 4. How Existing Systems Use This

Every gameplay system that asks "is this in FED space?" or "who patrols here?" routes through the territory bubble queries. The major callers:

### Clean-goods doctrine ([`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5)

The `stolenFrom` tag is set on a piracy event iff:
- The victim was a player (NPC victims never generate tags), AND
- `territoriesContaining(eventLocation)` includes at least one anchor whose `ownerType ∈ {Faction, Alliance}` *and* whose active-patrol status applies.

Piracy in lawless space → empty territories list → no tag → clean loot.

### NPC auto-arbitrage cross-faction rule ([`../economy/economy_npc_arbitrage.md`](../economy/economy_npc_arbitrage.md) §9.1)

When the NPC system scans for source hubs to fill a FED hub's shortage, it filters candidates by `isInTerritory(sourceHubPosition, "FED")` — only hubs inside FED-affiliated anchor bubbles are eligible. Same logic for ICE on the ICE side. The faction-isolation rule is enforced geometrically: cross-faction sourcing fails the territory check because FED and ICE anchor bubbles are non-overlapping by design.

### Patrol response triggers ([`../economy/economy_obligations.md`](../economy/economy_obligations.md))

When a player commits an attack on a faction NPC miner / NPC transport / lawful target, the patrol-response handler queries `territoriesContaining(attackLocation)`. If the faction or alliance whose asset was attacked has an anchor covering the location, that owner dispatches its standing patrol fleet. If the attack happened in lawless space, no patrol response (the attack location is outside enforcement reach).

### Resource permits enforcement ([`../economy/economy_obligations.md`](../economy/economy_obligations.md) §4)

A player attempting to harvest in alliance-controlled space triggers the permit check. "Alliance-controlled" means `territoriesContaining(harvestLocation)` includes that alliance's anchor. No anchor coverage = no enforcement = no permit needed (the location is functionally lawless).

### Faction-banks / trading-post access

Bank Terminals (other than the Black Market) live at faction or alliance anchors by construction — the hub IS an anchor. Player access to faction services scales with the territorial relationship between the player's standing and the anchor's owner.

---

## 5. Dynamic Effects — Capturing and Losing Territory

Because territory is computed live from anchor state, **destroying or capturing an anchor immediately reshapes the territory map**. There's no separate "redraw the borders" step — the bubble simply turns off (anchor.active = false) or its ownerId flips, and the territory query results change accordingly on the next tick.

This means:

- **Destroying a faction outpost shrinks faction territory** at that location. Previously-covered space becomes uncovered; lawless gameplay applies there until the faction rebuilds.
- **Capturing an alliance anchor flips its ownership** — the bubble now projects the capturing alliance's territory. The losing alliance lost not just a structure but the *space around it* that was inside their effective patrol reach.
- **Anchor disablement is a strategic objective.** Reducing an enemy faction's territorial reach is achieved by destroying anchors at the edge of their bubble network — each downed anchor shrinks the bubble overlap and creates new lawless corridors that pirates can exploit, smugglers can route through, and competing factions can fill with their own anchors.

This is where **alliance warfare and faction-political gameplay land mechanically**. Wardecs against alliance citadels aren't just "kill the structure" — they're "shrink the alliance's territorial footprint and open new lawless space."

---

## 6. Admin Tuning

The model exposes a single conceptual lever per anchor: `bubbleRadius`. Admin can:

- Set or change radii per anchor in PlayFab title internal data.
- Adjust faction-vs-alliance bubble overlap by tuning radii (e.g., shrink FED bubble to expose more contested space at the border, encouraging alliance growth).
- Spawn / despawn anchors to redraw the map quickly.

No hand-authored "this sector is FED space" lists exist. The map IS the bubbles.

---

## 7. Schema & Implementation Notes

- Territory anchors live in PlayFab title internal data, structured per-faction and per-alliance.
- The `CelestialRegistry` already houses hubs and major bodies — territory anchors can live in the same registry with an additional `territoryAnchor` block on each owned facility entry, OR as a parallel `TerritoryRegistry` keyed by ownerId. Defer the storage decision to implementation; either works.
- The territory query (`isInTerritory`, `territoriesContaining`) is implemented as a server-side helper in CloudScript, reused by every caller in the existing system.
- For client-side display (showing "you are in FED space" on the HUD), the client receives a cached snapshot of nearby anchors at sector load and runs the same point-in-circle math locally. The authoritative answer always comes from the server; the client display is advisory.

---

## 8. Why This Design

- **Geometric primitives compose.** Same bubble math as the gate network — one implementation, two systems. No special-cased sector-ownership tables that drift out of sync with anchor positions.
- **Dynamic by default.** Destroying an anchor immediately reshapes territory. No separate "recalculate borders" job.
- **Contested space is emergent.** Overlapping bubbles produce contested zones without hand-authoring. As factions grow / shrink anchors, the contested-space map shifts naturally.
- **Strategic depth in anchor placement.** Where to build the next StatCom or outpost is a real territorial-projection decision, not just a flavor choice.
- **Lawless space is a topology consequence.** Outlaw belts aren't "lawless because we said so" — they're lawless because no anchor's bubble reaches them. Add an anchor → the belt is now patrolled. Destroy enough anchors elsewhere → new lawless corridors open up.
