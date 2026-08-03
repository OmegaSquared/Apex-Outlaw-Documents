---
status: canon workflow
phase: ship-building
last-reviewed: 2026-06-09
---

# Part Identification Process for Ships

> The repeatable workflow for breaking a donor ship model into hand-curated build parts.
> Locked after the SM8 Bomber pass (2026-06-09) — Aaron: "That workflow is perfect."
> Aaron points at geometry in Blender; the assistant cuts, bakes, and wires Unity. No
> position-heuristic auto-cutting — that was scaffolding and it grouped pieces wrong.

## Roles

- **Aaron (in Blender):** visually selects the islands that make up each part; names the part; states mirror side ("left" = his left with the nose facing him).
- **Assistant (via Blender MCP + Coplay):** explodes, colors, joins, names, cap-fills, exports, bakes prefabs/schemas, removes baked parts from the working file, saves after every lock-in.

## The process, step by step

1. **Open the ship's working blend** (`Assets/Art_Assets/ShipParts/<Ship>/<prefix>_chunks.blend`). If starting fresh from a donor FBX, import it and delete bundled weapon props into their own consideration pile.
2. **Explode everything** into loose-part islands (`mesh.separate(type='LOOSE')` on every object).
3. **Color every island uniquely** — golden-ratio hue spread so adjacent pieces always contrast. CRITICAL: set BOTH the shader node color AND `material.diffuse_color`, and switch viewport Solid shading `color_type = 'MATERIAL'`, or Aaron sees one silver mesh.
4. **Aaron selects a group** in the viewport and says what it is (e.g. "this is the missile launcher", "left wing", "right side-mounted engine").
5. **Assistant locks it in** — one scripted pass:
   - read `bpy.context.selected_objects`,
   - `join` → rename to `<prefix>_Part_<Name>` (free the name from leftover islands first — rename strays to `Island_###`),
   - restore the donor material + append `PartCap_Black`, `bmesh.ops.holes_fill` on boundary edges → cap faces get the cap material,
   - export FBX to `Assets/Art_Assets/ShipParts/<Ship>/`,
   - **remove the part from the working blend** (fewer pieces = easier picking),
   - `save_mainfile()` — ALWAYS, immediately (Aaron's Ctrl+Z cannot cleanly undo scripted joins; saving makes each lock-in durable).
6. **Bake the Unity side** — `Temp/CoplayBakePart.cs` via Coplay `execute_script` with args `{part, ship, bucket, mat}`: refresh, instantiate the FBX, bind family material + `PartCap_Black` by slot name, save prefab under `Assets/Prefabs/ShipParts/<bucket>/<Ship>/`.
7. **Repeat 4–6** until the remainder IS the hull — the last group becomes `<prefix>_Part_Hull`.
8. **Finishing pass** — schemas (one per part; mirrored pairs share a schema with `prefab`/`mirroredPrefab` + `mirrorPlacement`), stats, sockets, rules updates, and deletion of any stale machine-cut schemas/prefabs/FBXs for that family.

## Conventions learned on the bomber

- **Mirror naming:** "left" = Aaron's left, nose toward viewer = world −X in the donor blends. `prefab` field gets the +X (right) mesh, `mirroredPrefab` the −X mesh.
- **Mirror sanity check:** a true mirror pair joins from the same island count with identical vert counts (bomber wings: 9 islands / 462 verts per side; cannons 6/308; engines 3/444). A mismatch means the selection missed a piece.
- **Small ships have no Cockpit part** — the hull includes the canopy ("bomber hull includes the cockpit"). Bridges become parts on capital chassis later. Cockpit rule is 0–1.
- **Parts can span the old buckets** — the bomber's launcher pulled islands from what the heuristic called hull, nose, AND both wings. That's why hand-cutting wins.
- **Verify selection state before acting** when Aaron mentions an undo — query the scene, don't assume; his undos usually only revert colors/selection, not scripted joins.
- New part classes minted on demand (bomber added **EnginePod**, **MissileLauncher** + the **Missile** fitting socket). Don't force new anatomy into old classes.
- **⚠ Blender FBX roundtrips flatten material groups (2026-06-10):** the label-swap reimport/re-export collapsed every part to ONE submesh, silently destroying the PartCap assignments on all three ships. After ANY roundtrip, verify `subMeshCount == 2` on the baked prefabs. **Recovery (now canon): caps are re-derived geometrically** — import all of a ship's parts at origin (assembled donor pose), build a BVH of every OTHER part, and any face whose center sits within 0.2m of a neighbour is a connection face → assign PartCap_Black. Caps = snap faces in the builder, so this derivation is also their semantic definition.
- **⚠ The X-flip (frigate lesson, 2026-06-09):** Blender and Unity disagree on handedness — a mesh sitting at Blender world −X imports to the OPPOSITE visual side in Unity. Side labels must be confirmed **in the Unity builder**, never from Blender world X alone. ALL hand-cut mirror pairs on all three ships shipped reversed and were label-swapped on 2026-06-09 (re-export with swapped names; schema refs untouched since they point at filenames): frigate wings + wing engines + medium engines, bomber wings + plasma cannons + engines, fighter wings + cannon sockets + engines + engine2s. If a pair looks wrong in-game, swap the labels — don't re-cut.
- **Never overwrite Aaron's viewport selection** when scanning for candidate islands — report findings instead and let him select.
- **TurretMount is its own class** (split from Turret 2026-06-09): mounts are hardpoint bases; Turret-class weapons only count as *attached* when contacting a TurretMount part, and the magnet only pulls turrets toward mounts.

## Status per ship

| Ship | Status |
|---|---|
| SM8 Bomber | ✅ hand-cut 2026-06-09 — 9 parts, 6 schemas |
| SM5 Fighter | ✅ hand-cut 2026-06-09 — 9 parts, 5 schemas (socket-only weapon mounts) |
| SM4 Smuggler Frigate | ✅ hand-cut 2026-06-09 — 10 parts, 7 schemas (armed plasma turret + 3 turret mounts; hull 0 open edges, clipping check passed). Engines recut + all side pairs label-swapped for the X-flip; mirrors now exact (wing engines 10 islands/594v, medium engines 22/1667v per side) |
| SM3 / SM6 / SM7 | machine-cut, families disabled in roster |

Known cosmetic asymmetries accepted by Aaron's eye (donor model is itself asymmetric): frigate wing engines differ by ~50v, medium engines by ~50v after merges.
