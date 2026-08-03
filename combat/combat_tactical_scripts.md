# MMO Tactical Scripts Architecture Overview

The `ApexOutlaw.Tactical` namespace houses the core deterministic simulator logic for all in-game ship combat and environments. The following is a comprehensive architectural breakdown of every script actively governing the physics, targeting, and visual pipelines.

---

### Core Engineering & Vitality
* **`TacticalFlightEngine.cs`** 
  The single most structurally complex engine powering every ship. It organically parses the hull schema and attached modules to calculate literal Newtonian drag, rigid-body mass, multidirectional thrust arrays, and defense capabilities (Armor/Shields/Capacitor). This natively ensures all combat is 100% physically deterministic.
* **`TacticalHitbox.cs`** 
  The structural receptor for all physical collisions. Maps damage securely to individual components, processes the "Dual-Layer Annihilation" (Tier 1 Shutdown vs Tier 2 Wreckage Detonation), and triggers the newly implemented `WeaponDamageProfile` shader rendering commands upon penetration.

### Weapons & Artificial Intelligence
* **`TacticalTurretAI.cs`** 
  The automated aiming brain. Natively respects ammo conservation (explicitly dropping locks on drifting/dead husks) and manages Gimbal tracking to predictive target intercept points using Line of Sight.
* **`TacticalWeaponArc.cs`**  
  Calculates restriction zones. Mathematically restricts turret rotation angles based on the physical socket they are welded into (e.g., stopping guns from physically clipping/firing through their own hull).
* **`TacticalFiringMechanism.cs`** 
  The literal trigger mechanism. Executes the actual round discharge, generates standard muzzle-flash VFX, and structurally links the specific `AmmunitionSchema`/`WeaponDamageProfile` to the bullet organically before it launches.
* **`TacticalProjectile.cs`** 
  The roaming physical bullet payload. Handles Raycast trajectory mapping independently, brutally detonates exactly on impact with both living objects and the `Environment` layer (dead wreckage), and pushes its inherited Damage Schema into the target's hitbox.

### User Interface & Input Commands
* **`TacticalSelectionManager.cs`** 
  The RTS (Real-Time Strategy) command interface. Allows the commander to right-click targets in 3D space to issue manual hit orders, forcefully overriding the Turret AI to track dead husks or specific cargo modules.
* **`TacticalShipHUD.cs`** 
  The dynamic tactical ring beneath every vessel. Organically reads the `TacticalFlightEngine`'s live states to map exact health, armor, and shield layers. It intuitively collapses unpowered UI elements explicitly the millisecond the core shuts down.

### Ecosystem & Graphics
* **`TacticalDamageRenderer.cs`** 
  The ECS GPU bridge. Safely reads the mathematically aggressive Entity Component System (Burst Compiler) data arrays and injects them directly into the target's Universal Render Pipeline (`DamageFX_URP`) materials to render glowing score marks completely free of C# thread lag.
* **`TacticalExplosiveCargo.cs`** 
  Handles isolated detonations for specialized environmental obstacles that can be triggered tactically during dogfights.
* **`TacticalCameraController.cs`** 
  Provides smooth, decoupled isometric tracking of targeted vessels during intense maneuvers without aggressive screen-shake clipping.

### Fleet Spawning & Simulation Bootstrapping
* **`TacticalFleetLoader.cs`** 
  The authoritative Shipyard-to-Combat loader. Pulls down the Commander’s exact drafted profile from the PlayFab servers, natively streams the raw Hull geometries via Unity Addressables, and asynchronously welds every engine and turret onto the ship recursively in real-time.
* **`TacticalSimulatorBootstrapper.cs`** 
  Initializes the overall test arena, building the scene topology natively, wiping illegal legacy code combinations, and rendering an authoritative exit UI strictly to break network loops gracefully.
* **`ShipLoadoutConfig.cs`**
  A structural configuration data script bridging logic for specific loadout formatting across networked transitions.
