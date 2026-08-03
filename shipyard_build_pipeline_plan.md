# Shipyard → Build → Fleet Pipeline — Implementation Plan

_Author: build-out plan, 2026-06-30. Covers: Build button + fabricator queue, Fleet menu, Blueprint page (module + ship blueprints), Parts inventory + refit-returns-to-inventory._

## 1. Target end-to-end loop

```
ShipBuilder (assemble structural parts) ──save──► Ship Blueprint
        │
        ▼
Shipyard: pick blueprint ─► fit modules ─► power settings ─► [BUILD]
        │                                                       │
        │                         build queue (N fabricators)   │
        ▼                                                       ▼
  parts pulled from Parts Inventory             completed ShipInstance
        │                                                       │
        └──────────────── refit returns parts ◄────────────────┤
                                                                ▼
                                                          FLEET MENU ─► deploy to Combat

Blueprint Page: Discovered MODULE blueprints (fabricatable) + Created SHIP blueprints (sellable)
```

## 2. What already exists (extend, don't reinvent)

- **`PlayerProfile`** (`Assets/Scripts/Networking/PlayerProfile.cs`, persisted to PlayFab UserData["Profile"]) already holds:
  - `List<ShipInstance> ownedShips` — every ship the player owns. **Built ships go here.**
  - `List<Fleet> fleets` — named fleets; `Fleet.shipInstanceIDs` references owned ships. `assignedFleetID == null` = dry-dock.
  - `List<PartInstance> moduleInventory` — loose (unequipped) parts. **This is the parts inventory.**
  - `Dictionary<string,int> stackableInventory` — ores/commodities. Currency fields (`federationCredits`, etc.).
- **`ShipInstance`** { `instanceID`(GUID), `displayName`, `hullID`, `Dictionary<string,PartInstance> equippedParts`(slot→part), `assignedFleetID` } — already models a built, fitted ship.
- **`PartInstance`** { `itemID`, `grade`(0-20), `checksum` } — already models an owned part; integrity-checksummed.
- **`PlayFabManager`** save/load: `SavePlayerProfile()` / `LoadPlayerProfile()`; `EnsureFleetSeeded()`, `ResolveCurrentEditTarget()`.
- **`FleetRosterHUD`** / **`MacroFleet`** — existing fleet visualization to extend or mirror in UITK.
- **`ShipBlueprintStore`** (used by the UITK shipyard) — saves player ship designs to disk (`…/blueprints/*.json`). Currently stores **structural parts only** (hull/engines/wings), NOT fitted modules.
- **Schemas**: all modules inherit `ItemSchema` (has `requiredTechnologies`, `requiredMaterials`, `weight` per-grade → build-time formula `build_seconds = WeightForGrade(grade) * construction_factor`). `ArmorSchema`, `PowerCoreSchema` exist under `Resources/Schemas/`.

## 3. What needs building (gaps)

- No **Build button / fabricator queue**.
- No **link from the UITK shipyard fitting → a persisted ShipInstance** (the new shipyard's fitting/power are display-only; they don't write `equippedParts`).
- Blueprint JSON doesn't store **fitted modules** (only structure).
- No **Blueprint Page** UI (module blueprints discovered / ship blueprints created+sellable).
- No **discovered-blueprint tracking** on the profile.
- No **Parts Inventory UI**, and no refit-returns-part-to-inventory wiring in the new shipyard.
- `fabricatorCount` not on the profile.
- Economy/market for selling = stub only (defer).

## 4. Data-model additions (PlayerProfile + small new types)

```csharp
// PlayerProfile additions
int fabricators = 1;                         // parallel build lanes
List<string> discoveredModuleBlueprints;     // itemIDs of module blueprints unlocked
List<SavedShipBlueprint> shipBlueprints;     // player-created designs (sellable); mirrors disk store
List<BuildOrder> buildQueue;                 // active fabrications (time ignored for now)

class SavedShipBlueprint { string blueprintId, name; string hullId;
    List<StructPart> structure;              // from ShipBuilder (partID,pos,rot)
    Dictionary<string,string> defaultFitting;// slot → module itemID (optional default loadout)
    bool forSale; int askingPrice; }

class BuildOrder { string orderId; string blueprintId; string shipName;
    List<string> partItemIds;                // parts to fabricate
    int lane;                                // which fabricator
    float secondsRemaining;                  // 0 now (time ignored) }
```

Fitting persistence: extend the blueprint/loadout save so the **fitted modules + power allocation + internal/shield choices** are captured (write `ShipInstance.equippedParts` on build).

## 5. Menus to build

1. **Build panel** (shipyard, after Power Settings): `BUILD SHIP` button → build summary (part list, fabricator lane allocation, est. time *shown but ignored*) → confirm → creates `ShipInstance`, consumes parts from `moduleInventory`, appends to `ownedShips`, assigns to a fleet (or dry-dock). Toast "Ship built → Fleet".
2. **Fleet menu** (new UITK page): lists `ownedShips` grouped by fleet / dry-dock; per-ship card (hull thumbnail, name, fitted summary); actions: Rename, Assign-to-fleet, **Deploy to Combat**, Refit (→ shipyard with this ship as edit target).
3. **Blueprint page** (new UITK page, two tabs):
   - **Module Blueprints** — discovered module schemas the player can fabricate (gated by `discoveredModuleBlueprints` / tech). Card per module (name, class, size, grade range).
   - **Ship Blueprints** — player-created ship designs (`shipBlueprints`); toggle **For Sale** + asking price (economy hook deferred).
4. **Parts Inventory** (new UITK page or panel): two lists — **In Storage** (`moduleInventory`) and **On Ships** (parts inside `ownedShips[*].equippedParts`, with which ship). Refit moves a part Ship→Storage.

## 6. Build/queue rules (time ignored for now)

- Player has `fabricators = N`. A build splits its parts across up to N lanes (parallel) → "each part in a separate fabricator."
- Queue model implemented now; **`secondsRemaining` forced to 0** so builds complete instantly. The lane-allocation + time-estimate display is built so turning time on later is a one-line change (set `secondsRemaining = Σ build_seconds / lane`).
- Parts consumed from `moduleInventory` on build; if a required part isn't owned, it's fabricated (instant now) — flag for later material/time cost.

## 7. Phasing (suggested build order)

- **Phase 1 — Build → Fleet (core loop).** BUILD button after power; capture fitting → `ShipInstance`; add to `ownedShips`/fleet; minimal **Fleet menu** listing built ships + Deploy-to-Combat. _(Highest value: closes the build→play loop.)_
- **Phase 2 — Fabricator queue.** `fabricators` on profile; build-queue model + lane allocation + time-estimate UI (time ignored). Build panel shows the queue.
- **Phase 3 — Parts Inventory + refit.** Inventory page (storage vs on-ship); fitting pulls from inventory; refit returns `PartInstance` to `moduleInventory`.
- **Phase 4 — Blueprint page.** Module-blueprint discovery tracking + Ship-blueprint list. ~~For-Sale toggle~~ **SUPERSEDED 2026-07-14 (Aaron): blueprints are never sold — parts ARE the blueprint market.** Players trade physical parts; a bought part can be destroyed in the crucible to learn its blueprint (same RE rule as salvage). See `ships/ships_manufacturing.md` §5 "Parts ARE the blueprint market" + "Dormant blueprints".
- **Phase 5 (later) — Economy + real build time/materials.** Market to sell PARTS (PlayFab catalog) — ~~blueprints~~ per the 2026-07-14 supersession above — `requiredMaterials` consumption, real timers.

## 8. Open questions / decisions

- Fleet capacity: cap owned ships / fleet size by `commandLevel` (exists) or unlimited for now? → **unlimited for now.**
- New scenes vs. additive UITK panels? → **UITK panels inside the existing shipyard/menu flow** (no new scenes) to match the current rebuild.
- Do built ships consume the blueprint, or is a blueprint reusable to build many? → **reusable** (blueprint is a template; building spends parts, not the design).
