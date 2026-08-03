# Smelter — Session Handoff

Last touched 2026-05-27 at end of a long session. The smelter is now a working production module end-to-end (UI → input deduction → craft timer → drone export). This doc is the running-state snapshot for the NEXT agent — what works, what's open, where the moving parts live.

## Vocabulary update

The building was renamed **Refinery → Smelter** in this session. `FacilityType.Refinery` is now `FacilityType.Smelter` (enum value 0 unchanged, recipes still serialize correctly). A future generalized "Refinery" facility can be added as a new enum value when needed — Aaron explicitly carved out that namespace.

## What works now

### Placement / snap
- `Smelter_T1.asset` lives at `Assets/GameData/Bases/Modules/T1/Smelter_T1.asset`. Schema sockets reference the **two** embedded conduit outer-tips (Aaron added a second `Conduit_Small_Straight (1)` this session, on the opposite face).
- Prefab at `Assets/Prefabs/Bases/Industry/Smelter_T1/Smelter_T1.prefab`. Root scale 11.877×, root rotation 90°X.
- **Q/E cycle between the two snap points** when the smelter is the ghost. `BaseBuildController.GetSelectedPartSocketCount` reads `schema.sockets.Count` and cycles `ghostInputSocketIndex`.
- **Side-mount disabled** on the smelter (`FacilityModuleSchema.disableSideMountSnap = 1`) so the standard socket-to-socket snap fires instead of perpendicular-conduit mounting.
- Snap rotation convention: schema sockets store the INWARD-facing rotation (Socket_Output direction flipped 180° around Y). If you re-author the sockets, run `Smelter: Add Dual Conduit Sockets (Q/E cycle)` THEN `Smelter: Flip Socket Rotations 180Y`.

### Door choreography
- `HangarDoorOpener.cs` drives the two hangar door pieces (`FrigateHangarDoorUpper` / `FrigateHangarDoorLower`) directly via `Quaternion.Slerp` between a closed pose (captured at Awake) and an open swing delta. **No Animator** — direct Transform manipulation, no animation-clip-path problems.
- Per-door swing is configured in the inspector (`upperOpenSwing` / `lowerOpenSwing`). Currently set so doors swing outward (signs flipped from initial).
- Public API: `HangarDoorOpener.Open()` / `Close()` / `Toggle()`. `SmelterState` drives these during the craft cycle.

### Production state machine — `SmelterState.cs`
Component on the smelter root. Owns the cycle:
- **Idle** → checks `autoRefineToggles` each Update; if a toggle is on AND a nearby player-owned crate has enough of the matching raw, deducts and transitions to Crafting.
- **Crafting** → timer runs (`secondsPerOutputTon × output[0].qty`, default 10s/ton, 100-ton cap). Drives `HangarDoorOpener.Close()` and `SmelterActiveVisuals.SetRefining(true)`.
- **Exporting** → on completion: spawns a refined-output `CrateInstance` at `outputSpawnLocalOffset`, dispatches `BaseDroneFleet.RequestStockJob` to the nearest empty `CargoSlotState`. Door opens, closes after `exportDoorOpenSeconds` (4s). Transitions back to Idle when the export crate is picked up.

Recipe catalog: `BuildRecipeCatalog` filters all `RecipeSchema` to `requiredFacility == Smelter` AND `inputs[0]` is an authored Raw resource AND `outputs[0]` is in the hardcoded `MetalOutputIDs` set. Result: only `iron+carbon→steel`, `iron+titanium→ferro_titanium`, `gold→gold_ingot`, `silver+copper→electrum_wire`, `nickel+iron→nickel_iron_plating`, `super_conductor`, `scrap_metal→iron`, etc.

### Visuals — `SmelterActiveVisuals.cs`
- 4× `GrateGlow_N` point lights (orange→orange-red, intensity 0 idle → 70 active, range 8). `idleGlowIntensity = 0` so lights are completely OFF when not refining (Aaron pref).
- 8× `Smoke_N` ParticleSystems with horizontal +X drift. Material `Assets/Materials/Refinery/RefinerySmokeParticle.mat` (URP/Particles/Unlit so no shader-error pink).
- `RefineryHum` 3D `AudioSource` playing `ambience_hum_machinery_working.wav` on a loop while refining.
- Space-wind ParticleSystem was removed — directional smoke alone reads better.
- Glow transitions smoothly between idle/active over `glowTransitionSeconds` (1.2s).
- `testRandomToggle` exists but `SmelterState` disables it on Awake (state machine owns the IsRefining flag now).

### UI — `SmelterControlPanel.cs`
- Right-edge panel, opens when player clicks a placed smelter (subscribes to `OnPlacedPartSelected`, shows iff selected part has `SmelterState`).
- Header + IDLE / REFINING-X% status + progress bar.
- Auto-discovered toggle list (one row per refinable raw, label `RawName → OutputName`). Toggle background is a dark inset square with blue outline; amber-fill checkmark when on.
- Wires into `SmelterState.SetAutoRefine(resourceID, bool)`.
- Bottom raised to Y=220 so it doesn't overlap the build strip.

### Inventory panel (separate UI work this session)
`CrateInventoryPanel.cs` — left list compressed: 45% pane width, padding 6/4/2, row height 26px, icon 22px, font 12pt. Grade chip removed; fill bar (translucent blue, alpha 0.50) shows per-row share of visible-tab tons. List expands vertically (panel VLG `childControlHeight = true`).

## Landed 2026-05-27 — Option 2 ingot intermediate

**Every raw metal now smelts to an ingot first; alloys consume ingots, not raws.** Implementation:
- 8 new ingot ResourceSchemas under `Refined Materials/` (iron, copper, nickel, titanium, tungsten, lithium, uranium, silver — gold_ingot already existed)
- 8 new raw→ingot Minting recipes under `Recipes/`
- 5 existing alloy recipes (steel, ferro_titanium, nickel_iron_plating, electrum_wire, super_conductor) updated to consume ingot inputs
- `SmelterState` refactored from per-raw to per-recipe toggles (`AutoRefineToggle.recipeID`, `AvailableRecipeIDs()`, `GetRecipe(recipeID)`)
- `SmelterControlPanel` refactored to render one toggle per recipe with "Iron → Iron Ingot" / "Iron Ingot + Carbon → Steel" labels
- `RequestInputs` now correctly handles ALL inputs (multi-input verify-then-deduct), not just inputs[0]
- `MetalOutputIDs` HashSet removed entirely — `requiredFacility == Smelter` is the only filter
- Canon doc updated: `economy_alchemy_tech_tree.md` §Tier 2 now lists the minting step + all alloys with ingot inputs

## Open items / next session

### Container color tinting (carry-over)
Storage yard accent-band color = dominant contents category (Yellow=raw, Blue=refined, Red=explosive, Cyan=coolant, etc). Color table in the original to_do; needs a `StorageYardColorTinter` component on each yard variant. Not started.

### Drone-driven INPUT delivery
Phase C currently deducts inputs INSTANTLY from a nearby crate. Adding a visible drone fly-in for the input crate (analogous to the existing Stock job for output) would close the visual loop. Pattern: extend `BaseDroneFleet` with a `JobKind.SmelterFeed` that mirrors `JobKind.Stock` but targets the smelter interior instead of a `CargoSlotState`.

### `MetalOutputIDs` is a hardcoded set
`SmelterState.cs` has a hand-maintained `HashSet<string>` of metal output IDs (steel, ferro_titanium, etc.). When new metal recipes are authored, that set needs updating. Cleaner: add a `ResourceCategory` enum to `ResourceSchema` (Metal / Polymer / Gas / Ceramic) and filter by `schema.category == Metal`. Lab recipes would gate the same way later.

### Some `Refinery` references remain
Intentionally left untouched:
- `MassHousekeepingMover.cs` — historical migration script, already executed.
- `Smelter_T1_Setup.cs` — legacy from-scratch creator with old `Refining/Refinery_T1.prefab` paths in `const` strings. Won't run by accident (the prefab already exists); update when next touched.
- Other design docs (`pipeline_recipe.md`, `economy_*.md`, `architecture_plan.md`, `ships_*.md`) — mention "Refinery" in broader category contexts. Sweep when each doc is next edited; risky to do all at once because some uses might be intentional category language.

### Editor patcher inventory
All in `Assets/Editor/`. Most are one-shot or idempotent. Keep around — they're how the smelter prefab is maintained.
- `Smelter_T1_AddDualConduitSockets.cs` — rebuild schema sockets[] from current conduit positions
- `Smelter_T1_FlipSocketRotations.cs` — flip socket eulers 180Y (run once after Add)
- `Smelter_T1_AddRefineryState.cs` — adds `SmelterState` + wires door/visuals refs
- `Smelter_T1_AddActiveVisuals.cs` — creates the lights + smoke + hum GameObjects
- `Smelter_T1_RenameAndWireVisuals.cs` — re-collects after manual duplications
- `Smelter_T1_WireDirectDoorOpener.cs` — wires `HangarDoorOpener` to Aaron's door children
- `Smelter_T1_FlipDoorSwings.cs` — flips upper/lower swing signs
- Plus a handful of one-off snap-debugging diagnostics

## Critical files to know about

- **Runtime**: `Assets/Scripts/Macro/SmelterState.cs`, `SmelterActiveVisuals.cs`, `SmelterDoorAnimator.cs` (legacy, unused), `HangarDoorOpener.cs`
- **UI**: `Assets/Scripts/UI/SmelterControlPanel.cs`, `Assets/Scripts/UI/Inventory/CrateInventoryPanel.cs`
- **Schema**: `Assets/GameData/Bases/Modules/T1/Smelter_T1.asset`
- **Prefab**: `Assets/Prefabs/Bases/Industry/Smelter_T1/Smelter_T1.prefab`
- **Recipes**: `Assets/Resources/Schemas/Recipes/*.asset` (filter by `requiredFacility: 0`)
- **Drone job system**: `Assets/Scripts/Macro/BaseDroneFleet.cs` (look at `RequestStockJob` for the export pattern)

## Tested working

- Place a smelter → both conduits' tips serve as snap points, Q/E cycles them.
- Flip a raw-material toggle in the right panel → smelter finds matching crate → deducts → grates light orange-red, smoke streams +X, hum loops.
- Timer counts down; output crate spawns at exit point; drone picks it up and stocks it in nearest empty cargo slot; cycle repeats while toggle is on.

## Known visual gotchas

- Output crate is `Object.Instantiate`'d from the first crate in `CrateInstance.All` as a template (the crate's prefab path isn't known to us). Visually it looks like one of the freighter crates — that's fine but if you want a smelter-specific crate prefab later, swap the template lookup for an Addressables / explicit prefab reference in `SpawnOutputCrate`.
- Lights / smoke / particle scaling: smelter prefab is at 11.877× scale and visuals use `ParticleSystemScalingMode.Local`, so particle sizes are tuned for refinery-local units. If you re-scale the prefab, particles need re-tuning.
