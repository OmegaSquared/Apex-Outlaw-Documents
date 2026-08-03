# MMO Backend & Network Architecture TDD

## 1. Overview: The Hybrid "Macro-Micro" Model
This MMO avoids the immense costs of a traditional 24/7 server loop by cleanly dividing gameplay into two networking models:
1. **The Macro Game:** REST-based, Serverless logic via **PlayFab**. Handles all economy, inventory, alchemy, travel math, **and the sector / planet maps** (lazy timestamp evaluation — no Fusion runner).
2. **The Micro Game:** Highly authoritative, high-tickrate **event instances** via **Photon Fusion**. Used **only** for combat encounters and mining ops. **Combat instances are capped at 3v3 active combatants + up to 10 spectators (16 players max).** Mining-op instances have a separate cap (TBD). A sector may host one or more instances. Sector maps and planet maps are **never** Fusion-driven.

---

## 2. PlayFab Backend (The Persistent State)
PlayFab (or equivalent like Nakama) is the ultimate absolute authority on the state of the universe.

- **Storage:** JSON-based Key-Value pairs.
- **The "Lazy Evaluation" System:**
  Instead of ticking player positions every second while they travel across the sector, the server simply records a timestamp. 
  - `DepartureTime_UNIX` = `1710500000`
  - `ArrivalTime_UNIX` = `1710503600` (1 hour later).
  When a player queries their status or tries to execute an action at the destination, the server checks `CurrentTime_UNIX` against the Arrival Time. If the ship hasn't arrived, the action is rejected. If it has, the state updates.
- **AFK Mining:**
  A mining laser has a `YieldPerMinute` value. A player activates the laser and logs off. The server stores `HarvestStartTime`. When the player logs back in, the server calculates: 
  `Yield = (CurrentTime - HarvestStartTime) * YieldPerMinute`, capped by the ship's maximum cargo hold.

---

## 3. Photon Fusion (The Real-Time Event Instances)
> **Scope:** Fusion is invoked **only** for event instances — combat encounters and mining ops. Sector maps and planet maps remain PlayFab macro state throughout; they never spawn a Fusion runner.

When players trigger a combat encounter or mining op, the PlayFab static data is serialized and handed to a Photon Room.

- **Entity Component System (ECS):** The Simulation relies purely on C# structs executing in a deterministic tick rate. No Unity GameObjects perform logic. 
- **The "Bridge":** 
  - Photon receives the `Instance JSON` (what modules the player has equipped).
  - It generates purely data-driven Entities with components like `[Transform]`, `[Health]`, `[Velocity]`, `[WeaponSystem]`.
  - The client Unity Engine strictly acts as a renderer, placing 3D models and particle effects wherever the ECS coordinates dictate.
- **Rollback Netcode:** Because the logic is deterministic, the clients predict physics instantly, hiding lag while the authoritative Host (or Server) double-checks for hits.

---

## 4. Anti-Hack Measures & Server Validation
- **Checksum Signatures:** Every piece of high-tier gear a player owns is "signed" by PlayFab with a hidden hash. If a client injects a JSON editor and changes a Railgun's damage from `100` to `999,999`, the checksum fails upon entering a Photon Room, and the item is deleted or the player is flagged.
- **Movement Validation:** Even during "Lazy Evaluation," the server runs a check. If a player claims they traveled 100,000 km in 3 seconds, but their engine's `MaxSpeed` dictates it should take 60 minutes, the request is immediately rejected (Rubberbanding).

---

## 5. The Launch Sequence (Vega Conflict Model)
To prevent "Ghost Loadouts" and synchronization exploits between the PlayFab economy and the Photon arena, the game uses a strict **"Modify ➔ Launch ➔ Fight"** cycle.

- **State Locking:** When a player finalizes their fleet mapping at their Base and hits "Launch," the PlayFab server flags the ships as `bIsFleetActive = true`. Once locked, API calls attempting to `EquipModule` or `ModifyShip` are explicitly rejected.
- **The Combat Snapshot:** Upon launch, the backend merges the Static Blueprint schemas and the player's unique Instance schemas (their 12,345 research values) into an immutable JSON payload (the *FleetSnapshot*). 
- **The Handoff:** This snapshot is what Photon loads to create the ECS simulation, giving the server plenty of time to buffer the data while the player navigates the Sector Map.
- **Post-Combat Reconciliation:** When the Photon room closes, a reconciliation packet is sent back to PlayFab recording Hull Integrity and Golden Logic loot, then setting `bIsFleetActive = false` so the player can re-fit.

---

## 6. Celestial Registry & POI Authority (Phase 6.0)
PlayFab title data is the single source of truth for body and POI placement. Per `Design_Documents/meta/master_to_do.md` Phase 6.0 + the canonical plan at `~/.claude/plans/in-the-solar-system-moonlit-simon.md`.

### 6.1 Title-data keys
- **`CelestialEpoch`** — single ISO-8601 UTC string. Frozen at game launch; every body's position is computed as a function of `(UtcNow - CelestialEpoch)`. Read by `CelestialEpochFetcher` on login. Local fallback `2026-01-01T00:00:00Z` flagged as BRIDGE for removal once production sets the key.
- **`CelestialRegistry`** — full JSON dataset (parents + children + meta). Schema lives in `Assets/Scripts/Schemas/Celestial/CelestialRegistry.cs`. Read by `CelestialRegistryClient` on login + on demand via `RequestRefresh()`. Local fallback `Resources/CelestialSeed.json` flagged as BRIDGE.
- **`PlanetControl_<id>`** — per-planet ownership state (alliance, grandfathered residents, granted residents, non-member tax). Schema in `Assets/Scripts/Schemas/PlanetControlState.cs`. Mutated only by Phase 5.5 control-evaluator CloudScript.

### 6.2 CloudScript handlers (alliance-built POIs — Phase 6.0.G)
Canonical sources live in the repo at `cloudscript/`. Manually deployed to PlayFab GameManager (Settings → Cloud Script → Revisions). See `cloudscript/README.md` for the deployment workflow.

- **`AllianceConstructPOI(args)`** — appends a new `CelestialChildRecord` with `source = AllianceBuilt` and `ownerAllianceId` = caller's alliance. Validates: alliance officer rank, alliance owns the host planet (via `PlanetControl_<id>`), POI type is in the alliance-buildable allow-list. Returns `{ ok, childId, reason }`.
- **`AllianceDemolishPOI(args)`** — removes a child the caller's alliance owns. Validates: officer rank, alliance owns the POI, POI is `AllianceBuilt` (static POIs can't be demolished). Returns `{ ok, reason }`.

Client-side wrapper: `Assets/Scripts/Macro/Celestial/CelestialPOIConstruction.cs` — calls `PlayFabClientAPI.ExecuteCloudScript`, parses the envelope, and on success calls `CelestialRegistryClient.RequestRefresh()` so the spawner instantiates the new POI within the next fetch cycle.

### 6.3 Authority invariants
- The client never writes `CelestialRegistry`, `CelestialEpoch`, or any `PlanetControl_<id>` key. CloudScript (or PlayFab admin tooling) is the only writer.
- All title-data writes use `server.SetTitleInternalData` so the registry can't be overwritten by leaked admin-API keys — only signed CloudScript revisions can mutate.
- Schema-version compatibility is additive only within a major version; breaking changes bump `CelestialRegistry.schemaVersion` and old clients tolerate unknown fields (Newtonsoft default).
