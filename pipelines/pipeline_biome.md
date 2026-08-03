# Biome Zone Pipeline

**Status: Proposed (schema not yet authored — master_to_do 6.9.I.2).** Written *ahead* of the schema per the "no new content type without a pipeline doc first" rule. Loop canon: [`../world/world_surface_gathering.md`](../world/world_surface_gathering.md).

A **biome zone** is a lat/lon region of a planet surface that drives three things at once: **visuals** (which SGT landscape layers paint the ground + which cosmetic dressing scatters), the **resource signature** (which deposits scatter there + their weights), and an optional **heightmap lean** (equator-lift / polar-sink shaping). Biomes are *material / dressing / data* variation keyed by surface direction — **not** a terrain-shape rebuild.

**Schema (proposed):** `BiomeZoneSchema` —
- `zoneId`, `displayName`
- `latMin` / `latMax` (degrees — the band). The later region-map mode swaps bands for a baked biome-ID mask.
- `sgtLayers` — reference to the SGT `SgtLandscapeBiome` layer set (ground textures + detail meshes) this zone paints.
- `resourceSignature` — list of `{ resourceID, weight }` driving which deposits scatter here (graded + bulk); consumed by the surface deposit scatter (`SurfaceResourceField` / `SurfaceResourceNode`). Honor the on-planet **A− grade cap** + each resource's `MaterialClass` per [`../world/world_resource_geography.md`](../world/world_resource_geography.md).
- `dressingProps` — cosmetic prop set (SGT-scattered; the biome selects which).
- `equatorLift` / `polarSink` (optional) — reinforce `TerrainThemeSchema`'s existing latitude shaping.

**Keying:** lat/lon via `PlanetSurfaceCoordinates` (`DirectionFromLatLon` / `LatLonFromDirection`) — the same canonical frame day/night + base placement already use. The `SgtSphereLandscape` material resolves the zone from each fragment's lat/lon (band test now; biome-ID mask later).

**Pipeline shape (six-stage):**
1. **Schema** — `BiomeZoneSchema` SO (this content family).
2. **Setup** — no per-instance prefab; a biome references existing SGT layer sets + prop sets. A setup helper may bake the default 3-band Alythar set.
3. **Catalog** — auto-discovery via `AssetDatabase.FindAssets($"t:{nameof(BiomeZoneSchema)}")`.
4. **UI** — authoring debug overlay (cursor lat/lon → active zone); no player-facing menu.
5. **Runtime** — a biome resolver maps surface lat/lon → zone → drives the SGT material blend, the dressing scatter, and the deposit signature.
6. **Doc** — this file.

**Storage:** `Assets/GameData/Biomes/` (instance assets).

**Author a new biome:**
1. Create → Apex Outlaw → Schemas → Biome Zone Schema.
2. Set the lat band, pick the SGT layer set + dressing, list the `resourceSignature` (per [`../world/world_resource_geography.md`](../world/world_resource_geography.md) composition + the A− cap).
3. The resolver + scatter pick it up automatically.

**Start point:** 3 latitude bands on Alythar (equatorial / temperate / polar) — the cheap first cut that reinforces the heightmap's existing equator-lift / polar-sink shape.
