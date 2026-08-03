# MMO Network Architecture & Global Game Flow
This document codifies the macro-level systems architecture, explicitly outlining the handshake between the Backend Economy (PlayFab), the Visual Client (Unity), and the Combat Simulation (ECS / Photon).

---

## 1. The Global Game Flow (The 4-Phase Loop)

### Phase 1: The Alchemy Matrix (Macro Economy)
- **Environment:** Safe Menu / Web Dashboard.
- **System:** PlayFab Cloud.
- **Action:** Players manage their 12,345-grid "Alchemy Matrix", research technologies, and queue industrial crafting times.
- **Network State:** Pure HTTP/JSON REST calls. No real-time physics running.

### Phase 2: The Shipyard (Loadout Assembly)
- **Environment:** 3D Hangar Bay (Safe).
- **System:** Unity Client + PlayFab Profile.
- **Action:** The client pulls `.asset` Schemas (Armor, Sensors, Cannons) locally, and requests the player's specific `PartInstance` Inventory from PlayFab. It interpolates the Min/Max Quality ratios to display exact Stats and Rarity Grades (e.g. `[Grade SS]`).
- **Network State:** Player "Commits" loadout, which pushes a final JSON Fleet Snapshot to PlayFab.

### Phase 3a: The Sector Map (Macro Navigation)
- **Environment:** Sector view — choose a body, plot a chain-mining route, browse anomalies.
- **System:** **PlayFab (lazy timestamp evaluation).** No Photon Fusion runner. No per-frame ticks.
- **Action:** The client reads sector body definitions from ScriptableObjects and queries PlayFab for player-specific state (current location, travel ETA, inventory). Travel commits go through CloudScript validation.
- **Network State:** Pure HTTP/JSON REST. The sector map *never* spawns a Fusion room.

### Phase 3b: The Event Instance (Deployment & Fog of War)
- **Environment:** Real-time Tactical Instance — entered when a **combat encounter** triggers or a **mining op** begins. (Nothing else enters this phase.)
- **System:** Photon Fusion (authoritative tick simulation).
- **Action:** Unity abandons all physics. Fusion spins up the instance using the immutable PlayFab Fleet Snapshot. Tear-down on event exit returns canonical state to PlayFab.
- **Network State:** 
  - Server dictates strict `SensorsRadius` and `JammerStrength`.
  - Client only renders what the server explicitly says it can see through the Fog of War.
  - Rollback Netcode guarantees authoritative collision between railguns and reactive armor.

### Phase 4: Extraction & Salvage (The Tow State)
- **Environment:** Real-time Tactical -> Menu Transition (High Risk).
- **System:** ECS Server -> PlayFab Cloud.
- **Action:** If a player secures Golden Logic or Raw Ore, they must survive extraction.
- **Network State:** The ECS Server compiles the final Match Results payload (Damage taken, Ore mined) and securely pushes the diff-patch directly to PlayFab. The Unity Client is re-routed back to Phase 1.

---

## 2. ECS (Entity Component System) Integration Rules
The combat relies strictly on separation of Data and View. Unity `GameObjects` are entirely cosmetic.

### The Immutable Snapshot Handshake
When a ship enters the Sector, exactly *how* does it spawn?
1. The **Matchmaker** pulls the `DraftShipID` and `equippedWeapons` Dictionary from the player's PlayFab Profile.
2. The Server intercepts the raw C# `PartInstance` (e.g., `"wpn_scrapper_autocannon_01", Quality: 7500`).
3. The Server natively interpolates that 7500 Quality against the `WeaponSchema` bounding boxes to calculate raw integers for `FinalDamage`, `FinalTrackingSpeed`, and `FinalMass`.
4. The **Photon ECS Frame 0** injects pure struct variables (int, float) directly into the simulation. No nested custom classes.

### Why Deterministic ECS is Mandatory
Because ships are restricted to forward-vector thruster speeds (`ForwardThrust`), and weapons utilize strict gimbal target-tracking logic with projectile intercepts, standard Unity Rigidbodies would immediately desync over the internet.
By utilizing ECS:
- A `[Grade S] Heavy Thruster` on Player A will always generate the exact same lateral strafe coordinates on Player B's screen.
- E-War Jammers reliably calculate range overlaps without Unity Collider latency.

---

## 3. Security Paradigms (Anti-Cheat)
- **Never Trust The Client:** Unity is only a viewer. If a hacker attempts to change their Sensor Radius via Cheat Engine, the ECS server simply will not send them enemy coordinate packets.
- **Blueprint Seam-Welding:** By forcing "TechnologySchema" unlocks to exist on PlayFab, a player cannot magically tell the ECS Server they are flying a ship they never earned. If the snapshot requests unearned modules, the network instantly rejects the extraction.
