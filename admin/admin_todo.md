# Admin — TODO

Tracks in-game admin tools. See [admin_overview.md](admin_overview.md) for the structure and persistence rules.

## In progress

_(none — pick up the next item below)_

## Backlog

### Tier 1 — Tuning knobs that we know we want now

- **Fleet visual scale multiplier** — same shape as `CelestialOrbitSpeed`, hooked at the fleet renderer.
- **FOW alpha / mask debug** — see `VesperionDebugFowColor` / `VesperionToggleFow` editor scripts for the patterns to lift into the runtime panel.
- **Sun intensity / scene tint** — currently tuned via `VesperionTuneSunIntensity` editor patcher; runtime slider would replace it.
- **Time-of-day scrub** — wire `CelestialClock.DesignerOffsetSeconds` to a slider in the admin panel. Lets you preview "where is everything in 6 hours?" without changing the orbital speed multiplier.
- **Jump-gate range controls** — add a tab/section in `AdminPanel` to view and tune jump-gate bubble radii live. Two flavors to consider: (a) a global multiplier on every gate's `JumpGateMarker.bubbleRadius` (PlayerPrefs, mirrors `CelestialOrbitSpeed` shape), useful for quick "tighter or looser links?" passes; (b) a per-gate inspector that lists every gate id + its current radius with an editable field, mirroring the existing editor-only `JumpGateAdminWindow` (`Assets/Editor/Celestial/JumpGateAdminWindow.cs`) but rendered in-game so it can be used during play. The per-gate flavor should write through to the live PlayFab `CelestialRegistry` via the existing admin path so changes are cross-client; the global multiplier stays local. Editor tooling: `ScaleJumpGateRadii.cs` + `HalveJumpGateBubbleRadii.cs` are the patterns to lift from.

### Tier 2 — Larger features (not until Tier 1 stabilizes)

- **Cross-client title-data settings** — promote select Tier-1 knobs into PlayFab title data so they affect every player simultaneously. Requires CloudScript handler `setAdminTitleData` with admin-claim guard.
- **Live entity inspector** — click any body / fleet / POI in the scene, see its current networked / registry state, tweak fields, broadcast change.
- **Replay scrubber** — record the last N seconds of fleet movement + combat ticks, scrub backwards. Useful for bug triage.

## Done

- **Orbital speed multiplier (admin slider)** — global multiplier on every `CelestialOrbiter` (planets, moons, named asteroids, procedural belt rocks). Hooked at `CelestialPositionEvaluator.AngleDegAt`, persisted to PlayerPrefs. Toggle the admin panel with **F10** and drag the slider. Non-admin players never see the panel and always experience the canonical 1.0× world (the getter rejects stored prefs for them). _Shipped: 2026-05-14._
- **Admin entitlement gate** — `AdminGate.IsAllowed` now delegates to `ApexOutlaw.Common.AdminRole.IsLocalPlayerAdmin` (PlayFab `"admin"` player tag). The hotkey, panel, and the `CelestialOrbitSpeed` setter all gate on this. _Shipped: 2026-05-14._

## Conventions

- Each Tier-1 knob is one file under `Assets/Scripts/Admin/`.
- Each knob persists to PlayerPrefs by default. Promote to PlayFab only when listed under Tier 2.
- The admin panel's row order matches the order knobs are listed in **Done** + **In progress** + **Backlog**, so the panel reads as a current snapshot of this doc.
