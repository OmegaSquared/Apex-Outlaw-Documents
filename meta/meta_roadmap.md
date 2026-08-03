# MMO Development Roadmap & Action Plan

This document breaks the immense scope of the MMO into highly focused, executable Sprints. We will completely finish one phase before attempting the next to prevent feature creep.

---

## Phase 1: The Core Database (The Foundation)
*Goal: Get the "Macro-Game" backend fully defined and communicating with Unity.*
- [ ] **1.1 C# Data Structs Setup:** Define `ItemSchema`, `ShipSchema`, and `PlayerProfile` classes in Unity.
- [ ] **1.2 PlayFab Integration:** Connect Unity to PlayFab Login/Authentication.
- [ ] **1.3 Inventory Retrieval:** Successfully pull a dummy JSON string from PlayFab, deserialize it, and print the player's ship stats to the Unity Console.
- [ ] **1.4 Server Math Test:** Write a basic `Formula(BaseStat * ResearchValue)` script that proves the Double-Schema logic works securely.

---

## Phase 2: The Command Center (Shift UI Integration)
*Goal: Build the non-combat, management experience using the Michsky Shift asset.*
- [ ] **2.1 Main Menu Flow:** Set up `MainPanelManager.cs` to smoothly transition between the Dashboard, Shipyard, and Lab tabs.
- [ ] **2.2 The Shipyard Visuals:** Bind the PlayFab JSON data (from Phase 1) to the UI. If the player owns a Frigate, the UI displays "Frigate" and lists the 4 hardpoint slots.
- [ ] **2.3 Drag and Drop Logic:** Create the C# logic allowing players to drag a module from their Inventory into a Ship Hardpoint and update the JSON.

---

## Phase 3: Resource Discovery — Scanning & Extraction (Vertical Slice)
*Goal: Stand up the canonical resource-discovery loop end-to-end. Player clicks a large named asteroid on the sector map, lands in a macro asteroid-instance scene, sweeps for resource anomalies, frequency-locks a vein, deploys a Telemetry Beacon, and extracts graded raw ore into cargo.*

Canon: [`../economy/economy_scanning_extraction.md`](../economy/economy_scanning_extraction.md). Replaces the legacy heatmap-grid plan; the 10,000×10,000 matrix model is superseded by a server-authoritative fat-tail RNG with zero coordinate persistence. See [`master_to_do.md`](master_to_do.md) Phase 3 for the full landed checklist + deferred work.
- [x] **3.1 Schemas + PlayFab fields:** `GradedStack`, `MaxDiscoveredGoods`, `ResourceAnomalySchema`, `TelemetryBeaconSchema`, `MiningLaserSchema`; `PlayerProfile` + `ContainerInstance` graded paths.
- [x] **3.2 Server-side fat-tail RNG:** `cloudscript/scanning.js` — `ScanResourceAnomaly`, `FrequencyLockAnomaly`. Mode at C, Paretian right tail, Slag-collapse on frequency mismatch.
- [x] **3.3 Asteroid-instance scene:** `AsteroidInstance.unity` runtime scene, sector-map place-marker click-to-enter, presence record, `IAsteroidInstanceHost` (macro-by-default; Fusion-upgrade stubbed for combat-on-hack).
- [x] **3.4 Scanner UX + Telemetry Beacon + extraction:** in-scene scanner sweep, anomaly blip, frequency-lock wind-up, beacon deploy (`cloudscript/beacons.js`), graded extraction tick (`cloudscript/mining.js`), sector-map best-find badges.

> **Deferred to Phase 5 (Economy):** purity cascade in `RunRecipe`, server-wide apex Maker's Mark, full canon rewrite of `economy_alchemy_research.md` §§1–3. **Deferred to Phase 4.2e:** beacon-hack → Fusion combat handoff. See `master_to_do.md` Phase 3.C for the forward pointer.

---

## Phase 4: The Photon Arena (The Micro-Game)
*Goal: Move from UI into real-time 3D flight.*
- [ ] **4.1 Photon Setup:** Integrate Fusion/Quantum. Initialize a basic "Empty Space" sector.
- [ ] **4.2 ECS Translation:** Pass the Ship's equipped JSON loadout to Photon, spawning an ECS Entity with the correct Mass, Turn Speed, and Weapon Hardpoints.
- [ ] **4.3 Flight Dynamics:** Implement `F = MA` physics. Ensure Freighters feel heavy and Fighters dodge quickly.
- [ ] **4.4 Basic Combat:** Implement Dumb-fire weapons and basic Shield/Hull health reductions.

---

## Phase 5: Economy & Scaling (The World)
*Goal: Connect the solo players into a massive, interdependent economy.*
- [ ] **5.1 The Hub Pricing Model:** Implement the `CurrentStock / TargetStock` scarcity scalar in PlayFab CloudScripts.
- [ ] **5.2 The 3% & 35% Taxes:** Ensure every trade accurately deducts the taxes.
- [ ] **5.3 Alliance Registration:** Allow players to form guilds and set Diplomatic Price Premiums (+15%, +100%) against each other.
- [ ] **5.4 The Golden Towing Sequence:** Implement the severe physics drag when capturing a wreck, intact-module recovery into inventory, and the per-module Repair Recipe roll (1% Sector Hub / 2% Citadel). Manufacturing is *not* unlocked by theft — that path stays with the originating Researcher's Seed. See [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md) §4.
