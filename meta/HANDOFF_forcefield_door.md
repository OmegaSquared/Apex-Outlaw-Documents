# Session handoff — Smuggler base parts (curved set, floor, force-field door)

**Date:** 2026-06-02. Read this, then continue the **force-field door** (the only unfinished part).

---

## 1. COMMITTED & done (branch `smuggler-floor-curved-parts`, commit `1e5edac`)
Not yet merged to `master`, not pushed. To land: `git checkout master && git merge smuggler-floor-curved-parts`.
- **Curved wall** (`Tile_Wall_Curved_T1_Smuggler`) + **curved rail** (`Tile_Railing_Curved_T1_Smuggler`) — 90° arcs that snap to the rounded foundation's new **arc `FoundationTop` socket** `(-5.657,4,5.657)`.
- **Floor/Ceiling** (`Tile_Floor_Square_T1_Smuggler` + `_Lit`) — rusted-steel deck top, 3D I-beam underside, Lit = yellow fluorescent tubes + 6 real point-lights.
- **Build menu:** WALLS tab now splits into **RAILS / WALLS** dividers (`BaseBuildPanel.IsRailingTile`).
- **`SurfaceTilePlacer` fixes:** **cursor-cell lock** (candidates filtered to the cell under the cursor; fills key off the placed piece, non-fills off their host tile; fallback keeps full set if nothing lands in-cell), default-pick ranks by placement footprint-centroid, and the wall overlap-guard now compares centroids (fixes corner-pivot curved walls false-blocking on a shared-centre circle).
- ⚠️ **NOT play-tested yet** — Aaron never confirmed the placer fixes in play mode. First task next session could be: play-test placement (snap to pointed cell, complete a 4-piece curved-wall circle, rounded-foundation flat-side clamping).
- Unrelated SciFi-pack `.mat` URP conversions are dirty in the working tree — **leave them**, not ours.

## 2. IN PROGRESS — Force-field door (NOT baked)
Goal (Aaron's ref image): smuggler wall with an **arched opening** holding a **blue energy force field**, + a **conduit-styled power plug** in the wall.

**Geometry DONE** — saved at `Assets/Prefabs/Bases/Tiles/Forcefield_Door_T1_Smuggler/Forcefield_Door_T1_Smuggler_WIP.fbx`
(also live in Blender as object `FF_Door_WIP`). Submeshes: **0 hull · 1 molding · 2 frame+plug+edge-trim**. It's the imported straight wall, boolean-cut with an arch, + a conduit plug (bottom-left front) + slim left/right edge trim. Symmetric height = same 8 m wall snap.

**KEY architecture decision (Aaron):** the force field is **power-dependent** — when power is off the field is off. So **DO NOT bake the field into the wall mesh.** Build it as a **separate, game-controlled toggleable child** (energy plane + blue point-light) that code switches on/off with power. Default it ON for now + add `// BRIDGE: remove when surface-tile power gating lands` and a `master_to_do.md` entry. (Conduit plug = where it's powered; wire to [progression_wiring.md] when that system reaches surface tiles.)

**Force-field textures generated** (blue energy): `Temp/ff_tex_1.png` (electric radial — most "shield"), `ff_tex_2.png` (tech rings), `ff_tex_3.png` (organic webs). Aaron's last input was ambiguous ("2", then interrupted) — **CONFIRM the field pick** before applying. They came out more electric than his pale-mottled reference; offer a softer re-gen (ComfyUI up at `127.0.0.1:8188`, SDXL RealVisXL set; see the `forcefield` prompt I used — pure SDXL, no IP-Adapter).

**"Top/bottom must match the other walls"** (Aaron's last note): the white top/bottom in the Blender preview is just the **untextured imported-FBX molding material** — cosmetic. The fix is at BAKE: assign **slot 0 = `Smuggler_WallHull`** (SM3_Yellow + SM3_Normal) and **slot 1 = `Smuggler_WallMolding`** (the straight wall's baked rust `.mat`, at `Assets/Prefabs/Bases/Tiles/Wall_Straight_T1_Smuggler/Materials/Smuggler_WallMolding.mat`) so the door's hull + crown/base molding are identical to the straight wall. Slot 2 (frame/plug/trim) = a rusted iron (`Smuggler_Iron`).

### Next steps to finish the door
1. **Confirm the field texture** with Aaron (and whether to re-gen softer).
2. In Blender: build the **force-field arch plane** as a SEPARATE object (arch profile, flat, in the opening), emissive blue + translucent, with the chosen `ff_tex`. Export separately.
3. **Setup script** `Tile_Forcefield_Door_T1_Smuggler_Setup.cs` — mirror `Tile_Window_T1_Smuggler_Setup.cs` for hull/molding (use the straight wall's mats per above) + frame; bake the door prefab `[hull, molding, frame]`; then like the ramp/floor `_Lit` (`AddGuideLights`/`AddTubeLights`) **add a child "ForceField" GameObject** (the field plane + emissive material + a blue point-light), default active, with the BRIDGE/TODO. Schema: copy dev wall dims, `DeriveSockets(Wall,Wall,8,8)` (WallBottom@-4/WallTop@+4), role=Wall, theme=smuggler, FLOORS… no — it's a **Wall** (WALLS tab).
4. Bake + verify (mirror `Temp/_RunFloor.cs`) + present.

## 3. Smuggler set status
Done: foundations (square/triangle/rounded), walls (straight/window/**curved**), railings (flat/inc45/inc22/**curved**), ramps (45/half22 +Lit), **floor (+Lit)**. In progress: **force-field door**. Remaining: pillars/columns, roofs, regular door, stairs, half-walls.

## 4. Env / gotchas
- Blender MCP connected; scene UNSAVED (has FF_Door_WIP, CMP_Wall comparison wall, conduit clip, baked floor/rail objects). ComfyUI `127.0.0.1:8188`. Unity not in play mode.
- **FBX X-mirror:** net-new authored asymmetric meshes bake Blender→Unity as `(-Bx,Bz,-By)` — author Blender **+X−Y** → Unity **−X+Z**; verify bounds-center quadrant. (Door is symmetric, N/A.)
- **Generate our own textures, don't atlas-map** the SF_Vol17 ship pack (drags engine/portholes onto parts). See `feedback_generate_theme_textures` memory.
- `theme-base-part` skill drives all this; it self-heals.

**Tell the next session: read `Design_Documents/meta/HANDOFF_forcefield_door.md` and continue §2.**
