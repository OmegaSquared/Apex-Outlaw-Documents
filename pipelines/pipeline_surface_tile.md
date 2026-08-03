# Surface Tile Pipeline

Canonical authoring pipeline for **surface base tiles** — the modular 8 m grid pieces (square foundation, triangle foundation, wall, ceiling, ramp, pillar) the player snaps together to construct a surface base inside the Scene 3 surface world. **Parallel** to the existing free-place / socket / conduit base system documented in [`pipeline_base.md`](pipeline_base.md), which continues to govern orbital bases and the legacy free-place flow.

**Scope:** every grid-snapped piece the player builds inside `Assets/Scenes/Surface.unity` (and its test scene `PlanetTest_Alythar.unity`). Excludes orbital chassis / connectors / modules / armor (those stay on the free-place pipeline), and excludes ships, weapons, recipes.

**Why a separate pipeline:** the surface-tile model has its own geometry (fixed 4 m cell quantization + equilateral-triangle math), its own snap algorithm (cell-centered + socket kind-matching, no conduit saddle), and its own structural-integrity graph (no peer in the free-place system). The two pipelines share `BasePartBuildTimer`, `BasePartBreakable`, and the `BasePartSetupHelpers` editor helpers — they diverge cleanly above that.

---

## 1. Two-Layer Architecture (Aaron 2026-05-29 pivot)

The system is split into a **persistent record layer** and a **runtime view layer**. The record is the source of truth; the scene is a view. This decoupling unlocks persistence, multi-context rendering (build in space, render on planet), and future ECS instancing.

| Layer | Lives where | Owns |
|---|---|---|
| **Record** ([`SurfaceBaseRecord`](../../Assets/Scripts/Schemas/SurfaceBaseRecord.cs)) | [`SurfaceBaseStore`](../../Assets/Scripts/Macro/SurfaceBase/SurfaceBaseStore.cs) (in-memory dictionary; BRIDGE for PlayFab Title Data) | `baseId`, `ownerId`, `bodyId`, anchor pos + basis, `claimRadiusMetres`, `tiles: List<TileRecord>` |
| **View** ([`SurfaceBaseRenderer`](../../Assets/Scripts/Macro/SurfaceBase/SurfaceBaseRenderer.cs)) | Per-base MonoBehaviour in the scene | Spawned `SurfaceBaseAnchor` + child `BaseTileInstance` GameObjects |
| **Catalog** ([`BaseTileSchema`](../../Assets/Scripts/Schemas/BaseTileSchema.cs)) | `Assets/GameData/Bases/SurfaceTiles/T<n>/` (static ScriptableObjects) | The 8 m-quantized building pieces — shape, role, sockets, stability, prefab address |

**Flow:**
1. Player clicks a tile card → `SurfaceTilePlacer` computes a ghost pose.
2. Player confirms → placer writes a `TileRecord` to `SurfaceBaseStore.AddTile(baseId, tile)`.
3. Store fires `OnTileAdded` → `SurfaceBaseRenderer` instantiates the prefab, registers in grid + stability, recomputes.
4. Player deletes (SHIFT + right-click) → placer reads the tile's `tileRecordInstanceId` → `SurfaceBaseStore.RemoveTile(baseId, instanceId)` → renderer destroys, cascades collapse via stability.
5. Stability cascade collapses unsupported tiles → `SurfaceStabilityGraph.CollapseTile` calls `SurfaceBaseStore.RemoveTile` so the record stays consistent.

The placer never instantiates prefabs anymore. The renderer never decides where things go. Single source of truth.

## 1.1 The Schema Family

| Schema | Role | Example | Storage |
|---|---|---|---|
| [`BaseTileSchema`](../../Assets/Scripts/Schemas/BaseTileSchema.cs) | One 8 m-quantized building piece. Shape (square / triangle / wall / ceiling / ramp / pillar) + role + grid footprint + sockets + stability values. | `Tile_Foundation_Square_T1`, `Tile_Wall_Straight_T1`, `Tile_Ceiling_Square_T1`, `Tile_Foundation_Triangle_T1`, `Tile_Ramp_T1` | `Assets/GameData/Bases/SurfaceTiles/T<n>/` |

One schema class covers all surface-tile shapes. Differentiation is via the `shape` and `role` enums, not via separate classes — this keeps the catalog query (`AssetDatabase.FindAssets("t:BaseTileSchema")`) returning every tile in one shot.

**Picking the right tile shape:**

| Want | Shape | Role |
|---|---|---|
| 4 m × 4 m floor cell on the ground | `Square` | `Foundation` |
| Triangle floor cell extending off a square's edge | `Triangle` | `Foundation` |
| Vertical wall along a foundation edge | `Wall` | `Wall` |
| Flat ceiling spanning four walls | `Square` | `Ceiling` |
| Triangle ceiling above a triangle foundation | `Triangle` | `Ceiling` |
| Sloped ramp between two altitudes | `Ramp` | `Ramp` |
| Vertical support post | `Pillar` | `Pillar` |

---

## 2. Schema Field Reference

### Identity
| Field | Notes |
|---|---|
| `tileID` | Stable string ID (e.g. `tile_foundation_square_t1`). DB key. |
| `displayName` | Player-facing name. |
| `description` | Tooltip / inspect-panel text. |
| `icon` | 2D sprite for the build-panel card. |

### Geometry
| Field | Notes |
|---|---|
| `shape` | `TileShape` enum — `Square`, `Triangle`, `Wall`, `Ceiling`, `Ramp`, `Pillar`. Drives socket layout and grid math. |
| `role` | `TileRole` enum (source of truth = `BaseTileSchema.cs`). Structural: `Foundation`, `Wall`, `Ceiling`, `Ramp`, `Pillar`. Non-structural (excluded from the stability graph; grid- or socket-snapped, never collapse): `Decorative`, `ConduitHolder`, `Corridor`, `Catwalk`, `Facility`, `Pipe`, `Communication`. Drives stability graph and snap eligibility. |
| `cellWidth` | Side length s in metres. **Must be 4.0** for v1 — the grid is hard-coded to 4 m. Stored on the schema for forward-compat. |
| `triangleHeight` | Read-only convenience field. For triangular shapes = `cellWidth × √3 / 2 ≈ 3.464 m`. For non-triangular shapes = 0. Computed in `OnValidate`. |
| `verticalRise` | For walls / ramps / pillars: how tall the piece is along its local up. Walls = 3 m default; ramps = 4 m (one cell rise); pillars match wall height. |

### Visual + placement
| Field | Notes |
|---|---|
| `prefabAddress` | AssetDatabase path (BRIDGE) / Addressables key (target). |
| `placementScale` | Uniform scale multiplier at instantiation. 1.0 = vendor prefab scale. |

### Sockets
| Field | Notes |
|---|---|
| `sockets` | `TileSocket[]` — explicit socket list. See § 4 for the layout per shape and the `TileSocketKind` enum. |

### Structural integrity
| Field | Notes |
|---|---|
| `canBeRoot` | If true, this tile can sit on terrain as a root node (Stability = 100). Foundations only. |
| `baseStability` | Stability the tile starts with when it is a root node. Always 100 for `canBeRoot=true`. |
| `stabilityLossPerHop` | How much stability a *downstream* (child) tile loses when inheriting from this tile. See § 5 for the formula. |
| `minStabilityToStand` | If this tile's resolved stability drops below this at any moment, it collapses (gets destructed). Default 1. |

### Categorization
| Field | Notes |
|---|---|
| `menuPlacement` | `MenuPlacement` enum — `Main` / `Misc` / `Upgrade`. Drives whether the card shows in the SURFACE TILES tab, the Misc tab, or only inside an inspect-panel addon picker. |
| `menuSection` | Optional in-tab **section-divider** label (e.g. the COMMUNICATION tab's tiers: *Radar / Planetary Array / Regional Array / Alliance Array / Interstellar Array*). When any card in a role tab sets it, that tab groups its cards under `BuildSectionLabel` headers ordered by `tileID`. Empty = flat list. |
| `tier` | 1-5. Higher tiers = stronger materials / more HP, same grid footprint. |

### Build
| Field | Notes |
|---|---|
| `buildTimeSeconds` | Drone-delivery duration. Default 6 s for walls / ceilings, 10 s for foundations, 8 s for ramps. Tune per part. Much shorter than free-place modules — tiles are cheap. |
| `buildCost` | `List<RecipeInput>` — materials drawn from base storage at placement. Validated server-side. |

### Tech tree
| Field | Notes |
|---|---|
| `prereqTileIds` | Player must have built at least one of each before this tile's card unlocks. |
| `upgradeOf` | If non-null, this tile is an upgrade of the referenced tile (inspect-panel addon picker). |

### Per-piece destruction
Per-piece destruction lives on the prefab children, not the schema. The setup script attaches `BasePartBreakable` to whichever children should break off independently in combat (e.g. wall *panels* but not the wall *frame*). Same pattern as [`pipeline_base.md`](pipeline_base.md) § 5.

---

## 3. The 8 m Grid (Math)

The grid is a **flat lattice in the local tangent plane** of a *base anchor* — the first foundation the player drops on the planet. Subsequent tiles are placed in cell coordinates relative to that anchor, then projected back to the planet's curved surface for rendering. At the scale of a base (≤ a few hundred metres across), curvature is negligible and the grid behaves like a flat plane.

**Sizes (Aaron 2026-05-29 — doubled from initial 4 m):**

| Constant | Value | Where |
|---|---|---|
| `CellSize` | 8 m | Foundation cube edge, ceiling square edge, triangle side, ramp footprint |
| `LayerHeight` | 8 m | Cube edge — foundation stacking stride (layer N → layer N+1 is one full cube above) |
| `WallHeight` | 6 m | Wall vertical extent. Decoupled from LayerHeight — walls are player-passage sized, not full-cube tall |
| `TriangleHeight` | ≈ 6.928 m | s × √3/2 with s = 8 m |
| `claimRadiusMetres` | 120 m (default) | Probe-stand-in claim disc — the buildable region around the first foundation |
| Tile thickness (foundation slab / ceiling) | 0.4 m | Doubled with the cube scale |

### 3.1 Base anchor

The first foundation placed defines:
- `AnchorWorldPos` — the foundation's pivot in world space (snapped to terrain via raycast against `SgtSphereLandscape.GetLocalPoint`).
- `AnchorUp` — the planet surface normal at that point.
- `AnchorForward` — the camera's forward projected onto the tangent plane at placement time. Defines cell-grid orientation. Once set, never changes for the lifetime of that base.
- `claimRadiusMetres` — the radius of the **buildable claim** around the anchor (default 60 m). See § 3.6.

Stored on `SurfaceBaseAnchor` (a runtime MonoBehaviour added to the first foundation). All later placements quantize against this anchor.

### 3.6 Claim bounds (probe-stand-in)

> ⚠️ **Superseded for base start (2026-06-09):** the "first foundation acts as the probe-stand-in" shim below is replaced by the **Base Deployment Beacon** — the player deploys a beacon to establish the anchor + claim, and `claimRadiusMetres` moves onto `BeaconSchema` (the `ProbeSchema` this section anticipated). Spec: [`../ground_base/ground_base_deployment_beacon.md`](../ground_base/ground_base_deployment_beacon.md). The text below is kept for historical context until the beacon ships.

The eventual world model: the player drops a dedicated **Probe** item to claim a region of terrain, then builds inside that claim. The probe schema doesn't ship in v1 — the **first foundation acts as the probe-stand-in**, claiming its own circular region.

**Rules:**
- The first foundation placed on terrain is allowed **anywhere** (no claim exists yet). Its placement establishes the anchor + the claim circle.
- Every tile placed **after** the first foundation must fall **inside the claim disc** (Euclidean distance from `AnchorWorldPos`, measured on the anchor's tangent plane). Outside → ghost goes red, click blocked. Same UX as occupied-cell rejection.
- The claim is rendered as a cyan `LineRenderer` ring on the terrain (sampled and raycast-projected so it follows terrain contours). Visible whenever the anchor exists.
- Radius defaults to 60 m. Inspector-tunable on `SurfaceBaseAnchor` for testing; will move to a per-probe-schema field when the real Probe ships.

**BRIDGE:** `SurfaceBaseAnchor.claimRadiusMetres` hardcoded value. Replace with `ProbeSchema.claimRadiusMetres` when the Probe schema lands (future phase). The first-foundation-as-probe shim collapses into "probe placed → spawns anchor" at that point.

### 3.2 Cell coordinates

Every square tile occupies one **cell** identified by integer `(cellX, cellZ)`. World position is:

```
WorldPos = AnchorWorldPos
         + AnchorRight   × (cellX × 4)
         + AnchorForward × (cellZ × 4)
```

then projected to the terrain surface (raycast down from a small altitude). The anchor itself is `(0, 0)`.

**Snap formula** (the cursor-to-grid quantization the player feels):

```csharp
// Cursor hit position projected into anchor-local space
Vector3 local = WorldToAnchorLocal(cursorHit);
int cellX = Mathf.RoundToInt(local.x / 4f);
int cellZ = Mathf.RoundToInt(local.z / 4f);
```

The grid is **infinite** at the schema level. Practical limit comes from the per-base slot count enforced in CloudScript (Phase 6.9.A.tile.5).

### 3.3 Triangle math

An equilateral triangle with side length 4 m has:
- 3 vertices, each angle 60°.
- Height (vertex-to-opposite-edge) = `4 × √3/2 ≈ 3.464 m`.
- Centroid = 1/3 of the height from each edge = `3.464 / 3 ≈ 1.155 m`.

Triangles are **edge-attached, not cell-occupying**. A triangle foundation does NOT live in `(cellX, cellZ)`. Instead, it attaches to one edge of an existing square foundation (or another triangle) via that edge's socket. Its pivot is at its centroid, offset outward from the parent edge by 1.155 m.

This means the integer cell grid tracks only squares. Triangles are tracked as **edge-bound nodes** in the placement registry — keyed by `(parentTileId, parentEdgeIndex)` rather than by `(cellX, cellZ)`. The structural-integrity graph treats them the same as squares (a triangle on a square inherits stability from the square; a square on a triangle inherits from the triangle).

### 3.4 Rotation

Tiles snap to **fixed 90° increments** for squares / walls / ceilings / ramps (`yaw ∈ {0, 90, 180, 270}`), and **fixed 60° increments** for triangles (`yaw ∈ {0, 60, 120, 180, 240, 300}`). The player presses **SHIFT + A / SHIFT + D** to cycle the ghost's rotation through the allowed values for the current shape (Q/E retired 2026-05-29 because of GroundBuildOrbitCamera conflicts).

No free rotation. No 45° increments. Matches the doc's "Fixed Cardinal Directions" prescription for an RTS-style grid.

### 3.4a Player controls (placement)

| Input | Action |
|---|---|
| Card click in build panel | Begin placing that tile |
| Move cursor over terrain or existing tile | Ghost previews placement |
| **Left-click** | Confirm placement (when ghost is cyan / orange) |
| **SHIFT + A** | Rotate ghost CCW (90° squares / 60° triangles) |
| **SHIFT + D** | Rotate ghost CW |
| **SHIFT + Right-click** on a placed tile | Delete it (cascades collapse for unsupported downstream tiles) |
| **Esc** | Cancel current placement |

### 3.5 Vertical layers

Tiles stack on an integer vertical level `layer ∈ ℤ`. **Layer stride is one cube edge (4 m)** — chosen so foundation cubes stack on integer-layer steps. The first foundation sits at layer 0 (its anchor altitude); the layer above is +4 m, the layer below is -4 m.

**Foundation placement rules — Minecraft strict-grid model** (Aaron 2026-05-29):
- The first foundation establishes layer 0 at its terrain hit point (lifted by `verticalRise/2` so the cube's bottom sits on terrain). The grid frame uses **world up (`Vector3.up`)**, NOT planet-radial up — so every subsequent brick snaps to a perfectly flat grid in world Y, with no cm-per-cell drift from planet curvature. The first brick's *position* still respects planet geometry (it sits on the terrain wherever the player clicked); only the grid *frame* is world-axis aligned. For huge bases (>1 km) that need to follow planet curvature, swap back to `GetPlanetUp(worldPos)` in `CreateAnchorAt`.
- A new foundation placed on **terrain** = always layer 0 (anchor plane). No terrain-derive — small bumps don't shift the layer. If the player wants higher / lower, they EXPLICITLY click an existing foundation:
  - **Cursor on top face** of an existing foundation → `ResolveSquareStack`, places at `layer + 1` (same cell, one cube up).
  - **Cursor on side face** of an existing foundation → `ResolveSquareEdgeAttach`, places in the adjacent cell at the SAME layer as the target. (Click a layer-3 foundation's side face → adjacent foundation also at layer 3.)
  - Disambiguation: `dot(hit.normal, anchor.anchorUp) > 0.7` → top face. Otherwise → side face.

**Walls / ceilings / ramps / pillars** position themselves **relative to their target tile's geometry**, not relative to integer cube layers (since wall + ceiling altitudes don't fit on the 4 m stride):
- **Wall** on a foundation cube → pivot = target edge midpoint + `up × (cubeHalfHeight + wallHalfHeight)`. Bottom sits on the cube's top edge.
- **Ceiling** on a foundation cube → `target.position + up × (cubeHalfHeight + ceilingHalfThickness)`. Flat roof directly on the cube.
- **Ceiling** on a wall → `target.position + up × (wallHalfHeight + ceilingHalfThickness)`. Roof on top of wall.
- **Ceiling** on another ceiling (cantilever) → same altitude, adjacent cell.
- **Pillar** on a foundation → same as wall (sits on the cube top).
- **Ramp** adjacent to a foundation → pivot at the adjacent cell at the foundation's layer; ramp geometry slopes up to meet the cube top.

---

## 4. Sockets

Each tile carries a hand-authored set of `TileSocket` entries. A socket has:

| Field | Notes |
|---|---|
| `kind` | `TileSocketKind` enum. Snapping requires matching kinds (with the exception of `Universal`). |
| `localPosition` | Position in tile-local space. Should sit on an edge midpoint, edge endpoint, or top/bottom face. |
| `localEulerAngles` | Outward facing direction. The snap math rotates the incoming tile so its mating socket points back along this vector. |
| `edgeIndex` | For foundations (square / triangle): which edge this socket lives on. Square = 0..3 (N, E, S, W). Triangle = 0..2 (per the right-hand winding). For walls / ceilings: 0 = bottom, 1 = top, 2+ = sides. |

### 4.1 Socket kinds

| Kind | Mates with | Used by |
|---|---|---|
| `FoundationEdge` | `FoundationEdge` | Foundation-to-foundation, edge-to-edge. Square has 4; triangle has 3. |
| `FoundationTop` | `WallBottom`, `PillarBottom`, `RampBottom`, `RampTop` | Foundation's / floor's top edge — walls / pillars rise from it; a ramp's foot climbs UP from it, or a ramp's head slopes DOWN off the edge. One per foundation edge (square = 4, triangle = 3), positioned at the edge midpoint on the top surface. |
| `WallBottom` | `FoundationTop` | Wall's bottom edge, mates to a foundation's top-edge socket. |
| `WallTop` | `CeilingEdge`, `WallBottom`, `RampBottom`, `RampTop` | Wall's top edge — supports a ceiling, stacks another wall, and is a ledge a ramp snaps to: a ramp's head lands here to walk UP onto the wall from the floor below, or its foot lands here to climb higher. Reachable from one build level down (ramp-only +1-level gate). |
| `CeilingEdge` | `WallTop`, `CeilingEdge`, `RampBottom`, `RampTop` | Ceiling / roof / floor rim. Mates a wall top, a neighbor ceiling's edge (cantilevered spans), or a ramp end (a ramp snaps onto a roof/floor rim as a ledge). Square = 4; triangle = 3. |
| `RampBottom` | `FoundationTop`, `WallTop`, `CeilingEdge`, `RampTop` | Ramp's foot (downhill end). Sits on a foundation / floor / wall top or a roof/floor rim to climb UP, or meets another ramp's head to chain. |
| `RampTop` | `FoundationTop`, `WallTop`, `CeilingEdge`, `RampBottom` | Ramp's head (uphill end). Lands on a foundation / floor / wall top or a roof/floor rim — slopes DOWN off a foundation edge, or walks UP onto a wall/roof from the floor below — or meets another ramp's foot to chain. A ramp snaps ONLY to these ledge sockets; with no ledge near the cursor the ghost hides (no free-ground placement). |
| `PillarBottom` / `PillarTop` | `FoundationTop` / `CeilingEdge` | Pillar end-caps. |
| `Universal` | Anything | Reserved for special parts (decoratives). Don't use on structural tiles. |

### 4.2 Snap algorithm

When the player has a ghost tile in hand:

1. **Raycast** from the camera to find the closest existing tile in front of the cursor.
2. **Iterate the target's free sockets** (sockets not already mated). For each, compute the candidate ghost pose if the ghost's first compatible socket were aligned to it.
3. **Score candidates** by camera-to-candidate-pivot distance. Pick the closest within `snapThresholdMetres` (default 2 m).
4. **Apply pose**: `ghost.position = target.SocketWorldPosition(s)` and `ghost.rotation = target.SocketWorldRotation(s) × Quaternion.Euler(0, 180, 0)` (the 180° flip is so the ghost's outward normal faces *back into* the target).
5. **Cell registration** (square only): translate the resulting pivot into anchor-local coordinates, round to nearest `(cellX, cellZ)`, reject if that cell is already occupied at this layer.
6. **Compatibility loop check**: after the primary snap, iterate the ghost's *other* sockets and check if any incidentally line up with free sockets on adjacent placed tiles (e.g. a square dropped into a U-shape closing the fourth edge). Auto-mate them if so. Same auxiliary-socket pattern as the existing free-place system.

**Failure modes:**
- No nearby target → ghost free-floats on terrain at cursor + cell-snapped to anchor grid (works for the very first foundation).
- Target found but no compatible kinds → ghost shows red, no snap.
- Cell already occupied → ghost shows red, blocks confirm.
- Stability would resolve below `minStabilityToStand` → ghost shows orange, allows confirm but warns "structurally unstable" in the HUD.

---

## 5. Structural Integrity Graph

The base is a **Directed Acyclic Graph**. Foundations are root nodes. Walls / ceilings / ramps / pillars are downstream nodes inheriting stability from their attachment points.

### 5.1 Stability propagation

When a tile is placed or destroyed, the system runs a recursive recompute:

```
Stability(T) =
    if T.canBeRoot AND T is grounded:  baseStability  (= 100)
    else:                              max( Stability(P) for P in parents(T) ) - parents[0].stabilityLossPerHop
```

`parents(T)` = the set of other tiles whose sockets are mated to T's sockets and which are *upstream* of T (closer to a foundation root).

**Default loss values:**

| Tile role | `stabilityLossPerHop` |
|---|---|
| `Foundation` (Square / Triangle) | 0 — foundation-to-foundation is lossless when both are grounded. |
| `Foundation` (cantilevered — not on terrain, attached to neighbor foundation) | 10 |
| `Wall` | 0 — walls don't lose stability themselves; they pass it through. |
| `Ceiling` | 25 — each ceiling hop costs 25. Per the source doc, this means 4 cells of cantilever before collapse (100 → 75 → 50 → 25 → 0). |
| `Ramp` | 5 |
| `Pillar` | 0 — same as wall, structural transfer. |

If `Stability(T) < minStabilityToStand`, T **collapses** — `BasePartBreakable.Shatter()` fires, T is removed from the placement registry, and the recompute cascades to T's children.

### 5.2 Grounded check

A foundation is **grounded** if its world-space center is within `groundedTolerance` metres of the terrain surface (default 0.5 m, raycast against `SgtSphereLandscape`). The base anchor is always grounded by construction. Adjacent foundations placed via foundation-edge snap are grounded if they too sit within tolerance of the terrain at their cell center. A foundation placed on top of a ceiling (multi-story) is NOT grounded — it depends on the structure below.

### 5.3 Placement preview

While the ghost is in hand and a snap is locked, the system runs a *speculative* recompute including the ghost as if placed. The HUD shows the ghost's resolved stability live. Below `minStabilityToStand` → orange ghost + "Will collapse" warning. Above → green ghost.

---

## 6. Folder Layout

```
Assets/GameData/
└── Bases/
    └── SurfaceTiles/
        ├── T1/           ← BaseTileSchema, tier 1
        │   ├── Tile_Foundation_Square_T1.asset
        │   ├── Tile_Foundation_Triangle_T1.asset
        │   ├── Tile_Wall_Straight_T1.asset
        │   ├── Tile_Ceiling_Square_T1.asset
        │   ├── Tile_Ceiling_Triangle_T1.asset
        │   └── Tile_Ramp_T1.asset
        └── T2/           ← BaseTileSchema, tier 2 (future)

Assets/Prefabs/Bases/
└── Tiles/
    ├── Foundation_Square_T1/
    │   ├── Foundation_Square_T1.prefab
    │   └── Materials/{Iron,CarbonBlack,…}.mat
    ├── Foundation_Triangle_T1/
    ├── Wall_Straight_T1/
    ├── Ceiling_Square_T1/
    ├── Ceiling_Triangle_T1/
    └── Ramp_T1/

Assets/Scripts/Schemas/
└── BaseTileSchema.cs

Assets/Scripts/Macro/SurfaceBase/
├── SurfaceBaseAnchor.cs       ← runtime anchor MonoBehaviour
├── SurfaceGridManager.cs      ← cell registry + coordinate math
├── SurfaceTilePlacer.cs       ← ghost preview, snap, click-to-place
├── SurfaceStabilityGraph.cs   ← DAG + recompute
└── SurfaceTileCatalog.cs      ← auto-discovery (AssetDatabase.FindAssets t:BaseTileSchema)

Assets/Editor/
└── Tile_<Name>_Setup.cs       ← one per tile (re-runnable [MenuItem])
```

---

## 7. Setup Script Template

```csharp
using UnityEditor;
using UnityEngine;
using ApexOutlaw.Schemas;

public static class Tile_Foundation_Square_T1_Setup
{
    [MenuItem("Apex Outlaw/Setup/Tile_Foundation_Square_T1")]
    public static void Execute()
    {
        const string fbxPath    = "Assets/Prefabs/Bases/Tiles/Foundation_Square_T1/Foundation_Square_T1.fbx";
        const string prefabPath = "Assets/Prefabs/Bases/Tiles/Foundation_Square_T1/Foundation_Square_T1.prefab";
        const string schemaPath = "Assets/GameData/Bases/SurfaceTiles/T1/Tile_Foundation_Square_T1.asset";

        BasePartSetupHelpers.ConfigureFBXImporter(fbxPath);

        var ironMat = BasePartSetupHelpers.LoadOrCreateLitMaterial(
            "Assets/Prefabs/Bases/Tiles/Foundation_Square_T1/Materials/Iron.mat",
            new Color(0.22f, 0.22f, 0.24f, 1f), metallic: 0.85f, smoothness: 0.45f);

        BasePartSetupHelpers.BuildPrefabFromFBX(fbxPath, prefabPath, instance =>
        {
            BasePartSetupHelpers.AssignMaterial(instance, "Top",   ironMat);
            BasePartSetupHelpers.AssignMaterial(instance, "Sides", ironMat);
            BasePartSetupHelpers.MakeChildBreakable(instance, "Top",
                hp: 500f, force: 4f, radius: 2f, upMod: 1.0f, linger: 4f, mass: 40f);
        });

        BasePartSetupHelpers.LoadOrCreateSchema<BaseTileSchema>(schemaPath, s =>
        {
            s.tileID         = "tile_foundation_square_t1";
            s.displayName    = "Foundation (Square, T1)";
            s.description    = "Standard 4 m square foundation. Roots a stability tree.";
            s.shape          = TileShape.Square;
            s.role           = TileRole.Foundation;
            s.cellWidth      = 4f;
            s.canBeRoot      = true;
            s.baseStability  = 100f;
            s.stabilityLossPerHop = 0f;
            s.prefabAddress  = prefabPath;
            s.menuPlacement  = MenuPlacement.Main;
            s.tier           = 1;
            s.buildTimeSeconds = 10f;
            // s.buildCost = […]
            s.sockets = BaseTileSetupHelpers.SquareFoundationSockets(s.cellWidth);
        });

        Debug.Log("[Tile_Foundation_Square_T1] Setup complete.");
    }
}
```

`BaseTileSetupHelpers.SquareFoundationSockets(s)` returns the canonical 4-edge socket array for a square of side `s`. Same helper has `TriangleFoundationSockets`, `WallSockets`, `CeilingSquareSockets`, etc. — one helper per shape so the setup scripts stay thin and socket geometry is consistent across all tiles of a kind.

---

## 8. Build Pipeline Integration

When the player confirms placement:

1. `SurfaceTilePlacer.ConfirmPlacement` instantiates the prefab as a child of `SurfaceBaseRoot/<baseId>/`.
2. Adds `BaseTileInstance` with the schema reference and the resolved `(cellX, cellZ, layer)` or `(parentTileId, edgeIndex)` for triangles.
3. Adds `BasePartBuildTimer` with `buildTimeSeconds` — exactly the existing drone-hologram reveal flow from [`pipeline_base.md`](pipeline_base.md) § 7. The drone fleet trips out from the base's Construction Yard module (when one exists) or from a generic drop-pod spawn point (anchor-relative) until CY semantics are wired for surface bases.
4. Registers the tile in `SurfaceGridManager` (cell occupancy) and `SurfaceStabilityGraph` (node + edges).
5. Triggers a stability recompute, which cascades to neighbours.

**Server validation** (Phase 6.9.A.tile.5, deferred to land alongside `BuildSurfaceTile` CloudScript):
- Confirm cell is free.
- Confirm sockets actually mate.
- Confirm `buildCost` is met from base storage.
- Confirm resulting stability ≥ `minStabilityToStand`.

Until that lands, validation is client-side only with a BRIDGE comment.

---

## 9. Runtime Consumers

| Consumer | What it reads | When |
|---|---|---|
| `SurfaceTileCatalog` | Every `BaseTileSchema` asset | Build-panel populate |
| `SurfaceBuildPanel` | Every field (cards, tooltips, cost display) | UI render |
| `SurfaceTilePlacer` | `shape`, `cellWidth`, `sockets`, `prefabAddress`, `buildTimeSeconds` | Ghost preview + placement |
| `SurfaceGridManager` | `shape`, `cellWidth`, `triangleHeight` | Cell occupancy + coordinate math |
| `SurfaceStabilityGraph` | `canBeRoot`, `baseStability`, `stabilityLossPerHop`, `minStabilityToStand` | Stability recompute on every place / destroy |
| `BaseTileInstance` | `sockets` (for runtime mate-lookup) | Per-tile runtime |
| `BasePartBuildTimer` | `buildTimeSeconds` (passed in at placement) | Build sequence |
| `BasePartBreakable` (per piece) | Authored at setup time, not read live | Combat (Phase 4) + stability collapse |
| CloudScript `BuildSurfaceTile` (Phase 6.9.A.tile.5) | `buildCost`, `prereqTileIds`, full sockets | Server-authoritative placement |

---

## 10. Authoring Checklist — Adding a New Tile

- [ ] **Pick the shape + role** (§ 1 table).
- [ ] **Get the FBX into the right folder** — `Assets/Prefabs/Bases/Tiles/<TileName>/<TileName>.fbx`. Author at world scale (1 unit = 1 metre). Side length = 4 m for any square/triangle/wall.
- [ ] **Decide per-piece destruction** — which children should break off individually when this tile collapses (or takes combat damage)? List them; the rest stay as cosmetic skeleton.
- [ ] **Author the materials** (or use existing Iron / CarbonBlack).
- [ ] **Write the setup script** at `Assets/Editor/Tile_<Name>_Setup.cs` from the § 7 template.
- [ ] **Fill in the schema fields** per § 2's reference. Pay particular attention to:
  - `shape` + `role` (drives socket helper + stability defaults)
  - `cellWidth` = 4 always
  - `canBeRoot` (only foundations)
  - `stabilityLossPerHop` (foundations = 0, ceilings = 25, etc.)
  - `menuPlacement` (Main / Misc / Upgrade)
  - `buildCost` (use existing `ResourceSchema` assets)
  - `prereqTileIds` (what must exist before this card unlocks)
- [ ] **Use the shape-matching socket helper** (`BaseTileSetupHelpers.<Shape>Sockets`). Don't hand-author the socket array.
- [ ] **Run the setup script** from `Apex Outlaw → Setup → Tile_<Name>` menu.
- [ ] **Verify in the editor**:
  - Prefab exists at the expected path
  - Schema asset exists with the right values
  - Materials assigned to the expected children
  - Per-piece breakables present on the destructible children
  - `triangleHeight` auto-populated on triangle shapes (≈ 3.464)
- [ ] **Play-test in `PlanetTest_Alythar.unity`**:
  - The card appears in the SURFACE TILES tab
  - Ghost preview shows on the terrain at cursor
  - Snap locks to a 4 m cell (first foundation) or to an adjacent tile's socket
  - Q / E cycles rotation through allowed increments (90° for squares, 60° for triangles)
  - Stability HUD shows correct value live during ghost preview
  - On confirm, drone delivers and reveals piece by piece
  - On destruction, stability cascade collapses dependent tiles
- [ ] **Document if you authored anything new** beyond an instance:
  - New socket kind → update § 4.1 table
  - New tile role / shape → update § 1 table + `TileRole` / `TileShape` enums + the matching socket helper
  - New `stabilityLossPerHop` default → update § 5.1 table

---

## 11. What's Live vs. In Flight

**Live (this pipeline doc, 2026-05-29):**
- Pipeline doc itself

**In flight (Phase 6.9.A.tile, this session — see master_to_do.md):**
- `BaseTileSchema` ScriptableObject
- `SurfaceGridManager` + `SurfaceStabilityGraph` + `SurfaceTilePlacer` + `SurfaceBaseAnchor`
- `BaseTileSetupHelpers` editor helpers (per-shape socket generators)
- Six starter tile schemas + prefabs (Foundation Square T1, Foundation Triangle T1, Wall T1, Ceiling Square T1, Ceiling Triangle T1, Ramp T1)
- Scene wiring in `PlanetTest_Alythar.unity`: `SurfaceBaseRoot` GameObject hosting the placer + grid manager

**Deferred (later tile-pipeline phases):**
- Multi-story (layers 2+) — pillars, multi-floor stability rules
- Server-authoritative `BuildSurfaceTile` CloudScript (validation runs client-side until then)
- Integration with `MacroBaseRecord` PlayFab persistence — per-tile list persisted to title data
- Surface CY semantics: which placed module spawns drones for tile delivery (currently anchor-spawn)
- Material upgrade visualisation when a tile is upgraded via `upgradeOf`
- Hex tile shape (6-sided) — not in scope for first pass

---

## 12. Bridge Code (per CLAUDE.md "Building durably" rule)

Tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md) under Phase 6.9.A.tile:

- `SurfaceTilePlacer.ConfirmPlacement` — `BRIDGE: client-side validation only. Remove when BuildSurfaceTile CloudScript ships.` Without it, a malicious client can spam tiles.
- `SurfaceBaseRoot` per-base tile list — `BRIDGE: in-memory only. Replace when MacroBaseRecord.tiles[] persists to PlayFab title data.` Lost on scene reload until then.
- Drone delivery spawn point in `SurfaceTilePlacer` — `BRIDGE: spawns drone from base anchor. Replace with Construction Yard module spawn when surface-base CY semantics land.`

---

## See also

- [`pipeline_base.md`](pipeline_base.md) — the parallel free-place / socket / conduit pipeline (orbital + legacy)
- [`pipelines_overview.md`](pipelines_overview.md) — six-stage pattern shared across all pipelines
- [`../world/world_surface_scene.md`](../world/world_surface_scene.md) — Scene 3 (surface) canon; defines where these tiles live
- [`../ground_base/progression_base_building.md`](../ground_base/progression_base_building.md) — base-construction progression (when surface tiles unlock relative to orbital chassis)
