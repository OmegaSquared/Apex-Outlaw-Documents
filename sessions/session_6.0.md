# Session 6.0 — The Celestial Overhaul (and the polish pass that triggered it)

**Date:** 2026-05-04
**Outcome:** Body and POI placement is now registry-driven, time-anchored, and PlayFab-sourced. Two clients running side-by-side see every body at the same XZ at the same wall-clock second. Alliances can construct POIs that propagate to every player's map within seconds.
**Pre-session checkpoint:** [`6be426c`](../../../) — fall back here if anything below proves to have been a mistake.

---

## Why this session happened

Started as a polish pass on the SolarSystem map: faction labels, centered planet names, lava glow on Ignis, planetary-defense POIs, etc. Mid-session it became clear the underlying authoring model wasn't going to scale:

- Every body and POI in `SolarSystem.unity` was hand-baked by `SolarSystemOneShotFix.cs` — ~3000 lines of editor code authoring `MacroOrbiter` components for every planet, moon, named asteroid, and POI.
- Positions advanced per-frame via `MacroOrbiter` × `SolarSystemTimeScale.Multiplier`. Two clients drifted apart over time — there was no shared "where is Ferrum right now."
- Alliance-built POIs (a future feature) couldn't appear on the map without a code change + scene rebuild.
- The sector map couldn't ask "where is my host parent body in the system right now?" with confidence — the answer depended on each client's frame history.

So we paused the polish work, designed the **Celestial Overhaul**, and shipped it in seven phases (A → G) plus a doc sweep, against a build-philosophy rule we locked into `CLAUDE.md` first so the new code wouldn't accumulate the same kind of half-done scaffolding.

---

## What landed before the overhaul (the polish pass that set the stage)

These came in before the overhaul kicked off — they're now stable and live alongside the registry-driven system.

- **Faction labels inline.** `[FED] Concordia` / `[ICE] Ferrum` rendered via TMP rich-text color tags on the body label. Faction tags propagated to moons + POIs via `TagFactionSystem` walking the planet subtree at editor time. Faction-colored dot tints for Stat Cons + Shipyards.
- **Discordia as a contested middle planet** with two moons: **Pax** (FED toehold, blue) and **Bellum** (ICE garrison, iron-red), opposite sides of the same orbit — peace and war eternally circling strife.
- **Planetary Defense POIs.** Two per faction-controlled planet (Concordia, Ferrum), riding the same outer orbit as the Stat Con. Defeatable structures (HP-stub component on `PlanetaryDefenseStructure`).
- **Map title** "Helion Solar System Map — Ferrum" centered over the planet when zoomed in. `SolarSystemMapTitle` component on the toggles canvas.
- **Ignis lava glow.** `SolarSystemBodyGlow` writes HDR `_EmissionColor` via MaterialPropertyBlock so the dark side of the planet glows from internal heat — no surrounding red corona.
- **Triangle chevron flow** on jump-gate tunnel walls (replaced the outline-stripe band) + dot markers for every gate position colored by faction reach.
- **Lore doc rewrite.** Federation/Mars/Belt → FED/ICE/Outlaws across the design docs. Helion star system as canon. Faction sovereignty model: 50+ member alliances claim a faction for two-way defense + tax; planetary defenses can be defeated; AI bases respawn elsewhere on planet takeover.
- **PlanetControl schemas + binder + access checker.** 50%-of-present-players control rule, residency grandfathering, controlling-alliance non-member tax. Server-authoritative; client renders.

Then the architecture pivot started.

---

## The build-philosophy rule (Phase 0 — `c6212b0`)

Before any code, codified into `CLAUDE.md`:

> **Build the real thing on the first pass.** Don't ship a stub today that you know you'll rip out tomorrow — every dead-end stub is a tax on every future change. If a temporary bridge / scaffold is genuinely required, comment-flag it `// BRIDGE: remove when <X> lands`, list it under `master_to_do.md` "Bridge code to remove", and time-box it.

Every subsequent commit was held to this. Bridges that DID get introduced (the local epoch fallback, the local seed.json fallback, the legacy MacroOrbiter fallback in JumpGateNetwork) are all flagged in code, listed in the TODO, and tracked for removal.

---

## The Celestial Overhaul — phases A through G

### Phase 6.0.A — Time-anchored CelestialOrbiter ([`9113b1d`](../../../))
**Goal:** Two clients side-by-side see the same body at the same XZ at the same wall-clock second.

- New `CelestialClock` static — `Now() = (DateTime.UtcNow - Epoch).TotalSeconds`. Pure function, no `Time.deltaTime` accumulation.
- Epoch sourced from PlayFab title-data key `"CelestialEpoch"` via new `CelestialEpochFetcher` (DontDestroyOnLoad singleton, fires after `PlayFabManager.OnLoginComplete`). Local fallback `2026-01-01T00:00:00Z` BRIDGE-flagged.
- `CelestialPositionEvaluator` — pure helpers for circular + elliptical positions and self-rotation. Same math drives the orbiter, gate-disconnect prediction, and (eventually) sector anchor.
- `CelestialOrbiter` MonoBehaviour replaces per-body `MacroOrbiter`. Position is `evaluator.PositionAt(...)` at `CelestialClock.Now()` — no per-frame angle accumulation.
- **Kepler scaling.** Glacies (outermost planet) anchored to **86,400 s = 1 real day**. Sibling sun-orbiting planets scale via `T = K · r^1.5`. Concordia (r=7,500) computes to ~3.94h. Moons keep authored periods (their hosts aren't the sun).
- `MacroOrbitalSpinner` + `MacroEllipticalOrbiter` migrated to clock-driven (no more Time.deltaTime).
- `SolarSystemTimeScale` repurposed as a **designer clock-offset shim** — pushes `DesignerOffsetSeconds` into the clock for fast-forward previews. Old `Multiplier` static stays as `[Obsolete]` compile compat (sector orbiters legitimately consume it).
- `JumpGateNetwork.PredictWorldPosition` simplified to use `CelestialOrbiter.PredictPositionAt`.
- `MacroOrbiterMigrator` editor menu auto-runs at end of `OneShotFix.Execute()` — converts every `MacroOrbiter` in the scene to `CelestialOrbiter` with frame-perfect angle preservation. **77 orbiters converted, 0 MacroOrbiters remain in `SolarSystem.unity`.**

### Phase 6.0.B — Registry schemas + seeder + runtime client ([`3eeeac3`](../../../))
**Goal:** The canonical body + POI dataset lives in PlayFab, not in scene files.

- Schemas under `Assets/Scripts/Schemas/Celestial/`:
  - `CelestialRegistry` — top-level JSON with `parents[]`, `children[]`, `schemaVersion`, `lastUpdatedAtUtc`, lazy lookup indices.
  - `CelestialParentRecord` — id, parentId hierarchy, displayName, orbital params, visualPrefabAddress (Phase C.2 consumer), baseline faction id/color, allianceClaimable, spinDegreesPerSecond, glowColor, isSectorAnchor.
  - `CelestialChildRecord` — id, parentId, type enum (15 distinct kinds), orbital params, Static/AllianceBuilt source, ownerAllianceId, type-specific payload (jumpGateBubbleRadius, defenseMaxHp).
  - `CelestialOrbitalParams` + `ColorRgba` — round-trip-safe sub-records (Newtonsoft doesn't handle UnityEngine.Color cleanly through property accessors).
- `CelestialChildType` enum — 15 entries covering every POI kind: JumpGate, Station, StatCon, DefenseAlpha/Beta, Military / MilitaryOutpost, Shipyard, TradingHub / TradingOutpost, AncientRuins, WreckageField, BlackMarket, PirateBase, Refinery.
- `CelestialRegistrySeeder` editor menu — walks the open SolarSystem scene, classifies GameObjects by name prefix, builds a CelestialRegistry, sorts deterministically by id, writes `Assets/GameData/Celestial/seed.json` (committed canonical) + `Assets/Resources/CelestialSeed.json` (runtime fallback). **First seed: 38 parents + 40 children = 78 records.**
- `CelestialRegistryClient` — DontDestroyOnLoad singleton, mirrors `CelestialEpochFetcher` pattern. Fetches PlayFab title-data key `"CelestialRegistry"` after login, falls back to the Resources copy if title-data is unset. Caches deserialized instance, fires `OnRegistryUpdated` on apply, exposes `RequestRefresh()` for the Phase G alliance-construction handlers.

### Phase 6.0.C.1 — Spawner + child builder ([`6a9b87e`](../../../))
**Goal:** A live registry update appears on the map without a scene rebuild.

- `CelestialChildBuilder` — procedural POI construction from a `CelestialChildRecord`. Same Dot + Ring + Label + (optional) `JumpGateMarker` tree as `BuildPoi`, but driven from registry data. Per-type `DefaultColorFor` map is now the canonical type→color authoring.
- `CelestialSpawner` — singleton bridging the live registry to the scene tree. On registry update:
  1. Indexes every parent GameObject by id.
  2. Syncs orbital params on existing parents/children (registry edits propagate without re-authoring).
  3. Spawns missing children procedurally via `CelestialChildBuilder`.
  Idempotent — won't duplicate existing scene content.
- Wired into OneShotFix: seeder runs after migrator; `[CelestialSpawner]` GameObject auto-ensured in scene root with the Rajdhani SDF font.
- Seeder fix: `ResolveChildType` now handles asteroid jump gates named `POI_<bodyName>_JumpGate` (Cautes, Petra, Pulvis Calidus). Trailing-token fallback resolves to the correct enum. Three previous Unknown warnings cleared.

**Phase 6.0.C.1 deliberately stops short of stripping OneShotFix authoring** — the spawner runs *alongside* existing scene-baked content, which is safer to land incrementally. **Phase 6.0.C.2** (strip + Addressables-load parent visuals) is deferred (see "What we deferred" below).

### Phase 6.0.D — Big centered planet name watermark ([`7ab664d`](../../../))
**Goal:** Every Celestial Parent gets the same visual treatment — a large semi-transparent name centered on the body.

- New `CelestialParentLabel` — WorldSpace canvas centered on the body, billboarded, ZTest=Always so it draws over the planet sphere from any angle. TMP text size scales with `cam.orthographicSize * 0.08` (≈ map-title weight). Color `(1, 1, 1, 0.55)` so the planet visual reads through. `[ICE]` / `[FED]` faction prefix in faction color via inline rich-text tags.
- ZTest re-applied each frame because TMP swaps materials behind our back when rich-text color tags spawn sub-meshes.
- Spawner attaches `CelestialParentLabel` on every parent record on registry apply, disables the legacy `SolarSystemBodyLabel` on parents (children keep theirs).
- OneShotFix adds an `ApplyParentLabelsEditTime` pass so the saved scene file already reflects what runtime would produce — designers see the watermark in scene view without entering Play mode.

### Phase 6.0.E — Sector ↔ solar map sync ([`b70a226`](../../../))
**Goal:** A sector scene knows where its host parent is in the system right now, sourced from the same evaluator the solar map uses.

- `CelestialSectorAnchor` — per-sector-scene MonoBehaviour. Resolves the host parent from the registry (with prefix-fallback so `"ignis"` finds `"Planet_ignis"`), walks the parentId chain (moon → planet → sun), exposes `ParentSystemPosition` updated each frame. Public API: `Vector3 ParentSystemPosition`, `bool Ready`, `CelestialParentRecord ParentRecord`, `static Instance`.
- `MacroSectorContext.EnsureCelestialAnchor` — Awake-time hook adds the anchor to every sector scene that has a `MacroSectorContext`. No scene-file edits needed; existing `aurelius.unity`, `ignis.unity`, `kessar_belt.unity` get the bridge for free.
- Same `CelestialClock` + `CelestialPositionEvaluator` runs in both the SolarSystem map and every sector scene → they agree on body positions to the second.

### Phase 6.0.G — Alliance-built POI authoring ([`bed3541`](../../../))
**Goal:** A player alliance constructs a POI; it appears on every other player's map within seconds.

- `CelestialPOIConstruction` client API — `RequestConstruct(parentId, type, orbit, callback)` and `RequestDemolish(childId, callback)`. Calls `PlayFabClientAPI.ExecuteCloudScript`, parses the canonical `{ ok, childId?, reason? }` envelope, on success calls `CelestialRegistryClient.RequestRefresh()` so the spawner instantiates the new POI within the next fetch cycle.
- New `cloudscript/celestial_alliance_pois.js` — canonical CloudScript source for `AllianceConstructPOI` + `AllianceDemolishPOI`. Authority gates: alliance officer rank, alliance owns the host planet (via `PlanetControl_<id>`), POI type in the alliance-buildable allow-list (excludes JumpGate / AncientRuins / WreckageField — those stay admin-baked). Mutates via `server.SetTitleInternalData` so leaked admin keys can't trivially overwrite — only signed CloudScript revisions can.
- `cloudscript/README.md` documents the manual upload-to-PlayFab-GameManager workflow (no programmatic deploy yet).
- New `architecture_backend_network.md` §6 documents the title-data keys (`CelestialEpoch`, `CelestialRegistry`, `PlanetControl_<id>`), CloudScript handler signatures, and authority invariants.

### Phase 6.0.F — Doc sweep ([`1c3a385`](../../../))
**Goal:** The design docs reflect the new model as canon.

- `architecture/architecture_plan.md` §1.5 — new "Celestial Layer — Parents, Children, Time-Anchored Positions" section.
- `world/world_sector_rules.md` §5 — new "Sector ↔ Celestial Sync (Phase 6.0)" section.
- `world/world_story_lore.md` §4.6 — new "Infrastructure layer (lore framing for Celestial Children)" subsection tying the in-fiction view to the data-layer reality.
- `00_Master_Design_Overview.md` — added the "Celestial registry as canon" setting note pointing readers at the registry instead of `SolarSystem.unity` for body/POI placement.
- `CLAUDE.md` — new Hard Rule under Don'ts: don't hand-bake new bodies or POIs into `SolarSystem.unity`; edit the registry instead.

### Bridge cleanup ([`a8e830c`](../../../))
**Goal:** Reality check on the bridge list — what actually came out, what stays by design.

- **Removed:** `MacroOrbiter` legacy fallback in `JumpGateNetwork.PredictWorldPosition`. Every SolarSystem-scene gate runs on `CelestialOrbiter` post-migration; the fallback was dead code. Function returns `t.position` for the unreachable "no orbiter" case.
- **Corrected to "Not bridges — kept by design":**
  - `MacroOrbiter.cs` — sector authoring (`SectorAuthoring`, `MacroAsteroidBelt`, `MacroSectorDirector`, `PlanetaryDefenseStructure`) legitimately uses it for sector-scoped bodies that don't need clock-anchored sync.
  - `SolarSystemTimeScale.Multiplier` + `ScaledDeltaTime` — `MacroOrbiter` reads them; both are required by the sector layer.
- **Genuine bridges remaining (gated on PlayFab production setup, not code work):**
  - `CelestialClock.LocalFallbackEpoch` — remove when production seeds the title-data key.
  - `Resources/CelestialSeed.json` fallback — same gate.

---

## What we deferred (intentionally)

- **Phase 6.0.C.2 — strip OneShotFix authoring + Addressables-load parent visuals.** Real value, real cost. Needs:
  1. Programmatic Addressables registration so each planet/moon/named-asteroid prefab is marked Addressable.
  2. Seeder populates `CelestialParentRecord.visualPrefabAddress` from the Addressable address.
  3. Spawner does `Addressables.LoadAssetAsync<GameObject>(address)` for parents whose GameObjects don't exist in the scene.
  4. Strip the `BuildOrUpdatePlanet[2-N]` / `BuildOrUpdateLagrangePair` / `BuildOrUpdateLatro` / etc. authoring blocks from `SolarSystemOneShotFix`.
  5. `SolarSystem.unity` becomes mostly empty (sun, lights, skybox, deep-space nebula, faction bands, jump-gate network singleton, spawner, title canvas).
- **An attempted half-step ("convert OneShotFix MacroOrbiter writes to CelestialOrbiter without stripping")** was scoped, the helper file built, then reverted as a no-net-value change per the no-throwaway rule. The migrator runs idempotently at the end of every OneShotFix pass and converts everything correctly — inlining the conversion into 40+ sites would be busy-work that doesn't remove meaningful debt.

---

## Files added or substantially changed

```
Assets/Scripts/Schemas/Celestial/
  CelestialChildType.cs         — 15-value enum for POI kinds
  CelestialRegistry.cs          — top-level + ParentRecord + ChildRecord + helpers

Assets/Scripts/Macro/Celestial/
  CelestialClock.cs             — static UTC clock anchored to PlayFab epoch
  CelestialPositionEvaluator.cs — pure circular / elliptical / spin math
  CelestialOrbiter.cs           — replaces MacroOrbiter on SolarSystem bodies
  CelestialRegistryClient.cs    — singleton, PlayFab fetch + Resources fallback
  CelestialSpawner.cs           — registry → scene sync + spawn missing children
  CelestialChildBuilder.cs      — procedural POI construction recipe
  CelestialParentLabel.cs       — big centered watermark, ZTest=Always
  CelestialSectorAnchor.cs      — exposes parent's system position to sector scenes
  CelestialPOIConstruction.cs   — client API for alliance-built POIs

Assets/Scripts/Networking/
  CelestialEpochFetcher.cs      — PlayFab title-data → CelestialClock.SetEpoch

Assets/Editor/Celestial/
  CelestialRegistrySeeder.cs    — scene → seed.json + Resources copy
  MacroOrbiterMigrator.cs       — one-pass conversion to CelestialOrbiter

Assets/GameData/Celestial/
  seed.json                     — canonical seed dataset (38 parents, 40 children)

Assets/Resources/
  CelestialSeed.json            — runtime fallback copy (BRIDGE)

cloudscript/
  README.md                     — deployment workflow
  celestial_alliance_pois.js    — AllianceConstructPOI / AllianceDemolishPOI

Modified:
  Assets/Scripts/Macro/MacroOrbitalSpinner.cs   — clock-driven self-rotation
  Assets/Scripts/Macro/MacroEllipticalOrbiter.cs — clock-driven elliptical orbiter
  Assets/Scripts/Macro/SolarSystemTimeScale.cs  — repurposed as designer offset shim
  Assets/Scripts/Macro/JumpGateNetwork.cs       — uses CelestialOrbiter prediction
  Assets/Scripts/Macro/MacroSectorContext.cs    — auto-attaches CelestialSectorAnchor
  Assets/Editor/SolarSystemOneShotFix.cs        — runs migrator + seeder + spawner setup

Design_Documents/architecture/architecture_plan.md       — new §1.5 Celestial Layer
Design_Documents/architecture/architecture_backend_network.md — new §6 Celestial Registry & POI Authority
Design_Documents/world/world_sector_rules.md             — new §5 Sector ↔ Celestial Sync
Design_Documents/world/world_story_lore.md               — new §4.6 Infrastructure layer
Design_Documents/00_Master_Design_Overview.md            — Celestial registry canon note
Design_Documents/meta/master_to_do.md                       — Phase 6.0 + Bridge subsection
CLAUDE.md                                                — no-throwaway rule + no-hand-baking rule
```

---

## Commits in chronological order

| Hash | Phase | Message |
|---|---|---|
| `6be426c` | — | Pre-celestial-overhaul checkpoint (fall-back snapshot) |
| `c6212b0` | 0 | Add no-throwaway-code rule to CLAUDE.md |
| `9113b1d` | 6.0.A | Time-anchored CelestialOrbiter — two clients now sync |
| `3eeeac3` | 6.0.B | CelestialRegistry schemas + seeder + runtime client |
| `6a9b87e` | 6.0.C.1 | CelestialSpawner + child builder — registry drives the scene |
| `7ab664d` | 6.0.D | CelestialParentLabel — big centered watermark on every parent |
| `b70a226` | 6.0.E | CelestialSectorAnchor — sector ↔ solar map sync |
| `bed3541` | 6.0.G | Alliance-built POI authoring — client API + CloudScript source |
| `1c3a385` | 6.0.F | Doc sweep — Celestial Layer canon across the design docs |
| `a8e830c` | cleanup | Drop MacroOrbiter fallback in JumpGateNetwork; correct TODO bridge entries |

---

## What's true now that wasn't true before

1. **Two clients see the same body at the same position to the second.** No frame-time drift, no per-client `Time.deltaTime` accumulation.
2. **PlayFab title data is the canonical source for body and POI placement.** `SolarSystem.unity` is no longer the source of truth — it's just a scene that happens to contain a baked snapshot of what the registry says.
3. **Adding a new planet, moon, or POI doesn't require a code change.** Add a record to `CelestialRegistry` (or alliance-construct it via CloudScript); the spawner instantiates it on every connected client's next registry fetch.
4. **The sector map and the solar map are synchronized.** A sector knows where its host body is in Helion right now via the same evaluator the solar map uses.
5. **Every Celestial Parent renders the same standard label** — large centered watermark with the faction tag in faction color.
6. **Alliance-built POIs are wired end-to-end.** Client API → CloudScript handler → registry mutation → push notification → spawner instantiation. Authority gates on every step.
7. **The codebase's bridge debt is honest.** The two genuinely-temporary scaffolds left (local epoch fallback, local seed.json fallback) are flagged in code with `// BRIDGE:` comments AND tracked in `master_to_do.md` AND time-boxed to the next concrete event ("when PlayFab production seeds the title-data key").
