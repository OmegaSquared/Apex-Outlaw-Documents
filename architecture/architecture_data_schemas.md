# MMO Data Schemas & Class Architecture TDD

## 1. The "Double-Schema" Philosophy
To maintain absolute security and modularity, the game utilizes two distinct JSON blueprints. 

1. **Static Schema:** The universal truth about an item (stored globally).
2. **Instance Schema:** A player's specific, unique version of that item (stored on their PlayFab account).

The final stats of an item in combat are a merged calculation performed dynamically by the server, preventing players from hacking stat blocks directly.

---

## 2. Global Static Schema (The Blueprint)
This defines what an item fundamentally *is*. It applies to everyone.

```json
{
  "ModuleID": "WPN_RAILGUN_T1",
  "Name": "Federation Standard Railgun",
  "Type": "Kinetic_Weapon",
  "VisualPrefab": "Assets/Ships/Weapons/PFB_Railgun.prefab",
  "BaseStats": {
    "Damage": 50,
    "HeatDraw": 15,
    "EnergyCost": 5,
    "Cooldown": 2.5
  },
  "RequiredElements": {
    "Steel": 100,
    "Tungsten": 50
  }
}
```

---

## 3. Player Instance Schema (The Loadout)
This is what sits in the player's inventory datastore. Notice how it only stores the `ModuleID` and the player's `ResearchValue`.

```json
{
  "InstanceUID": "a1b2c3d4-xxxx-yyyy",
  "OwnerID": "PlayFab_User_5928",
  "ModuleID": "WPN_RAILGUN_T1",
  "Condition": 100.0,
  "ResearchValue": 12345, 
  "MarketChecksum": "0xABC123Hash"
}
```

---

## 4. The Server Resolver (Combat Math & The Bounding Box)
When the ECS combat instance spins up, the Server dynamically interpolates the final stats using the Item's Min/Max bounding variables against the player's PartInstance Quality score.

**Formula Example (Lerping between bounds):**
`Ratio = Mathf.Clamp01(QualityScore / 12345.0f)`
`FinalWeight = Mathf.Lerp(maxWeight, minWeight, Ratio)`
`FinalDamage = Mathf.Lerp(minDamage, maxDamage, Ratio)`

Using the C# Unity Schema variables:
If `maxWeight` = 50 and `minWeight` = 20, a `12,345` Quality module weighs exactly 20. 
A flat `1` Quality module weighs 50.

If a player brings a poorly researched `Quality: 1000` Railgun, its mass is fundamentally heavier, it tracks slower, and its output is strictly weaker.

---

## 5. Ship Loadout Schema
Defines what a ship currently has equipped. Passed directly to Photon to build the ECS Entity.

```json
{
  "ShipInstanceUID": "hull_xyz_999",
  "HullID": "HULL_FRIGATE_T2",
  "CurrentHP": 5000,
  "Slots": {
    "Weapon_Left": "InstanceUID_Railgun_1",
    "Weapon_Right": "InstanceUID_Railgun_2",
    "Reactor_Core": "InstanceUID_Reactor_T1",
    "E_War_Main": "InstanceUID_Jammer_T3"
  }
}
```

---

## 6. The FleetSnapshot Structure (Macro to Micro Payload)
Because of the "Modify ➔ Launch ➔ Fight" sequence, the server bundles the Ship Schema and all its child modules into a single, immutable snapshot parameter to send to the Photon ECS Instance.

This JSON payload is the "absolute truth" of the combat room:
- **HullID:** Creates the ECS base Entity (determines Base Mass, Turn Rate).
- **SubEntityID (Linked Array):** Maps the `ModuleID` to its specific `HardpointID` defined in the ShipSchema, determining exactly where on the 3D model the ECS system should render the turret tracking.
- **Finalized Multipliers:** The server does the math *before* the match starts. The JSON payload doesn't hand Photon the formula `Lerp(min, max, ratio)`, it hands Photon a hardcoded `100 Damage` integer to save CPU cycles inside the high-tickrate simulation.

---

## 7. The Technology Tree & Fog of War Schemas
The economy gates physical progression through two specific schemas implemented into the Unity Architecture:

**1. TechnologySchema:**
Intangible network nodes. Players must permanently burn extremely high-quality Refined Materials to "Unlock" a Tech Node on their PlayFab JSON. Without the prerequisite technology node, the Item Blueprints (like Titanium Armor) remain mathematically locked.

**2. SensorSchema & EWarfareSchema (The Fog of War):**
Specialized schema expansions to enforce strict "Information Economy" rules.
- **SensorSchema:** Dictates visual Fog of War limitations (`minSensorRadius`, `maxSensorRadius`, and `eccmStrength` against jams). High quality versions can physically pierce Soft-Cover Silicate Nebulas without the 50% detection penalty.
- **EWarfareSchema:** Driven entirely by Quality bounds. If an active `JammerStrength` mechanically outscores the target's `ECCMStrength`, the target forcibly loses their minimap UI, enemy health bar UI, and breaks all active Smart Tracking locks.
