# Admin — Overview

In-game tools that let a privileged user (Aaron, dev, future GM) tune live systems while playing — without recompiling or leaving the running session.

Goals:
- **Fast iteration**: change one knob (orbital speed, fleet scale, FOW alpha, etc.) and immediately see the result in the running scene.
- **Safe by default**: admin entry points are gated, never on by default in shipped builds, and never write to authoritative PlayFab state without an explicit save action.
- **Pure overlays, no scene churn**: admin tools must NOT mutate scene files (`*.unity`) at runtime — they tweak in-memory state, optionally persisted to PlayerPrefs or PlayFab title data.

## Components
- `AdminPanel` — runtime OnGUI overlay, toggle key F10. Single panel with grouped tabs.
- `AdminGate` — decides who can open the panel. Backed by `ApexOutlaw.Common.AdminRole.IsLocalPlayerAdmin`, which only returns true after the PlayFab player-tag fetch resolves AND the caller carries the `"admin"` tag. A client-side bypass would only fool the local UI — every privileged write is re-validated server-side by `cloudscript/celestial_admin.js`.
- Per-feature setting holders — small static classes (e.g. `CelestialOrbitSpeed`) the panel reads/writes. Each setting owns its own persistence (PlayerPrefs for client-local, PlayFab title data for cross-client).

## Persistence layers
1. **Client-local** (PlayerPrefs) — convenience tunings only the admin sees. Default for visual / pacing knobs.
2. **PlayFab title data** — cross-client tunings that should affect every player. Requires CloudScript handler + admin write entitlement. Off-limits until those land.

Always start a new feature in layer 1. Promote to layer 2 only when other players need to see the change.

## Adding a new admin setting — checklist
1. Add the setting holder under `Assets/Scripts/Admin/<Feature>Setting.cs` (static class, get/set, fires an event on change).
2. Wire it into the system it affects (single hook — multiple hooks = drift).
3. Add a row in `AdminPanel` under the appropriate group.
4. Decide persistence layer (1 or 2) and implement; default to PlayerPrefs.
5. Add a `*_todo.md` entry under "Done" when shipped.

See [admin_todo.md](admin_todo.md) for current work.
