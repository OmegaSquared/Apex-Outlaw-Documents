# Container Pipeline

**Status: Live (Slice 1)** — schema + helpers, PlayerProfile integration, CloudScript handlers, UI all shipped. The data model is location-bound (each container lives at a specific PlayerProfile / ship / base / hub) and mass-capped via ResourceSchema's `massPerUnitKg`.

**Schemas:** [`ContainerSchemas.cs`](../../Assets/Scripts/Schemas/ContainerSchemas.cs) — `ContainerInstance` (a single container with type, location, capacity, entries), `ContainerType` enum (Ship / BaseStorageModule / Pickup queue / Contract escrow / External crate / etc.), `ContainerMath` (mass-cap helpers).

**Storage:** ContainerInstance records live in PlayerProfile under `containers : List<ContainerInstance>` — there are no asset files; they're per-player runtime data.

**Pipeline shape (already live):**
1. CloudScript handlers (`InventoryReadOwn`, `InventoryListOwn`, `InventoryInsert`, `InventoryExtract`, `InventoryMove`) own all container mutations
2. `InventoryClient.cs` wraps the calls
3. UI surfaces (`InventoryView`, `RemoteTerminalView`) consume via the client
4. Mass-cap math (`ContainerMath.Compute*`) reads `massPerUnitKg` from `ResourceSchema`
5. New container types extend the enum + add a handler-side case for any type-specific rules (e.g. crate hazard rules)

**Gaps to address when filling in this doc:**
- External Crate variant (Phase 1.6 todo) — `ExternalCrate` enum value + `crateForm` (Solid/Gas) + `crateHazard` (None/Explosive/Cryo/Radioactive) fields not yet added
- Cryo Crate / Radioactive Crate physical variants for Tier-3+ material transport
- Visual prefab authoring for crates (the crate-mesh-by-form-and-color spec is canon; assets aren't authored yet)
- No "container schema asset" file format — containers are pure runtime records. If we ever need authored container types (e.g. specific bulk-storage modules with different capacity tiers), we'd add a `BaseStorageModuleSchema` and bring that into the base-part pipeline rather than extending this one.

**Canon:** [`../economy/economy_overview.md`](../economy/economy_overview.md) "Inventory & Storage" + the canonical crate visual rules.

**Author this pipeline doc fully when:** the External Crate work lands, OR the Pickup Queue work lands, OR an authored container type emerges.
