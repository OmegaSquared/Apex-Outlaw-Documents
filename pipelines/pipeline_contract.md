# Contract Pipeline

**Status: Proposed** — designed in canon, not yet implemented. Schemas (`Contract`, `CargoManifest`, `HaulerProfile`) and CloudScript handlers (`ContractPost / Cancel / Claim / Pickup / Deliver / CollectDelivery / AutoTick`) are specced. Lifecycle: Posted → Claimed → InTransit → Delivered → Closed (with Failed / Cancelled branches).

**Schemas (proposed):** `Contract` (per-job record), `CargoManifest` (what's being hauled), `HaulerProfile` (per-player aggregate — completed/failed/on-time rate, route specializations, blocklist). All runtime records, no asset files.

**Storage:** PlayFab title internal data + per-player keys. No `Assets/GameData/Contracts/` folder — contracts aren't authored at edit time, they're created at runtime by players posting jobs.

**Pipeline shape (when built):**
1. Player A clicks "Post Contract" at a Bank Terminal → fills form (cargo, origin, destination, payment, deadline, collateral)
2. `ContractPost` handler validates + writes to title data, registers in the contract board
3. Player B (hauler) browses contract board, claims → `ContractClaim` handler
4. Cargo escrowed into a `ContainerType.ContractEscrow` container at origin
5. Hauler picks up → `ContractPickup`, in transit (cargo follows their ship)
6. Hauler arrives at destination → `ContractDeliver`, payment released
7. Receiver collects → `ContractCollectDelivery` extracts cargo to receiver's container

**Gaps that block authoring this doc fully:**
- Schemas + handlers not yet written
- Bank Terminal contract-board UI not yet built
- HaulerProfile aggregation logic (mirror of MakerProfile) not yet built
- Supply-Chain Tap integration (hacking module reads contract store filtered by alliance + InTransit) blocks on this

**Canon:** [`../economy/economy_freight_contracts.md`](../economy/economy_freight_contracts.md) (full lifecycle + schema fields + aggregation rules + Supply-Chain Tap unification).

**Author this pipeline doc fully when:** the contract schemas + first CloudScript handler ship.
