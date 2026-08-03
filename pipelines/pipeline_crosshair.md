# Pipeline — Crosshairs (cursor / aim reticle states)

The custom mouse crosshair. Turns the OS pointer into a "Crosshairs Plus" reticle that changes shape + color by what the cursor (or the player's ship) can interact with. Follows the standard [six-stage schema pipeline](pipelines_overview.md).

> **Reframe that matters:** Apex Outlaw is pointer-driven, not an FPS. In both the macro (sector/planet) and combat (Fusion) layers the mouse is a *smart cursor*, not a stick-steered aim. So "if a ship can interact, the crosshair changes" = the cursor previews the click/aim verb. The pack's `_hip` art = the passive cursor; `_zoom` art = the "actionable / locked" reticle.

---

## 1. Schema — `CrosshairSchema`

`Assets/Scripts/Schemas/CrosshairSchema.cs` (namespace `ApexOutlaw.Schemas`). One asset **per state**, keyed by the `CrosshairContext` enum.

| Field | Meaning |
|---|---|
| `context` | Which state this draws. Catalog is keyed by it — one schema per value. |
| `restSprite` | Passive reticle (a sliced **hip** sub-sprite). |
| `focusSprite` | Actionable reticle (usually a **zoom** scope sub-sprite). Falls back to `restSprite`. |
| `tint` / `focusTint` | Color applied to the (white) art. Use the canon palette below. |
| `restScale` / `focusScale` | Size multiplier on `CrosshairController.baseSizePixels`. |
| `pulseOnFocus` / `pulseSpeed` | Gentle scale-breathing on the actionable reticle (Attack / Mine / Jump / missile). |

### `CrosshairContext` states
`Default, Move, SelectFriendly, Interact, Jump, Mine, Attack, JoinBattle, Blocked` (macro pointer) and `CombatIdle, CombatAcquiring, CombatLocked, MissileArming` (tactical reticle).

### Canon palette (verbatim from `TacticalMinimap` — see [`../combat/combat_minimap_signatures.md`](../combat/combat_minimap_signatures.md))
`white #ffffff` · friend/FED-blue `#3aa2ff` · alliance-green `#7be07b` · foe-red `#ff5333` · neutral-gray `#bbbbbb` · range-amber · FOW-cyan · missile-orange. The cursor speaks the same color language as the rest of the HUD.

---

## 2. Setup script — `Crosshair_Setup`

`Assets/Editor/Crosshair_Setup.cs` → menu **Apex Outlaw → Setup → Build Crosshair Schemas (slice + bake)**. Idempotent.

1. Re-imports the **white** sheets as sliced sprites:
   - `Assets/Spags Assets/Textures/white_hip.png` → **3×3** grid, named `white_hip_r{row}_c{col}` (row 0 = top). ⚠️ The white master only fills the **top two rows (6 reticles)** — its bottom row is blank (the colored sheets carry 9). So the mapping uses only `r0_*`/`r1_*` for hip shapes.
   - `Assets/Spags Assets/Textures/white_zoom.png` → **4×4** grid (16 scopes), named `white_zoom_r{row}_c{col}`.
   - Only the white sheets are sliced — the art is tinted at runtime, so the colored sheets in the pack go unused. (If you want the missing chevron/hex shapes, slice a colored sheet and reference its sub-sprite instead.)
2. Bakes one `CrosshairSchema` per context to `Assets/Resources/Schemas/Crosshairs/crosshair_<Context>.asset`, wiring the rest/focus sub-sprites + canon tint per the mapping table in the script.

**To retune a reticle:** edit the `Bake(...)` line for that context in the setup script (swap the `Hip(r,c)`/`Zoom(r,c)` cell or the color) and re-run the menu. Don't hand-edit the `.asset` in the inspector — a re-bake overwrites it.

---

## 3. Catalog — `CrosshairCatalog`

`Assets/Scripts/Schemas/Catalog/CrosshairCatalog.cs`. `Resources.LoadAll<CrosshairSchema>("Schemas/Crosshairs")`, cached by context (runtime-safe in player builds, mirrors `RecipeCatalogLoader`). `Get(context)` → schema or null. Falls back to the OS cursor when empty (before first bake).

---

## 4 + 5. Runtime — controller + context providers

`Assets/Scripts/UI/Crosshair/CrosshairController.cs` — self-installing singleton (a `RuntimeInitializeOnLoadMethod` spawns one persistent instance). Draws a single non-raycasting `Image` on a max-sort ScreenSpaceOverlay canvas, hides the OS cursor while a reticle shows, restores it over UI / in menus, and pins to screen-center when the hardware cursor is locked (drone-pilot mouselook).

Each frame it polls registered **`ICrosshairContextProvider`s** in descending priority and draws the first that's live:

| Provider | Priority | Reads | File |
|---|---|---|---|
| `TacticalCrosshairContextProvider` | 100 | local player ship `inAttackMode`, turret `isAimSecured`/`currentTarget`, missile `IsTargeting` | `Assets/Scripts/Tactical/` |
| `MacroCrosshairContextProvider` | 50 | `MacroInteractionResolver.Classify` (hover) + `EventSystem` over-UI | `Assets/Scripts/Macro/` |

`MacroInteractionResolver` (`Assets/Scripts/Macro/MacroInteractionResolver.cs`) is a **read-only** mirror of `MacroSelectionManager.IssueCommandToSelected`'s target-priority ladder (join window → hostile-in-ring → mining → gate → interactable → fleet → ground), so the cursor previews exactly what a click does.

Add a future provider (e.g. mining-op instance) by implementing `ICrosshairContextProvider` and calling `CrosshairController.Instance.Register(...)`.

---

## 6. Authoring checklist — add a new crosshair state

1. Add a value to `CrosshairContext` in `CrosshairSchema.cs`.
2. Add a `Bake(...)` line for it in `Crosshair_Setup.cs` (pick rest/focus cells + tint + scale).
3. Run **Apex Outlaw → Setup → Build Crosshair Schemas**.
4. Emit the new context from a provider's `TryGetContext` where the new situation is detected.

---

## Known bridges / follow-ups

- **`// BRIDGE`-free.** The crosshair reads live scene/selection/aim state; only the visual blueprints are static assets (like ship/tile schemas). No scene-baked data.
- **Resolver unification (tracked):** `MacroInteractionResolver` currently *mirrors* `MacroSelectionManager`'s classification (two tiny helpers duplicated). Route `IssueCommandToSelected` through the resolver so there's a single classifier with zero duplication — gated on a playtest pass.
- **Mining-op reticle:** add a `MiningOpCrosshairContextProvider` when the mining-op Fusion scene lands ([`../meta/master_to_do.md`](../meta/master_to_do.md) Phase 4.2d).
- **Aim-zoom (ADS):** if direct mouse-aim combat is ever added, the `_zoom` art is already wired as the focus reticle — point an ADS toggle at `CombatLocked`/`focusSprite`.
