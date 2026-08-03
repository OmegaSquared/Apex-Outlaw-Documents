# Planet Authoring — Canon Pattern (Solar / Sector view)

How to add a new planet to a solar-system scene (Scene 1 — Solar / Sector view) so it looks and behaves like Avernus in `Vesperion.unity`. Avernus is the reference build; every future planet inherits the same anatomy. Only **scale**, **planet type/art**, **number of moons**, and **number of jump gates** vary.

> **Three-scene context** — this doc covers planet authoring at the **Solar view** layer (Scene 1). For the planet's appearance inside Low Orbit (Scene 2) and Surface (Scene 3), see [`world_low_orbit_scene.md`](world_low_orbit_scene.md) and [`world_surface_scene.md`](world_surface_scene.md). The same `terrainThemeId` from the registry drives the planet's visual in all three scenes.
>
> **Phase 6.9.B note** — the legacy MeshRenderer/sphere-primitive planet visual is being **upgraded to a 3D Planet Forge thumbnail** (`MacroPlanetThumbnail` prefab) per body's `terrainThemeId`. Visual continuity from Solar to Low Orbit to Surface — the planet you see in Solar is the same planet you fly to in Low Orbit. Authoring steps below still apply; what changes is step 1's visual asset (PF thumbnail prefab instead of sphere primitive).

## What a finished planet looks like

A planet has these elements, in order from the planet outward:

1. **Planet body** — the visual sphere (or whatever the type's art is), scaled to taste.
2. **Low-orbit dashed ring** — gray dashed circle, parented to the planet, hugging just outside the planet's visual surface. Sits on `Planet_<id>/SatelliteOrbits/Orbit_LowOrbit`.
3. **High-orbit dashed ring** — gray dashed circle, slightly outside the low orbit. Jump gates orbit on this ring. Sits on `Planet_<id>/SatelliteOrbits/Orbit_HighOrbit`.
4. **Jump gate(s)** — one or more, orbiting on the high-orbit ring. Each is a `POI_<PlanetName>JumpGate_*` with `CelestialOrbiter` + `JumpGateMarker` + `MacroJumpGate`. Most planets have one. Some hubs have multiple.
5. **Planet-entry POI** — `POI_<PlanetName>PlanetEntry`. A dot+ring tap target inside FOW, a pulsing beacon outside FOW. Always present, one per body. See [`MacroPlanetEntryDot.cs`](../../Assets/Scripts/Macro/MacroPlanetEntryDot.cs) for the in-FOW/out-of-FOW logic. **Clicking this POI triggers `SceneManager.LoadScene("LowOrbit")`** with the body ID handoff — voluntary planet entry into Scene 2. (Hyperspace intercept by an enemy fleet routes through the existing attack-timer flow instead, dropping into blank space combat — see [`world_sector_map.md`](world_sector_map.md) Orbit Scenes section.)
6. **Moons** (optional, 0..N) — each parented under `Planet_<id>/SatelliteOrbits/Moons/Moon_<id>`, each with its own `CelestialOrbiter` and entry POI. Moons get the same gated-entry treatment as planets.
7. **Moon orbit rings** — one gray dashed ring per moon, at the moon's orbit radius, parented under `SatelliteOrbits` (NOT under the moon — the ring stays centered on the planet). Authored as `MoonPath_<moonId>`.

All orbit rings — low, high, moon paths, planet paths — render in **the same gray dashed style** so they read as one visual element. Style constants live in [`VesperionAddOrbitPaths.cs`](../../Assets/Editor/VesperionAddOrbitPaths.cs).

## GameObject hierarchy (canon)

```
Planet_<id>                                ← MacroOrbiter, MacroPlanet, PlanetInfo, PlanetControlBinder, MacroPlanetEntryDot
├── Visual                                  ← the planet mesh
├── SatelliteOrbits
│   ├── Orbit_LowOrbit                      ← MacroDashedRing (gray, thin)
│   ├── Orbit_HighOrbit                     ← MacroDashedRing (gray, thin)
│   ├── POI_<PlanetName>JumpGate_<Faction>  ← CelestialOrbiter + JumpGateMarker + MacroJumpGate, riding HighOrbit radius
│   ├── (additional jump gates if a hub)    ← same, different orbit phase
│   ├── MoonPath_<moonId>                   ← MacroDashedRing per moon
│   └── Moons
│       └── Moon_<id>                       ← MacroOrbiter, CelestialOrbiter, MacroPlanet (per-moon scale)
│           └── POI_<MoonName>PlanetEntry   ← (authored by VesperionAddPlanetEntry, treats moons as planets)
└── POI_<PlanetName>PlanetEntry             ← PlanetEntryPoi + PlanetEntryAccessGate + MacroBroadcastPing
                                              + PlanetEntryPoiScaler. Children: Dot, Ring, BroadcastPingLine.
```

A `PlanetPath_<id>` dashed ring sits under the system's `Sun` GameObject — one per planet, at that planet's orbit radius around the star. Authored together with the moon paths.

## Per-planet parameters

When asked to add a planet, the answers needed are:

| Parameter | Notes |
|---|---|
| **Planet id** | `Planet_<lowercase_id>` — used for GameObject name and PlayFab body id. |
| **Display name** | What the label reads (e.g. "Avernus"). |
| **Type / art** | Which prefab or material set drives the visual. |
| **Visual scale** | World units. Drives the surface radius. |
| **Orbit radius around the sun** | World units. Drives `PlanetPath_<id>` radius and the planet's `CelestialOrbiter.orbitRadius`. |
| **Orbit period** | Seconds for a full revolution around the sun. Must follow **Kepler's third law** (T ∝ r^1.5) relative to the system's anchor planet. For Helion / Vesperion the anchor is Avernus (r=700, T=600s), so any new planet: `period = 600 × (radius / 700)^1.5`. Outer planets drift visibly slower than inner — that's the rule. |
| **Low-orbit radius** | Just outside the visual surface. Scales **with planet size** (see rule below). |
| **High-orbit radius** | A tight band beyond low orbit. Scales with planet size. |
| **Jump gates** | List of `(faction, orbit phase deg)`. Most planets: 1. Hubs: 2–4. All ride the high-orbit radius. |
| **Moons** | List of `{ id, displayName, orbitRadius, period, startAngleDeg, visualScale }`. Empty list = no moons. Moon orbit radii scale **with planet size**, not with the system. |

### Orbit-radius rule (relative to planet size)

Low and high orbit are **relative to the planet's visual radius**, not absolute world units. For Avernus (visual scale 80, surface radius ~40), the canonical values are:

- `Orbit_LowOrbit.radius` = visual surface radius × **1.25** (≈ 50 for Avernus)
- `Orbit_HighOrbit.radius` = visual surface radius × **1.75** (≈ 70 for Avernus)

Jump gates ride `Orbit_HighOrbit.radius` (their `CelestialOrbiter.orbitRadius` matches it exactly).

Moon orbit radii are case-by-case but should sit comfortably outside the high orbit ring so the moons don't overlap the gate band. As a guideline, the first moon sits at `Orbit_HighOrbit.radius × ~2`.

**Functional meaning (Phase 6.9 forward).** The dashed rings aren't just visuals — they correspond to the altitude bands of the three-scene model:
- **Low orbit ring** marks where Scene 2 (Low Orbit) gameplay anchors. Orbital structures (satcom, citadels, docks, planetary defense) live at this band in the registry.
- **High orbit ring** marks where jump gates orbit. Still functional in Scene 2 — gates remain dockable targets.
- Both are visual cues in Solar view; the actual structures spawn as 3D prefabs inside Scene 2.

## View-mode behavior (the contract)

Every planet in a solar system honors the system's 3-view controller (e.g. [`VesperionViewController.cs`](../../Assets/Scripts/Macro/Vesperion/VesperionViewController.cs)). The visibility table is the canon:

| Element                 | View 1 (gameplay) | View 2 (planet/strategic) | View 3 (system) |
|---|---|---|---|
| Planet body             | ✓                 | ✓                         | ✓               |
| Low / high orbit rings  | ✓                 | ✓                         | hidden          |
| Jump gate(s) visual     | ✓                 | ✓                         | hidden (POI)    |
| Planet-entry POI        | ✓ (dot+ring inside FOW, pulse outside) | ✓ (**pulse-only**, ForcePulseOnly=true) | hidden |
| Moon orbit rings (`MoonPath_*`) | hidden    | ✓                         | hidden          |
| Planet orbit rings (`PlanetPath_*`) | hidden | hidden                    | ✓               |
| Moon labels             | ✓                 | ✓                         | hidden          |
| Planet labels           | ✓                 | ✓                         | ✓               |
| Non-player fleets       | ✓                 | hidden                    | hidden          |
| FOW overlay             | on                | off                       | off             |

Sizes that change with camera zoom — planet-entry POI dot, ring, and broadcast pulse — are driven by [`PlanetEntryPoiScaler.cs`](../../Assets/Scripts/Macro/PlanetEntryPoiScaler.cs). The scaler expresses each element as a fraction of viewport height, so they read at a constant on-screen size from View 1 (ortho ~10–50) all the way to View 3 (ortho ~5000).

## Authoring steps

For each new planet:

1. **Decide the per-planet parameters** (table above).
2. **Add the body to the registry**, NOT by hand-baking into the scene. The canonical source is the `CelestialRegistry` PlayFab title-data key (mirrored at `Assets/GameData/Celestial/seed.json`). `CelestialSpawner` instantiates the body on scene load. *(For the Vesperion-era hand-authored sub-tree, see "Migration note" below — the current Avernus build predates the registry-driven pipeline being fully wired for sector scenes.)*
3. **Set the orbit radius around the sun** in the registry and the planet's `CelestialOrbiter.orbitRadius`.
4. **Author the low/high orbit rings.** Re-run `VesperionAddOrbitPaths.Execute()` (or the per-system equivalent). The helper finds `Orbit_LowOrbit` and `Orbit_HighOrbit` under `Planet_<id>/SatelliteOrbits` and gives them the canonical gray dashed style with a thin (`bandWidth=0.12`) band. Add new planets' `LowOrbit` / `HighOrbit` child nodes first; the helper styles them — it doesn't create them.
5. **Author the moon orbit rings + planet orbit ring around the sun.** Same `VesperionAddOrbitPaths.Execute()` run picks up new moons under `SatelliteOrbits/Moons` (one `MoonPath_<id>` per moon) and new planets via `CelestialOrbiter` (one `PlanetPath_<id>` under the sun).
6. **Author the planet-entry POI** by adding the body name to the system's `*AddPlanetEntry` bootstrap (e.g. [`VesperionAddPlanetEntry.cs`](../../Assets/Editor/VesperionAddPlanetEntry.cs) `Bodies[]`) and running its `Execute()`. The shared helper [`PlanetEntryAuthor.AuthorEntryPoi`](../../Assets/Editor/PlanetEntryAuthor.cs) builds the POI with `PlanetEntryPoi`, `PlanetEntryAccessGate`, `MacroBroadcastPing`, `PlanetEntryPoiScaler`, and the Dot+Ring children. **Moons go in the same list** — they get the same gated-entry treatment as planets.
7. **Author the jump gate(s).** One `POI_<PlanetName>JumpGate_<Faction>` under `SatelliteOrbits`, with `CelestialOrbiter.orbitRadius` = `Orbit_HighOrbit.radius`. For hub planets with multiple gates, add additional gate POIs at different `orbitPhaseDeg`. Connectivity is bubble-radius-based across the system — see [`world_sector_map.md` § Jump gate authoring canon](world_sector_map.md#jump-gate-authoring-canon).
8. **Wire the system view controller.** No change needed for new planets — `VesperionViewController` finds POIs / labels / orbit rings by name prefix, so any new `POI_*`, `MoonPath_*`, `PlanetPath_*`, `Moon_*` body automatically follows the View 1/2/3 contract.

## Code references — single source of truth

| Concept | File |
|---|---|
| Per-system 3-view controller | [`VesperionViewController.cs`](../../Assets/Scripts/Macro/Vesperion/VesperionViewController.cs) |
| Planet-entry POI authoring (shared) | [`PlanetEntryAuthor.cs`](../../Assets/Editor/PlanetEntryAuthor.cs) |
| Planet-entry POI runtime (click + FOW logic) | [`PlanetEntryPoi.cs`](../../Assets/Scripts/Macro/PlanetEntryPoi.cs) |
| Planet-entry access rules | [`PlanetEntryAccessGate.cs`](../../Assets/Scripts/Macro/PlanetEntryAccessGate.cs) |
| Zoom-reactive POI scaling (dot, ring, pulse) | [`PlanetEntryPoiScaler.cs`](../../Assets/Scripts/Macro/PlanetEntryPoiScaler.cs) |
| Broadcast pulse component | [`MacroBroadcastPing.cs`](../../Assets/Scripts/Macro/MacroBroadcastPing.cs) |
| Dashed orbit ring renderer | [`MacroDashedRing.cs`](../../Assets/Scripts/Macro/MacroDashedRing.cs) |
| Orbit-ring authoring (low/high/moon/planet) | [`VesperionAddOrbitPaths.cs`](../../Assets/Editor/VesperionAddOrbitPaths.cs) |
| Per-system planet-entry bootstrap (lists which bodies get POIs) | [`VesperionAddPlanetEntry.cs`](../../Assets/Editor/VesperionAddPlanetEntry.cs) |
| Celestial orbital math (lazy-eval, registry-driven) | `Assets/Scripts/Macro/Celestial/CelestialChildBuilder.cs`, `CelestialPositionEvaluator.cs` |

## Don't

- **Don't hand-bake jump gates as chain-pairs.** Connectivity is bubble-radius based across the system — every gate just rides high orbit, the network resolves at runtime. See [`world_sector_map.md` § Jump gate authoring canon](world_sector_map.md#jump-gate-authoring-canon).
- **Don't recolor or re-style orbit rings per-planet.** They are uniform gray dashed everywhere, by design. Style constants live in `VesperionAddOrbitPaths`.
- **Don't add `MacroOrbitRing` (solid LineRenderer) for low/high orbit on planets.** That was the legacy style; the canon is `MacroDashedRing`. The authoring helper auto-strips legacy components when re-run.
- **Don't put `[Networked]` Fusion state on planet GameObjects in Solar view (Scene 1).** Macro layer is PlayFab lazy-eval. Fusion runners only spawn inside Low Orbit (Scene 2) and Surface (Scene 3), per the three-scene model.
- **Don't author a 2D rotating planet view scene.** The old `Planet_<bodyId>.unity` pattern is retired. Clicking the planet-entry POI in Solar swaps to the `LowOrbit.unity` template; the per-body content is registry-driven, not per-planet scenes.
- **Don't introduce real-world body names** ("Earth", "Mars", "Federation"). This is the Helion system; FED and ICE are the factions.
- **Don't set per-planet POI sizes in absolute world units.** Always use `PlanetEntryPoiScaler` fractions of viewport so the POI reads at every zoom.

## Migration note — registry vs. hand-baked

The repository CLAUDE.md states:

> **Don't hand-bake new bodies or POIs into `SolarSystem.unity`.** Body and POI placement is registry-driven — the canonical source is the `CelestialRegistry` PlayFab title-data key (mirrored at `Assets/GameData/Celestial/seed.json`).

The Avernus build in `Vesperion.unity` predates the registry-driven pipeline being fully wired for sector scenes — it's the reference for the **visual contract** above, but the future canonical path is: add the body to the registry, let `CelestialSpawner` instantiate it, then run the orbit-path / planet-entry authoring helpers to attach the dashed rings and POIs. When the registry path is fully wired for sector scenes, the authoring helpers in `VesperionAddOrbitPaths` and `VesperionAddPlanetEntry` should be ported to be system-agnostic (not per-system bootstrap scripts) and run automatically after `CelestialSpawner` finishes.
