# Apex Outlaw — Implementation To-Do List

This document translates the master design and roadmap into an actionable, tracked checklist. **Phases are listed in the likely build order to reach a ready game.** Items higher in the list unlock items lower in the list.

> **How to read this list.** Each phase has a *goal* — the user-visible / functionally observable thing that exists when the phase ships. Don't treat tasks as independent — the order matters because later phases assume earlier ones landed. If you find yourself tempted to jump phases, check whether the prereq in the upstream phase is actually done.

---

## 🔥 ACTIVE — Surface Base Tile System: wire the Blender-built parts (2026-05-31)

**Where we are:** the unified socket-snap tile system works (equilateral triangles, foundation↔
foundation + ceiling all-side snapping, any-shape start — all in `PlanetTest_Alythar`). 24 new part
**meshes** were modeled in Blender and exported to `Assets/Prefabs/Bases/Tiles/<Name>/<Name>.fbx`, but
they are **mesh-only — not schema-wired, not play-tested.** Design + per-part list + math:
[`../pipelines/pipeline_surface_tile_authoring.md`](../pipelines/pipeline_surface_tile_authoring.md)
(§9b = the 24-mesh build log, §7 = the data path for wiring a part).

### Wiring steps (in order)
- [ ] **1. FBX import settings** on each new `.fbx` — `useFileScale=false`, `globalScale=1`, no auto
      camera/light import (Blender→Unity 0.01× scale trap). Confirm in-Unity bbox matches the 8 m
      module dims listed in §9b.
- [ ] **2. `PartDef` rows** in [`Assets/Editor/Tile_DataDriven_Setup.cs`](../../Assets/Editor/Tile_DataDriven_Setup.cs)
      for each STRAIGHT-EDGED part — `prefabAddress` → the part's prefab, set shape/role/cell/rise/menu.
      One row each, no new code; `DeriveSockets` makes the sockets. Placeable now: CornerColumn,
      Pillar_Section, Stairs, HalfRamp, Hatch, AngledRoof, TriangleRoof, TriangleWall,
      HalfTriangleWall, Passageway, Door, Ladder, RailingGate, Rooftop, AngledRoofCorner.
- [ ] **3. New socket kinds / mates** where needed: Ladder → wall-face mount socket kind + one
      `CanMate` row; AngledRoof / TriangleRoof → confirm wall-top / foundation-top mates.
- [ ] **4. Socket Matrix diag** (`Apex Outlaw → Diag → Surface Tile Socket Matrix`) — verify each new
      part's ✓/— row; fix socket DATA (not the engine) on anything wrong.
- [ ] **5. Play-test** the straight-edged batch in `PlanetTest_Alythar`; promote 🔵→✅ in §9b.
- [ ] **6. Replace placeholder geometry** (doors are box-cut; AngledRoofCorner is a rough hip) after
      placement is confirmed.

### 🔴 Blocked on subsystems (meshes built, can't place yet)
- [ ] **Curved-mesh placement subsystem** → unblocks RoundedFoundation, RoundedFloor, RoundedWall,
      RoundedInwardFloor (authoring doc §8.1).
- [ ] **Multi-cell occlusion layer** → unblocks LargeGate (16×16=2×2), WideDoor, TallDoor,
      WideStairs, WideRamp (authoring doc §8.2).

### 🧹 Cleanup (deferred from this session)
- [ ] Delete dead per-shape resolvers in `SurfaceTilePlacer.cs` (`ResolveTrianglePlacement`, triangle
      branches of `GetHostEdgeLocal` / `TargetEdgeMidpoint` — unreachable since the unified engine).
- [ ] Remove one-shot diags `Tile_TriPlacement_Diag.cs` + `Tile_TriangleSnap_Diag.cs` (keep
      `Tile_SocketMatrix_Diag.cs` for QA).
- [ ] Banner `pipeline_surface_tile.md` as superseded by `_authoring.md` (geometry/snap sections).
- [ ] Git commit the play-verified surface-tile milestone once confirmed.

---

## Phase 0 — Project Initialization
**Goal:** Empty Unity project that compiles, has the third-party packages, and the folder layout the rest of the work assumes.

- [ ] Initialize a new Unity Project (Universal Render Pipeline).
- [ ] Set up the internal folder structure (`Scripts`, `Scenes`, `Prefabs`, `ScriptableObjects`, `UI`).
- [ ] Import required third-party packages (PlayFab SDK, Photon Fusion, Michsky Shift UI).

---

## Phase 1 — Core Database & Foundation (Macro)
**Goal:** A logged-in player can pull their inventory from PlayFab, deserialize it, and the server can validate stat math.

- [x] **1.1 Global Schemas:** Write the C# structures (`ItemSchema.cs`, `ShipSchema.cs`, `WeaponSchema.cs`, `PlayerProfile.cs`) using the **Double-Schema** approach.
- [x] **1.2 PlayFab Integration:** Configure PlayFab backend, implement player Login/Authentication.
- [x] **1.3 Inventory Retrieval:** Fetch a mock player state from PlayFab, deserialize in Unity, print Ship Stats.
- [ ] **1.4 Server Math Prototype:** Code the basic formula checking (`BaseStat * ResearchValue`) securely.
- [ ] **1.5 PlayFab Starting Inventory Migration:** Move the hard-coded C# starting-inventory array into PlayFab via CloudScripts or server-side Player Registration.

### 1.6 Inventory & Storage (slice 1 of 5)
Location-bound container model. See [`../economy/economy_overview.md`](../economy/economy_overview.md) "Inventory & Storage" + the plan file in `~/.claude/plans/`.

- [x] Add `cargoCapacityKg` (kg) to [`ShipSchema.cs`](../../Assets/Scripts/Schemas/ShipSchema.cs).
- [x] Add `massPerUnitKg` to [`ResourceSchema.cs`](../../Assets/Scripts/Schemas/ResourceSchema.cs).
- [x] Create [`ContainerSchemas.cs`](../../Assets/Scripts/Schemas/ContainerSchemas.cs) (`ContainerInstance`, `ContainerType`, `ContainerMath`).
- [x] Extend `PlayerProfile` with `List<ContainerInstance> containers`; sweep `IntegrityChecksum.StampAll` / `ValidateAll` over container `moduleInstances`.
- [x] Write [`cloudscript/inventory.js`](../../cloudscript/inventory.js) handlers (`InventoryReadOwn`, `InventoryListOwn`, `InventoryInsert`, `InventoryExtract`, `InventoryMove`).
- [x] Splice inventory.js into [`cloudscript/_deploy_bundle.js`](../../cloudscript/_deploy_bundle.js).
- [x] Write [`InventoryClient.cs`](../../Assets/Scripts/Networking/InventoryClient.cs) PlayFab wrapper.
- [x] Write [`InventoryView`](../../Assets/Scripts/UI/Inventory/InventoryView.cs) + [`InventoryRow`](../../Assets/Scripts/UI/Inventory/InventoryRow.cs) + [`RemoteTerminalView`](../../Assets/Scripts/UI/Inventory/RemoteTerminalView.cs).
- [ ] Upload new CloudScript revision to PlayFab GameManager + update [`architecture_cloudscript_deployed.md`](../architecture/architecture_cloudscript_deployed.md).
- [ ] Author `massPerUnitKg` on every existing `ResourceSchema` asset (Iron exists; rest don't yet — pair with the raw-materials authoring pass below).
- [x] Author Tier-1 raw-material `ResourceSchema` assets per the canon list in [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md). Landed with Slice 2 (33 ResourceSchema assets total): Iron, Copper, Titanium, Nickel, Lithium, Tungsten, Uranium, Silicates, Sulfur, Carbon, Helium-3, Hydrogen, Nitrogen, Xenon, Neon, Methane, Water Ice (raw); Gold, Silver, Scrap Metal (rare/byproduct/salvage); Steel, Ferro-Titanium, Carbon-Fiber Glass, Thermal Paste, Super-Conductor, Ion Plasma, Synthetic Polymer, Electrum Wire, Nickel-Iron Plating, Ammonia, Gold Ingot, Aerogel Mesh, Radar-Absorbent Pigment (Tier-2 refined). Tier-3+ outputs added as recipes land in later slices.
- [ ] Author `cargoCapacityKg` on every existing `ShipSchema` asset (currently all default to 0).
- [ ] Author the first base storage module schema (separate ScriptableObject, slot in [`progression_base_building.md`](../ground_base/progression_base_building.md) §E "Storage Vaults / Cryo-Silos"). Defer to Phase 6.8 base-building if not blocking.
- [ ] **UtilityModuleSchema + Mining Laser + Salvage Beam:** new `UtilityModuleSchema : ItemSchema` for industrial/utility hardpoint modules (sibling to `WeaponSchema`). First two instances: Mining Laser (extracts vein-typed raws from asteroids) and Salvage Beam (extracts Scrap Metal from wrecks). Both share the `Weapon` hardpoint `componentClass` but reject combat-only slots. Canon: [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §D "Industrial & Utility Modules". Defer to slice 2 (recipe / production schema) — these are the first non-combat modules that need recipes.
- [ ] **Hacking & Intel modules** (Sensor Probe, Cargo Sniffer, Signal Tap, Notice Board Decryptor, **Supply-Chain Tap**, **Roster Sniffer**, **Transaction Ledger Tap**, **Combat Record Tap**, Tech Tree Spy, **Privilege Ledger Decryptor**, **Member Dossier Decryptor**) — `UtilityModuleSchema` instances per canon at [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §D and the material chain at [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) "Hacking & Intel Chain". Every hacking *read* must go through a server-authoritative CloudScript handler that validates the caller's consumable inventory + proximity / sector requirement before returning data. Per CLAUDE.md "Don't trust the client": the client must never see alliance internal state, another player's private data, OR combat statistics in any code path other than the handler's response payload. Defer to the Alliance system phase (current placeholder: Phase 6.x social) — needs the alliance data model to exist first.
- [ ] **Alliance schema must include rank + privilege model.** The Privilege Ledger Decryptor (T4) reads a rank-based privilege table — which means alliance data needs to actually have one. When the alliance system is authored, the data model must include: (a) ordered rank ladder with tier indices, (b) per-rank equipment-draw permissions from alliance armory, (c) per-rank special-issue gear allocations, (d) per-member rank assignment, (e) per-member contract list, (f) last-seen telemetry harvested from chat / sector activity. Without this structure the hacking modules have nothing to read. Pair with the alliance system itself, not the hacking modules — the data model is the prerequisite.
- [ ] **Per-player historical data persistence.** Member Dossier Decryptor (T4) and Transaction Ledger Tap (T3) require historical per-player state to read from — neither can exist without the data behind it. Required structures: (a) **Transaction ledger** — every market buy/sell, contract completion, credit transfer, alliance armory draw recorded as an append-only event log keyed by `playerId`; (b) **Loadout snapshots** — periodic capture of each player's equipped modules indexed by timestamp / engagement, written automatically before combat encounters and on significant loadout changes. Both structures live in PlayFab player data (or a sibling key) with retention policy: dossier reads always show the full retained history; transaction tap only shows what leaked during the relay session. Pair with the Alliance + Combat phases — these structures need to start being written *before* any hacking module is implemented, otherwise the modules launch with empty intel.
- [ ] **Hacking counter-chain — member-side privacy modules** (canon: [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) Hacking chain doctrinal note #3). New defender tools that protect individual member data: proxy-routed transactions (route via wallet alias, transactions attributed to the alias not the primary playerId), loadout-history retention limits (player can configure their dossier to retain only the last N snapshots), credit-balance scrambling (balance encrypted at rest, only the member sees true value). Without member-side defenses, the only counter to Dossier hacking is "don't be on anyone's radar", which is bad gameplay. Pair with the hacking modules, not after.
- [ ] **Alliance shipment manifest data structure** (required for Supply-Chain Tap to have anything to read) — a PlayFab title-data structure per alliance listing scheduled inbound + outbound shipments: sender, receiver, cargo summary, origin/destination sector, ETA, predicted route. Hauler contracts and player-fleet auto-routing both write to it; Supply-Chain Tap reads a filtered subset via CloudScript. Without this layer the Tap module has no source data to parse — it's the literal prerequisite for blockade gameplay. Pair with the Hauler / Transporter role system.
- [ ] **External Crates as `ContainerInstance` variant.** Extend slice 1's `ContainerType` enum with `ExternalCrate`, and add two new fields: `crateForm` (`Solid | Gas` — drives the visual mesh / silhouette) and `crateHazard` (`None | Explosive | ExplosiveGas | Cryo | Radioactive` — drives the hazard color overlay and damage behavior). Crates are deployable container instances that ride a hauler's Crate-Push Rail. Mass-cap math from slice 1 applies. Canon: [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) "External Crates". **Visual canon is two-stage: silhouette (box vs. cylinder) + color**. Both are load-bearing — pirates resolve silhouette first at long range, then color as they close. UI / visual asset pass on crate prefabs has to enforce both axes; do NOT let crate variants ship with similar silhouettes OR similar colors that defeat snap recognition. Solid forms use the box mesh; Gas forms use the cylindrical pressure-tank mesh with visible end-caps and valve geometry.
- [ ] **Crate-Push Rail utility module** (M/L/XL) — `UtilityModuleSchema` instance. Holds N external `ExternalCrate` containers depending on rail size. Crate combined mass counts against the hauler's tow/push thrust budget. Crates on the rail are exposed to enemy fire (intentional). Canon: [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §D.
- [ ] **Transporter hull family** — Light Hauler, Heavy Freighter (existing canon), **Armed Hauler**, **Bulk Hauler**. New `ShipSchema` instances per canon at [`../ships/ships_class_index.md`](../ships/ships_class_index.md). All four fit a Crate-Push Rail; Armed Hauler and Bulk Hauler trade rail capacity for multiple defensive turret hardpoints. Bulk Hauler is capital-tonnage and is the primary Supply-Chain Tap blockade target.
- [ ] **Future crate variants** — Cryo Crate (for refrigerated Tier 3+ materials per Cryo-Silos canon) and Radioactive Crate (for Uranium / DU / Nuclear transport). Different hazard profiles; same `ContainerInstance` extension. Defer until those material classes have authored content in inventory.
- [ ] **Mining Outposts (pushable deployable structures)** — three variants (Standard / Refining / Fortified) per canon at [`../ships/ships_class_index.md`](../ships/ships_class_index.md). Built on the Tier 3 Outpost Structural Frame (Stainless + Ferro-Ti + Aerogel). Towed into a belt via Pusher Prow, anchored in place, auto-mines + stores yield in attached external crates. Powers down systems while in transit (no mining, no defenses). Schema-wise: new `OutpostSchema` (or extend `ShipSchema` with `deployable = true` flag, TBD with slice 2 — Outpost shares more with base-building modules than with hulls). Outpost ownership transfers if captured by Aggressive Tractor + Pusher Prow tow to friendly anchorage. Pair with the base-building system (Phase 6.8) — Outposts are doctrinally adjacent to base modules but mobile rather than fixed.

### 1.6.2 Recipes & Refining (Slice 2 of 5) — **LANDED**
Server-authoritative production handler + Tier-2 canon recipe set + facility-tier gating. Implementation summary in [`../economy/economy_overview.md`](../economy/economy_overview.md).
- [x] [`RecipeSchema.cs`](../../Assets/Scripts/Schemas/RecipeSchema.cs) ScriptableObject + [`FacilityType.cs`](../../Assets/Scripts/Schemas/FacilityType.cs) enum.
- [x] `PlayerProfile.smelterLevel / labLevel / minerLevel` + `FacilityLevel(FacilityType)` helper.
- [x] 14 Tier-2 canon `RecipeSchema` assets under [`Assets/Resources/Schemas/Recipes/`](../../Assets/Resources/Schemas/Recipes/).
- [x] 33 `ResourceSchema` assets covering canon Tier-1 raws + Tier-2 refined outputs.
- [x] [`cloudscript/recipes.js`](../../cloudscript/recipes.js) `RunRecipe` handler — validates inputs, scales by runs, enforces facility-tier gate, mass-checks against the container cap, emits resource adds + (reserved) module mints via `forge.js` checksum primitive.
- [x] [`RecipeClient.cs`](../../Assets/Scripts/Networking/RecipeClient.cs) + [`RecipeCatalogLoader.cs`](../../Assets/Scripts/Schemas/Catalog/RecipeCatalogLoader.cs).
- [x] [`ForgePanel.cs`](../../Assets/Scripts/UI/Forge/ForgePanel.cs) + [`RecipeRow.cs`](../../Assets/Scripts/UI/Forge/RecipeRow.cs) — recipe list, detail panel, run-with-toast, greyed-out un-met-tier rows.
- [x] Dev seed migration in `PlayFabManager.cs` (`CreateNewCommanderProfile` + existing-account Slice-2 backfill).
- [ ] Upload new CloudScript revision to PlayFab GameManager + update [`architecture_cloudscript_deployed.md`](../architecture/architecture_cloudscript_deployed.md). (Same deploy step as Slice 3a.)
- [ ] Author the ForgePanel prefab in the editor and wire a dashboard chip to open it. The C# locks the API; the prefab is cosmetic.

#### 1.6.2 Bridge code to remove
- [ ] **`cloudscript/recipes.js` `RECIPE_CATALOG` hardcoded mirror.** The catalog is hand-keyed today (BRIDGE flagged in-file) because the title-data export pipeline that would publish `RecipeCatalog` / `ResourceCatalog` / `ItemCatalog` from the ScriptableObject assets doesn't exist yet. Same removal moment as the existing Phase-1 inventory bridge (line 39 above). Single follow-up resolves both.
- [ ] **`PlayerProfile.smelterLevel / labLevel / minerLevel` flat per-player level fields.** Slice 2 stopgap until Phase 6.8 base-building lands. When per-base facility installations exist, the `RunRecipe` tier-resolution branch swaps "read profile field" for "scan player's `MacroBaseRecord`s on the container's body for max installed-facility tier of this type, capped by `base.tier`". Same RunRecipe error envelope — client doesn't change. Flag in [`PlayerProfile.cs`](../../Assets/Scripts/Networking/PlayerProfile.cs) `FacilityLevel(...)` helper.

### Phase 5+ Economy — Exchange / DOM / Currency / Banking

The universal DOM market system (canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md)) and the currency / banking layer that sits on top of it. Listed here because the slices interlock: DOM is the matching engine, currency is what gets priced on it, banks are the access gate.

- [ ] **DOM (Depth-of-Market) order-book exchange.** Universal trading engine — currency pairs, commodity markets, module flips all run through it. Bid / Ask sides, Market / Limit / Stop order types, price-time priority matching, partial fills. Schemas: `Order`, `Trade`, `MarketState` (per canon §7). Server-authoritative — all order placement, cancellation, and matching go through CloudScript handlers. **Hidden admin floor/ceiling values** (`floorPrice` / `ceilingPrice` per market in PlayFab title internal data) drive the "invisible hand" market-maker; these values must NEVER be returned to clients in any code path (per CLAUDE.md "Don't trust the client" — leaking them defeats the design).
- [ ] **Player-instance listing mechanics for graded modules / ships.** When a player lists a `PartInstance` on the DOM: (a) eligibility check enforces full durability (damaged items can't list — repair first), (b) seller's checksum validated against their `(playFabId, alchemySeed)`, (c) instance moved into a server-side market escrow, (d) on fill, escrowed instance is destroyed and a fresh instance minted for the buyer with their own checksum signature, (e) on cancel, instance re-stamped back to the seller and returned to inventory. Market segmentation: every `(itemID, grade, hub)` tuple is its own DOM market — Grade-A Fusion Reactors are fungible *within* their market, distinct from Grade-B. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "Player-instance listing mechanics".
- [ ] **Bespoke listings for individually designed ships / modules.** Seller chooses fungible vs. bespoke at listing time. Bespoke listings use a single-instance market keyed by `instanceId` (`market.bespoke.<instanceId>.<hub>`); single Ask, normal Bid side. **No atomization** — the actual instance transfers on fill (with checksum re-stamping for buyer) preserving custom name, paint, combat-record metadata. **Ship bespoke listings include all currently-fitted modules** as a package by default; seller can strip first. UI: separate "Bespoke" tab in the Bank Terminal trading panel, with a configuration-card display per listing rather than book rows. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "Bespoke listings". This is the path that lets Forged provenance and unique-build identity command premium pricing — distinct from the commodity-fungible market.
- [ ] **Physical-presence requirement for listings.** Goods must be physically at the trading post / hub before listing — listings are not abstract IOUs. CloudScript handler validates the seller has the goods at the hub's local inventory; on listing, goods move to a **per-hub escrow** keyed by `(marketId, hub, sellerId, listingId)`. On fill, escrowed goods enter the **buyer's pickup queue at the same hub** — NOT teleported to the buyer's home. Buyer must travel (or send a hauler) to collect. On cancel, goods return to the seller's pickup queue at the same hub. This is what makes hub control economically meaningful, enables Transporter arbitrage gameplay, and extends the Supply-Chain Tap blockade loop to purchases (buying creates inbound shipments). Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "Goods at the trading post".
- [ ] **Periodic storage fees on parked goods (anti-storage-abuse).** Weekly auto-debit at the Weekly Economy Tick for every active listing, computed against the **fungible market value** of the listed goods (NOT the listed asking price). Default rates per trading-post type (admin-tunable per hub in PlayFab title internal data): **0.5% / week at mainstream FED/ICE/alliance hubs, 0.1% / week at black markets**. Payment auto-debits from seller's wallet; if insufficient: commodity listings auto-liquidate a portion to cover, bespoke listings freeze, and any listing where back-owed fees exceed the goods' fungible value is **forfeited to the trading post** as a hard backstop. Fee is burned as a currency sink. UI shows expected weekly cost before listing + running total per open listing. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "Storage fees on parked goods". *(Supersedes the earlier one-time-at-withdrawal restocking-fee model — periodic charging is more economically authentic and closes the parking exploit during the listing, not just at the exit.)*
- [ ] **Black Market trading posts.** Special trading-post type with three advantages (no transaction tax — bypasses FED 35% / ICE tariff / 3% universal escrow; reduced 0.1%/week storage fees; **accepts contraband / stolen goods / Outlaw-doctrine items that mainstream hubs reject**) and several drawbacks (hidden location not on default map / discovered via player-to-player knowledge, no faction patrol coverage, no legal recourse, smaller liquidity, lawless space). Schema: new `tradingPostType : enum { Faction, Alliance, BlackMarket }` on the bank terminal / trading post record. Discovery flow: black-market coordinates spread via player-to-player intel, alliance directives, pirated couriers, or discovery quests — once known, persistent on the player's personal map. The hidden discoverability is the doctrinal cost; "I know where a black market is" becomes valuable social/trading capital. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "The Black Market".
- [ ] **Territory bubble model (foundational geometric mechanic).** Canon: [`../world/world_territory_bubbles.md`](../world/world_territory_bubbles.md). Faction and alliance territory is measured the same way the jump-gate network is measured — as bubble radii centered on owned anchors (faction capitals, faction outposts, alliance citadels, StatComs, etc.). Schema: `TerritoryAnchor { anchorId, ownerId, ownerType, position, bubbleRadius, tier, active }` in PlayFab title internal data. Server-side helpers `isInTerritory(point, ownerId)` and `territoriesContaining(point)` are the canonical queries every caller routes through. **No hand-authored sector-ownership lists.** Emergent space types (lawless / core / patrolled / contested) drop out of bubble overlap. Dynamic — destroying or capturing an anchor immediately reshapes territory. Used by: clean-goods `stolenFrom` rule, NPC auto-arbitrage cross-faction source filter, patrol response triggers, resource-permit enforcement, faction-bank access. **Foundational across multiple systems — implement before any of them are wired to the territory concept.**
- [ ] **Stolen-goods provenance tracking (territory-dependent).** New optional field `stolenFrom : string` on `PartInstance` / `ContainerEntry`. The tag is set **only when the piracy event occurs in patrolled territory** (FED core, ICE core, or alliance space with active patrols) AND the victim was a player. **Outlaw / lawless / neutral-contested space piracy produces clean goods** — no tag, sellable at mainstream hubs. NPC victims never generate `stolenFrom` tags regardless of territory (NPCs have no provenance), but patrol response still triggers faction hostility on attackers in patrolled space. Refining naturally launders (refined output is freshly-stamped). FED and ICE hub listing handlers reject tagged items; black markets accept. **Tagged goods appear visibly in black-market listings**, including to the original owner — enables recovery / revenge / bounty gameplay. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "Clean goods doctrine". **Two distinct piracy doctrines emerge:** faction-space (high-volume tagged loot, modest margin after laundering) vs. Outlaw-space (low-volume clean loot, high margin per kill).
- [ ] **Laundering service (black-market-only).** Admin-tunable fee (`market.launderFeePercent`, default 15% of fungible market value, payable any currency) that clears the `stolenFrom` tag from a listed item, allowing mainstream resale. Available only at black-market terminals. Forensically detectable for bespoke items via the maker's mark + custom name, but cleanly undetectable for fungible commodities. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "The Black Market".
- [ ] **Repair system.** Restores `currentDurability` to `maxDurability` (derived from `ItemSchema.durability` AnchorCurve at the instance's grade). New persistent field `currentDurability : float` on `PartInstance` (distinct from existing `runtimeHealth`). Repair handler `RepairInstance(instanceId, hubId, expressMode)` validates location + charges (currency + small material cost) + restores durability + re-stamps integrity checksum. **Facility tiers:** FED/ICE hubs (mainstream, refuse stolen/restricted); alliance citadels (member discount); black markets (accept anything, 20% premium); Mining Outposts Fortified-variant (emergency only, caps at ~80%). **Cost formula:** `(1 - currentDurability/maxDurability) * baseRepairCost * gradeMultiplier`. Queued repair (next weekly tick) is the default cheap path; express repair available at 3× cost. **Destroyed instances cannot be repaired** — durability=0 means the instance is gone. Capital-class repairs always queue regardless of price tier. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "Repair System". Closes the combat→damage→repair→resale loop that the listing-eligibility rule depends on.
- [ ] **Price bands on liquid fungible markets (anti-distortion).** Hard server-side rejection of orders outside the band — default ±50% of recent volume-weighted clear-price (per-market override in PlayFab title internal data: `market.priceBandPercent`). Applies only to markets with established price history (≥5 trades in last 7 days). Below threshold = "price discovery" mode, no band. **Bespoke listings exempt** — uniqueness + Forged-maker-premium justifies unrestricted pricing (the restocking fee remains the only friction on bespoke parking). Engine returns `{ ok: false, err: "OUTSIDE_PRICE_BAND", referencePrice, minLegal, maxLegal }` on reject. Client UI surfaces the band alongside the price input. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §3.5 "Price Bands on Liquid Markets". Together with the restocking fee, this closes the storage-abuse loophole at both ends — bands make absurd listings *impossible* (not just unprofitable), fee makes parking *unprofitable* (not just hard).
- [ ] **Regional pricing doctrine — admin-curated per-hub floor/ceilings.** Floor/ceiling values for commodity markets are set with **regional logic, not global defaults**: cheap floors at hubs near the resource source (gas hubs orbiting gas planets, metal hubs near belts, ice hubs near comet fields), higher floors at distant hubs. The spread between hubs is the arbitrage gameplay loop that justifies the Transporter role. Admin tools (or the market-creation pipeline) must surface "set floor/ceiling per hub" as the default workflow — NOT a global value that gets copy-pasted everywhere. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "Regional Pricing Doctrine". Forward-looking design item: should alliance leadership eventually get the power to tune local floor/ceilings on alliance-owned hubs? Currently admin-only; flagged as a future canon decision.
- [ ] **Cross-currency buyer auto-conversion (fiat ↔ fiat only).** Seller picks listing currency (FED / ICE / Gold). Buyer paying in non-listed fiat triggers an atomic two-leg transaction: (1) market BUY on the appropriate fiat-pair currency DOM to convert buyer's holdings to listed currency, (2) goods purchase using the converted currency. Either both legs execute or neither does. Buyer absorbs slippage from the currency conversion. **Gold is excluded** — gold-priced listings require the buyer to have physical Gold Ingots at the hub already, because gold is a finite physical commodity and can't be conjured from fiat at buy time. Generates guaranteed organic demand on the FED↔ICE DOM, keeping it liquid. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "Cross-currency buyer convenience".
- [~] **Maker's mark on `PartInstance` — Slice 3a landed.** `forgerPlayFabId` and `forgerDisplayName` are covered by the v3 `IntegrityChecksum` pepper on both C# and CloudScript sides; client cannot hand-edit them without tripping the tamper detector. `ForgePartInstance` CloudScript handler is the canonical mint primitive (recipe-driven forge in Slice 2 will call into it); dev-seed grants use `PartInstance.ForgeSystem` with the SYSTEM sentinel so they don't pollute MakerProfile aggregates. `InventoryInsert` / `InventoryMove` reject `INVALID_INSTANCE_ORIGIN` for any client-introduced Maker's Mark that doesn't pre-validate. **Still pending:** resale-rewrite path (the maker fields must be explicitly preserved when a buyer's checksum re-stamp happens — this lands with the market-listing handler in the DOM bullet above), and the fungible-vs-bespoke listing UI that hides/shows the mark at sale time.
- [ ] **MakerProfile aggregation + UI.** Server-side aggregation of forging stats per player: total volume, grade distribution, specialization (most-forged item types), sale-price premium (bespoke clear-price vs. fungible average for the same `(itemId, grade)`), downstream combat record (depends on combat-record metadata — see below). UI: clickable maker name on any forged item → MakerProfile page; top-level "Famous Makers" directory in the Bank Terminal; "follow maker" feature for ping on new bespoke listings. **No admin-curated reputation list** — reputation is purely emergent from data. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "Maker's Mark".
- [ ] **Combat-record metadata on instances** (dependency for bespoke listings, MakerProfile, AND hacker-readable player combat stats). Two parallel structures get written during combat resolution:
  - **Per-instance event log** — `notableEvents : List<NotableEvent>` on `PartInstance` / `ShipInstance`. Append-only. Captures kills logged on that specific instance, named pilots flown by, engagements survived, fleet ops participated in. Travels with the instance through resale (bespoke listings show this; the maker's mark links the instance back to its forger so MakerProfile reputation can aggregate downstream combat performance).
  - **Per-player aggregate combat record** — new top-level structure per player (server-side, in PlayFab player data or sibling key). Lifetime aggregates: total fights, win/loss ratio, kill counts by ship class, kill counts vs. each named opponent (so "Velkov vs Smith" rivalry surfaces), losses by ship class, highest-grade kill, fleet engagement count, total damage dealt / received, PvE vs PvP breakdown. **Stored as private player state** — default visibility is the player themselves only. Alliance leadership cannot see non-member combat stats. The only external read paths are hacking modules (T3 Combat Record Tap for session-scoped recent engagements; T4 Member Dossier Decryptor for lifetime aggregates). Plus a recent-engagements append-only log (rolling 60-day per data-retention canon) feeding the T3 module's session-scoped read.
  - Pair with the combat resolution / damage system (Phase 4) — events get written during combat, read during bespoke sale, MakerProfile aggregation, AND hacking module fills. Privacy doctrine is load-bearing on Combat Record Tap / Member Dossier value — if combat stats leak through any path other than hacking (debug panel, profile UI, alliance roster page), the hacking modules lose their purpose.
- [ ] **DOM UI — Bank Terminal trading panel.** Level-2 DOM display, order entry form, open-orders panel, trade-history strip, account summary. UI deliberately busy to feel like a commodity terminal; Market orders are the one-click simple path for casual users.
- [ ] **DOM access split: physical-presence vs. universal.** Per canon at [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §6:
  - **Universal (no bank required):** Fiat currency exchange (FED ↔ ICE); browsing markets; placing limit / market / stop orders; **buying goods** (settles atomically — currency debits, goods enter buyer's pickup queue at the hub); cross-currency auto-conversion as part of a goods buy.
  - **Bank Terminal required:** **Listing goods** (goods must physically be at the trading post to enter escrow); **collecting from pickup queue** (buyer must dock at the hub to take possession); converting Gold ↔ fiat (gold physically delivered to bank).
  - Outlaw belts have no banks, so all bank-required paths are closed *in Outlaw space*; players in Outlaw belts can still buy remotely from FED/ICE hubs, just can't pick up without traveling there. Fiat exchange always works.
  - CloudScript handler split: `BankExchangeFiat`, `BuyGoods` (with `targetHubId` param to route purchase into buyer's pickup queue at that hub) work universally with just a player session ticket. `ListGoods`, `CollectFromPickupQueue`, `ConvertGold` require a `bankTerminalId` validated against the player's current sector.
- [ ] **Per-hub Pickup Queue inventory structure.** Implicit per-(playerId, hubId) container holding goods awaiting collection — purchases routed here automatically, cancelled listings dropped here when seller isn't on-site, gold withdrawals queued here. **Storage fees apply identically to listings:** 0.5%/week mainstream, 0.1%/week black market against fungible market value, debited at the Weekly Economy Tick from the player's wallet. Same insolvency cascade as listing escrow: auto-liquidate commodities → freeze bespoke → forfeit if back-owed fees exceed value. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §6 "The pickup queue".
- [ ] **Freight contract system.** Full lifecycle per canon at [`../economy/economy_freight_contracts.md`](../economy/economy_freight_contracts.md): Posted → Claimed → InTransit → Delivered → Closed (with Failed / Cancelled branches). Schemas: `Contract`, `CargoManifest`, `HaulerProfile`. Escrow integration with slice 1 `ContainerInstance` via new `ContainerType.ContractEscrow`. Three contract scopes (Open / Direct / Alliance) + optional Contraband tag. Listing fee (admin-tunable, default 1% of payment) as currency sink. Collateral mechanics (poster's protection against hauler default; forfeit on failure). Auto-cancel on stale unclaimed posts (default 7-day post deadline); auto-fail on missed delivery deadline; auto-fail on cargo-lost-in-transit. CloudScript handlers: `ContractPost / Cancel / Claim / Pickup / Deliver / CollectDelivery / AutoTick`.
- [ ] **Hauler Profile aggregation.** Mirror of MakerProfile, per-player. Tracks completed / failed contracts, on-time delivery rate, total cargo value delivered, default rate, route specializations, cargo-class specializations, contraband-runs-completed counter, and a personal blocklist. Emergent from data — no admin-curated reputation list. "Find Haulers" directory UI at Bank Terminals lets posters discover haulers by filter (rep, route, cargo, faction alignment) and issue Direct Contracts. Canon: [`../economy/economy_freight_contracts.md`](../economy/economy_freight_contracts.md) §3.
- [ ] **Supply-Chain Tap data source unification.** The "alliance shipment manifest" that Supply-Chain Tap (T3 hacking) reads is now formally **the contract store filtered by `alliance affiliation AND status = InTransit`**. CloudScript hacking handler queries the contract store; result is filtered to leak only what was discoverable via passive Phantom Relay traffic. Closes the previous hand-wavy data-source for the manifest. Canon: [`../economy/economy_freight_contracts.md`](../economy/economy_freight_contracts.md) §5 + existing Supply-Chain Tap canon.
- [ ] **NPC auto-arbitrage system.** Trading posts as autonomous economic agents per canon at [`../economy/economy_npc_arbitrage.md`](../economy/economy_npc_arbitrage.md). Components:
  - **`HubStockLevel` schema** per `(hubId, itemId)` in PlayFab title internal data: `targetStock` / `replenishThreshold` / `replenishOrderSize` / `currentStock` / `maxStock`. Current stock publicly visible (market intel); thresholds admin-only.
  - **Restock cycle CloudScript job** at Weekly Economy Tick — scans for under-threshold hubs, queries cheapest Ask across hubs, places NPC market-buy order on the destination hub's DOM (`playerId = NPC_<hubId>`), dispatches AI transport.
  - **AI Transport NPC ship** — server-spawned hauler scaled to cargo volume, scaled PD escort by route risk, lootable on destruction (cargo wreck spawns for player salvage). Schema: `AITransport` runtime state per §3.
  - **Production hub bootstrap** — designated hubs (typically gas planets, prime mining bodies) auto-refill `currentStock` from a virtual source equal to floor price, simulating lore-justified inexhaustible supply. Admin tunable per (hub, commodity).
  - **Spread-burns-as-currency-sink** — AI sources at source-hub floor, sells at destination-hub ceiling; the spread disappears (contributes to deflationary pressure balancing new currency mintings).
  - **Pirate prey loop** — AI transports' routes are predictable + readable via Supply-Chain Tap (T3 hacking treats AI manifests identically to alliance shipment manifests, with `posterPlayerId = NPC_<hubId>`). Lost transports auto-replace at next tick. This is the recurring pirate income floor.
  - **Solves the earlier NPC seed liquidity gap as a side effect** — day-1 hubs with zero inventory auto-bootstrap on first tick.
- [ ] **NPC auto-arbitrage locked design decisions** (per canon [`../economy/economy_npc_arbitrage.md`](../economy/economy_npc_arbitrage.md) §9):
  - **Cross-faction sourcing: NO.** FED hubs never source from ICE; ICE never sources from FED. Source-scan filter enforces faction alignment strictly. Cross-faction commodity flow exists ONLY via player smuggler contracts. Alliances inherit by their faction alignment; neutral/Outlaw alliances opt out of faction-side sourcing entirely.
  - **Alliance-hub participation: opt-in per commodity.** New `allianceHub.npcArbitrageOptIn : Dictionary<commodityId, bool>` config. Default false. Alliance leadership explicitly enables auto-arbitrage on commodities they want stable supply for; opting in exposes hub stock levels publicly and accepts NPC transport traffic.
  - **Adaptive PD escalation: auto-learn from losses.** Per-route `routePDState` tracking 30-day rolling losses. If losses ≥ threshold (default 3), `currentEscortCount` auto-increments by `escalationStep` (default 1). After cooldown of zero losses, auto-decrements toward `baselineEscortCount`. Admin-set ceilings and overrides still apply. Affects both AI transports AND returning NPC miners on the route. Emergent design: pirates who moderate their hunting maintain low escort levels indefinitely; greedy pirates auto-tune the route past profitability.
  - **Mining Outpost integration: no direct AI ↔ outpost link.** Outposts are not trading hubs and not DOM-addressable. The outpost-to-NPC-buyer flow is two-step: (1) outpost owner physically hauls goods to a trading hub, (2) lists on hub DOM, NPC auto-arbitrage may fill the listing same as any other player ask. Preserves the canonical "all trading goes through trading posts" rule.
- [ ] **NPC miners — supply side of the NPC economy.** Faction-employed (FED mining contractors, ICE military extraction) or alliance-employed AI mining ships that physically extract raw materials from belts / gas clouds, then haul to nearby hubs. Canon: [`../economy/economy_npc_arbitrage.md`](../economy/economy_npc_arbitrage.md) §4.5. Schema: `NPCMiner` per §4.5 with five-state lifecycle (Spawning / Mining / Returning / Selling / Despawning). **Replaces lore-handwave "production hub infinite supply" with concrete physical miners** — more realistic, more attackable, more interactive. Admin tunables: `maxConcurrentMiners` per `(sectorId, commodityId)`, spawn frequency, mining rate, escort count, preferred destination hub. **Two new piracy prey types** beyond NPC transports: stationary-mining-phase miners (low-tier hunt) and returning-transit-phase miners (medium-tier hunt). **Permit interaction:** in alliance territory, alliance can deny faction NPC miners by withholding permits — strategic lever to cut off NPC upstream supply. NPC mining feeds the same `currentStock` field as NPC transports — destination hub treats both supply sources identically.
- [ ] **Contract-bound cargo flag.** Cargo that's in transit on a contract carries a flag preventing the hauler from listing it on the DOM, selling it directly, or repurposing it. Cleared on successful delivery. Implementation: new boolean / contractId field on `ContainerEntry` or `PartInstance` that the listing-eligibility checks consult. Without this, a malicious hauler could divert contract cargo for personal profit before completing the contract.
- [ ] **60-day data retention + daily aggregation job.** Canonical retention rule: transient transaction records deleted after 60 days. Maintenance CloudScript runs daily — for every transient record older than 60 days, computes contribution to long-lived aggregates (MakerProfile stats, per-market daily VWAP summaries, per-player counters for paid/missed obligations), updates aggregates in place, then deletes the raw record. **Idempotent** — running twice doesn't double-count. **Resumes from interruption** — tolerant of partial failures. Pruned: `Trade` fills, closed `Order` records, loan/tax payment events, expired permits, hacking events, fee-debit events. Retained indefinitely: MakerProfile aggregates, open orders, active loans/permits, `PartInstance` / `ShipInstance` inventory, faction standings, daily VWAP summaries. **Disputes have to be raised within the 60-day window** — flag in player-facing trade-history UI. Canon: [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §10 "Data Retention and Aggregation". Critical: MakerProfile rollup correctness — if this path is lossy, maker reputation rots silently.
- [ ] **Three-currency schema migration.** Rename `PlayerProfile.federationCredits` → `pactCredits` to match faction-naming canon. Add `iceCredits : int`. Keep `premiumCurrency` (real-money only, separate from in-game economy). Gold lives in `stackableInventory["gold_ingot"]` as a regular resource — not a separate balance field. **BRIDGE:** existing `federationCredits` field stays as an alias readonly for backward compat with saves until a migration handler ships. Track here.
- [ ] **PlayFab currency-state title data.** New title key `CurrencyState` with `pactSupply`, `iceSupply`, `goldSupplyEstimate` (server-rolled-up from inventories) plus per-market `floorPrice` / `ceilingPrice` admin-tunable values.
- [ ] **Gold-to-currency conversion at banks.** Player physically deposits Gold Ingots at a bank terminal; conversion goes through the gold-currency DOM market (`market.gold_to_pact` or `market.gold_to_ice`) at current market price. No special "convert" button — gold conversion is just a trade like any other.
- [ ] **Reconcile `economy_trade.md` scarcity-pricing model with DOM canon.** The old `currentStock / targetStock` formula now seeds DOM floor/ceiling defaults but does NOT drive live prices. Update `economy_trade.md` to point to `economy_exchange_pricing.md` as the canonical live-pricing model and clarify the scarcity formula's narrower seeding role.

### Phase 5+ Economy — Obligations, Loans, and Licenses

Three interlocking mechanics that bind players to faction / alliance authority. Full canon: [`../economy/economy_obligations.md`](../economy/economy_obligations.md). All three depend on faction-standing state (separate prerequisite, flagged below).

- [ ] **Faction Standing system.** Numerical standing per `(playerId, factionId)` ranging -10,000 to +10,000. Changes from contracts, attacks, paid taxes, defaulted loans. Gates loan eligibility, permit pricing, patrol hostility. Schema: `PlayerProfile.reputations : Dictionary<factionId, int>`. CloudScript handlers for read / mutate; server-authoritative only. **Hard prerequisite for Loans and Permits work.**
- [ ] **Faction Loans system.** Reputation-gated capital borrowing. Schema: `Loan` per canon §6. Weekly auto-debit at the economy tick. Three-tier escalation: late fee → grace period → **unwinnable NPC raid fleet** to base. Raid scaled to always-beat-defender so default isn't a free exploit. Currency burns on penalty; sinks on raid collection.
- [ ] **Planet Tax system.** Weekly tax to planet owner (FED/ICE faction OR alliance). Assessment scales with base footprint (modules × tier × per-planet rate). Three-tier escalation: late fee → grace period → **defeatable NPC tax collector fleet** (contrast with loan default raid, which is unwinnable). Alliance-owned planets: alliance sets the tax rate within the 25% non-member ceiling.
- [ ] **Resource Permit system.** Alliance-issued licenses for harvesting in alliance-controlled territory. Listed on the DOM like commodity items. Server-side permit check on every harvest action; non-permit-non-member harvesters alert the alliance patrol fleet. Retroactive permit purchase at 2× penalty rate clears in-progress violations. Default 7-day expiry creates recurring purchase events.
- [ ] **NPC enforcement spawn system.** Three tiers per canon §5: Patrols (defeatable, sector-threat-scaled), Tax Collectors (defeatable, debt-age-scaled), Default Raid Fleet (unwinnable, scaled to overwhelm). Server-spawned at appropriate triggers (patrol on unauthorized harvest, collector after 2 missed tax weeks, raid fleet after 3 missed loan weeks). Each tier needs its own NPC AI doctrine.
- [ ] **Weekly economy tick scheduled job.** Server-side cron-like CloudScript job that runs all the weekly mutations: assess taxes, auto-debit loan payments, age delinquencies, expire permits, trigger enforcement spawns at thresholds. Single coherent tick rather than each system having its own scheduler.
- [ ] **Point-Defense (PD) modules — three-pillar doctrine.** `UtilityModuleSchema` (or possibly `WeaponSchema` subtype with a `pdMode = true` flag) instances for the three canonical PD modules: **Flak Batteries** (kinetic, T2, already in canon), **Talos Laser Array** (energy, T3, consumes UV Laser Cells), **Iron Dome Interceptor** (interceptor-missile, T3, consumes Interceptor Missile ammo). PD modules need an auto-targeting subsystem that fires at incoming projectile entities without player input — distinct from primary weapons which the player controls. Schema slot: `componentClass = "PointDefense"` on a dedicated PD hardpoint, OR runtime auto-fire flag on existing weapon hardpoints (TBD with slice 2). Canon: [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §3.1 "Point-Defense Doctrine".
- [ ] **Interceptor Missile ammo** (T2, see [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md) "Point-Defense Ammunition") — `AmmunitionSchema` instance, family = "Interceptor", size variants S/M for Iron Dome S/M/L module size compatibility. Recipe: Steel + Sulfur + Crypto Substrate. Ships alongside the Iron Dome module.
- [ ] **Naval-doctrine pivot — lasers move from primary to PD** (canon: [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §0 "Combat Doctrine" + §3.1 four-pillar PD). When `WeaponSchema` instances are authored for the existing T2/T3 laser cells, the parent module schema must be classed as PD (auto-targeting, anti-small-target) rather than primary. Pulse Laser Turret, UV Laser PD (a.k.a. Talos Laser Array), IR Laser PD, X-ray Laser Spinal (lone capital exception). Primary weapon doctrine is kinetic-first; energy is specialty.
- [ ] **Machine Guns + Machine Gun Drum** (T2 PD module + ammo). `WeaponSchema` instance class = "Kinetic", `pdMode = true`, S-class only. Recipe: Steel + Sulfur. Canon: [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §A.
- [ ] **Heavy Cannons / Naval Guns** (L/XL kinetic primary). `WeaponSchema` instances — the "broadside" capital weapons doctrinally central to "navy battle in space" feel. Slow ROF, high damage, AP Steel / Tungsten Penetrator / HE Shell ammunition. Canon: [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §A.
- [ ] **Naval close-combat & blockade modules** (canon: [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §3.2):
  - Ramming Spike / Reinforced Prow (L/XL nose-mount) — consumes Reinforced Prow Plate (T3).
  - **Pusher Prow** (L/XL nose-mount, mutually exclusive with Ramming Spike) — consumes Reinforced Prow Plate (T3). Capital-asset mover for salvage tugs and aggressive ship-push tactics.
  - **Tow Cable Winch** (S/M/L) — consumes Tow Cable Spool (T2). Friendly + hostile tow modes. Cheap default rescue / salvage tool. Cable severable by enemy fire.
  - Aggressive Tractor Beam (M/L) — pulls hostile target rather than wreckage. Distinct from industrial Tractor Beam.
  - Proximity Mine deployment module (S/M) — drops Kinetic / EMP / Nuclear mine variants. Mine variants live in T2/T3 ammo chain.
  - Mass Driver weapon (XL) — fires Mass Driver Boulder ammunition. Cheap-blockade Outlaw doctrine.
  - Stealth Missile launcher (M/L) — same hardpoint as Missile Rack, consumes Stealth Missile Body + standard warhead.
- [ ] **Stealth Cost Doctrine compliance check** (canon: [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) §3.4) — when authoring stealth-related recipes (Stealth Coating, Phase Cloak Field, Stealth Missile Body), do NOT lower their material cost without paired strategic justification. Stealth is expensive by design; cheap stealth breaks ambush + scout + transporter balance simultaneously.
- [ ] **Hacking counter-chain (defender side)** — alliance encryption upgrades, anti-tap detection modules, decoy chat noise generators, tech-tree compartmentalization. Same phase as the hacking modules. Without the counter-chain, hacking is one-sided and the alliance gameplay loop gets toxic fast. Track as a paired deliverable, not a follow-on.

#### 1.6 Bridge code to remove
Per [`../../CLAUDE.md`](../../CLAUDE.md) "Building durably — no throwaway code", every bridge below must be code-flagged with `// BRIDGE: …` and resolved by the listed phase.

- [ ] **`PlayerProfile.moduleInventory` + `stackableInventory` are the home-base vault.** Today the legacy global inventory fields are treated as a single implicit "home-base vault" container, because [`ShipyardUI.cs`](../../Assets/Scripts/UI/ShipyardUI.cs) and several login-time grant paths still read/write them directly. Remove when ShipyardUI is refactored to read inventory through `InventoryClient` / `ContainerInstance` (target: alongside Phase 6.8 base-building, when storage modules become a thing). Bridge flag in [`PlayerProfile.cs`](../../Assets/Scripts/Networking/PlayerProfile.cs).
- [ ] **CloudScript mass-cap math uses defaulted per-unit / per-instance masses.** [`cloudscript/inventory.js`](../../cloudscript/inventory.js) cannot read the `ResourceSchema` / `ItemSchema` mass curves directly (no Title Data export pipeline yet), so it uses `DEFAULT_RESOURCE_MASS_PER_UNIT_KG = 1.0` and `DEFAULT_GRADED_INSTANCE_MASS_KG = 0.0`. Client UI is fine — it has the schema assets. Remove when the schema → Title Data export ships (target: Phase 1.5 PlayFab starting-inventory migration). Bridge flag in `cloudscript/inventory.js`.
- [ ] **`FactionId.LegacyPact` normalization shim — PACT → FED rename migration.** The Federation faction was briefly renamed PACT in 2026-05-03 docs/code and reverted to "Federation" with tag "FED" on 2026-05-16. [`FactionId.cs`](../../Assets/Scripts/Common/FactionId.cs) carries a `LegacyPact = "PACT"` constant and a `Normalize()` helper that maps any legacy `"PACT"` it reads from external data to `"FED"`. Touch points: `JumpGateMarker.UpdateState`, `JumpGateNetwork.SameFaction`, `JumpGateNetwork.IsFactionVisible`, `MacroJumpGateBroadcastVisual.ResolveColor`, `CelestialChildBuilder.ColorForOwner`. **Remove the shim when:** (a) [`Assets/GameData/Celestial/seed.json`](../../Assets/GameData/Celestial/seed.json) is re-uploaded as the `CelestialRegistry` title data in PlayFab GameManager (one admin action, already updated locally), AND (b) any player saves carrying `"PACT"` in faction-tagged fields (alliance memberships, etc.) have rolled through one login cycle. After both: delete `FactionId.LegacyPact` + the legacy branch in `FactionId.Normalize`/`IsFederation`, and audit all callers that use the helpers vs. direct `== FactionId.Federation` compares — direct compares are fine once legacy data is gone.

---

## Phase 2 — User Interface & Garage Mechanics
**Goal:** Player logs in, lands on a Dashboard, opens the Shipyard, drags a weapon onto a hardpoint, and the change writes back to PlayFab.

### 2.0 UI Toolkit migration (foundation)
**Started 2026-05-27** — pivoting new UI work from uGUI (Canvas + HorizontalLayoutGroup / VerticalLayoutGroup procedural builds) to Unity's UI Toolkit (UXML + USS + UIDocument). Reason: uGUI's layout system is brittle for complex menus (`childControlHeight` / `childForceExpandHeight` interactions are non-obvious, debugging requires per-element logging). UI Toolkit's flexbox + USS hot-reload makes iterations vastly cheaper, and Apex Outlaw has a long menu queue ahead (Smelter, Lab, Forge, Market, Alliance, Hauler, Dossier, Trade Window, Shipyard refresh, etc.) — paying the migration tax now beats compounding the uGUI cost.

- [x] **2.0.1 Pilot — Inventory Panel:** Rewrite `CrateInventoryPanel` to UIDocument. Files: `Assets/UI/Inventory/Inventory.uxml`, `Inventory.uss`, `Assets/UI/InventoryPanelSettings.asset`. Existing uGUI build (`BuildUI`/`BuildHeader`/etc.) removed; data methods kept. Toggle hotkey + sort + delta tracking + smeltable detection + periodic-card display all preserved.
- [ ] **2.0.2 Deferred — Inventory open/close animation:** USS transitions on `opacity` + `scale` (200ms ease-out). Was in old uGUI version via coroutine + CanvasGroup; reimplement as `.inv-root` style transitions when polish pass happens.
- [ ] **2.0.3 Pilot review:** Once `2.0.1` ships and Aaron has used it for a session, decide: migrate all future new UI to UI Toolkit (default), and migrate existing uGUI panels opportunistically when they need substantial rework. **Do NOT** mass-migrate uGUI to UI Toolkit as a standalone task — too risky, too little payoff vs. the in-flight feature queue.
- [ ] **2.0.5 SettingsOverlay (incl. Display panel, added 2026-06-07):** runtime-procedural uGUI by design — built to match the existing overlay rather than fork the settings UI across two frameworks. Migrate per the 2.0.3 policy when the overlay gets substantial rework. Display state itself lives in `DisplaySettings` (framework-agnostic), so only the widget layer migrates.
- [ ] **2.0.4 Modern UI Pack + Cyberpunk RPG UI sprite ecosystem:** these were uGUI-only assets. With the UI Toolkit pivot, all chrome (panels, buttons, frames, icons) lives in USS instead. Existing uGUI panels still using these assets are fine until they're rewritten; new UIs do not adopt them.

### 2.1 The Dashboard Frame
- [x] Implement `PlayFabManager` login triggers to open the main dashboard scene using Michsky Shift UI.
- [x] Create a Top Bar UI with `Commander Name`, `PlayFab ID`, and live `Credits` / `Premium Polish`.
- [ ] Integrate a responsive notification system for server status and live updates.

### 2.2 Shipyard
- [x] **2.2 The Shipyard Visuals:** Bind deserialized PlayFab inventory data to UI. Display active hulls and hardpoints.
- [x] **2.3 Ship Visualizer & Interaction:** Top-Down Orthographic blueprint camera (RenderTexture).
- [ ] **2.4 Drag and Drop Logic:** Drag an item onto a UI hardpoint slot and write the updated JSON back to PlayFab.

---

## Phase 2.5 — Sector View HUD
**Goal:** Player sees a sector map with their launched fleets in a bottom roster, can pick a configured fleet from a right-edge dock and launch it.

*Added 2026-05-02 — flagged after promoting the `GlobalHUD` top bar to a persistent singleton (`GlobalHUDBootstrap`). The top bar carries player identity (commander, credits, settings, nav); the sector view needs its own surfaces below that.*

- [ ] **2.5.1 Launched Fleet Roster Bar:** Bottom-anchored transparent bar listing **launched** fleets (not configured fleets). Card per fleet with name, ship-count icon, HP/shield aggregate, distance/ETA, combat indicator. Source data: live launched-fleet state. Canon: [`../world/world_sector_map.md`](../world/world_sector_map.md) line 489.
- [ ] **2.5.2 Right-Edge Fleet Launcher Dock:** Persistent right-edge dock listing the player's configured fleets so launches can fire from the sector view. Read-only re composition (editing happens in Shipyard). Canon: [`../world/world_sector_map.md`](../world/world_sector_map.md) §"Fleet launcher dock".
- [ ] **2.5.3 `SectorMapHUD` controller:** Top-level MonoBehaviour owning the sector-view HUD surfaces (range rings, beacon icons, waypoint preview, gate-spool overlay, launched-fleet roster, fleet launcher dock). Canon: [`../world/world_sector_map.md`](../world/world_sector_map.md) lines 485–489.

---

## Phase 3 — Resource Scanner (Sector-View Material Anchors)
**Goal (revised 2026-05-17):** Player opens the sector-view Resource Scanner panel, toggles a material, and sees up to 50 flashing markers on belt rocks where they can find that material at their current max-discovered grade. Per-player deterministic from `alchemySeed`. Canon: [`../economy/economy_scanning_extraction.md`](../economy/economy_scanning_extraction.md).

> **Course correction 2026-05-17:** The earlier vertical slice (fly-and-lock 3D scanning, deployable Telemetry Beacons, mining-tick extraction in a programmatic AsteroidInstance scene) was scrapped — wrong UX shape. The data layer (schemas + admin PDF + maxDiscoveredGoods cache + grade table tweak) survived; the gameplay layer was demolished and rebuilt as the right-side toggle menu described above. See the canon doc §6 for what was deleted.

> **Replaces** the legacy "Alchemy Engine (heatmap grid)" plan. The 10,000×10,000 per-player matrix model in [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md) §§1–3 is superseded by the seed-driven fat-tail RNG here. The grade table (§3.5), Golden-Logic loot path (§4), and economic-role framing (§4.5) survive untouched. Full canon-doc rewrite ships with the purity cascade (Phase 5).

### 3.A Landed in current slice (post-2026-05-17 pivot)
- [x] **Grade asset** + `Fl` → `[Flaw]` shortCode tweak. Survives from pre-pivot.
- [x] **Data-layer schemas** (survive from pre-pivot): `GradedStack`, `MaxDiscoveredGoods`, `ResourceAnomalySchema`, `TelemetryBeaconSchema` (schema only — entity concept dead), `MiningLaserSchema`. `PlayerProfile.maxDiscoveredGoods` + `gradedInventory`; `ContainerInstance.gradedStacks` + mass-cap math (Unity + `cloudscript/inventory.js`).
- [x] **6 anomaly assets** under `Resources/Schemas/Anomalies/` (iron, carbon, silicates, titanium, helium3, platinum) with admin-tuned grade-probability `AnchorCurve`s.
- [x] **`cloudscript/scanning.js` rewrite** — single `ResolveMaterialAnchors(materialId, beltSeed, virtualCount)` handler. Returns up to 50 anchor indices per material; per-player deterministic from `alchemySeed`. BRIDGE: defaults `maxGrade` to A (byte 9) when player hasn't discovered the material yet.
- [x] **Resource Scanner panel UI** (`ResourceScannerPanel` + `ResourceScannerMarker`). Auto-installed via `[RuntimeInitializeOnLoadMethod]` into any scene with a `MacroAsteroidBelt`. Programmatic UGUI; designer prefab to replace later.
- [x] **`MacroAsteroidBelt.TryGetRockOrbit(index, ...)`** accessor so markers can track rocks as they orbit.
- [x] **`cloudscript/_deploy_bundle.js`** auto-generator (`Apex Outlaw → CloudScript → Rebuild Deploy Bundle` menu item).
- [x] **Canon doc rewrite** — `economy_scanning_extraction.md` reflects the new model.

### 3.A1 Deployment + verification

- [x] **Aaron uploads bundle as PlayFab revision 8** — deployed 2026-05-17.
- [x] **Smoke test: toggle "iron" in the panel → see ~50 markers flash on belt rocks** — passed 2026-05-17.

### 3.A2 Demolished in pivot (do NOT resurrect)

The following were built then deleted because the underlying UX shape was wrong (fly-and-lock 3D scanning instead of the sector-view toggle model). If you see references to these in old design docs or stale memory, those references are stale:
- `Assets/Scripts/Macro/AsteroidInstance/` — Loader, Host, Interface, PresenceClient, EntryClickHandler, EntryRegistrar, Scanner UX (sweep renderer, blip marker, freq-lock controller).
- `Assets/Scripts/Macro/Beacons/` — TelemetryBeaconEntity, BeaconDeployAffordance, BeaconExtractionSession.
- `Assets/Scripts/Macro/SectorMap/AsteroidInstanceIndicator.cs`.
- `cloudscript/beacons.js`, `cloudscript/mining.js` — DeployBeacon, RetrieveBeacon, ListBeaconsInBody, ApplyExtractionTick.
- `Assets/Resources/Schemas/Recipes/recipe_telemetry_beacon.asset` (deployable concept dead).
- `CelestialParentRecord.entryEnabled` + `.candidateResourceFamilies` + `CelestialSpawner.EnsureAsteroidInstanceEntry` (no per-named-asteroid runtime click target anymore).
- `MacroAsteroidBelt.bypassFowStreaming` (no runtime instance scene needs it).
- `AsteroidInstanceCategoryRegistry` schema + asset.
- Pre-pivot `economy_scanning_extraction.md` (replaced).

### 3.A3 Hand-off notes (gotchas a fresh session WILL hit)

- **Do NOT edit C# while Aaron is in play mode.** Every recompile kills FOW state and forces a restart through MainMenu (login re-fires). Aaron got bitten 4+ times in this thread; he has limited patience for it.
- **Do NOT touch `MacroMiningBridge.cs`.** It's the live placeholder for click-belt-rock → 5-min timer. Will be replaced by the mining scene (see §3.C). Marking it legacy was wrong the first time.
- **CloudScript deploys are manual.** Aaron pastes the bundle into PlayFab Game Manager → Automation → Cloud Script → Revisions → Upload New Revision → Save → Deploy. There's `Assets/Editor/Debug/SyncPushRegistry.cs` for celestial registry pushes (uses Admin/SetTitleData) but no equivalent automation for CloudScript revisions.
- **Bundle rebuilder:** `Apex Outlaw → CloudScript → Rebuild Deploy Bundle` menu (`Assets/Editor/Debug/RebuildCloudScriptBundle.cs`). Auto-concatenates `cloudscript/*.js` (excludes `_*.js`) into `cloudscript/_deploy_bundle.js`.
- **Login state survives across script executions in the same play session**, but a C# edit triggers domain reload and clears it. After any edit, restart play from MainMenu (not Vesperion) so login fires.
- **`PlayFabClientAPI.IsClientLoggedIn()` is lying when blocked.** Calling it from a `Thread.Sleep` poll returns false because the SDK callback can't fire while the main thread is blocked. Use the fire-and-log pattern with a separate inspect call rather than synchronous waits.
- **`GameObject.Find` is unreliable in Unity 6.** It returns null for root-level GameObjects that demonstrably exist. Use `SceneManager.GetSceneAt(i).GetRootGameObjects()` and walk by name instead.
- **The Vesperion scene has NO `CelestialSpawner`.** Bodies are hand-authored. Hooks that subscribe to `CelestialRegistryClient.OnRegistryUpdated` work; hooks that ride inside the spawner's `ApplyRegistry` pass do not.
- **The two pending design calls are Aaron's, not yours.** Don't pre-build the mining scene or the named asteroid scenes — wait for direction.

### 3.B Phase 3 Bridge code to remove
- [ ] **`cloudscript/scanning.js` ANOMALY_CATALOG hardcoded mirror.** Same removal moment as the existing `RECIPE_CATALOG` bridge (`cloudscript/recipes.js`) — the title-data export job that publishes `RecipeCatalog` will also publish `AnomalyCatalog` and `ResourceCatalog`.
- [ ] **`cloudscript/scanning.js` `SCAN_BRIDGE_DEFAULT_GRADE` (A=9).** Hardcoded fallback when player has no `maxDiscoveredGoods` entry for a material. Remove once the mining scene stamps real discoveries via extraction.
- [ ] **`ResourceScannerPanel` programmatic UGUI.** v1 builds the panel in code. Replace with a designer-authored prefab when one is ready.
- [ ] **`PlayerProfile.stackableInventory` (ungraded path).** Already tracked under Phase 1 inventory bridges — graded paths land in `gradedInventory`/`gradedStacks` as features ship.

- [ ] **`ConstructionLabController.DevGrantMaterials` dev material grant.** `// BRIDGE: remove when the surface mining drop-off writes into PlayerMaterialsStore` — the lab's material feed is real (consumes `player_materials.json`), but until mining/extraction deposits into `PlayerMaterialsStore`, the DEV GRANT button seeds test stock. Remove button + this entry when the drop-off hookup lands (see `ships_construction_pipeline.md`).
- [ ] **Construction Lab default forge cost rule.** Parts without an authored `buildCost` fall back to the explicit mass-based iron rule (`ConstructionLabController.CostFor`). Author real `buildCost` recipes on the marauder/corsair part schemas, then tighten the fallback to a hard "no recipe = can't forge" gate.

### 3.C Deferred to later phases (forward pointers, do not lose)
- **Mining scene (TBD authoring) — the canonical extraction loop.** Click a small belt asteroid → load a per-rock mining scene. Inside: deeper scan of individual rocks for better grades, deploy miner ships / outposts, pull ore. Extraction event compares rolled grade vs `maxDiscoveredGoods` and stamps if better. Removes the `SCAN_BRIDGE_DEFAULT_GRADE` bridge above. Aaron has not authored this scene yet.
- **Named asteroid scenes — `Asteroid_<bodyId>.unity`.** Click a large named asteroid (Castor, Latro, etc.) on the sector view → load that body's scene (mirror of `Planet_avernus.unity`). Contents undecided.
- **Phase 5 — Purity cascade in `RunRecipe`.** Recipes consume `GradedStack`s; output grade = `min(input grades)`. `recipe.apexThreshold` + `MaybeRegisterApexDiscovery` server-wide first-Flawless event with Maker's Mark stamp.
- **Phase 5 — Full rewrite of `economy_alchemy_research.md` §§1–3.** Replace the matrix grid model with the canonical scanning + cascade economic loop.
- **Phase 5 — DOM Exchange classification UI.** Surface the TDD §1 fungibility table (Bulk / Premium / Serialized / Bespoke Maker's Mark) on inventory + listings.
- **Phase 5+ — NPC scanner doctrine.** NPC patrols, mining-camp behaviors.

---

## Pipeline Hardening — ship/part content platform (2026-07-06)
**Goal:** adding a ship or part is a clean schema drop-in everywhere. The LOCAL path is already
there (`NpcShipSpawner` derives all stats at spawn from `ShipPartSchema` + module schemas; see
[`../pipelines/pipeline_ship.md`](../pipelines/pipeline_ship.md)). Remaining gaps:

- [~] **PH.1 Converge spawn paths.** DONE 2026-07-06 (schema-first): `TacticalFleetLoader` now
  resolves fitted-module visuals via `ResolveModulePrefab` (WeaponSchema.weaponPrefab /
  ShipPartSchema.prefab by itemID) — the same schema resolution `NpcShipSpawner` uses. The old
  name-based `GetModuleResourcePath` is demoted to `LegacyModuleAddressableKey`, a marked BRIDGE
  fallback for modules whose schema carries no prefab yet. Compile-verified; runtime verification
  pending the Fusion/PlayFab path (not runnable offline). Remaining: retire the bridge once all
  modules author prefabs; converge the Fusion `NetworkObject` spawn onto the local assembler.
- [ ] **PH.2 Retire legacy `ShipHullData`.** `Smuggler_Frigate_Data.asset` loads null (broken);
  superseded by `ShipSchema` + `ShipPartSchema`. Deprecate + remove references.
- [x] **PH.3 Kill residual name smell.** ~~`NpcShipSpawner` classifies thrusters via
  `partID.Contains("thruster")`~~ — DONE 2026-07-06: replaced with schema-typed
  `IsThrusterPart(ps)` (a part is a thruster iff a ThrusterSchema resolves for its
  `engineProfileId`). Verified: flaw cruiser still classifies its 8 thruster nozzles + derives
  strafe/yaw/power correctly.
- [ ] **PH.4 Derive baked vitality.** Armor/shield/AI-range still read `NpcShipRecord.baked*`;
  derive from parts like flight + power already are, then drop `baked*`.

---

## Phase 4 — Tactical Combat Instances (Micro-Game)
**Goal:** Two players can engage in a Fusion combat instance, fire weapons, take damage, and at instance-end the result is written back to PlayFab.

> **Instance cap (canonical — updated 2026-05-04):** Combat Fusion instances are hard-capped at **3 vs 3 active combatants + up to 10 spectators (16 players total per instance)**. Spectators see the fight but cannot fire, take damage, or contribute fleet stats. Mining-op instance cap is sized separately and is **TBD**. See [`../architecture/architecture_plan.md`](../architecture/architecture_plan.md) §3.0 and [`../world/world_sector_rules.md`](../world/world_sector_rules.md) §1.

- [ ] **4.0 Fusion Architecture Paradigm:** Install the Photon Fusion SDK. Establish the boundary from `MonoBehaviour` float physics into Fusion's tick-driven authoritative simulation for combat instances.
- [ ] **4.1 Sector Serverless Map Matrix:** Macro "Sector/Universe" map runs on PlayFab CloudScripts only — no Fusion runner outside event instances.
- [ ] **4.2 Battle Room Initialization:** Launch combat Fusion rooms enforcing the **3v3 combatant slot cap** + **10 spectator slots** (16-seat total). Handle disconnected inputs (AI handoff). Finalize end-of-combat results payload.
  - [ ] **4.2a Spectator role:** Spectators join read-only — receive networked state, render the fight, no weapon authority, no hitboxes, no aggro contribution. Decide entry policy (open / fleet-only / alliance-only) and overflow when the 10-slot ceiling is hit.
  - [ ] **4.2b Combatant overflow / instance spilling:** When a sector wants more than 3v3, decide between (a) parallel combat instance, (b) queue late joiners as spectators until a combatant slot frees, or (c) reject with a "fight is full" macro-map message. Document in [`../world/world_sector_rules.md`](../world/world_sector_rules.md).
  - [ ] **4.2c Mining-op instance cap (TBD):** Mining ops aren't bound to 3v3. Decide the cap (suggest scaling to roid-cluster size) and document in [`../architecture/architecture_plan.md`](../architecture/architecture_plan.md) and [`../world/world_sector_rules.md`](../world/world_sector_rules.md).
- [ ] **4.2d Mining-op Fusion scene:** Build the actual mining-op Fusion event instance — the real implementation behind the macro-side bridge in Vesperion (`MacroMiningAttachment` / `MacroMiningSession` — click procedural asteroid → fleet attaches → drifts with rock → tinted red → 5 min). Replaces the bridge with: Fusion runner spawn on click, FleetSnapshot bridge per [`../architecture/architecture_data_schemas.md`](../architecture/architecture_data_schemas.md) §6, multi-fleet roster (miners + attackers), per-tick yield resolution against `MacroAsteroidYield.category`, end-of-session writes the rolled resources back to PlayFab. Tracked here so the bridge in `Assets/Scripts/Macro/MacroMining*.cs` has an explicit "replace me" destination. Aaron's design for the per-rock mining scene (Phase 3 §3.C) is the input — wait for that before scoping.
- [ ] **4.3 Hardware Loadout Translation Pipeline:** Translate PlayFab loadouts into replicated Fusion entities with `Mass`, `Thrust`, `Capacitor` integers.
- [ ] **4.4 Flight & Combat Dynamics:** `F = MA` flight inside Fusion `[Networked]` state. Unity is "View" — interpolation, VFX, optical lasers. No gameplay logic on the view side.
- [ ] **4.7 Universal Speed Governor → battle-tier dispatch:** Generalize `SurfaceHyperDrive` (surface-only v1) into a scene-agnostic `SpeedGovernor` over an `IMovementSurface` (flat space / spherical planet). Hostile-only bubble drop + cooldown, camera zoom↔speed-mode coupling, base-zone slowdown. Battle tiers: Tier 1 PvE (no Fusion, CloudScript-resolved outcome), Tier 2 PvP (Fusion runner spawn + `FleetSnapshot` handoff), and the Tier 1→2 live promotion when a 2nd player enters the bubble. Canon: [`../combat/combat_speed_bubbles.md`](../combat/combat_speed_bubbles.md).
- [ ] **4.8 Orbital shield gate combat capture:** Capturing a `source = Static` `OrbitalShieldGate` by defeating its defenses flips `ownerId` to the victor (same attack pattern as `SurfaceBase`/`DefenseStation`). Canon: [`../world/world_orbital_shield_gates.md`](../world/world_orbital_shield_gates.md).

#### Phase 4 — Bridge code to remove
- `Assets/Scripts/Macro/Ground/SurfaceHyperDrive.cs` — `// BRIDGE: PvE outcome resolution` — Tier 1 PvE currently resolves locally; replace with CloudScript-authoritative resolution from `FleetSnapshot` vs NPC roster when Phase 4 lands. Surface-only governor lifts to the universal `SpeedGovernor` in 4.7.
- `Assets/Scripts/Macro/MacroCombatBridge.cs` — existing visual-only stub (`OnBattleJoinClicked` logs the future Fusion handoff). Replace with the Tier 2 Fusion runner spawn + `FleetSnapshot` per 4.7.
- `OrbitalShieldGate` capture flip — bridged (admin/dev) until 4.8 combat resolution lands. Tracked in [`../world/world_orbital_shield_gates.md`](../world/world_orbital_shield_gates.md).
- `Assets/Editor/CoplayFlightShell.cs` (`Low Orbit Flight Shell (DEV)` + `Smuggler Frigate (TEST)`) — scene-authored flight-layer scaffolding; the flight shell becomes code/registry-driven and the ship spawns from the fleet path. Remove when the low-orbit flight layer ships.

---

## Phase 4.5 — Server-Authority Hardening (Combat Layer)
**Goal:** A modded client can't cheat damage, capacitor, or shield state. All authoritative writes are gated; non-authority clients only render.

*Added 2026-04-29 — flagged while wiring capacitor / shield / shutdown systems. None are blockers for solo or host-authoritative tests, but all are correctness-critical for true MMO play.*

- [ ] **4.5.1 Convert `TacticalHitbox` to `NetworkBehaviour`:** Currently a plain `MonoBehaviour`; `currentHealth` and `structuralIntegrity` are per-client `public float`s with no synchronization. Promote to a Fusion `NetworkBehaviour`, decorate both with `[Networked]`, route `OnModuleDestroyed` through Fusion's event/RPC system.
- [ ] **4.5.2 RPC-driven damage application:** `TacticalHitbox.ApplyPrecisionDamage` is invoked client-locally by `TacticalProjectile` and `TacticalExplosiveCargo` on collision. Replace with a server RPC: projectile reports the hit, authority resolves shield → armor → hull and broadcasts.
- [ ] **4.5.3 Audit `[Networked]` writes for authority gates:** `currentCapacitor`, `currentShield`, `currentArmor` writes are gated on `HasStateAuthority`. Sweep the rest of `Tactical/` for any other write paths (shield collapse latching, power-out cooldown, recharge state) and confirm authority-only.
- [ ] **4.5.4 Capacitor / power-out validation:** The `currentCapacitor < drainPerShot` check and `< 7%` shutdown trip must run only on authority's view of the synchronized value.
- [ ] **4.5.5 Remove client-side guesses from non-authority damage path:** Once 4.5.2 lands, the workaround that lets non-authority clients consume damage budget locally for visual sync can be removed.

---

## Phase 4.6 — Fog of War (Combat Vision)
**Goal:** Each fleet's visibility is a server-authoritative union of its members' sensor coverage. Modded clients can't wallhack.

*Added 2026-05-01 — initial FOW pass landed (`TacticalSensorResolver`, `SensorSchema.scanArcDegrees`, missile fire-controller gate, mid-flight Smart→Dumb downgrade, player-FOW ring). Canon: [`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md).*

- [ ] **4.6.1 Author `SensorSchema` assets** under `Resources/Schemas/Sensors/`. At least one Turret-class omni (long range, `scanArcDegrees = 360`) and one Internal-class directional (e.g. 90°) per the mount-class table.
- [ ] **4.6.2 `TacticalFleetVision` server-authoritative aggregator:** Fusion `NetworkBehaviour` that unions every fleet member's `CoverageVolumes` and pushes a `[Networked]` snapshot. Cap at `MAX_FLEET_VISION_SOURCES = 32`. Blocked on `fleet_id` data source decision (open thread in the FOW doc).
- [ ] **4.6.3 Server-side transform filtering (wallhack mitigation):** Gate Fusion's per-tick serialization so ships outside the viewer fleet's FOW union are filtered before the snapshot reaches the client.
- [ ] **4.6.4 `TacticalSpectatorVision` client subsystem:** Spectator clients subscribe to every faction's `TacticalFleetVision` stream and union locally. Drives expanded ship rendering + per-faction-color FOW overlay set. Depends on 4.6.2.
- [ ] **4.6.5 Jammer system (`EWarfareSchema` + integration):** Define how a jammer module reduces enemy `EffectiveSensorRadius` and how `eccmStrength` resists. Hook into `TacticalSensorResolver.EnsureFresh`.
- [ ] **4.6.6 Silicate Nebula volumes + 0.5x range multiplier:** Author per-sector nebula bounds; resolver applies the multiplier to volumes whose source sensor doesn't pierce. Tunable: `NEBULA_PENALTY = 0.5f`.

---

## Phase 5 — Economy & MMO Scaling
**Goal:** Hub pricing reacts to stock levels, taxes route correctly, alliances can form and trade with diplomatic multipliers, wrecks can be towed.

- [ ] **5.1 Hub Pricing Model Server-Scripts:** PlayFab CloudScripts modulate prices via `CurrentStock / TargetStock` scarcity.
- [ ] **5.2 Economy Taxes:** Math functions enforcing the universal **3% Escrow** and the **35% FED Federation Tax**.
- [ ] **5.3 Alliance Registration & Org System:** Allow alliance formation and faction-to-faction diplomatic multipliers (e.g. 100% markup to enemies). Per [`../social/social_alliance_guild.md`](../social/social_alliance_guild.md), implement:
  - **Uncapped membership** — alliance roster is a single PlayFab record up to ~500 members; **roster sharding** kicks in above that (split across squadron-named child documents with a server-side aggregator on read).
  - **Eight-rank ladder** with per-rank default permission sets and a `customPermissions` per-member override map. Authoritative gate on every alliance action lives in CloudScript.
  - **Director departments** — `Military` / `Industrial` / `Diplomatic` / `Treasury` / `Recruitment`; permissions branch on `directorDepartment`.
  - **Squadrons** — first-class subdivisions with their own roster slice, sub-vault, citadel access list, chat channel, and tag. Squadron CRUD requires Director-tier authority.
  - **Two-tier vault** — main alliance vault + per-squadron sub-vaults. Withdrawal authority and daily caps gated by rank + department.
  - **Audit log** — every promote / demote / vault withdrawal / wardec writes to an alliance audit log. Retention placeholder: 90 days. Read access: Officer+.
- [ ] **5.4 The Golden Towing Sequence:** Drag wrecks, speed penalties (physics drag), forensic deconstruction. Per [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md) §4 the loot model is:
  - **Intact stolen modules** — pulled into the looter's inventory; fittable, repairable, sellable. *Cannot* be manufactured into duplicates — manufacturing requires the Matrix Scanner research path keyed to the Researcher's Seed.
  - **Repair Recipes ("Golden Logic")** — rolled per-module on Deep Decon (1% Sector Hub, 2% Citadel). Documents *maintenance ratios* for refurbishment, not manufacturing. Lives in the player's personal Library; alliance-shared Library is gated by the rank matrix in [`../social/social_alliance_guild.md`](../social/social_alliance_guild.md).
  - **Field Strip** — scrap/ore only; no modules, no recipes.
  - Modules destroyed in the fight (sub-entity-targeted to oblivion) are lost — both the intact loot and the recipe roll. Implements the Scavenger's Dilemma in [`../combat/combat_mechanics.md`](../combat/combat_mechanics.md) §9.

---

## Phase 5.5 — Sector & Planet Control Doctrine
**Goal:** Alliances can claim factions, control sectors, contest planets. POIs have code-level meaning, not just decoration.

*Added 2026-05-04 — captured while seeding faction-controlled systems (Concordia/FED, Ferrum/ICE) with their POIs and Planetary Defense platforms in the SolarSystem map.*

- [ ] **5.5.1 Sector control = 100% POI ownership:** An alliance only "controls" a sector once it owns **every** POI (jump gates, stations, stat cons, shipyards, trading hubs, military outposts). Partial ownership grants nothing. PlayFab CloudScript evaluates atomically — flipping any single POI flips control.
- [ ] **5.5.2 Planet entry requires defeating all Planetary Defense systems:** Each faction-controlled planet hosts ≥ 2 `Planetary Defense` POI platforms on a tight inner orbit. Entering PlanetView on a hostile planet requires destroying every platform first. Defenses respawn on a long timer (placeholder 6h). Gate `SolarSystemZoomController.EnterPlanetView` on a server-side `PlanetaryDefenseStatus` check.
- [ ] **5.5.3 Authoring contract:** Every faction-controlled planet must carry ≥ 2 POIs named `Planetary Defense` (`DefenseAlpha` / `DefenseBeta`, extend with Greek letters) on a `~50 unit` inner orbit. Wired via `BuildPoi` in `Assets/Editor/SolarSystemOneShotFix.cs` — see Concordia/Ferrum builders. Neutral / outlaw planets are exempt.
- [ ] **5.5.4 Planetary Defense — defeatable structures:** Promote `Planetary Defense` POIs from passive markers to **destructible structures**. Each platform has `currentHP`, `maxHP`, `factionOwner`, `OnDefeated()`. Wire into `TacticalHitbox` / `ApplyPrecisionDamage`. Authoritative HP lives PlayFab-side (lazy-eval); Fusion combat instances pull a snapshot at start, report deltas at end. Defeated platforms swap to wreck mesh and stop orbiting. Required reading: [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) §4.2.
- [ ] **5.5.5 Alliance faction-claim system (50+ member gate, defense + tax):** Per [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) §4.1.
  - **Eligibility gate:** alliance must have ≥ 50 active members at claim.
  - **Claim payload:** alliance writes `claimedFaction = "FED" | "ICE"` + `claimedAt` + `cooldownExpires` to its PlayFab alliance record.
  - **Defense response:** when alliance assets are attacked in faction-controlled space, the faction's NPC fleets (FED Police / ICE Garrison — see [`../world/world_npc_ai.md`](../world/world_npc_ai.md) §1, §1A) spawn scaled to threat.
  - **Tax obligation:** auto-route 35% of trade-hub revenue (FED) or industrial cut (ICE) to the faction treasury on top of internal alliance cuts. Hook into Phase 5.1/5.2 hub-pricing pipeline.
  - **Betrayal cost:** dropping the claim before cooldown expires triggers a sharp standing crash and a temporary system-wide bounty on alliance leadership.
  - **Mutual exclusion:** one faction claim per alliance at a time.
- [ ] **5.5.6 Faction defeat → AI base respawn elsewhere:** When a hostile alliance fully captures a faction homeworld (every Planetary Defense defeated per 5.5.4 + every system POI captured per 5.5.1), the defeated faction does *not* vanish. Per [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) §4.3:
  - Spawn new NPC bases (recovery citadels, exile shipyards, mobile command stations) in **other Helion regions**, weighted away from the captured system. Use a curated `FactionRespawnCandidates` table.
  - Re-anchor FED Police / ICE Garrison to the new bases. Sectors covered shrink to a radius around the new bases.
  - Alliances claiming the defeated faction lose defense + tax routing for the captured region until the faction reclaims a planetary holding.
  - Reclaim sorties spawn from the new bases on a doctrine cadence (placeholder 24–72h). Successful sorties flip a sector POI back to faction control.
  - This guarantees the faction war loop is **permanent** — no alliance can permanently delete FED or ICE.
- [ ] **5.5.7 Planet-level alliance ownership (50% rule + tag swap):** Per [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) §4.4. Schemas + helpers landed in `Assets/Scripts/Schemas/PlanetControlSchema.cs`, `PlanetControlState.cs`, `Assets/Scripts/Macro/PlanetControlEvaluator.cs` / `PlanetControlBinder.cs`.
  - **Author the schema asset:** `Assets/GameData/PlanetControl/PlanetControlSchema.asset` with entries for Concordia (FED baseline, claimable), Ferrum (ICE baseline), Discordia (neutral, claimable), Pax / Bellum, etc.
  - **Attach `PlanetControlBinder` to each planet GameObject** in `SolarSystemOneShotFix` so the binder swaps tags when a fresh state lands.
  - **Census collector (CloudScript):** lazy-eval job walking `PlayerSectorPresence` records, tallying alliance counts per planet, writing to `PlanetControlState`.
  - **Authoritative evaluator (CloudScript):** mirrors `PlanetControlEvaluator.ResolveCandidate`. Enforces `controlAcquireGraceSeconds` / `controlLoseGraceSeconds`. Writes `controllingAllianceId/Tag/Color`, snapshots `grandfatheredResidentIds`.
  - **Client pull-down:** PlayFab title-data fetch on scene load + push-via-WebSocket on flip. Feed each binder via `SetState()`.
- [ ] **5.5.8 Planet residency / access gate:** Per [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) §4.4 and `Assets/Scripts/Macro/PlanetAccessChecker.cs`.
  - **Server gate:** `LandOnPlanet` / `DockAtPlanet` CloudScript runs the same logic as `PlanetAccessChecker.Resolve`.
  - **Officer grant UI:** alliance UI panel listing pending requests + approve/deny that writes `grantedResidentIds` via CloudScript.
  - **Client preview:** call `PlanetAccessChecker.Resolve` on macro before sending the land call so "Land" can pre-disable; never trust this for the actual gate.
  - **Grandfather snapshot:** at the moment `controllingAllianceId` flips, CloudScript snapshots all currently-present player ids. Cleared on next flip.
- [ ] **5.5.9 Non-member planetary tax (controlling-alliance toll):** Per [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) §4.5 and `PlanetControlState.nonMemberTaxFraction`.
  - **Officer-set rate:** UI slider clamped to `[0, PlanetControlSchema.maxNonMemberTaxFraction]` (default ceiling 25%); CloudScript re-clamps server-side.
  - **Transaction hook:** every economic CloudScript touching a planet's services (trade, dock, repair, refuel, station-services) checks `controllingAllianceId` and charges the toll on top of FED/ICE tax. Receipt line shows toll explicitly.
  - **Treasury routing:** toll revenue lands in the controlling alliance's treasury record (separate ledger entry from internal dues).
  - **Public visibility:** rate exposed on the planet's info card.
  - **Stacks with faction tax:** alliance toll is **additive** to FED (35%) / ICE (industrial) tax.

---

## Phase 6.0 — Celestial Architecture (Parents, Children, Time-Anchored Positions)
**Goal:** Every body is a deterministic function of `(now − epoch)` so all clients agree on world position to the second. Every POI lives in PlayFab so alliance construction reflects on every player's map.

*Added 2026-05-04. Multi-phase overhaul replacing the per-frame `MacroOrbiter` model. Plan canon: `~/.claude/plans/in-the-solar-system-moonlit-simon.md`. Build philosophy: [`../../CLAUDE.md`](../../CLAUDE.md) "Building durably — no throwaway code."*

- [x] **6.0.A — Time-anchored evaluator:** `CelestialClock`, `CelestialPositionEvaluator`, `CelestialOrbiter`, `CelestialEpochFetcher`, `MacroOrbiterMigrator`. Migrates `MacroOrbiter` components in `SolarSystem.unity` to `CelestialOrbiter` with Glacies anchored to 86,400s + Kepler scaling. Two clients now sync to the second.
- [ ] **6.0.B — Registry schemas + seed importer:** `CelestialRegistry`, `CelestialParentRecord`, `CelestialChildRecord` JSON schemas + `CelestialRegistrySeeder` editor menu pushing the dataset to PlayFab title-data key `"CelestialRegistry"`. `CelestialRegistryClient` for client fetch + cache + change notification.
- [ ] **6.0.C — Scene built from registry:** `CelestialSpawner` instantiates parents + children at scene load from the registry (Addressables prefab loads). Strip parent/child authoring from `SolarSystemOneShotFix`; keep only visual setup (sun, lights, skybox).
- [ ] **6.0.D — Big centered planet name:** `CelestialParentLabel` watermark component (~30-36px, semi-transparent, centered, ZTest=Always) replaces the parent path of `SolarSystemBodyLabel`. POI labels fade when overlapping a parent label.
- [ ] **6.0.E — Sector map sync:** Sector director reads host parent's id from `SectorSchema`, evaluates position via the same `CelestialClock` + `CelestialPositionEvaluator` the solar map uses. Sector internal layout stays scene-authored; only the parent anchor moves.
- [ ] **6.0.F — Game docs update (rides alongside each phase):** [`../architecture/architecture_plan.md`](../architecture/architecture_plan.md) (Celestial Layer section), [`../architecture/architecture_backend_network.md`](../architecture/architecture_backend_network.md) (registry schema + CloudScript handlers), [`../world/world_sector_rules.md`](../world/world_sector_rules.md) (Sector ↔ Celestial sync subsection), [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) (POI infrastructure note), [`../00_Master_Design_Overview.md`](../00_Master_Design_Overview.md), [`../../CLAUDE.md`](../../CLAUDE.md).
- [ ] **6.0.G — Alliance-built POI authoring:** CloudScript handlers `AllianceConstructPOI` / `AllianceDemolishPOI` with control-gate validation. Client live-updates via `CelestialRegistryClient.OnRegistryUpdated`.

### Phase 6.0 — PlayFab production sync (closes the bridges)
*The Celestial layer's local fallbacks all gate on these tasks. Until they ship, every client runs on the local fallback and "PlayFab as source of truth" is design intent rather than working reality.*

- [ ] **6.0.SYNC.1 — Seed `CelestialEpoch` in PlayFab GameManager.** Open Title → Title Data → add key `CelestialEpoch`, value `2026-01-01T00:00:00Z` (or whatever world-launch instant we lock in). Once set, `CelestialEpochFetcher` resolves to the real value on every client; the `LocalFallbackEpoch` becomes unreachable. **Verification:** `CelestialEpochFetcher` log shows `"Helion epoch set to ... from PlayFab title data."` instead of `"PlayFab title-data key 'CelestialEpoch' is unset. Using local fallback."`
- [ ] **6.0.SYNC.2 — Seed `CelestialRegistry` in PlayFab GameManager.** Paste the contents of `Assets/GameData/Celestial/seed.json` into a Title Data key called `CelestialRegistry`. Once set, every client pulls the canonical dataset on login; the `Resources/CelestialSeed.json` fallback becomes unreachable for normal flow. **Verification:** `CelestialRegistryClient` log shows `"Registry applied from PlayFab title data: ..."` instead of `"... Using local seed fallback."`
- [ ] **6.0.SYNC.3 — Editor menu "Push Registry to PlayFab".** Add an Apex Outlaw → Celestial menu item that uses `PlayFabAdminAPI.SetTitleData` to push the current `seed.json` to the production title. Eliminates manual paste; lets the seeder + push fire as one editor command after each scene update.
- [ ] **6.0.SYNC.4 — Deploy CloudScript revision.** Upload `cloudscript/celestial_alliance_pois.js` to PlayFab GameManager → Settings → Cloud Script → Revisions. Required before `CelestialPOIConstruction.RequestConstruct/Demolish` can do anything but log a "function not found" error. See `cloudscript/README.md` for the manual workflow.
- [ ] **6.0.SYNC.5 — End-to-end verification.** From two logged-in editor instances on different machines: confirm Ferrum sits at the same XZ at the same wall-clock instant. Confirm an alliance officer's Stat Con construction call lands on the second client's map within the next registry-fetch tick. This is the test that proves the celestial overhaul is live, not just in code.

### Phase 6.0 — Schema unification: faction = AI alliance
*Canon (per `../world/world_faction_sovereignty.md` §3 header note, 2026-05-04): a faction IS an alliance, just driven by AI instead of player officers. Every ownership concept in code should be a single `ownerId` string. FED and ICE become reserved AI-controlled alliance ids. Player alliance ids are alliance UUIDs. The current schema's split `factionId` / `allianceId` fields are a bug we're paying interest on every time we add an ownership-aware feature.*

- [ ] **6.0.SCHEMA.1 — Replace split fields with `ownerId` across the celestial layer:**
  - `CelestialParentRecord.baselineFactionId` → `baselineOwnerId` (string, holds `"FED"` / `"ICE"` / alliance UUID / empty for unowned).
  - `CelestialParentRecord.baselineFactionColor` → `baselineOwnerColor` (cosmetic; admin-set per-alliance, hardcoded for the AI alliances FED/ICE).
  - `CelestialChildRecord.ownerAllianceId` → `ownerId` (same semantics).
  - `CelestialChildRecord.jumpGateFactionId` → drop entirely; the gate inherits its owner from the host parent's resolved owner.
  - `PlanetControlState.controllingAllianceId` → `controllingOwnerId`.
  - `PlanetControlState.controllingAllianceTag/Color` → `controllingOwnerTag/Color`.
- [ ] **6.0.SCHEMA.2 — Display layer cleanup:** `PlanetControlBinder`, `CelestialParentLabel`, `SolarSystemBodyLabel`, `CelestialSpawner`, `CelestialChildBuilder` — every `factionTag` / `factionColor` field becomes `ownerTag` / `ownerColor`. Inline rich-text `[FED]` / `[ICE]` / `[ALLIANCE-XYZ]` rendering is uniform.
- [ ] **6.0.SCHEMA.3 — `OwnerRegistry` schema** (new): catalog of known owner ids → display name + color. Seeded with FED (blue) + ICE (iron-red) + Outlaws (gray) at world launch. Player alliances append entries via CloudScript when they form. The label layer reads color from this registry instead of carrying it inline on every record.
- [ ] **6.0.SCHEMA.4 — CloudScript handler updates:** `cloudscript/celestial_alliance_pois.js` gates already check `controllingAllianceId == callerAllianceId`. Update to `controllingOwnerId == callerOwnerId` and add the AI-faction handlers (`AIFactionConstructPOI`, `AIFactionAbandonPOI`) with the same shape — those run from a server-side AI loop (Phase 5.5 sovereignty engine), not from a player call.
- [ ] **6.0.SCHEMA.5 — Migration script:** Editor tool that fetches the live PlayFab registry, transforms old field names → new, validates, pushes back. One-shot, deletable after the production push.

### Phase 6.0 — Bridge code to remove
*Per [`../../CLAUDE.md`](../../CLAUDE.md) "Building durably — no throwaway code", every temporary scaffold introduced by the celestial work is tracked here for explicit removal.*

- [ ] **`CelestialClock.LocalFallbackEpoch`** (`Assets/Scripts/Macro/Celestial/CelestialClock.cs`) — hardcoded `2026-01-01T00:00:00Z` fallback. **Remove when** PlayFab title-data key `"CelestialEpoch"` is reliably written for every environment.
- [ ] **`CelestialRegistry` local seed.json fallback** (`Assets/Resources/CelestialSeed.json`, loaded by `CelestialRegistryClient`). **Remove when** PlayFab title-data `"CelestialRegistry"` is reliably written for every environment AND a deploy pipeline pushes new revisions automatically.
- [x] **`MacroOrbiter` legacy fallback in `JumpGateNetwork.PredictWorldPosition`** — *removed in cleanup pass after 6.0.G.* Every SolarSystem-scene gate now runs on `CelestialOrbiter` post-migration; the fallback was dead code. `JumpGateNetwork.PredictWorldPosition` returns `t.position` for the unreachable "no orbiter" case.
- [ ] **`SectorAuthoring.BuildChainGates` + `BuildSatellites` edit-time scene baking** (`Assets/Editor/SectorAuthoring.cs`) — chain-pair gate authoring + hand-listed satellite spawning kept as a fallback while the runtime `SectorRuntimeSpawner` rolls out. The runtime spawner clears any baked `JumpGate_*` GameObjects on enable, so the bake is harmless when the spawner runs. **Remove when** every sector body has a registry parent record AND the `SectorChainRegistry` asset is no longer the source of truth for sector-side gate destinations. See `// BRIDGE` comment in `SectorAuthoring.BuildSectorScene`.
- [ ] **Sector gate live destination resolution** — `MacroJumpGate.destinationSectorId` is currently empty for runtime-spawned gates (the `SectorRuntimeSpawner` sets only the visual + position + faction tag from the registry). The chain-baked gates from `BuildChainGates` still set it as a fallback. **Remove when** `JumpGateNetwork`'s bubble-overlap connectivity logic is generalized to resolve sector-side jump destinations live (gate's bubble overlaps gate B's bubble → fleet jumps to body B's sector). Until then, a runtime-spawned gate without a baked sibling reads as "closed" via `MacroJumpGateBroadcastVisual` (gray, no pulse) — correct behavior, just not connectable yet. See `// BRIDGE` comment in `SectorRuntimeSpawner.EnsureGate`.
- [ ] **Sector moon position scene-bake** — `SectorAuthoring.BuildSatellites` still spawns moons from the hand-authored `SectorBodyDefinition.satellites` list. `SectorRuntimeSpawner.SyncMoonOrbits` pushes registry orbital params onto matching scene moons each frame, but the moon GameObjects themselves are still scene-baked. **Remove when** the runtime spawner is extended to spawn moon GameObjects from registry parent records (loading the visual prefab via Addressables) and `SectorBodyDefinition.satellites` becomes empty / ignored.
- [ ] **Sector scene overwrite guard relaxed** (`Assets/Editor/SectorAuthoring.cs:BuildSectorScene`) — the early-return `if (File.Exists(scenePath)) return;` was relaxed during fleet-visual / sector-map iteration so `Build/Sector/<body> (from body asset)` always overwrites without confirmation. Logs a warning instead. **Re-add the guard** before production ship so accidental rebuilds can't destroy hand-tuned authoring; the existing `Build/Sector/Force Rebuild From Active Scene Body` menu already provides the explicit force path. See `// BRIDGE` comment in `BuildSectorScene`.
- [ ] **Local-only fleet composition mutations** (`Assets/Scripts/Macro/FleetCompositionService.cs`, `Assets/Scripts/Macro/PendingFleetTransfer.cs`, `Assets/Scripts/Macro/RuntimeFleetSpawner.cs`). Drag-and-drop merge / split in the bottom-bar slot cards mutates `MacroFleet.ships` on the client without server validation — every transfer or split is committed locally, the on-map convergence is purely client-driven. **Remove when** PlayFab CloudScript handlers `PlayerTransferShip(sourceFleetId, shipIndex, targetFleetId)` and `PlayerSplitFleet(fleetId, shipIndex, spawnHint)` land + the client routes through them. Every mutation site is flagged with `// BRIDGE: remove when fleet-composition CloudScript handler lands`.
- [ ] **Fleet max size scales with base.** `FleetCompositionService.MAX_FLEET_MASS` is currently a flat `2000f` constant — drag-merges that would push a fleet above this cap are refused. Per design, the cap should be **derived from the player's home-base capacity / upgrade level** (a starter base allows a small fleet; upgraded bases unlock higher caps). **Remove when** the home-base data model exposes a per-player `MaxFleetMass` field (PlayFab user data), and the service reads it instead of the constant. Until then, every player has the same hard ceiling regardless of base.

### Phase 6 — UI / Theme (player-driven theme palette + global menu hub)

The reusable UI shell is built. Three components form the framework that every future menu plugs into:

- **`ThemePalette`** (`Assets/Scripts/UI/Theme/ThemePalette.cs`) — static palette (accent, foreground, background, font, `WindowSprite`) with a `Changed` event.
- **`ThemedMenu`** (`Assets/Scripts/UI/Theme/ThemedMenu.cs`) — reusable framed-panel chrome with a `[icon] TITLE [X]` header, color-line section dividers, and `AddSection(name)` API. Re-tints on `ThemePalette.Changed`.
- **`MenuHub`** + **`SceneMenuRegistry`** (`Assets/Scripts/UI/Theme/MenuHub.cs`, `SceneMenuRegistry.cs`) — global persistent (DontDestroyOnLoad) bottom-right chip stack; per-scene manifests declare which menus drop in when each scene loads. Chips animate in from above and slide out cleanly when their scene unloads.

First consumer: the SolarSystem map's Jump Gates menu. Future scenes add menus by creating a `ThemedMenu` GameObject in the scene + listing it on the scene's `SceneMenuRegistry`.

- [ ] **`GlobalNavHub` stub section panels** (`Assets/Scripts/UI/GlobalNavHub.cs`, added 2026-06-09) — the persistent nav chips (Command Deck, Shipyard, Inventory, Alchemy Lab, Market, Alliance, Social) ship with placeholder "Planned" rows listing each section's contents per [`../social/social_menus_ui.md`](../social/social_menus_ui.md) §2. Working today: Shipyard scene launch, live Inventory listing from `ActiveProfile`, Command Deck name/credits. **Remove each stub when** its real panel lands (Alchemy Lab → Phase 3+, Market → Phase 5, Alliance/Social → later phases). Flagged with `// BRIDGE` in `BuildStubRows`. NOTE: if [`../architecture/architecture_ui_framework.md`](../architecture/architecture_ui_framework.md) is approved, these chips migrate to `GameMenuBase`/`MenuRegistry` entries rather than growing further on ThemedMenu.

- [ ] **Player theme system.** Replace the hardcoded defaults in `ThemePalette.cs` (`_accent` teal, `_foreground`, `_background`) with a per-player `ThemeAsset` selected from a settings UI. The palette + ThemedMenu + MenuHub already retint on `ThemePalette.Changed` — what's missing is:
  - A `ThemeAsset` ScriptableObject (color set + WindowSprite + font) authored per theme.
  - A theme picker UI that calls `ThemePalette.Seed(...)` with the selected asset.
  - Persistence: store the player's theme choice in PlayFab user data (`SelectedThemeId`); load it at boot before any menu builds.
  - **Faction-driven default palette.** Each player's accent color defaults to their faction theme: FED → cyan, ICE → red, Outlaw → blue. The settings UI lets the player override; when unset, the boot path reads the player's faction tag and seeds `ThemePalette.SetAccent(...)` accordingly. This affects every themed surface — menu chrome, hub chips, switch knobs, and the in-world Gate Range disc fill (`JumpGateNetworkVisualizer.bubbleColor`).

#### Phase 6 — UI/Theme bridges to remove

- [ ] **`ThemePaletteBootstrap`** (`Assets/Scripts/UI/Theme/ThemePaletteBootstrap.cs`) — per-scene seeder that pushes editor-wired sprite/font refs into the static palette. **Remove when** the boot sequence loads the palette from a `ThemeAsset` selected via PlayFab user data.
- [ ] **Hardcoded color defaults at the top of `ThemePalette.cs`** (`_accent = teal`, etc.) — kept so menus look right before the player picks a theme. **Remove when** the boot path always seeds from a `ThemeAsset`.
- [ ] **`SolarSystemFactionToggles`** (`Assets/Scripts/UI/SolarSystemFactionToggles.cs`) — vestigial stub kept only so the existing scene asset doesn't deserialize as a missing-script. **Remove when** every reference to its `network` / `filterPanel` / `mainButtonPrefab` fields has been migrated and the scene no longer needs the component for ref-holding.

### Not bridges — kept by design (corrected from earlier flagging)

The following were initially flagged as bridge code but have legitimate non-celestial users. They stay in the codebase indefinitely, **NOT** for removal:

- **`MacroOrbiter.cs`** — sector authoring (`SectorAuthoring.cs`, `MacroAsteroidBelt.cs`, `MacroSectorDirector.cs`, `PlanetaryDefenseStructure.cs`) creates and consumes `MacroOrbiter` for sector-scoped bodies that are independent of the global `CelestialClock`. Sector orbiters spin per-frame via `Time.deltaTime` — that's the right model for sector-internal content (asteroid drift, gate orbits within a single sector instance). Only the SolarSystem-map's parent/child tree needs clock-anchored sync.
- **`SolarSystemTimeScale.Multiplier`** + `ScaledDeltaTime` static getters — `MacroOrbiter` reads `Multiplier` for sector-side time scaling. Now repurposed as a designer fast-forward shim that pushes the offset into `CelestialClock.DesignerOffsetSeconds` *and* multiplies sector-scoped per-frame motion. Stays.

---

## Phase 6.7 — Helion Unified World & Mesh-Network FOW
**Goal:** A new `Helion.unity` scene becomes the unified macro play space — the entire solar system rendered as one continuous world so fleets can travel between planets in open space (slow, dodging hostiles), not just through gates. Alliance vision becomes a **mesh network**: friendly fleets only share FOW when within each other's `syncRadius`. Lone scouts go blind; stations act as super-hubs.

*Added 2026-05-09. Coexists with `SolarSystem.unity` (strategic overlay) and existing sector scenes (`ignis.unity` etc.) — those are explicitly preserved untouched. Helion is a parallel implementation, not a migration. Plan: `~/.claude/plans/okay-question-look-at-snug-floyd.md`.*

### 6.7.A — Schema foundations (✅ landed)
- [x] Add `syncRadius` curve to `SensorSchema.cs` (per-grade anchor curve, 8000–26000 baseline).
- [x] Add `syncRadius` field + `RecomputeSectorSync()` stub to `MacroFleet.cs`.
- [x] Add `SyncRadius()` accessor (tier-scaled) to `MacroBaseRecord.cs`.

### 6.7.B — Mesh FOW logic (✅ landed)
- [x] `MacroSyncMesh.cs` — friendly proximity graph + union-find clustering, `OnPlayerSyncStateChanged` event.
- [x] `MacroPartyService.cs` — in-memory party trust group stub.
- [x] Refactor `MacroFOWUnion` to consume cluster + party-mate personals (instead of "all friendly fleets globally").

### 6.7.C — Helion scene + 3-tier camera
**C# done; scene authoring is a manual editor task — see [`../architecture/architecture_helion_scene_checklist.md`](../architecture/architecture_helion_scene_checklist.md).**
- [x] New Helion-only camera + view-mode controllers in `Assets/Scripts/Macro/Helion/` (legacy `MacroCameraController` / `MacroViewModeController` left untouched for SolarSystem.unity / ignis.unity).
- [x] `HelionZoomTier` enum (Fleet / PlanetSystem / SolarSystem).
- [x] `HelionViewModeController` — M cycles tiers; PlanetSystem skipped when not within `nearPlanetRange` of any registered planet; Esc collapses to Fleet.
- [x] `HelionCameraController` — discrete tier bands; mouse-wheel zoom only within active tier; Tier 2 = absolute hard cap.
- [ ] Hand-author `Assets/Scenes/Maps/Helion.unity` per the checklist.
- [ ] **Phase 6.7.C.2 contingency:** if Helion world extent exceeds float32-safe range (~10⁵ units) once celestials spawn, add floating-origin recenter system.

### 6.7.D — Visualization + notifications (✅ landed)
- [x] `NotificationManager.cs` — self-installing toast UI, TTL + auto-dismiss predicate.
- [x] `MacroSyncVisualizer.cs` — sync ring + cluster edge lines, hooks `OnPlayerSyncStateChanged` → "Sync lost" / "Sync regained" toasts.

### 6.7.E — Server-FOW (deferred, anti-cheat) + logout persistence
- [ ] CloudScript AoI grid: bucket Helion into spatial cells, fleets light cells within sync/sensor radius.
- [ ] Per-alliance lit-cell union precomputed once per tick; per-player payload = (alliance union) ∪ (party union) ∪ (own).
- [ ] CloudScript handler `GetVisibleEntities(playerId)` returning filtered fleet/POI list.
- [ ] Refactor client fleet sync to consume filtered payloads + delta updates (entered/left).
- [ ] Server-FOW radius = client-FOW radius × 1.1 (tunable buffer to prevent edge popping).
- [ ] **Cost guardrails:** event-driven cluster recompute (fires on cell crossing, not per tick); idle-fleet skip; delta payloads only; logged-in-player gating (logged-out players ship no payloads until login).
- [ ] **Logout persistence (auto-travel-to-safety):** On logout, fleet auto-travels to nearest safe spot in this priority: (1) player's home station, (2) nearest alliance/coalition-owned station, (3) nearest faction-controlled station the player has clearance at, (4) fallback: stays at logout position, fully vulnerable. In transit the fleet is visible on FOW unions and a valid combat target — this is the *fleeing-fleet hunt* gameplay window. Once docked, removed from active AoI iteration (static cell, zero per-tick CPU). Combat-against-in-transit-fleet wakes a CloudScript handler; player gets attack/loss notification on next login. **Anti-exploit invariant:** auto-travel uses the normal macro flight model at normal cruise speed — NEVER teleport, fast-travel, or safe-corridor. The return trip must remain a real cost (danger, time, exposure) so deep-space resource runs can't be cheesed by logging out at the destination. See `~/.claude/projects/C--Users-Aaron-Apex-Outlaw-Apex-Outlaw-Client/memory/project_logout_persistence.md`.

### 6.7.F — Planet scenes + per-planet player rosters — SUPERSEDED by 6.9.A-H
**Goal (original):** Each planet has its own `.unity` scene with a Vega-Conflict-style 2D rotating near-orbit view.

**STATUS: Superseded 2026-05-29** by the three-scene world architecture (see plan at `~/.claude/plans/if-i-was-going-mutable-parnas.md` and [`world_low_orbit_scene.md`](../world/world_low_orbit_scene.md) + [`world_surface_scene.md`](../world/world_surface_scene.md)). The 2D rotating planet view is **retired**. Replacements:
- The "planet scene" concept splits into **Low Orbit (Scene 2)** and **Surface (Scene 3)**, both rendered with 3D Planet Forge planets.
- The `PlanetPlayerRoster` schema is **kept** (still useful for "who's at this body" lookups). Renamed conceptually to "body presence channel" but the data shape is unchanged.
- `Planet_avernus.unity` and `Planet_praedo.unity` will be deleted in Phase 6.9.H (legacy retirement).
- The `PlanetAvernusSceneBuilder.cs`, `PlanetSurfaceViewController.cs`, `PlanetFleetLongitudePinner.cs`, and `PlanetSurfaceBaseSpawner.cs` are all retired in 6.9.H.

The active doc track is now Phase 6.9.A through 6.9.H (three-scene architecture rollout) — see below.

- [x] `PlanetPlayerRoster` schema (`Assets/Scripts/Schemas/PlanetPlayerRoster.cs`) — KEPT (still used as body-presence channel).
- [ ] `PlanetPlayerRosterClient` — fetch/cache per-planet rosters from PlayFab Title Data key `Planet_<bodyId>_PlayerRoster`. Mirror `CelestialRegistryClient` boot-fetch + seed.json fallback pattern. — KEPT.
- [ ] CloudScript handlers: `DockAtPlanet(playerId, bodyId)` and `UndockFromPlanet(playerId, bodyId)`. Now writes into the body-presence channel used by Scene 2/3.
- [~] Helion click-on-planet HUD popup — REPLACED. Solar (Scene 1) click → scene swap to Scene 2 (Low Orbit) via `SceneManager.LoadScene`.
- [~] Author Planet_avernus.unity Vega-Conflict-style — RETIRED. Replaced by Scene 2/3 unified templates loaded with a per-body handoff.
- [~] Wire launch flow planet scene → Helion — REPLACED. Solar (Scene 1) ↔ Low Orbit (Scene 2) scene swaps; Low Orbit → Surface (Scene 3) is permit-gated.
- [~] Roll out per-planet scenes — REPLACED. One template scene each for Scenes 2 and 3; per-planet content is data-driven from the registry.

### 6.9.A → 6.9.H — Three-scene architecture rollout (NEW PRIMARY TRACK)
**Goal:** Ship the three-scene world model (Solar / Low Orbit / Surface) replacing the deprecated 2D planet entry scene. Full plan at `~/.claude/plans/if-i-was-going-mutable-parnas.md`.

- [ ] **6.9.A — Surface scene template** (`Assets/Scenes/Surface.unity`). Loader, 3D surface-base placement at (lat, lon), activity-noise visibility. Single-planet test (Avernus). No Fusion yet. Canon: [`../world/world_surface_scene.md`](../world/world_surface_scene.md).
  - [ ] **6.9.A.tile — 4 m grid surface tile pipeline** (parallel to free-place base parts; in-flight in `PlanetTest_Alythar.unity`). Hybrid square + equilateral-triangle grid, socket-snap, structural-integrity DAG. Canon: [`../pipelines/pipeline_surface_tile.md`](../pipelines/pipeline_surface_tile.md).
    - [ ] **6.9.A.tile.1** — `BaseTileSchema` ScriptableObject + `TileShape` / `TileRole` / `TileSocketKind` enums. New file: `Assets/Scripts/Schemas/BaseTileSchema.cs`.
    - [ ] **6.9.A.tile.2** — Runtime: `SurfaceBaseAnchor`, `SurfaceGridManager`, `SurfaceStabilityGraph`, `SurfaceTilePlacer`, `SurfaceTileCatalog`. New folder: `Assets/Scripts/Macro/SurfaceBase/`.
    - [ ] **6.9.A.tile.3** — Editor helpers: `BaseTileSetupHelpers` (per-shape socket generators — square / triangle / wall / ceiling / ramp). New file: `Assets/Editor/BaseTileSetupHelpers.cs`.
    - [ ] **6.9.A.tile.4** — Starter prefabs + schemas (grey placeholder art, baked via setup scripts): Foundation Square T1, Foundation Triangle T1, Wall T1, Ceiling Square T1, Ceiling Triangle T1, Ramp T1. New folders: `Assets/Prefabs/Bases/Tiles/<Name>/` and `Assets/GameData/Bases/SurfaceTiles/T1/`.
    - [ ] **6.9.A.tile.5** — CloudScript: `BuildSurfaceTile` + `DemolishSurfaceTile` server-authoritative validation (cell occupancy, socket mate, cost, stability ≥ min). New file: `cloudscript/surface_tiles.js`. Until this lands, client-side validation only (BRIDGE).
    - [ ] **6.9.A.tile.6** — Scene wiring in `PlanetTest_Alythar.unity`: `SurfaceBaseRoot` GameObject with `SurfaceGridManager` + `SurfaceTilePlacer`; hotkey to enter tile-build mode (B?); reuse `BasePartBuildTimer` + `BasePartBreakable` for drone delivery + per-piece destruction.
    - [x] **6.9.A.tile.7** — Record-driven architecture pivot (Aaron 2026-05-29). `SurfaceBaseRecord` is the canonical persistent shape (anchor + tiles[]). `SurfaceBaseStore` holds records in memory + fires `OnTileAdded/OnTileRemoved/OnAnchorEstablished` events. `SurfaceBaseRenderer` subscribes and reflects record state into the scene. Placer no longer instantiates prefabs — it only writes to records. Decouples build-in-isolation from rendered-on-planet, unblocks ECS instancing + PlayFab persistence. Canon: [`../pipelines/pipeline_surface_tile.md`](../pipelines/pipeline_surface_tile.md) § 1.
    - [ ] **6.9.A.tile.8** — ECS-instanced rendering (post-pivot). Replace per-tile MonoBehaviour spawn with `BaseTileInstanceData` (`IComponentData`) entities + a BatchRendererGroup / DrawMeshInstanced system. One draw call per tile type vs. one per GameObject. ~50× faster at 1000+ tiles.
    - [ ] **6.9.A.tile.9** — PlayFab persistence (post-pivot). `SurfaceBaseStore` swaps from in-memory dict to PlayFab Title Data: index key `Body_<bodyId>_SurfaceBases` (list of baseIds), per-base key `SurfaceBase_<baseId>` (full record). Hooked into the new `BuildSurfaceTile` / `DemolishSurfaceTile` CloudScript handlers from tile.5.
    - [ ] **6.9.A.tile.10** — Server-FOW streaming (post-pivot, after 6.9.F). On fleet-enters-body-presence, fetch the body's surface-base records, spawn renderers. On exit, despawn. Subscribe to `ServerFowMatcher` notifications.
    - [~] **6.9.A.tile.comms — Communication antenna set** (Aaron 2026-06-05). 10 Sci-Fi Base antennas authored as `TileRole.Communication` tiles in a COMMUNICATION tab (Main Parts), grouped into `menuSection` tiers via `Assets/Editor/Comms_Antennas_Setup.cs`: Radar / Planetary Array / Regional Array (wall-mount) / Alliance Array / Interstellar Array. **Placement LANDED — cosmetic-now placeables.** TODO — wire the FUNCTION (NOT built yet): every tier draws **power**; **Radar** increases the base's FOW visibility radius; the array tiers unlock **chat channels** over Photon Chat (Planetary = planet-wide, Regional = nearest 10 bases, Alliance = alliance, Interstellar = galaxy). Add `// BRIDGE` markers + flip to live when the surface-base power model + chat-unlock hooks land. Canon: memory `project_comms_antennas.md`.
    - [x] **6.9.A.tile.cam** — Two-tier surface camera (cruising ↔ base) in `GroundBuildOrbitCamera`: a high cruising band kept above terrain peaks and a low base band that unlocks only over a base's claim (or before the first base exists). Click a base while cruising → swoop down + centre; pan outside the claim radius → swoop back up. Zoom is wheel/swoop-only, never terrain-driven; ground-clip handled by a hard floor that raises the camera (not zoom). Tuning shared via `Assets/Editor/AlytharCameraTuning.cs`. (Aaron 2026-06-02.)
    - [~] **6.9.A.tile.fleet-height** — Extend the two-tier HEIGHT to surface FLEETS: pathfinding, movement, and fleet battles run at the cruising altitude (collision-free above peaks); descend to base level only inside a base's claim, for localized base attacks. **Surface-fleet representation LANDED (Aaron 2026-06-03):** `SurfaceFleetSpawner` deploys a frigate on the cruise shell of `Planet_alythar`, flying the LOCAL (server-free) flight sim (see the flight-decouple note below). `GroundBuildOrbitCamera.TryGetActiveFleetWorldPos` is now wired to it, so Shift+F centers on the fleet. STILL TODO: descend-to-base-level once a base exists, and 6.9.F Fusion engagement for fleet battles.

    - [ ] **6.9.A.tile.beacon — Base Deployment Beacon (replaces first-foundation start)** (Aaron 2026-06-09). The single item that starts a surface base — the realization of the planned **Probe/claim item** (resolves the probe-stand-in bridge below). Player deploys a green-smoke beacon → it establishes the `SurfaceBaseAnchor` + claim, summons a freighter (reuse [`DeliveryEvent`](../../Assets/Scripts/Macro/DeliveryEvent.cs) + [`StartingCrateLoadout`](../../Assets/Scripts/Macro/StartingCrateLoadout.cs)) that drops a standard starter kit, then unlocks the build tools. **No relocation variant — by design** (forces material hauling → the transporter/logistics loop). Beacon is a **carried inventory deployable** (consumed on deploy), authored as a **new `BeaconSchema`** (= the anticipated `ProbeSchema`; `claimRadiusMetres` moves onto it). Spec: [`../ground_base/ground_base_deployment_beacon.md`](../ground_base/ground_base_deployment_beacon.md). Slices: **(1)** surface deploy → anchor + claim + freighter trigger (reuses the pre-anchor terrain-placement path; retires the first-foundation anchor logic in `SurfaceTilePlacer`); **(2)** `BeaconSchema` + green-smoke prefab + pipeline doc; **(3)** fleet-bar equipped-beacon entry + deploy action ([`FleetRosterHUD`](../../Assets/Scripts/UI/FleetRosterHUD.cs)); **(4)** PlayFab deploy dispatch + carried-item inventory (`// BRIDGE` until base persistence + auth land).

  **6.9.A.tile bridges to remove:**
  - `SurfaceTilePlacer.ConfirmPlacement` — client-side validation only. Remove when **6.9.A.tile.5** ships `BuildSurfaceTile` CloudScript.
  - `SurfaceBaseStore` in-memory dictionary — wipes on play exit. Remove when **6.9.A.tile.9** persists records to PlayFab Title Data.
  - `SurfaceTilePlacer.ownerId` / `bodyId` hardcoded ("test_player" / "alythar") — replace with live player session + active body context when surface scene loader lands (post-6.9.A surface scene template).
  - Drone delivery spawn point — spawns from base anchor instead of a Construction Yard module. Remove when surface-base CY semantics land (later phase).
  - `SurfaceBaseAnchor.claimRadiusMetres` hardcoded (default 60 m) — first foundation acts as probe-stand-in for claim bounds. Remove when `ProbeSchema` lands and the probe becomes a real authorable item; first-foundation-as-probe shim collapses into "probe placed → spawns anchor with its own claim radius". **→ realized by the Base Deployment Beacon (`BeaconSchema` = `ProbeSchema`); see 6.9.A.tile.beacon + [`../ground_base/ground_base_deployment_beacon.md`](../ground_base/ground_base_deployment_beacon.md).**
  - `SurfaceTilePlacer.foundationMaxSlopeCos` slope check — DISABLED for v1 (planet-radial up reference requires authoritative planet-center). Re-enable when `CelestialSpawner` / surface scene loader wires the planet transform into the placer.
  - `SurfaceFleetSpawner` (`Assets/Scripts/Macro/Ground/`) — spawns a HARDCODED test frigate + fallback loadout (autocannon + power core + 8 thrusters, grade 18) because the surface-scene fleet handoff (player's PlayFab fleet → surface scene) isn't wired yet. Replace the prefab + loadout source with the handed-off player fleet when the surface scene loader lands (post-6.9.A). Same `// BRIDGE` shape as `SurfaceTilePlacer.ownerId`/`bodyId`.
  - **Base-claim scatter exclusion (clear trees/rocks under a base).** Record-driven: `SurfaceBaseRenderer.EnsureSceneAnchor` (the reactor that draws the claim ring from `OnAnchorEstablished`) registers the claim disc with `SurfaceScatterExclusion` (`Assets/Scripts/Macro/SurfaceBase/SurfaceScatterExclusion.cs`); `HandleTileRemoved` (base emptied) + `TeardownAll` drop it. The facade forwards to a small static registry + Burst-job cull added to SGT's `SgtLandscapeSpawner` (`SetExclusionDisc` / `RemoveExclusionDisc` / `PointInExclusion`, marked `// APEX OUTLAW`). Two BRIDGE aspects: **(a)** discs are **in-memory only** — on scene load they must be rebuilt from the live surface-base records once persistence exists (resolve alongside **6.9.A.tile.9** PlayFab persistence). **(b)** The cull lives in the **SGT plugin** (`Assets/Plugins/CW/.../SgtLandscapeSpawner.cs`) because the private `SpawnJob` is the only place that can suppress the GPU-instanced scatter; ⚠️ **re-applying SGT (Planet Forge) will revert it** — same fragility class as the URP asmdef fix. If SGT is ever re-imported, re-add the `// APEX OUTLAW` blocks. Clear-only today; optional `SgtLandscapeFlatten` pad is a separate follow-up. (Aaron 2026-06-05.)

  **Flight decouple (Stage 1, Aaron 2026-06-03) — combat re-networking owed:**
  - `TacticalFlightEngine` — the flight sim was decoupled from Photon Fusion so ships fly LOCALLY with no `NetworkRunner` (open-world / planet cruise). The 15 ship-sim fields that were `[Networked]` (6 thrust intensities, shield/armor/capacitor, power-out cooldown, 2 shield flags) are now PLAIN fields; both `FixedUpdateNetwork` (authority) and a new local `FixedUpdate` drive a shared `StepFlight(dt)`; `localFlightEnabled` gates local running; `ConfigureShellFrame` adds spherical (planet-surface) movement alongside the flat tactical plane (`movementFrame` defaults to Flat, so the combat/tactical path is byte-identical). **Combat replication of ship/hull state is therefore NOT networked right now** — it must be rebuilt server-authoritatively (FleetSnapshot in / reconcile diff-patch out, hull HP + projectiles + destruction made authoritative) when combat lands. Tracked under **Phase 6.9.F** (Server FOW matcher + Fusion engagement) / Phase 4 combat. NOTE while here: the combat layer is *already* mostly client-trusted today (hull HP not networked, projectiles `Instantiate`d locally, destruction local `Destroy`) and the `Assets/Scripts/ECS/` damage subsystem named in CLAUDE.md does not actually exist — so this decouple does not regress an otherwise-secure combat path; the real anti-cheat build is greenfield.
- [ ] **6.9.B — Solar PF thumbnails**. `MacroPlanetThumbnail` prefab + `CelestialSpawner` swap. Every body in Vesperion renders as themed Planet Forge sphere with atmosphere ring.
- [ ] **6.9.C — Low Orbit scene template** (`Assets/Scenes/LowOrbit.unity`). Same Planet Forge planet as Surface, at higher altitudes. Orbital structures from registry (docks, citadels, satcom, planetary defense, jump gates). RTS ship controls via `TacticalFlightEngine` + `TacticalSelectionManager`. Canon: [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md).
- [ ] **6.9.D — Permit-gated Low Orbit → Surface transition**. `PlanetSurfacePermitCheck` CloudScript handler (own base / allied / defenses defeated). New `canEnterAtmosphere` bool on `ShipChassisSchema` excluding capital ships.
- [ ] **6.9.E — Activity-noise radar stealth**. `BaseNoiseEmitter` MonoBehaviour on surface bases. Computes `NoiseLevel` from active facility tasks (smelter, forge, drone build). Nearby enemy ship sensors reveal noisy bases on radar; silent bases stay off-radar but remain visually rendered in 3D world.
- [ ] **6.9.F — Server FOW matcher + Fusion engagement**. `ServerFowMatcher` CloudScript (adaptive cron, 15s baseline ramping to 1s when fleets converge). `FleetEncounterClient` subscription + lazy `NetworkRunner` spawn per engagement cluster (16-player cap each). `FleetSnapshot` handoff to networked authority.
- [ ] **6.9.G — Hyperspace intercept → blank space combat**. When attack timer matures in Solar (Scene 1), drop into the existing `shipmanagerTestFleet.unity`-style sandbox with `NetworkRunner` already active. NOT Low Orbit, NOT Surface — pure interstellar combat with skybox + nearby-body backdrops.
- [ ] **6.9.H — Retire legacy**. Delete: `Planet_avernus.unity`, `Planet_praedo.unity`, `PlanetSurfaceViewController.cs`, `PlanetFleetLongitudePinner.cs`, planet-variant `MacroFOWOverlay.cs`, `PlanetSurfaceBaseSpawner.cs`, `PlanetAvernusSceneBuilder.cs`. Update `MacroSurfaceBasePoi.cs` (if kept as registry-binding class) to drive 3D-world placement instead of arc projection. Grep-verify no stragglers of the old vocabulary remain.

### 6.9.I — Surface resource gathering loop (drone-gather MVP) (NEW 2026-06-07)
**Goal:** Close the production tree's Layer-0 gap — give the surface base a live source of raw materials. Canon: [`../world/world_surface_gathering.md`](../world/world_surface_gathering.md). Resolves the "raws are graded" question (yes) and locks the on-planet **A− (Elite) grade cap** (above A− is off-planet only — also in [`../world/world_resource_geography.md`](../world/world_resource_geography.md) §3).

- [ ] **6.9.I.0 — `MaterialClass` on `ResourceSchema`** — add `MaterialClass { Graded, Bulk }` (default `Graded`). Bulk = ungraded construction commodities (granite, regolith); scanner / discovery / A− cap logic skips non-`Graded`; crate stacks show grade "—"; Bulk excluded from the min-grade purity cascade. **Canon-debt reconciliation (schema/docs stale, pre-2026-05-17-pivot):** the `ResourceSchema` class docstring + `massPerUnitKg` tooltip still assert ALL raws are ungraded — correct them for the `Graded` class; add a clarifying note to [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md) §3.5 (graded RAW resources carry the extraction-location matrix quality that ceilings synthesis); sync the stale field list in [`../pipelines/pipeline_resource.md`](../pipelines/pipeline_resource.md) (lists removed `tier`/`vein`; missing `phase`/`miningTier`/`MaterialClass`).
- [x] **6.9.I.1 — Pipeline docs** (2026-06-07). `pipeline_biome.md` written + indexed in `pipelines_overview.md`. (`pipeline_surface_deposit.md` was written then **deleted** — the deposit system is component-based, not schema-driven; see 6.9.I.3.)
- [ ] **6.9.I.2 — Biomes (`BiomeZoneSchema` + Alythar bands)** — the one net-new piece left in the surface loop. Canon: [`../world/world_surface_gathering.md`](../world/world_surface_gathering.md) (biome system) + [`../pipelines/pipeline_biome.md`](../pipelines/pipeline_biome.md). **Next steps (TODO, 2026-06-07):**
  1. **Schema** — `Assets/Scripts/Schemas/BiomeZoneSchema.cs`: `zoneId`, `displayName`, `latMin`/`latMax` (band degrees), `sgtLayers` (ref to the SGT `SgtLandscapeBiome` layer set), `resourceSignature` (`List<{ resourceID, weight }>`), `dressingProps`, optional `equatorLift`/`polarSink`. `CreateAssetMenu`; auto-catalog via `AssetDatabase.FindAssets($"t:{nameof(BiomeZoneSchema)}")`.
  2. **3 Alythar band instances** — `Assets/GameData/Biomes/`: equatorial (±~25°), temperate (~25–60°), polar (~60–90°). Signatures: granite everywhere (Bulk); vary the *graded* ores per band per `world_resource_geography.md` composition (on-planet cap A−).
  3. **Biome resolver (runtime)** — from a surface (lat, lon) via `PlanetSurfaceCoordinates.LatLonFromDirection`, return the active `BiomeZoneSchema` (latitude-band lookup). Consumed by the deposit scatter + the SGT material.
  4. **SGT material biome blend** — drive the `SgtSphereLandscape` material by lat/lon (per-band layer/tint first; baked biome-ID mask + Voronoi regions later). The bigger Planet-Forge visual chunk — start with a simple per-band swap.
  5. **Wire scatter → signature** — `SurfaceResourceField` (currently hardcoded granite) reads the active biome's `resourceSignature` to choose what scatters where. Connects biomes → the gather loop.
  6. **Per-biome dressing** — vary the SGT `SgtLandscapeBiome.Layers` (trees/rocks) per band (forest temperate, barren polar). Already GPU-scattered; the biome just selects the layer set.
  - **Notes:** start with latitude BANDS (cheap), region-map is a follow-up; planet-AGNOSTIC (Alythar is the test vehicle); `pipeline_biome.md` already exists, so the content-type doc precedes the schema.
- [x] **6.9.I.3/.4/.5 — Deposit + scatter + drone Gather** (DONE by the parallel drone work, 2026-06-07). Component-based, **no `SurfaceDepositSchema`**: `SurfaceResourceField` scatters granite nodes at first-foundation; `SurfaceResourceNode` is the mineable node; `BaseDroneFleet` mines → hauls → `DepositGranite`/`SpawnGraniteCrate` to a player crate; RTS right-click targets nodes. **v1/BRIDGE:** editor-time prefab load + RANDOM scatter + placeholder grade (granite is Bulk so the inventory reads `—`). Future: per-player deterministic graded geography from the alchemy seed (canon `world_surface_gathering.md`); honor `SurfaceScatterExclusion`; must NOT write `maxDiscoveredGoods` (drone = no discovery).
- [ ] **6.9.I.6 — Processing handoff** — collected graded stacks feed the smelter→refinery→forge spine.
- **FUTURE (designed, not built):** surface scanner + extraction that *stamps* `maxDiscoveredGoods` (miner path, mirrors the belt mining scene); stationary mining outpost (reserved `FacilityType.Miner`); roaming scanner/miner vehicle; large equipment.

**6.9.I bridges to add when work starts:**
- Surface deposit records **in-memory only** — rebuild from live records once persistence exists (same removal moment as **6.9.A.tile.9** PlayFab persistence).
- Deposit-node + biome prefab/asset loads — editor-time `AssetDatabase` (BRIDGE → Addressables, same moment as the sibling surface-base loads).
- A− cap clamp + grade roll — read the ceiling from `grade_table_default.asset` (`GradeSchema`), never a hardcoded constant.

### Bridge code to remove (Phase 6.7 + 6.9)
Until 6.7.E lands, the mesh-FOW system (6.7.B + 6.7.D) is **client-side display only** — PlayFab still ships the full registry + full fleet list. A memory-scraping client can see fleets the FOW hasn't revealed. Tagged in code so the cheat surface is grep-able. Phase 6.9.F (`ServerFowMatcher`) is where the macro FOW becomes fully server-authoritative.

- `Assets/Scripts/Macro/MacroSyncMesh.cs` — `BRIDGE: client-side mesh-FOW only — until Phase E server-FOW lands, full registry is still shipped to client.` Remove when Phase 6.7.E (or 6.9.F, whichever lands first) ships server-side `GetVisibleEntities` / `ServerFowMatcher`.
- `Assets/Scripts/Macro/MacroFOWUnion.cs` — `BRIDGE: client-side FOW filter only — until server-FOW lands, full registry is still shipped to client and FOW is purely a display layer (not anti-cheat).` Remove when 6.7.E / 6.9.F ships.
- `Assets/Scripts/Macro/MacroSyncVisualizer.cs` — `BRIDGE: client-side display only — server-FOW phase moves the authoritative sync graph to CloudScript.` Visualizer itself stays; the BRIDGE comment goes away when its data source becomes server-authoritative.
- `Assets/Scripts/Macro/MacroPartyService.cs` — `BRIDGE: in-memory only — until party-management UI + PlayFab persistence land, this set is populated by tests / debug commands and resets per session.` Remove when party-management UI + backend persistence ship.
- `Assets/Editor/HelionSceneBuilder.cs` (test fleet + `HelionPlayerSpawnAnchor`) — dev-only simulator. Helion itself is retired (the unified world); for Phase 6.9 the test fleets live in `PlanetTest_Alythar.unity` and `shipmanagerTestFleet.unity`. Remove when the production planet-scene flow ships.
- `Assets/Scripts/Macro/MacroSurfaceBasePoi.cs` `BeginAttack` onComplete callback — `BRIDGE: remove when 6.9.F server-FOW Fusion engagement lands`. Replace with the `ServerFowMatcher` → `NetworkRunner` spawn flow; `BeginAttack` becomes the explicit "I declare an attack" client-side trigger that hands off to the matcher.
- `Assets/Scripts/Macro/PlanetSurfaceBaseSpawner.cs` — DEPRECATED. **Delete in Phase 6.9.H** (replaced by 3D registry-driven surface base spawning in `world_surface_scene.md`). Was: `BRIDGE: PlayerPrefs last-view — move to PlayFab player data`. PlayerPrefs concern goes away with the new scene model (there's no rotating planet to remember a view of; the player respawns at their fleet's last position via the `Body_<bodyId>_Presence` channel).

#### NEW Phase 6.9 bridges (to add when work starts)

- `Assets/Scripts/Macro/Ground/BaseNoiseEmitter.cs` (Phase 6.9.E) — `BRIDGE: reads from local MacroBaseRecord.installedModules and infers activity from module state. Replace when CloudScript-backed facility activity tick channel ships.` Without the tick channel, noise emission may be sketchy across clients.
- `Assets/Scripts/Macro/Ground/GroundBuildOrbitCamera.cs` `TryGetActiveFleetWorldPos` (Phase 6.9) — `BRIDGE: remove when surface fleets land`. The **Shift+F** birds-eye snap is meant to center over the player's active fleet; until a landed-fleet representation exists in the surface scene the method returns false and Shift+F falls back to birds-eye-in-place (the current behaviour). Wire the landed fleet's world position here when surface fleets land. (**Shift+B** over the base is already fully live via `SurfaceBaseAnchor.Current`.)
- `cloudscript/planet_surface_permits.js` `PlanetSurfacePermitCheck` (Phase 6.9.D) — `BRIDGE: alliance membership lookup uses local cache; replace with authoritative alliance roster CloudScript when Alliance system lands.`
- `cloudscript/server_fow_matcher.js` `ServerFowMatcher` (Phase 6.9.F) — `BRIDGE: adaptive cron implemented as PlayFab scheduled task; if encounter latency feels sluggish, swap to always-on Photon "matcher runner" per body.` Hosting decision documented in the meta-plan.
- `Assets/Scripts/Networking/PlanetSceneEntry.cs` (Phase 6.9.A) — `BRIDGE: handoff payload is a static class; replace with PlayFab session ticket carrying the handoff when cross-device scene transitions need it.` Local-only across SceneManager swaps for now.
- `Assets/Scripts/Macro/Ground/BaseDronePilot.cs` `ResolveDronePrefab` (Phase 6.9) — `BRIDGE: editor-time AssetDatabase load of the Drone_ZR7 prefab; returns null in player builds`. The base drone (loaded by the first-foundation placement via `SurfaceTilePlacer.ConfirmPlacement` → `BaseDronePilot.EnsureForBase`) resolves its prefab through `AssetDatabase`, identical to `SurfaceTilePlacer.LoadPrefab` / `GroundBaseSceneLoader.LoadTheme`. Replace with an Addressables load when the surface-base Addressables pipeline is wired (same removal moment as those sibling loads).
- `Assets/Scripts/Macro/PlanetDayNightCycle.cs` + `Assets/Scripts/Macro/PlanetSurfaceCoordinates.cs` (Phase 6.9 — Planet_alythar surface day/night + cursor lat/lon/alt readout) — `BRIDGE: dayLengthHours authored per-scene on the sun's PlanetDayNightCycle`. Per-planet day length should be sourced from a **dedicated** per-body day-length field on `CelestialParentRecord` once the `Planet_*` scenes are registry-bound. The registry's existing `spinDegreesPerSecond` is the **cosmetic strategic-map spin** (a turn every ~minute) and is deliberately NOT reused. When the field + binding land, read `dayLengthHours` from the body record and keep the serialized value only as a fallback (same removal moment as planet-scene registry binding, 6.8.4 / 6.9.H). **Companion note (not itself a bridge):** `PlanetSurfaceCoordinates` is the canonical (lat,lon)↔direction frame (lat 0=equator/+90=+Y pole; lon 0=local +Z, east-positive, [0,360)). The future real surface-base placement — replacing the north-pole placeholder in `GroundBaseSceneLoader` (Phase 6.8.D) — **must** call `PlanetSurfaceCoordinates.DirectionFromLatLon` rather than re-deriving the math, so an authored (lat,lon) round-trips with the cursor readout.
- `Assets/Scripts/Macro/PlanetMoonSystem.cs` (Phase 6.9 — Planet_alythar moons + eclipse) — `BRIDGE: serialized moon set` — moon *bodies* ✅ resolved 2026-06-09 (`Assets/Prefabs/Moons/Moon_Luna.prefab`, harvested from SGT's *Lunara* demo, wired as `moonBodyPrefab`; the flat sun-disk billboard is hidden so the eclipse reads against the SGT corona; [`CelestialTimeScrubber`](../../Assets/Scripts/Macro/CelestialTimeScrubber.cs) scrubs `CelestialClock.DesignerOffsetSeconds` to pose it). These are the **Planet Forge moon bodies** (map-reusable per [`../pipelines/pipeline_cw_planet.md`](../pipelines/pipeline_cw_planet.md)) so the *same* moon drops onto the system map. And the moon set (count / periods / radii) is authored on the component; source it from the **CelestialRegistry moon-ladder** (per-body moons at 12/14/16h…) once `Planet_*` scenes are registry-bound — same removal moment as the day-length registry binding. The moon **orbits + the eclipse are already deterministic** (`CelestialClock`, per-observer coverage) and need no bridge — they're MMO-consistent as-is (no server, no anchor).
- `Assets/Scenes/Planets/Planet_A_orbit.unity` + `Planet_01_surface.unity` — **planetary shield + orbital gate** (2026-06-09) — `BRIDGE: shield, aperture, and the RoundSpaceStation gate are scene-authored, not registry-driven`. Shield = [`Assets/Shaders/PlanetShield.shader`](../../Assets/Shaders/PlanetShield.shader) + `Assets/Prefabs/Weather/PlanetShield.mat` / `ShieldIcoSphere.asset` (radius 110,000, subtle Bloom `Assets/GameData/Rendering/ShieldBloom.asset`); gate = `Assets/Art_Assets/RoundSpaceStation/` ring at the north pole. When orbital structures go registry-driven (6.8.1 `OrbitalPoiRecord` / a `RingStation` child type), the gate becomes a `RingStation`(+shield) `CelestialChildRecord` spawned by `CelestialSpawner`, with the aperture direction/size derived from it. Canon: [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md) § Planet visual stack.
- `Assets/Prefabs/Weather/StormRig.prefab` (`PlanetStormLightning` + `LightningFlasher`) in the `Planet_01` scenes — `BRIDGE: storm bands (lat 0 / ±38°) + boltRadius authored per-scene`. Extracted from `Planet_aridonPF.unity`; source the bands + cloud-coupled bolt radius from per-body climate/registry data when `Planet_*` scenes are registry-bound (same removal moment as the moon-set / day-length bindings).
- `Assets/Scripts/Macro/SurfacePrecipitation.cs` (surface scene) — *not strictly a bridge:* camera-following rain/snow, auto by latitude (`snowLatitude` default 50°, pole→snow). If per-biome/per-planet weather data lands, drive the rain↔snow threshold + intensity from it; fine as a local visual otherwise.

---

## Phase 6.8 — Vesperion Body Schema & POI System
**Goal:** Replace the hand-authored Avernus subtree in `Vesperion.unity` with a live, registry-driven body model that supports player bases, alliance POIs, and faction jump gates — same data path as the existing celestial registry.

**Context.** The Helion scene accumulated too many half-baked authoring decisions and was set aside. Vesperion is the clean restart. The first planet (Avernus, lava world + 3 moons + 1 neutral jump gate) was hand-authored into `Vesperion.unity` to validate the visual language. The data shape behind it is intentionally deferred to this phase to avoid bloating the visual-iteration step.

- [ ] **6.8.1 Schema extension** — extend `CelestialParentRecord` (or split into `CelestialPlanetRecord` / `CelestialMoonRecord`) with:
  - `bases: List<PlayerBaseRecord>` where `baseType ∈ { MainBase, AllianceBase, Outpost }`. Lives in a separate PlayFab key keyed by body id, NOT in the static registry.
  - `lowOrbitPois: List<OrbitalPoiRecord>` — alliance-built structures (`PlanetaryDefense`, `StatCom`, `SensorArray`, future). Also dynamic, separate PlayFab key.
  - `highOrbitGates: List<JumpGateRecord>` — jump gates only. `gateType ∈ { Neutral, Faction }`; faction gates carry `factionId` (alliance UUID or "FED"/"ICE").
  - `moons: List<MoonId>` — child body references. Moons are structurally a planet record **minus** `highOrbitGates` and `moons` (moons don't have moons or jump gates per design rule).
- [ ] **6.8.2 Slot system** — fixed buildable slot count per body per type (e.g. N main-base, M outpost, K low-orbit POI). Authored on the celestial parent record; placement validated server-side in CloudScript.
- [ ] **6.8.3 CloudScript handlers** — `BuildBase`, `DemolishBase`, `BuildOrbitalPoi`, `BuildFactionGate`. Mirror the alliance-POI handler shape at `cloudscript/celestial_alliance_pois.js`. All slot-occupancy checks server-side.
- [ ] **6.8.4 CelestialSpawner integration** — once 6.8.1–6.8.3 are in, delete the hand-authored Avernus subtree from `Vesperion.unity` and have `CelestialSpawner` build it from the registry on scene load (same pattern that already drives SolarSystem.unity).
- [ ] **6.8.5 Faction gate visuals** — extend `JumpGateMarker` (or `POI_*JumpGate` authoring) to support a `gateType` selector. Neutral = gray dot + colorless bubble; Faction = faction-color dot + faction-tinted bubble. Currently `JumpGateMarker` already has FED/ICE/dual color states — wire `gateType` to drive which one renders.
- [ ] **6.8.6 Lava-glow validation** — confirm `SolarSystemBodyGlow.boostMaterialEmission` actually lights the night side of `Planet_Avernus_LavaGlow.mat` as intended; tune emission HDR and glow color if it's flat. Currently set to `(1.8, 0.4, 0.05)` glow + `(2.2, 0.6, 0.1)` emission.

- [ ] **6.8.7 New-account onboarding flow** — `PlayerEnsureHomeLocation` currently hard-codes the first-login defaults to `Planet_avernus` / `Vesperion`. Replace with a real new-player onboarding flow that lets the player pick a starting body / system from an admin-curated allow-list. Until then, every new signup lands on Avernus.
- [ ] **6.8.8 Slot uniqueness on home location** — Once the slot system (6.8.2) lands, extend `PlayerEnsureHomeLocation` (and the future `PlayerSetHomeLocation`) to enforce "only N main bases per body" server-side. First-N-served until the planet is full; new signups overflow to a fallback body.
- [ ] **6.8.A Default orbital periods for body satellites (Vesperion canon)** —
  - **Moons** follow the *moon ladder*: the innermost moon orbits its host body at **12h**, and every moon further out adds **+2h** (so a planet's 1st/2nd/3rd/4th moons orbit at 12/14/16/18h). The ladder breaks resonance — moons don't lock into fixed angular relationships, and a planet's whole moon system slowly precesses through configurations. Avernus already follows this canon (Cinis 12h, Fumus 14h, Scoria 16h).
  - **Low-orbit POIs** (StatCom, Planetary Defense, etc.) orbit at **4h**.
  - **High-orbit jump gates** orbit at **6h**.

  When CelestialSpawner takes over (6.8.4), these defaults should drive the period for any newly built POI / moon unless an authoring override is provided. The moon-ladder calculation needs to know each moon's index within its host's moon list — order is by orbit radius (innermost = index 0).
- [ ] **6.8.9 JumpGateNetworkVisualizer body-model rework** — `JumpGateNetworkVisualizer.cs` was authored against the legacy Helion sector-chain model. The home-body fallback was migrated minimally to `homeBasePlanetBodyId` to keep it compiling, but the visualizer logic still assumes sectors as gate endpoints. Rewrite for the body-in-system gate model when Phase 6.8 jump-gate behavior locks down.

- [x] **6.8.B Asteroid belt registry migration (Slice A → registry)** — Landed 2026-05-17. `CelestialChildType.AsteroidBelt = 17` (not 16 — `SurfaceBase` already occupied 16; appended). Belt-payload fields (`beltInnerRadius` / `beltOuterRadius` / `beltYOffset` / `beltYJitter` / `beltSeed` / `beltAsteroidCount`) added to `CelestialChildRecord`. `CelestialChildBuilder.Build` short-circuits to `BuildAsteroidBelt` for the new type — attaches the belt GameObject directly under the host (not under SatelliteOrbits), spawns `MacroAsteroidBelt` + `MacroAnnulusFill` child as `bandFill`, syncs borders, inherits host layer. Seed.json entry: new `Sun_Vesperion` root parent + `Sun_Vesperion/Belt_Vesperion_Outer` child with the live geometry (r=7000–9000, seed=1337, yOffset=120, jitter=40, count=0). `VesperionAddOuterBelt.cs` + scene-baked `Sun/Belt_Vesperion_Outer` GameObject removed. Live integration via narrow `VesperionRegistryBeltMounter` MonoBehaviour on `[VesperionBootstrap]` — listens for registry updates and mounts AsteroidBelt children with `parentId == "Sun_Vesperion"` onto the scene's hand-authored Sun. **BRIDGE flagged** — removed when 6.8.4 lands the full `CelestialSpawner`-in-Vesperion path. **Destination shape:**
  - **Enum:** append `AsteroidBelt = 16` to `CelestialChildType` (after `Refinery = 15`).
  - **Record payload** (additive on `CelestialChildRecord`, no schemaVersion bump — Newtonsoft ignores unknown fields):
    - `float beltInnerRadius`
    - `float beltOuterRadius`
    - `float beltYOffset`
    - `float beltYJitter`
    - `int beltSeed`
    - `int beltAsteroidCount` — `0` in Slice A means band-only; Slice B treats it as max density.
  - **Seed.json entry** parented to whatever owns the Vesperion star (likely a new `Sun_Vesperion` parent record, since the existing `Sun` in seed.json is Helion's). Orbit radius on the belt's own `orbit` block is cosmetic — the band geometry is driven by `beltInnerRadius`/`beltOuterRadius`. Set `orbit.orbitPeriodSeconds = 0` (the belt root doesn't rotate; asteroids will each carry their own MacroOrbiter when Slice B spawns them).
  - **Spawner branch** in `CelestialChildBuilder.Build()`: short-circuit before the SatelliteOrbits path with `if (record.type == CelestialChildType.AsteroidBelt) return BuildAsteroidBelt(record, host);` and a private helper that creates the belt GameObject directly under the host (NOT under SatelliteOrbits, so the band stays visible at every zoom level), adds `MacroAsteroidBelt` + a `MacroAnnulusFill` child wired as `bandFill`, calls the public `belt.SyncBorders()`, and inherits the host's layer for the SolarSystem-camera cullingMask.
  - **Live-data acceptance test:** delete `VesperionAddOuterBelt.cs` and confirm the belt still appears on V2/V3 after a fresh scene load, driven entirely by the registry. Mining-op + depletion are Slices B/C and don't block this migration.
- [ ] **6.8.C Asteroid belt — FOW-driven asteroid spawn (Slice B)** — Refactor `MacroAsteroidBelt.Awake` from "spawn `count` asteroids eagerly" to "spawn cells lazily based on friendly-FOW coverage." Cell math: divide the band into `(angularBuckets × radialBuckets)` cells; on each tick check `MacroFOWUnion.IsInsideFriendlyFOW(cellCenter)`; instantiate the cell's asteroids from a deterministic per-cell seed derived from `(beltSeed, angularIndex, radialIndex)`; despawn cells that leave the FOW union. Per-asteroid count then matches `beltAsteroidCount / totalCells` density, not an eager total.
- [ ] **6.8.D Asteroid belt — depletion + lazy regen (Slice C)** — Per Aaron's canon: mined asteroids regenerate once nobody's watching. Storage: sparse `(beltId, asteroidIndex, depletedAtUtc)` rows in a PlayFab title-data key. On CloudScript query when a player approaches a belt: for each row, if `(NOW - depletedAtUtc) > regenDelay` AND `!IsInsideFriendlyFOW(asteroidPos)` → drop the row (regenerated). No background ticks. The mining-op event (Fusion, separate phase) writes new depletion rows when an asteroid is fully mined out.
- [ ] **6.8.E SolarSystem SystemView gate reveal — re-home.** `JumpGateNetwork.SetLinesVisible` no longer force-activates gate POIs against `SolarSystemZoomController`'s hidden `SatelliteOrbits` subtree at SystemView (the coupling was destroying gate visuals + orbit rings in Vesperion across ON/OFF toggle cycles). Move the "reveal gate POIs at SystemView when the Jump Gates overlay is on" behavior into `SolarSystemZoomController.cs` so it consults `JumpGateNetwork.Instance.linesVisible` and selectively keeps gate POIs visible (without un-hiding moons / non-gate POIs). Until this lands, the Jump Gates master toggle in `SolarSystem.unity` draws tunnel overlay correctly but the gate position dots may stay hidden at SystemView. Vesperion is unaffected. File: `Assets/Scripts/Macro/SolarSystemZoomController.cs`.

- [ ] **6.8.F Space coordinates (system-space) — Vesperion-based** — A **system-attached** coordinate type for SPACE, mirroring the surface [`PlanetCoordinate`](../../Assets/Scripts/Schemas/PlanetCoordinate.cs) (`{ bodyId, lat, lon, alt }`). A `SpaceCoordinate` carries `{ systemId, …position }` so a point in space resolves unambiguously to "that spot in the Vesperion system" and is shareable (chat pins / waypoints / rendezvous) — same role as the surface `geo:` token but for the system map. **Frame:** anchor to the system's star (`Sun_Vesperion`) at origin, XZ orbital plane (matching `CelestialPositionEvaluator`). **Representation (decide at build):** raw `(x, y, z)` vs polar `(radius, angleDeg, yOffset)` to fit the orbital model. Provide a shareable token (e.g. `sys:vesperion:<…>`) + display string + a resolver back to a world position when in that system. Parallels the surface nav coordinate work — see [`../world/world_surface_navigation.md`](../world/world_surface_navigation.md) § Planet-attached coordinates. Vesperion is the first system (per-system scene canon).

### Bridge code to remove (Phase 6.8)
- [x] ~~`Assets/Editor/VesperionAddOuterBelt.cs`~~ — Removed 2026-05-17 with Slice 6.8.B. The registry-driven spawn via `VesperionRegistryBeltMounter` + `CelestialChildBuilder.BuildAsteroidBelt` replaces it.
- [ ] **`Assets/Scripts/Macro/Vesperion/VesperionRegistryBeltMounter.cs`** — Narrow runtime bridge that mounts AsteroidBelt children whose `parentId == "Sun_Vesperion"` onto Vesperion's hand-authored `Sun` GameObject. Exists only because Vesperion has no `CelestialSpawner` and the scene's Sun is named bare `"Sun"` (collides with Helion's registry id `"Sun"`). Remove when Phase 6.8.4 lands the full `CelestialSpawner`-in-Vesperion path and the scene's Sun is renamed to `Sun_Vesperion` (or some equivalent bridging is built into `CelestialSpawner`). Bridge flag in [`VesperionRegistryBeltMounter.cs`](../../Assets/Scripts/Macro/Vesperion/VesperionRegistryBeltMounter.cs).
- `Assets/Editor/VesperionAvernusBuilder.cs` — hand-author script that bakes Avernus + moons + neutral gate into the scene. Delete when 6.8.4 ships and the registry-driven spawn replaces it.
- `Assets/Materials/Macro/Planet_Avernus_LavaGlow.mat` (the inline duplicate) — replace with an Addressable lava material registered to the planet's `visualPrefabAddress`.
- `Assets/Editor/VesperionAddBootstrap.cs` — one-shot editor helper that authored the `[VesperionBootstrap]` GameObject into the scene. Once the bootstrap GameObject is committed in the scene, the editor helper can go.
- `PlayerEnsureHomeLocation` hard-coded defaults (`Planet_avernus` / `Vesperion`) in `cloudscript/player_home_location.js` — bridge until 6.8.7 onboarding flow ships.
- Legacy `homeBaseSectorID` cleanup write in `cloudscript/player_home_location.js` — remove after every active account has had at least one login post-deploy (the migration write becomes a no-op once no accounts carry the legacy key).
- [`Assets/Scripts/Editor/BaseSocketSeeder.cs`](../../Assets/Scripts/Editor/BaseSocketSeeder.cs) — bounding-box cardinal-socket auto-seeder. Useful only while individual chassis/connector socket layouts aren't designer-authored. Delete when every base schema ships with hand-placed sockets that match the prefab's actual doorways. Currently a no-op against `Command_Outpost_MK1` and `Standard_Hallway` because they're already authored.
- **Base-builder snap socket-kind coverage** — chassis (`Command_Outpost_MK1.sockets[]`) and hallway (`Standard_Hallway.endpoints[]`) are all `SocketKind.Medium`. Modules with `requiredSocketKind = Small` or `Large` have no compatible sockets and won't snap. Resolve by either (a) authoring Small/Large sockets on chassis/connectors per design intent, or (b) shipping the "Large socket accepts Small/Medium" matching rule the SocketKind comment promises for v2.
- **Module input-socket convention is implicit** — `FacilityModuleSchema` has no `sockets[]` list; the snap algorithm in [`BaseBuildController.cs`](../../Assets/Scripts/Macro/BaseBuildController.cs) assumes every module's input is at local origin facing +Z, kind = `requiredSocketKind`. If/when a module needs multiple connection points (e.g. a junction-style module), promote `FacilityModuleSchema` to an `endpoints[]` list and remove the implicit-origin assumption in `TryGetGhostInputSocket`.

---

## Phase 6.9 — Resource Geography & Inner-System Composition
**Goal:** Every body in Helion has a signature resource identity. Players know "if I need tungsten I go to Avernus, if I need lithium I go to Aridus." Geography drives travel decisions; the 12,345 Alchemy Matrix layers per-player grade variance on top.

*Added 2026-05-17. Canon: [`../world/world_resource_geography.md`](../world/world_resource_geography.md). Future-feature catalogue: [`../world/future_ideas.md`](../world/future_ideas.md).*

### 6.9.A — Inner system resource lockdown (canon)
- [x] **Resource geography doc authored** ([`../world/world_resource_geography.md`](../world/world_resource_geography.md)) covering frost-line principles, full Tier-1 raws → location matrix, Avernus / Aridus / Main Belt signature resource sets, named features, expansion phases A–I.
- [x] **Future ideas doc** ([`../world/future_ideas.md`](../world/future_ideas.md)) capturing Fleet Graveyard, Generation Ship, Sun-Grazer Comet, Sub-Ice Ocean Moon, Hollow / Dyson Moon, Rogue Planet, Lagrange Hub, Black Hole, Pulsar, Military Bunker.
- [x] **Phase 6.8.B Main Belt** category trim from 10 → 8 (remove Ice + Ice_Spikey families — pre-frost-line). Belt categories edited on the [VesperionRegistryBeltMounter](../../Assets/Scripts/Macro/Vesperion/VesperionRegistryBeltMounter.cs) inspector field. Landed 2026-05-17.

### 6.9.B — Surface extraction mechanics (Phase 6.8 dependency)
- [ ] **Surface mining schema** — extend `MacroSurfaceBasePoi` (or a sibling extraction component) with per-body resource composition. Avernus surface base → sulfur + tungsten + uranium (hazard); Aridus surface base → lithium + silicates + titanium; Avernus moons → silicate / carbon / sulfur lean per moon.
- [ ] **Radiation-hazard tag on uranium extraction.** Slows extraction rate or carries periodic crew-damage events on Avernus.
- [ ] **Lore-coded moon resource leans.** Cinis (silicates), Fumus (carbon graphite), Scoria (sulfur ash). Each moon's surface base produces its lean as primary + the other two as trace.

### 6.9.C — The Ring of Castor (alien-tech feature)
- [ ] **Schema for non-belt mineable / explorable features.** New field on `CelestialParentRecord` (or a sibling `MineableComposition` SO) for bodies that aren't standard asteroids — covers The Ring's special resources + future Hollow/Dyson Moon content.
- [ ] **Ring debris geometry around Castor.** Modeled as a thin `AsteroidBelt` orbiting Castor (radius ~50–80 units from Castor) with a custom "AsteroidCategory_AncientAlloy_Debris" category + low spawn count (rare scatter, not dense swarm).
- [ ] **Intact arc segments.** A small number (3–5) of larger interactable structures along the ring's circumference. Each is its own GameObject — not belt-spawned. Some hold pressure / atmosphere for mini-dungeon interiors.
- [ ] **Ancient Alloy + Precursor Crystal `ResourceSchema` assets** — new Tier-4+ raws. Sourced ONLY from The Ring today (other precursor sites graduate from `future_ideas.md` as needed).
- [ ] **Central function reveal** — late-game alliance objective. Final design TBD per [open design decision #7](../world/world_resource_geography.md). Placeholder: discovering The Ring's purpose triggers a Helion-wide event.

### 6.9.D — Praedo Pirate Stronghold (Outlaw faction content)
- [ ] **Outlaw faction hub** at Praedo. Black market trading post (no FED tax / no ICE tariff / accepts contraband per [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 Black Market).
- [ ] **Hollowed-asteroid interior scene.** New per-named-asteroid scene type (similar pattern to `Planet_avernus.unity` but smaller scope). Interior: multi-deck docking bays, market terminal, NPC contact, hostile defenders.
- [ ] **Hidden from default scanners.** New flag on the parent record (or POI authoring) gates default-map visibility. Discovery via player-to-player intel / quest / alliance share.
- [ ] **Alliance capture mechanic.** Praedo can be attacked + captured by an alliance. Capture transfers control of services (black market remains? open design decision #9).
- [ ] **Quest source.** Hauler contracts + smuggling missions originate from Praedo.

### 6.9.E — Wandering bodies mechanic
- [ ] **Per-wanderer composition payload.** `MacroEllipticalOrbiter` already exists (Praedo uses it). New schema field for "this wanderer carries the resource mix of its origin zone." Cold-origin wanderers carry helium-3 / ice in the inner system — limited-time mining opportunity.
- [ ] **Authoring 5–10 wandering bodies** (per open design decision #10) beyond Praedo. Each one has a unique composition + lore hook.
- [ ] **Risk-by-position mechanic.** Perihelion (sun-close) → heat damage to structures. Aphelion (deep outer) → pirate ambush territory + no faction patrols.
- [ ] **Mining-base time lock.** Placing a base on a wanderer means committing to its orbital cycle. Document the tradeoff in player-facing UI.

### 6.9.F — Named asteroid composition (excluding Castor + Praedo)
- [ ] Hand-tuned material lists for the remaining 7 named asteroids:
  - **Pollux** — Castor's twin; nickel-iron mining outpost? Or another paired alien feature?
  - **Latro** ("robber") — secondary Outlaw operation; small fence / smuggler waypoint.
  - **Cautes / Petra** ("rock") — vanilla mineable bonanzas (each gets a primary resource).
  - **Custos** ("guardian") — old FED or ICE military bunker remnant? (links into [`future_ideas.md`](../world/future_ideas.md) — Military Bunker.)
  - **Speculum** ("lookout") — Outlaw sensor / spy outpost? OR alien observation array?
  - **Vallum** ("rampart") — fortified position; could be a captured pirate base or precursor defensive structure.
- [ ] Each composition is **lore-driven**, not random — names imply gameplay roles.

### 6.9 — Open design questions
*Live list in [`../world/world_resource_geography.md`](../world/world_resource_geography.md). Resolutions get folded back into this section as they're decided.*

### 6.9 — Future expansion phases (forward pointers)
Per [`../world/world_resource_geography.md`](../world/world_resource_geography.md) Expansion phases section:
- **Phase F** — Goldilocks zone (1–2 terrestrial planets; surface water; new jump gates)
- **Phase G** — Gas giants + Saturn-style rings + gas scoop mechanic
- **Phase H** — Outer cold (ice belt; cold-trapped helium-3 reservoirs; Outlaw territory by default)
- **Phase I** — Beyond Helion (multi-system support if/when the game expands)

These each get their own master to-do phases when authored. Don't start them ahead of dependencies (Phase 6.8 base-building + Phase 6.9 inner system) landing.

---

## Phase 6.10 — Base Building (T1 to Light Ship)
**Goal:** A new player spawns into a base scene with a **Drop Pod** (the only structure present), builds a Construction Yard, drops a T1 Outpost chassis, lays conduits, installs the production modules in T1 prereq order (paying material costs from base storage), and **produces a Light Ship from a Light Shipyard**. That is the explicit T1 win condition — completing this loop wraps the T1 base-building design pass.

Canon: [`../ground_base/progression_base_building.md`](../ground_base/progression_base_building.md) §§ 4–6 + § 5.E (Drop Pod bootstrap) + § 5.F (T1 win condition).

T2 chassis (HQ), T2+ modules, and the External Armor Layer (§ 7) are explicitly out of scope. Armor implementation lives in Phase 6.11 (below); T2+ is deferred per § 5.G.

### 6.10.A Freighter intro bootstrap (Outpost chassis + intro cinematic)

The Drop Pod chassis concept is gone — the bootstrap is now a scripted cinematic that delivers cargo crates and lets the player build the Outpost + CY in sequence. Canon: [`../ground_base/progression_base_building.md`](../ground_base/progression_base_building.md) § 5.E.

**Landed (this slice):**
- [x] [`Outpost_Starter.prefab`](../../Assets/Prefabs/Bases/Chassis/Outpost_Starter/Outpost_Starter.prefab) — assembled AMINT pieces (landing pad + drone hangar + station body + dock + dock-full-storage + hangar + extport + drone-hangar-doors + 2× BaseSnapNeck conduits centered at Y=0).
- [x] [`Outpost_Starter.asset`](../../Assets/GameData/Bases/Chassis/Outpost_Starter.asset) `BaseChassisSchema` (chassisID `chassis_outpost_starter`, baselinePower 50, baselineBeds 4, baselineFood 4, maxConnectorCount 2, maxModuleCount 4, tierMax 1, single Medium socket entry for Socket_Snap kind inference).
- [x] [`CinematicShip.cs`](../../Assets/Scripts/Macro/CinematicShip.cs) — generic scripted flight helper (FlyTo / Hover / FollowPath / LandOn).
- [x] [`DeliveryEvent.cs`](../../Assets/Scripts/Macro/DeliveryEvent.cs) — reusable freighter-delivers-cargo coroutine. Designed for both FTUE and recurring resupply.
- [x] [`IntroSequence.cs`](../../Assets/Scripts/Macro/IntroSequence.cs) — FTUE orchestrator. Auto-populates cargo manifest from `CivilianFreighterSpaceshipCollection/Prefabs/ScifiCargoContainers` folder.
- [x] Base.unity scene restructured — removed StartingBay + standalone Outpost instance + diagnostic CY; added `IntroSequence` GameObject wired with freighter / loader / frigate prefabs + Outpost + CY schema refs.
- [x] CY conduit position fix in [`DockingScaffoldD.prefab`](../../Assets/Prefabs/Bases/Docking/DockingScaffoldD/DockingScaffoldD.prefab) (BaseSnapNeck local X=-1.558 protruding past the scaffold's outer face).
- [x] CY prefab dead-fileID override cleanup (BaseSnapNeck root transform overrides on fileID `2113346330349532098` and m_Name override on fileID `5560148625838544363` removed — both were orphaned by a prior BaseSnapNeck.prefab rebuild).
- [x] [`BasePartInstance.Awake()`](../../Assets/Scripts/Macro/BasePartInstance.cs) auto-init for scene-baked BasePartInstance (kept; still useful for any prefab-baked tests even though the chassis goes through normal placement now).

**Still pending:**
- [ ] **Smuggler frigate landing pad name verification.** `IntroSequence.landingPadChildName` defaults to `station_hangar_centr_platform` — verify this matches the actual child name on the placed Outpost prefab. If the prefab's child is named differently (e.g. `station_hangar_central_platform`), update the default.
- [ ] **PlayerProfile.introCompleted flag** for skip-on-replay. Currently a BRIDGE in `IntroSequence.Start` — intro plays every scene load. Add the bool field to [`PlayerProfile.cs`](../../Assets/Scripts/Networking/PlayerProfile.cs), wire to PlayFab persistence, gate the `StartCoroutine(RunIntro())` call.
- [ ] **Cargo crates → ContainerInstance mapping** (Slice-1 inventory wiring). Crates are visual scene objects today; the proper path is each delivered crate becomes a `ContainerInstance` row (containerType `BaseStorageModule`, location `base:<bodyId>:cargo_drop`) written via `cloudscript/inventory.js`. Player drone construction would draw from the ContainerInstance as it consumes pieces. BRIDGE.
- [ ] **Crate-consumption visualization** during construction. Drone build lifecycle should shrink/dissolve crates as material is pulled. Hook into the existing `BasePartBuildTimer.cs` reveal animation pattern (reverse it — crates fade out as the built part fades in).
- [ ] **Optional**: `BaseBuildPanel.ForceSelect(BaseChassisSchema | FacilityModuleSchema)` API for guided pre-selection during the intro. Skipped for v1 — existing stage-hint text guides the player. Add if v1 testing shows the player gets lost picking from the full chassis list.
- [ ] **Recurring delivery trigger logic** — out of scope for this phase. Tracked as a forward pointer: when the player qualifies for or requests a resupply, fire the same `DeliveryEvent` component with a different cargo manifest. Phase 6.10.+ design.

#### Bridge code to remove (Phase 6.10.A)
- [ ] **`IntroSequence` plays on every scene load.** Flag with `// BRIDGE: remove when PlayerProfile.introCompleted lands` (already commented in `IntroSequence.Start`). Replaced by the PlayerProfile flag + persistence above.
- [ ] **`IntroSequence.PopulateDefaultCargoManifest` editor-only AssetDatabase scan.** Auto-population is `#if UNITY_EDITOR` only; for standalone builds the populated list must already be serialized into the scene. Flag with `// BRIDGE: remove when cargoDrops becomes addressable-loaded`.
- [ ] **Cargo crates as scene props, not ContainerInstance.** See pending task above. Flag with `// BRIDGE: remove when cargo→ContainerInstance CloudScript handler lands`.

### 6.10.B Module Catalog Consolidation (T1 only)
- [ ] Add `DoorState` enum + `doorState` field to [`FacilityModuleSchema.cs`](../../Assets/Scripts/Schemas/FacilityModuleSchema.cs).
- [ ] Add `BarrelArmament` enum + `barrelArmament` + `animatedBarrel` fields to `FacilityModuleSchema`.
- [ ] Add `BaseModuleCategory.Cosmetic = 7` enum value to [`BaseModuleCategory.cs`](../../Assets/Scripts/Schemas/BaseModuleCategory.cs).
- [ ] Move all `Top_*`, `CrewPart_*`, `SmugglerAdvertisement*`, `FiveStars` SOs into `Assets/GameData/Bases/Modules/T1/Cosmetic/`; set `category = Cosmetic`, `powerDraw = 0`, `crewRequired = 0`.
- [ ] Move generic mesh fragments (`IndustrialPart_03/05/06/08/09`, `Hangar_Central_Platform`, `Hangar_Controltower`, `Hangar_Extport`, `Hangar_Extport_Structure`, `Farmland2/3`, `Farm1/2/4`, `IndustrialSection`) into `Assets/GameData/Bases/ChassisPieces/`; remove from module pool.
- [ ] Merge Fighter Hangar SOs (`FighterHangarModule` + `FighterHangarModuleAnimated` + `FighterHangarForceField`) into one canonical SO with `doorState` variant.
- [ ] Merge Frigate Hangar SOs (`FrigateHangarModule` + `FrigateHangarDoorLower` + `FrigateHangarDoorUpper` + `FrigateHangarDoorAnimated`) into one canonical SO.
- [ ] Merge each Station Turret MKI/II/III family (body + all barrel variants) into one SO per MK with `barrelArmament` + `animatedBarrel`.
- [ ] Delete redundant SOs after merging; verify no `prefabAddress` lookup orphans remain.
- [ ] Audit: canonical buildable T1 module count lands between 15 and 25 (excluding Cosmetic, Chassis, Conduits). T2+ slots reserved in schema but not authored this phase.

### 6.10.C Tech Tree & Unlock Gates (T1 prereq map)
- [ ] Add `prereqModuleIds : List<string>` field to `FacilityModuleSchema`.
- [ ] Add `prereqSameCategoryAtPrevTier : int` (default 2) field to `FacilityModuleSchema` — stored but unenforced in Phase 6.10 since T2+ modules don't exist yet; field is in place for when T2 lands.
- [ ] Author T1 prereqs on every canonical T1 module per the table in [`../ground_base/progression_base_building.md`](../ground_base/progression_base_building.md) § 5.D.
- [ ] Write `Assets/Scripts/Networking/BaseModuleUnlockResolver.cs` — query player's `MacroBaseRecord` for built modules, return `UnlockState` per candidate.
- [ ] Wire [`BaseBuildPanel.cs`](../../Assets/Scripts/Bases/BaseBuildPanel.cs) to grey out locked modules + tooltip the missing prereqs.
- [ ] CloudScript handler for placement-confirm runs the same resolver — server-authoritative gate.

### 6.10.D Resource Costs (T1)
- [ ] Uncomment + activate `buildCost : List<RecipeInput>` field in [`FacilityModuleSchema.cs:78`](../../Assets/Scripts/Schemas/FacilityModuleSchema.cs).
- [ ] Author `buildCost` on every canonical T1 module per the ladder in [`../ground_base/progression_base_building.md`](../ground_base/progression_base_building.md) § 6.C. References existing `ResourceSchema` assets — no new material types needed.
- [ ] Author `buildCost` on Conduit SOs and the T1 Outpost chassis SO (raw alloys per § 6.B).
- [ ] Write `Assets/Scripts/Networking/BuildCostValidator.cs` — on placement, scan base bulk storage for sufficient `ResourceSchema` quantities; deduct or reject.
- [ ] Update [`BaseBuildController.cs`](../../Assets/Scripts/Bases/BaseBuildController.cs) to call validator; render red ghost + insufficient-materials tooltip on failure.
- [ ] CloudScript handler validates the same on the server side at placement-confirm.
- [ ] Drone visual: carry glowing crate(s) sized to load (cosmetic — no schema change).

### 6.10.E PlayFab Persistence
- [ ] CloudScript `BaseModuleInstall(baseId, moduleId, position, rotation)` — server-authoritative add to `MacroBaseRecord.installedModules`. Stamps integrity checksum (Double-Schema rule).
- [ ] CloudScript `BaseModuleUninstall(baseId, moduleInstanceId)` — remove + refund partial materials.
- [ ] CloudScript `BaseChassisUpgrade(baseId, fromChassisId, toChassisId)` — server-authoritative in-place chassis swap. Validates the source chassis is the player's current one, the target equals `source.upgradeTarget` (no skipping), and `upgradeCost` is paid from base storage. Updates `MacroBaseRecord.chassisID`; leaves `installedConnectors` and `installedModules` intact. Drop Pod is server-spawned at base creation, not player-installed.
- [ ] Wire [`LowOrbitBasePlacement.cs`](../../Assets/Scripts/Bases/LowOrbitBasePlacement.cs) `LowOrbitRosterClient` proxy to the actual CloudScript endpoints (currently stubbed per survey).
- [ ] Splice new handlers into [`cloudscript/_deploy_bundle.js`](../../cloudscript/_deploy_bundle.js); upload + update [`../architecture/architecture_cloudscript_deployed.md`](../architecture/architecture_cloudscript_deployed.md).

### 6.10.F T1 win-condition verification
- [ ] CloudScript `BuildLightShip(shipyardId)` — server-authoritative ship mint from a built Light Shipyard. Consumes shipyard inventory, outputs a `ShipInstance` to the player's fleet roster.
- [ ] End-to-end test: spawn fresh player into base scene → walk the 9-step T1 ladder per § 5.F → queue and complete a Light Ship build → ship appears in player's fleet roster. **This test passing = Phase 6.10 done.**

### 6.10.G Placed-module inspect & upgrade UI (Aaron 2026-05-23)
Goal: clicking a built module opens a side menu with picture + name + an upgrade picker. Each upgrade is a child module pre-defined per parent (e.g. Outpost ships with a known list of addon modules). Build cost is shown for the upgrade; if the player can't afford it, the button is disabled.

- [ ] **Schema:** add `availableAddons: List<FacilityModuleSchema>` to `BaseChassisSchema` and `FacilityModuleSchema` (an addon is itself a `FacilityModuleSchema` — it plugs into one of the parent's sockets). Cost data lives on the addon's own `buildCost` (authored per 6.10.D).
- [ ] **Click selector:** `BasePartInstance` raycast click handler — clicking a placed instance routes to a new `BasePartInspectPanel` (mirrors the existing `BaseBuildPanel` slide-in pattern).
- [ ] **Inspect panel UI:** portrait sprite + display name + per-addon row (name, cost line, "Install" button). Cost text reads from the addon's `buildCost`. Disabled when the inventory check fails (uses the same `BuildCostValidator` from 6.10.D).
- [ ] **Install action:** clicking an enabled addon triggers the existing connector / module placement path against the parent's free sockets. CloudScript `BaseModuleInstall` (already in 6.10.E) is the server commit.
- [ ] **Build-panel cost row (M2 from the session-pause split):** also surface `buildCost` text under each module / chassis button in `BaseBuildPanel` even before the inspect panel ships. This is the M1+M2 slice that was paused mid-implementation 2026-05-23 — pick up from the audit notes there.

### 6.10.H Surface manufacturing facilities + power model (Aaron 2026-06-06)
Goal: the production-tree facilities ([`../ground_base/progression_production_tree.md`](../ground_base/progression_production_tree.md)) exist on the SURFACE builder as `role=Facility` `BaseTileSchema` tiles, big machines reserve real grid footprints, and a base power model ties gas → power → the machines that draw it. Before this, the Forge was the only surface facility.

**Built 2026-06-06:**
- [x] **Multi-cell facility footprint system.** `BaseTileSchema.footprintCellsX/Z`; `SurfaceBaseAnchor.Footprint*` cell math (parity-aware: odd dim → cell-centre, even → corner); `SurfaceGridManager.RegisterFootprint` / `AreCellsFree` + footprint-aware `Unregister`; `BaseTileInstance.footprintCells`; `SurfaceTilePlacer.ResolveFootprintFacility` + N×M block ghost preview; `SurfaceBaseRenderer` re-reserves the block on load. A facility reserves cells at `layer+1` (the volume above the floor it rests on), so it can sit on a floor while nothing overlaps its body. 1×1 facilities (the Forge) keep the old single-point path, unchanged.
- [x] **Gas Generator T1** surface Facility tile ([`Tile_Generator_T1.asset`](../../Assets/GameData/Bases/SurfaceTiles/T1/Tile_Generator_T1.asset), 3×3, `placementScale` 1.55, INDUSTRY tab → "Power" section). `BaseBuildPanel` INDUSTRY tab now groups facilities under `menuSection` dividers.

**Deferred (own design pass — the "runtime backbone"):**
- [ ] **Surface power/gas grid SIM.** Add power/gas stat fields for `role=Facility` tiles (`powerOutput`, `powerDraw`, `gasDrawPerMin` — units TBD). Base power budget: sum reactor/generator output vs. facility draw; brown-out machines when over budget (the "Capacitor Grid", [`../ground_base/progression_base_building.md`](../ground_base/progression_base_building.md) § 2.C). Gas consumption pulled from gas tanks through the pipe network. **The Generator is a placeable shell until this lands.**
- [ ] **Generator `buildCost`** — empty stub today; author with the § 6.10.D cost pass (grade-agnostic `BuildCostRow`, tons).
- [ ] **Bring the rest of the spine onto the surface** as Facility tiles from the Sci-Fi Base machine meshes, each with its `menuSection`: Fusion Reactor (Power), Smelter (Mint), Refinery (Metallurgy), Gas Plant (Gas/Cryo), Foundry Lab (Synthesis). Decide reuse-orbital-logic vs. surface-native per facility. Canon: progression_production_tree.md § 2 + § 7.
- [ ] **Gas storage tanks** as the Generator / Gas-Plant input buffer (the pack's Tank meshes; the `Tank` bulk-import category already maps to `Facility`).

### Bridge code to remove (Phase 6.10)
- [ ] **"All modules always available" stub.** [`BaseBuildPanel.cs`](../../Assets/Scripts/Bases/BaseBuildPanel.cs) currently lists every `FacilityModuleSchema` regardless of prereqs/cost — flag with `// BRIDGE: remove when BaseModuleUnlockResolver lands` when adding the resolver call. Resolver lands in § 6.10.C.
- [ ] **In-memory placement (no save/load).** [`BaseBuildController.cs`](../../Assets/Scripts/Bases/BaseBuildController.cs) — placed modules vanish on scene reload. Flag with `// BRIDGE: remove when CloudScript install handlers land`. Replaced by § 6.10.E CloudScript handlers.
- [ ] **`PlayerProfile.smelterLevel / labLevel / minerLevel` flat fields** (already tracked at line 70 above as a Slice 2 bridge — same removal moment as § 6.10.C, since the resolver makes per-base facility-tier scanning live). Cross-reference confirmed: one work item resolves both.
- [ ] **Sci-Fi Base bulk import — pipes/cables as `Decorative`.** [`SciFiBase_BulkImport.cs`](../../Assets/Editor/SciFiBase_BulkImport.cs) imports the pack's 52 Pipe + 15 Cable pieces as grid-snapped `Decorative` placeables (flagged `// BRIDGE:`). Upgrade Pipes to `Pipe` role + `PipeEnd` end-snap sockets and Cables to the `ConduitHolder`/Run-Wire flow in the dedicated pipes+wires batch. (`tile_sfb_*` under `Assets/GameData/Bases/SurfaceTiles/SciFiBase/{Pipe,Cable}`.)
- [ ] **Sci-Fi Base bulk import — 96 structural fragments deferred.** `SciFiBase_BulkImport` skips wall corners / ends / L-R halves / windows / doors / joints (anything failing `IsCleanStraight`) rather than dump them as broken flat 8×8 walls. They need corner/multi-cell socket support the 8 m grid doesn't model yet — author as a curated corner/opening batch (extends § 6.10 structural). Re-run the importer after `IsCleanStraight` / socket support changes.

---

## Phase 6.11 — Base External Armor Layer
**Goal:** Base modules can be clad in HP-bearing angled-half-hex armor plates that absorb raid damage; destroyed plates are repaired post-encounter by drones. First true "absorb" defense layer for bases — until this lands, base survivability is turrets + module HP only.

Canon: [`../ground_base/progression_base_building.md`](../ground_base/progression_base_building.md) § 7.

Depends on Phase 6.10 landing (modules, conduits, drone pipeline must all be live) and intersects with Phase 4 combat for the damage-routing tick. **Land after Phase 6.10 ships the T1-to-Light-Ship loop.**

### 6.11.A Schema + sockets
- [ ] Create `Assets/Scripts/Schemas/BaseArmorPlateSchema.cs` per canon § 7.B.
- [ ] Create `Assets/Scripts/Tactical/ArmorSocket.cs` MonoBehaviour.
- [ ] Create `Assets/Editor/BaseArmorSocketBuilder.cs` — auto-tile ArmorSockets on prefab exterior faces (mirror of [`BaseSnapNeckBuilder.cs`](../../Assets/Editor/BaseSnapNeckBuilder.cs)).
- [ ] Run the builder over every canonical T1 module + conduit prefab + Drop Pod + T1 Outpost prefab; commit the generated ArmorSocket children.

### 6.11.B Plate authoring
- [ ] Author armor plate prefab (angled half-hex geometry — model in Blender, import via OBJ roundtrip if the source vendor is ASCII FBX per [`project_ascii_fbx_scifi_military.md`](../../../.claude/projects/C--Users-Aaron-Apex-Outlaw-Apex-Outlaw-Client/memory/project_ascii_fbx_scifi_military.md); importer scaled per [`feedback_blender_fbx_scale.md`](../../../.claude/projects/C--Users-Aaron-Apex-Outlaw-Apex-Outlaw-Client/memory/feedback_blender_fbx_scale.md)).
- [ ] Author T1/T2/T3 armor plate SOs in `Assets/GameData/Bases/ArmorPlates/`.

### 6.11.C UI + placement
- [ ] Add "Armor" tab to base build panel; auto-conform-to-face placement flow per § 7.D.
- [ ] Drone armor install flow — reuse [`BaseDroneFleet.cs`](../../Assets/Scripts/Bases/BaseDroneFleet.cs) lifecycle, plate is the cargo.

### 6.11.D Combat + repair
- [ ] Combat damage routing per § 7.E — extend whatever combat-damage handler exists at the time (Phase 4 dependency).
- [ ] Drone armor repair flow — same drone lifecycle as install, triggered by destroyed-plate event (queued during combat, dispatched post-encounter per § 7.F).

### 6.11.E Persistence + gating
- [ ] CloudScript `BaseArmorPlateInstall(baseId, socketId, plateId)` — server-authoritative add to ArmorSocket; checksum stamping.
- [ ] Armor tech tree gating per § 7.G (Defense modules required).

### 6.11.F Walled-bases pivot (design exploration — prototype)
**Goal:** Validate an Anno/Frostpunk-style walled-base layout before committing the pivot. A throwaway prototype scene (`Assets/Scenes/base_test.unity`) lets the player feel wall placement at RTS scale — bounded plot, Minecraft-style invisible block grid, gray walls flush with cube faces. If the feel is right, the rest of Phase 6.11 above gets re-shaped: walls become the primary structural defense layer (HP, raidable), small modules go interior, large modules stay exterior. Decision is design-gated, not code-gated.

- [ ] Open `base_test.unity` → orbit camera + planet backdrop render → click to place gray walls on the invisible 50×50×20 grid → assess scale (2 m cells by default; tune the `BlockArea` cellSize in-inspector if it reads wrong).
- [ ] **Decision point:** If the walled-base feel wins → write a Phase 6.11 re-shape plan that turns plates into walls + adds `EnvironmentTag` (Interior/Exterior) to `FacilityModuleSchema`. If it loses → fall back to the existing 6.11.A–E armor-plate scope and delete the prototype.

#### Bridge code to remove (Phase 6.11.F — walled-bases prototype)
Per [`../../CLAUDE.md`](../../CLAUDE.md) "Building durably — no throwaway code", this prototype is scaffolding only; every file below is throwaway and must be deleted when the decision above resolves.

- [ ] **`Assets/Scenes/base_test.unity`** — prototype scene. Delete when the walled-bases design is locked in (or rejected).
- [ ] **`Assets/Scripts/Macro/BlockArea.cs`** — prototype-only voxel grid. Delete with the scene.
- [ ] **`Assets/Scripts/Macro/BlockBuildController.cs`** — prototype-only wall placement. Delete with the scene.
- [ ] **`Assets/Scripts/Macro/BackdropPlanetLoader.cs`** — prototype-only standalone planet spawn (mirrors `BaseBuildController.SpawnBackdropPlanet` so we don't pull in the full live build system). Delete with the scene.
- [ ] **`Assets/Scripts/UI/WallPalettePanel.cs`** — prototype-only programmatic UGUI palette that auto-discovers walls from `Assets/Prefabs/Bases/Test/` via AssetDatabase. The real walled-bases palette will read from the schema-driven catalog (`WallSegmentSchema`), not a folder scan. Delete with the scene.
- [ ] **`Assets/Scripts/Macro/WallSnapPoints.cs`** — prototype-only base-corner snap-point holder. The real walled-bases system bakes snap topology into the schema itself. Delete with the scene.
- [ ] **`Assets/Editor/BuildBaseTestScene.cs`** — one-shot scene builder (`Apex Outlaw > Prototype > Rebuild base_test scene`). Delete with the scene.
- [ ] **`Assets/Prefabs/Bases/Test/`** — entire prototype folder: shared `Wall_Steel_Gray_Mat.mat`, 10 wall variants (`Wall_Straight_Gray`, `Wall_Half_Gray`, `Wall_Doorway_Gray`, `Wall_Corner_Gray`, `Wall_Angle_45_Gray`, `Wall_Angle_22_Gray`, `Wall_Angle_30_Gray`, `Wall_Stub_Gray`, `Wall_Crossbar_Gray`, `Wall_Triangle_Gray`), and the procedural mesh `Wall_Triangle_Gray_Mesh.asset`. Delete the whole folder with the scene.
- [ ] **`BaseBuildOrbitCamera.suppressAllMovementKeysDuringPlacement` flag** — added so the prototype scene can release WASD/QE/RF to `BlockBuildController` for wall rotation. The flag itself stays in the live camera (default false = legacy behaviour) but the `BlockBuildController` OR-check in `HandleKeyboard` can be removed once the prototype is gone.

---

## Phase 6.12 — Wire / Conduit Power Routing
**Goal:** Players route power from sources to facilities with hideable **conduit-holders** + **black wire splines**
(straight / curved / floor-sag), bundle wires in **1/3/5-slot brackets**, pass wires **through walls**, and rely on
**multiple sources for redundancy**. First system that makes a base's power *physical and attackable* — cut the
wire or kill the generator and things go dark.

Canon: [`../ground_base/progression_wiring.md`](../ground_base/progression_wiring.md). Depends on the surface-base
tile system (Phase 6.9) + facility-module power fields (`FacilityModuleSchema.powerDraw/powerProvided`, currently
UI-only — this phase wires the runtime eval). **Design decisions resolved 2026-06-01** — see the wiring doc's "Resolved decisions"; ready to build.

> **STATUS (2026-06-02) — resume here.** 6.12.0 / A / B / C **+ the two-look batch are committed** (`2d5b968` onward):
> ONE 5-slot **"Conduit Clamp"** (3/5 brackets hidden); **clamp→clamp = a round steel PIPE tube** with **fully
> axis-aligned (orthogonal) bends — no diagonal legs**; **loose runs = the black SAGGING wire**; clamp highlight
> (blue / yellow-ceiling); delete-anywhere. The batch also landed **floor-peel for wires/pipes** (they hide with the
> level like tiles). **The full done / next state + gotchas live in the wiring doc's "Implementation status / handoff
> (2026-06-02)" — read that first.** **6.12.D + the clamp re-theme (#3) are committed (clip = steel U-saddle clamps).
> Next: #13 wall-clip → #8 ceiling + yellow-ghost → #7 gravity-fall → 6.12.E PowerNetwork (needs a generator/power tile first).

### 6.12.0 Prerequisite — Level view culling (floor peel)
- [x] Surface-builder view feature (general, not wiring-specific): Shift+W/S sets the active level and **hides all
  structure above it** (full peel) so wires/rooms on lower floors are visible to build/route. Tied to
  `currentBuildLayer`; per-tile GameObjects already carry `layer` + `schema.role`, so it's a visibility toggle over
  `layer > currentBuildLayer`, not a new subsystem (a small `SurfaceBaseLevelView` helper subscribing to the level
  change). Canon: [`../ground_base/progression_base_building.md`](../ground_base/progression_base_building.md) § 8.

### 6.12.A Conduit brackets (×3) + menu placement
- [x] Author **three** `BaseTileSchema` brackets with the new **`ConduitHolder` `TileRole`** (excluded from the
  stability graph) + new `TileSocketKind`s for wall/ceiling/floor mounting, each with a wire-rail axis: **Conduit
  Clip** (`slotCapacity = 1`), **Conduit Bracket 3-wire** (`= 3`), **Conduit Bracket 5-wire** (`= 5`). Placeholder
  prefabs first (thin rail + N marked slots), themed later via the `theme-base-part` skill. Reuses `SurfaceTilePlacer`
  — verify snap == an existing wall.
- [x] **Menu home = `Power` category of Main Parts**, beside the reactors (not a standalone tab, not a themed
  surface-tile tab). Cross-list the brackets + wall-plug into the `Power` tab in `BaseBuildPanel`; `DraggableCard`
  already routes `BaseTileSchema` cards to `SurfaceTilePlacer.SelectSchema`.

### 6.12.B Wire routing tool + editing + persistence
- [x] **Run Wire** mode card in the `Power` tab arms `WirePlacer` (`WirePlacer.cs` + `WireToolCard.cs` +
  `BaseBuildPanel.BuildWireToolCard`, cross-listed beside the brackets). **Freeform "wire the home" model
  (revised 2026-06-01):** click-to-start (conduit slot / ground) → **each empty-space click drops a curve point and
  the run keeps going**; it **stops** only on **(A)** plugging into a conduit or **(B)** right-click / Esc (loose end).
  Both ends may be loose; a wire connects two endpoints (chain brackets = a wire per hop). *Routing uses ConduitSlot + Loose only
  this session — Source/Consumer hit-test is dormant until power tiles exist (→ 6.12.E). Segment-shape derivation
  (off-axis→curve, unsupported/loose→catenary sag) is **6.12.C**; this session renders **straight** segments.*
- [x] **Wire editing:** **drag** a loose end onto a free slot to plug it (full bracket rejects — not clickable);
  **click a loose end to extend**; **delete** via Shift+RMB + red preview — aim at the dangling tail trims to the
  **last connected conduit**, aim at the origin deletes the **whole wire**. (Wire tool owns Shift+RMB; the tile
  placer's delete + red tile-hover yield while `WirePlacer.ToolArmed`.)
- [x] **Data + persistence:** `WireRecord` = ordered `List<WireNode>` (`Source|Consumer|ConduitSlot|Loose`), not a
  fixed from/to. Added `wires[]` to `SurfaceBaseRecord`; `SurfaceBaseStore.AddWire/RemoveWire/UpdateWire` +
  `OnWireAdded/Removed/Changed`; `SurfaceBaseRenderer` spawns/redraws on change (minimal straight `LineRenderer` —
  curves/sag/bundling = 6.12.C). `PowerNetwork` BFS (loose end = open circuit) is 6.12.E. *(Cursor→world ray
  extracted to `SurfaceCursorRay.cs`, shared by the tile placer + wire tool.)*

### 6.12.C Spline renderer + sag + bundling
- [x] `SurfaceBaseRenderer` samples each wire as a black spline: **Catmull-Rom** through the nodes (collinear → straight),
  **catenary sag** on segments with a Loose endpoint (clamped to the lower endpoint so a floor run can't sink below
  it; bracket↔bracket stays taut), and **bundling** — added `railWidth` to `BaseTileSchema` (set by `WireConduit_T1_Setup`,
  re-baked: clip 0.3 / 3-wire 0.65 / 5-wire 1.0) and each bracket's *k* strands fan parallel at spacing
  `railWidth / slotCapacity` (`NodeLocalPos`), seated on the bracket's outer face so the wire clears the mount surface.
  v1 = *k* offset `LineRenderer`s (tube mesh → v2). Loose/ground points lifted `groundClearance` above terrain so they
  render ON the surface, not buried. Tunable: `wireWidth` / `wireSagFactor` / `wireMaxSag` / `wireSamplesPerSegment`.
  *(Flow-shader "power flowing" effect → deferred polish.)*

### 6.12.D Wall pass-through — via paired clamps (revised 2026-06-02, Aaron)
- [x] **No separate plug part** — the clamp is multi-functional. A clamp placed on a wall's **opposite face** snaps
  into alignment across the wall (`SurfaceTilePlacer.SnapAcrossWall`); a wire routed into one crosses straight through to
  the aligned clamp on the far face (`SurfaceBaseRenderer.ClampExitDir` exits along the mount normal for a through-wall run).
  **DONE 2026-06-02** — implicit (any aligned opposite-face pair a wire links crosses). Same commit also fixed corner routing
  to HUG the clamp faces (inside-corner turn) so a run can't cross to the back of a wall.
- [x] **Clamp re-theme** — DONE 2026-06-02: in-place reskin, the clip is now 5 steel U-saddle clamps (Blender FBX via
  `WireConduit_T1_Setup` → `BakeThemedFbxPrefab`); snap contract unchanged. SciFi Warehouse Kit `structure_props` palette.

### 6.12.E PowerNetwork (runtime — net-new)
- [ ] v1 connectivity graph (consumer powered iff unbroken path to a live source; redundancy via multiple sources;
  recompute on wire/source break). v2 capacity (provided vs drawn). Gate consumer activation on live power.

### Bridge code to remove (Phase 6.12)
- [ ] **In-memory wire/power persistence** — `WireRecord`s + power links live in `SurfaceBaseStore` only (same
  BRIDGE as surface tiles). Flag `// BRIDGE: remove when CloudScript surface-base persistence lands`; migrate with
  the Phase 6.9 PlayFab push.
- [ ] **`prefabAddress` AssetDatabase paths** on the holder/plug schemas — Addressables not wired yet (same bridge as
  all surface tiles); migrate when the Addressables pipeline lands.
- [ ] **`WirePlacer` Source/Consumer hit-test is dormant** — routing uses ConduitSlot + Loose only (the `Source`/
  `Consumer` `WireNodeKind`s are typed but nothing clickable provides/draws power on the surface yet). `// BRIDGE:`
  in `WirePlacer.cs`; wire the source/consumer pick when power-bearing surface tiles exist (Phase **6.12.E**).

---

## Phase 7 — Content, Polish, Launch Prep (post-MVP)
**Goal:** A first-time player can install the build, log in, fly through a tutorial loop, and leave with the impression of a finished game. Pre-launch hygiene.

*This phase is intentionally light on detail — flesh it out as Phase 5/5.5/6 land and the real gaps surface. Below are the predictable buckets, not exhaustive subtasks.*

- [ ] **7.1 First-time-user experience (FTUE):** New-account starter loadout, scripted intro fight, alchemy lab tutorial, first sector jump.
- [ ] **7.2 NPC content:** Pirate / freighter / police behavior trees populated per [`../world/world_npc_ai.md`](../world/world_npc_ai.md). Wave/encounter authoring.
- [ ] **7.3 Hull & weapon catalog fill:** Author the rest of [`../ships/ships_hulls_classes.md`](../ships/ships_hulls_classes.md) and [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md). Balance pass against combat math (Phase 4).
- [ ] **7.4 Audio & VFX pass:** Apply [`../world/world_audio_vfx.md`](../world/world_audio_vfx.md) — vibration audio in vacuum, flash explosions, no fiery plasma. Hooked into combat events.
- [ ] **7.5 Monetization wiring:** Cosmetic shop, "FED License" subscription per [`../economy/economy_monetization.md`](../economy/economy_monetization.md).
- [ ] **7.6 Live-ops infrastructure:** Crash reporting, telemetry, player support flow, server-status notifications (already partly Phase 2).
- [ ] **7.7 Pre-launch testing:** Closed playtest → open beta → soft launch. Stress-test the 3v3+10 instance cap under organic traffic.
- [ ] **7.8 Bridge-code sweep:** Walk every "Bridge code to remove" subsection and confirm each one has either landed or has a shipped replacement. **Nothing labeled "BRIDGE" should ship to launch.**

---

## How this list evolves
- New phases are added in numerical order. If new work fits between two existing phases, use a fractional number (e.g. 4.5, 5.5) — that's already the convention.
- When a sub-task is complete, mark `[x]` and leave it in place for grep-ability. Don't delete completed history; the file is small enough to scroll.
- "Bridge code to remove" subsections are mandatory whenever a phase introduces a temporary scaffold. Per [`../../CLAUDE.md`](../../CLAUDE.md), every bridge must be code-flagged, listed here, and time-boxed to a specific phase.
