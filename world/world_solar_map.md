# Solar System Map

The Helion solar system map (`Assets/Scenes/Maps/SolarSystem.unity` / `Vesperion.unity`) is the top-level navigation surface — the player's primary view of the whole star system, its planets in their live orbits, and the dynamic jump-gate network that links them. It sits in the **macro layer** (PlayFab + lazy evaluation, no Photon Fusion runner). Combat and mining-op event instances live elsewhere; nothing on this map ever spins up a `NetworkRunner`.

> **Phase 6.9 canon (added 2026-05-29):** Solar / SystemView **is hyperspace itself**. The fleet pointer icons on the map represent fleets in hyperspace / light-speed travel between bodies. Voluntarily clicking a planet's entry POI triggers `SceneManager.LoadScene("LowOrbit")` (Scene 2 — see [`world_low_orbit_scene.md`](world_low_orbit_scene.md)). Interception (attack timer maturation while in hyperspace) drops into the existing blank-space combat sandbox — NOT Low Orbit, NOT Surface. Per Phase 6.9.B, planet POIs in this scene render as **3D Planet Forge thumbnails** instead of legacy MeshRenderer spheres for visual continuity with Scene 2 and Scene 3.

This doc is the canonical reference for everything that renders on the SolarSystem scene. When labels, lines, or schedule UI regress, this is where to look first.

## Two view states

`SolarSystemZoomController.ViewState` drives a zoom-anchored two-state model:

| State | Camera | What renders |
|---|---|---|
| **SystemView** | Wide ortho — whole system in frame. | Sun, parent bodies (planets, named asteroids), parent name labels, faction territory bands (when toggled), jump-gate connection lines (when toggled), gate-line timer chips (when toggled), shipyard / control overlays, fleet bar. |
| **PlanetView** | Zoomed onto one parent's orbit. | Same as SystemView **plus** that parent's `SatelliteOrbits` subtree — moons, POIs, jump gates, with their own labels and orbit rings. Other parents' children stay hidden. |

Transition: mouse-wheel zoom past a threshold pushes the controller into PlanetView with the nearest parent set as `CurrentTarget`. Wheel back out returns to SystemView. PlanetView is "x-ray on one planet"; the rest of the map keeps drawing.

## Label rules

`SolarSystemBodyLabel` (Assets/Scripts/Macro/SolarSystemBodyLabel.cs) is the canonical name renderer for every body — parents AND children. Each instance owns its own world-space TMP canvas, billboards to the camera, and scales linearly with `cam.orthoSize` so labels read at constant pixel size at every zoom.

Rules:

- **`displayName` is required.** Authored from the celestial registry's `CelestialParentRecord.displayName` / `CelestialChildRecord.displayName`. Falls back to GameObject name when blank — never rely on this fallback in shipping content. If a body's name is missing in either view, run `Apex Outlaw / Repair / Repopulate Solar System Body Labels From Registry` to rewrite from the registry mirror.
- **Parent labels always render.** Sun + every `Planet_*` / `Asteroid_*` parent body shows its name in both views.
- **Child labels render only in PlanetView, only on the focused parent.** Children live under `SatelliteOrbits`, which `SolarSystemZoomController` toggles per-planet — the visibility gate is the parent's `SatelliteOrbits.activeSelf`. In SystemView every child subtree is inactive; in PlanetView only the focused parent's subtree is active.
- **Faction tag is inlined.** When `factionTag` is set on a label, the renderer emits `[FED] Concordia` / `[ICE] Ferrum` as a single TMP rich-text string. Color comes from `factionColor`. The tag is sourced from the registry's `baselineFactionId` — keep them in sync via the repair tool.
- **Jump-gate markers suppress their world-space label.** `JumpGateMarker.LateUpdate` sets the marker's own `BodyLabel_Canvas` inactive — gate identity reads through the schedule UI, not in-world tags. Each gate's host body label still renders normally.

## Jump-gate schedule UI

The map IS the schedule. When the **Jump Gates** toggle is on, every active connection line drawn by `JumpGateNetworkVisualizer` carries an inline timer chip — Cyberpunk-RPG-UI styled — riding the line itself. There is no sidebar, drawer, or modal.

### Inline timer chips

`JumpGateLineChip` is a world-space canvas anchored at the midpoint of each connection line, billboarded to the camera, sortingOrder above the line and below screen-space UI (mirrors `SolarSystemBodyLabel`'s pattern).

Anatomy:
- **Frame** — 9-sliced `Pick_frame_*` from `Assets/Art_Assets/Cyberpunk_RPG_UI/UI_Parts/`. Tint cycles by status:
  - `Pick_frame_g.png` — open + stable (no close inside horizon)
  - `Pick_frame.png` (neutral) — open, normal countdown
  - `Pick_frame_o.png` — open, closing in <30 s; pulses on a 1 Hz alpha curve
  - `Pick_frame_p.png` — currently closed but reopens within horizon
  - `Pick_frame_r.png` — one-way / restricted
- **Status icon** — small icon from `Icons_256_256/`, tinted to match the frame.
- **Countdown** — monospaced TMP text, `2m 14s` / `47s` / `—`.
- **Progress bar** — thin `Energy_line.png` underline that shrinks left-to-right toward zero as the timer ticks down. Reads as an analog "fuel gauge".

Placement: default at line `t=0.5`. When two chips would overlap (parallel near-coincident lines, common around hub planets), a bounded iterative pass nudges each chip's `t` away from conflict. Chips offset by a small camera-up vector so they float above the line; billboard each frame.

One-way connections get two chips, one near each endpoint, each with an arrow icon pointing toward the destination it can reach. Closed-but-reopens-soon pairs draw a faded/dashed line variant alongside their purple `OPENS in Xs` chip.

### Player anchoring

The schedule prioritizes the player's neighborhood. Anchor body resolves to the parent of the body identified by `PlayFabManager.Instance.ActiveProfile.currentSectorID` (sector id == body id by canon). If empty, fall back to `homeBaseSectorID`. If both empty, no anchoring — every chip renders at base size.

Visual weight by hop distance from the anchor:
- **Anchor (hop 0)** — chip renders at 1.0× scale with a `Big_vert_frame_b.png` glow accent.
- **Hop 1** — base render.
- **Hop 2+** — 80 % scale, 70 % alpha — visually deprioritized but still legible.

Hop distance is BFS over the current `BubbleReaches` adjacency.

### Companion: Next 3 Departures widget

`SolarSystemNextDeparturesWidget` — small ~140 px corner widget anchored top-right. Lists the three soonest events from the player's anchor body — open lines closing soonest, plus closed lines reopening soonest. Backed by `Big_vert_frameonly.png`. Click a row to pan/zoom the camera to that line's midpoint.

The widget exists because chips can be off-screen when the player zooms in close. It's the on-screen guarantee that the next events aren't missed.

### Visibility

Both the line chips and the corner widget are visible iff `JumpGateNetwork.linesVisible == true`. The same toggle in `SolarSystemFactionToggles` gates everything.

### Prediction model

Two pure-function-of-time predictors on `JumpGateNetwork`:

- `PredictDisconnectSeconds(from, to, horizon=3600)` — for currently-open pairs; returns seconds until `BubbleReaches` flips false. `+inf` when stable beyond horizon.
- `PredictReconnectSeconds(from, to, horizon=3600)` — for currently-closed pairs; returns seconds until `BubbleReaches` flips true. `+inf` when no reconnect within horizon.

Both step real-time at 5 s granularity through `CelestialOrbiter.PredictPositionAt`, which is itself a pure function of `(UtcNow - CelestialEpoch)` per the celestial-clock canon.

## Authoring rules

- **Bodies and POIs come from the celestial registry.** PlayFab title-data key `CelestialRegistry`, mirrored at `Assets/GameData/Celestial/seed.json`. Edit the registry; do not hand-bake bodies into the scene. See [`architecture/architecture_plan.md`](../architecture/architecture_plan.md) §1.5.
- **Jump gates follow the bubble-radius model.** One `POI_<bodyId>JumpGate` per body, parented under `Planet_<bodyId>/SatelliteOrbits/`. Connectivity computed each frame from `JumpGateMarker.bubbleRadius`. See [`world_sector_map.md` § Jump gate authoring canon](world_sector_map.md#jump-gate-authoring-canon). The legacy chain-pair model is deprecated.
- **Faction = alliance.** A faction IS an alliance per [`world_faction_sovereignty.md`](world_faction_sovereignty.md) §3. FED and ICE are alliance ids in `ownerId` / `baselineFactionId`. No separate faction concept.

## Live-data discipline (CLAUDE.md)

Every player-visible piece of the map wires to live data on the first pass:

- **Body display names** → registry (`displayName` field).
- **Gate adjacency / radius / faction** → live `JumpGateMarker` graph populated by `CelestialChildBuilder` from the registry.
- **Schedule predictions** → live from `CelestialOrbiter.PredictPositionAt`.
- **Player current planet** → live from `PlayFabManager.Instance.ActiveProfile.currentSectorID`.

Nothing on this map should be hardcoded into the scene. If a wire-up isn't possible today, mark with `// BRIDGE: remove when <X> lands` and add an entry under [`master_to_do.md`](../meta/master_to_do.md) "Bridge code to remove".

## Repair workflow

When labels go missing or the chip UI desyncs:

1. **`Apex Outlaw / Repair / Repopulate Solar System Body Labels From Registry`** — walks the open scene, matches each parent body's GameObject id to a `CelestialParentRecord`, and writes `displayName` + `factionTag` onto its `SolarSystemBodyLabel`. Idempotent. Re-runnable.
2. **Toggle Jump Gates off and back on** — forces `JumpGateNetworkVisualizer` to repopulate the chip pool with a fresh registry pass.
3. **If a body is missing from the scene entirely** — it's a registry / spawner issue, not a label issue. See `CelestialSpawner` and the gate-canon authoring rules.

## Critical files

| Concern | File |
|---|---|
| Two-view state machine | `Assets/Scripts/Macro/SolarSystemZoomController.cs` |
| Body name labels | `Assets/Scripts/Macro/SolarSystemBodyLabel.cs` |
| Gate marker (radius, faction) | `Assets/Scripts/Macro/JumpGateMarker.cs` |
| Network singleton + predictors | `Assets/Scripts/Macro/JumpGateNetwork.cs` |
| Connection line + chip rendering | `Assets/Scripts/Macro/JumpGateNetworkVisualizer.cs` |
| Inline chip world-space canvas | `Assets/Scripts/Macro/JumpGateLineChip.cs` |
| Next-3 corner widget | `Assets/Scripts/UI/SolarSystemNextDeparturesWidget.cs` |
| Cyberpunk sprite resolver | `Assets/Scripts/UI/CyberpunkUiSprites.cs` |
| Toggle button | `Assets/Scripts/UI/SolarSystemFactionToggles.cs` |
| Registry source | `Assets/Scripts/Schemas/Celestial/CelestialRegistry.cs` |
| Registry client (PlayFab + seed fallback) | `Assets/Scripts/Macro/Celestial/CelestialRegistryClient.cs` |
| Editor repair tool | `Assets/Editor/SolarSystemBodyLabelRepair.cs` |
