# Hotkeys

Living reference for every keyboard / mouse binding in the game. Update this file whenever a new hotkey is added — grep for `wasPressedThisFrame` / `isPressed` to verify the list against code if you suspect it's stale.

---

## Base scene — camera (`BaseBuildOrbitCamera`)

| Key | Action |
|---|---|
| `W` / `A` / `S` / `D` | Pan camera focus on the XZ plane (forward / left / back / right). Suppressed while Shift is held so combos don't also pan. |
| `Q` / `E` | Turn the camera in place (yaw). Camera world position stays put; only look direction rotates. Suppressed while a build ghost is selected — then Q/E rotates the ghost instead. |
| `R` / `F` | Tilt the camera (pitch). **F** = tilt-in-place down, capped at the focus.y constraint (won't lower further once focus would clip below the build plane). **R** = tilt-in-place up; once it hits the constraint, switches to **orbit-up**: pitch keeps increasing toward `maxPitch`, focus stays put, distance shrinks to keep camera Y at `min(currentY, cameraMaxY)`. Hold R from any angle to glide to birds-eye without crossing the `cameraMaxY` ceiling. |
| Mouse scroll wheel | Zoom in / out (multiplicative — each notch moves a fixed fraction of current distance). |
| Right-mouse drag | Orbit (mouse-look): pitch/yaw change, camera arcs around the focus. |
| Middle-mouse drag | Pan focus point in camera-relative space. Focus Y is clamped after the pan. |
| `Shift + F` | Birds-eye reset — snap pitch to `maxPitch`, distance to `cameraMaxY / sin(maxPitch)` so camera lands at Y = `cameraMaxY` (default 50). Focus Y → `focusMinY`. Keeps current XZ. Mirrors `TacticalCameraController` Shift+F. |
| `Shift + B` | Birds-eye reset + recenter on the base. Same Y = `cameraMaxY` snap as Shift+F. Resolution order for the XZ recenter: placed Outpost chassis → inspector `focus` transform → world origin. |

## Base scene — placement (`BaseBuildController`)

| Key | Action |
|---|---|
| Left click | Place / select / click-to-build (panel-mediated). |
| `Q` / `E` (while a ghost is selected) | Rotate the placement ghost (free-place yaw). Camera's Q/E is suppressed while placing. |
| `Delete` / `Backspace` (with a placed part selected) | Remove the selected placed part. |
| Right click | Deselect ghost / cancel placement. |

## Base scene — drone (`BaseDroneFleet`)

| Key | Action |
|---|---|
| `Shift + D` | **Summon** the construction drone — drops any carried piece in place, parks the drone in front of the camera (~6 units forward, 0.5 below eye level), looks at the camera. Press again to dismiss; drone returns to its prior state. Phase 1: future "ask the drone a question" UI hooks into the summoned state. |

## Tactical scene (`TacticalCameraController`)

| Key | Action |
|---|---|
| `W` / `A` / `S` / `D` (or arrow keys) | Fly camera horizontally. |
| `Q` / `E` | Rotate camera (yaw). |
| `R` / `F` | Tilt camera (pitch). |
| `Shift + F` | Birds-eye snap — pitch to 90° (top-down). |

---

## Conventions

- **Shift modifiers are reserved for one-shot snaps / actions** that should not also trigger their unmodified counterparts. Camera `BaseBuildOrbitCamera.HandleKeyboard` suppresses WASD pan while Shift is held to enforce this.
- **`wasPressedThisFrame` for one-shots, `isPressed` for held actions.** Snap shortcuts (Shift+F/B/D) must use `wasPressedThisFrame` so a single tap doesn't fire repeatedly.
- **No `Input.GetKey` API.** This project uses the New Input System exclusively (`UnityEngine.InputSystem.Keyboard.current` / `Mouse.current`).

## When you add a new hotkey

1. Add the binding in code with a comment that includes the literal hotkey string (e.g. `// Shift+D:`).
2. Add a row to the right table above.
3. If it's a snap / combo, suppress conflicting input in the same handler (see WASD / Shift suppression in `BaseBuildOrbitCamera`).
