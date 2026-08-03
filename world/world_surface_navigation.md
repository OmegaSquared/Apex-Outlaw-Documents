---
status: canon
phase: "6.9"
last-reviewed: 2026-06-09
---

# Surface Navigation HUD — Compass Strip + Nav-Minimap

> **Layer:** Macro / PlayFab (Scene 2 Low Orbit + Scene 3 Surface). **No Fusion.** This is the
> exploration/navigation HUD — distinct from the combat-arena radar in
> [[combat_minimap_signatures]], which is the
> Fusion micro-game's bottom-left signature map. The two share *conventions* (procedural,
> data-driven blips; owner-relationship colors; FOW gating) but are separate components with
> separate data sources.
>
> **Build status (2026-06-09):** the **compass strip is BUILT** — a full-screen-width ribbon with
> cardinal heading + cursor lat/lon/alt + the Helion clock. The **nav-minimap is a built placeholder**
> (framed corner circle; the full sensor radar is deferred — see below). Both ship as the shared
> **`SurfaceNavHud`** prefab, instanced per planet scene (see *Portability*). Phases 3–4 (more POI
> sources, enemy gating) remain spec.

## Why we build this (not an Asset Store import)

The rendering is the easy part; the value is wiring markers to this game's bespoke data — the
`CelestialRegistry` POIs, three-scope FOW ([`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md)),
activity-noise base reveal, the dynamic jump-gate network, and the per-planet surface coordinate
frame. No off-the-shelf minimap understands any of that, and most bring their own camera /
RenderTexture pipeline that fights URP + SGT. We already build HUDs procedurally (`MacroBodyProximityHUD`,
`PlanetSurfaceReadout`, `HelionClockHUD`), so this is a focused extension, not a dependency.

## At a glance

```
        ┌───────────────────  W · · · N · · · E · · · S ───────────────────┐   ← compass ribbon (full screen width, top)
        │        ▲HQ            △gate                ◆resource              │     heading-centered cardinal scale
        │            LAT 12.4° N    LON 207.8° E    ALT 1,240 m            │   ← coordinate line (folded in)
        └──────────────────────────────────────────────────────────────────┘
   ┌──────────┐                                                      (top-left readout retired —
   │ nav-map  │  ← optional corner nav-minimap (Phase 2)             its lat/lon/alt now lives
   │  ·  ▲    │     top-down POI blips, north-up                      in the compass strip)
   │ ◆    △   │
   └──────────┘
```

## UI technology — UI Toolkit (UXML + USS)

All HUD here is **UI Toolkit** (Unity's CSS-like UI), matching the project's menu convention
(`SmelterControlPanel`, `FacilityControlPanel`, `DroneOperationsPanel`, the Inventory panel) —
**never** legacy uGUI Canvas / TextMeshPro. Per component:

- A **`.uxml`** (structure) + co-located **`.uss`** (style) under `Assets/Resources/UI/<Name>/`, the USS referenced from the UXML via `<Style src=… />`.
- A `[RequireComponent(typeof(UIDocument))]` controller (`UnityEngine.UIElements`) that loads the UXML + the **shared** `Resources/UI/SharedRuntimePanelSettings`, queries elements by `name` (`root.Q<Label>("…")`), styles via USS classes (`AddToClassList`), and refreshes each frame. Same shape as `SmelterControlPanel.BuildUI`.
- **HUD = non-interactive overlay:** root `picking-mode="Ignore"` (clicks pass through to the world / build grid) and a low `UIDocument.sortingOrder` (below the interactive menus).
- **Palette:** the menus' dark-slate + blue accent — bg `rgba(8,14,26,0.9)`, accent `rgb(115,195,255)`, borders `rgba(80,160,240,0.4)`. Restated per-USS (the menus don't share a theme file).

> **Migration note.** The day/night coordinate readout (`PlanetSurfaceReadout`) and the Helion clock
> (`HelionClockHUD`) were first built this session as legacy uGUI HUDs. They are **re-implemented in
> UI Toolkit**: the coordinate readout folds into the compass strip's UXML, and the clock becomes a
> UXML/USS document. The uGUI versions are retired.

## Portability — one `PlanetSurfaceContext` per planet

Every surface system here is **planet-agnostic** — it carries no planet name, radius, or day
length. The single per-planet thing is a [`PlanetSurfaceContext`](../../Assets/Scripts/Macro/PlanetSurfaceContext.cs)
you drop on the planet root: it auto-derives the frame (center / pole / prime-meridian from its
transform, radius from the child `SgtSphereLandscape`) and carries the per-planet `bodyId` +
`dayLengthHours`. The day/night cycle, coordinate readout, compass, minimap, and `SurfacePoiProvider`
all read `PlanetSurfaceContext.Active` and self-configure.

**The HUD itself is a single shared prefab — `Assets/Prefabs/UI/SurfaceNavHud.prefab`** (root
`SurfaceNavHud` → `SurfaceCompassHUD` + `SurfaceMinimapHUD` children, each with its `UIDocument`). It is
**instanced** into each planet scene, so **editing the prefab once propagates to every planet** (compass
FOV, ribbon styling, radar frame, future tools). The prefab carries **zero** planet specifics — the
compass resolves its planet via `PlanetSurfaceContext.Resolve()` and its camera via
`FindFirstObjectByType<GroundBuildOrbitCamera>()` at runtime, so the same asset drops into any scene.

Porting to a new planet = (1) add a `PlanetSurfaceContext` to the planet root (set `bodyId` + radius +
`dayLengthHours`), then (2) run **Apex Outlaw → Planet → Add Nav HUD (active scene)**
(`SurfaceNavHudSetup`) to instance the shared prefab into whatever planet scene is open. The command is
idempotent (it migrates any older loose compass/radar GameObjects onto the prefab) and
**landscape-agnostic** — it works on `SgtSphereLandscape` *or* `SgtTerrainPlanet`, **surface *or*
low-orbit** (unlike the older path, which located the planet via `SgtSphereLandscape` only). The broader
**Set Up Surface Nav** command (`PlanetSurfaceSetup`, which also wires day/night + moons) now delegates
its nav-HUD step to the same `SurfaceNavHudSetup.EnsureNavHud` — **one source of truth**. The old
Alythar-specific patcher was deleted; Alythar, `Planet_01_surface`, and `Planet_A_orbit` (Planet_01's
orbit) all instance the one shared prefab.

## Components

| Component | Role | Phase |
|---|---|---|
| `SurfaceCompassHUD` | Top-center ribbon: cardinal heading + POI bearing ticks + **LAT/LON/ALT** line. | 1 |
| `SurfacePoiProvider` | Collects POIs (world pos + type + ownerId + label + broadcast flag) from the registry + scene. The single source the compass and minimap both query. | 1 |
| `SurfaceMinimapHUD` | Corner top-down nav-map: POI blips + self marker, data-driven (no second camera). | 2 |

All three are **UI Toolkit** documents (see *UI technology* below). `SurfaceCompassHUD` +
`SurfaceMinimapHUD` are packaged together as the shared **`SurfaceNavHud`** prefab and instanced into any
surface/low-orbit scene (edit-once-propagates — see *Portability*); `SurfacePoiProvider` is the data
source both query.

---

## Coordinate frame, heading & bearings (math)

All angles use the canonical per-planet frame from
[`PlanetSurfaceCoordinates`](../../Assets/Scripts/Macro/PlanetSurfaceCoordinates.cs) (pole = planet
`up`, prime meridian = planet `forward`). Let the **view anchor** = the camera's surface focus point
(`GroundBuildOrbitCamera.target`), `center` = planet center.

- **Surface up at anchor:** `up = (anchor − center).normalized`.
- **Local north (tangent):** `north = (P − dot(P,up)·up).normalized`, where `P` = pole axis. (Points toward higher latitude; degenerates at the poles — fall back to camera-forward there.)
- **Local east (tangent):** `east = cross(up, north)`.
- **Compass heading** (where the camera looks): project camera-forward `f` to the tangent plane → `fT`; `heading = atan2(dot(fT,east), dot(fT,north))` → **0° = N, 90° = E, 180° = S, 270° = W**.
- **POI bearing** (from anchor to a POI at `poi`): project `(poi − anchor)` to the tangent plane → `dT`; `bearing = atan2(dot(dT,east), dot(dT,north))`. This equals the great-circle **initial** bearing, so it's correct, not an approximation.
- **POI distance** (great-circle): `dist = radius · acos(clamp(dot(up, (poi−center).normalized)))`.
- **Ribbon placement:** `delta = wrap180(bearing − heading)`; markers within the visible half-FOV (`COMPASS_FOV_DEG/2`, default 70°) map linearly to horizontal pixels; outside → clamped to the edge as a ">" hint or hidden (tunable).

---

### Planet-attached coordinates (`PlanetCoordinate`)

A surface coordinate is **never bare lat/lon** — it carries its body.
[`PlanetCoordinate`](../../Assets/Scripts/Schemas/PlanetCoordinate.cs) = `{ bodyId, latitude,
longitude, altitude }`. `PlanetSurfaceContext.CoordinateAt(worldPos)` stamps the current planet's
`bodyId`; `TryResolveWorld(coord)` turns one back into a world point **only if it's for that planet**.
That's what lets a coordinate cross contexts — pin one in **global chat** and the game knows it's "that
spot on Alythar" (token `geo:alythar:12.40,207.80,1240`), not an ambiguous lat/lon. The compass
coordinate line and any future chat-pin / waypoint feature use this type.

## Compass strip (Phase 1)

- **Anchor:** top, **full screen width**. The cardinal scale (N / NE / E / SE / S / SW / W / NW with degree ticks) spans the entire width and scrolls under a fixed center pointer as the camera yaws (Q/E / right-drag). The configured `fieldOfViewDeg` (default 140°) fills the whole ribbon: `SurfaceCompassHUD` reads the ribbon's live resolved width each frame and derives px/degree = width ÷ FOV (the `clipWidth` / `pixelsPerDegree` fields are pre-layout fallbacks only; the `.compass-clip` USS is `width: 100%`). The Helion clock (left) + numeric heading (right) sit on a centered, max-width row above the ribbon.
- **POI ticks:** one marker per visible POI at its `bearing`, icon + color by type/owner (below). Optional tiny distance label under the marker (e.g. `1.2 km`). Off-screen POIs clamp to the ribbon edge.
- **Coordinate line (folded in):** **`LAT 12.4° N   LON 207.8° E   ALT 1,240 m`**, centered under the ribbon. **This absorbs today's [`PlanetSurfaceReadout`](../../Assets/Scripts/Macro/PlanetSurfaceReadout.cs)** — the standalone top-left readout is retired so coordinates live in one place. Source = the **cursor** hit (terrain collider → analytic-sphere fallback), because in the base-builder the cursor is where you're about to build. *(Tunable `coordSource = Cursor | ViewCenter`; pick ViewCenter once a real surface ship/avatar exists and "where I am" matters more than "where I point.")*

## Sensor radar — the nav-minimap  *(DEFERRED — placeholder for now)*

> **Build status: DEFERRED.** For now the minimap is just a **circular placeholder in the bottom-left
> corner**, with the surrounding HUD reflowed to clear it (the build strip insets). The design below is
> the eventual system — the player-facing **sensor radar** (the client view of the macro sensor / FOW /
> streaming / encounter layer), **selection-driven (center + range follow the currently-selected fleet
> OR base)**, reusing existing canon: inner **FOW ring** = `SensorSchema.sensorRadius` (entities
> rendered), outer **detection ring** = `SensorSchema.sectorRadius` (contacts as dots only, NOT
> rendered — early warning); contact visibility gated by **`radarSignature`** (an approaching fleet
> pings before you can see it); the radar range **IS** the PlayFab lazy-stream `syncRadius` (beyond it
> nothing loads); closing hostiles trigger the **`ServerFowMatcher`** Fusion handoff (6.9.F);
> server-authoritative (anti-cheat), bridged client-side via `MacroSyncMesh` until 6.7.E / 6.9.F.
> Canon: [`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md) +
> [`../combat/combat_minimap_signatures.md`](../combat/combat_minimap_signatures.md). Eventual detail:

- **Anchor:** a corner (default bottom-left, mirroring the combat minimap's familiar spot; top-left is free now that the readout moved). Square panel, faint grid, translucent dark bg.
- **Rendering:** **data-driven 2D blips** — pooled `VisualElement`s positioned via `style.left`/`style.top` from POI world-XZ → panel UV — **NOT** a second orthographic camera / RenderTexture. Data-driven like `TacticalMinimap`, but built as USS-styled VisualElements, and sidesteps URP/SGT camera conflicts.
- **Orientation:** **north-up** default; `headingUp` option rotates the blip field by `−heading` and spins a compass rose (spec both; ship north-up first).
- **Self marker:** directional triangle at center pointing along `heading`.
- **Projection (sphere-correct):** **azimuthal** — each POI placed at `angle = bearing`, `radius = greatCircleDistance / range`, centered on the player. A top-down tangent map only reads right locally; azimuthal stays correct out to a whole hemisphere on the 100 km sphere, and reuses the compass's bearing + distance math.
- **Range zoom (this *is* the long-range map):** zooms from **tactical** (~1–5 km, effectively flat — your base + immediate surroundings) out to **long-range** (regional → the whole visible hemisphere, up to ~half the ~628 km circumference) so you can see a base on the far side and plot a course around the world. Labelled **range rings** (e.g. 1 / 10 / 100 km) give scale; mouse-wheel over the map (or a hotkey) steps the range.
- **Self / orientation:** self marker at center; **north-up** default, `headingUp` optional (rotates blips by −heading + spins a compass rose).
- **Full planet map (later phase):** a toggled full-screen **equirectangular (lat/lon) overlay** showing the entire planet's POIs at once — the strategic "world map." Heavier; lands after the corner minimap.

---

## POI sources (`SurfacePoiProvider`)

A `SurfacePoi` = `{ Vector3 worldPos; SurfacePoiType type; string ownerId; string label; bool broadcasts; }`.
Sources are **registry/scene-driven** (live-data rule), added in phases:

| Source | Type | When | Notes |
|---|---|---|---|
| Own surface base anchor (`SurfaceBaseAnchor.Current`) | `HomeBase` | Phase 1 | Always visible. |
| Surface-base registry children (`CelestialChildRecord` where `type == SurfaceBase`) | `Base` | Phase 1 | World pos via `PlanetSurfaceCoordinates.DirectionFromLatLon(surfaceLatitude, surfaceLongitude)` × radius. |
| Resource-scanner markers (`ResourceScannerPanel`) | `Resource` | Phase 3 | Belt/surface deposits at the player's grade. |
| Jump gates (registry `JumpGate` children) | `Gate` | Phase 3 | Low/high-orbit scenes. |
| Other fleets | `Fleet` | when surface fleets land | BRIDGE: no surface fleet exists yet. |

## Visibility / FOW gating

Mirrors [`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md) + the surface canon in the
minimap doc:

- **Own / allied POIs:** always shown.
- **Neutral broadcasting POIs** (gates, trading posts — `broadcastsLocation`): always shown.
- **Enemy bases:** shown **only** when emitting noise (smelter/forge/drone active) **and** inside your `sensorRadius` — the activity-noise rule (`BaseNoiseEmitter`, Phase 6.9.E). Silent enemy bases stay off the HUD but remain physically rendered in-world (visual scouting counter-play).
- Owner relationship is resolved from `ownerId` (FED / ICE / alliance-UUID / empty) per the faction-IS-alliance canon — **no `factionId`**.

### Marker colors (owner-relationship, perspective-relative)

| Relationship | Color | Notes |
|---|---|---|
| Self / own | `#ffffff` | HomeBase uses a distinct icon. |
| Alliance | `#7be07b` | |
| Foe | `#ff5333` | Activity-noise gated for bases. |
| Neutral | `#bbbbbb` | Broadcasting POIs (gates) only, unless scouted. |

Icons by type: `HomeBase` ▲, `Base` ◣, `Gate` △, `Resource` ◆, `Fleet` ●.

---

## Architecture & reuse

- Builds on today's [`PlanetSurfaceCoordinates`](../../Assets/Scripts/Macro/PlanetSurfaceCoordinates.cs) (frame) and absorbs [`PlanetSurfaceReadout`](../../Assets/Scripts/Macro/PlanetSurfaceReadout.cs) (coord line) into `SurfaceCompassHUD`.
- Camera coupling is read-only (heading from `GroundBuildOrbitCamera`'s transform + target); the HUD never drives the camera. A future **click-compass / click-minimap → recenter** is an `open thread`, gated until camera control centralizes.
- Tunables (`COMPASS_FOV_DEG`, ribbon width, minimap radius, marker sizes, colors) locked on the components for v1; promote to a config asset if balance tuning gets frequent.

## Phasing (build order)

1. ✅ **Compass strip** (BUILT) — full-screen-width cardinal heading + cursor LAT/LON/ALT (readout folded in) + Helion clock. Standalone top-left readout retired. Own-base + surface-base POI ticks still to wire.
2. ◧ **Nav-minimap** (PLACEHOLDER BUILT) — framed corner circle; the data-driven blip field + north-up rendering remain to build.
3. **More POI sources** — resource markers, jump gates.
4. **Enemy gating** — wire `BaseNoiseEmitter` + sensor range (Phase 6.9.E) so enemy bases obey activity-noise stealth.

> Packaging: 1 + 2 ship as the shared `SurfaceNavHud` prefab, instanced per planet scene via `SurfaceNavHudSetup` (see *Portability*).

## Bridges (live-data discipline)

- `SurfacePoiProvider` enemy-visibility gating is **not** authoritative until 6.9.E/6.9.F land — v1 shows own + allied + broadcasting POIs only. `// BRIDGE: enemy POI reveal awaits BaseNoiseEmitter + server FOW (6.9.E/6.9.F)`.
- "Your position / heading" uses the **camera view anchor**, not a real ship, until surface fleets land. `// BRIDGE: view-anchor stands in for the player ship until surface fleets exist`.
- Both tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md) Phase 6.9 bridges.

## Open threads

- **Cursor vs view-center** for the coordinate line (defaulting Cursor; flip when a ship avatar exists).
- **North-up vs heading-up** minimap default.
- **Click-to-recenter** on compass/minimap (needs centralized camera control).
- **Marker clustering** when POIs crowd a bearing (count badge), as in the combat minimap doc.

## See also

- [`../combat/combat_minimap_signatures.md`](../combat/combat_minimap_signatures.md) — combat-arena signature radar (shared conventions).
- [`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md) — three-scope FOW + activity-noise reveal.
- [`world_surface_scene.md`](world_surface_scene.md) — Scene 3 surface; base placement + noise stealth.
- [`PlanetSurfaceCoordinates`](../../Assets/Scripts/Macro/PlanetSurfaceCoordinates.cs) / [`PlanetDayNightCycle`](../../Assets/Scripts/Macro/PlanetDayNightCycle.cs) — the shared per-planet frame + day/night.
