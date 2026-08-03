# MMO NPC & AI Behaviors

> **Phase 6.9 NPC placement canon (added 2026-05-29):** Under the three-scene world model, NPC spawn location depends on the scene context:
> - **Solar (Scene 1)** — NPC fleets in transit appear as macro pointer icons on the sector map (hyperspace travel); NPC freighter routes (§3) and pirate roaming patrols (§2) are tracked here as macro state. No 3D entities spawn until a fleet enters Low Orbit, Surface, or a hyperspace intercept sandbox.
> - **Low Orbit (Scene 2)** — Orbital NPCs spawn at real 3D positions around the planet: FED Police interceptors (§1) and ICE Garrison frigates (§1A) warp in from defense-station POIs; citadel garrisons and station defenders are tied to their structures' (altitude, lat, lon) registry placements. See [`world_low_orbit_scene.md`](world_low_orbit_scene.md).
> - **Surface (Scene 3)** — Surface NPCs spawn at real 3D positions on the terrain mesh at registered (lat, lon): planetary patrol non-capitals, ground-base defenders bound to `SurfaceBase` registry children, and surface industrial AI (FED inspector drones, ICE garrison patrols around alliance-claimed planets). Capital-class NPC ships are blocked from Surface per the permit gate. See [`world_surface_scene.md`](world_surface_scene.md).
> - **Hyperspace intercept combat sandbox** — Pirate / ICE / FED interceptor NPCs that mature attack timers in Solar drop into the blank-space combat sandbox alongside the player; no body, no terrain.
>
> The pirate flee mechanic (§2 — `BaseHP < 20%` → 10-second spool → warp out) applies in **all three combat scenes**. The faction-defeat cascade (§1B — new AI bases relocate after homeworld defeat) writes new registry records the spawners read at scene load; no special-case scene logic.

## 1. FED Police (Concordia Authority Response)
The absolute, overwhelming force of law in High-Sec (0.8 - 1.0) — FED Core space. They are explicitly designed to be unkillable in their patrol zones. Legacy notes call this the "CONCORD response"; rename to **FED Police** / **Concordia Authority** going forward.

- **The Crime:** If Player A shoots Player B unprovoked in FED Core space, a `Criminal Timer` begins.
- **The Response:**
  1. *0 Seconds:* An alarm blares across the Sector. Player A is "Webbed" (Gravity Tethered to 0 speed) automatically by station/gate authorities.
  2. *10 Seconds:* Five FED-Class Dreadnoughts physically warp into the instance, directly aligned to Player A.
  3. *15 Seconds:* The Dreadnoughts fire 12,345-peak Antimatter Spinal Mounts, instantly vaporizing the criminal.
- **Looting:** Player A's wreck remains. Player B can safely loot or tow it.

### 1A. ICE Garrison Response (Ferrum / contested space)
Mirror of the FED Police, but for ICE-controlled sectors (Ferrum and ICE-claimed contested space). ICE garrison fleets respond to attacks on ICE-aligned alliances and on faction infrastructure (Planetary Defense, Stat Cons, Shipyards). Per `world_faction_sovereignty.md` §4.1, an alliance that has formally claimed ICE (50+ members) gets these fleets in their defense; the alliance pays the ICE tax in exchange.

### 1B. Faction Defeat Cascade — AI Base Respawn
Both FED Police and ICE Garrison fleets are anchored to live planetary infrastructure. If a hostile alliance defeats every Planetary Defense platform on a homeworld and captures every POI in that planet's system per `../meta/master_to_do.md` Phase 5.5, the faction's response fleets stop spawning *from that planet*. The faction does not vanish — instead:

- New AI bases (recovery citadels, exile shipyards, mobile command stations) **spawn in other Helion regions** (deep belts, Lagrange points, contested fringe sectors), weighted away from the captured system.
- Response fleets re-anchor to the new bases. Reclaim sorties spawn from those bases on a doctrine cadence (placeholder: 24–72h).
- Alliances that had claimed the defeated faction lose their defense umbrella *for that captured region* until the faction reclaims a planetary holding.

This guarantees the faction war loop is permanent: even total planetary defeat just relocates the fight.

---

## 2. The Pirate / Outlaw Fleet AI
Operating heavily in Low-Sec and Null-Sec, these NPCs form the bulk of PVE content.

- **State - Roaming:** Fly slowly around asteroid fields waiting for a radar signature.
- **State - Interdiction:** If they detect a Player Freighter, they warp to 10km out, engage thrusters, and attempt to lock Gravity Tethers.
- **State - The Flee Mechanic:** Pirates are not suicidal. If a Pirate's `BaseHP` drops below 20%, they immediately halt weapons fire and enter a 10-second `Spool Sequence`. If the player does not apply a Gravity Tether or completely destroy the Hull within 10 seconds, the Pirate warps out of the instance and despawns.

---

## 3. The Industrial AI (Macro-Logistics)
To make the universe feel alive, the economy physically moves.
- **NPC Freighters:** If Hub City A is starved for Titanium and Hub City B has a massive surplus, the game does not just magically teleport the resources. 
- **The Spawn:** An NPC Heavy Freighter spawns at Hub B. It physically flies across the Sector Map, approaches the Jump Gate, jumping to Hub A.
- **The Ambush:** Pirate players can stalk these NPC routes in Null-Sec. If they successfully destroy the NPC Freighter before it reaches the gate, a portion of the Hub's cargo drops into space. This dynamic AI explicitly allows Outlaws to strangle the supply lines of rival factions.
