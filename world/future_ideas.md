# Future Ideas — Helion System Content Concepts

This doc captures **designed-but-deferred features** for Helion. These aren't canon yet — they're ideas that survived a design pass but aren't ready to lock into the build. When a feature graduates here, it moves to [`world_resource_geography.md`](./world_resource_geography.md) and gets master to-do entries.

Pairs with [`world_resource_geography.md`](./world_resource_geography.md) (current canon) and [`world_overview.md`](./world_overview.md). Edit freely — promote / demote / kill ideas as the design evolves.

---

## Fleet Graveyard ("The Boneyard")

A debris field stretching for thousands of units — hundreds of derelict capital ships, freighters, fighters frozen in space. Origin deliberately ambiguous: an early exile fleet that came through the Custos Gateway and never made planetfall? FED/ICE flashpoint that escalated and was buried? Something precursor-old?

- **Geographic placement:** outer Main Belt edge / Goldilocks fringe. Out of the way enough to feel lost, close enough to be reachable.
- **Mechanics:**
  - Salvage extraction — scrap metal in industrial quantities; occasional intact modules (a Forged Tier-2 component someone made centuries ago, full Maker's Mark still readable from a dead pilot).
  - Field is mined — literally. Old defensive minefields still active. Detection + careful navigation required.
  - Possible Outlaw stronghold inside (secondary pirate base — complements Praedo).
- **Why it's fun:** every salvage run is unique. Lore unspools through what you find. FED markings on one hull, ICE on another, and **an unknown third faction symbol on a few** — who?
- **Dependencies:** salvage extraction schema (TBD), minefield detection mechanic (TBD).

---

## Generation Ship ("The Last Caravan")

A single colossal vessel — kilometers long. Pre-Exodus colony ship that left Earth before Helion was settled, lost contact, drifted into the system on a hyperbolic. Now in a slow elliptical orbit.

- **Geographic placement:** wandering body — long elliptical orbit, swings through inner + outer system over a multi-year period.
- **Mechanics:**
  - Interior explorable — large multi-floor scene. Mining bots, half-functional life support, archive databases.
  - Resources inside: archive data (lore drops, faction intel, lost Earth records), pre-Exodus tech (some Tier-3 modules from a different design lineage — Maker's Mark of a long-dead engineer), occasional organic material in cryo-storage.
  - Hostile inhabitants? TBD — could be feral descendants of the original colonists, automated defense AIs gone wrong, or pristine and silent.
- **Why it's fun:** one-shot dungeon content. Each player's first visit feels significant. The lore unspooled here is the canonical pre-Helion human history.
- **Dependencies:** interior-scene mechanic (similar to planet entry scene but mobile), event-driven hostile spawns.

---

## Sun-Grazer Comet ("Lacrima")

A specific named comet on a very tight elliptical. Perihelion brings it close to the sun — extreme heat, evaporating tail. Tail dispenses gas + ice into space (scoopable from following ships).

- **Geographic placement:** comet origin in outer cold; tail visible across inner system at perihelion.
- **Mechanics:**
  - Comet tail = mobile gas + ice resource zone. Equip a gas scoop or ice harvester and ride alongside.
  - Perihelion is a sky event — for a couple weeks every cycle, the comet is the brightest thing in Helion. Player attention magnet.
  - Dangerous to follow too close to the sun — solar radiation hazard for hulls without thermal shielding.
- **Why it's fun:** a recurring "comet season" event. Pirates ambush scoopers. Limited window each cycle.
- **Dependencies:** gas scoop schema, thermal shielding ship module, recurring world event scheduling.

---

## Sub-Ice Ocean Moon (Europa-style)

A future outer moon with a frozen surface and liquid water ocean beneath. Possible primitive biology / xenobiology.

- **Geographic placement:** moon of a future gas giant (Phase D in resource geography).
- **Mechanics:**
  - Drill-mining — break through ice crust to reach the ocean. Risk: structural failure of base if drilling is sloppy.
  - Xenobiological Trace — new resource, only here. Tier-3+ medical / biological catalyst.
  - Liquid water — abundant once you crack the crust.
- **Why it's fun:** the "first life found in Helion" moment. Lore branch: was it here before humans, or seeded by the Generation Ship's exobiology cargo that drifted?
- **Dependencies:** gas giant phase landing, drill-mining mechanic, new biological resource chain.

---

## Hollow Moon ("World Inside a World")

Looks like a normal moon from outside. Hollow interior, with atmosphere, light, gravity, ruins, partial life support. Dock at hidden entry points; explore vast internal scenes.

- **Lore hook:** Built by precursors to preserve something inside — biosphere? archive? prisoner? The interior space is bigger than the exterior implies (some kind of dimensional / gravity trickery — fits "unknown tech").
- **Gameplay:** Multi-floor dungeon content. Habitation cells for alliance bases inside. Exotic resource: Ancient Alloy from the shell itself (mining the moon's "skin" is sacrilege + possibly hostile-defended).
- **Why deferred:** alternative implementation path for the "alien tech moon" concept. The Ring (locked-in) is the chosen variant; Hollow Moon stays as a backup or as a second alien artifact later.

---

## Dyson Moon ("Surface Patchwork")

Looks like a moon but the surface is covered in geometric paneling — solar collectors, energy conduits, sensor arrays. Still partially functioning (some panels glow / pulse).

- **Lore hook:** Built to harvest the sun's energy. Long-range power broadcast antennas point at... nothing currently in the system. Whatever they powered is gone.
- **Gameplay:** Surface mining yields Ancient Alloy + Precursor Crystal (energy-bearing). Active panels project shield/aura effects nearby (combat modifier zone — pirates love it). No interior, but the surface itself is the content.
- **Why deferred:** another alternative path for "alien tech moon." If The Ring proves too narrow, this is a broader-surface alternative.

---

## Rogue Planet (Interstellar Drifter)

A planet-sized body on a hyperbolic trajectory — it came from interstellar void, will swing through Helion once, and leave forever.

- **Geographic placement:** entering Helion from outside, passes through outer system, swings around inner system, exits.
- **Mechanics:**
  - Limited-time content. Window of visibility ~6 months (real-time? or compressed game-time).
  - Frozen surface, no atmosphere. Exotic composition (came from a different star system, carries materials Helion doesn't have natively).
  - Player base on it = you go with it when it leaves the system. Permanent loss of your assets if you don't evacuate.
- **Why deferred:** scheduling + one-shot event design is heavier than other features. Better as a season event after launch.

---

## Lagrange-Point Trading Hub

A stable Lagrange point between the sun and a major planet (Avernus L4/L5 or future gas giant L4/L5). Hosts a Trojan-style cluster of small bodies + a player-built or NPC trading hub.

- **Geographic placement:** Lagrange points are mathematically stable; they fit naturally into the orbital model.
- **Mechanics:** stable orbital location for installations; small bodies around the L-point can be mined; NPC or alliance trading post is a social hub.
- **Why deferred:** needs a strong reason to exist beyond "it's mathematically interesting." If a future faction or storyline anchors here, promote it.

---

## Black Hole / Singularity

A small black hole hidden in the outer system. Gravitational hazard + exotic radiation signature.

- **Geographic placement:** deep outer system, away from main travel lanes.
- **Mechanics:**
  - Navigation hazard — ships within gravitational influence have movement penalties.
  - Cargo occasionally falls in (passing ships, dust, gas) — some kind of debris stream you can scavenge.
  - Pirates use it as a moving ambush point (event horizon hides their sensor signature until they're already close).
- **Why deferred:** physics simulation cost + balance complexity. Cool concept but not essential.

---

## Pulsar / Dying Star

If Helion has a stellar companion (binary system future), a pulsar adds periodic radiation bursts.

- **Geographic placement:** distant companion. Periodic radiation cycles affect outer system bodies.
- **Mechanics:**
  - Radiation periods grant temporary bonuses (energy collection?) and risks (hull damage, sensor jamming).
  - Schedule-driven event content.
- **Why deferred:** requires binary-system support in the celestial model. Open design decision in [`world_resource_geography.md`](./world_resource_geography.md).

---

## Abandoned Military Bunker (Moon Surface)

A cold-war-era FED or ICE installation on a moon, now derelict. Weapons cache, intel data, deactivated defense systems.

- **Geographic placement:** moon of Avernus, Aridus, or future planet. Multiple bunkers possible across the system.
- **Mechanics:**
  - One-shot dungeon — discover, breach, loot.
  - Defenders: deactivated automated turrets that can be reactivated if puzzles are solved wrong.
  - Loot: pre-Exodus weapons, intel logs (faction war lore), faction-coded equipment.
- **Why deferred:** small-scope content. Easier to author after the main surface-extraction mechanics land.

---

## How features graduate

A feature moves from this doc to canon when:
1. **Design is concrete enough to author** — mechanics, schema needs, dependencies all spelled out.
2. **Dependencies are satisfied** — the schemas / mechanics it needs are either built or scheduled.
3. **It fits the current expansion phase** — adding outer cold features before the outer cold region exists is premature.
4. **Aaron explicitly promotes it** — design review and approval.

Promotion checklist:
- Move the section into [`world_resource_geography.md`](./world_resource_geography.md).
- Add a phase entry to [`../meta/master_to_do.md`](../meta/master_to_do.md).
- Author the schemas / scene assets.
- Update [`world_overview.md`](./world_overview.md) if the feature warrants its own canon doc.
