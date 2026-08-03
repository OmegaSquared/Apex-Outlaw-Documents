# MMO Combat Mechanics: Technical Design Document

> **Phase 6.9 context (2026-05-29):** Combat happens in **three contexts**: hyperspace intercept (existing blank-space testfleet sandbox), Low Orbit combat (Scene 2 — capitals allowed), and Surface combat (Scene 3 — non-capital only, capitals stay in orbit). All three use the same `TacticalFlightEngine` mechanics described in this doc. The differences are entry path, what ship classes are present, and visual backdrop. Canon: [`combat_overview.md`](./combat_overview.md), [`combat_fog_of_war.md`](./combat_fog_of_war.md), [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md), [`../world/world_surface_scene.md`](../world/world_surface_scene.md).

## 1. Overview & Core Philosophy
The combat module for this hybrid MMO is designed for an authoritative **ECS (Entity Component System)** environment (e.g., Photon Quantum / Fusion). Combat must be stateless, predictable, and physics-based to allow for rollback netcode and dense player clusters. 

Unity `GameObjects` will strictly act as visual shells (VFX, Audio, Rendering) driven by the pure C# struct data of the ECS simulation. The "rock-paper-scissors" loop relies on **Locomotion, Heat/Energy Management, Electronic Warfare (E-War), and Environmental line-of-sight (LoS).**

---

## 2. Flight Dynamics & Locomotion (Physics)
Movement is the foundation of engagement and escape. Ships do not stop instantly; they are subject to simulated inertia.

- **Mass & Inertia:** Each ship tier has a base `Mass`. Freighters accelerate slowly but are hard to push; fighters accelerate rapidly.
- **Thrust Vectors:**
  - `ForwardThrust`: The primary acceleration force.
  - `StrafeThrust`: Lateral velocity capability (crucial for dodge maneuvers).
  - `TurnRate` (Rotation Speed): Degrees per second a ship can pitch/yaw.
- **Top Speed Limits:** Implemented through a simulated "Drag" coefficient that scales with velocity to naturally cap speed without hard collision walls.
- **Collision & Avoidance:** Boid-based separation logic or predictive Raycasting avoids mass clustering and clipping. 

---

## 3. Targeting & Tracking Systems
Weapons require a target to function fully, dividing engagements into "Smart" and "Dumb" fire states.

- **Radar Signature:** Every ship emits a signature. Firing weapons or using thrusters expands the signature radius.
- **Dumb Fire:** Projectiles are fired strictly along the weapon barrel's local Z-axis. Uses zero targeting resolution.
- **Smart Targeting (Lock-On):** 
  - Requires target to be within a `SensorsRadius` and unbroken Line-of-Sight (LoS).
  - Enables "Gimbal/Turret Tracking" where the weapon auto-rotates toward the target, bound by restricted **Firing Arcs** (e.g., 45-degree front cone).
  - **Projectile Leading:** Smart targeting actively calculates target velocity and distance to aim at the predictive intercept point.
- **Targeting Rotation Speed:** Heavy artillery turrets turn slowly; light point-defense cannons track rapidly. Evasive maneuvers can outrun heavy turret tracks.

---

## 4. Weapon Mechanics & Resource Management
Holding the trigger indefinitely is penalized through heat and energy management.

### A. Heat System (The Thermal Grid)
- **Heat Generation:** Firing generates a specific heat value per shot.
- **Heat Sinks:** Ships dissipate a flat amount of heat per second. (Can be upgraded via Alchemy materials like *Thermal Paste* or *Cryo-Coolants*).
- **Overheating:** Reaching 100% heat initiates a mandatory "Venting Sequence." Weapons are locked, and the ship's radar signature aggressively expands for a duration (e.g., 5 seconds).

### B. Energy / Capacitor System
- **Capacitor Storage:** The maximum energy a ship can hold.
- **Draw Rate:** Shields, Energy Weapons, and E-War modules drain the capacitor.
- **Regen Rate:** Core reactors replenish energy passively. If a player drains their capacitor, energy weapons cannot fire, and shields halt regeneration.

### C. Damage Types
- **Kinetic (Railguns/Autocannons):** Heavily impacts Hull/Armor. Minimal effect on Shields. Draws small energy, high heat.
- **Energy (Plasma/Ion):** Devastates Shields. Minimal effect on Hull. Draws high energy, low heat.

---

## 5. Defense Systems (Survivability Layers)
Damage mitigation and vehicle destruction follows a highly rigorous multi-tier lifecycle:

- **Shields (Regenerative):** Takes 100% of incoming damage first via the Capacitor grid. Disabled organically on Civilian Freighters to emphasize massive static armor blocks instead.
- **Armor / Hull (Strategic Buffer):** Once shields drop, Armor mitigates damage dynamically based on equipped modules (e.g. CFS Freighters start with a monolithic 1000f block).

### The Dual-Layer Annihilation Mechanics
To allow ships and discarded cargo to function organically as physical wreckage, ships do not instantly disappear when defeated:
- **Tier 1 (Core Shutdown / Drifting Husk):** When nominal `currentHealth` drops to 0, engines disable, cargo un-parents, and the husk enters a permanent zero-damping physical drift. Autonomous turrets aggressively conserve ammunition and *immediately drop target locks* on any target entering Tier 1.
- **Tier 2 (Structural Annihilation):** The dead husk exposes its hidden `structuralIntegrity` layer (which scales identically to its original HP). Players can use the Tactical Selection Manager to explicitly *right-click* and issue manual termination-orders on dead husks. If Structural Integrity hits zero, the ship undergoes total geometric annihilation, spawning proportional physical `debris_junk` corresponding to its surviving colliders.

---

## 6. Electronic Warfare (E-War) & Utility
Non-lethal modules designed for control and disruption based on Alchemy values.

- **Jammers (Signal Disruption):** 
  - Targeted debuff that forcefully breaks Smart Targeting locks.
  - Against players: Blanks out the minimap, scrambles UI, and hides enemy health bars.
- **Gravity Tethers (Tractor Beams):**
  - Severely cuts the `TopSpeed` and `StrafeThrust` of the target, preventing escape. 
  - Has a maximum tether range. If the target manages to break distance, the tether snaps.
- **Energy Siphons:** 
  - Drains the target's Capacitor and transfers a percentage back to the attacker, shutting down their energy weapons.
- **ECCM (Counter-Measures):** Defensive sensor suites that resist Jammer strength. If `ECCM_Value > Jammer_Value`, the debuff duration is slashed.

---

## 7. Environmental Hazards & Terrain
Space geography forces tactical repositioning.

- **Asteroid Fields (Hard Cover):** Physically block projectiles and immediately break Smart Targeting LoS.
- **Silicate Dust / Nebulas (Soft Cover):** Reduces the `SensorsRadius` by 50%. Ideal for smuggling or ambushes.
- **Plasma Storms (Hazard Phase):** Slowly drains Shields to 0% and disables regenerating while inside. Creates high-risk/high-reward flanking routes.
- **Cryo-Clouds:** Drains Ship Capacitor at a rapid rate, shutting down energy weapons and E-War modules.

---

## 8. The Scavenging "Tow" State (Asymmetric Combat)
When a player secures a wreck to pull intact components and roll for the wreck's **Repair Recipe** ("Golden Logic" — see [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md) §4), they enter a vulnerable state. Note: stolen components go straight into inventory and can be fitted / repaired / sold — they cannot be manufactured into duplicates without the original Researcher's Seed.

- **The Towing Debuff:** Towing a destroyed chassis applies a massive drag scalar (`TowDrag_Multiplier = 0.3x speed`). 
- **The Pirate Beacon:** Activating a tow cable immediately broadcasts a global UI marker to the current Sector map: `"Salvage Operation Detected."`
- **Towed Physics:** The wrecked hull becomes a joint-tethered Rigidbody dragging behind the player, susceptible to asteroid collisions and physics bouncing if the player flies too erratically. This turns extraction into a highly defensive escort sequence.

---

## 9. Sub-Entity Targeting (Tactical Dismantling)
Because combat is calculated via ECS, every 3D model is functionally a collection of "Child Entities" (Weapons, Engines, Radars) parented to the main Ship Hull. Players can tactically break these components to cripple a ship without destroying it.

- **Ablative Hardening (The Module Armor Curve):** Modules are protected under the ship's massive global Shield Buffer. Once shields are down, modules calculate damage using a specialized hardening curve: `FinalModuleDamage = IncomingDamage * (100 / (100 + ArmorRating + 50))`. Meaning, you need exceptionally high-penetration Kinetic Railguns to "snipe" an engine block.
- **Tactical Breaches:** 
  - **Engine Kill:** Destroys Thrusters. Results in a stackable -25% penalty to `ForwardThrust` and `TurnRate`. *Required step to successfully attach a Towing Cable to a target.*
  - **Radar Kill:** Reduces `SensorsRadius` by 70%, completely breaking the target's ability to "Smart Lock" weapons.
  - **Reactor Kill:** Halves `Capacitor Regen`, eventually forcing energy weapons offline.
- **The Scavenger's Dilemma:** You can snipe a Dreadnought's guns to win the fight safely, but **destroying a module destroys the loot** — both the intact stolen component and the chance of rolling its Repair Recipe ("Golden Logic"). A safer fight produces a poorer wreck. Win choices are real.

---

## 10. Hybrid Visuals & Damage FX (Schema-Driven ECS)
Visualizing combat trauma is heavily optimized for massive scale, employing a Hybrid ECS structural pipeline that mechanically buffers geometry modifications without stalling the main thread.

- **The GPU Bridge (`TacticalDamageRenderer`):** Ships naturally construct an ECS proxy entity upon spawning. Damage events natively feed into a `FixedList4096Bytes` struct buffered by the Burst compiler (preventing internal 32-element array clipping). This array pumps strictly into assigned `DamageFX_URP` materials mapped on the vessel. Cargo automatically dynamically acquires its own rendering matrix upon detachment.
- **Schema-Driven Weapon FX (Roadmap):** To elegantly uncouple rendering from base shader logic, future weapon arrays will be completely dictated by `WeaponDamageProfile` ScriptableObjects attached natively to the hull schema. This enables precise per-weapon visual instantiation (e.g., Artillery Spawns vs Energy Spawns) securely managed at the `TacticalHitbox.ApplyPrecisionDamage` layer.
