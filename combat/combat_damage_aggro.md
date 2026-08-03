# MMO Combat Math: Damage & Aggro Formulas

## 1. Damage Mitigation (Shield vs Armor)
This game avoids arbitrary "Level 50 Defense" numbers. Instead, resistance is mechanically segmented between regenerating energy fields and thick ablative plating.

### A. Shield Mechanics (The Buffer)
- **Math:** `ShieldDamageTaken = IncomingDamage * DamageTypeModifier`
- **Modifiers:** 
  - *Energy Weapons:* `1.5x` Damage against shields.
  - *Kinetic Weapons:* `0.75x` Damage against shields.
  - *Explosive:* `1.0x` Damage against shields.
- **Rule:** Shields mitigate 100% of hull damage until they hit 0. They cannot be bypassed except by extremely rare Outlaw Antimatter lances.

### B. Armor Mechanics (The Curve)
Once shields are down, physical armor mitigates damage. 
- **Math (The Armor Curve):** `FinalHullDamage = IncomingDamage * ( 100 / (100 + ArmorRating) )`
- **Logic:** This creates diminishing returns. 
  - An ArmorRating of `100` means `FinalHullDamage = IncomingDamage * 0.5` (50% reduction).
  - An ArmorRating of `300` means `FinalHullDamage = IncomingDamage * 0.25` (75% reduction).
- **Modifiers:**
  - *Kinetic Weapons:* Treat `ArmorRating` as `-50` for the calculation (Armor Piercing).
  - *Energy Weapons:* Treat `ArmorRating` as `+50` for the calculation (poor at melting physical plating).

---

## 2. PVE Threat & Aggro Generation
How NPC Pirates, Federation Police, and Automated Turrets decide who to shoot. Every entity calculates a `ThreatScore` for every player passing through their radar.

- **The Threat Formula:** 
  `Threat = (BaseThreat + DamageDone) * ThreatMultiplier + ProximityWeight`
- **Factors:**
  - **Damage Done:** The highest contributor. You shoot a pirate, they get extremely mad at you.
  - **Proximity:** If Player A is 1000m away and did 500 damage, but Player B is 50m away and did 100 damage, the NPC might prioritize the immediate physically closer threat.
  - **E-War (Huge Multiplier):** Using a Gravity Tether or Jammer on an NPC generates `5x ThreatMultiplier`, forcing the pirate to instantly switch targets to the player locking them down, saving the squishy Damage-Dealers.
  - **Healing/Logistics (Global Threat):** Repair bays generating Hull repairs permanently build threat equally across all NPCs in the room. If a repair ship isn't defended, the swarm will eventually lock onto it.
