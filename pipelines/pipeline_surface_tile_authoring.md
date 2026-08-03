# Surface Tile — Authoring Logic, Math & Parts Roadmap

> **Status:** Reflects the system as actually built (2026-05-31). This supersedes the geometry / snap
> sections of the older [`pipeline_surface_tile.md`](pipeline_surface_tile.md), which describes the
> pre-unification design (corner-snap, right-isosceles triangle, cell-grid-only foundations). Where the
> two disagree, **this doc is canon**.

The goal of this system: **adding a new building part is DATA, not code.** You set a part's shape,
role, and dimensions; one shared function derives its sockets; one shared engine snaps it. We are
heading toward 100+ parts (see the roadmap at the end), so every part flows through the same pipeline.

---

## 1. The one rule

> **A part connects when one of its sockets lines up with a compatible OPEN socket on a placed part.**

Everything else — walls stacking, floors capping foundations, triangles fanning into rings, columns
center-mounting — is just *which sockets a part carries* and *which socket-kinds may mate*. There is
no per-shape placement code in the happy path. Get the **data** right (mesh + sockets) and the part
works.

---

## 2. The 8 m module (exact math)

Everything is one cube edge. Constants live in `SurfaceBaseAnchor.cs`:

| Constant | Value | Meaning |
|---|---|---|
| `CellSize` | **8 m** | foundation cube edge, floor/ceiling square edge, triangle side, grid stride |
| `LayerHeight` | **8 m** | vertical layer stride (one cube up) |
| `WallHeight` | **8 m** | wall height = full module (a wall == a story) |
| `TriangleHeight` | **≈ 6.928 m** | equilateral height, `s·√3/2` |
| `TriangleCentroidOffset` | **≈ 2.309 m** | centroid→edge (inradius), `height/3` |
| `SlabThickness` | **0.4 m** | floor / ceiling / roof plate thickness (`TileSocketLibrary.SlabThickness`) |

**Exactness rule (Aaron):** every part is exactly 8 m on the module so levels never drift. A floor
does **not** stack 0.4 m *on top* of a wall — its mating socket is on its **top rim**, so the slab
clips flush into the wall top and one story stays exactly 8 m. Minor clipping is accepted; cumulative
drift is not.

### Pivot convention — critical
**Every fill part's pivot is its geometric centroid.** Square pivot = centre. Equilateral-triangle
pivot = centroid. This is what makes the overlap test a trivial centroid-distance check (§6) and keeps
snap math origin-clean. When you author a new mesh, **centre it on its centroid.**

### Equilateral triangle geometry (side s = 8)
- height `s·√3/2 ≈ 6.928`
- inradius (centre→edge midpoint) `s/(2√3) ≈ 2.309`
- circumradius (centre→vertex) `s/√3 ≈ 4.619`
- 3 identical edges, 120° apart, **so one 8 m wall fits every edge** and the triangle fans at 60°
  into rings / hexagons. (A right triangle cannot have 3 equal sides — that's why we use equilateral,
  same choice Dune Awakening made.)

---

## 3. Roles & shapes

`TileRole` drives placement behaviour; `TileShape` drives the mesh + socket footprint.

| Role | Behaviour |
|---|---|
| `Foundation` | Roots a base on terrain; the structural ground piece. Square is grid-bound + socket-snap; triangle is socket-snap only. |
| `Wall` | Vertical panel. Rises off a foundation/floor top; stacks on another wall. (Windows, doors, railings, half-walls are all `Wall`.) **Wide walls (2026-06-03):** a wall with `cellWidth` > 8 (e.g. the Hanger 16 m × 32 m hangar wall) gets one `WallBottom`/`WallTop` pair **per 8 m segment** from `DeriveSockets`, so it snaps across multiple foundation cells; `cellWidth = 8` collapses to the single centre pair, unchanged. Height (`verticalRise`) can also be any multiple of 8 — sockets stay at ±rise/2. |
| `Ceiling` | Horizontal plate = **floor OR roof**. Caps foundations, sits on wall tops, cantilevers off other plates. `roofTopsOnly` makes it a roof (caps only, nothing rises off it). |
| `Pillar` | Vertical post. Center-mounts on a foundation/floor; stacks into towers; receives a ceiling on top. |
| `Ramp` | Sloped traversal. Mates a foundation top (head) or bottom (foot) only. |
| `Decorative` | **Free-place props** — crates, barrels, pipes, fuseboxes (built for the Hanger theme, 2026-06-03). Bypasses the socket engine but **obeys the build-level rule**: `SurfaceTilePlacer.ResolveGridSnapPlace` locks the pivot to the **current build level's surface** (the dashed grid plane; Shift+W/S moves it), quantizes X/Z to a fine **2 m** grid, Shift+Q/E yaws. Off-grid, **never collapses** (excluded from the stability graph). **No sockets**, pivot-at-base. Build menu's **PROPS** tab (`TileRole.Decorative` in `BaseBuildPanel.SurfaceRoleOrder`). |
| `Corridor` | **Pre-built tunnel segments** — straights, corners, tees, 4-ways, doors, inclines (Hanger theme, scaled to the 8 m grid; 2026-06-03). Bypasses the socket engine but **obeys the build-level rule**: `SurfaceTilePlacer.ResolveGridSnapPlace` locks the pivot to the **current build level's surface**, quantizes X/Z to the **4 m** sub-grid (so any footprint parity — 1×1, 2×2, 3×2, 3×3 — tiles on the 8 m cells, aligned with foundations) + 90° turns. Off-grid (claims no cells), **never collapses**. **No sockets**, pivot-at-base. Build menu's **CORRIDORS** tab. |
| `Catwalk` | **Half-width walkways / scaffolding** — 4 m wide × 8 m long grating planks, railed/corner variants (Hanger theme, 2026-06-03). Same `ResolveGridSnapPlace` level-lock as Corridor but on a **finer 2 m** sub-grid, so a 4 m plank lands **centred (2-4-2)** or **hugging either side (4-0)** of an 8 m cell. Off-grid, **never collapses**, **no sockets**, pivot-at-base. Build menu's **CATWALKS** tab. |

---

## 4. Socket kinds & the mate table

A socket has `kind`, `localPosition`, `localEulerAngles` (outward normal), `edgeIndex`. The snap
engine aligns a ghost socket's outward normal **anti-parallel** to the host socket's (they face each
other) and makes the positions coincide.

`TileSocketKind` (in `BaseTileSchema.cs`):

| Kind | Lives on | Sits at |
|---|---|---|
| `FoundationEdge` | foundation side | edge mid-height (y = 0) |
| `FoundationTop` | foundation/floor top edge | top rim, outward |
| `FoundationBottom` | foundation base edge | base rim, outward |
| `WallBottom` / `WallTop` | wall bottom / top | ∓ rise/2 |
| `CeilingEdge` | floor/roof rim | top rim |
| `RampBottom` / `RampTop` | ramp foot / head | low/high edge |
| `PillarBottom` / `PillarTop` | post ends | ∓ rise/2 |
| `CenterMount` | foundation/floor **centre** | column-only mount |
| `Universal` | anything | decoratives |

**Mate table** — `CanMate(a,b)` in `SurfaceTilePlacer.cs` (mirror copy in `Tile_SocketMatrix_Diag.cs`):

| A | B | Enables |
|---|---|---|
| FoundationEdge | FoundationEdge | foundations/triangles chain edge-to-edge (rings) |
| FoundationTop | WallBottom | wall rises off a foundation **or a floor** (multi-story) |
| WallTop | WallBottom | walls stack |
| WallTop | CeilingEdge | floor/roof sits on a wall top |
| CeilingEdge | FoundationTop | floor/roof **caps a foundation** directly |
| CeilingEdge | CeilingEdge | floors/roofs cantilever & chain (round roofs) |
| PillarTop | CeilingEdge | floor sits on a pillar |
| PillarTop | PillarBottom | pillars stack into towers |
| PillarBottom | CenterMount | **column** mounts dead-centre (column-only "class") |
| RampTop | FoundationTop | ramp head meets a higher foundation/floor |
| RampBottom | FoundationBottom | ramp foot meets a foundation base |
| Universal | anything | decoratives |

> **Adding a connection type = one line here.** It is the single source of truth for "what snaps to
> what." The socket-matrix diagnostic (`Apex Outlaw → Diag → Surface Tile Socket Matrix`) prints the
> full ghost×host grid so you can verify a new part's connectivity **without play-testing**.

### The "class" trick (how to make a part snap only to specific things)
Give it a **dedicated socket kind** and add exactly the mate rows you want. Example: the **column** has
`PillarBottom`, which mates **only** `CenterMount`. Foundations expose `CenterMount` only at their
centre, so columns center-snap and nothing else can grab the centre. Use this pattern for any part
that needs its own snapping rules.

---

## 5. Per-shape socket recipes (`TileSocketLibrary.DeriveSockets`)

This is the **one function** that turns a part's `(shape, role, cell, rise, roofTopsOnly)` into its
socket list. Setup scripts call it; never hand-author sockets.

| Shape / Role | Sockets generated |
|---|---|
| Square Foundation | 4× FoundationEdge (sides), 4× FoundationTop (top, outward), 4× FoundationBottom (base, outward), 1× CenterMount (top centre) |
| Triangle Foundation | 3× each of FoundationEdge / FoundationTop / FoundationBottom, at inradius 2.309, 120° apart |
| Wall | WallBottom (faces 180°), WallTop |
| Square Ceiling/Floor | 4× CeilingEdge (top rim); +4× FoundationTop +1× CenterMount unless `roofTopsOnly` |
| Triangle Ceiling/Floor | 3× CeilingEdge (top rim); +3× FoundationTop unless `roofTopsOnly` |
| Pillar | PillarBottom (faces 180°), PillarTop |
| Ramp | RampTop (head, high edge), RampBottom (foot, low edge) — **top/bottom only**, no mid-mount |

Geometry helpers in the same file: `SquareEdgeMids`/`SquareOutwards` (4 edges) and `TriangleEdges`
(3 edges at inradius, 120° apart, edge 0 base faces +Z). Reuse these for any new square/triangle part.

---

## 6. The placement engine (`SurfaceTilePlacer.cs`)

### Dispatch (`ResolvePose`)
1. **First piece** (no anchor): any `Foundation` (square **or** triangle) roots on terrain →
   `ResolveFoundationOnTerrain` (establishes the anchor + grid).
2. **Square foundation on a cube TOP face** → `ResolveSquareStack` (clean vertical grid stacking).
3. **Everything else** → `TryResolveSocketSnap` (the one engine).
4. **Square foundation with no socket host under cursor** → `ResolveSquareFoundationForced` (flat
   open-field grid placement).

### The snap engine (`TryResolveSocketSnap`)
- Enumerates **every** placement: each host socket in range × each compatible ghost socket × **both
  facings** (flush + flipped 180°).
- Dedups coincident poses; flags `taken` ones via the overlap guard (red ghost, click blocked).
- Sorts by a **stable `sortKey`** (`host × 1000 + hostSocket × 100 + ghostSocket × 10 + flip`) so the
  cycle order never jitters frame-to-frame.
- Default pose = nearest **open** candidate to the cursor; **Shift+Q/E** (`yawStep`) steps through the
  whole list (every edge, both facings) and **carries over** between placements.
- Tunables: `cornerSnapRadius = 14 m` (how far it gathers sockets — big enough to reach a full
  cube + the walls on it), `SocketCoincidenceTol = 0.4 m`.

### Overlap guard (`IsObstructed`)
- **Fills** (Foundation/Ceiling): blocked if another fill's centroid is within `FillClearance = 3 m`
  in full 3D. Pivot-at-centroid makes this exact; 3D distance auto-separates stacked levels (y=0 vs
  y=8). Blocks duplicates (~0 m) yet allows two triangles sharing an edge (~4.62 m apart).
- **Non-fills** (wall/pillar/ramp): exact-pose + same-role duplicate check.

### Storage & render (no per-part code)
Snapped parts commit **off-grid**: `offGrid = true` + `localPosition` + `localEulerAngles` +
`parentInstanceId`. `SurfaceBaseRenderer` **replays the stored local pose verbatim**, so the built
tile always matches the ghost. Cell-bound squares store `(cellX, cellZ, layer)`.

### Ghost facing marker
Every ghost gets a yellow patch on its +Z (outward) face so you can read which way it faces and see
the flip when Shift+Q/E cycles facings. Stripped from the placed tile.

---

## 7. How to add a new part (the data path)

For a **straight-edged** part (box / triangle / ramp footprint) it is purely a table row — no new C#:

1. Open `Assets/Editor/Tile_DataDriven_Setup.cs` and add a `PartDef` row:
   `{ id, name, desc, shape, role, cell, rise, mesh (Box|TrianglePrism|Ramp), roofTopsOnly, menu,
   buildTime, color }`.
2. The shared `Bake` routine builds the mesh (thin-Z panel for `Wall` roles, full footprint
   otherwise), creates the schema, and calls `DeriveSockets` — done.
3. Run **Apex Outlaw → Setup → Surface Tiles (Data-Driven NEW parts)**.
4. Run the **Socket Matrix** diagnostic; confirm the new row shows ✓ against the hosts it should mate.
5. Play-test.

Worked examples already in the table: Half Wall (`rise=4`), Center Column (`cell=2`), Window, Railing
(`rise=2`).

A part needs **new C#** only when it requires one of the **subsystems** below.

---

## 8. Subsystems still needed (gates for the full list)

The snap/socket layer covers every straight-edged part. Three things don't exist yet and gate whole
families:

1. **Curved-mesh generator** — a wedge/arc mesh baker (90° quadrant, 8 m-radius arc). Unlocks all
   *rounded* parts (foundation, floor, wall, roof, silos, domes). Sockets are fine; only geometry is
   missing.
2. **Multi-cell occlusion layer** — lets a part claim more than one cell and disable interior snaps in
   the cells it covers. Unlocks oversized parts: Large Gate (16×16 = 2×2), Wide Door/Stairs/Ramp
   (claim an extra cell), Tall Door (occludes the cell above), Angled Roof (lip into the cell above).
   This is the "Volumetric Occlusion Layer" from the part spec.
3. **Sloped-mesh + submesh conventions** — sloped mesh bakers (angled roof, stepped stairs, vertical
   right-triangle walls) and an animated-submesh convention (doors, hatches, gates, ladders). Medium
   effort each, no new architecture — they're mesh bakers + a child-object naming convention.

Minor: a **wall-face mount socket** for ladders (one socket kind + one mate row).

---

## 9. Parts roadmap — the full list

**Legend — be honest about verification state:**
- **✅ play-verified** — built AND confirmed working in a play trial by Aaron.
- **🔵 baked, UNVERIFIED** — asset exists + passes the socket matrix, but **not yet play-tested**.
  Treat as "should work on paper"; prove it in-game before trusting it.
- **🟢 data-only** — not built; add a table row now (existing mesh baker covers it).
- **🟡 mesh** — needs a new mesh baker / submesh; sockets already covered by `DeriveSockets`.
- **🔴 subsystem** — needs §8.1 curved-mesh or §8.2 occlusion before it can exist.

> Reality check (2026-05-31): only the **square foundation, wall, and square floor** are 🔵→✅
> play-verified across this session. The equilateral triangle, ramp rebuild, column, half-wall,
> window, and railing are **🔵 baked-but-unverified** — they passed the matrix and rebaked clean, but
> the last play trial predates several of their fixes. Next play session promotes the ones that work
> to ✅.

### I. Foundations & Columns
| Part | Status | Notes |
|---|---|---|
| Foundation (8³ cube) | ✅ | `tile_foundation_square_t1` — play-verified |
| Triangle Foundation | 🔵 | equilateral, 8 m sides — `tile_foundation_triangle_t1`; baked, not yet play-tested |
| Rounded Foundation (90° quadrant) | 🔴 | curved mesh |
| Center Column (2×2×8) | 🔵 | `tile_column_center_t1`, CenterMount; baked, not play-tested |
| Corner Column (L, 2×2×8) | 🟡🔨 | FBX BUILT in Blender → `Tiles/CornerColumn_T1/`; still needs schema row + Pillar sockets wired |
| Pillar Bottom / Middle / Top (8 m, stack) | 🟢 | Pillar role; stacking already works |

### II. Floors & Roofs
| Part | Status | Notes |
|---|---|---|
| Floor (8×8) | ✅ | `tile_ceiling_square_t1` — play-verified |
| Triangle Floor | 🔵 | `tile_ceiling_triangle_t1` — equilateral; baked, not play-tested |
| Rounded Floor (90° quadrant) | 🔴 | curved mesh |
| Rounded Inward Floor | 🔴 | curved mesh |
| Hatch (8×8 + door cutout) | 🟡 | floor mesh + animated submesh |
| Rooftop / Rooftop 2 (flat caps) | 🟢 | Ceiling role, `roofTopsOnly = true` |
| Triangle Rooftop | 🟢 | triangle Ceiling, `roofTopsOnly = true` |
| Rounded / Rounded Inward Rooftop | 🔴 | curved mesh |

### III. Walls, Windows & Doors
| Part | Status | Notes |
|---|---|---|
| Wall 1–4 (8×8) | ✅ | `tile_wall_straight_t1` play-verified; variants = cosmetic rows 🟢 |
| Half Wall (8×4) | 🔵 | `tile_wall_half_t1`; baked, not play-tested |
| Window 1–4 (8×8) | 🔵 | `tile_window_t1` (box stand-in mesh); baked, not play-tested; variants 🟢 |
| Rounded Wall 1,2 / Half Rounded | 🔴 | curved mesh |
| Rounded Window | 🔴 | curved mesh |
| Door / Prudence Door | 🟡 | wall mesh + animated door submesh |
| Wide Door (12 m, +1 cell) | 🔴 | occlusion |
| Tall Door (12 m, occludes cell above) | 🔴 | occlusion |
| Passageway (open arch) | 🟡 | mesh; wall sockets |
| Wide Passageway | 🔴 | occlusion |

### IV. Sloped & Angled Structures
| Part | Status | Notes |
|---|---|---|
| Angled Roof (8×8, 45°, lip into cell above) | 🔴 | sloped mesh + occlusion |
| Angled Roof Corner / Inwards Corner | 🔴 | sloped mesh + occlusion |
| Rounded Roof | 🔴 | curved + sloped |
| Triangle Roof (Bottom/Top) | 🟡 | sloped triangle mesh |
| Roof Cover (triangular trim) | 🟡 | mesh |
| Triangle Wall (right-triangle vertical) | 🟡 | vertical right-triangle mesh; wall sockets |
| Half Triangle Wall (8×4) | 🟡 | mesh |

### V. Vertical Navigation
| Part | Status | Notes |
|---|---|---|
| Ramp (8 m rise, 45°) | 🔵 | `tile_ramp_t1`, flat 45° plank, top/bottom mate only; baked, not play-tested |
| Half Ramp (4 m rise) | 🟢 | Ramp role, `rise = 4` (mesh auto-derives angle) |
| Stairs / Half Stairs | 🟡 | stepped mesh; Ramp sockets |
| Stairs Corner / Inwards Corner | 🟡 | mesh |
| Wide Stairs (16 m, 2 cells) | 🔴 | occlusion |
| Wide Ramp | 🔴 | occlusion |
| Ramp / Stairs Corner (continuous turn) | 🟡 | mesh |
| Wide Ramp Edge / Wall Incline / Floor Triangle / Wall Triangle | 🟡 | trim meshes |
| Ladder (mounts on wall face) | 🟡 | mesh + a wall-face mount socket (one kind + one mate row) |

### VI. Safety & Perimeter Fencing
| Part | Status | Notes |
|---|---|---|
| Railing (8×2) | 🔵 | `tile_railing_t1`; baked, not play-tested |
| Railing Gate | 🟢 | railing row + gate submesh |
| Rounded Railing | 🔴 | curved mesh |
| Incline Railing / Half Incline | 🟡 | sloped mesh; mounts on stair edge |

### VII. Base Infrastructure & Specials
| Part | Status | Notes |
|---|---|---|
| Large Gate (16×16, claims 2×2, clears interior snaps) | 🔴 | occlusion — the flagship occlusion case |

### Roadmap summary
- **Play-verified (✅):** square foundation, wall, square floor. **Everything else is at best 🔵 —
  baked but not proven in a trial.** Promote 🔵→✅ only after an in-game test.
- **Buildable as data today (🟢):** pillar sections, flat rooftops, triangle rooftop, wall/window
  cosmetic variants, half ramp, railing gate. These are the cheapest wins — table rows only.
- **Need a mesh baker (🟡):** corner column, hatch, doors/passageways, triangle roofs & walls, stairs,
  ramp corners, trims, ladder. Each is one mesh function; sockets already handled by `DeriveSockets`
  (a couple need one new socket kind).
- **Need a subsystem (🔴):** everything **rounded** (→ §8.1 curved-mesh generator) and everything
  **oversized/occluding** (→ §8.2 multi-cell occlusion layer).

---

## 9b. Blender build log (this session — FBX meshes only, not yet schema-wired)

Meshes authored in Blender and exported to `Assets/Prefabs/Bases/Tiles/<Name>/<Name>.fbx`. Each still
needs a schema/`DeriveSockets` row to be placeable (🔨 = mesh done, wiring pending). **🔨 marks where
this session's work reached** — resume after the last 🔨 entry.

- 🔨 Corner Column → `Tiles/CornerColumn_T1/` (tight L, 2 m arms × 4 m, 8 m tall; bbox 6×6×8)
- 🔨 Pillar Section → `Tiles/Pillar_Section_T1/` (2×2×8 post; one mesh serves Bottom/Middle/Top)
- 🔨 Stairs → `Tiles/Stairs_T1/` (8 m run × 8 m rise × 8 m wide, 8 stepped boxes)
- 🔨 Half Ramp → `Tiles/HalfRamp_T1/` (thin 45° plank, 8 m run × 4 m rise)
- (workflow change: build VISIBLE, export, then clear before the next part — Aaron watches in Blender)
- 🔨 Hatch → `Tiles/Hatch_T1/` (8×8×0.4 floor slab, 3×3 square hole via boolean)
- 🔨 Angled Roof → `Tiles/AngledRoof_T1/` (8×8 plank sloped 45°, run 8 / rise 8)
- 🔨 Triangle Roof → `Tiles/TriangleRoof_T1/` (equilateral 8 m, PITCHED 45° — slope from `z = y`, base edge high / apex low; bbox 8×6.93×7.33)
  - NOTE: roof slope MUST come from vertex Z (z rises with depth) = 45°, NOT a flat slab laid down. First attempt was flat (wrong) — fixed.
- 🔨 Triangle Wall → `Tiles/TriangleWall_T1/` (vertical right-triangle 8×8 panel, 0.4 thick)
- 🔨 Passageway → `Tiles/Passageway_T1/` (8×8 wall, 4×6 open archway via boolean)
- 🔨 Door → `Tiles/Door_T1/` (8×8 wall, 3×6 doorway + door panel)
- 🔨 Ladder → `Tiles/Ladder_T1/` (1.15×8 rails+rungs, wall-face mount)
- 🔨 Railing Gate → `Tiles/RailingGate_T1/` (8×2 railing with center gate panel)
- 🔨 Rounded Foundation → `Tiles/RoundedFoundation_T1/` (90° quadrant, 8 m legs, 8 m tall — 🔴 needs curved subsystem to place)
- 🔨 Rounded Floor → `Tiles/RoundedFloor_T1/` (90° quadrant, 0.4 slab — 🔴)
- 🔨 Rounded Wall → `Tiles/RoundedWall_T1/` (8 m radius, 90° arc, 8 m tall — 🔴)
- 🔨 Large Gate → `Tiles/LargeGate_T1/` (16×16 frame, 12×12 opening — 🔴 needs occlusion, claims 2×2)
- 🔨 Wide Door → `Tiles/WideDoor_T1/` (12×8 wall, 8×6 opening — 🔴 occlusion, +1 cell)
- 🔨 Tall Door → `Tiles/TallDoor_T1/` (8×12 wall, 5×10 opening — 🔴 occlusion, cell above)
- 🔨 Wide Stairs → `Tiles/WideStairs_T1/` (16 wide × 8 run × 8 rise — 🔴 occlusion, 2 cells)
- 🔨 Wide Ramp → `Tiles/WideRamp_T1/` (16 wide × 8 run × 8 rise plank — 🔴 occlusion)
- 🔨 Angled Roof Corner → `Tiles/AngledRoofCorner_T1/` (hip wedge, exterior 90° join)
- 🔨 Half Triangle Wall → `Tiles/HalfTriangleWall_T1/` (right triangle 8×4)
- 🔨 Rounded Inward Floor → `Tiles/RoundedInwardFloor_T1/` (8×8 slab, 8 m quarter-circle cutout — 🔴)
- 🔨 Rooftop → `Tiles/Rooftop_T1/` (flat 8×8×0.4 armored cap; use roofTopsOnly when wired)

### Session total: 23 FBX meshes built in Blender → `Assets/Prefabs/Bases/Tiles/`
AngledRoof, AngledRoofCorner, CornerColumn, Door, HalfRamp, HalfTriangleWall, Hatch, Ladder,
LargeGate, Passageway, Pillar_Section, RailingGate, RoundedFloor, RoundedFoundation,
RoundedInwardFloor, RoundedWall, Stairs, TallDoor, TriangleRoof, TriangleWall, WideDoor, WideRamp,
WideStairs, Rooftop.

**ALL are mesh-only (🔨). NONE are schema-wired or play-tested yet.** Next steps to make them usable:
1. Configure FBX importers (scale 1, no auto-cam/light) per the project's Blender→Unity import rule.
2. Add each as a `PartDef` row in `Tile_DataDriven_Setup.cs` (or per-part setup) → schema +
   `DeriveSockets` + prefab. Straight-edged ones place immediately; 🔴 rounded/oversized ones need
   the curved-mesh / occlusion subsystems before they snap correctly.
3. Run the Socket Matrix diag, then play-test.

## 10. Files map
| File | Owns |
|---|---|
| `Assets/Scripts/Schemas/BaseTileSchema.cs` | schema fields + `TileShape` / `TileRole` / `TileSocketKind` enums + `TileSocket` |
| `Assets/Scripts/Macro/SurfaceBase/TileSocketLibrary.cs` | `DeriveSockets` (the one socket generator) + shape edge helpers |
| `Assets/Scripts/Macro/SurfaceBase/SurfaceTilePlacer.cs` | `ResolvePose` dispatch, `TryResolveSocketSnap` engine, `CanMate` mate table, `IsObstructed` overlap |
| `Assets/Scripts/Macro/SurfaceBase/SurfaceBaseRenderer.cs` | replays stored poses → scene tiles |
| `Assets/Scripts/Macro/SurfaceBase/SurfaceBaseAnchor.cs` | module constants, grid, yaw |
| `Assets/Editor/BaseTileSetupHelpers.cs` | mesh bakers (`BakeBoxPrefab`, `BakeTrianglePrismPrefab`, `BakeRampPrefab`) |
| `Assets/Editor/Tile_DataDriven_Setup.cs` | **the part table** — add a row to add a straight-edged part |
| `Assets/Editor/Tile_Starter_T1_Setup.cs` | the original 6 starter tiles |
| `Assets/Editor/Tile_SocketMatrix_Diag.cs` | QA: prints the ghost×host mate matrix (no play mode) |

## See also
- [`pipeline_surface_tile.md`](pipeline_surface_tile.md) — original pipeline doc (pre-unification;
  geometry/snap sections are superseded by this file)
- [`pipelines_overview.md`](pipelines_overview.md) — the six-stage content pipeline pattern
