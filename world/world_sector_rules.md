# MMO Sector Rules & Zoning TDD

## 1. What is a "Sector"?
The Helion system is divided into thousands of contiguous "Sectors" (hexes or grid squares on the Nav-Map). A sector itself is a **PlayFab macro construct** — there is no Fusion runner for the sector map. Fusion event instances only spin up when an in-sector event fires (combat encounter or mining op). See `../architecture/architecture_plan.md` §3.0.

- **Combat instance cap:** A combat Fusion instance is hard-capped at **3 vs 3 active combatants + up to 10 spectators (16 players total)**. Spectators see the fight but cannot fire, take damage, or contribute fleet stats.
- **Mining-op instance cap:** Sized separately from combat (TBD); mining ops are not battles and don't share the 3v3 model.
- **Instance Spilling:** A single sector OR a single planet (in Scene 2 / Scene 3) may host **multiple concurrent combat instances** — one Fusion runner per engagement cluster, matched server-side by the `ServerFowMatcher` based on wide-FOW overlap. Players in different runners cannot interact or see each other's ships directly. See [`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md) for the three-scope FOW model that drives clustering.
- **Capital ship Scene 3 exclusion:** Capital-class ships (chassis flagged `canEnterAtmosphere = false`) **cannot enter the Surface scene**. They stay in Low Orbit while smaller fleet ships drop down. Permit-gated transition from Low Orbit → Surface enforced server-side via `PlanetSurfacePermitCheck` CloudScript (owns base / allied with owner / planetary defenses defeated). Canon: [`world_surface_scene.md`](./world_surface_scene.md).

---

## 2. Security Threat Levels (The PvP Rules)
Every sector is assigned a Security Status (0.0 to 1.0) governing PvP rules and faction response times.

### A. High Security (FED Core Space: 0.8 - 1.0)
- *Examples:* Concordia and the inner ring of FED-controlled bodies (the densest registered-trade-hub cluster in Helion).
- **Rules:** Firing a weapon unprovoked upon another player prevents them from jumping/warping, but immediately triggers an invincible, overwhelming **FED Police Response Fleet** (formerly "CONCORD" in legacy notes). The aggressor is guaranteed to die within 15 seconds.
- **Vibe:** Highly populated, safe for trading. Terrible resource yields.

### B. Low Security (ICE / Contested Border: 0.4 - 0.7)
- *Examples:* Ferrum industrial outposts, the inner belts, Discordia and its contested moons (Pax / Bellum).
- **Rules:** Firing unprovoked is allowed, but the aggressor takes a severe hit to their FED Standing and Wanted Level. Automated turrets protect the Hubs and Gates, forcing pirates to ambush players deep in the asteroid fields away from the stations. ICE patrols intervene in defense of ICE-aligned alliances per the faction-claim doctrine in `world_faction_sovereignty.md` §4.
- **Vibe:** Tense. Solo miners must constantly watch their radar for incoming signatures.

### C. Null Security (The Outlaw Rim: 0.0 - 0.3)
- *Examples:* Glacies and the outer-system bodies, the Limen Belt, the deep belts, the Latro / Praedo outlier orbits.
- **Rules:** Completely lawless. No standing penalties for murder. FED police fleets do not patrol here.
- **Vibe:** The only place where Tier 4 (Dark Matter / Plutonium) anomalies naturally spawn. Controlled entirely by player alliance citadels. If an alliance owns the sector (per the 100% POI ownership rule in `../meta/master_to_do.md` Phase 5.5), they are the de-facto police.

---

## 3. Sector Transitions (Moving Between Regions)
A player's ship traverses the macro sector graph via **PlayFab travel commits** — no Fusion handoff, no sub-server load. Sector and planet maps are pure PlayFab macro state; Fusion is only spun up later, *if* the player triggers a combat encounter or mining op.

- **Deep Space Borders:** Flying to the absolute X/Y coordinate edge of the sector map fades the screen and commits a travel transition through PlayFab into the contiguous neighboring sector context.
- **Jump Gates:** Massive structures acting as instant fast-travel points to non-contiguous sectors. Entering the gate requires remaining stationary for 10 seconds to spool up the drive (creating a massive target for ambushes). The gate's destination is **whichever other gates currently fall inside its bubble radius** at the moment of spool — connectivity is dynamic, computed live from orbital positions, so the option list a pilot sees on approach is what's reachable *right now*. Routes vanish and reappear as planets drift; see [`../lore/lore_story_bible.md`](../lore/lore_story_bible.md) §5.

---

## 4. Points of Interest & Environmental Dynamics
A sector is not empty space; it is populated by persistent and dynamic Points of Interest (POIs).

- **Static POIs (Permanent):**
  - *The Sector Hub City:* Floating neutral market. Safe docking radius.
  - *Alliance Citadels:* Guild-owned stations built in Null-Sec.
- **Dynamic POIs (Spawning Events):**
  - *Drifting Comets:* High-value ore nodes that travel through the sector on a linear path and despawn at the map border. Forces players to chase them.
  - *Plasma Storms:* Massive visual clouds that randomly drift across the map, creating temporary "No-Shield Hazards" that smart tacticians utilize for ambushes.
  - *Golden Wrecks:* A destroyed dreadnought from a previous battle. Persists for 2 hours before despawning, giving scavengers a window to establish a Tow.

---

## 5. Sector ↔ Celestial Sync (Phase 6.0)
Every sector scene is anchored to a Celestial Parent (planet, moon, or named asteroid). The sector knows which parent via its `MacroSectorContext.bodyId` field; on Awake, that component auto-attaches a `CelestialSectorAnchor` (`Assets/Scripts/Macro/Celestial/CelestialSectorAnchor.cs`) which:

- Resolves the host parent record from the live `CelestialRegistry` (with prefix-fallback so the bare body id `"ignis"` finds `"Planet_ignis"` in the registry).
- Walks the parentId chain (moon → planet → sun) and computes the parent's absolute Helion-system position via `CelestialPositionEvaluator.PositionAt(...)` at `CelestialClock.Now()`.
- Exposes the result as `CelestialSectorAnchor.ParentSystemPosition`.

**The same evaluator runs in the SolarSystem map**, so a sector and the solar map agree on the parent's XZ position to the second. Cross-scene math (jump-gate transit time, ETA, sub-space comm latency) reads from this single source.

Sector internal layout (asteroids, ambient drift, the player's own ships) lives in the sector's own coordinate space anchored at world origin — only the parent's *apparent* system position is shared with the solar map. Visual elements that *do* want to track the parent's position (parallax skybox tilts, sun-angle ambient lighting) read `ParentSystemPosition` directly.

See `../architecture/architecture_plan.md` §1.5 for the broader Celestial Layer design and `../meta/master_to_do.md` Phase 6.0 for status.
