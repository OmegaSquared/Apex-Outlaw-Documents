# Progression — Wire / Conduit Power Routing

> **Status: implementation IN PROGRESS (Phase 6.12).** Conduit placement + floor-peel + the Run Wire tool +
> spline + bundling + the **two-look** (one 5-slot clamp; **clamp→clamp = a round steel PIPE tube**, **loose
> runs = the black SAGGING WIRE**; clamp highlight + delete-anywhere) are all **committed** (`2d5b968` onward).
> The two-look batch also landed **floor-peel for wires/pipes** (they now hide with the level like tiles) and
> **fully axis-aligned (orthogonal) clamp→clamp bends** (no diagonal legs). **6.12.D + the clamp re-theme (#3, steel
> U-saddle clamps) are committed. Next: #13 wall-clip standoff (#4).** See [Implementation status / handoff](#implementation-status--handoff-2026-06-02)
> just below for the exact done/next state + gotchas. Tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md) **Phase 6.12**.

## Implementation status / handoff (2026-06-02)

**Built & committed (`2d5b968` on `master`):**
- **Floor-peel view culling** — [`SurfaceBaseLevelView.cs`](../../Assets/Scripts/Macro/SurfaceBase/SurfaceBaseLevelView.cs)
  hides every tile with `layer > anchor.GridLayer`; hooked into `SurfaceBaseAnchor.SetGridLayer` +
  `SurfaceBaseRenderer.SpawnTile`. Shift+W/S drives it. (Verified: terrace-down stays visible.)
- **Corner-snap layer fix** — the unified corner-snap path in `SurfaceTilePlacer` now stamps
  `pose.layer = currentBuildLayer` (was persisting `layer 0`, which broke the peel + host-level gating
  off level 0).
- **`TileRole.ConduitHolder`** + `slotCapacity` + `wireRailAxis` on `BaseTileSchema`.
- **3 placeholder conduit brackets** (1 / 3 / 5-wire) — [`WireConduit_T1_Setup.cs`](../../Assets/Editor/WireConduit_T1_Setup.cs)
  bakes flat-tray prefabs + relabels the core theme → **"Core"**. Assets under
  `Assets/GameData/Bases/SurfaceTiles/T1/Tile_conduit_*.asset` + `Assets/Prefabs/Bases/Conduits/`.
- **Core → Power menu** — `BaseBuildPanel`: on the surface the core theme shows only a **POWER** tab;
  `CountCardsForTab` / `PopulateCards` cross-list `ConduitHolder` tiles into the Power category,
  **controller-independent** (the surface has no orbital `BaseBuildController`).
- **Flush placement** — `SurfaceTilePlacer.ResolveConduitFlush`: conduit lies flush against the surface
  under the cursor (floor/wall/ceiling), oriented to the hit normal, **Shift+Q/E** yaw. Bypasses the
  socket snap engine (ConduitHolder → empty sockets in `TileSocketLibrary.DeriveSockets`).
- **Stability exclusion** — `SurfaceStabilityGraph`: `ConduitHolder` + `Decorative` are marked fully
  stable and skipped in the collapse pass (they're non-structural). *This fixed the "conduit spawns
  then instantly vanishes" bug — it was collapsing as unsupported.*

**Built & committed since (on `master`):**
- **`3868bb1` — Run Wire tool (6.12.B):** `WirePlacer.cs` (routing / extend / drag-to-plug / Shift+RMB aim-delete),
  `SurfaceCursorRay.cs` (shared precision-safe cursor ray), the Power-tab **Run Wire** card (`WireToolCard.cs` +
  `BaseBuildPanel.BuildWireToolCard`), a straight black `LineRenderer` render in `SurfaceBaseRenderer`, and the wire
  data model (`WireNode`/`WireRecord`/`SurfaceBaseRecord.wires` + `SurfaceBaseStore.AddWire/RemoveWire/UpdateWire` +
  `OnWireAdded/Removed/Changed`).
- **`143dbe0` — spline (6.12.C):** Catmull-Rom + catenary sag + bundling + the "empty-space clicks shape the curve"
  placement model; added `railWidth` to `BaseTileSchema` (re-baked brackets).
- **`7dd786e` — Group 1 polish:** wire width `0.1`; the wire-spline tuning fields are now **`[NonSerialized]`** (code is the
  single source of truth — a stale scene-serialized `wireWidth=0.4` had been overriding every change → the "wire won't shrink"
  saga); clip rail `0.15`; Shift+RMB delete selects a wire **anywhere along its rendered length** (samples the cached spline).

**Built & committed this session (the two-look batch — Aaron signed off on the look 2026-06-02):**
- **Spline shape (Group 2)** in `SurfaceBaseRenderer`: wire **seats IN the clamp centre** (not on its face); **centripetal
  Catmull-Rom** for loose runs (no overshoot/kinks); **clamp→clamp = right-angle run** (`EmitRightAngleRun`: straight out the
  dominant base axis → rounded 90° corner → straight in; radius `wireCornerRadius`); loose runs stay smooth + sagging.
- **Placement model revised** (`WirePlacer.RoutingClick`): **every left-click appends a node and the run keeps going** — click
  clamps in a row (clamp→clamp = tight) and/or ground (loose = saggy); **only RMB/Esc ends** (clicking a clamp no longer stops it).
- **#11 parallel bundle:** a wire's slot offset is applied to BOTH endpoints, so multiple wires through the same clamps are
  parallel translates (stay evenly spaced through bends). Slots fill lowest-first (one side → across the rail).
- **#12 clamp highlight while wiring** (`WirePlacer.UpdateClampHighlights`): placed clamps tint **blue** (floor/wall) / **yellow**
  (ceiling, by mount-normal facing down) while the tool is armed; cleared on disarm.
- **One-clamp model** (`WireConduit_T1_Setup`): a single **"Conduit Clamp"** — `slotCapacity 5`, rail `1.5`, thin band `0.2`,
  holds 5 pipes flat across with gaps. The 1/3/5 bracket variants are **hidden** (`menuPlacement = Upgrade`, kept on disk).
- **Two-look render** (`SurfaceBaseRenderer`): **clamp→clamp = a procedural round PIPE tube** (`BuildPipeMesh` sweeps a ring along
  the right-angle run, parallel-transport framed, double-sided) skinned with a **one-colour steel** material (the SciFi Warehouse Kit
  `Structure Props Mat` instanced, albedo map cleared → `pipeColor`); **loose runs stay the black sagging WIRE** (the line draws the
  full path; the tube overlays the clamp→clamp parts). Pipe radius `0.1175` (≈ Pipes 06 Ø0.235); tunables `pipeRadius`/`pipeSides`/`pipeColor`.

- **Clamp nudge-snap** (`SurfaceTilePlacer.ResolveConduitFlush` + `NudgeAlignConduit`): placing a clamp pulls it into line
  with the nearest **same-facing** clamp (each anchor-local axis within `conduitAlignSnapMetres`, 0.75 m) so clamp→clamp runs
  come out **straight, not jogged**. Applies to the ghost too — you see it align before you click.
- **Floor-peel for wires + pipes** (`WireRecord.layer`, `SurfaceBaseLevelView.OnApplied`, `SurfaceBaseRenderer`): wires/pipes
  are standalone GameObjects (not grid tiles), so the level-view peel never hid them. `WireRecord` now carries a `layer`
  (stamped at creation = `SurfaceBaseAnchor.GridLayer`); the level view fires `OnApplied`, and the renderer hides each wire's
  line + pipe by `layer <= activeLevel` (also on `SpawnOrUpdateWire`, so loaded/edited wires land right). Clamps already peeled
  — they're tiles.
- **Orthogonal clamp→clamp bends** (`SurfaceBaseRenderer.EmitRightAngleRun`): the old single-corner L left a **diagonal** second
  leg whenever two clamps differed on >1 axis. Now it routes a fully axis-aligned (Manhattan) path — leave along clamp A's axis,
  any middle axis, arrive along clamp B's axis — with a rounded 90° corner at each turn. No diagonal legs.

**Committed in the two-look batch (specific paths, never `-A`; the scene stays untracked):**
`Assets/Scripts/Macro/SurfaceBase/SurfaceBaseRenderer.cs`, `…/WirePlacer.cs`, `…/SurfaceTilePlacer.cs`, `Assets/Editor/WireConduit_T1_Setup.cs`,
`Assets/GameData/Bases/SurfaceTiles/T1/Tile_conduit_{clip,bracket3,bracket5}_t1.asset`,
`Assets/Prefabs/Bases/Conduits/conduit_clip_t1/conduit_clip_t1.prefab`, `…/_SharedMaterials/Conduit_Grey.mat`.

**Remaining — to do next (rough order):**
1. ~~Verify the two-look → commit the batch.~~ **DONE 2026-06-02** — look signed off; floor-peel-wires + orthogonal bends landed; batch committed.
2. ~~Wall pass-through + snapping.~~ **DONE 2026-06-02** — implicit model: `SurfaceTilePlacer.SnapAcrossWall` aligns a clamp to an
   opposite-face clamp on the same wall; `SurfaceBaseRenderer.ClampExitDir` exits along the mount normal for a through-wall run, so a
   wire plugged across crosses straight through. Same commit also fixed **corner routing** — clamp→clamp runs on different surfaces now
   HUG the faces and turn at the inside corner (`EmitRightAngleRun`), so a curve can't cross to the back of a wall ("follow the clamp side").
3. ~~Clamp re-theme.~~ **DONE 2026-06-02** — in-place reskin: the clip is now 5 steel U-saddle clamps on a backing strip
   (Blender FBX baked via `WireConduit_T1_Setup` → `BakeThemedFbxPrefab`); snap contract unchanged. Hidden 3/5 brackets stay boxes.
4. **#13 wall-clip** — pin down where a wire/pipe clips a wall (behind the clamp vs along the run) and add a small surface standoff.
5. **#8 ceiling clamps** — Shift+Q/E placement cycle includes "attach to the **ceiling above**" (hidden by floor-peel) with a **yellow ghost**.
6. **#7 gravity-fall** — an unclamped wire drops to the ground.
7. **6.12.E PowerNetwork** + wire the dormant `Source`/`Consumer` hit-test (needs power-bearing surface tiles first — a **generator**;
   see the generator-design discussion: orbital already has `PowerGenerator`/`Fusion_Reactor_T1` modules + a `G8_Reactor_Core` surface chassis).
8. Optional pipe-look refinements (exact Pipes-06 diameter via mesh inspection; the kit texture instead of a flat colour).

**Gotchas for the next session (important):**
- The working tree has lots of **unrelated** uncommitted work — **leave it alone**; commit only the wiring files listed above
  (specific paths, never `-A`). The surface scene `PlanetTest_Alythar.unity` is **untracked** — don't bake into it.
- **Wire-spline tuning is code-only (`[NonSerialized]` in `SurfaceBaseRenderer`):** `wireWidth`, `wireSagFactor`, `wireMaxSag`,
  `wireCatenaryTightness`, `wireCornerRadius`, `pipeRadius`, `pipeSides`, `pipeColor`. A code-default change **always** applies on the
  next play (no scene override). For instant in-play preview, `set_property` them LIVE (reverts on stop).
- **Recompiles only land in EDIT mode** — Coplay defers `RequestScriptCompilation` while playing, so script edits don't reach a running
  session. Stop play → let it recompile → re-enter. (This was the "wire won't shrink" / "changes don't apply" saga.)
- **Coplay quirk:** `execute_script` (the `_WireCompileNudge` refresh, or `WireConduit_T1_Setup.Execute`) often times out mid-recompile —
  harmless; verify with `check_compile_errors`. Asset bakes (`Execute`) must run in **edit mode**.
- The **conduit clamp** is now ONE part (`Tile_conduit_clip_t1`, displayName "Conduit Clamp", cap 5); the 3/5-wire brackets are hidden.
  `SurfaceBaseRenderer` is **scene-placed** on `SurfaceBaseRoot`; `WirePlacer` is **auto-added** by `SurfaceTilePlacer.Awake`.
- Conduits are **offGrid** (`RegisterLoose`), excluded from stability, record `layer = currentBuildLayer`.
- Routing still uses **ConduitSlot + Loose** only; `Source`/`Consumer` node kinds are typed but **dormant** until 6.12.E.

## Context / why

## Context / why
A surface base needs to route **power** from sources to powered facilities. Players want to (a) place
**conduit-brackets** that hide/route wires along walls/ceilings/floors, (b) **run wires** from a power source
through brackets to the thing being powered, with the wire rendering as a clean **black spline** — straight when
the hold-points line up, **curving/sagging** when a point is off-axis, and a **loose sine-wave droop** when a wire
just lies across the floor — (c) bundle **multiple wires side-by-side** in one bracket (1-, 3-, or 5-slot), and (d)
pass a wire **through a wall** via a plug/grommet. Power **sources matter**: multiple sources give redundancy so the
base keeps running if one is destroyed in an attack. This is the first system that makes a base's power *physical and
attackable* (cut the wire / kill the generator → things go dark).

## Player flow (UX) — freeform "wire the home" model
1. From the build menu's **Power** section (Main Parts), place conduit-brackets (snap to walls/ceilings/floors like
   any tile) wherever wires should be hidden/guided.
2. Pick the **Run Wire** tool (same Power section). **Click to start** the wire — on a source, a conduit slot, or
   **bare ground** (start anywhere).
3. **Each left-click on empty space drops a curve point** — the wire is a Catmull-Rom through them, so clicks SHAPE
   the run as it grows, and it **keeps going**. The run **STOPS** only when the player **(A) plugs into a conduit**
   (a free slot — caps 1 / 3 / 5; a full conduit isn't pluggable, so clicking it just drops a curve point) **or
   (B) right-clicks / Esc** (ends with a loose, unconnected end at the last point). A wire may have **both ends loose**.
   *(A wire connects two endpoints with curve points between — to chain several brackets, run a wire per hop.)*
4. **Plug loose ends later** — grab a loose end and **drag** it onto a free slot / source / consumer to connect it
   (terminate the cable after the run is pulled). Full slots reject the drop. **Extend** a wire by clicking its loose
   end to resume routing.
5. Segment shape: **straight** between aligned hold-points; **curve** when a point is off-axis; **catenary droop** for
   a floor run or a loose end (wire lying/hanging).
6. Bundling: more wires on a bracket **fan out side-by-side** up to its slot cap, re-spaced; a wire past the cap is
   rejected.
7. Cross a wall → drop a **wall pass-through plug** on any existing wall; the wire continues on the far side.
8. **Power**: a consumer goes live only with an **unbroken _plugged_ path to a live source** — a loose end is an open
   circuit (no power past it) until plugged. Several sources = redundancy.
9. **Delete** (Shift+RMB, red hover-preview): aim at a wire's **dangling tail** → trims back to the **last connected
   conduit**; aim at the wire's **source/origin** → deletes the **whole wire**. The preview shows exactly what goes.

> **Seeing buried wires.** Routing along lower floors means upper floors hide the work. The surface builder's
> **level view culling (floor peel)** — Shift+W/S sets the active level and hides all structure above it — is the
> companion that makes wiring lower levels practical. Canon:
> [`progression_base_building.md` § 8](progression_base_building.md). It is a Phase 6.12 prerequisite.

## Architecture — reuse vs net-new (grounded in the repo)
**Reuse (brackets ride the existing surface-tile pipeline):**
- Placement/snap: [`SurfaceTilePlacer.cs`](../../Assets/Scripts/Macro/SurfaceBase/SurfaceTilePlacer.cs)
  (`TryResolveSocketSnap`, `CanMate` mate table), `SurfaceBaseAnchor.cs`, `SurfaceGridManager.cs`,
  `BaseTileInstance.cs`.
- Schema/catalog/UI: [`BaseTileSchema.cs`](../../Assets/Scripts/Schemas/BaseTileSchema.cs) (+ `TileShape` /
  `TileRole` / `TileSocketKind` enums), `SurfaceTileCatalog.cs`, `BaseBuildPanel.cs`, `themeId`.
- **Build-menu home:** the wiring parts surface in the **`Power` category of the Main Parts menu**
  ([`BaseBuildPanel.cs`](../../Assets/Scripts/UI/BaseBuildPanel.cs)), next to the reactors — *not* a standalone tab
  and *not* a themed surface-tile tab. `DraggableCard` already routes a `BaseTileSchema` card to
  `SurfaceTilePlacer.SelectSchema` (snaps), so the brackets/plug are cross-listed into the `Power` tab with no new
  placement system. The **Run Wire** entry is a small mode card in that tab that arms `WirePlacer`.
- Asset bake: [`BaseTileSetupHelpers.cs`](../../Assets/Editor/BaseTileSetupHelpers.cs) `BakeThemedFbxPrefab`;
  per-part `Tile_*_Setup.cs`; socket-from-transform pattern in `Smelter_T1_AddDualConduitSockets.cs`. Theming via
  the `theme-base-part` skill.
- Persistence/render events: `SurfaceBaseRecord.cs` + `SurfaceBaseStore.cs` (`OnTileAdded/Removed`) →
  `SurfaceBaseRenderer.cs`. (BRIDGE: in-memory now → PlayFab later, same as tiles.)

**Net-new (build from scratch):**
- **WirePlacer** — a routing tool/mode (armed by the Run Wire menu card) plus wire editing: click-to-route with
  **loose ends**, **drag-to-plug** a loose end onto a free slot, **extend** from a loose end, and **aim-based delete**
  (trim-to-last-conduit vs whole-wire) layered on the builder's existing Shift+RMB delete + red hover-preview.
- **Spline renderer** — curve sampling + sag; reuse `LineRenderer` patterns: `MacroTargetLineRenderer.cs`
  (dashed/procedural-texture line), `JumpGateNetworkVisualizer.cs` (parallel line bundles + scrolling-flow texture
  — great for the multi-strand bundle and an optional "power flowing" effect), `MacroWaypointRenderer.cs` (polyline),
  `MacroDashedRing.cs` (procedural mesh if we go tube-mesh). **No Bézier/Catmull/catenary exists — author it.**
- **PowerNetwork** — graph of sources/consumers/wire-edges; connectivity + (later) capacity; redundancy; recompute
  on break. `FacilityModuleSchema.cs` already has `powerDraw`/`powerProvided` (int, **UI-only today** — wire the
  runtime eval).

## Data model (new)
- **ConduitBracket** = a `BaseTileSchema` instance with the new **`ConduitHolder` `TileRole`** (excluded from the
  stability graph; snaps via new wall/ceiling/floor `TileSocketKind`s). **Three variants by `slotCapacity`:**
  - **Conduit Clip** — `slotCapacity = 1` (cheap, snaps anywhere, short single runs)
  - **Conduit Bracket (3-wire)** — `slotCapacity = 3`
  - **Conduit Bracket (5-wire)** — `slotCapacity = 5`

  Each carries a wire-rail axis + mount socket(s). Menu home = **`Power` category of Main Parts** (cross-listed), not
  a surface-tile role tab. (`ConduitHolder` is the code-side `TileRole` constant; "bracket/clip" is the display term.)
- **WireNode** = one point along a wire: `kind ∈ {Source, Consumer, ConduitSlot, Loose}`; plus `portRef` / `slotIndex`
  for connected kinds, or `worldPos` (anchor-local) for `Loose`. A `Loose` node is an unplugged terminus.
- **WireRecord** = `{wireId, List<WireNode> nodes, cachedSplineControlPoints[], color/gauge, isBreached}` — an
  **ordered node list**, not a fixed from/to. Drag-to-plug flips a `Loose` node to a connected kind; extend appends
  nodes from a loose end; trim-delete pops trailing nodes back to the last connected conduit; full-delete removes the
  record. Add `List<WireRecord> wires` to `SurfaceBaseRecord`; `SurfaceBaseStore.AddWire/RemoveWire/UpdateWire` +
  `OnWireAdded/Removed/Changed` events for the renderer.
- **WallPassThrough** = a plug add-on that mounts on **any existing wall**, with a coincident hold-point on each face,
  linked so a wire crosses.
- **PowerSource / PowerConsumer** = derived from `powerProvided`/`powerDraw`; `PowerNetwork` resolves the live set.

## Spline behavior (the look)
- Route = ordered hold-points (source → brackets → consumer). Evaluate **per segment** between consecutive points.
- **Straight** if the two points are collinear with the bracket rail within a tolerance; else a **curve** —
  Catmull-Rom through the route points (C1-continuous, no tangent authoring) is the cleanest v1; per-segment cubic
  Bézier if we want manual tangents later.
- **Sag/droop**: for an *unsupported* segment (floor run, or a point far off the bracket line) apply a
  **catenary** `y = a·cosh(x/a)` (bigger `a` = looser) so it reads as wire resting/looping; bracket-to-bracket taut
  runs get little/no sag. This is the "sine-wave loose line on the floor."
- **Bundling**: a bracket carrying *k* wires assigns each a lateral offset along the rail at
  **spacing = railWidth / `slotCapacity`**; the spline passes through the offset point at that bracket so the *k*
  strands run parallel. A wire past `slotCapacity` is rejected. Render as *k* offset `LineRenderer`s (**v1**) or one
  merged tube mesh (v2 polish).
- Sample the final curve into `LineRenderer` positions (N samples/segment). Black wire material.

## Power model (phased)
- **v1 — connectivity** *(locked)*: a consumer is powered iff an unbroken wire path reaches *any* live source (graph
  BFS). Redundancy falls out for free (multiple sources/paths). Breaking a wire or destroying a source recomputes.
- **v2 — capacity**: sources provide W, consumers draw W; sum per connected network; over-subscription drops
  lowest-priority consumers. Hook destruction (`BasePartBreakable` / wire breach) → recompute → consumers deactivate.

## Asset generation
- **Black wire material** — URP/Lit, near-black base, metallic ≈ 0.2, smoothness ≈ 0.15 (matte insulation).
  Optional procedural **dash/flow texture** (copy `MacroTargetLineRenderer`'s dash texture; `JumpGateTunnel.shader`
  for animated "power flowing" if wanted). Author via a `MakeMat` in an Editor setup script. **This + a
  `LineRenderer` IS the "black spline line."** No FBX needed for the wire itself in v1.
- **Conduit-bracket prefabs** — three placeholders first (a thin rail + 1 / 3 / 5 marked slots) so placement works
  day 1; Blender-authored + themed (Smuggler) via `theme-base-part` later. Hold-points = baked child transforms or
  schema sockets (mirror `Smelter_T1_AddDualConduitSockets.cs`).
- **Wall pass-through plug prefab** — grommet/hole that mounts on any wall with a hold-point each side.
- **Editor setup scripts** — `WireConduit_Bracket_Setup.cs` (emits all three brackets), `WallPassThrough_Setup.cs`
  mirroring `Tile_*_Setup.cs` (materials → `BakeThemedFbxPrefab` → schema). Schemas under `Assets/GameData/Bases/...`;
  prefabs under `Assets/Prefabs/Bases/...`. Set `prefabAddress` now (Addressables not wired yet — BRIDGE, same as
  tiles).
- **Tube-mesh (v2 only)** — adapt `MacroDashedRing.cs`'s procedural-mesh pattern to extrude a ring along the spline
  for chunky sagging cables.

## Build order
0. **(Prerequisite) Level view culling (floor peel)** — Shift+W/S active level hides all structure above it so wires
   on lower floors are visible to route/inspect. Canon:
   [`progression_base_building.md` § 8](progression_base_building.md).
1. **Bracket parts** — new `ConduitHolder` `TileRole` + new socket kinds + three placeholder prefabs (1/3/5-slot);
   snap via the existing placer; cross-list into the `Power` menu category. Verify snap.
2. **Wire tool** — `WirePlacer` armed by the Run Wire card: click source → brackets → consumer, build a `WireRecord`,
   persist via the store.
3. **Spline renderer** — `LineRenderer` + Catmull-Rom sampling; straight & curve segments; black material.
4. **Sag/droop** — catenary for unsupported/floor segments.
5. **Bundling** — lateral offsets, up to each bracket's `slotCapacity` parallel strands.
6. **Wall pass-through** plug part.
7. **PowerNetwork v1** — connectivity graph + consumer activation gate + redundancy + recompute-on-break.
8. **Later** — capacity (v2), PlayFab persistence, themed brackets, flow shader.

## Resolved decisions (2026-06-01)
- **Bracket role:** dedicated **`ConduitHolder` `TileRole`** (snap semantics + stability-graph exclusion). Its menu
  home is the **`Power` category of Main Parts** (cross-listed), *not* its own surface-tile tab.
- **Bracket variants:** three by `slotCapacity` — **1-wire Clip, 3-wire Bracket, 5-wire Bracket**.
- **Build-menu placement:** wiring parts (the three brackets + wall-plug + a **Run Wire** mode card) live in the
  **`Power` section of the Main Parts menu**, beside the reactors.
- **Wire input (freeform "wire the home", revised 2026-06-01):** click-to-start anywhere (source / conduit slot /
  ground); **each left-click on empty space drops a curve point and the run keeps going** (Catmull-Rom through the
  points). The run **stops only** when the player **(A) plugs into a conduit/device** or **(B) right-clicks / Esc**
  (loose end). A wire connects two endpoints with curve points between — chaining multiple brackets is a wire per hop
  (not one wire threaded through all). **Drag** a loose end onto a free slot/source/consumer to plug it later; **click
  a loose end to extend**. Segment shape auto-derived (collinear → straight, off-axis → Catmull-Rom curve,
  unsupported/loose → catenary sag).
- **Wire delete:** Shift+RMB with red preview — aim at the dangling tail trims to the **last connected conduit**, aim
  at the source/origin deletes the **whole wire**.
- **Wall crossing:** a **plug add-on** that mounts on any existing wall (not a dedicated holed-wall tile).
- **Power model (v1):** **connectivity-only** (BFS to any live source; redundancy free); capacity → v2.
- **Bundle render (v1):** ***k* offset `LineRenderer`s**; merged tube mesh → v2.
- **Floor peel:** **full peel** — Shift+W/S active level hides all structure strictly above it; tied to
  `currentBuildLayer`. (Companion surface-builder feature; canon in `progression_base_building.md` § 8.)

## Verify (when built)
- Place 2+ brackets on a wall → run a wire: straight when aligned, curves when one is off-axis; floor run sags.
- Stack 5 wires on the 5-bracket → they fan parallel, the 6th is rejected; 3 on the 3-bracket → the 4th is rejected;
  the 1-wire clip refuses a 2nd.
- The three brackets + Run Wire + wall-plug all appear in the build menu's **`Power`** section.
- Power a consumer from source A; destroy A; confirm it dies unless also wired to source B (redundancy).
- Pass a wire through a wall plug and power something on the far side.
- Start a wire on bare ground, click two conduits, end on ground → it persists with **two loose ends**; the consumer
  stays unpowered until both are plugged.
- Drag a loose end onto a free conduit slot → it plugs and re-splines; drag onto a **full** slot → rejected.
- Click a loose end → routing resumes (extend); add another conduit.
- Shift+RMB the dangling tail → trims to the last connected conduit; Shift+RMB the source → whole wire removed; the
  red preview matches in both cases.
- Shift+W/S to a lower level hides the floors above so a buried wire is visible; raising the level restores them.
- Reload the base (store round-trip) → brackets + wires + power links restore.
