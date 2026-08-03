# Economy — Category Overview

Apex Outlaw's economy is the spine of the game. Because there is no character XP, *every* progression curve runs through the economy: gear quality, base building, alliance reach. Specialization (Researcher / Miner / Transporter / Pirate / Mercenary) only matters because the economy forces interdependence.

> **Phase 6.9 economic asset placement (2026-05-29):** Player surface bases (smelters, forges, drone bays, refineries, storage) now live as **3D world objects in the Surface scene (Scene 3)** at registered (lat, lon) on the planet's terrain mesh. The old 2D arc-based placement is retired. **Production activity emits radar noise** via `BaseNoiseEmitter` — running a smelter / forge / drone build broadcasts to nearby enemy sensors. Silent bases stay off the radar but remain visually discoverable. Defenders balance economic throughput against radar exposure. Canon: [`../world/world_surface_scene.md`](../world/world_surface_scene.md), [`../ground_base/progression_base_building.md`](../ground_base/progression_base_building.md).

> **2026-07-05 — resource roster + composite-ore mining canon:** the material roster exists
> to feed the BLIND tech tree (ingredient variety = the crucible's puzzle alphabet), and
> mining is COMPOSITE — one run yields several materials at once, weighted by location
> ("some ground runs copper-rich, some iron-rich"; no per-material mine hunting). Census,
> guardrails, and the proposed roster trims live in
> [`economy_resources_roster.md`](./economy_resources_roster.md).

## Foundational principles

These three principles are the *why* of the economy — every concrete mechanism downstream serves one or more of them.

1. **The 12,345 Alchemy Matrix** — Every player has a unique seed. Each element (Iron, Helium, etc.) is a 10,000×10,000 heatmap; ~95% is junk, ~5% holds peaks up to a hidden value of 12,345. Final stats lerp between min and max by `quality / 12345`. Synthesis (e.g. Iron + Carbon = Steel) unlocks new heatmaps. Per-player seeds mean coords *cannot* be shared — the only way to benefit from another player's research is to **trade their output**.
2. **Specialization without level-gating** — Roles are gear and territory, not XP. A Researcher never has to fight; a Miner never has to research; a Transporter risks cargo through dangerous space; a Maker / Forger stakes reputation on the quality of what they ship. The economy's interdependence is what forces collaboration.
3. **Physical-presence trading** — Goods listed for sale must physically be at a Bank Terminal. Buyers can purchase from anywhere, but they (or a hauler) must travel to collect from the per-hub pickup queue. Geography matters; teleporting cargo never happens; the Transporter role exists because of this.

> **Load-bearing rule:** Stealing a component gets you *that component* (fittable, repairable, sellable) — never a manufacturing blueprint. The only path to *producing* new high-quality modules is the Matrix Scanner research path, keyed to the Researcher's own Seed. Pure-combat players who never research are **permanent customers** of the market and the wreck-economy. This is by design and it's what keeps Researchers economically valuable. See [`economy_alchemy_research.md`](./economy_alchemy_research.md) §4 for the full canon.

## System layers (concrete mechanisms)

The principles above are realised by these concrete systems, stacked roughly bottom-up:

1. **Inventory & Storage** — Location-bound containers, mass caps, auto-sort. Schema implemented in slice 1. Canon for downstream: every subsequent system reads/writes inventory through this layer.
2. **Universal DOM Exchange** — Two-sided order book (Bid/Ask), Market/Limit/Stop orders, price-time priority matching, **hidden admin floor/ceiling** ("invisible hand") that defends per-hub price bands. Applies to currencies, commodities, AND graded modules — one engine, every market. See [`economy_exchange_pricing.md`](./economy_exchange_pricing.md).
3. **Bespoke listings + Maker's Mark** — Player-forged items carry an immutable forger identity that travels through every resale. Bespoke listings preserve specific instances (custom name, paint, fitted modules, combat record); fungible listings commoditize at the grade level. `MakerProfile` reputation is emergent from data — no admin-curated rankings. See [`economy_exchange_pricing.md`](./economy_exchange_pricing.md) §5 "Bespoke" / "Maker's Mark".
4. **Regional pricing + NPC auto-arbitrage** — Per-hub floors/ceilings set with regional logic (cheap near sources, expensive at consumption hubs). NPC miners + NPC transports physically maintain the flow; AI transports are predictable pirate prey. See [`economy_npc_arbitrage.md`](./economy_npc_arbitrage.md).
5. **Freight contracts** — Formal commission mechanism for the Transporter role. Post → claim → ship → deliver → pay, with cargo + payment + optional hauler collateral all escrowed. Drives the alliance shipment manifest that Supply-Chain Tap (T3 hacking) reads. See [`economy_freight_contracts.md`](./economy_freight_contracts.md).
6. **Black market + clean-goods doctrine** — Hidden trading posts that accept restricted ordnance, stolen goods, and Outlaw-doctrine items. The `stolenFrom` provenance tag is **territory-dependent** — piracy in patrolled space tags loot, piracy in Outlaw space leaves loot clean. See [`economy_exchange_pricing.md`](./economy_exchange_pricing.md) §5 + [`../world/world_territory_bubbles.md`](../world/world_territory_bubbles.md).
7. **Obligations layer (loans + tax + permits)** — Faction loans (reputation-gated, three-tier default escalation ending in unwinnable raid fleet), weekly planet tax (defeatable tax collectors), alliance resource permits (patrol enforcement). Every obligation runs through the **Weekly Economy Tick**. See [`economy_obligations.md`](./economy_obligations.md).
8. **Repair system** — Restores durability to `1.0` so damaged items can be DOM-listed. Facility tiers: faction hubs (mainstream-only), alliance citadels (member discount), black markets (accept anything, 20% premium). See [`economy_exchange_pricing.md`](./economy_exchange_pricing.md) §5.
9. **60-day data retention** — Transient transaction records (trades, closed orders, payments, hacking events) auto-prune after 60 days. Long-lived aggregates (MakerProfile, HaulerProfile, daily VWAP, per-player counters) survive forever. See [`economy_exchange_pricing.md`](./economy_exchange_pricing.md) §10.

## Key constants (don't reinvent these — link the doc)
- **12,345** — quality cap / lerp denominator. See [`economy_alchemy_research.md`](./economy_alchemy_research.md).
- **35%** — Federation tax on hub sales. See [`economy_trade.md`](./economy_trade.md) and [`economy_exchange_pricing.md`](./economy_exchange_pricing.md).
- **3%** — Universal market escrow on standard hubs. (Black markets bypass this.) See [`economy_trade.md`](./economy_trade.md).
- **25%** — Hard ceiling on alliance-set non-member planet toll. See [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) §4.5.
- **5% / 0.5% / 0.1%** — Storage fee defaults: legacy restocking-on-withdrawal (5%), mainstream weekly parking (0.5%), black-market weekly parking (0.1%). See [`economy_exchange_pricing.md`](./economy_exchange_pricing.md) §5.
- **±50%** — Default price band around volume-weighted clear price for liquid markets. Per-market admin override. See [`economy_exchange_pricing.md`](./economy_exchange_pricing.md) §3.5.
- **60 days** — Data retention window before transient records aggregate + prune. See [`economy_exchange_pricing.md`](./economy_exchange_pricing.md) §10.

## Implementation status (what's in code vs. paper)

The economy canon above is *richly designed* but unevenly *implemented*. Honest status:

**In code (live):**
- **Inventory & Storage** — slice 1 of the original 5-slice plan. Location-bound containers, mass caps, auto-sort, server-authoritative CloudScript handlers, basic inventory UI. Schemas at [`ContainerSchemas.cs`](../../Assets/Scripts/Schemas/ContainerSchemas.cs), CloudScript at [`cloudscript/inventory.js`](../../cloudscript/inventory.js), client wrapper at [`InventoryClient.cs`](../../Assets/Scripts/Networking/InventoryClient.cs), UI at [`Assets/Scripts/UI/Inventory/`](../../Assets/Scripts/UI/Inventory/). Plan file: `~/.claude/plans/looking-at-the-game-glowing-piglet.md`.
- **Slice 3a — schema + checksum + forge mint** — `PartInstance` carries `forgerPlayFabId`, `forgerDisplayName`, `currentDurability`, `stolenFrom`, all now covered by the v3 `IntegrityChecksum` domain on both C# and CloudScript sides ([`PlayerProfile.cs`](../../Assets/Scripts/Networking/PlayerProfile.cs), [`cloudscript/inventory.js`](../../cloudscript/inventory.js)). One-shot v2→v3 migration in `ValidateAll` re-stamps legacy saves on first login. `ForgePartInstance` CloudScript handler ([`cloudscript/forge.js`](../../cloudscript/forge.js)) is the canonical mint primitive (used by Slice 2 recipes once they land); dev-seed grants use the in-process `PartInstance.ForgeSystem` factory with the SYSTEM forger sentinel. `InventoryInsert` / `InventoryMove` reject any client-introduced non-default Maker's Mark whose checksum doesn't pre-validate (`INVALID_INSTANCE_ORIGIN`). **Pending:** combat-driven durability writes (Phase 4 Fusion→PlayFab path), repair handler, `stolenFrom` mutation (piracy / laundering), MakerProfile aggregation — all tracked in `master_to_do.md` Phase 5+.
- **Slice 2 — Production foundation (Recipes & Refining)** — `RecipeSchema` ScriptableObject ([`Assets/Scripts/Schemas/RecipeSchema.cs`](../../Assets/Scripts/Schemas/RecipeSchema.cs)) + 14 authored canon Tier-2 recipes under [`Assets/Resources/Schemas/Recipes/`](../../Assets/Resources/Schemas/Recipes/) (Steel, Ferro-Titanium, Nickel-Iron Plating, Electrum Wire, Gold Ingot mint, Scrap refining w/ byproducts, Carbon-Fiber Glass, Thermal Paste, Super-Conductor, Ion Plasma, Synthetic Polymer, Ammonia, Aerogel Mesh, Radar-Absorbent Pigment). 30+ canon Tier-1 / Tier-2 `ResourceSchema` assets seeded under [`Assets/Resources/Schemas/Resources/`](../../Assets/Resources/Schemas/Resources/). Server-authoritative `RunRecipe` CloudScript handler ([`cloudscript/recipes.js`](../../cloudscript/recipes.js)) validates inputs, scales by run count, enforces a per-facility-type tier gate (`Refinery` / `Lab` / `Miner` / `Forge`), reuses inventory.js mass math, and emits resource adds (and reserved module-mint slot via `forge.js`). Client wired through `RecipeClient.Run` ([`Assets/Scripts/Networking/RecipeClient.cs`](../../Assets/Scripts/Networking/RecipeClient.cs)) and `RecipeCatalogLoader` ([`Assets/Scripts/Schemas/Catalog/RecipeCatalogLoader.cs`](../../Assets/Scripts/Schemas/Catalog/RecipeCatalogLoader.cs)). Minimal `ForgePanel` + `RecipeRow` UI under [`Assets/Scripts/UI/Forge/`](../../Assets/Scripts/UI/Forge/) — un-met-tier rows render greyed so players see the upgrade path. Dev seed bumped to grant the Tier-1 canon raws so recipes round-trip on a fresh account. **Pending:** per-recipe unlocks / tech-tree gating (Slice 3), graded-module fabrication recipes (later slice when alchemy matrix lands), per-base facility installations (Phase 6.8 — flat per-player level fields on `PlayerProfile` are the explicit bridge today).

**Paper-only canon (designed, not yet built):**
- DOM exchange engine + matching + price bands + invisible hand
- Currency model expansion (`pactCredits` → already `federationCredits` post-rename; `iceCredits` field needs adding)
- Bespoke listings + MakerProfile aggregation
- Bank Terminal access enforcement + pickup queue
- Storage fees + Weekly Economy Tick scheduler
- Repair system
- Freight contracts + HaulerProfile aggregation
- NPC arbitrage (HubStockLevel + AI transports + NPC miners)
- Obligations layer (loans + tax + permits + three-tier NPC enforcement)
- Hacking modules + intel routing
- Stolen-goods provenance tracking + black market + laundering
- 60-day data retention + daily aggregation job
- Territory bubble model (depended on by NPC arbitrage cross-faction filter, clean-goods rule, patrol response)

All of the above is tracked deliverable-by-deliverable in [`../meta/master_to_do.md`](../meta/master_to_do.md) Phase 5+ Economy section.

**Recommended next implementation slice (Slice 3 — Market Infrastructure):**
DOM engine + currency migration + price bands + bank-terminal access + storage fees + Weekly Economy Tick framework. Unlocks the most downstream gameplay per unit of engineering work. Mining mechanics + refining process design can run in parallel (pure canon work, no implementation contention) and unblock Slice 2 (Production Foundation) afterward.

## Docs in this category

| Doc | Purpose |
|---|---|
| [`economy_trade.md`](./economy_trade.md) | Taxes, transporter risk, escrow, sub-space comm intel. (Pricing model superseded by `economy_exchange_pricing.md`.) |
| [`economy_exchange_pricing.md`](./economy_exchange_pricing.md) | **Universal DOM order-book** — Bid/Ask, Market/Limit/Stop orders, matching engine, hidden admin floor/ceiling. Applies to currencies, commodities, and module markets. |
| [`economy_obligations.md`](./economy_obligations.md) | **Faction loans + planet tax + resource permits** — the governance layer. Reputation-gated borrowing, weekly tax to planet owners, alliance-issued harvest licenses, escalating NPC enforcement (patrols, tax collectors, unwinnable default raid fleets). |
| [`economy_freight_contracts.md`](./economy_freight_contracts.md) | **Freight contracts** — the Transporter role's primary gameplay loop. Contract lifecycle (post → claim → ship → deliver → pay), escrow on both cargo and payment, hauler collateral, reputation-as-service-economy, integration with Supply-Chain Tap intel. |
| [`economy_npc_arbitrage.md`](./economy_npc_arbitrage.md) | **NPC auto-arbitrage** — trading posts as autonomous economic agents. Detect own stock shortages → scan other hubs via DOM → dispatch AI transport ships to physically move goods. Solves NPC seed liquidity, self-maintains regional pricing, generates recurring pirate prey, coexists with player Transporters by niche. |
| [`economy_monetization.md`](./economy_monetization.md) | Real-money model — cosmetics, "FED License" subscription, what's not for sale. |
| [`economy_alchemy_research.md`](./economy_alchemy_research.md) | The 12,345 peak-scanning system — heatmap math, false peaks, distraction nodes. |
| [`economy_alchemy_tech_tree.md`](./economy_alchemy_tech_tree.md) | Synthesis paths from raw elements through processed goods to Exotic Void-Steel. |

## Where this category sits in the build order
Economy was nominally Phase 5 in [`../meta/meta_roadmap.md`](../meta/meta_roadmap.md), but the canon has grown substantially and the implementation order is now slice-driven rather than phase-driven. Slice 1 (Inventory) is in code. Slice 3 (Market Infrastructure — DOM, currency, bank terminal, storage fees, weekly tick) is the recommended next implementation push and doesn't depend on combat being live. The Alchemy engine ([`economy_alchemy_research.md`](./economy_alchemy_research.md)) remains Phase-3-era — it's a progression layer that has to be playable before deep production mechanics matter.
