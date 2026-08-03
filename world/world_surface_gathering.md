# Surface Resource Gathering — Planet-Side Extraction Loop

This doc owns the **planet-surface resource gathering loop**: how raw materials get out of a planet's crust, into a base's crates, and into the production chain. It is the *supply* side of the ground base — the smelter→refinery→forge spine ([`../ground_base/ground_base_overview.md`](../ground_base/ground_base_overview.md)) is the *consumption* side.

Pairs with:
- [`world_resource_geography.md`](./world_resource_geography.md) — **what** resources live where (composition, frost line, the on-planet grade cap). Surface gathering is one of its extraction channels (§2).
- [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md) — the 12,345 Alchemy Matrix (per-player grade rolls).
- [`../economy/economy_scanning_extraction.md`](../economy/economy_scanning_extraction.md) — the belt Resource Scanner + the **discovery** mechanism (`maxDiscoveredGoods`). The surface *miner* path reuses this; the drone path deliberately does not.
- [`world_surface_scene.md`](./world_surface_scene.md) — Scene 3, the surface itself (3D-placed bases at lat/lon, activity-noise radar).

> **Canon, not wishlist.** The drone-gather MVP is the near-term build; the miner/outpost/equipment tiers are designed-for and deferred. Tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md) Phase 6.9.

---

## Why this exists

The production tree consumes raw ore and gas but, today, **nothing produces them on the surface**. Crates are filled exactly once — by the opening freighter drop (`StartingCrateLoadout`) — and then never refilled. The whole "Layer 0: Extraction" stage of the production spine is a hole. This doc defines the loop that fills it, and locks the canon that gives planets a distinct economic identity: **planets are the "honest day's work" tier; the elite materials are off-world and dangerous to reach.**

---

## Principles (canon)

### 1. Two material classes — Graded (alchemy) vs Bulk (construction)
A resource is **graded only if its quality drives downstream stat math.** That splits raws into two classes, carried on `ResourceSchema` as **`MaterialClass { Graded, Bulk }`**:

- **Graded (alchemy)** — ores + gases that synthesize into parts (iron, helium-3, titanium…). Each carries a grade: a 0–12,345 Alchemy-Matrix quality, banded F…Fl per [`grade_table_default.asset`](../../Assets/Resources/Schemas/Grades/grade_table_default.asset). The grade is a property of a *specific deposit*, rolled per-player at extraction — not hand-set on the resource type. Scanned, discoverable, A−-capped on-planet (Principles 2–4).
- **Bulk (construction)** — ungraded commodity tonnage whose quality is inert (an A-grade wall and an F-grade wall are identical). Members so far: **granite** (base stone), **regolith**, **water**, **scrap metal**. No grade, no scan, no discovery, no cap — pure tons. In crates these stacks read grade **"—"**.

This resolves the earlier "are raws graded?" ambiguity precisely: *graded* raws are graded — superseding the old "a unit of Iron is just a unit of Iron" framing **still present in `ResourceSchema`'s docstring (stale, flagged for update)** — while *bulk* raws never were. **Purity-cascade rule:** Bulk inputs are **excluded from the "min input grade" cascade** — they count for tonnage, never drag a forged part's grade down.

### 2. On-planet grade ceiling = A− (Elite); above A− is off-planet only
Surface *graded* deposits never roll above the **A− (Elite)** band (ceiling ~9,099 on the 0–12,345 scale, per the grade table — read from the table, never a magic number). Everything above A− — **A (Master), A+ (Grandmaster), S, E, Fl** — exists **only off-planet** (belts, named asteroids, The Ring). This is a geography rule; it also lives as canon in [`world_resource_geography.md`](./world_resource_geography.md) §3. Distribution under the cap is **per-material** (a tungsten world skews refractory; an ice band skews volatiles), driven by the same `ResourceAnomalySchema` PDF shape the belts use, clamped at A−.

**Why A−:** it gives planets a clean "top out at Elite" identity and makes the belts/asteroids/Ring worth the travel and danger. The grind for Master+ pulls players off the homestead and into contested space.

### 3. Two acquisition paths, separated by *information* — not by grade range
Both paths obey the same A− cap. The difference is what the player *learns*:

| | **Drone gathering** (early game — BUILD NOW) | **Mining / scanning** ("miner-first" — FUTURE) |
|---|---|---|
| Scan? | No | Yes — surface scanner, mirrors the belt `ResolveMaterialAnchors` |
| Seek a grade? | No — random pickup of whatever's nearby | Yes — target the richest deposits |
| **Discovery** | **No** — does **not** stamp `maxDiscoveredGoods` | **Yes** — stamps `maxDiscoveredGoods.bestGradeByResource[materialId]` if better, identical to the belt mining scene |
| Gear | The base's worker drone | Stationary mining outpost + roaming scanner/miner + large equipment |
| Node tier | "small / hand-collectable" | "needs equipment" |
| Feel | "You get what you get" | Deliberate progression that unlocks the matrix + tech tree |

The split matters: the lazy early-game trickle can't shortcut alchemy progression. To *learn* where grades are (and unlock the tech tree's discovery-gated nodes), the player must commit to the miner path.

### 4. One grade model — deterministic per-player
A deposit's true grade is deterministic per-player, hashed from `(alchemySeed, materialId, bodySeed, position)` — exactly like belt rocks. The drone just grabs whatever it reaches **without revealing or discovering** it; it *feels* random to the player while staying a single, reproducible model (no second RNG system to maintain).

### 5. Build planet-agnostic
Every system here (biome zones, deposit scatter, harvest job, processing handoff) is authored against the live model and is **not** Alythar-specific. Alythar is the prototyping vehicle (a dev playground that may be promoted to canon); promoting a planet into canon geography is then a one-line `CelestialRegistry` composition add, zero rework.

---

## The loop

```
BIOME ZONE (lat/lon)                 ← sets visuals + resource signature
   │  determines which resources + dressing scatter here
   ▼
DEPOSIT SCATTER  ──────────────┬──→  harvestable nodes (interactive, graded, depletable)
   │ deterministic per-planet  └──→  cosmetic dressing (SGT GPU scatter — trees/rocks)
   ▼
HARVEST
   ├─ DRONE (now):  roam near base → random pickup → haul home   (no scan, no discovery)
   └─ MINER (future): scan → seek grade → extract                (stamps maxDiscoveredGoods)
   ▼
CRATE  (ContainerInstance.gradedStacks — (resourceID, grade, tons) rows, mass-capped)
   ▼
PROCESSING  (smelter → refinery → forge spine)        ← closes the Layer-0 input gap
```

---

## Deposit model

- **Record-driven**, mirroring the surface-tile architecture (`SurfaceBaseRecord` / `SurfaceBaseStore` / `SurfaceBaseRenderer`): a deposit *record* (id, resourceID, tier, remaining tons, seed-derived position) is the canonical shape; a store holds them; a renderer reflects them into the scene. Persistence → PlayFab Title Data later (BRIDGE: in-memory until then, same removal moment as 6.9.A.tile.9).
- **Grade** resolved on extraction from `(alchemySeed, materialId, bodySeed, position)`, clamped at A− (Principle 2 & 4).
- **Tier flag** — `Small` (drone-collectable) vs `Equipment` (future miner path). One scatter system serves both.
- **Per-material distribution** — `ResourceAnomalySchema`-style PDF per resource, keyed by the biome's resource signature (Principle 2).
- **Respects base claims** — deposits register/honor the existing `SurfaceScatterExclusion` discs so a node never spawns inside a base footprint (same system that culls SGT dressing under bases).
- **Depletion = deplete-and-respawn, slow trickle** (canon 2026-06-07) — each node holds finite tons; harvesting depletes it to empty, then it's removed and the field re-seeds a replacement elsewhere after a slow cooldown. Net supply is **infinite but rate-limited** — a homestead never runs dry, but on-planet throughput is capped (push volume off-planet or to the future miner tier). The respawn cooldown is the knob that sets the trickle rate.

---

## Biome system (net-new)

The terrain is an SGT `SgtSphereLandscape` heightmap; dressing comes from `SgtLandscapeBiome.Layers`, which today are **global per-theme**. Biomes add **spatial variation** of those layers, plus a resource signature.

- **`BiomeZoneSchema`** (new content type → needs [`../pipelines/pipeline_biome.md`](../pipelines/pipeline_biome.md) before the schema is authored): a zone = a lat/lon region → { SGT layer set (visuals + dressing), resource signature (which materials, what weights), heightmap lean }.
- **Key by lat/lon** via `PlanetSurfaceCoordinates` (the canonical frame already driving day/night + base placement — `DirectionFromLatLon` / `LatLonFromDirection`). Biomes are a **material/dressing variation**, not a terrain-shape change.
- **Start cheap: latitude bands** (equatorial / temperate / polar). This reinforces the heightmap baker's existing latitude shaping (`TerrainThemeSchema.bakeEquatorLift` / `bakePolarSink`) — the color/dressing follows the shape the terrain already makes.
- **Later: region map** (Voronoi-style "lava belt here, ice cap there") via a baked biome-ID texture channel — same infrastructure, a region map instead of bands.
- **Biome → resource signature** is the tie-in to [`world_resource_geography.md`](./world_resource_geography.md)'s composition matrix: a polar-ice band yields volatiles, an equatorial volcanic band yields sulfur/refractories, etc.

---

## "Dropping more items on the planet" — two scatter classes

| Class | System | Status |
|---|---|---|
| **Cosmetic dressing** (trees, boulders, lichen) | SGT `SgtLandscapeSpawner` GPU-instanced scatter, per biome layer | ✅ Live. Biomes vary which layers spawn where. |
| **Harvestable deposits** (graded, interactive) | NEW record-driven node layer — deterministic seed, LOD-instanced, individually targetable + depletable | 📋 New. |

Keep them separate: GPU-instanced scatter is not individually interactive, so harvestable nodes can't be "just more SGT scatter" — they're real records/objects the drone targets and depletes. The new node layer borrows the belt's `MacroAsteroidBelt` virtual-roster discipline (deterministic, camera-LOD-instanced, no per-frame accumulation) and conforms to terrain via `SgtSphereLandscape.GetLocalPoint()`.

---

## Drone-gather MVP — integration

The early-game collector is the existing base worker drone (`BaseDroneFleet`, the AMINT drone — currently "construction drone," rename TBD). Reuse, don't reinvent:

- **Work queue** — add a `Gather` job kind to the shared queue (`RequestDrone` / `RequestStockJob` / priority dequeue). Idle drone near the base claims the nearest `Small`-tier deposit, harvests it, hauls the load home.
- **Drop-off** — into a base crate (`ContainerInstance.gradedStacks`, honoring `CrateCategory` stacking + mass caps per the unified base-crate model), or by the anchor (BRIDGE: anchor drop-off until Construction-Yard semantics land).
- **No discovery write** — the gather job must **not** touch `maxDiscoveredGoods` (Principle 3).
- **Haul timing** — reuse the `BasePartBuildTimer` cadence so gathering takes believable time, not instant.
- **Grade unknown until processed** (canon 2026-06-07) — a drone-hauled stack lands in the crate as **unidentified grade**; the processing step (smelter / assay) reveals it. The grade is already determined (Principle 4) — only the *reveal* is gated, reinforcing that the drone doesn't scan. Implementation: an `identified` flag on the graded stack, flipped on first process.

Larger mining equipment (stationary outpost via the reserved `FacilityType.Miner`, the roaming scanner/miner vehicle) is **future** — designed-for here, not built now.

---

## Processing handoff

Collected materials land in graded crates and become the raw input the production spine was always waiting for: crate → smelter (ore→ingot) → refinery → forge. This is the concrete close of the Layer-0 extraction gap called out in [`../ground_base/ground_base_overview.md`](../ground_base/ground_base_overview.md). Build costs and recipe inputs already consume graded stacks — the only missing arrow was "where do the stacks come from," and this loop supplies it.

---

## Implementation status (2026-06-07)

- **Deposits + drone-gather — BUILT (v1).** Implemented as runtime *components*, not a schema: `SurfaceResourceField` scatters granite nodes around the base at first-foundation; `SurfaceResourceNode` is the mineable node (collider for RTS right-click, `Take()` / `FindNearest()`, destroy-on-deplete); `BaseDroneFleet` mines → hauls → `DepositGranite`/`SpawnGraniteCrate` into a player crate. A schema-driven `SurfaceDepositSchema` was considered and **dropped** — the component system covers v1; revisit only if multiple authored deposit types are needed. **v1/BRIDGE:** editor-time prefab load + RANDOM scatter + placeholder grade (granite is Bulk so it reads `—`). Target: per-player deterministic graded geography from the alchemy seed.
- **Biomes — not yet built.** A new `BiomeZoneSchema` content type; author its pipeline doc first ([`../pipelines/pipeline_biome.md`](../pipelines/pipeline_biome.md)) per the project rule.

---

## Open design decisions

*Resolved 2026-06-07: **node depletion** = deplete-and-respawn with a slow infinite trickle (see Deposit model); **drone-loot grade** = unknown until processed (see Drone-gather MVP); **straddler classes** = Water + Scrap Metal are `Bulk` (Bulk set so far: granite, regolith, water, scrap metal).*

1. **Drone economy tuning.** Capacity per trip, haul speed, how many concurrent gather jobs — sets the early-game material rate.
2. **Biome granularity for the Alythar test.** How many bands to start (3 latitude bands is the cheap first cut).
3. **Surface scanner UX (future).** When the miner path lands, is the surface scanner the same right-anchored panel as the belt scanner, or a deployable surface structure?

---

## How this doc gets used

- **Before adding a deposit/biome:** confirm the resource fits the biome's signature + the body's composition in [`world_resource_geography.md`](./world_resource_geography.md), and that nothing rolls above A−.
- **Before wiring harvest:** drone path = no scan / no discovery; reserve scan + `maxDiscoveredGoods` stamping for the miner path.
- **When the miner tier lands:** move the "future" column of Principle 3 into "built," and unlock surface discovery.
