# Resource Scanner — Sector-View Material Anchors

> **Phase 6.9 scanning canon (added 2026-05-29):** Sensors use the three-radii `SensorSchema` curves: `sensorRadius` (tactical / Scene 2 + 3), `sectorRadius` (Solar / sector map), and `syncRadius` (FOW mesh share between friendlies). On the **Surface scene (Scene 3)** specifically, enemy surface bases are revealed on the radar/minimap ONLY when their `BaseNoiseEmitter` is emitting noise (smelter, forge, drone build active) AND within sensor range. Silent bases stay off-radar but remain physically rendered in 3D — visual scouting is a valid counter-strategy. Canon: [`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md) "Activity-noise radar stealth", [`../world/world_surface_scene.md`](../world/world_surface_scene.md).

> **Scope.** Sector-view Resource Scanner menu only. The follow-on mining scene (where the player actually pulls ore + discovers new max grades) is **not yet designed** — discovery currently bridges off a hardcoded default. The named-asteroid scenes (planned per `Asteroid_<bodyId>.unity` pattern) are also separate and undecided. **Note:** the Vega-Conflict-style `Planet_<bodyId>.unity` 2D rotating planet view referenced in some earlier docs is **retired** — surface gameplay now happens in Scene 3 (`Surface.unity` template). See [`../world/world_surface_scene.md`](../world/world_surface_scene.md).
>
> This doc supersedes the earlier "Resource Discovery vertical slice" (TDD pasted 2026-05-16). That earlier model — fly-and-lock in 3D space, deploy physical Telemetry Beacons, mining-tick extraction — was scrapped 2026-05-17. The data layer (schemas + admin-curve PDF + `maxDiscoveredGoods` cache) survived; everything else is rebuilt.

## 1. The Loop

```
   Sector view (Vesperion)
   ──────────────────────
   open Resource Scanner panel  ──►  per-material toggles, right side

   toggle "iron" ON
      ↓
   client → ResolveMaterialAnchors(materialId, beltSeed, virtualCount)
      ↓
   server reads profile.maxDiscoveredGoods.iron (BRIDGE: A=9 default)
      ↓
   server walks belt indices 0..virtualCount, deterministically rolls a grade
   per (alchemySeed, materialId, beltSeed, index) against anomaly PDF
      ↓
   returns up to 50 indices where rolled grade ≤ player's max
      ↓
   client spawns ResourceScannerMarker at each rock's evaluated world
   position; marker tracks the rock as it orbits, pulses, tinted by the
   player's max-grade band color

   toggle "iron" OFF → markers despawn
```

## 2. The Sector-View Panel

`ResourceScannerPanel` auto-installs into any loaded scene that contains a `MacroAsteroidBelt` (Vesperion-style per-system scenes). It builds a right-anchored UGUI panel listing one toggle per `ResourceAnomalySchema` asset under `Resources/Schemas/Anomalies/`.

- v1 panel is **programmatic UGUI, no prefab dependency.** Replace with a designer-authored prefab when one is ready.
- Toggles are independent — multiple materials can be active simultaneously, each with its own ~50 markers (cap is per-material, not aggregate).
- Markers persist across belt rotation; they re-evaluate position every frame via `CelestialPositionEvaluator` using the rock's orbit params (read via `MacroAsteroidBelt.TryGetRockOrbit`).

## 3. Per-Player Determinism

Anchor placement is a pure function of `(player.alchemySeed, materialId, beltSeed, asteroidIndex)`. Two players standing in the same Vesperion will see the **same rocks** (the field is shared, seed-deterministic at the scene level) but **different anchors** (which of those rocks carries which material at which grade is per-player secret).

This means:
- Player A may find their [Flaw] iron at rock #2174; Player B at rock #883.
- Both players see all 6000 rocks in the same positions.
- An Apex grade typically resolves to ~1 anchor for that player; a Baseline grade resolves to many (up to the 50 cap).

## 4. Discovery — Where `maxDiscoveredGoods` Gets Stamped

**Not in this slice.** The mining scene that does the actual ore-pull is unbuilt. When it lands, the player extraction event compares the rolled grade against `profile.maxDiscoveredGoods.bestGradeByResource[materialId]` and writes if better.

Until the mining scene ships, the server **BRIDGE** treats every material's `maxGrade` as `A` (byte 9) when the player has no entry. The Resource Scanner panel still works — it just shows the "A-grade iron lives at these rocks" anchor set even though the player has never actually discovered iron. Tracked in `master_to_do.md`.

## 5. Server Handler

[`cloudscript/scanning.js`](../../cloudscript/scanning.js) — single handler:

```
ResolveMaterialAnchors({ materialId, beltSeed, virtualCount })
  → { ok, materialId, playerMaxGrade, anchorIndices[], anchorCount }
```

- Validates `materialId` against the hardcoded `ANOMALY_CATALOG` mirror (BRIDGE — same removal moment as `RECIPE_CATALOG`, when title-data export pipeline ships).
- Pulls `playerMaxGrade` from profile cache (or default A=9 BRIDGE).
- Hashes `(alchemySeed, materialId, beltSeed, index)` per rock, samples the admin-tuned PDF, collects up to 50 indices where rolled grade ≤ player max.
- Server cap: `virtualCount ≤ 50000` (anti-DOS).
- No PlayFab write — read-only.

The PDF sampler + per-material curves are the same admin-controlled `AnchorCurve` model from the earlier slice. Designers tune `Assets/Resources/Schemas/Anomalies/anomaly_<id>.asset` in the Inspector; rebuild the bundle to push.

## 6. What Survives From the Earlier Slice

**Kept** (data layer, still load-bearing):
- `GradedStack`, `MaxDiscoveredGoods`, `ResourceAnomalySchema` (admin probability curves), `MiningLaserSchema`, `TelemetryBeaconSchema` (schema only — entity concept dead).
- Grade table tweak (`[Flaw]` shortCode).
- 6 anomaly assets under `Resources/Schemas/Anomalies/`.
- `PlayerProfile.maxDiscoveredGoods` + `gradedInventory` fields.
- `ContainerInstance.gradedStacks` + mass-cap math (both Unity + `cloudscript/inventory.js`).
- Admin-tuned distribution curves verified via [`cloudscript/tests/scanning_distribution.test.js`](../../cloudscript/tests/scanning_distribution.test.js).

**Deleted** (gameplay layer — wrong model):
- `Assets/Scripts/Macro/AsteroidInstance/` (entire folder — Loader, Host, Interface, PresenceClient, EntryClickHandler, EntryRegistrar, Scanner UX).
- `Assets/Scripts/Macro/Beacons/` (TelemetryBeaconEntity, BeaconDeployAffordance, BeaconExtractionSession).
- `Assets/Scripts/Macro/SectorMap/AsteroidInstanceIndicator.cs`.
- `cloudscript/beacons.js`, `cloudscript/mining.js` — DeployBeacon, RetrieveBeacon, ListBeaconsInBody, ApplyExtractionTick.
- `recipe_telemetry_beacon.asset` — the deployable concept is dead.
- `entryEnabled` + `candidateResourceFamilies` on `CelestialParentRecord` and in `seed.json`.
- `CelestialSpawner.EnsureAsteroidInstanceEntry` — there's no per-named-asteroid runtime click target anymore.
- `MacroAsteroidBelt.bypassFowStreaming` — no runtime instance scene needs it.
- The runtime `AsteroidInstance.unity` programmatic scene loader.

## 6.5. Composite Ore — Multiple Resources Per Mining Run (CANON 2026-07-05)

> Full model: [`economy_resources_roster.md`](./economy_resources_roster.md) §2. Summary here
> because it changes what "extraction" means for every future mining slice.

**Ore is a composite.** A mining run does NOT pull one material — it returns a **yield
vector**: one operation might produce iron *and* carbon *and* copper together, in proportions
set by **where** the mining happens (biome band / site signature). Some ground runs
copper-rich, some iron-rich. The player never needs sixteen mine types; prospecting for
*good ground* is the decision.

Implications for this doc's systems:

- **Scanner anchors mark the HEADLINE material** ("your A-grade iron lives here") — the
  assay at the site reveals the full vector (e.g. `iron 42% · silicates 30% · copper 18% ·
  carbon 10%`). The per-player anchor model and the composite model compose cleanly.
- **Yield vectors are SPARSE** — 3–5 materials per site. A site's absences create regional
  identity and trade.
- **Site quality drives the grade distribution of everything it yields** — rich veins give
  *better* materials, not just more. The discovery event (extraction → `maxDiscoveredGoods`)
  therefore can stamp SEVERAL materials per run.
- **Exotics never appear in common ore** — the rare tier is location-locked (dangerous /
  strange places only); that's the deepest layer of the blind tech tree's fog.
- Already half-built: `BiomeBandAuthor` resource signatures + `SurfaceStoneEconomy` crate
  multi-yield (stone runs already emit copper).

## 7. Out of Scope (Future Work)

- **Mining scene** — where the player actually scans individual rocks for better grades, deploys miner ships / outposts, pulls ore. Click any belt rock → load this scene. Aaron to design. **Must implement the composite yield-vector model (§6.5).**
- **Discovery event** — extraction inside the mining scene writes to `maxDiscoveredGoods`. Removes the bridge default.
- **Named asteroid scenes** — `Asteroid_castor.unity` etc., mirroring `Planet_avernus.unity`. Click on the large named asteroid in the sector view → load that body's scene. Contents undecided.
- **`MacroMiningBridge.cs`** stays as the live placeholder for click-belt-rock → 5-min timer until the mining scene ships.
- **Title-data export pipeline** — same future removal as the recipes mirror. Until then, `cloudscript/scanning.js` `ANOMALY_CATALOG` is a hand-maintained JSON-array mirror of the asset files.

## 8. Critical File Index

**Code (active):**
- [`Assets/Scripts/Macro/ResourceScanner/ResourceScannerPanel.cs`](../../Assets/Scripts/Macro/ResourceScanner/ResourceScannerPanel.cs) — auto-installed right-side UI.
- [`Assets/Scripts/Macro/ResourceScanner/ResourceScannerMarker.cs`](../../Assets/Scripts/Macro/ResourceScanner/ResourceScannerMarker.cs) — per-anchor world marker.
- [`Assets/Scripts/Macro/MacroAsteroidBelt.cs`](../../Assets/Scripts/Macro/MacroAsteroidBelt.cs) — `TryGetRockOrbit` accessor + existing virtual-roster streaming.
- [`Assets/Scripts/Schemas/ResourceAnomalySchema.cs`](../../Assets/Scripts/Schemas/ResourceAnomalySchema.cs) — admin probability curve schema.
- [`Assets/Scripts/Schemas/MaxDiscoveredGoods.cs`](../../Assets/Scripts/Schemas/MaxDiscoveredGoods.cs) — per-player best-grade cache.
- [`Assets/Scripts/Schemas/GradedStack.cs`](../../Assets/Scripts/Schemas/GradedStack.cs) — graded raw-material stack.

**CloudScript (active):**
- [`cloudscript/scanning.js`](../../cloudscript/scanning.js) — `ResolveMaterialAnchors`.

**Assets (active):**
- `Assets/Resources/Schemas/Anomalies/anomaly_<id>.asset` — 6 files (iron, carbon, silicates, titanium, helium3, platinum).
- `Assets/Resources/Schemas/Grades/grade_table_default.asset` — `[Flaw]` shortCode tweak.

**Verification harness:**
- [`cloudscript/tests/scanning_distribution.test.js`](../../cloudscript/tests/scanning_distribution.test.js) — Node smoke test for the admin-curve PDF. Mode at C, ~90% baseline, 0.1–1% apex per family.
