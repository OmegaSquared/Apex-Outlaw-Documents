# Fog of War (FOW) & Sensors — Reference

Vision in tactical combat is gated by what the player can detect. Every ship has a small baseline line-of-sight; **sensors** (radars) extend it. FOW is shared inside fleets — a designated scout ship lights up enemies for everyone in the same fleet. Spectators see the union of every faction's FOW so observers / streamers / replays have the full picture.

> Status: design only. Schemas (`SensorSchema`) already exist; runtime resolver, fleet-sharing layer, missile-targeting gate, **server-side wide-scope FOW (Phase 6.9.F)**, and **activity-noise base reveal (Phase 6.9.E)** are TODO.

## Three FOW scopes (Phase 6.9 canon)

FOW is **not one shared map.** There are **three independent scopes**, all driven by the same `SensorSchema` math but with different consumers:

| Scope | Owner | Job | Visible to |
|---|---|---|---|
| **My-client FOW** | Each player's client | Renders what THIS player sees — ships, bases, POIs inside the player's combined sensor union | The player who owns it |
| **Server-side FOW** | Server (CloudScript / `ServerFowMatcher`) | Wide-scope; **proactively predicts encounters** and **pre-spawns Fusion runners** before either client has revealed the other | Server only (never returned to clients) |
| **Their-client FOW** | The OTHER player's client | Renders what THEY see — asymmetric, sized from THEIR fleet's sensors | The other player, not me |

**Important consequences:**

1. **The three scopes are independent.** A ship inside the server-FOW (server tracks it) might NOT be inside the enemy player's client-FOW (their client doesn't render it). Stealth ambush mechanics fall out of this naturally.
2. **Fusion spawn is server-authoritative.** When two hostile fleets' wide-FOW circles overlap on the server, a `NetworkRunner` spawns for that cluster **before** either client has revealed the other. The attacker can be inside the server's view without showing up in the victim's client view.
3. **A ship can be networked without being rendered.** Fusion makes a ship a networked client, but the OTHER player's client only renders ships their narrow client-FOW reveals. Hidden combatants are real combat participants but invisible until the FOW lets you see them.
4. **The wide server FOW is rougher.** Adaptive cron 15s baseline ramping to 1s when fleets are approaching. Latency is fine for combat triggering because the attacker hasn't yet entered the victim's tactical FOW — there's headroom.

This canon is implemented in three places:

- **My-client FOW** — the existing `TacticalSensorResolver` + the fleet-vision aggregator described below. Per-frame rendering decisions.
- **Server-side FOW** — NEW `ServerFowMatcher` CloudScript (Phase 6.9.F). Reads `Body_<bodyId>_Presence`, computes wide circles per fleet, detects overlap, spawns / joins `NetworkRunner`s.
- **Their-client FOW** — same code as my-client FOW, running on the other player's client with their fleet's sensors. Each client computes its own FOW independently.

---

## At a glance

```
Each ship          Per-fleet union          Per-faction union          Spectator union
+--------+         +----------------+        +-----------------+        +---------------+
| ship A |         | fleet 1        |        | faction Mars    |        | ALL FOW       |
| ship B | ---->   |   ship A       | -X-X-> | (no auto-share  | -X-X-> | (observer-    |
|  ...   |         |   ship C       |        |  across fleets) |        |  side only)   |
+--------+         +----------------+        +-----------------+        +---------------+
                   shared vision           independent fleets           streaming /
                   inside the fleet        keep separate FOW            replay only
```

Combat math + UI render only what the **viewer's vision union** can see. Targeting only works on colliders inside that union.

---

## Vision tiers

| Tier | Source | Range |
|---|---|---|
| **Baseline LOS** | Every ship gets it for free. Universal — same for all hulls. | `500m` (constant in code). |
| **Sensor mounts** | Equipped `SensorSchema` modules. Stack across multiple sensors with diminishing returns. | Per-grade `sensorRadius` curve on each asset. |
| **Effective FOW** | Per-ship resolved value. | `max(baseline, baseline + bestSensor + 0.25 × sum(otherSensors))` |
| **Fleet union** | Union of every fleet member's effective FOW. | All circles OR'd together. |
| **Viewer union** | What the local client renders. Gameplay = fleet union. Spectator mode = union of every faction's FOW. | Logical, not in world. |

### Stacking formula in detail

Effective sensor contribution for one ship:

```
sensors[]      = every equipped SensorSchema with its forge grade
ranges[]       = sensors[i].SensorRadiusForGrade(grade[i])  for each i
bestRange      = max(ranges)
otherSum       = sum(ranges) - bestRange
sensorReach    = bestRange + 0.25 × otherSum

effectiveFOW   = max(BASELINE_LOS, BASELINE_LOS + sensorReach)
                                  ↑ baseline is added on top so a ship with no sensors still has 500m
```

**Why max + diminishing additive?** Pure max means extra sensors are dead weight (no reason to fit more than one). Pure sum means stacking 4 cheap radars beats 1 strong one (degenerate optimization). The 25%-of-each-other rule keeps both build paths viable: you fit the best radar you can afford, then secondaries pay off but at a discount.

> The `0.25` discount is a tuning lever — it's a constant on the resolver, not in the schema. Bump up if redundancy should pay better; bump down if the meta becomes "stuff every slot with sensors."

---

## Mount classes

Sensors are authored as a single `SensorSchema` type. The hardpoint slot determines what tier fits AND whether the sensor is omnidirectional or directional — different mount, different physical envelope.

| Slot type | Hardpoint `componentClass` | Coverage | Authoring guidance |
|---|---|---|---|
| **Exposed (turret-tier)** | `"Turret"` (shared with weapon turrets) | **Omnidirectional** (full 360°). The antenna physically rotates on the mount, so vision is a circle around the ship. | Long range (4–5km at high grade). Big antenna arrays, jammer-strong (high `eccmStrength`). Fragile — destroyed turret = lost sensor. |
| **Internal (protected)** | `"Internal"` (shared with cargo bays / utility) | **Directional cone** locked to ship-forward (like a fighter jet's nose AESA). The scan arc is a per-asset stat — narrower beams trade coverage for jammer resistance / range. | Shorter range (1.5–3km at high grade). Buried in the hull, harder to knock out. Lower `eccmStrength` (less aperture). Player has to maneuver to keep contact. |

A hull's `hardpoints[]` list mixes both — a frigate might author `1× Turret-class sensor mount` and `2× Internal sensor mounts`. Smaller hulls (interceptors / fighters) typically have only Internal mounts, forcing the "scout silhouette" to actually point at what it's spotting.

> Nothing in code stops a designer from authoring an "internal" `SensorSchema` asset with absurd range or a 360° arc. Discipline lives in authoring, not validation. If this becomes an issue, add a `SensorSchema.expectedMount` enum (Internal / Turret) and warn at equip time.

The schema needs **one new field** (`scanArcDegrees`) to support directional scans; the rest is already in place:

| `SensorSchema` Field | Purpose |
|---|---|
| `sensorRadius` (AnchorCurve) | **In-event** detection range per grade. **Not** added directly to FOW — feeds the stacking formula above. Drives `TacticalSensorResolver`. |
| `sectorRadius` (AnchorCurve) | **Macro / sector-view** detection range per grade. Larger than in-event — strategic radar reach used for the sector dark-overlay reveal, not combat targeting. Feeds the same stacking formula but at the macro layer (`MacroFleet.RecomputeSectorFOW`). |
| `scanArcDegrees` (float, NEW) | Width of the scan cone in degrees. `360` = omnidirectional (turret-tier default). `<360` = directional, locked to the equipped ship's forward axis (internal-tier default, e.g. `90°` forward wedge). Authoring narrower arcs is the lever for "long-range narrow-beam" vs. "short-range wide-coverage" tradeoffs. |
| `eccmStrength` (AnchorCurve) | Resistance to enemy signal jammers. Higher value = less FOW reduction when jammed. (Jammer system TODO — schema field is reserved.) |
| `piercesNebulaDust` (bool) | If true, the sensor ignores the 50% range penalty inside Silicate Nebulas. (Nebula system TODO — flag is reserved.) |

### Directional mechanics

When `scanArcDegrees < 360`, the sensor projects a forward cone of vision rather than a circle:

- Cone apex sits at the equipped ship's position.
- Cone center axis is `ship.forward` (XZ-projected — pitch ignored, this is a top-down tactical view).
- Cone half-angle is `scanArcDegrees / 2`.
- Range is `sensorRadius` per grade as before.

A target is "seen" if it falls inside ANY equipped sensor's coverage volume — directional cones OR the omni circles. Stacking formula still applies for range; coverage is a union of all the volumes.

**No arc is drawn in the world.** Per design: the player knows they have a forward sensor and has to learn to fly the cone. A subtle UI cue (e.g. fading vignette outside the forward arc, or a small radar reticle in the HUD) is fine if needed later, but the world itself stays clean — no firing-arc-style fan visualization to add visual noise.

> Implementation note: the directional check is `Vector3.Angle(ship.forward, target - ship.position) <= scanArcDegrees / 2 && distance <= sensorRadius`. Cheap. Works the same whether the sensor is the only equipped one or one of many — each sensor's volume is tested independently.

---

## Fleet vision sharing

Players inside the same fleet **share vision** — every fleet member contributes their effective FOW to a fleet-wide union. A scout interceptor with a max-grade Turret radar lights up enemies for the whole fleet.

### Resolution rules

1. **Same-fleet** (same `fleet_id` on both viewer and source) → shared. No per-faction or alliance check; the fleet is the unit of trust.
2. **Different fleets, same faction** → NOT shared. Two Mars fleets running parallel ops keep their FOW independent so they can scout-trade or set up flanks without leaking position.
3. **Allied factions** → NOT auto-shared. Players have to coordinate via voice or trade signal-relay items (TODO). Forcing automatic share across factions removes the "you're allies but still wary" texture the lore goes for.

### Performance

The fleet union is computed once per network tick on the server, not per-client per-frame. Each client receives `(fleet_id, fow_circles[])` and renders locally. Cap the number of contributing ships per fleet to a reasonable upper bound (suggest `32` — well above the combat-instance ceiling of 3v3 combatants + 10 spectators = 16 players).

> Edge case: a fleet member whose own ship has zero contribution (just spawned, no sensors, dead in the water) still contributes their baseline `500m`. Useful for "sit on the gate and spot" scout play.

---

## Spectator vision

Spectator mode is a **client-side privilege only** — gameplay logic is unchanged. The spectator client receives the union of every faction's fleet FOW and renders all of it as visible.

### Who's a spectator?

- A user logged in as a spectator role (no controlled ships).
- A player whose own ship has been destroyed and is in observe-the-engagement mode pre-respawn.
- Replay viewers (when replays land).

### What changes

| Subsystem | Player view | Spectator view |
|---|---|---|
| Ship rendering | Only ships inside player's fleet FOW union | All ships in the instance |
| FOW ring overlays | Player's own ship + selected fleet member | Optional — can render every ship's FOW circle with translucent fill, color-coded by faction |
| Targeting | Gated by FOW (see below) | N/A — spectators don't fire |
| Damage numbers / HP bars | Only inside FOW | All visible |

The server still authoritatively decides what each client receives. A spectator's expanded view is a dedicated stream from the server, not a client-side cheat.

---

## Missile-targeting integration

When the player presses **Shift + R** to arm a missile shot:

1. The fire controller pulls the ship's effective FOW (fleet-shared union, since the firing ship is naturally inside it).
2. The visible `TacticalRangeRing` shows `min(missileRange, effectiveFOW)` — players see the actual reach, not the missile's theoretical max.
3. On left-click, the raycast hit's `transform.position` is checked against the FOW union. If outside, the click is rejected with a feedback message — the lock doesn't complete and the cooldown isn't burned.
4. After launch, mid-flight tracking uses the firing ship's FOW at the time of the hit, not at launch. If the target slips out of FOW (jammed, scout died, target outranged the radar), behavior depends on `MissileTargetingMode`:
   - **`Smart`** → the missile loses the homing update and becomes effectively `Dumb`, flying to the last-known aimpoint. It can still hit if the target hasn't maneuvered.
   - **`Dumb`** → no behavior change; Dumb missiles never re-read the target anyway.

Hard refusal on the lock-attempt (rather than soft / blind-fire) is the design choice — it gives the player clean feedback ("you can't see that") and keeps the game readable. Soft / blind fire is reserved for a future `BarrageMode` weapon class if we ever want it.

> Implementation note: the FOW check uses `(targetPos - sourceShipPos).sqrMagnitude <= effectiveFOW²` per fleet member, OR'd. Cheap — same scaling as a click vs. union test in any RTS.

---

## Runtime architecture (TODO)

Components the implementation will need:

### `TacticalSensorResolver` (per ship)
Tracks each equipped `SensorSchema` as a separate **coverage volume** (omni circle OR forward cone) at its grade-resolved range. Exposes:
- `IsTargetVisible(Vector3 worldPos)` — point-in-volume test against the union of all equipped sensors + the baseline LOS circle.
- `EffectiveOmniRadius` — convenience scalar for UI / range-ring rendering when the player has at least one omni sensor (used to size the FOW display ring on the player's own ship).
- `CoverageVolumes` — readonly list of `(center, forward, range, halfAngleDeg)` tuples so the fleet-vision aggregator can union them across ships without re-resolving.

Recomputes on equipment / damage events (lost turret = lost coverage volume → drop from list). Pure data — no rendering. The `0.25` stacking discount applies to the **range** of secondary sensors when computing the omni radius for display, but the visibility check (`IsTargetVisible`) is a clean OR over individual volumes — no math fudge needed there.

### `TacticalFleetVision` (per fleet, server-authoritative)
Aggregates each fleet member's `EffectiveSensorRadius` + position into a fleet-union representation. Pushed to clients in the per-tick networked snapshot. One per active fleet in the tactical instance.

### `TacticalSpectatorVision` (client-only, opt-in)
For spectator clients: subscribes to every faction's `TacticalFleetVision` stream and unions them locally. Drives the spectator's expanded rendering / overlay set.

### Hooks needed on existing components
- `TacticalMissileFireController.AttemptFireAt` — add the FOW check before `selector.SelectedBay.TryFire`.
- `TacticalMissileFireController.ArmTargeting` — clamp the displayed `TacticalRangeRing` radius to `min(missileRange, effectiveFOW)`.
- `TacticalMissileEntity.TickCruising` — if `Smart` and target has slipped out of FOW, downgrade to `Dumb` (use the last-known frozen aimpoint).

### Visualization

**Sector / Solar (Scene 1).** The dark `MacroFOWOverlay` quad is the primary cue — pixels outside the friendly fleet vision union dim under the fog color; pixels inside any reveal circle become transparent. The overlay edge IS the visualization, so per-fleet cyan rings and union-outline meshes have been retired (the previous `MacroFOWView` and `MacroFleetVisionUnion` scripts are gone). On the strategic Sector Map mode the overlay disables itself and `MacroSectorMapVisibility` hides every fleet, so the strategic view is unobstructed.

**Low Orbit / Surface (Scenes 2 & 3) — NEW for Phase 6.9.** The 2D `MacroFOWOverlay` is retired in these scenes (replaced by 3D-native visibility):
- **Per-client FOW spheres** around friendly ships in orbital space — distance-fade volumes that gate which enemy ships render. Cheap; uses the existing `SensorSchema.sensorRadius` math.
- **Decal projectors on planet surface** for surface-base FOW (Scene 3). Only bases inside the fading projection circle render their HUD markers. The bases themselves are always physically rendered in 3D — see Activity-noise radar stealth below.
- The legacy planet-view `MacroFOWOverlay` (Avernus / Praedo) is **deleted in Phase 6.9.H**.

**Tactical (in-event).** TODO — match the macro pattern with a tactical-side dark overlay. Until then the per-ship `TacticalFOWRing` (cyan) and the `TacticalFleetFOWUnionRing` outline carry the load.

- Reuse `TacticalRangeRing` for the ship's own FOW omni component (always visible on selection, distinct color from missile range — suggest a soft cyan vs. the orange missile range).
- **Directional sensors render no world overlay** by design. The player learns the cone by flying. If a UI hint is needed later, a faint screen-space vignette outside the forward arc reads better than yet another world-space wedge.
- Per-fleet-member FOW volumes can be unioned into a single mesh for performance, but a stack of individual `TacticalRangeRing`s (omni only — directional contributors are invisible by design) is fine for prototype.

## Activity-noise radar stealth (Surface — Scene 3)

Surface bases get a **special visibility model** that's separate from ship FOW. The activity-noise system means:

- **Bases are always physically rendered in the 3D world.** A silent base is fully visible if you fly over it visually. Stealth is NOT invisibility.
- **Bases appear as markers on the radar/minimap/HUD** only when generating noise AND nearby enemy sensors detect it.

### How it works

Every active surface base attaches a `BaseNoiseEmitter` MonoBehaviour. It:

1. Watches the base's facility activity (smelter running, forge active, drone build queued, mining laser cutting, etc.).
2. Computes a `NoiseLevel` per-facility-contribution. Idle base = 0.
3. Each tick, checks if any enemy ship sensor (per the standard `SensorSchema.sensorRadius` math) is within the noise emission radius.
4. If yes, this base is added to that ship's `revealed-on-radar` set (which the HUD / minimap renders as a marker).
5. Stop production → `NoiseLevel` decays over ~60 s → base falls off enemy radar markers.

### Consequences

- **Defensive doctrine:** silent operations stay off the radar but remain visually discoverable. Terrain hiding (canyons, behind ridges) matters. Decoy operations matter.
- **Attacker doctrine:** active scouting (visual flyover) is a valid counter-strategy. Don't rely solely on the minimap to find enemies.
- **Stealth is interactive, not binary.** A defender who throttles back their economy gets radar-quiet but pays in production. A defender who runs at full capacity announces their position.

Canon: [`../world/world_surface_scene.md`](../world/world_surface_scene.md) "Activity-noise radar stealth" section.

---

## Jammer system

Jammers are authored on `EWarfareSchema` and equipped per ship. Each equipped jammer is a separate emitter — no per-ship stacking; multiple emitters apply independently and the strongest suppression on a given sensor wins.

### Schema fields (`EWarfareSchema`)

| Field | Purpose |
|---|---|
| `jammerStrength` (AnchorCurve) | Per-grade jamming power. Compared against enemy `SensorSchema.eccmStrength`. |
| `jammerRange` (AnchorCurve) | Per-grade radius of effect. Sensors outside this radius are unaffected. |
| `passive` (bool) | If true the jammer broadcasts continuously while equipped. If false the player toggles it (capacitor-draw integration is future work). |

### Runtime component (`TacticalJammerEmitter`)

One MonoBehaviour per equipped jammer module. Registers itself in a static `activeEmitters` list on enable / disable so the sensor resolver can walk all live emitters cheaply (allocation-free). `IsEmitting` initializes from `schema.passive`; `SetEmitting(bool)` flips the active state for the future toggle UI.

### Suppression formula

For each enemy emitter within `jammer.Range` of the sensor's host ship, per equipped sensor:

```
suppression    = clamp01((jammer.Strength - sensor.eccmStrength) / 100)
effectiveRange = sensorBaseRange * (1 - suppression)
```

Friend/foe uses the same heuristic as the minimap resolver (aggressors list OR faction differs). The effective range then feeds the normal stacking formula above.

---

## Tunables (single source of truth)

Constants the resolver / fire controller will reference. Author these in one place (`TacticalSensorResolver`) so balance can be retuned without grepping:

| Constant | Default | Meaning |
|---|---|---|
| `BASELINE_LOS` | `500m` | Free vision every ship gets. |
| `STACKING_DISCOUNT` | `0.25` | Fraction of each non-best sensor's range that adds to the resolved reach. |
| `MAX_FLEET_VISION_SOURCES` | `32` | Safety cap on contributing ships in the fleet union. |
| `JAMMER_PENALTY` (TODO) | TBD | Per-tick range reduction inflicted by enemy jammers (mediated by `eccmStrength`). |
| `NEBULA_PENALTY` (TODO) | `0.5` | Range multiplier inside Silicate Nebula volumes (bypassed by `piercesNebulaDust`). |

---

## Open threads

- **Server topology.** The fleet union resolver must run server-authoritative (Photon Fusion `NetworkBehaviour`) — clients can't be trusted with vision info they shouldn't have. Push the per-fleet circle list as a `[Networked]` snapshot.
- **Wallhack prevention.** Even with server-authoritative vision, the client receives world-state for ships in its fleet's FOW. A modded client could in theory render that data outside the FOW. Mitigation: server only sends ship transforms / state for ships actually inside the viewer fleet's FOW union. Ships outside FOW get filtered out before serialization.
- **Nebula volumes.** `piercesNebulaDust` flag exists but no nebula trigger volumes yet. Likely a per-sector authored volume that applies a multiplier inside its bounds, gated by the schema flag.
- **Per-hull baseline LOS override.** Currently universal. If specific hulls should see further (dedicated scout silhouettes), promote `BASELINE_LOS` to a `ShipSchema.baselineSensorRadius` override that defaults to the constant.
- **Fleet membership data source.** Where does `fleet_id` live? Player profile, networked component, or PlayFab title data sync? Out of scope for FOW; needs answering before the resolver lands.
