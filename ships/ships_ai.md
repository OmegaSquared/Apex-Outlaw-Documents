# Ship AI — Reference

> **Phase 6.9 combat-context canon (added 2026-05-29):** Under the three-scene world model, the ship AI brain runs in **three distinct combat contexts**, each with its own spawn trigger and FOW scope. The FSM + utility hybrid below is the same in all three — only the scene loader, opponent class, and engagement bounds differ:
> 1. **Hyperspace intercept combat** — Solar map (Scene 1) attack-timer matures → drop into the blank-space combat sandbox. Pure ship-vs-ship, no body to land on, skybox + optional planet backdrop. AI Patrol/Engage states identical to the Tactical sandbox model used by `shipmanagerTestFleet.unity`.
> 2. **Low Orbit defense** — Scene 2 around a planet. AI defenders here include NPC orbital structures (defense platforms, citadel garrisons) and player capital ships repelling boarders. Engagement clusters are spawned by the `ServerFowMatcher` per `[world_low_orbit_scene.md](../world/world_low_orbit_scene.md)`.
> 3. **Surface raids** — Scene 3 above terrain. AI defenders are surface-base turrets and non-capital patrol fleets; AI attackers are pirate strike teams sent against player bases. Same matcher spawns the runner; only non-capital ships eligible (capitals are blocked from Surface per the permit gate).
>
> The FOW model is **per-context**: tactical sensor model (this doc + `SensorSchema`) governs Scenes 2 and 3 client-side; the server FOW matcher governs encounter prediction; hyperspace intercept uses the existing attack-timer-maturation trigger. Cross-refs: [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md), [`../world/world_surface_scene.md`](../world/world_surface_scene.md), [`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md).

Ship AI is the **hull-level pilot brain** that drives non-player ships and (optionally) the local player's own ship in autopilot mode. Per-turret aim is already solved by [TacticalTurretAI](../Assets/Scripts/Tactical/TacticalTurretAI.cs); this system decides **what to engage, where to fly, when to retreat, and when to launch missiles**. Turrets handle the rest.

Architecture is an **FSM + Utility hybrid**: a small four-state machine for hard mode-switches (Patrol / Alert / Engage / Retreat), and inside Engage a continuous utility score picks both target and sub-behavior (Close / Orbit / Kite). One pilot brain across all hulls — class differentiation is data-driven via a new `ShipAIProfile` schema.

> Status: design only. Schemas + runtime are TODO. NPC missile firing depends on the existing `TacticalMissileBay` surface, which is in. FOW-honest target visibility depends on the [Fog of War](../combat/combat_fog_of_war.md) sensor resolver landing first.

---

## At a glance

```
                         FSM transitions
       +----------+    target acquired    +----------+
       | Patrol   | --------------------> | Alert    |
       |          | <-------------------- |          |
       +----------+   target lost (fade)  +----------+
                                              |
                                              | closed to engagement range
                                              v
                            retreat trip   +----------+
                          +--------------> | Engage   |
                          |                |          |
                       +--+-----+          +----------+
                       | Retreat |              ^
                       |         |              |
                       +---------+   threat clear / safe
                            ^
                            | armor% < profile threshold
                            | AND no fleet-mate within cover radius

                        Inside Engage (utility-driven):

                        target = argmax( score(t)  for t in visible_hostiles )
                        score(t) = w_vuln  * (1 - hp_frac(t))
                                 + w_dist  * (1 - dist(t)/maxRange)
                                 + w_threat* dpsTowardSelfOrFleet(t)

                        sub-behavior = f( dist(target), profile.preferredBand )
                          dist > band.max  -> Close
                          dist < band.min  -> Kite
                          band.min..max    -> Orbit
```

Two consumers share the same brain:

```
+------------------+        drives        +-------------------------+
| NPCShipAI        | -------------------> | TacticalFlightEngine    |
| (autonomous)     |                      | (waypointQueue,         |
+------------------+                      |  inAttackMode, thrust)  |
                                          |                         |
+------------------+                      |  TacticalMissileBay     |
| PlayerAutopilot  | -------------------> |  (TryFire, NPC only)    |
| (button-driven,  |                      |                         |
|  no missiles)    |                      |  TacticalTurretAI       |
+------------------+                      |  (manualTarget hint)    |
                                          +-------------------------+
```

---

## Architecture

### Authority + networking

AI runs **server-authoritative on the Photon Fusion runner**, matching every other tactical-instance subsystem (per [CLAUDE.md](../CLAUDE.md) micro-game rule). The brain ticks on the StateAuthority host and only commits decisions through the existing `[Networked]` surfaces on `TacticalFlightEngine` (`waypointQueue`, `inAttackMode`) and `TacticalMissileBay` (`TryFire`). Clients never run a copy — they observe the resulting networked state.

### Two controllers, one brain

The decision logic lives in a shared `ShipAIBrain` static helper (pure functions: target picker, sub-behavior selector, retreat check, missile-fire gate). Two thin `NetworkBehaviour` controllers consume it:

| Controller | Used by | Autonomy | Fires missiles? |
|---|---|---|---|
| `NPCShipAI` | NPC ships (faction patrols, pirates, civilians) | Full FSM \+ utility | **Yes**, profile-gated |
| `PlayerAutopilot` | Player's own ship when autopilot mode toggled | Button-driven (Attack / Defend / Retreat / Hold) | **No** — missiles are always manual |

The brain helpers are stateless; both controllers feed in `(self, profile, world snapshot)` and read back the chosen target + sub-behavior + retreat flag.

### Why FSM + Utility (not pure BT, not GOAP)

- **Pure FSM** breaks down once target picking has more than two factors — transition explosion.
- **Pure BT** is overkill for a 4-state combat loop and is a pain to debug under Fusion's network rollback.
- **GOAP** has no win for tactical space combat — there is no plan to make beyond "engage / disengage."
- **Utility inside Engage** is exactly the right shape for "score every visible hostile and every reachable position, pick the best." The hard states stay an FSM so transitions are readable.

---

## States + transitions

| State | Behavior | Exits to |
|---|---|---|
| **Patrol** | Default non-combat state. Behavior depends on `profile.civilianObjective` (see below) — Freighters fly trade lanes at cruise speed, Miners orbit asteroids, Patrolmen run waypoint loops, Combatants idle / drift. No combat scanning beyond passive FOW. | → **Alert** when at least one hostile enters effective FOW and passes the targeting filter. |
| **Alert** | Turn toward strongest contact, close to engagement range, broadcast contact to fleet (reserved hook), light up `inAttackMode`. No firing yet. Brief wind-up so AI doesn't snap-attack the moment a friendly ship grazes its FOW edge. | → **Engage** once `dist(target) ≤ profile.engagementRange`. → **Patrol** if all contacts drop out of FOW for `profile.alertFadeSeconds`. |
| **Engage** | Active combat. Utility picks target + sub-behavior every tick. Turrets fire via existing `TacticalTurretAI` once the hull turns to bring them in arc. Missiles fire when profile-gated rules pass. | → **Retreat** when retreat trip fires. → **Patrol** when no hostile remains in FOW for `profile.engageFadeSeconds`. |
| **Retreat** | Burn full forward thrust along `(self - centroid(threats))` direction. Disengage turrets (`inAttackMode = false`), refuse new target locks, run until `dist(nearestThreat) > profile.safeRetreatRange` then drop to Patrol. Hard to interrupt — only flips back to Engage if cornered (no escape vector inside FOW). | → **Patrol** when safe distance reached. |

### Patrol objectives (civilian / non-combat behavior)

Idle ships look busy until provoked. The Patrol state is parameterized by `profile.civilianObjective`, an enum that selects a per-tick movement rule:

| Objective | Behavior | Authoring |
|---|---|---|
| `Idle` | Hold position with slight drift (current default). | Combatants on station, anchored picket ships. |
| `TradeLane` | Fly between two or more `TacticalPatrolNode`s authored in the sector at `profile.cruiseSpeedFraction × maxForwardSpeed` (default `0.5`). On reaching a node, pick the next one (cycle or ping-pong, authored on the route). | Freighters running cargo, civilian transports. |
| `MiningOrbit` | Locate the nearest `TacticalMiningAnchor` (asteroid / resource node) in the sector, slow-orbit it at `profile.miningOrbitRadius` (default `120m`), and play mining-laser VFX (cosmetic — no actual resource extraction in v1). When the anchor depletes / despawns, find the next nearest. | Industrial miners. |
| `PatrolRoute` | Follow a closed loop of `TacticalPatrolNode`s at full cruise speed, in order. Loops forever. | Faction patrols, security craft. |
| `StationKeep` | Hold position relative to a designated `TacticalAnchor` (a station, a flagship). Drift correction every few seconds. | Escort fighters, station guards. |

When the FSM transitions Patrol → Alert → Engage, the objective is **suspended**. On Retreat → Patrol (or Engage → Patrol via fade), the AI **resumes** its objective from wherever it is — a freighter that fled an ambush picks up the trade lane from its current position, not from the start.

Implementation note: each objective is a small strategy struct (`IPatrolObjective`) with a single method `Tick(self, profile, sectorContext) → waypointCommit`. The brain delegates to it during Patrol. Adds maybe 5 short classes — cheap to extend later (`Survey`, `RescueDrift`, `Pirate-Loiter`, etc.) without touching the FSM.

The sector-side anchors (`TacticalPatrolNode`, `TacticalMiningAnchor`, `TacticalAnchor`) are simple `MonoBehaviour` markers placed in the scene by the sector author. They register themselves in a static lookup at `OnEnable` so the brain finds them with zero allocation per tick.

---

> **Retreat trip rule.** `armor% < profile.retreatHullPct` **AND** no fleet-mate within `profile.coverRadius`. The fleet-cover check is the texture knob: a frigate doesn't bug out if its battleship escort is 200m away, but the same frigate alone runs the moment its hull cracks. Civilian profile sets `coverRadius = 0` so they always retreat at the threshold regardless.

---

## Targeting score

Computed every `profile.targetReevalSeconds` (default `0.5s`) over the ship's currently visible hostile set:

```
score(t)  = w_vuln  * (1 - hp_frac(t))
          + w_dist  * (1 - clamp01(dist(t) / profile.engagementRange))
          + w_threat* threatNorm(t)

hp_frac(t)    = (currentArmor + currentShield) / (maxArmor + maxShield)
threatNorm(t) = clamp01(dpsToward(self_or_fleet, t) / profile.threatNormDPS)
```

Weights `w_vuln`, `w_dist`, `w_threat` are authored on `ShipAIProfile`. Default profile weights:

| Class | w_vuln | w_dist | w_threat | Reads as |
|---|---|---|---|---|
| Interceptor | 0.3 | 0.5 | 0.2 | Snap to closest threat. |
| Fighter | 0.4 | 0.3 | 0.3 | Balanced — finishes wounded, defends self. |
| Bomber | 0.6 | 0.1 | 0.3 | Hunts wounded heavies, ignores fighters. |
| Frigate | 0.4 | 0.3 | 0.3 | Balanced. |
| Cruiser | 0.4 | 0.2 | 0.4 | Anti-threat — focuses on whatever's hurting it. |
| Battleship | 0.5 | 0.1 | 0.4 | Stand-off finisher. |
| Freighter | n/a | n/a | n/a | Civilian — never engages. |
| Dreadnought | 0.4 | 0.05 | 0.55 | Anti-flagship — kills the biggest threat, range mostly irrelevant. |

> These are **starting values**, authored on the default profile assets. All knobs live on `ShipAIProfile` so balance can move without grepping code.

### Override target

Both controllers honor an explicit override:

- **NPC AI**: a `RegisterAggressor` event on the flight engine boosts that aggressor's score by `profile.aggressorBonus` for `profile.aggressorMemorySeconds` so AI tends to fight back when shot. Hard lock is not set — the AI can still pick a different target if the bonus doesn't outweigh the rest.
- **Player Autopilot**: the player's right-click target is a **hard** override — score is bypassed entirely until the target dies, leaves FOW, or the player clears it.

---

## Engage sub-behaviors (range-band utility)

Sub-behavior is a function of distance to the chosen target relative to the profile's preferred range band:

| Distance vs. band | Sub-behavior | What the brain commits |
|---|---|---|
| `dist > band.max` | **Close** | Push waypoint at `(target.position - target.forward * band.optimal)` so the AI ends up inside the band, not on top of the target. Full forward thrust. |
| `band.min ≤ dist ≤ band.max` | **Orbit** | Strafe-circle the target at radius `band.optimal`. Direction (CW/CCW) flips on profile-driven jitter timer to break predictability. Maintain target inside firing arc. |
| `dist < band.min` | **Kite** | Burn lateral + reverse to push back into band. Bomber/Battleship classes typically have `band.min > 0` so they get pushed out by interceptors closing to point-blank. |

Default per-class bands (meters):

| Class | band.min | band.optimal | band.max | Notes |
|---|---|---|---|---|
| Interceptor | 50 | 200 | 500 | Tight knife-fight. No min-range. |
| Fighter | 100 | 400 | 800 | Mid-range strafe. |
| Bomber | 600 | 1200 | 2000 | Long stand-off, kites incoming fighters. |
| Frigate | 200 | 600 | 1200 | Mid-range orbit. |
| Cruiser | 400 | 1000 | 1800 | Long-orbit. |
| Battleship | 800 | 1500 | 2500 | Stands off, broadside arcs. |
| Freighter | n/a | n/a | n/a | Never engages. |
| Dreadnought | 1000 | 2000 | 3500 | Maximum stand-off. |

> Sub-behavior locks for `profile.subBehaviorMinHoldSeconds` (default `1.5s`) before re-evaluating, so a fighter that just kited away doesn't immediately decide to close and yo-yo.

---

## Awareness model (FOW)

AI is **FOW-honest**: it only sees what its own + fleet sensors can detect, via [TacticalSensorResolver](../combat/combat_fog_of_war.md#runtime-architecture-todo).

```
visibleHostiles = filter(allShipsInInstance, t =>
    relationship(self, t) is Foe or ProvokedNeutral
    AND sensorResolver.IsTargetVisible(t.position) for self.fleet
)
```

- **No omniscient AI.** Stealth ships (low `radarSignature` + outside sensor reach) are invisible to AI exactly as they are to players. This gates the Ship AI design on the FOW sensor resolver landing first — the brain takes a `IFOWQuery` interface so it can be unit-tested against a stub before the real resolver ships.
- **Lost contact.** When a target slips out of FOW mid-engagement, the AI gets `profile.lastKnownPersistSeconds` (default `3s`) of "ghost track" — it keeps flying toward the last-known position. After that the target is dropped and the brain re-scores.
- **Fleet vision is shared.** The visibility filter takes the **union** of every fleet member's sensors, matching how player fleet vision works.

---

## Schemas

### `ShipAIProfile` (NEW — `Assets/Scripts/Schemas/ShipAIProfile.cs`)

A `ScriptableObject` authored once per role/class (e.g. `AI_Fighter_Standard.asset`, `AI_Bomber_Aggressive.asset`, `AI_Civilian.asset`). Reused across many NPCs and across player ship hulls.

| Field | Type | Notes |
|---|---|---|
| `displayName` | string | "Federation Standard Fighter", etc. |
| **Patrol objective (non-combat behavior)** | | |
| `civilianObjective` | enum `{Idle, TradeLane, MiningOrbit, PatrolRoute, StationKeep}` | Selects the strategy used during Patrol. Default `Idle` for combatants, `TradeLane` for freighters, `MiningOrbit` for miners, `PatrolRoute` for security craft. |
| `cruiseSpeedFraction` | float (0..1) | Patrol-state throttle as a fraction of max forward speed. Default `0.5` for freighters, `0.8` for patrols. |
| `miningOrbitRadius` | float | Orbit radius around the resource anchor when `civilianObjective = MiningOrbit`. Default `120m`. |
| **Engagement geometry** | | |
| `engagementRange` | float | Distance at which Alert → Engage. Typically equals or exceeds turret max range. |
| `preferredBand` | (min, optimal, max) floats | The range-band engine for sub-behavior selection. |
| **Targeting weights** | | |
| `w_vuln`, `w_dist`, `w_threat` | floats | Score weights. Sum need not equal 1 — the argmax is invariant. |
| `threatNormDPS` | float | Normalization for `threatNorm`. Default `200 dps` — tune so a typical mid-class enemy reads as `~0.5` threat. |
| `aggressorBonus` | float | Score bump for ships in `aggressors` set. Default `0.4`. |
| `aggressorMemorySeconds` | float | How long the bonus persists after damage. Default `8s`. |
| **Retreat trip** | | |
| `retreatHullPct` | float (0..1) | Armor fraction below which retreat trips. Default `0.30`. |
| `coverRadius` | float | Max distance to a fleet-mate that suppresses retreat. Default `350m`. |
| `safeRetreatRange` | float | Distance from nearest threat at which Retreat → Patrol. Default `2500m`. |
| **Tempo** | | |
| `targetReevalSeconds` | float | Default `0.5`. |
| `subBehaviorMinHoldSeconds` | float | Default `1.5`. |
| `alertFadeSeconds` | float | Default `5`. |
| `engageFadeSeconds` | float | Default `8`. |
| `lastKnownPersistSeconds` | float | Default `3`. |
| **Missile usage** | | |
| `firesMissiles` | bool | Master gate. Civilian and Interceptor profiles default to false. |
| `missileLockRangeMin` | float | Below this, AI won't lock — too close, wasted shot. |
| `missileLockRangeMax` | float | Above this, AI won't lock — outside reasonable hit envelope. |
| `missileTargetMode` | enum `{HighestThreat, HighestValue, GunTarget}` | Whether the AI's missile picks the same target as guns or its own. |
| `missileMinTargetHullPct` | float | "Don't waste a missile on a near-dead ship." Default `0.20`. |
| **Reserved (v2 hooks)** | | |
| `formationRole` | enum `{Free, Lead, Wing, Scout}` | Reserved. Read by future fleet coordinator; ignored in v1. |
| `skillTier` | float (0..1) | Reserved. Reaction-time / aim-jitter scalar. v1 hardcodes `1.0`. |
| `factionPersonality` | enum | Reserved. v1 cosmetic-only — no behavior delta. |

### `NPCShipSchema` — additions

Already exists at [NPCShipSchema.cs](../Assets/Scripts/Schemas/NPCShipSchema.cs). Add one field:

| Field | Type | Notes |
|---|---|---|
| `aiProfile` | `ShipAIProfile` | The pilot brain config. Required for any NPC that should fight; null = never engages (drift / scenery). |

> The existing `aiEngagementRange` field on `NPCShipSchema` becomes redundant once `ShipAIProfile.engagementRange` is in use. Migration: leave the old field for one cycle, log a warning when both are set, and prefer the profile value. Remove on the cycle after.

### `ShipSchema` — additions (player ships)

| Field | Type | Notes |
|---|---|---|
| `defaultAutopilotProfile` | `ShipAIProfile` | The brain the autopilot uses when the player flips it on. Authored per hull class (so a Fighter hull's autopilot flies like a Fighter). Player can't override mid-battle in v1. |

---

## Runtime architecture

### `NPCShipAI` (NEW — `Assets/Scripts/Tactical/NPCShipAI.cs`)

`NetworkBehaviour` mounted on every NPC ship. Tick rate: `profile.targetReevalSeconds` for target/state decisions; per-frame for committing waypoint + thrust.

Owns:
- Current FSM state.
- Cached visible-hostiles list (rebuilt on reeval tick).
- Currently chosen target + sub-behavior + sub-behavior hold timer.
- Last-known-position ghost track for lost contacts.

Drives:
- `TacticalFlightEngine.waypointQueue` / `inAttackMode`.
- `TacticalTurretAI.manualTarget` (suggestion — turret stays autonomous, but the hint biases its scan toward the brain's chosen target).
- `TacticalMissileBay.TryFire(target, transform)` when the missile gate passes.

### `PlayerAutopilot` (NEW — `Assets/Scripts/Tactical/PlayerAutopilot.cs`)

`NetworkBehaviour` mounted on the player's own ship. Off by default. Toggled by a UI button cluster in the bottom-right HUD:

| Button | Behavior |
|---|---|
| **Attack — Nearest** | Brain runs in Engage state, targeting weights overridden to `(w_vuln=0, w_dist=1, w_threat=0)` so target = closest visible hostile. |
| **Attack — Weakest** | Brain runs in Engage, weights overridden to `(w_vuln=1, w_dist=0, w_threat=0)`. |
| **Attack — Right-click target** | Player right-clicks an enemy in the world. That collider becomes the hard-locked target. Sub-behavior still derived from range band. |
| **Defend** | Brain runs in Engage but only against ships in `aggressors` set (return fire only). No initiation. |
| **Retreat** | Brain forced into Retreat state. Returns to Patrol once safe. |
| **Hold position** | Brain forced into Patrol. Drift in place. |
| **(off / manual)** | Autopilot disabled. Player flies manually. |

**Critical: `PlayerAutopilot` never calls `TacticalMissileBay.TryFire`.** Missile launches are always a manual shift+R from the player. The brain's `firesMissiles` gate is hardcoded false on this controller path regardless of profile.

Manual flight inputs (WASD / mouse-fly) take priority while held — autopilot pauses one tick when input is detected and resumes when released. Avoids the "AI fights me for the stick" feel.

### `ShipAIBrain` (NEW — `Assets/Scripts/Tactical/ShipAIBrain.cs`)

Static, stateless helper class. Pure functions:

```csharp
public static Transform PickTarget(ShipAISnapshot self, IList<Transform> visible, ShipAIProfile p);
public static SubBehavior PickSubBehavior(float dist, ShipAIProfile p, SubBehavior current, float holdTimer);
public static bool ShouldRetreat(ShipAISnapshot self, IList<Transform> visibleFleet, ShipAIProfile p);
public static bool ShouldFireMissile(ShipAISnapshot self, Transform target, TacticalMissileBay bay, ShipAIProfile p);
```

Where `ShipAISnapshot` is a small POCO bundling `(position, forward, currentArmor, maxArmor, currentShield, maxShield, fleetMates)`. Keeping the brain stateless makes it cheap to unit-test and lets both controllers consume identical logic.

### `IFOWQuery` (NEW — interface)

Stub interface so the brain can be tested before the FOW sensor resolver lands:

```csharp
public interface IFOWQuery {
    bool IsVisible(Vector3 position, int viewerFleetId);
    IEnumerable<Transform> VisibleHostiles(int viewerFleetId);
}
```

Production impl wraps `TacticalSensorResolver` + `TacticalFleetVision`. Test impl returns hardcoded sets.

---

## Hooks into existing components

| Existing component | Hook | What changes |
|---|---|---|
| [`TacticalFlightEngine`](../Assets/Scripts/Tactical/TacticalFlightEngine.cs) | `inAttackMode`, `waypointQueue`, `aggressors`, `RegisterAggressor` | AI sets `inAttackMode = true` on entering Alert/Engage. Pushes waypoints for sub-behavior commits. Reads `aggressors` for the targeting bonus. **No new fields.** |
| [`TacticalTurretAI`](../Assets/Scripts/Tactical/TacticalTurretAI.cs) | `manualTarget` | Brain writes its chosen target into each turret's `manualTarget` as a **bias hint** — turret still validates against its own arc and falls back to auto-scan if the hinted target is unreachable. No code change inside `TacticalTurretAI` needed; the `manualTarget` surface already exists. |
| [`TacticalMissileBay`](../Assets/Scripts/Tactical/TacticalMissileBay.cs) | `TryFire(target, firingShipRoot)` | NPC AI calls this directly. Same surface as the player fire controller. PlayerAutopilot never calls it. |
| [`TacticalMissileFireController`](../Assets/Scripts/Tactical/TacticalMissileFireController.cs) | (none) | Player's manual missile path is unchanged. Autopilot never touches it. |
| [`TacticalSensorResolver`](../combat/combat_fog_of_war.md) | `IsTargetVisible`, `CoverageVolumes` | AI consumes via `IFOWQuery`. Hard dependency. |
| [`NPCShipSchema`](../Assets/Scripts/Schemas/NPCShipSchema.cs) | `aiProfile` (new field) | Add reference to a `ShipAIProfile` asset. |
| [`ShipSchema`](../Assets/Scripts/Schemas/) | `defaultAutopilotProfile` (new field) | Add reference to a `ShipAIProfile` asset for player autopilot. |

---

## Distress beacons (macro ↔ micro)

A civilian NPC under attack can broadcast a **distress call** that crosses from the tactical instance into the macro PlayFab sector layer. Nearby NPCs in macro space can be re-tasked to respond, transit to the sector node, and join the same tactical instance as reinforcements — **but only if they can arrive before the join window closes** (see below).

This is a **cross-architecture subsystem** — it's not pure Ship AI, but it's adjacent enough to belong in this doc until it grows large enough to split out.

### Battle lifecycle: the join window

Every tactical instance opens with a fixed-duration **join window** before combat is locked. The window is a base tactical-instance rule, not a distress-only mechanic — it applies to additional players AND distress responders identically.

```
   t = 0s                      t = JOIN_WINDOW_SECONDS              t = ...
   |                           |                                    |
   |--- JOIN WINDOW (open) -----|------ COMBAT LOCKED ---------------|
   |                           |                                    |
   ^                           ^                                    ^
   first shot fired,           instance closes to new participants  battle ends
   instance opens              ALL ships present at this moment     by victory /
                               are the ones who fight it out        retreat / death
```

| Constant | Default | Notes |
|---|---|---|
| `JOIN_WINDOW_SECONDS` | `15` | Time between first hostile action and combat lock. After this, no new participants — players or NPCs — can enter the instance. |

Rules during the window:
- Both attackers and defenders can call in additional support (other players, distress responders).
- Existing participants can leave (retreat / disengage).
- After lock, the participant set is **fixed for the duration**. A late-arriving NPC patrol bounces off — even if they were in transit, they don't get spawned in. They return to their previous objective.

This creates a tight tactical decision: **the attacker either commits hard during the window or aborts**. Lingering past lock means fighting whoever showed up. Fleeing during the window leaves cleanly.

### How distress interacts with the window

```
   TACTICAL INSTANCE (Fusion)              MACRO LAYER (PlayFab)
   +-----------------------+                +-------------------------+
   | Civilian NPC enters   |   distress     | CloudScript:            |
   | Alert state for the   | -- beacon --> | DistressCall(sector_id, |
   | first time this fight |    (RPC)       |  faction, position)     |
   +-----------------------+                +-------------------------+
                                                       |
                                                       | filter NPCs
                                                       v
                                           +-------------------------+
                                           | candidates =            |
                                           |   nearby NPCs           |
                                           |   AND faction-sympathic |
                                           |   AND idle / re-taskable|
                                           +-------------------------+
                                                       |
                                                       | re-task selected
                                                       v
                                           +-------------------------+
                                           | NPC.objective ->        |
                                           |   TransitToBeacon       |
                                           |   (eta_seconds)         |
                                           +-------------------------+
                                                       |
                                                       | on arrival
                                                       v
   +-----------------------+                +-------------------------+
   | NPC spawns into the   | <-- join ----- | spawn into instance     |
   | tactical instance     |   in-progress  | as Alert-state hostile  |
   | as a new participant  |                | toward attackers        |
   +-----------------------+                +-------------------------+
```

### Trigger

Each `NPCShipAI` carries a `profile.canBroadcastDistress` flag (default `true` for civilian profiles, `false` for combatants — combatants don't beg for help). On the **first** Patrol → Alert transition of a given engagement, an NPC with this flag fires a one-shot RPC to the PlayFab CloudScript endpoint:

```
DistressBeacon {
    sectorId           : string
    instanceId         : string         // tactical-instance handle for join-routing
    victimNpcId        : string
    victimFaction      : Faction
    victimPosition     : Vector3        // sector-space, not instance-space
    attackerFaction    : Faction        // best-guess from current target
    attackerPlayerIds  : string[]       // for bounty / reputation hooks later
    timestamp          : int64
}
```

One beacon per engagement — re-entering Alert after a brief Patrol fade does NOT re-broadcast within `BEACON_REBROADCAST_LOCKOUT_SECONDS` (default `120s`). Prevents flapping.

### Macro-side resolution (PlayFab CloudScript)

`DistressCall` CloudScript handler:

Candidates resolve into **two response classes** based on ETA. Both classes get dispatched — the world stays reactive even when nobody can make the fight in time.

| Class | Condition | Behavior |
|---|---|---|
| **Reinforcement** | `eta ≤ window_remaining` | Transits to the beacon, **joins the tactical instance** in Alert state, fights. Counts against `DISTRESS_MAX_RESPONDERS` and instance capacity. |
| **Investigator** | `eta > window_remaining` (but inside `DISTRESS_RESPONSE_RADIUS`) | Transits to the beacon position **without joining the fight**. Arrives after the instance has locked. On arrival, sweeps the area at low speed for `INVESTIGATOR_LINGER_SECONDS` (default `30s`) — searching for stragglers, reading the wreck, etc. — then resumes its previous objective (patrol route, idle, station-keep). Doesn't count against responder cap or instance capacity. |

This means a distress beacon ripples the entire sector neighborhood: nearby patrols make the fight, distant patrols converge on the area too late but visibly *react*. A player who flees a kill and tries to re-enter the area finds patrols on station, which creates organic post-combat tension without any explicit "manhunt" system.

**Filter pipeline:**

1. **Faction sympathy:** `relationship(candidate.faction, victim.faction) ∈ {Friend, Alliance}`. Outlaws don't help Federation freighters; a Mars patrol helps a Mars miner.
2. **Re-taskable:** candidate's current objective is in `{PatrolRoute, Idle, StationKeep}`. NPCs already in combat / docked / questing are skipped.
3. **Combat-capable:** candidate's `aiProfile.engagementRange > 0` AND `aiProfile.respondsToDistress = true`.
4. **Proximity (sanity bound):** macro-space distance ≤ `DISTRESS_RESPONSE_RADIUS` (default `60km`). Beyond this they don't react at all — even Investigator class gives up.
5. **Compute ETA** for each candidate.
6. **Classify** into Reinforcement or Investigator based on the ETA vs. remaining join window.
7. **Cap Reinforcements** at `DISTRESS_MAX_RESPONDERS` (default `3`) and at `tactical_instance.remainingCapacity - safety_buffer` (default buffer `5`). Sort by ETA ascending; trim. Investigators are NOT capped — every distant qualifying patrol still moves.
8. **Re-task** each selected NPC. Reinforcements get objective `TransitToBeaconReinforce(beacon, joinDeadline)`. Investigators get objective `TransitToBeaconInvestigate(beacon, lingerSeconds)`. Both objectives auto-revert to the prior objective when complete.
9. **Return** the Reinforcement list + ETAs to the requesting tactical instance for HUD readout. The victim's HUD shows "Federation patrol inbound — ETA 11s" with a countdown lining up to the join window. Investigators don't need to surface in the combat HUD — they're a sector-layer concern.

### Arrival + join-in-progress

When a responder's `arrival_timestamp` ticks past **and the join window is still open**, the macro layer instructs the Photon Fusion runner of the target instance to **spawn the responder ship**. The responder enters the tactical instance as a fresh `NPCShipAI` participant, **starting in Alert state** with the original distress-call attackers pre-populated in its `aggressors`-equivalent priority bonus. It hits the instance already pissed off — no patrol wind-up.

If the join window has **already closed** by arrival time, the responder is recalled to its previous objective without entering combat. Same outcome if the engagement ends early (victim destroyed, attackers fled). The macro layer is the source of truth.

### Travel-time gameplay shape

The 15-second join window plus macro-space travel time creates the core "pirate" tactical decision:

- **Hit-and-run attacker:** scouts the macro layer to find an isolated victim (no patrols within `~15s × patrol.cruiseSpeed` of the trade lane) → fast kill, clean exit. Even if a distant patrol gets the beacon, they can't arrive in time.
- **Greedy attacker:** picks a victim near a patrol → responders join the instance during the window → fights 2v1 or 3v1 outnumbered. Risk/reward of attacking high-traffic lanes.
- **Patrol stationing matters:** defenders intentionally place patrols within join-window range of trade lanes to reduce the unprotected window. A patrol that's 12s away protects everything in its sphere; a patrol that's 18s away doesn't.
- **Symmetric for attackers:** an attacker fleet can also call its own NPC support during the window (Outlaw raiders calling other Outlaw NPCs nearby). Same rules, same ETA gate.
- **Distant patrols still react:** an Investigator-class responder won't arrive in time but is visibly converging on the area. A player who hits a freighter and lingers post-combat gets surrounded; a player who hits and runs leaves Investigators sweeping a now-empty patch of sector. This is the cheapest possible "post-combat presence" mechanic — no global manhunt logic needed, just dispatch-everyone-in-radius and let arrival times do the work.

The lazy-timestamp model in PlayFab handles ETA computation cheaply: `eta = distance / npc.cruiseSpeed`, single computation per candidate, no ticking. The window itself is just a `Time.time + JOIN_WINDOW_SECONDS` deadline on the Fusion host.

### Faction sympathy table

Used by both the macro-side filter and any future macro-AI behaviors. Symmetric in v1 (no asymmetric grudges):

| | Federation | Mars | Belt/Outlaw | Civilian |
|---|---|---|---|---|
| Federation | Friend | Neutral | Foe | Friend |
| Mars | Neutral | Friend | Foe | Friend |
| Belt/Outlaw | Foe | Foe | Friend | Foe |
| Civilian | Friend | Friend | Foe | Friend |

> Civilian distress is honored by all three majors but not by Outlaws. A Belt freighter under attack by Mars patrol can call to other Belt ships only — the lore-honest outcome.

### Cross-system schema additions

| Where | Field | Notes |
|---|---|---|
| `ShipAIProfile` | `canBroadcastDistress` (bool) | Default true for civilian profiles, false for combatants. |
| `ShipAIProfile` | `respondsToDistress` (bool) | Default true for combatant profiles, false for civilians. A patrol responds; a freighter doesn't go play hero. |
| `NPCShipSchema` | `cruiseSpeedSectorKmPerMin` (float) | Macro-layer travel speed. Independent of tactical-instance flight stats — the sector layer is its own physics. Default values keyed off hull class. |
| (PlayFab title data) | `DistressActiveBeacons` | Map of `instanceId → beacon record`. Cleared when instance closes or beacon expires. |
| (PlayFab title data) | `DistressCooldowns` | Map of `npcId → last_broadcast_timestamp`. Drives `BEACON_REBROADCAST_LOCKOUT_SECONDS`. |

### Tunables

| Constant | Default | Where |
|---|---|---|
| `JOIN_WINDOW_SECONDS` | `15` | Tactical-instance lifecycle. Time from first hostile action until the instance locks out new participants. |
| `BEACON_REBROADCAST_LOCKOUT_SECONDS` | `120` | CloudScript |
| `DISTRESS_RESPONSE_RADIUS` (sector km) | `60` | CloudScript. Mostly redundant with the ETA gate but clamps the candidate set. |
| `DISTRESS_MAX_RESPONDERS` | `3` | CloudScript |
| `DISTRESS_INSTANCE_CAPACITY_BUFFER` | `5` players | CloudScript |
| `DISTRESS_RESPONDER_INITIAL_STATE` | `Alert` | NPCShipAI spawn-in (Reinforcements only) |
| `INVESTIGATOR_LINGER_SECONDS` | `30` | How long an Investigator-class responder sweeps the beacon area after arriving post-lock before resuming its prior objective. |

### Open questions / dependencies

- **Macro NPC position model.** This subsystem assumes there's a queryable list of NPCs with sector-space positions in PlayFab. The current PlayFab integration is auth + currency — the **NPC roster system doesn't exist yet**. Ship AI alone doesn't need it; this distress feature does. Build out the macro-NPC ledger before wiring distress.
- **Tactical-instance handle.** Re-spawning a responder mid-fight requires a stable instance ID the macro side can address. Confirm Photon Fusion exposes one we can route to from CloudScript (likely yes via the runner's session token).
- **Player-vs-civilian griefing.** Attacking a civilian within sensor range of a Federation patrol becomes a deathwish. That's *intentional* — pirates should be picking isolated targets — but balance pass needed once it's playable.
- **Reputation hook.** `attackerPlayerIds` in the beacon is reserved for a faction-rep system that doesn't exist yet. Logging it now means the data is there when rep ships.
- **Player-issued distress (v2).** Players in their own ships pressing a "request help" button to call NPC patrols. Same beacon format, different trigger. Out of scope here; flagged for later.

---

## Tunables (single source of truth)

All numeric knobs live on `ShipAIProfile` per class. Cross-cutting constants on `ShipAIBrain`:

| Constant | Default | Meaning |
|---|---|---|
| `BRAIN_TICK_RATE_HZ` | `4` | Decision tick frequency for Patrol/Alert FSM checks. Engage uses the per-profile `targetReevalSeconds` instead. |
| `WAYPOINT_PUSH_DEADBAND` | `15m` | Don't re-issue a waypoint if the new commit point is within this radius of the current one. Avoids twitchy waypoint-spam. |
| `KITE_LATERAL_BIAS` | `0.7` | Fraction of kite thrust applied as strafe vs. straight reverse. Higher = more "side-step away" feel. |
| `ORBIT_DIRECTION_FLIP_SECONDS` | `4..7s` random | Window after which an orbiting AI may reverse direction. Breaks predictability vs. human players. |

---

## Authoring a new AI profile

1. Right-click → **Apex Outlaw / Schemas / AI Profile**. Save under `Assets/Resources/Schemas/AIProfiles/`.
2. Set `engagementRange`, `preferredBand`, scoring weights (start from the defaults table above and tweak).
3. Set retreat thresholds + `coverRadius` (use `0` for civilians, `200–400m` for soldiers).
4. Decide `firesMissiles` and tune missile lock band if true.
5. Reference the asset from a `NPCShipSchema` (`aiProfile`) or a player `ShipSchema` (`defaultAutopilotProfile`).
6. No code change required.

---

## Open threads

- **FOW dependency.** Brain ships behind a stub `IFOWQuery` so it can be developed and tested before the FOW resolver lands. Once the resolver ships, swap the production impl in one file and delete the stub.
- **Fleet coordination (v2).** `formationRole` field is reserved on `ShipAIProfile`. Future doc covers focus-fire (everyone shoots fleet leader's target), formation slots, scout-spotter pairs, and a per-fleet `TacticalFleetCoordinator` `NetworkBehaviour`.
- **Difficulty tiers (v2).** `skillTier` float is reserved. Plan: scale `targetReevalSeconds` (slower = worse), add aim-lead error to turret hints, raise/lower `retreatHullPct`. One float drives the whole tier dial.
- **Faction personality (v2).** `factionPersonality` enum is reserved. Cosmetic only in v1. If/when this turns on, it's a multiplier layer on top of the class profile (not a replacement) — Federation Fighter inherits Fighter weights, then applies a `+discipline` modifier.
- **Migrating `NPCShipSchema.aiEngagementRange`.** Old field becomes redundant once profiles are in. Two-cycle deprecation: warn + prefer profile, then delete.
- **Player autopilot UI.** Button-cluster wiring lives in the macro-UI doc; the controller surface is defined here but the buttons / hotkeys / icon set are not (TODO in [../social/social_menus_ui.md](../social/social_menus_ui.md)).
- **Anti-stuck.** If an AI is in Engage but its waypoint hasn't moved by `> 1m` for `> 5s`, log + drop to Patrol for a tick (likely geometry trap or unreachable target). Not a state in the FSM — a watchdog inside `NPCShipAI`.
- **Provoked-neutral interaction.** AI with a Civilian profile (`firesMissiles=false`, `engagementRange=0`) still uses the existing `RegisterAggressor` hook — they just panic-flee (Retreat) when shot, since their `retreatHullPct` is high. No special-case code. Confirm this reads as intended once it's on screen.
- **Sector anchors authoring.** `TacticalPatrolNode` / `TacticalMiningAnchor` / `TacticalAnchor` are scene-placed `MonoBehaviour` markers. They register themselves in a static lookup on enable so the brain queries them allocation-free. Authoring lives in the sector scene; no schema needed. If sectors ever become data-driven (loaded from a config), promote anchors to `ScriptableObject` definitions plus a runtime spawner.
- **Mining VFX is cosmetic.** v1 `MiningOrbit` plays the mining-laser visual but doesn't extract resources or interact with the economy. When the mining loop lands, the same anchor doubles as the resource source and the AI consumes it like a player would.
- **Networking traffic.** AI decisions only commit through existing `[Networked]` properties; no new replicated state needed. If the brain ever wants to network the chosen target for client-side UI prediction (e.g., enemy aim indicators), add a single `[Networked] NetworkObject currentTarget` field — not yet required.
