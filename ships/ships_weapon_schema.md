# MMO Weapon Schema & Definitions

This document defines the C# data structure for Weapon Modules. It is designed to act as the deserialized blueprint that both PlayFab (Server) and Photon (ECS) read from.

## The Weapon Struct

```csharp
[System.Serializable]
public struct WeaponSchema
{
    // Identification
    public string ModuleID;        // e.g., "WPN_PLASMA_T3"
    public string Name;            // "Helium-Plasma Caster"
    public WeaponMount MountType;  // Enum: Fixed, Gimbal, Turret
    public DamageType DmgType;     // Enum: Kinetic, Energy, Explosive

    // Core Combat Mathematics
    public float BaseDamage;       // Final damage = BaseDamage * AlchemyResearchMultiplier
    public float ProjectileSpeed;  // Units per second (ECS physics)
    public float Cooldown;         // Seconds between shots
    public float MaxRange;         // Maximum distance before projectile despawns/fizzles

    // Resource Draw
    public float EnergyCost;       // Capacitor drain per shot
    public float HeatDraw;         // Heat generated per shot (requires venting)

    // Tracking & Servos (Weapon's Mechanical Limit)
    public float MaxWeaponArc;     // Fixed=0°, Gimbal=45°, Turret=360° max capability.
    public float TrackingSpeed;    // Degrees per second it can rotate to face a target
}

public enum WeaponMount { Fixed, Gimbal, Turret }
public enum DamageType { Kinetic, Energy, Explosive }
```

---

## 2. Resolving the "Shooting Through the Ship" Problem
A Turret might mechanically have a `MaxWeaponArc` of 360°, but if it is attached to the side of a Frigate, 180° of that sweep is blocked by the ship's own fuselage.

Because of this, **the Weapon has no concept of what is behind it**. The weapon simply asks the `Hardpoint` it is attached to: *"What are my physical clearance boundaries?"*

During the ECS combat simulation, the final Firing Arc is calculated dynamically as the **Intersection** between the Weapon's `MaxWeaponArc` and the Ship Hardpoint's physical hull obstructions. (Detailed in `ships_schema.md`).

---

## 3. How to Create a New Weapon Pipeline

Adding a new weapon to the game involves creating the visual representation and the deterministic schema data that powers the server-side calculations.

### Step 1: Create the Weapon Visuals (Prefab)
1. **Model & Prefab**: Import your 3D model and assemble the weapon prefab.
2. **Effects**: Attach required ECS link components or Forge3D scripts (e.g., muzzle flashes, barrel rotators, laser sights).
3. **Addressables**: If your pipeline dynamically loads them, ensure the prefab is mapping in your `Default Local Group.asset`. **Note its exact addressable key or name** (e.g. `front_facing_plasma_cannon`).

### Step 2: Create the Weapon Schema (ScriptableObject)
The `WeaponSchema` acts as the single source of truth for both Photon/ECS (Client) and PlayFab (Server).
1. Navigate to `Assets/Resources/Schemas/Weapons`.
2. Right-click and choose **Create -> Apex Outlaw -> Schemas -> Weapon Schema**.
3. Name it appropriately (e.g., `wpn_plasma_cannon_front_01_schema`).

### Step 3: Configure the Schema Properties
Select the resulting `.asset` and set up the critical combat rules:

- **itemID**: A unique programmatic name (e.g., `wpn_plasma_cannon_front_01`).
- **prefabIdentifier**: MUST exactly match the Prefab/Addressables key from Step 1.
- **Weapon Type & Damage**: Set whether this is `Energy`, `Kinetic`, or `Explosive`. Adjust Base Damage.
- **Heat Generated Per Shot**: For energy/plasma weapons, heavily penalize the ship's reactor here.
- **Firing Cone Angle**: Restrict the `firingConeAngle`. For a traditional 360-degree turret, use `360`. For a front-facing or fixed weapon (like a fixed plasma caster), restrict this to something closer to `30` or `90` degrees. This statically clamps the weapon's trackable rotation during combat regardless of where it is mounted. 
- **Mechanical Tracking Speed**: Define how quickly the weapon barrel can pivot to track a moving target (`min/maxMechanicalTrackingSpeed`).

### Step 4: Inject into Gameplay Data
Once the schema is populated, add the `itemID` string to the appropriate Drop Tables (Loot), Shipyard default manifests, or crafting matrices so that players and NPC ships have the authorization to install the weapon.
