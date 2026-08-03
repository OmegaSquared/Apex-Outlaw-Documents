# MMO Player Dossier & Infamy Rating System

## 1. Overview
In a universe driven by piracy, resource scarcity, and deep-space alliances, reputation is everything. This document outlines the **Player Dossier**—a public-facing stat sheet that other commanders can view when deciding to recruit, betray, or hunt a player. 

This system relies on **PlayFab Statistics** (for global leaderboards) and **PlayFab Read-Only Data** (for complex dictionary tracking) to create a terrifyingly accurate profile of a player's behavior.

---

## 2. The Combat Record (The Nemesis System)
Players are tracked intensely on their combat viability, but rather than just a flat "Kill/Death" ratio, the system tracks vendettas.

- **Global PvP W/L Ratio:** Total ships destroyed vs. total times the player's ship was destroyed.
- **The Nemesis Ledger:** PlayFab specifically tracks combat metrics against *individual players*. 
  - *Example:* Instead of seeing "100 Kills", an Alliance recruiter can look at Player A's dossier and see: `Target: Cmdr_Draken -> Won: 12 / Lost: 2`. This proves the player consistently dominates rival factions.
- **The Infamy Score:** A master leaderboard integer. 
  - Gaining Infamy: Attacking unprovoked players, stealing cargo, and disabling trade ships.
  - Losing Infamy (Becoming Lawful): Hunting high-Infamy pirates, successfully escorting shipping lanes, and paying Federation fines.

---

## 3. The Economic Archetype
Alliances need to know if they are recruiting a Miner or a Pirate. 

- **Total Resources Mined:** Flat metric of raw ores (Iron, Tungsten, etc.) legally extracted from Asteroids.
- **Total Resources Stolen (Piracy Yield):** Amount of cargo specifically acquired by opening wrecked opponent cargo bays or towing their wreckage.
- **The Pirate Ratio:** `(Stolen Resources) / (Mined Resources + Stolen Resources)`. If a player's ratio is 95%, Alliances immediately know they do not mine; they are a pure predator.

---

## 4. The Logistics & Trade Record
Shipping cargo through the Fog of War is the core economy of the game.

- **Gross Federation Trade:** Total value of items legally sold at NPC Hubs.
- **Successful Shipments:** Volume of cargo safely transported from Point A to Point B without dying.
- **Cargo Lost to Piracy:** Volume of cargo stolen off the player's burning wreckage.
  - *Psychological Impact:* If an Alliance sees a player has "10,000 Cargo Lost / 200 Cargo Shipped successfully", they know that player is an easy, undefended target who cannot protect their own supply lines.

---

## 5. Technology Obfuscation (The Unknown Threat)
Players can research terrifying 12,000+ Quality weapons, but **that information must never be public.** If rivals could see a player's exact Matrix Quality math, they could easily counter-build them.

- **Public Tech Rating (Vague):** The Dossier only shows generalized "Sectors" of progression.
  - *Example:* `Tech Specialization: Magnetic Acceleration (Tier 4) | Shield Harmonics (Tier 2)`.
  - The recruiter knows the player can build Railguns, but they have absolutely no idea if the player builds garbage 1,000-Quality Railguns or god-tier 12,000-Quality Railguns. They only find out when they get shot.
- **Total Tech Nodes Unlocked:** A flat integer (e.g., `Technologies Mastered: 45/120`). Shows their overall dedication to the Alchemy Matrix without spoiling their secrets.

---

## 6. PlayFab Implementation Guidelines
To minimize server cost and API calls, these statistics are updated in batches.

1. **ECS Match End:** When the deterministic combat simulation (Photon) concludes, the Server Authority compiles the "Damage/Kill/Salvage" report.
2. **Server-Side API Call:** The ECS Server securely calls `PlayFabServerAPI.UpdatePlayerStatistics` (for numbers like Infamy and Total Mined) and `PlayFabServerAPI.UpdateUserData` (to save the complex JSON Nemesis dictionary).
3. **Client Read-Only:** Searching for a player in the UI uses `PlayFabClientAPI.GetPlayerProfile`. The client parses these statistics to render the beautiful UI Dossier chart for recruiters to study.
