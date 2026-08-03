# Base Part Pipeline

Canonical authoring pipeline for **base parts**: chassis, connectors, modules, and armor. The reference shape for all schema-driven pipelines in this project — see [`pipelines_overview.md`](pipelines_overview.md) for the cross-cutting pattern.

**Scope:** every player-buildable structure on a base (Outpost chassis, Construction Yard, conduits, armor plates, future modules and chassis tiers). Excludes ships, weapons, recipes, and other content types (see their per-pipeline docs).

---

## 1. The Four Schema Families

| Schema | Role | Example | Storage |
|---|---|---|---|
| [`BaseChassisSchema`](../../Assets/Scripts/Schemas/BaseChassisSchema.cs) | Foundation structure the player drops first on a plot. Provides baseline power / inventory / beds and exposes sockets where modules + connectors plug in. | Outpost Starter, HQ Module, future T2 HQ | `Assets/GameData/Bases/Chassis/` |
| [`BaseConnectorSchema`](../../Assets/Scripts/Schemas/BaseConnectorSchema.cs) | Structural connector — hallways, junctions, ring segments. Pure skeleton (no power draw, no crew); routes the snap graph between chassis and modules. | `Conduit_Straight`, `Conduit_Small_Straight` | `Assets/GameData/Bases/Connectors/` |
| [`FacilityModuleSchema`](../../Assets/Scripts/Schemas/FacilityModuleSchema.cs) | Installable module — reactors, shipyards, labs, storage, docking, defense, intel. Plugs into chassis sockets or connector endpoints. | `Construction_Yard_T1`, `Fusion_Reactor_T1`, `Bunk_Pod_T1` | `Assets/GameData/Bases/Modules/T<n>/` |
| [`ArmorSchema`](../../Assets/Scripts/Schemas/ArmorSchema.cs) | Armor plate that clamps to a conduit (or future: module face). HP-bearing, repairable, individually destructible per-panel. | `ConduitArmorWall_01` | `Assets/GameData/Armor/` |

**Picking a schema for new content:**
- Player drops it first on a fresh plot? → Chassis
- Pure skeleton, plugs into a chassis socket, exposes more sockets? → Connector
- Provides a gameplay capability (refining, docking, sensors, etc.)? → Module
- Mounts to the outside of a conduit/module for HP absorption? → Armor

---

## 2. Schema Field Reference

All four base schemas share the same authoring vocabulary. Per-family extensions are noted.

### Identity (all)
| Field | Notes |
|---|---|
| `<X>ID` / `itemID` | Stable string ID (e.g. `chassis_outpost_starter`). Used as DB key. |
| `displayName` | Player-facing name. |
| `description` | Tooltip / inspect-panel text. |
| `icon` (Armor only) | 2D sprite for inventory grids. |

### Visual + placement (all)
| Field | Notes |
|---|---|
| `prefabAddress` / `shellPrefabAddress` | AssetDatabase path (BRIDGE) / Addressables key (target). |
| `placementScale` | Uniform scale multiplier at instantiation. 1.0 = vendor prefab scale. |
| `snapTipOffsetLocalX` (Armor only) | Tripod-tip offset from prefab origin to the clamp face. |
| `embedDepth` (Armor only) | Inward sink past the conduit surface for "hugged" feel. |
| `alongConduitLength` (Armor only) | Grid spacing for side-by-side snap. |

### Categorization (all)
| Field | Notes |
|---|---|
| `category` (Module only) | `BaseModuleCategory` enum — Docking / Industry / Power / Defense / Intel / Lab / Habitat / Cosmetic. Drives tab assignment. |
| `menuPlacement` | `MenuPlacement` enum — `Main` / `Misc` / `Upgrade`. Drives whether the card shows in the Main tab, the Misc tab, or only inside an inspect-panel upgrade picker. |
| `facilityType` (Module only) | Recipe-family gate (None / Smelter / Lab / Shipyard / etc.). Compared against RecipeSchema.facilityType. |
| `tier` (Module only) | 1-5. Recipes compare against MAX tier across installed modules of same facilityType. |

### Economics (Module only)
| Field | Notes |
|---|---|
| `powerDraw` / `powerProvided` | Net base power balance. |
| `inventoryCapacity` | Adds to base's inventory cap (storage modules). |
| `bedsProvided` / `foodProduced` / `crewRequired` | Population / habitat balance (loose gate). |
| `dockBayShipClassIds` | Ship classes this module can host (Docking modules only). |

### Build (all)
| Field | Notes |
|---|---|
| `buildTimeSeconds` | Drone-delivery duration. Default 60s; armor 12s; tune per part. |
| `buildCost` | `List<RecipeInput>` — materials drawn from base storage at placement. Validated server-side. |

### Tech tree (all, enforced in Phase 6.10.C)
| Field | Notes |
|---|---|
| `prereqModuleIds` | Player must have built at least one of each before this card unlocks. |
| `prereqSameCategoryAtPrevTier` (Module only) | T(N+1) requires this many T(N) modules in the same category. Default 2. |
| `upgradeOf` | If non-null, this part is an upgrade of the referenced part (drives inspect-panel addon picker). |

### Slot fit
| Field | Notes |
|---|---|
| `requiredSocketKind` (Module only) | `SocketKind` enum — Small / Medium / Large / Capital. |
| `sockets` (Chassis + Module) | Explicit socket list — overrides the default one-socket-at-origin behavior. |
| `endpoints` (Connector only) | Where modules / sub-connectors attach. Index 0 is the input. |

### Destruction (per-piece, see § 5)
Per-piece destruction lives on the **prefab children**, not the schema. The setup script attaches the components.

---

## 3. Folder Layout

```
Assets/GameData/
├── Bases/
│   ├── Chassis/          ← BaseChassisSchema assets
│   │   ├── Outpost_Starter.asset
│   │   └── HQ_T1.asset
│   ├── Connectors/       ← BaseConnectorSchema assets
│   │   ├── Conduit_Straight.asset
│   │   └── Conduit_Small_Straight.asset
│   └── Modules/
│       ├── T1/           ← FacilityModuleSchema, tier 1
│       │   ├── Construction_Yard_T1.asset
│       │   └── …
│       └── T2/           ← FacilityModuleSchema, tier 2 (future)
└── Armor/                ← ArmorSchema assets
    └── ConduitArmorWall_01.asset

Assets/Prefabs/Bases/
├── Chassis/<ChassisName>/<ChassisName>.prefab
├── Connectors/<ConnectorName>/<ConnectorName>.prefab
├── Modules/<ModuleName>/<ModuleName>.prefab
└── Armor/<ArmorName>/
    ├── <ArmorName>.fbx
    ├── <ArmorName>.prefab
    └── Materials/{Iron,CarbonBlack,…}.mat

Assets/Editor/
└── <PartName>_Setup.cs   ← one per asset family (re-runnable [MenuItem])
```

> **Pending move (open question).** Armor currently lives at `Assets/Prefabs/Modules/Armor/` rather than `Assets/Prefabs/Bases/Armor/`. Aaron flagged the inconsistency 2026-05-23. Move when convenient; update `ArmorSchema.prefabAddress` + the setup script path in one pass.

---

## 4. Setup Script Template

Every new part gets one setup script under `Assets/Editor/`. Use the shared [`BasePartSetupHelpers`](../../Assets/Editor/BasePartSetupHelpers.cs) class — it owns FBX import config, material creation, prefab building, per-child destruction, schema creation. The per-part script is then thin.

**Template** (replace `<PartName>` and tune values):

```csharp
using UnityEditor;
using UnityEngine;
using ApexOutlaw.Schemas;

public static class <PartName>_Setup
{
    [MenuItem("Apex Outlaw/Setup/<PartName>")]
    public static void Execute()
    {
        const string fbxPath    = "Assets/Prefabs/Bases/<Category>/<PartName>/<PartName>.fbx";
        const string prefabPath = "Assets/Prefabs/Bases/<Category>/<PartName>/<PartName>.prefab";
        const string schemaPath = "Assets/GameData/Bases/<Category>/<PartName>.asset";

        BasePartSetupHelpers.ConfigureFBXImporter(fbxPath);

        var ironMat   = BasePartSetupHelpers.LoadOrCreateLitMaterial(
            "Assets/Prefabs/Bases/<Category>/<PartName>/Materials/Iron.mat",
            new Color(0.22f, 0.22f, 0.24f, 1f), metallic: 0.85f, smoothness: 0.45f);
        var carbonMat = BasePartSetupHelpers.LoadOrCreateLitMaterial(
            "Assets/Prefabs/Bases/<Category>/<PartName>/Materials/CarbonBlack.mat",
            new Color(0.04f, 0.04f, 0.04f, 1f), metallic: 0.0f, smoothness: 0.10f);

        BasePartSetupHelpers.BuildPrefabFromFBX(fbxPath, prefabPath, instance =>
        {
            // Assign materials per child.
            BasePartSetupHelpers.AssignMaterial(instance, "Beam_Top",   ironMat);
            BasePartSetupHelpers.AssignMaterial(instance, "Panel_Top",  carbonMat);
            // …

            // Per-piece destruction (only the pieces that should break off in combat).
            BasePartSetupHelpers.MakeChildBreakable(instance, "Panel_Top",
                hp: 200f, force: 5f, radius: 2f, upMod: 1.2f, linger: 4f, mass: 25f);
            // …
        });

        // Schema: create or refresh in place. Pass a configure callback so the
        // helper handles dirty-mark + save.
        BasePartSetupHelpers.LoadOrCreateSchema<ArmorSchema>(schemaPath, s =>
        {
            s.itemID            = "<part_id>";
            s.displayName       = "<Player-Facing Name>";
            s.description       = "<Tooltip text>";
            s.prefabAddress     = prefabPath;
            s.menuPlacement     = MenuPlacement.Upgrade;  // or .Main, .Misc
            // … schema-specific fields …
        });

        Debug.Log($"[<PartName>] Setup complete.");
    }
}
```

**The setup script's job:**
1. Configure the FBX importer (scale, materials, etc.)
2. Create / refresh the URP materials
3. Build the prefab from the FBX, applying per-child material + destruction
4. Create / refresh the schema asset with the authored field values
5. Log success

**What the script does NOT do:**
- Place anything in a scene
- Modify other prefabs or schemas
- Touch settings or hooks outside this part

---

## 5. Per-Piece Destruction

Each prefab child that should be **independently destroyable** gets three components, baked at setup time:

| Component | Purpose |
|---|---|
| `Collider` (Box / Mesh) | Receives combat hits, sized to the child's mesh bounds. |
| `Rigidbody` (kinematic, no gravity) | Stays attached at idle; freed by `BasePartBreakable.Shatter()` to fly off. |
| [`BasePartBreakable`](../../Assets/Scripts/Macro/BasePartBreakable.cs) | Holds HP. On `TakeDamage` hits 0, calls `Shatter()` — flips its Rigidbody non-kinematic, applies explosion impulse, destroys after `lingerSeconds`. |

**Granularity guidance:**
- **Conduit / chassis** — root has a single `BasePartBreakable` (1000 HP). Shatters as a unit when destroyed; all child rigid bodies fly off.
- **Armor** — only the visible **panels** (not the iron frame) are individually breakable. Each panel ~200 HP. Frame stays as cosmetic skeleton when panels are gone; the conduit underneath is then exposed.
- **Module** — root-level breakable for now. Per-sub-system destruction (e.g. reactor core vs. cooling vanes) is a future refinement.

**Combat damage routing** lives in `Tactical/` (Phase 4 combat). Per-piece breakables are *ready* for that hookup — currently `TakeDamage` is only firable via the inspector "Test Shatter" context menu.

---

## 6. Menu Placement

The build panel ([`BaseBuildPanel`](../../Assets/Scripts/UI/BaseBuildPanel.cs)) auto-discovers all four schemas via [`BaseBuildController.LoadCatalogs`](../../Assets/Scripts/Macro/BaseBuildController.cs). Placement in the menu is driven by **schema fields**, not hardcoded lists.

| Schema field value | Where it shows |
|---|---|
| `menuPlacement = Main` | MAIN tab (foundation pieces — currently Outpost + CY) |
| `menuPlacement = Misc` | MISC tab (other chassis, future variants) |
| `menuPlacement = Upgrade` | NOT in any top-level tab — only in the inspect-panel addon picker for the parent (Phase 6.10.G) |
| Module with `category = X` | The matching category tab (Industry / Power / Defense / etc.) — unless `menuPlacement = Main/Upgrade` overrides |
| Connector (any kind) | CONDUITS tab |
| Armor (any kind) | CONDUITS tab today (BRIDGE) — moves to the inspect panel of its host part when Phase 6.10.G lands |

**Tab visibility rules:**
- A tab is BRIGHT when it has at least one buildable card AND the player is past the stage that unlocks it (e.g. Conduits tab is dim until the CY is built).
- A tab is DARK (and click-suppressed) when empty.

---

## 7. Build Pipeline Integration

When the player confirms placement, [`BaseBuildController.PlaceFromGhostTransform`](../../Assets/Scripts/Macro/BaseBuildController.cs) does:

1. Instantiate the prefab under `basePartsRoot` (or, for armor, under the target conduit's transform)
2. Add `BasePartInstance` with the schema reference
3. Add `BasePartBuildTimer` with `buildTimeSeconds` from the schema
4. The build timer:
   - Hides every renderer + replaces materials with the shared blue hologram
   - Each direct child = one "shard"
   - Drone (`BaseDroneFleet`) trips from the CY to deliver each shard
   - On delivery, that shard's renderers re-enable + restore original materials
   - Build timer self-destructs on the final shard

**Free-place vs. snap** is handled by the controller — armor uses its own `TryFindConduitArmorSnap` path (grid-aligned along the conduit length); modules use the side-mount or socket snap path; chassis use the standard snap. All three paths share the same placement commit code.

**Cost validation** (Phase 6.10.D, in flight): `BuildCostValidator` will pre-check `buildCost` against base storage at placement-confirm and red-ghost the placement if insufficient.

**Tech-tree gating** (Phase 6.10.C, in flight): `BaseModuleUnlockResolver` will read `prereqModuleIds` and grey out cards whose prereqs aren't met.

---

## 8. Runtime Consumers (what reads from the schema at runtime)

| Consumer | What it reads | When |
|---|---|---|
| `BaseBuildPanel` | Every field (cards, tooltips, cost display) | UI render |
| `BaseBuildController` | `prefabAddress`, `buildTimeSeconds`, `requiredSocketKind`, sockets/endpoints | Placement |
| `BasePartInstance` | `sockets` / `endpoints` / `requiredSocketKind` | Runtime occupancy tracking |
| `BasePartBuildTimer` | Schema's `buildTimeSeconds` (passed in at placement) | Build sequence |
| `RecipeSchema.RunRecipe` gate | All installed modules' `facilityType` + `tier` (max across base) | Recipe eligibility |
| `BasePartBreakable` (per piece) | Authored at setup time, not read live | Combat (Phase 4) |
| CloudScript `BaseModuleInstall` (Phase 6.10.E) | `buildCost`, `prereqModuleIds` | Server-authoritative placement validation |

---

## 9. Authoring Checklist — Adding a New Base Part

Use this every time. Skipping steps creates the kind of half-finished content this pipeline exists to prevent.

- [ ] **Pick the schema family** (Chassis / Connector / Module / Armor) per § 1's "Picking" rules.
- [ ] **Get the FBX into the right folder** — `Assets/Prefabs/Bases/<Category>/<PartName>/<PartName>.fbx`. If sourced from Blender, check `useFileScale=false, globalScale=1` (the setup helper enforces this).
- [ ] **Decide per-piece destruction** — which children should break off individually in combat? List them; the rest stay as cosmetic skeleton.
- [ ] **Author the materials** you want (or use existing Iron / CarbonBlack if it fits).
- [ ] **Write the setup script** at `Assets/Editor/<PartName>_Setup.cs` from the § 4 template.
- [ ] **Fill in the schema fields** in the script's `LoadOrCreateSchema` callback per § 2's reference. Pay particular attention to:
  - `menuPlacement` (Main / Misc / Upgrade)
  - `buildCost` (use existing `ResourceSchema` assets — don't invent new materials)
  - `prereqModuleIds` (what must exist before this card unlocks)
  - `buildTimeSeconds` (12 for armor, 20-60 for modules, 60+ for chassis)
- [ ] **Run the setup script** from `Apex Outlaw → Setup → <PartName>` menu.
- [ ] **Verify in the editor**:
  - Prefab exists at the expected path
  - Schema asset exists with the right values
  - Materials assigned to the expected children
  - Per-piece breakables present on the destructible children
- [ ] **Play-test placement**:
  - The card appears in the right tab in the build panel
  - The blueprint hologram appears in the right color on placement
  - The drone delivers and reveals piece by piece
  - The build timer dial completes
  - The placed part snaps to the right surface / endpoint
  - If armor: it grid-snaps to the conduit length; multiple pieces butt cleanly
- [ ] **Document if you authored anything new** beyond an instance:
  - New schema field → update § 2's reference table
  - New shared setup-helper move → update `BasePartSetupHelpers` and § 4's template
  - New `category` value, `menuPlacement` value, etc. → update CLAUDE.md / progression_base_building.md

---

## 10. What's Live vs. In Flight

**Live (2026-05-23):**
- All four schema families
- Auto-discovery catalogs in `BaseBuildController`
- Menu placement via tabs + Main/Misc hardcoded lists (being migrated to `menuPlacement` field)
- Snap pipeline (standard, side-mount, armor)
- Blue-hologram + drone-build sequence via `BasePartBuildTimer`
- Per-piece destruction structurally (HP / collider / rigidbody on panels)
- `ConduitArmorWall_01_Setup.cs` as the prototype shared-helper setup script
- This pipeline doc

**In flight (this session — see master_to_do.md Phase 6.10):**
- `menuPlacement` field replacing hardcoded `MainChassisNames` / `MainModuleNames`
- `buildCost` field activated + cost row in build-panel cards
- `prereqModuleIds` field added (display only — resolver lands separately)
- `upgradeOf` field added (consumed by Phase 6.10.G inspect panel)
- `BasePartSetupHelpers` shared editor class
- `ConduitArmorWall_01_Setup` refactored to use the helpers

**Deferred (later phases):**
- `BuildCostValidator` actually checking storage at placement (Phase 6.10.D)
- `BaseModuleUnlockResolver` actually gating placement (Phase 6.10.C)
- CloudScript persistence (Phase 6.10.E)
- `BasePartInspectPanel` (Phase 6.10.G) — the click-to-inspect side panel that consumes `upgradeOf`
- Phase 4 combat hooking into `BasePartBreakable.TakeDamage`
- Armor `BaseArmorPlateSchema` migration (Phase 6.11) — current `ArmorSchema` doubles as a base-builder asset via BRIDGE fields

---

## 11. Bridge Code (per CLAUDE.md "Building durably" rule)

Tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md):

- `ArmorSchema.prefabAddress` / `snapTipOffsetLocalX` / `embedDepth` / `alongConduitLength` / `buildTimeSeconds` — base-builder fields on a hull-armor schema. Remove when Phase 6.11 lands `BaseArmorPlateSchema` and migrates `ConduitArmorWall_01.asset`.
- `BaseBuildController.LoadCatalogs` editor-only `AssetDatabase.FindAssets` — switch to Addressables-label discovery when the project's Addressables pipeline is wired.
- `Assets/Prefabs/Modules/Armor/` location — move to `Assets/Prefabs/Bases/Armor/` for consistency with other base-part folders.
