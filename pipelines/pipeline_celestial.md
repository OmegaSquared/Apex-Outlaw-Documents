# Celestial Pipeline

**Status: Live** — registry-driven body + POI placement, deterministic orbital evaluation, alliance-built POIs via CloudScript. The pipeline is unusual because the "schema" is a JSON file (the `CelestialRegistry` mirror) rather than a ScriptableObject, but the same principles apply: single source of truth, auto-discovery, no scene-baked hardcoded versions.

**Schema:** `CelestialRegistry` PlayFab title-data key (mirrored at [`../../Assets/GameData/Celestial/seed.json`](../../Assets/GameData/Celestial/seed.json)) — describes every planet / moon / named asteroid / POI / jump-gate in the system. Parents (planets, moons, named asteroids), children (POIs). Each entry has bodyId, position-evaluation params (epoch + orbital elements), owner, visualPrefabAddress.

**Storage:** `Assets/GameData/Celestial/seed.json` (local mirror, edited via [`CelestialRegistrySeeder`](../../Assets/Scripts/Editor/CelestialRegistrySeeder.cs)). PlayFab title data is the runtime source.

**Pipeline shape (already live):**
1. Edit `seed.json` (via the seeder UI or directly)
2. Push to PlayFab title data via the seeder's "Push Registry" button
3. At scene load, `CelestialSpawner` reads the registry and instantiates every body + POI parented under their orbital parent
4. Per-frame position is a pure function of `(UtcNow - CelestialEpoch)` via `CelestialClock` + `CelestialPositionEvaluator` — never `Time.deltaTime`-accumulated
5. Jump gates are bubble-radius based — connectivity computed each frame from current positions
6. Alliance-built POIs go through CloudScript handlers in `cloudscript/celestial_alliance_pois.js`, not direct registry writes

**This is the canonical "live data or tracked TODO" example** — flagged explicitly in [`../../CLAUDE.md`](../../CLAUDE.md) "Hard Rules — Don't" and "Hard Rules — Do". No bodies / POIs hand-baked into `SolarSystem.unity`; everything flows from the registry.

**Gaps that would extend this doc:**
- Authoring tooling for asymmetric POI placements (currently best done in JSON directly)
- Per-body visual variant authoring (the `visualPrefabAddress` field's full asset library)
- Alliance-citadel POI authoring (CloudScript-side schema for player-built celestial entities)

**Canon:** [`../architecture/architecture_plan.md`](../architecture/architecture_plan.md) §1.5 (registry-driven design), [`../world/world_planet_authoring.md`](../world/world_planet_authoring.md) (per-planet scene authoring rules), [`../world/world_sector_map.md`](../world/world_sector_map.md) (jump-gate authoring canon).

**Author this pipeline doc fully when:** alliance-citadel construction lands, OR a major new body class (asteroid field, rogue planet, dust cloud, etc.) gets a dedicated authoring flow.
