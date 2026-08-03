# MMO Ship Schema & Hull Definitions

This document defines the C# data structure for ship frames. It solves the physical geometry problem of weapons firing through their own hull by defining strict obstruction limits on the hardpoints themselves.

---

## 1. The Hardpoint Struct
A hardpoint is a dedicated slot on the hull model. It defines exactly where a weapon sits and, crucially, what physical obstructions exist around it.

```csharp
[System.Serializable]
public struct HardpointData
{
    public string SlotID;           // e.g., "Left_Wing_Weapon_01"
    public SlotSize Size;           // Enum: Small, Medium, Large, Capital
    
    // Physical Geometry (ECS Spawn Points)
    public Vector3 LocalPosition;   // The XYZ coordinate of the mount relative to the ship center.
    public Vector3 DefaultFacingDir;// At rest, where does this gun point? (Usually Vector3.forward)

    // The Hull Clearance Limits (Solving the "Shooting Through the Ship" bug)
    // Degrees relative to the DefaultFacingDir.
    public float MinYawLimit;       // e.g., -45° (Blocked by the bridge if turning further left)
    public float MaxYawLimit;       // e.g., +180° (Completely open space to the right/rear)
    public float MinPitchLimit;     // e.g., -10° (Cannot aim sharply down because of the wing)
    public float MaxPitchLimit;     // e.g., +90° (Can aim directly "up" into space)
}

public enum SlotSize { Small, Medium, Large, Capital }
```

---

## 2. The Final Combat Calculation (Weapon + Hardpoint)
When a player equips a Turret (`MaxWeaponArc = 360°`) into `"Left_Wing_Weapon_01"`, the ECS tracking logic runs this resolution function every frame:

```csharp
// Pseudo-code for ECS Target Tracking
float finalMinYaw = Mathf.Max(-Weapon.MaxWeaponArc / 2f, Hardpoint.MinYawLimit);
float finalMaxYaw = Mathf.Min(Weapon.MaxWeaponArc / 2f, Hardpoint.MaxYawLimit);

// Result: The Turret wants to spin 360, but the final Max Yaw is clamped by the Hull's geometry.
// The turret will stop rotating right before its barrels clip into the cockpit.
```

---

## 3. The Core Ship Schema
The overarching struct defining the base chassis that players purchase or manufacture.

```csharp
[System.Serializable]
public struct ShipSchema
{
    // Identification
    public string HullID;           // e.g., "HULL_FRIGATE_FEDERATION_T2"
    public string Name;             // "Aegis-Class Frigate"
    public HullClass ClassType;     // Enum: Fighter, Frigate, Cruiser, Freighter

    // Core Physics Bounds
    public float BaseMass;          // kg. Determines F=MA acceleration in ECS.
    public float BaseTurnRate;      // Base chassis rotation speed (affected heavily by total mass)
    
    // Survivability
    public float BaseHullHP;        // Raw structural integrity
    public float BaseArmorRating;   // Mitigation factor against Energy vs Kinetic
    
    // Slots
    public HardpointData[] Hardpoints; // Where weapons/jammers are attached.
    public int MaxCapacitorSlots;      // How many reactor cores it can hold.
    public int CargoCapacity;          // Total volume (m³) for raw ore/goods.
}

public enum HullClass { Fighter, Frigate, Cruiser, Dreadnought, Freighter, Tug }
```
