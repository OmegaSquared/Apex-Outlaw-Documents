# Comprehensive MMO Menu & UI Hierarchy

This document details the complete, hierarchical layout for every user interface and menu screen required in the game. It is designed to act as a definitive blueprint for the **Michsky Shift - Complete Sci-Fi UI** integration, utilizing `MainPanelManager` for major section swaps, `ModalWindowManager` for critical decisions, and Slide/Fade animators for nested tabs.

---

## 1. Pre-Game & Authentication
*The flow before entering the persistent universe.*

- **Login Screen:** PlayFab/Authentication credentials.
- **Server / Realm Selection:** Choosing the cluster.
- **Commander Select / Creation:** Picking a character or starting a new career path.
- **Settings (Cog Icon):** Access to Audio, Graphics, and basic Keybinds before joining.

---

## 2. The Persistent Global HUD
*Elements that remain visible (or easily accessible via overlay) while navigating the macro-game.*

- **Top Status Bar:**
  - **Commander Name & Portrait**: Clickable to open Profile.
  - **Balances:** Credits, Premium Currency, and active "Wanted Level" or Federation Standing.
  - **Notification Center (Bell):** High-priority alerts (e.g., "Refining complete", "Market item sold", "Hostile action against Citadel").
- **Bottom / Sidebar Navigation (MainPanelManager Hub):**
  - Buttons switching between: `Command Deck`, `Shipyard`, `Inventory`, `Alchemy Lab`, `Market`, `Alliance`, and `Social`.

---

## 3. Social & Communications `[NEW]`
*The lifelines of the MMO experience. Managed via fly-out panels or dedicated tabs.*

### A. The Chat Terminal (Dockable / Resizable window)
- **Global:** Entire server (often chaotic, strictly moderated).
- **Sector/Local:** Broadcast to current physical location.
- **Alliance:** Encrypted comms for guild members.
- **Whisper/PM:** Direct 1-to-1 tabs with players.
- **System/Combat Log:** Raw text data on damage taken, items looted, and system alerts.

### B. Friends & Contacts Panel
- **Friends List:** Online/Offline status, location tracking (if permitted).
- **Recent Contacts/Rivals:** Players you recently traded with or fought.
- **Ignore / Block List.**
- **Context Menu Options (Right-Click on Name):**
  - *Invite to Fleet (Party up)*
  - *Direct Message*
  - *Offer Private Contract/Trade*
  - *View Public Profile*

### C. Fleet / Party Management
- **Active Roster:** HP/Shield bars of up to 4-5 fleet members currently flying with you.
- **Fleet Commander Tools:** Pinging locations on the map, initiating fleet-warps.

---

## 4. Player Profile & Progression `[NEW]`
*The commander’s personal record.*

- **Service Record (Overview Tab):** Playtime, total ships destroyed, total asteroids cracked.
- **Reputation & Standing Tab:** 
  - Visual sliders showing affinity with the Federation, Mars, and Pirate factions.
  - Dictates access to certain Hub Cities and tax rates.
- **Titles & Achievements:** Unlocked badges to display next to your name in chat.

---

## 5. The Shipyard & Fleet Management
*Where players configure their loadouts, swap modules, and analyze ship statistics.*

- **Hull Roster (Carousel Tab):** 3D renderer of the player's available ships. Includes actions: *Deploy Ship*, *Storage*, *Sell Hull*.
- **The Fitting Room (Loadout Tab):**
  - **Hardpoint Grid:** Graphical representation of the ship (Weapons, Jammers, Shields, Reactors).
  - **Module Selection Drawer:** Left-pane listing available items in the Inventory. 
  - **Analytics Board:** Dynamically updating stat block (Power Draw vs. Reactor Output, DPS, Mass, Top Speed, Shield Regen).
- **Cargo & Inventory (Hold Tab):**
  - **Raw Resources:** Unrefined ores and gases.
  - **Refined Assets:** Steel, Helium-3, Void-Steel.
  - **Blueprints & Modules:** Stored equipment.

---

## 6. The Alchemy Lab (Research & Progress)
*The core resource min-maxing loop.*

- **Matrix Scanner Grid (Tab 1):** A massive interactable heatmap. Players click coordinates to probe for the `12,345` peak values using their unique seed.
- **Best Found Ledger (Tab 2):** A strictly organized list tracking the highest peak values the player has discovered (e.g., `Iron [Value: 11,200]`).
- **Synthesis Crucible (Tab 3):** A drag-and-drop crafting interface where two "Parent" elements unlock "Child" blueprints (e.g., Iron + Carbon = Steel). 

---

## 7. Economy & Markets (Sector City Hub)
*Accessed when docked at Federation, Mars, or Pirate outposts.*

- **Universal Trade Terminal:**
  - **Buy / Sell Orders:** List of player and NPC listings.
  - **Price Ticker Graph:** Visual representation of local Scarcity (CurrentStock / TargetStock).
- **Private Contracts Board:**
  - **Job Board:** Players posting escrow-backed tasks (Courier, Escort, Hitman).
  - **Contract Creation UI:** Set reward, collateral, and target.
- **Industrial Refineries:**
  - Queue-based UI showing raw ore being processed into base elements over time. Prominently displays the 35% Federation Tax deduction.

---

## 8. Alliance & Diplomacy (Guild Menus) `[NEW]`
*Guild-level interactions, the endgame macro layer.*

- **Overview & Messages of the Day (MOTD):** Central guild landing page.
- **Member Roster:** Activity tracking, ranks (Leader, Officer, Recruit), kick/promote buttons.
- **Diplomatic Ledger:** List of other alliances setting standings (Ally, Neutral, Rival, Hostile) to dictate the Market Price Premium (+0% to +300%).
- **Alliance Bank / Vault:** 
  - View guild tax income, coordinate payouts for defense ops. 
  - **Shared Inventory Log:** Who is depositing/taking refined materials.
- **Golden Logic Library (Repair Recipe Index):** Shared database of **maintenance recipes** the alliance has recovered through scavenging — refurbishment ratios for stolen / looted modules. Lets any member with read access keep stolen masterpieces operational. Does **not** include manufacturing recipes; producing new high-quality modules still requires a Researcher running the Matrix Scanner against their own Seed (see [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md) §4).
- **Citadel Construction:** Voting or allocating resources to upgrade base defenses, lab tiers, and refineries.

---

## 9. Sector Operations (Navigation & Map)
*How players move through the universe.*

- **System / Galaxy Map:** Zoomable interface showing controlled territory, Hubs, and contested zones.
- **Nav-Computer (Flight Planner):** Calculates PlayFab ETA, fuel cost, and displays the "Jump / Warp" execution button.

---

## 10. Combat, Scavenging & Autopsy
*The interfaces for active conflict and looting.*

### A. The Scavenger (Modal & Panel Hybrid)
- **Towing Status (Persistent Alert HUD):** Blinking warning indicating a tether is active and a "Pirate Beacon" is broadcasting the player's location.
- **Autopsy Deck:** Displays the retrieved wreck.
- **Extraction Modals (Using `ModalWindowManager`):**
  - **Field Strip:** *Takes 15m. Safe. Scrap only — no intact modules, no Repair Recipe roll. Accept?*
  - **Deep Forensics:** *Takes 1h. High Risk. Recovers intact stolen modules + 2% chance per module to learn its Repair Recipe (Golden Logic). Accept?*

### B. The Tactical Arena (Photon Combat HUD)
- **World Space Elements:** Firing cones, smart-tracking brackets, max-range indicators.
- **Player Vitals (Bottom Center):** Shift UI Health/Shield bars and Capacitor energy levels.
- **Heat Gauge:** Fills as weapons fire, visually warns on overheat.
- **E-War Degradation Overlays:** Severe visual static, disabled minimap, and error warnings if hit by an enemy Jammer.

---

## 11. System Menus (The Escape Menu)
*Standard client controls.*

- **Resume Game**
- **Settings:**
  - **Graphics:** Resolution, URP Quality Settings, Ambient Occlusion.
  - **Audio:** Master, Music, Effects, Voice / Vivox Chat volume.
  - **Controls:** Keybinds for targeting, UI toggles, and flight axes.
  - **Gameplay:** Colorblind modes, chat filters, UI scaling.
- **Support / Report Player:** Ticket submission system.
- **Logout:** Return to Commander Select or Exit to Desktop.
