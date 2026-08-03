# MMO Ship Hulls & Classes TDD

## 1. Classification Overview
Ship hulls are the rigid physical chassis that limit what modules a player can equip. A hull dictates the base `Mass`, `BaseHP`, `BaseTurnRate`, and the exact number of hardpoints available. 

---

## 2. Core Ship Archetypes

### A. Striker Craft (Fighters & Interceptors)
*Nimble, cheap, high-risk. Built for dogfighting and scrambling.*
- **Interceptor:** 
  - *Hardpoints:* 2x Small Weapons, 1x Small Reactor, 1x Utility (Usually E-War Jammer).
  - *Role:* Extreme top speed. Used to chase down Transporters or outrun turrets. Paper-thin armor.
- **Heavy Fighter:**
  - *Hardpoints:* 4x Small Weapons, 2x Small Reactor, 1x Medium Shield.
  - *Role:* The backbone of Outlaw swarms. Can overwhelm massive ships if working together but easily destroyed by Flak batteries.

### B. Escorts (Frigates & Destroyers)
*The workhorses of the fleet. Slower but capable of equipping Medium-tier tracking weapons.*
- **Frigate:**
  - *Hardpoints:* 2x Medium Weapons, 2x Small Weapons, 1x Medium Reactor, 2x Utility.
  - *Role:* Balanced combatant. Usually fits Anti-fighter loadouts to protect Cruisers.
- **Destroyer:**
  - *Hardpoints:* 4x Medium Weapons, 1x Large Reactor.
  - *Role:* High-damage output against larger ships. Often the primary user of Plasma Casters and Railguns.

### C. Capital Class (Cruisers & Dreadnoughts)
*Massive, slow, high-maintenance status symbols.*
- **Heavy Cruiser:**
  - *Hardpoints:* 2x Large Weapons, 4x Medium Turrets, 1x Large Reactor, 3x Utility.
  - *Role:* Tanking and siege warfare. Requires an immense energy grid to function. Often requires an escort of Frigates to avoid being swarmed.
- **Dreadnought / Flagship:**
  - *Hardpoints:* 1x Capital (Spinal) Weapon, 8x Small Turrets, 2x Capital Reactors.
  - *Role:* Alliance prestige ships. Used strictly to bombard enemy Citadels. Extremely vulnerable to Electronic Warfare and torpedoes.

### D. Industrial & Support Class (Non-Combat)
*Vital for the economy and recovery. Extremely slow acceleration.*
- **Heavy Freighter:**
  - *Hardpoints:* 1x Medium Turret (Defense), Massive Cargo Hold.
  - *Role:* Transporting raw ore to Hubs. The prime target for Pirates.
- **The "Tug" (Scavenger Rig):**
  - *Hardpoints:* 1x Small Weapon, 2x Heavy Towing Cables, 1x Utility.
  - *Role:* The only ship capable of latching onto capital wrecks to harvest Golden Logic without severely draining its own engines.
- **Mobile Refinery:**
  - *Hardpoints:* 1x Small Weapon, 1x Mobile Lab.
  - *Role:* Process raw ore in deep space to bypass the 35% Federation tax, but broadcasts a massive radar signature. 

---

## 3. The "Mass vs Thruster" Physics Constraint
In the ECS implementation, you do not assign a fixed "Speed" to a ship. 
- The Hull inherently provides `TotalMass`.
- Every equipped module (Weapons, Reactors) adds to `TotalMass`.
- The ship's `EnginePower` is pushed against the `TotalMass` using `F = MA` (Force = Mass * Acceleration).
- Therefore, a heavily armored Frigate with massive Railguns will turn and accelerate significantly slower than the EXACT SAME Frigate stripped down with lightweight Carbon-Fiber Glass and Small Lasers.
