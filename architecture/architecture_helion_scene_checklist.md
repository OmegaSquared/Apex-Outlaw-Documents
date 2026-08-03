---
status: superseded
superseded-by: "[[architecture_overview]]"
deprecated-on: 2026-05-29
last-reviewed: 2026-06-07
phase: "6.9"
tags: [architecture, deprecated]
---

# Helion.unity — Scene Authoring Checklist — DEPRECATED

> **DEPRECATED as of 2026-05-29.** Helion's "single continuous world" model is superseded by the **three-scene architecture** (Solar / Low Orbit / Surface). See:
> - [`architecture_overview.md`](architecture_overview.md) for the three-scene canon
> - [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md) for Scene 2 authoring
> - [`../world/world_surface_scene.md`](../world/world_surface_scene.md) for Scene 3 authoring
> - Meta-plan: `~/.claude/plans/if-i-was-going-mutable-parnas.md`
>
> The checklist below is preserved for reference because **some components remain valid for Solar view (Scene 1, `Vesperion.unity`)** — specifically `MacroFOWOverlay`, `MacroSyncMesh`, `MacroPartyService`, and `MacroSelectionManager`. If you're authoring or patching the **Solar** scene, this checklist's component list is still partially useful. If you're authoring **Low Orbit** or **Surface** scenes, use the new docs above instead.
>
> **Important:** the FOW model has expanded from one shared FOW to **three scopes** (my-client, server-side, their-client). See [`../combat/combat_fog_of_war.md`](../combat/combat_fog_of_war.md). The Helion checklist's `MacroFOWOverlay` covers only the my-client-FOW visualization; the server-side scope (Phase 6.9.F `ServerFowMatcher`) is new and lives in CloudScript, not in a Unity scene.

---

## Original checklist (preserved for Solar-view reference)

Hand-author checklist for the new `Assets/Scenes/Maps/Helion.unity` scene. Mirrors the boot pattern of `SolarSystem.unity`. Do not rebuild — once Helion exists, patch in place per the "patch, don't rebuild scenes" project rule.

## Required GameObjects

1. **Root: `Helion`** (empty GameObject at world origin).
2. **`Helion/CelestialClock`** — empty + `CelestialClock` component. Drives the orbital math from `CelestialEpoch` title-data.
3. **`Helion/CelestialSpawner`** — empty + `CelestialSpawner` component. Subscribes to `CelestialRegistryClient.OnRegistryUpdated` and instantiates parents/children. Same component used by SolarSystem.unity.
4. **`Helion/MacroFOWOverlay`** — empty + `MacroFOWOverlay` component. Renders the fog quad. The overlay reads from `MacroFOWUnion`, which already consumes `MacroSyncMesh` clusters + `MacroPartyService` party union (Phase 6.7.B).
5. **`Helion/MacroSyncMesh`** — empty + `MacroSyncMesh` component. Singleton; rebuilds the friendly proximity graph each frame.
6. **`Helion/MacroPartyService`** — empty + `MacroPartyService` component. In-memory party stub (Phase 6.7.B).
7. **`Helion/MacroSyncVisualizer`** — empty + `MacroSyncVisualizer` component. Draws the player-fleet sync ring + cluster edge lines and posts "Sync lost" / "Sync regained" toasts via `NotificationManager`.
8. **`Helion/MacroSelectionManager`** — empty + `MacroSelectionManager` component. Singleton fleet registry (existing macro-layer component).
9. **`Helion/Camera`** — `Camera` (orthographic) + `HelionCameraController` + `HelionViewModeController`. Initial ortho size = 600 (Tier 0 snap default). Initial position over the player's spawn point.
10. **`Helion/EventSystem`** — standard UGUI EventSystem + InputSystemUIInputModule for the new Input System.

## Wiring

- Add `Assets/Scenes/Maps/Helion.unity` to **Build Settings → Scenes In Build** so addressables / `SceneManager.LoadScene` can target it.
- Confirm `GlobalHUDBootstrap` runs (it does — `RuntimeInitializeOnLoadMethod`); the addressable HUD installs over Helion the same way it does over other macro scenes.
- `NotificationManager` self-installs the first time something calls `Post()` — no scene wiring needed.

## Tunables to set in inspector

- `HelionViewModeController.nearPlanetRange` — defaults to 60000 world units. Tune against Helion's actual world extent so PlanetSystem-tier becomes available within ~one planet's local zone.
- `HelionCameraController` tier bounds — defaults framing assumes Helion world half-extents ≈ 250000 units. Adjust `solarMaxOrtho` to fit the system on Tier 2 without empty margin.
- `HelionCameraController.worldHalfExtents` — set to actual Helion bounds once celestials spawn.

## Verification

- Open `Helion.unity`, hit Play.
- Wait for `CelestialEpochFetcher` boot (or local `seed.json` fallback) → confirm celestials spawn.
- Default tier = Fleet (Tier 0). Press M:
  - If near a planet → switches to PlanetSystem (Tier 1).
  - If not → skips to SolarSystem (Tier 2).
- Press M again → cycles forward.
- Try mouse-wheel zoom-out at Tier 2 → confirm hard cap, no scrolling past `solarMaxOrtho`.
- Spawn a friendly test fleet near the player (alliance match) within sync radius → confirm sync ring + edge line render.
- Move it outside the radius → confirm "Sync lost" toast appears in the top-right HUD area.
- Move it back → confirm "Sync regained" toast.

## What Helion does NOT need (yet)

- Sector zone subdivisions — those land later as registry-driven logical regions, not authored GameObjects.
- Floating origin / scaled space — only needed if Helion world extent exceeds float32-safe range. Verify after initial registry spawn; if fine at raw scale, skip Phase 6.7.C.2.
- Phase 6.7.E CloudScript hooks — the scene runs entirely on client-side mesh FOW until that lands.
