---
status: proposed
phase: 6.9
last-reviewed: 2026-06-09
---

# Fleet Management — Roster, Storage & the Deploy Menu

> **Status: proposed plan (notes captured 2026-06-09).** How the player organizes ships into fleets, where ships are stored (built hangar vs. leased orbital dock), which ships are active vs. parked during a base fight, and the shared bottom-of-screen card menu that hosts both the roster and the **[Base Deployment Beacon](../ground_base/ground_base_deployment_beacon.md)**. The card UI mirrors the existing Vesperion fleet cards ([`FleetRosterHUD`](../../Assets/Scripts/UI/FleetRosterHUD.cs) + [`FleetSlotCard`](../../Assets/Scripts/UI/FleetSlotCard.cs)).

## 1. One global roster, two storage states

The roster is **player-wide** (all your ships, wherever they are). Within it, each ship is in one of two states relative to a base:

| State | Where | Defends base? | Takes damage in a base fight? | Cost |
|---|---|---|---|---|
| **Platform (active)** | Stationed/deployed at the base | **Yes** — these are the defenders | **Yes** — exposed | — |
| **Hangar (parked)** | A parking spot in the base hangar, behind reinforced blast doors | **No** | **No** — exempt (sealed behind blast doors) | Cheap — you build the hangar |

The hangar has a **limited number of parking spots** (allotted space) — you build more capacity to park more ships.

## 2. Storage economics — build vs. lease

- **Build your own hangar** (in your surface base): cheapest per-ship parking. Limited slots; expand by building. Parked ships are **safe but inert** during a base fight.
- **Lease a dock** (the orbital **Dock** — "city in space," an existing registry orbital structure, [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md)): pay a **lease fee per parking space**. More expensive than building your own — the trade-off is location/availability.
- **Capital ships** park at the **Dock** by rule: capitals carry `canEnterAtmosphere = false` and can never enter the Surface scene ([`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md)). The hangar (surface) holds only atmosphere-eligible hulls.

The lease fee is an economy sink (recipient TBD — dock owner / faction). It deliberately incentivizes building your own base hangar over renting.

## 3. The deploy menu (mirrors the Vesperion fleet cards)

A bottom-of-screen card menu, same screen location as the surface **build** menu ([`BaseBuildPanel`](../../Assets/Scripts/UI/BaseBuildPanel.cs)) but listing **ships** instead of build parts. Built on the existing fleet-card pattern:

- **Cards = ships / fleets.** Ships combine into fleets here (the drag-to-split-a-fleet behavior already exists — see [`MacroFleet`](../../Assets/Scripts/Macro/MacroFleet.cs) `FleetShip.customName`).
- **The equipped [Base Deployment Beacon](../ground_base/ground_base_deployment_beacon.md) is a card on this menu.** The player drags it onto a world to deploy it and **start the base process** (deploy → establish anchor + claim → freighter delivers a starter kit → build tools unlock).
- Hangar (parked) and Platform (active) ships are distinguished on the menu so the player can move ships between states.

## 4. What exists vs. to-build

- **Reuse:** [`FleetRosterHUD`](../../Assets/Scripts/UI/FleetRosterHUD.cs) (bottom card hotbar), [`FleetSlotCard`](../../Assets/Scripts/UI/FleetSlotCard.cs) / [`FleetSlotShipChip`](../../Assets/Scripts/UI/FleetSlotShipChip.cs) (ship chips), [`MacroFleet`](../../Assets/Scripts/Macro/MacroFleet.cs) (roster model, capital/hull classes), the `Dock` orbital structure (capital parking).
- **Build:** the Hangar/Platform state on the roster; the parking-slot + blast-door model + the damage-exemption rule during a base fight; the lease-fee economy on dock parking; the beacon card + drag-to-deploy on the menu.
- **Bridge:** roster/parking persistence is local until PlayFab player-data + base persistence land (same removal moment as the surface-base persistence bridges).

## 5. Open questions

- Exact slot counts (hangar capacity per base tier; dock lease price curve).
- Lease-fee recipient (faction / dock owner) and whether it's a pure sink.
- Where the menu is shown per scene (surface base view, low-orbit, solar/sector while flying) — the beacon needs it available where you can target a world.
- Visual: blast-door open/close on launch/park; whether parked ships render in the hangar.

## 6. See also

- [`../ground_base/ground_base_deployment_beacon.md`](../ground_base/ground_base_deployment_beacon.md) — the beacon that shares this menu and starts a base.
- [`../social/social_menus_ui.md`](../social/social_menus_ui.md) §C/§5 — fleet/party management + Shipyard loadout (the configure side).
- [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md) — the orbital Dock + capital-parking rule.
- [`ships_class_index.md`](ships_class_index.md) — hull classes (capitals = Class D).
