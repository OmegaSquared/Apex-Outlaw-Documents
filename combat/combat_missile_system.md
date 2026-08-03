# Missile System — Reference

The missile system models warheads as **mini ships**: manufactured per-unit, one-shot consumable, fly under their own power, can be shot down, and detonate a payload on impact. This doc maps how the schemas, runtime entities, and player input wire together so you can author content and debug behavior without re-reading every script.

> Status: schemas + runtime are in place. Inventory consumption (PlayFab) and networked authoritativeness (Photon Fusion) are deferred — see [Open Threads](#open-threads).

---

## At a glance

```
                                              FIRES                 FLIES               DETONATES
+----------------+   shift+R   +-------------+        +----------+         +---------+
|  Player input  | ---------> |  Bay /      | ---->  | Missile  | ----> | Payload |
| (Fire ctrlr)   |   click    |  Launcher    |        | Entity   |         | Damage  |
+----------------+   target    +-------------+        +----------+         +---------+
        |                            ^                      ^
        | shift+wheel                | TacticalMissileBay   | TacticalMissileEntity
        v                            | TacticalMissileLauncher
+----------------+                   | (both : IMissileMount)
| Mount Selector |
+----------------+
```

---

## Schemas (`Assets/Scripts/Schemas/`)

All five schemas inherit `ItemSchema`, so they get **mass / structural HP curves**, `prefabIdentifier`, `displayName`, `requiredMaterials`, and the auto construction-time formula (`weight × admin_construction_factor`) for free.

### `MissileSchema` — the missile itself
The "mini ship" identity. Carries the cinematic signature, survivability, and references its engine + payload.

| Field | Type | Notes |
|---|---|---|
| `faction`, `missileClass`, `mark`, `version` | enums + ints | Auto-generates `itemID` as `missile_<faction>_<class>_mk<n>_v<n>`. `displayName` stays author-editable so you can ship "Junkyard Hornet". |
| `targetingMode` | `Dumb` / `Smart` | Dumb = lock target position at launch; Smart = chase the moving target each tick. |
| `missileEngine` | `MissileEngineSchema` | Required. Drives thrust / burn / agility. |
| `payload` | `MissilePayloadSchema` | Required. Drives damage on detonation. |
| `rangeMeters` | AnchorCurve | Hard kill-after distance. Beyond this the missile self-destructs harmlessly. |
| `shieldCapacity` | AnchorCurve | Built-in shield (no separate ShieldSchema reference). |
| `durability` | inherited AnchorCurve | Structural HP — when shield + HP collapse the missile is shot down without delivering its payload. |
| `missilePrefab` | GameObject | The flying body / mesh. Spawned at launch. |
| `contrailPrefab` | GameObject | Persistent smoke trail. Reparented to the world on detonation so it dissipates per its own particle lifetime. |
| `explosionPrefab`, `explosionScale` | GameObject + float | Detonation VFX. |
| `firingSound`, `thrusterLoopSound`, `explosionSound` | AudioClips | One-shot at launch, looped during burn, one-shot at impact. **`thrusterLoopSound` should match the ship thruster clip** (`TacticalFlightEngine.engineSound`) for audio consistency. |

> No armor field by design — missiles are shield + HP only.

### `MissileEngineSchema` — propulsion module
| Field | Type | Notes |
|---|---|---|
| `thrustNewtons` | AnchorCurve | F=MA on the missile's mass curve → acceleration profile. Default `15kN → 35kN`. |
| `burnDurationSeconds` | AnchorCurve | After this the engine cuts and the missile coasts on momentum. Default `4s → 8s`. |
| `turnRateDegPerSec` | AnchorCurve | Course-correction agility. Default `20° → 100°/s`. |
| `flareCoreColor`, `flareEdgeColor` | Color | **Same color picker pattern as `EngineSchema`** — author the missile's flame style directly. |
| `flareBaseScale` | Vector3 | Procedural flame size at peak burn. Default sized smaller than ship thrusters (`0.18 × 0.18 × 0.5`). |
| `flareLightRange` | float | Bloom radius of the flame's point light. Default `4m`. |

The exhaust is built at runtime via `TacticalExhaustFactory.BuildExhaust(...)` — the same factory ship engines use. Procedural cross-shaped vertex-colored mesh + URP additive material + tinted point light.

### `MissilePayloadSchema` — warhead module
Pure damage chemistry. No VFX (the missile owns visuals).

| Field | Type | Notes |
|---|---|---|
| `damageType` | `AmmunitionDamageType` enum | Reuses `Kinetic / Explosive / Thermal / EMP` taxonomy. |
| `baseDamage` | AnchorCurve | Direct hit damage. Default `400 → 950`. |
| `blastRadius` | AnchorCurve | AoE radius for splash falloff. `0` = single-target only. |
| `armorPenetration` | AnchorCurve | `0` = surface impact, `1` = ignores all armor. |

**Splash damage** is capped at `0.75 ×` direct damage (`SPLASH_MAX_FRACTION` in `TacticalMissileEntity`), then linearly falls off to `0` at `blastRadius`. This guarantees splash victims always take less than the primary target.

### `MissileLauncherSchema` — single-shot mount
Mounts on a hardpoint with `componentClass = "Missile"`. Holds exactly one pre-loaded missile; rearm at station between battles.

| Field | Type | Notes |
|---|---|---|
| `acceptedMissileSize` | string | "Small" / "Medium" / "Large". Must match loaded missile's `size`. |
| `launchType` | `MissileLaunchType` | `Vertical` / `Forward` / `DropBay`. Default `Forward`. |
| `launchVelocity` | AnchorCurve | Initial kickoff before missile engine ignites. Default `40 → 120 m/s`. |
| `launchVFX`, `launchSound` | GameObject + AudioClip | Tube-side cosmetic on launch. |

### `MissileBaySchema` — multi-shot mount
Mounts on an `Internal` hardpoint. Holds multiple missiles with per-bay reload between launches.

| Field | Type | Notes |
|---|---|---|
| `acceptedMissileSize` | string | All loaded missiles in the magazine must match. |
| `launchType` | `MissileLaunchType` | Default `DropBay`. |
| `capacity` | AnchorCurve | Tubes per grade. Default `1 → 10`. Float curve, floor-rounded to int (`CapacityForGrade(g)`). |
| `reloadTimeSeconds` | AnchorCurve | Per-bay cooldown between launches. Default `8s → 3s`. **Lower-is-better** (F-grade = slowest). |
| `launchVelocity` | AnchorCurve | Same as launcher. |

> **Per-bay cooldowns are independent.** Two bays with 30s reload each: fire bay 1, immediately fire bay 2, then wait. The bay timers don't gate each other — only their own.

### Launch types

| Launch Type | Phase 1 (Launching) | Phase 2 (Cruising) | Use case |
|---|---|---|---|
| `Vertical` | Booster kicks straight up (0.4s, engine off). Then auto-thrusters reorient toward target at 2× turn rate (0.8s). | Pure-pursuit homing. Engine on. | Top-mounted launchers. |
| `Forward` | Forward kickoff, engine ignites immediately. | Quadratic Bézier spline arc to the aimpoint. Last 15% hands off to pure pursuit for terminal homing. | Nose-mounted single-shot launchers. |
| `DropBay` | Free-fall (0.6s, engine off, slight downward gravity bias). | Bézier spline (built fresh after free-fall). | Ventral cargo-class bays. |

### Targeting modes

| Mode | Behavior |
|---|---|
| `Dumb` | `frozenAimpoint` set at launch and never updated. Missile flies to that point regardless of target movement. Cheap, brittle vs. mobile targets. |
| `Smart` | Aimpoint chases the target's `Transform.position` each tick. Bézier endpoint regenerates so the spline follows the target. Authored on better-grade missiles. |

---

## Runtime entities (`Assets/Scripts/Tactical/`)

### `TacticalMissileEntity`
Lives on each in-flight missile (added at spawn by the bay/launcher). Drives the state machine, physics, guidance, and impact.

**State machine:** `Launching → [Reorienting?] → Cruising → Terminal → Detonated`. Reorienting only fires for `Vertical` launches. Engine flame visible only when `(Cruising || Terminal) && burnTimer < burnDuration`.

**Survivability:** `TakeDamage(float)` — shield first, then HP. At `HP ≤ 0` the missile detonates cosmetically without applying its warhead (a "shot-down" — VFX/audio still play so spectators see the kill, but the target is unscathed).

**Lifetime guards:** distance traveled ≥ `rangeMeters` OR `lifeTimer > 30s` (safety) → `Detonate(currentPosition, null)` (no target, no damage).

### `IMissileMount`
Common interface implemented by every per-instance missile mount runtime — `TacticalMissileBay` (multi-shot) and `TacticalMissileLauncher` (single-shot) today, plus any future mount kind. The selector / fire controller / HUD all address mounts through this interface so they don't care which kind they're driving.

| Member | Notes |
|---|---|
| `MountNumber` | Author-facing 1, 2, 3... display number. Selector cycles in this order. |
| `CurrentLoaded` | Missiles ready to launch. |
| `IsOnCooldown` / `CooldownRemaining01` | Per-mount reload signal. Always `false` / `0f` for single-shot launchers (no in-battle reload). |
| `IsEmpty`, `CanFire` | Selectability gates. |
| `TryFire(target, firingShipRoot)` | Returns `true` if a missile dispatched. |
| `LoadedMissile` + `LoadedMissileGrade` | Currently-loaded round; the fire controller reads these to size the targeting range ring. |

### `TacticalMissileBay`
Per-bay-instance state component (implements `IMissileMount`). One per equipped bay slot.

| Property | Notes |
|---|---|
| `schema` | The `MissileBaySchema` asset. |
| `grade` | Forge grade of this specific bay instance (drives capacity + reload + velocity). |
| `bayNumber` | Display number for HUD readout (1, 2, 3...). |
| `loadedMissile` + `loadedMissileGrade` | Missile type + grade currently in the magazine. (Future: pulled from PlayFab inventory.) |
| `launchAnchor` | Optional child Transform marking the missile spawn point. Falls back to bay's own transform. |
| `CurrentLoaded` | Decrements on each fire. Reset to capacity by `Rearm()`. |
| `IsOnCooldown`, `CooldownRemaining01` | Per-bay timer. The HUD radial-sweep widget reads `CooldownRemaining01` and maps it to a clockwise `Image.fillAmount`. |
| `TryFire(target, firingShipRoot)` | Returns `true` if a missile dispatched. Instantiates `loadedMissile.missilePrefab`, attaches `TacticalMissileEntity`, calls `Configure`, decrements load, starts cooldown. |

### `TacticalMissileLauncher`
Per-launcher-instance state component (implements `IMissileMount`). One per equipped single-shot launcher.

| Property | Notes |
|---|---|
| `schema` | The `MissileLauncherSchema` asset. |
| `grade` | Forge grade of this specific launcher instance (drives launch velocity). |
| `launcherNumber` | Display number for HUD readout — shares the 1, 2, 3... numbering with bays so the selector cycles all mounts in a single ordered list. |
| `loadedMissile` + `loadedMissileGrade` | Pre-loaded round. (Future: pulled from PlayFab inventory.) |
| `launchAnchor` | Optional child Transform marking the missile spawn point. Falls back to launcher's own transform. |
| `CurrentLoaded` | `1` while loaded, `0` after firing. Reset by `Rearm()`. |
| `IsOnCooldown`, `CooldownRemaining01` | Always `false` / `0` — single-shot launchers have no in-battle reload. Once fired, the tube is spent for the engagement; `Rearm()` only happens at a station between battles. |
| `TryFire(target, firingShipRoot)` | Same dispatch path as the bay — instantiates `loadedMissile.missilePrefab`, attaches `TacticalMissileEntity`, calls `Configure` with the launcher's `launchType` and grade-resolved kickoff velocity. Latches the spent state on success. |

### `TacticalMissileMountSelector`
One per ship. Scans for any component implementing `IMissileMount` in children (sorted by `MountNumber`) and tracks which one is "active" for firing. Covers bays and launchers in a single ordered list. Listens for **shift + mouse wheel** to cycle when there's more than one mount.

`SelectedMount` getter exposes the currently active mount to the fire controller and HUD.

### `TacticalMissileFireController`
One per player-controlled ship. Runs the fire flow:

1. **Shift + R** — arms the next click as a target-select. Logs why if it can't (no bay / empty / on cooldown). Plays `lockWarningSound` at the ship's position as a **3D-spatialized world sound** — every nearby player hears "this ship is locking on" and has a window to react / maneuver / pop countermeasures before the click confirms. Also shows a `TacticalRangeRing` around the ship at the loaded missile's grade-resolved range so the player can see exactly how far they can target.
2. **Left click** — raycasts from `Camera.main` to find a collider under the cursor. Clicked collider's `transform` becomes the target (supports subsystem-level targeting — clicking an engine collider homes to the engine).
3. Calls `selector.SelectedBay.TryFire(target, transform)`.
4. `Esc` or right-click cancels targeting without firing.

The clicked collider's exact `Transform` is passed in (not just the root), so a `Smart`-targeted missile chases the specific subsystem as it moves with the parent ship.

**Targeting policy: anything but self.** Friendly fire (faction-mates, fleet members, allied factions) is intentionally allowed — players can missile any collider that isn't on their own ship. The lock-warning sound makes the system fair: every potential victim hears the lock before the missile flies.

### `TacticalMissileBayHUD`
Worldspace widget — circle with mount number + analog-clock cooldown sweep. Mounts on the ship root next to `TacticalMissileMountSelector`. Renders south of the ship below the existing stats HUD, only when the ship is locally selected and has at least one equipped mount. Player-facing language stays "Bay" — launchers reuse the same widget by design (their `CooldownRemaining01` is always `0`, so the radial sweep just stays empty, which reads correctly as "ready / spent").

The cooldown overlay is an `Image` with `FillMethod.Radial360`, `fillClockwise = true`, `fillOrigin = Top`. `fillAmount` tracks `mount.CooldownRemaining01` each frame, so the sweep visibly shrinks clockwise as the cooldown expires (just-fired = full overlay, ready = empty). The mount number text comes from `mount.MountNumber`. Cycling via shift+wheel updates the displayed number + cooldown immediately.

The circle sprite is generated procedurally at startup (one shared static `Sprite` across all bay HUDs) — no asset wiring required.

### `TacticalRangeRing`
Reusable flat indicator drawn on the XZ plane around a ship. Built from a procedural mesh with two concentric vertex rings — outer ring fully opaque, inner ring fully transparent — so only a thin band near the radius is visible. The ship in the middle is unobstructed because the interior of the inner edge isn't drawn at all.

Defaults: `bandWidthFraction = 2%` of radius (clamped to a `5m` minimum so very small rings stay legible). Color is a semi-transparent orange. Material is URP unlit alpha-transparent (not additive — additive would bloom out the band against bright skyboxes).

The `TacticalMissileFireController` instantiates one of these per ship and toggles it on Shift+R / off on fire-or-cancel. Same component can later show FOW radii, jammer halos, etc. — just `SetRadius` + `Show`/`Hide`.

### `TacticalExhaustFactory`
Static factory, not a MonoBehaviour. Builds the procedural cross-shaped flame mesh + URP additive glow material + child GameObject with a tinted point light. Used by both `TacticalFlightEngine` (ship engines/thrusters) and `TacticalMissileEntity` (missile thruster) so missiles inherit the same visual style by construction.

---

## Player inputs

| Input | Action |
|---|---|
| **Shift + Mouse Wheel** | Cycle which missile mount is selected (only when > 1 mount; bays and launchers cycle together). |
| **Shift + R** | Arm next click as missile target-select. |
| **Left Click** (while armed) | Resolve target collider, fire selected mount. |
| **Esc** or **Right Click** (while armed) | Cancel targeting. |

---

## Authoring a new missile (asset wiring)

1. **Engine asset** → `Assets/Resources/Schemas/MissileEngines/`. Author thrust / burn / turn rate curves and pick the flame colors directly.
2. **Payload asset** → `Assets/Resources/Schemas/MissilePayloads/`. Author damage / blast radius / AP curves and pick `damageType`.
3. **Missile prefab** → `Assets/Prefabs/Missiles/`. Mesh + colliders for the flying body. The `TacticalMissileEntity` component is added automatically at spawn if missing.
4. **Contrail prefab** → wherever you keep VFX. Configure it as a particle system that lingers and dissipates after the parent stops moving (set Stop Action: Destroy + suitable particle Lifetime).
5. **Explosion prefab + sounds** → standard prefab + audio assets.
6. **Missile asset** → `Assets/Resources/Schemas/Missiles/`. Set `faction`, `missileClass`, `mark`, `version` (auto-fills `itemID`), wire in the engine + payload + prefabs + audio. Pick `targetingMode`.
7. **Bay or launcher asset** → `Assets/Resources/Schemas/MissileBays/` or `MissileLaunchers/`. Pick `launchType` and tune curves.
8. **Hull hardpoint** → on the hull's `hardpoints[]` list, add a `Missile` (for launchers) or `Internal` (for bays) slot with a matching size.

## Wiring a player ship to fire missiles

On the player ship root (the same GameObject that holds `TacticalFlightEngine`):

1. Add a `TacticalMissileMountSelector` component. Set `acceptsLocalInput = true`.
2. Add a `TacticalMissileFireController` component. Set `acceptsLocalInput = true`. (It auto-grabs the selector via `[RequireComponent]`.) Plug in a `lockWarningSound` AudioClip (broadcasts on Shift+R as a 3D world sound).
3. Add a `TacticalMissileBayHUD` component for the on-screen mount readout. (Auto-grabs the selector via `[RequireComponent]`. Optional — skip if you don't want the widget.)
4. Under that ship, add a mount component on each missile-carrying hardpoint — pick the type that matches the schema:
   - **Multi-shot bay** (Internal hardpoint, `MissileBaySchema`): add a `TacticalMissileBay` with:
     - `schema` → the `MissileBaySchema` asset
     - `grade` → forge grade of this bay instance
     - `bayNumber` → 1, 2, 3, ... (in the order the player should cycle through them)
     - `loadedMissile` + `loadedMissileGrade` → magazine contents (future: PlayFab inventory)
     - `launchAnchor` → child Transform at the bay's exit (optional; falls back to the bay's transform)
   - **Single-shot launcher** (Missile hardpoint, `MissileLauncherSchema`): add a `TacticalMissileLauncher` with the same fields, except:
     - `schema` → the `MissileLauncherSchema` asset
     - `launcherNumber` → 1, 2, 3, ... shares the cycle ordering with bays so a ship can mix and match
     - The tube is single-shot — once fired, the launcher is spent for the engagement and rearms only at a station via `Rearm()`.
   - Both kinds implement `IMissileMount`, so the selector / fire controller / HUD work transparently regardless of which is mounted.

NPCs can use the same components but with `acceptsLocalInput = false` and AI-driven `TryFire` calls.

---

## Future weapons in this family

The schemas + entity already support being shot down (shield + HP + `TakeDamage(float)`), but nothing currently shoots at missiles. Two new weapon types are planned to close the loop:

### Interceptor missiles
A `MissileSchema` whose `payload` is tuned for hitting other missiles — small `blastRadius`, high `armorPenetration` (since target missiles have shield + HP, not armor), short `rangeMeters`. Fired from a bay/launcher targeting an enemy missile's `TacticalMissileEntity` via `Smart` mode. Existing fire controller works unchanged — the player just clicks an inbound missile collider.

### Auto near-defense turrets
A new `WeaponSchema` variant that auto-targets nearby `TacticalMissileEntity` instances inside its arc and applies `TakeDamage(...)` per shot. Lives on a `Weapon` or `Turret` hardpoint, runs server-side, no player input. The plumbing is the same as existing weapons; the targeting AI just adds missiles to the priority list.

> Both rely on `TacticalMissileEntity.TakeDamage(float)` already being public — no schema/entity changes needed to add them.

---

## Open threads

- **Networking.** `TacticalMissileEntity` is a plain `MonoBehaviour` matching the existing `TacticalProjectile` pattern. Once point-defense vs. missile combat goes live it should evolve into a Photon Fusion `NetworkBehaviour` with `[Networked]` shield/HP so all clients agree on whether a missile got shot down.
- **Inventory consumption.** `TacticalMissileBay.loadedMissile` is currently authored on the component. When PlayFab inventory wiring lands, each `TryFire` should decrement a missile from the player's stock and refuse to fire if the inventory is empty (separate from the magazine load).
- ~~**Bay HUD.**~~ Built — `TacticalMissileBayHUD` renders the circle + radial sweep widget driven by `CooldownRemaining01`.
- ~~**Single-shot launcher runtime.**~~ Built — `TacticalMissileLauncher` mirrors the bay, holds exactly one round, and exposes the same `IMissileMount` surface so the selector / fire controller / HUD treat it transparently.
- **Ammo-grade tracking.** `TacticalFiringMechanism` samples ammo curves at the weapon's grade as a placeholder. Same compromise applies to missiles whose `payload` curves currently use the missile's grade. Wire ammo / payload inventory grades when the inventory model gets per-stack grade support.
