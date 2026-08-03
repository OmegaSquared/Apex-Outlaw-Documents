# Sector Map & Actions — Reference

The Sector Map is the **macro-game view** of one sector — what the player sees when flying around outside of tactical combat. It runs on Mono + PlayFab with timestamp-based lazy evaluation; no Photon Fusion runner, no per-frame ticking. This doc owns the macro flight UI, the macro NPC ledger, the player actions on the map, the handoff to a tactical instance when combat starts, and the return path when combat ends.

> Status: design locked, runtime TODO. Hard dependency: the Ship AI distress system already assumes this exists (see [Distress beacon integration](#distress-beacon-integration)).

> **Future direction (Phase 6.7 — Helion unified world).** Sectors are migrating from standalone `.unity` scene files to **logical zones** inside a single continuous `Helion.unity` world. Open-space inter-zone travel becomes possible (slow, exposed to mesh-network FOW); jump gates remain as fast travel, not only-travel. The "scene per sector" model and the per-sector authoring patterns documented below remain canonical for legacy scenes (`SolarSystem.unity`, `ignis.unity`, etc.) — those are preserved untouched. New sector content authored after Helion lands should be authored as zones inside Helion, registry-driven, not as new `.unity` files. **Mesh-network FOW** also lands with Helion: alliance vision is proximity-mesh-shared via per-fleet `syncRadius`, not pooled globally. See [`../meta/master_to_do.md`](../meta/master_to_do.md) Phase 6.7 for the migration plan.

---

## At a glance

```
                        MACRO LAYER (Mono + PlayFab, lazy-eval)
   +------------------------------------------------------------------+
   |  Sector Unity scene (top-down camera, 3D models)                 |
   |    +- Player ship (waypoint queue)                               |
   |    +- Macro NPC roster (Title Data, lazy-eval positions)         |
   |    +- Stations / asteroids / gates / POIs / wreckage / beacons   |
   |    +- Macro FOW (sensor-gated via TacticalSensorResolver)        |
   +------------------------------------------------------------------+
              |                      |                       |
       border cross            orbit entry             attack initiated
              v                      v                       v
   +------------------+   +------------------+   +-------------------------+
   | Neighbor sector  |   | Orbit scene      |   | TACTICAL INSTANCE       |
   | scene (load via  |   | (planet/moon/    |   | (Photon Fusion)         |
   | SectorTransition |   | asteroid orbital |   | spawned by CloudScript, |
   | Service)         |   | bases)           |   | FleetSnapshot +         |
   +------------------+   +------------------+   | MacroEntryContext       |
                                                 +-------------------------+
                                                          |
                                                  combat resolves
                                                          v
                                                 +-------------------------+
                                                 | TacticalExitState ->    |
                                                 | macro layer; player     |
                                                 | returns to anchor pos   |
                                                 +-------------------------+
```

The map is **authoritative on the macro layer** — PlayFab CloudScript holds the NPC roster, validates moves, and provisions tactical instances. Fusion runs only inside combat; the moment combat ends the canonical state flows back to PlayFab.

---

## Map UI

### Camera + render

- **Top-down 2D camera over a 3D scene.** RTS register — orthographic-ish camera locked to the sector plane, with full 3D ship/station/asteroid models underneath. Players see ship orientation and visual depth without flying Newtonian 3D themselves.
- **Player ship is a 3D model.** A small chevron/icon overlay drawn over the model at low zoom for readability when the camera is pulled out.
- **Sector scale: large.** Authored sectors are EVE-scale: a typical hull crossing the sector at cruise takes ~5 minutes. Patrol stationing, distress ETAs, and trade-route timing are all keyed to this. The sector's bounding extent is authored on the sector definition and clamped on transition.

### Controls

- **Right-click move.** Click the ground plane → ship sets a single waypoint. Shift-right-click → appends to a waypoint queue. Click a friendly station / gate / POI → context move (dock / jump / interact). Click a hostile ship → see [Initiate combat](#player-actions).
- **Camera pan / zoom.** Mouse-drag edge-scroll + wheel zoom. Camera is constrained to the sector plane; no free 3D orbit.
- **Selection.** Left-click selects a target (your own ship if nothing else). Selected objects show range rings and FOW circles.

### Macro fog of war

Macro vision is **sensor-gated**, using the same resolver that runs in tactical combat ([Fog of War](../combat/combat_fog_of_war.md)). The same equipped `SensorSchema` modules and stacking formula determine effective reach on the macro layer; jammers and ECCM apply identically.

| Object class | Visibility |
|---|---|
| **Stations, gates, named POIs** | Always visible to all players in the sector (common knowledge). |
| **Ships (player + NPC)** | FOW-gated. A pirate hiding in a dust cloud at low signature is invisible to a passing freighter in macro space exactly as in tactical. |
| **Asteroids / wreckage / drifting comets** | Always visible above a base size threshold (large rocks); small wreckage is FOW-gated. |
| **Distress beacons** | See [Distress beacon integration](#distress-beacon-integration) — visible only to faction-sympathetic players. |

> Why reuse the tactical FOW resolver? Two reasons. (1) Sensor stat gear has to matter outside combat — otherwise the Pirate role can't *find* the Transporter role. (2) Stealth ships need to be stealth everywhere; otherwise the macro map exposes them and tactical engagements are pre-decided. The 25%-of-each stacking discount and directional cone behavior carry over unchanged.

Fleet vision sharing also applies: fleet-mates contribute their effective FOW to a shared union on the macro map. A scout in your fleet lights up the lane for everyone.

### Fleet launcher dock

A persistent right-edge dock listing the player's available fleets so launches can be initiated directly from the sector view, without diving into a menu.

- **Position.** Anchored to the right edge of the screen, vertically centered, above the standard HUD bottom bar. A small gutter keeps it clear of the camera-pan edge-scroll zone so hovering the dock never starts a pan.
- **Two states.** Semi-collapsable:
  - **Collapsed (default).** A thin vertical tab/handle (~32 px wide) showing a fleet icon plus a count badge of available fleets. Click toggles to expanded.
  - **Expanded.** A panel ~240 px wide listing each available fleet as a row. Each row shows:
    - Fleet name (primary label).
    - Optional secondary line (hull count / readiness state) — punted to v2, reserved space only.
    - A "Launch" affordance on the row. Design preference: row click selects, a dedicated button on the row commits the launch.
  - Click the handle again, click outside the panel, or press `Esc` → collapses.
- **Source of truth.** The fleet list comes from the player's Fleet Loadouts in their PlayFab profile (see [Data Schemas §6](../architecture/architecture_data_schemas.md)). The dock is **read-only** with respect to fleet composition — editing fleets happens in the Shipyard / Fleet Management menu ([Menus & UI Layout §5](../social/social_menus_ui.md)).
- **Empty state.** If the player has no configured fleets, the expanded panel shows a one-line hint pointing to the Shipyard.
- **v1 launch action.** The "Launch" button is a **stub** in v1 — the row and button render and respond visually, but the click handler is a no-op + `Debug.Log`. The real launch flow (deploying NPC wingmen / fleet members into the sector) is tied to fleet runtime and lands later. Flagged in [Open threads](#open-threads).
- **Persistence.** Collapsed/expanded state persists per-player via `PlayerPrefs` so the dock remembers the player's preference across sessions.

Owned by `SectorMapHUD` (see [Runtime architecture / Client side](#client-side-unity-mono)).

---

## Sector contents

Every sector is one Unity scene loaded from Addressables on transition. The scene authors place static content directly; dynamic content is spawned at runtime by the macro NPC system.

| Object | Source | Notes |
|---|---|---|
| **Stations / Hub Cities** | Authored in scene | Persistent. Faction-tagged. Full docking flow is a follow-up doc. |
| **Alliance Citadels** | Authored or runtime-spawned (null-sec) | Player-built structures. Citadel mechanics in their own doc. |
| **Jump gates** | Authored in scene — **one POI per body, mirroring `SolarSystem.unity`** (see [Jump gate authoring canon](#jump-gate-authoring-canon)). | Spool window + rule live in [Sector Rules §3](world_sector_rules.md); UX lives here. |
| **Asteroid clusters** | Authored fields + procedural per-cluster instances | Mining anchors register themselves for `MiningOrbit` AI objectives. |
| **Drifting comets / dynamic POIs** | Spawned by sector director | Linear travel path, despawn on border. Per [Sector Rules §4](world_sector_rules.md). |
| **Plasma storms / nebulas / cryo-clouds** | Authored volumes | Interact with `piercesNebulaDust`, weapon disable, etc. |
| **Macro NPCs** | PlayFab roster (see below) | Spawned into the scene on sector load, despawned on player exit. |
| **Wreckage** | Spawned on tactical instance close | Persists per [Sector Rules §4](world_sector_rules.md) — Golden Wrecks live ~2h. |
| **Distress beacons** | Spawned on tactical instance start | One per active engagement; FOW + faction-gated. |
| **Player ships** | Live | Each player in this sector instance is rendered as a real ship. |

### Asteroid resource loading

Asteroids are the primary entry point for raw materials into the economy. The chain is **asteroid prefab → category → raw materials**, all data-driven via ScriptableObjects so designers can rebalance without code changes.

#### Schemas

| Schema | Path | Purpose |
|---|---|---|
| `ResourceSchema` | [Assets/Scripts/Schemas/ResourceSchema.cs](../Assets/Scripts/Schemas/ResourceSchema.cs) | One raw material (Iron, Helium-3, Gold, etc.). Ungraded — a unit of Iron is a unit of Iron. |
| `AsteroidCategorySchema` | [Assets/Scripts/Schemas/AsteroidCategorySchema.cs](../Assets/Scripts/Schemas/AsteroidCategorySchema.cs) | One asteroid family (Cratered, Crystal, Ice, etc.). Holds the visual prefab variants in the family plus the `ResourceSchema[]` that drops when mined. |
| `MacroAsteroidYield` | [Assets/Scripts/Macro/MacroAsteroidYield.cs](../Assets/Scripts/Macro/MacroAsteroidYield.cs) | Component on every mineable asteroid that points back at its category. Mining code reads this to decide what drops. |

#### Authored data

- **Raw materials** live at `Assets/GameData/Resources/RawMaterials/Resource_<id>.asset`. Canonical list per [Architecture Plan §Raw Materials Sourcing](../architecture/architecture_plan.md): Iron, Copper, Aluminum, Silicates, Helium-3, Carbon (Tier 1); Nickel, Tungsten, Titanium, Sulfur, Platinum, Gold, Silver (Tier 2); Hydrogen, Nitrogen, Methane, Water Ice, Lithium, Cobalt (Tier 3). Add new materials by creating a `ResourceSchema` asset.
- **Categories** live at `Assets/GameData/Asteroids/AsteroidCategory_<Family>.asset`. Each ships pre-populated with its prefab variants and a starter mineral mix; the **Raw Materials** array is the lever for what each family drops.

#### Spawning into a sector

Two paths put asteroids into a sector:

1. **`MacroAsteroidBelt` (procedural belt)** — A scene-placed spawner with a weighted list of `AsteroidCategorySchema` entries. On Awake it rolls one category per asteroid (by weight), picks a random prefab from that category, and auto-attaches `MacroAsteroidYield` pointing at the rolled category. Belt geometry (inner/outer radius, count, scale, drift) is configured per-instance.
   - **Per-category weight = 0** disables that family in this belt. This is the primary lever for **controlling which raw materials enter the sector** — set Crystal=0 in a Federation sector if rare crystals shouldn't spawn there; set Gold=high in a "rich belt" sector to flood it with currency-grade ore.
2. **Authored standalone asteroids** — Hand-placed GameObjects (e.g. a planet's captured satellites). These get `MacroAsteroidYield` attached manually with `category` pointed at the matching `AsteroidCategorySchema`. Same schema chain, same drop behavior.

At mine-time, the resolver is uniform regardless of source: read `MacroAsteroidYield.category.rawMaterials` for the drop list. Per-material yield quantity (units per pass, ore→ingot conversion) is gated by the player's mining laser and refinery level — none of that lives on the asteroid.

> Wiring helper: `Apex Outlaw → Wire Asteroid Belt` (menu) seeds the canonical `ResourceSchema` assets, creates one `AsteroidCategorySchema` per visual family from the asteroid art pack, populates the belt's category list, and tags the standalone orbiters. Safe to re-run; never overwrites hand-tuned `Raw Materials` arrays.

### Orbit scenes (two scenes, gated transition)

Approaching a celestial body opens **one of two scenes** depending on what the player wants to do — they're separate Unity scenes loaded by the same transition service that handles sector border-cross. Player macro state is handed to PlayFab on entry, restored on exit. The sector scene unloads while in either.

**Scene 2 — Low Orbit** ([`world_low_orbit_scene.md`](world_low_orbit_scene.md))
- Opens when the player voluntarily clicks "Enter Planet" from this sector map on a body.
- Renders the body as a **3D Planet Forge planet** (atmosphere, biome, ocean per the body's `terrainThemeId`).
- All fleet sizes welcome — capitals stay here.
- Orbital structures (docks, citadels, satcom, planetary defense, jump gates) spawn from the registry as 3D prefabs.
- Ship control is RTS via the existing `TacticalFlightEngine` + `TacticalSelectionManager` pipeline.
- Fusion `NetworkRunner`s spawn lazily per engagement cluster (16-player cap each, multiple parallel runners normal).

**Scene 3 — Surface** ([`world_surface_scene.md`](world_surface_scene.md))
- Opens **only** when the player passes the permit check from Low Orbit (own a base / allied with owner / planetary defenses defeated).
- **Capital ships are excluded** — they stay in Low Orbit. Per-ship `canEnterAtmosphere` bool gates eligibility.
- Same Planet Forge planet body as Scene 2, but at low altitude. Surface bases are 3D-placed at registry (lat, lon) on the displaced terrain.
- Bases are **always physically rendered in 3D**; their HUD/minimap markers are gated by **activity noise** (silent = off radar, NOT invisible; visual scouting is a valid attacker counter-strategy).

**Hyperspace intercept** — separate from voluntary planet entry. When a fleet in transit on this sector map gets caught by an attack-timer maturation, the client **drops out of hyperspace** into the existing blank-space combat sandbox (`shipmanagerTestFleet.unity` pattern) with the Fusion runner already active. NOT Low Orbit, NOT Surface — just open interstellar space with skybox + maybe nearby-body backdrops. Full three-scene + hyperspace model documented in [`../architecture/architecture_overview.md`](../architecture/architecture_overview.md).

---

## Macro NPC system

### Roster authority

The authoritative NPC ledger lives in **PlayFab Title Data**, sharded per sector:

```
Sector_<SectorId>_NPCs : {
   npcs: [
     {
       npcId: "...",
       schemaId: "NPC_FREIGHTER_HEAVY_T2",
       aiProfile: "AI_Civilian_Freighter",
       faction: "Federation",
       fleetId: "fed_civilian_lane_07",
       lastUpdateTs: 1730000000,
       lastWaypoint: { x, y },
       velocity: { x, y },              // sector-km / minute
       cruiseSpeedSectorKmPerMin: 12,
       objective: { type: "TradeLane", routeId: "lane_jupiter_03", legIndex: 2 },
       hpFrac: 1.0,
       cargoTags: [...]
     },
     ...
   ]
}
```

CloudScript reads/mutates this on:
- **Sector load** for any client → recompute lazy-eval positions, return current snapshot.
- **Distress dispatch** → re-task selected NPCs to `TransitToBeaconReinforce` / `TransitToBeaconInvestigate`.
- **Tactical instance close** → apply `TacticalExitState` (NPC dead, NPC damaged, NPC moved).
- **Sector transition** of an NPC → move record between sector shards.

> Why Title Data? Cheap, no extra infra, fits the macro lazy-eval rule. Risk: title data has size limits — at ~150 NPCs per sector with a small record this fits comfortably, but if rosters grow we'll shard further (e.g., one entry per `(sectorId, faction)`). Flagging in [Open threads](#open-threads).

### Spawn model — hybrid

A sector's authored definition declares **role slots**, not concrete NPCs:

```
SectorDefinition {
   sectorId: "jupiter_outer_03",
   securityLevel: 0.6,
   ownerFaction: "Federation",
   tradeLanes: [ ... ],
   patrolRoutes: [ ... ],
   miningAnchors: [ ... ],
   roleSlots: [
     { role: "FederationPatrol",  count: 6, schema: "NPC_PATROL_LIGHT_T2" },
     { role: "CivilianFreighter", count: 10, schema: "NPC_FREIGHTER_T1", lanePool: [...] },
     { role: "Miner",             count: 4,  schema: "NPC_MINER_T2" },
     { role: "PirateAmbush",      count: 0..2, schema: "NPC_PIRATE_T2", trigger: "lowSecOnly" }
   ]
}
```

CloudScript instantiates concrete NPCs from these slots on sector cold-start and on a scheduled refresh cadence (replenish kills). Authored content gives sectors personality; procedural fill keeps density alive without per-NPC hand-placement.

### Position model — lazy-eval

NPC positions are computed on demand, never ticked:

```
position(now) = lastWaypoint + velocity × (now - lastUpdateTs)

   if position has crossed the next waypoint along the objective:
       advance objective leg
       set lastWaypoint = next waypoint
       set velocity     = direction(nextNext) × cruiseSpeedSectorKmPerMin
       set lastUpdateTs = the crossing time
```

Recompute is forced by:
- **Objective change** (distress re-task, kill, dock).
- **Sector load** for any player (resolve all NPCs in the sector to current positions).
- **Distress dispatch query** (resolve a candidate set's positions to compute ETAs).
- **Tactical instance close** (apply exit state, resolve NPCs that participated).

No 24/7 server loop. CloudScript pays per call, on demand.

### Objective execution

Objective semantics are shared with the tactical layer — same `civilianObjective` enum (`Idle / TradeLane / MiningOrbit / PatrolRoute / StationKeep`) plus distress-only objectives (`TransitToBeaconReinforce / TransitToBeaconInvestigate`). The **executors are different**:

| Layer | Executor | When it runs |
|---|---|---|
| Tactical | `IPatrolObjective.Tick(self, profile, sectorContext)` (per-tick, Burst-friendly) | While the NPC is in a Fusion instance |
| Macro | `IMacroObjective.ResolvePosition(now, lastUpdateTs, lastWaypoint, velocity, definition)` (lazy, JS-side in CloudScript) | Whenever a query forces a recompute |

The objective concept survives the layer boundary. A freighter that flees an ambush picks up its trade lane on the macro layer from its tactical-exit position, not from the start of the lane. See [Tactical → macro return](#tactical--macro-return).

---

## Player actions

### Fly — waypoint queue

The macro flight engine mirrors the tactical `waypointQueue` shape conceptually but executes lazily:

- Right-click → set single waypoint.
- Shift-right-click → append to queue.
- ETA per leg = `distance / ship.cruiseSpeedSectorKmPerMin`.
- Position at any time = lazy-eval from the queue head + elapsed time, identical to NPC math.
- Player input is **client-issued, server-validated** on every commit — CloudScript `Checksum` rejects implausible waypoint moves (per the `ETA verification` rule in [Architecture Plan §5](../architecture/architecture_plan.md)).
- Waypoint cancel / reorder is a free client action.

### Initiate combat

Players cannot trigger combat from arbitrary distance. The macro layer enforces a **range gate**:

```
if dist(self, target) > MACRO_ENGAGEMENT_RANGE → action disabled, show "close to engage" prompt
otherwise → "Attack" is a valid right-click context action
```

On commit:

1. Client → CloudScript `RequestEngagement(self, target, sectorId, position)`.
2. CloudScript validates: range, sector security rules ([Sector Rules §2](world_sector_rules.md)), wanted-level rules, target's current state (not already in another instance).
3. CloudScript provisions a Fusion instance (or attaches the attacker to an existing instance the target is already in; see [Distress join window](../ships/ships_ai.md#battle-lifecycle-the-join-window)).
4. CloudScript bundles `FleetSnapshot` ([Data Schemas §6](../architecture/architecture_data_schemas.md)) + a new `MacroEntryContext` for both sides.
5. Both clients receive a tactical-instance handoff token → load the tactical scene.
6. The instance opens in its 15-second join window.

Defenders do not get an opt-out popup. Once the attacker is at engagement range, the fight is on — security-tier penalties (Federation police) are the consequence layer, not consent.

| Constant | Default | Notes |
|---|---|---|
| `MACRO_ENGAGEMENT_RANGE` | TBD (~few sector-km) | Distance at which "Attack" becomes valid. Tune with sensor reach so a stealth ship can sometimes get to engagement range without being detected. |

### Jump gate authoring canon

**`Assets/Scenes/Maps/SolarSystem.unity` is the source of truth for the gate network.** Sector scenes mirror it — they do **not** invent their own gate topology. We are building the solar system one planet at a time; each authored sector is the close-up view of one body that already exists in `SolarSystem.unity`.

Concrete rules a sector scene must follow (matching the SolarSystem hand-authored pattern; see [`SolarSystemOneShotFix.cs:879`](../Assets/Editor/SolarSystemOneShotFix.cs:879) `BuildPoi` and the `DefaultGates[]` table at [`SolarSystemOneShotFix.cs:1293`](../Assets/Editor/SolarSystemOneShotFix.cs:1293)):

- **One gate POI per body**, not one per chain neighbor. A planet has *its* gate (the gate that lets traffic in and out of that planet's sector). Travel routing — which other gates this gate reaches — is a property of the network, not of the gate's local scene.
- **GameObject naming.** `POI_<bodyId>JumpGate` (e.g. `POI_IgnisJumpGate`), parented under `Planet_<bodyId>/SatelliteOrbits/`. The dashed orbit ring is a sibling named `Orbit_<bodyId>JumpGate`.
- **Required components on the POI.** `MacroOrbiter` (orbits the parent body), `MacroJumpGate` (sector-transition trigger + collider), `JumpGateMarker` (faction state machine — Offline / PactOnline / IceOnline / DualOnline; drives marker color), `SolarSystemBodyLabel` ("Ignis Jump Gate"). Visual children: a small unlit `Dot` mesh and a `Ring` line renderer.
- **Connectivity is bubble-radius based, not chain-neighbor based.** Two gates connect when their `JumpGateMarker.bubbleRadiusM` regions overlap. The authoritative table of `(gateId, displayName, bubbleRadiusM, factionId)` is `DefaultGates[]` in `SolarSystemOneShotFix.cs`. **The legacy `SectorChainRegistry` chain-pair model is deprecated** — when a sector ships its real gate, delete the old `JumpGate_<destinationId>` pair and replace with the single `POI_<bodyId>JumpGate`.
- **Faction tag.** Set `JumpGateMarker.factionId` to `"FED"`, `"ICE"`, or `""` (neutral) per the `DefaultGates[]` row for this body. Marker tint and overlay state read from this.
- **Identity is shared with the SolarSystem.** The gate in `Planet_ignis`'s sector scene is the *same conceptual gate* as `Planets/Planet_inner01/SatelliteOrbits/POI_IgnisJumpGate` in `SolarSystem.unity`. Renames must happen in lockstep.

> Why one POI per body: this matches how the network is authored, lets a single body's faction allegiance flip without re-wiring neighbors, and keeps the `JumpGateNetwork` bubble visualization (system-map view) and the `MacroJumpGate` trigger (sector-scene gameplay) reading from one POI per body instead of N stand-ins.

### Jump gate UX

Sector Rules §3 owns the rule (10s spool, cancel-on-damage, transitions to non-contiguous sector). This doc owns the UX:

- Click the gate → "Initiate jump" → ship moves to the gate's anchor point, then begins a 10s spool.
- A countdown ring is rendered around the ship; the gate's portal warps up.
- During spool, ship is **stationary** (gate-locked). Any damage taken cancels the spool with a visible feedback ("Spool aborted").
- Spool complete → screen fade → unified `SectorTransitionService` hands state to PlayFab → loads the destination sector scene.
- On the macro map, other players see the spooling ship as a stationary target with a gate-spool indicator (a tactical opportunity for ambush, per the design lore).

### Border-cross + orbit-entry

Both flow through the same transition service. Reaching the X/Y edge of the sector or entering a celestial body's orbit-entry trigger volume produces the same fade-out → state-handoff → scene-load. The destination scene is the only difference:

- Border-cross → contiguous neighbor sector scene.
- Orbit-entry → orbit scene for the body.
- Jump-gate → non-contiguous destination sector (after spool).

> Punt: Active sensor scans (manual sweep to reveal hidden objects) and station docking flow are out of scope for this doc; flagged in [Open threads](#open-threads).

---

## Macro → tactical handoff

### Lifecycle

Tactical instances are owned by the macro layer:

```
   CloudScript                       Photon Fusion                  CloudScript
   +---------------+    provisions   +---------------+   on close   +---------------+
   | RequestEngage | --------------> | Instance runs | -----------> | ApplyExitState |
   | (validate +   |   instanceId    | (sim, fight,  |  ExitState   | (write to      |
   |  bundle)      | <-------------- |  network)     | -----------> |  PlayFab)      |
   +---------------+                 +---------------+              +---------------+
            |                                ^
            |        join window open        |
            |         responders dispatched  |
            +--------------------------------+
                  (distress system, see Ship AI)
```

The `instanceId` is the stable handle CloudScript uses to address the instance for distress reinforcement spawn-ins.

### Handoff payload

Per side bundled into the instance:

| Schema | Source | Purpose |
|---|---|---|
| `FleetSnapshot` (existing, [Data Schemas §6](../architecture/architecture_data_schemas.md)) | Player's PlayFab profile, server-resolved | Hull + module stats with hardcoded post-`Lerp` integers. Already designed; no changes. |
| `MacroEntryContext` (new) | Sector state at moment of engagement | Sector position, velocity, fleet, aggressor list. |

```
MacroEntryContext {
   sectorId        : string
   instanceId      : string
   macroPosition   : Vector3   // sector-space position at moment of entry
   macroVelocity   : Vector3   // for exit-velocity drift continuity
   fleetId         : string
   aggressorIds    : string[]  // pre-populates TacticalFlightEngine.aggressors
}
```

The aggressor list pre-seeds the brain's targeting bonus so a defender NPC enters Engage state already aware of who hit them, not in Patrol-then-Alert wind-up.

---

## Tactical → macro return

When the instance closes (victory / retreat / wipe), Fusion compiles a `TacticalExitState` per surviving participant and CloudScript writes it back to PlayFab. The macro side then re-spawns participants in the sector scene at their **tactical instance anchor position** (with their final tactical-instance velocity, for continuity — "I drifted out the side of the engagement").

```
TacticalExitState {
   participantId       : string          // player or npcId
   survived            : bool
   exitPosition        : Vector3         // sector-space (anchor + drift)
   exitVelocity        : Vector3
   hullHpFrac          : float
   armorHpFrac         : float
   shieldHpFrac        : float
   damagedModules      : ModuleDamage[]
   cargoDelta          : CargoChange[]   // mined ore, looted scrap, lost goods
   wreckIds            : string[]        // wrecks left in sector for scavengers
}
```

The macro layer applies this state authoritatively:
- Dead NPCs are removed from the sector roster; killed players go through their respawn flow.
- Surviving participants resume their objective from the exit position. A freighter that escaped the ambush picks up the trade lane from its current location, not from the start.
- Wreckage entries are spawned in the sector at recorded positions, persistent for the duration defined in [Sector Rules §4](world_sector_rules.md).
- Investigators that were dispatched but not yet arrived continue toward the beacon — the macro layer is authoritative on their objective regardless of combat outcome (see below).

---

## Distress beacon integration

The distress system itself is owned by [Ship AI § Distress beacons](../ships/ships_ai.md#distress-beacons-macro--micro). This section covers what the **macro sector map** contributes:

### The macro side serves the beacon

When a tactical-instance NPC fires a `DistressBeacon` RPC, CloudScript:

1. Loads the relevant sector's NPC roster from Title Data.
2. Lazy-evals every candidate's current position.
3. Filters by faction sympathy (per [Ship AI faction table](../ships/ships_ai.md#faction-sympathy-table)), re-taskability, combat-capability, proximity.
4. Computes ETA per candidate → classifies into Reinforcement (`eta ≤ window_remaining`) or Investigator (`eta > window_remaining` but inside `DISTRESS_RESPONSE_RADIUS`).
5. Re-tasks selected NPCs by writing a new objective into their roster record.
6. Returns the Reinforcement list with ETAs to the requesting Fusion instance.

The Fusion instance HUDs the ETAs to participants. The macro map shows nothing extra to the participants in the fight — they're already in tactical. The map activity matters for **the rest of the sector**.

### Beacon visibility on the map

A live distress beacon shows as an icon on the macro sector map only to **friend / alliance factions of the victim**. Faction sympathy reuses the same table from Ship AI:

- Federation freighter under Outlaw attack → all Federation + civilian-friendly players in the sector see the beacon (and may choose to respond manually, even though only NPCs are auto-dispatched in v1).
- Outlaw freighter under attack → only other Outlaws see it.
- Mars freighter attacked by Federation patrol → other Mars + civilian players see it; Federation players don't.

This preserves "pirates can't farm beacons as a soft-target radar" while keeping rescue gameplay legible to the right audience.

> Player-issued distress (a player pressing "request help") is reserved for v2 (per the Ship AI doc's Open questions). The beacon UI surface is the same when it lands; only the trigger differs.

### Investigator presence on the map

After combat resolves, NPCs that were dispatched as Investigators continue their `TransitToBeaconInvestigate` objective regardless of the fight's outcome. They arrive at the beacon position, sweep the area for `INVESTIGATOR_LINGER_SECONDS`, then resume their prior objective.

Investigators are **normal NPCs on the macro map** — they appear on the player's view if they're inside the player's macro FOW union. A pirate who killed a freighter and lingers gets to see Federation patrols converging through their sensor reach; a pirate who hits and runs leaves the system without ever knowing patrols are sweeping the spot.

This is the cheapest possible "post-combat presence / ambient manhunt" mechanic — no global manhunt logic, just dispatch + ETA + FOW.

---

## Schemas

### `SectorDefinition` (NEW — `Assets/Scripts/Schemas/SectorDefinition.cs`)

`ScriptableObject` per authored sector. Static — runtime state lives in PlayFab.

| Field | Type | Notes |
|---|---|---|
| `sectorId` | string | Unique. Matches the Title Data key. |
| `displayName` | string | "Jupiter Outer 03". |
| `securityLevel` | float (0..1) | Drives PvP rules per [Sector Rules §2](world_sector_rules.md). |
| `ownerFaction` | enum `Faction` | Influences default roleSlots and reactive police response. |
| `extentsKm` | Vector2 | Sector size in macro km. |
| `sceneAddress` | string | Addressables key for the sector scene. |
| `tradeLanes` | `TradeLane[]` | Authored point sequences for `TradeLane` objectives. |
| `patrolRoutes` | `PatrolRoute[]` | Authored loops for `PatrolRoute` objectives. |
| `miningAnchors` | `MiningAnchorRef[]` | Sector-relative anchor positions; matched to in-scene `TacticalMiningAnchor` markers at runtime. |
| `roleSlots` | `RoleSlot[]` | The hybrid spawn list. |
| `dynamicPOISpawners` | `POISpawnerRef[]` | Drifting comets, plasma storms (per Sector Rules §4). |
| `orbitEntryRefs` | `OrbitEntryRef[]` | Triggers + target orbit-scene addresses for celestial bodies. |

### `RoleSlot`

| Field | Type | Notes |
|---|---|---|
| `role` | string | Authoring tag (e.g. "FederationPatrol"). |
| `count` | int or `IntRange` | Fixed or `min..max` for procedural variance. |
| `schema` | `NPCShipSchema` ref | Concrete NPC blueprint. |
| `aiProfile` | `ShipAIProfile` ref | (Optional override; defaults to schema's profile.) |
| `routeRef` | string | For trade/patrol — references a route in the sector's lane/route lists. |
| `triggerCondition` | enum | "Always", "LowSecOnly", "OnSectorRefresh", etc. |

### `MacroNPCRecord` (PlayFab Title Data shape)

The runtime record per NPC, stored under `Sector_<SectorId>_NPCs`. Fields enumerated in [Macro NPC system / Roster authority](#roster-authority).

### `MacroEntryContext` (NEW)

Sent alongside each side's `FleetSnapshot` when a tactical instance opens. Fields enumerated in [Macro → tactical handoff / Handoff payload](#handoff-payload).

### `TacticalExitState` (NEW)

Returned per participant when the tactical instance closes. Fields enumerated in [Tactical → macro return](#tactical--macro-return).

### `NPCShipSchema` — additions

Already required by the distress doc:

| Field | Type | Notes |
|---|---|---|
| `cruiseSpeedSectorKmPerMin` | float | Macro-layer travel speed. Default keyed off hull class. (Already flagged in [Ship AI § Cross-system schema additions](../ships/ships_ai.md#cross-system-schema-additions).) |

---

## Runtime architecture

### Server side (PlayFab CloudScript)

| Module | Responsibility |
|---|---|
| `SectorRosterService` | Read / write `Sector_<id>_NPCs` Title Data; lazy-eval positions on read. |
| `SectorSpawner` | On sector cold-start / refresh, instantiate NPCs from `SectorDefinition.roleSlots` and write to roster. |
| `MacroObjectiveResolver` | The lazy-eval `IMacroObjective.ResolvePosition(now, ...)` per objective type (TradeLane, MiningOrbit, PatrolRoute, StationKeep, Idle, TransitToBeaconReinforce, TransitToBeaconInvestigate). |
| `EngagementService` | Validate `RequestEngagement`, provision Fusion instance, bundle `FleetSnapshot` + `MacroEntryContext`. |
| `DistressDispatcher` | Receive `DistressBeacon` RPC from Fusion, run candidate filter + classification, re-task NPCs, return Reinforcement ETAs. (Also touches Ship AI's surface — the dispatcher logic is shared.) |
| `ExitStateApplier` | On tactical instance close, apply `TacticalExitState` to roster + player profiles. |
| `SectorTransitionService` | Hand player canonical state between scenes (border, orbit, gate). Validates plausibility (`Checksum`, ETA gate). |

### Client side (Unity Mono)

| Component | Responsibility |
|---|---|
| `MacroSectorScene` (per sector scene) | Top-level scene controller; loads sector content from `SectorDefinition`; spawns visual representations of macro NPCs from the roster snapshot. |
| `MacroFlightController` (player ship) | Click-to-move + waypoint queue; commits to CloudScript; lazy-evals visual position. |
| `MacroNPCVisualizer` (per NPC) | Drives the 3D model from the roster's lazy-eval position; cosmetic-only client-side simulation between server snapshots. |
| `MacroFOWOverlay` | Dark semi-transparent quad covering the playable sector view. Reads `MacroFleet.fowRadius` off every fleet friendly to the local player and packs reveal circles into the shader. The overlay edge alone communicates vision — no per-fleet cyan rings. Auto-disables in Sector Map mode. |
| `SectorMapHUD` | Range rings, beacon icons (faction-filtered), waypoint preview, gate-spool overlay, fleet roster, and the right-edge **fleet launcher dock** (see [Fleet launcher dock](#fleet-launcher-dock)). |
| `SectorTransitionClient` | Plays the fade, loads next scene via Addressables, hands state to PlayFab. |

> The visual NPC simulation between server snapshots is **cosmetic only** — the canonical position is whatever CloudScript returns next time it's queried. Client-side smoothing keeps the world from looking like everyone teleports.

---

## Hooks into existing components

| Existing component | Hook | What changes |
|---|---|---|
| [`TacticalSensorResolver`](../combat/combat_fog_of_war.md#runtime-architecture-todo) | `IsTargetVisible`, `CoverageVolumes` | Lifted into a shared assembly so the macro view consumes it. The resolver is layer-agnostic — it operates on positions and equipped sensors; both layers feed it. |
| `TacticalFlightEngine.aggressors` | Pre-populated from `MacroEntryContext.aggressorIds` on instance spawn | Defender NPCs enter Engage state already targeting the attacker. |
| [`NPCShipSchema`](../Assets/Scripts/Schemas/NPCShipSchema.cs) | `cruiseSpeedSectorKmPerMin` (new field) | Already required by the distress design. |
| [`FleetSnapshot`](../architecture/architecture_data_schemas.md) | (none) | Consumed as-is. `MacroEntryContext` rides alongside, doesn't modify it. |
| `TacticalAnchor` / `TacticalMiningAnchor` / `TacticalPatrolNode` (Ship AI's scene markers) | (none) | The same MonoBehaviour markers double as macro-objective targets — `MacroObjectiveResolver` reads them at sector load time to seed lane / orbit / route data. |

---

## Tunables

| Constant | Default | Where |
|---|---|---|
| `SECTOR_CROSS_TIME_MINUTES` | ~5 (target) | Authoring guideline for `extentsKm` × hull cruise speed |
| `MACRO_ENGAGEMENT_RANGE` | TBD (~few sector-km) | `EngagementService` |
| `JUMP_GATE_SPOOL_SECONDS` | `10` | [Sector Rules §3](world_sector_rules.md) (canonical home) |
| `MAX_NPCS_PER_SECTOR` | `150` | `SectorRosterService` |
| `NPC_ROSTER_REFRESH_SECONDS` | `300` | `SectorSpawner` (replenish kills, not re-tick positions) |
| `MACRO_FOW_BASELINE` | inherits `BASELINE_LOS = 500m` from FOW doc | Resolver constant |
| `WAYPOINT_QUEUE_DEPTH_MAX` | `8` | `MacroFlightController` |
| `INVESTIGATOR_LINGER_SECONDS` | `30` | (Owned by Ship AI; surfaced here for cross-reference) |
| `JOIN_WINDOW_SECONDS` | `15` | (Owned by Ship AI; surfaced here for cross-reference) |
| `DISTRESS_RESPONSE_RADIUS` | `60` sector-km | (Owned by Ship AI) |

---

## Out of scope (follow-up docs)

- **Multi-sector / galaxy nav-map.** Cross-sector planning UI is its own doc.
- **Orbit scene contents.** This doc owns the *boundary* (transition into orbit). Low-orbit layout (orbital structures, capital-ship docks, citadels) belongs in [`world_low_orbit_scene.md`](world_low_orbit_scene.md). Surface gameplay (3D-placed bases, activity-noise radar, permit gate) belongs in [`world_surface_scene.md`](world_surface_scene.md). The original `MMO_Orbit_Scene.md` placeholder was resolved Phase 6.9 with the three-scene split.
- **Docking flow.** Station UI, refit, refinery, market terminal — its own doc, layered on top of the orbit-scene work.
- **Active scanning.** Manual sensor sweeps to reveal hidden objects — flavor for v2.
- **Player-issued distress.** Already flagged for v2 in Ship AI.
- **Mining loop.** `MiningOrbit` is cosmetic in v1 per Ship AI.
- **Alliance citadel construction / sovereignty.** Mentioned in Sector Rules §2C; its own doc.

---

## Open threads

- **Title Data sharding.** ~150 NPCs × ~400 bytes each is comfortable per-sector, but if a sector blows past the cap or rosters grow we'll shard further (per `(sectorId, faction)` or paged). Validate size empirically once content is real.
- **Client-side NPC smoothing model.** Cosmetic interpolation between server snapshots is needed so NPCs don't teleport when a player loads in. Open: tween rate, what happens when the server's resolved position contradicts what the client extrapolated (snap vs. lerp). Snap on > N meters, lerp otherwise; tune empirically.
- **`MACRO_ENGAGEMENT_RANGE` value.** Tune once tactical instance scales are real. Should be smaller than typical macro sensor reach so a stealth ship can sometimes close without being detected.
- **Cross-instance defender state.** If a defender NPC is already in another tactical instance when an attacker tries to engage it, attack is rejected with a "target engaged" message. Spec: client should surface this clearly.
- **Sector handoff for in-flight NPCs.** An NPC reaching the X/Y border needs to migrate from one sector's roster shard to the neighbor's. Spec: CloudScript transactional move with an `inTransit` flag to avoid duplication.
- **Federation police response.** [Sector Rules §2A](world_sector_rules.md) requires an "invincible police fleet" in high-sec. This is implemented as a special role-slot reactive spawn on `RequestEngagement` violations — not separately detailed here, but this doc owns the spawn surface; follow-up balancing pass needed.
- **Active scan + docking** — out of scope by decision; flagged for follow-up doc.
- **Wreckage persistence model.** Sector Rules §4 specifies 2h Golden Wreck despawn. Storing wrecks in Title Data alongside NPCs is the simplest path; revisit if it pressures the size budget.
- **Fleet launcher dock — real launch flow.** v1 ships the dock with a stubbed Launch button. The actual deploy semantics (which fleet members spawn, where, with what AI hand-off) need a follow-up tied to fleet runtime so a future implementer doesn't wire a half-defined launch behind the existing button.
