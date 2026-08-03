---
status: canon
phase: "6.9"
last-reviewed: 2026-06-09
tags: [code-map]
---

# Code Map — Support Folders

The small infrastructure folders (~8 runtime files + editor bots). Mostly identity, admin gating, and one-off helpers.

## `Assets/Scripts/Player/` (1 file)
- `LocalPlayer.cs` — local player identity singleton (who am I / ownership checks). Used wherever code asks "is this mine?".

## `Assets/Scripts/Common/` (2 files)
- `FactionId.cs` — faction/owner-ID normalization shim: legacy `"PACT"` → `"FED"` on read, `IsFederation()` helpers. Canon rule: faction IS an alliance, single `ownerId` string (CLAUDE.md).
- `AdminRole.cs` — admin role/permission model.

## `Assets/Scripts/Admin/` (3 files)
- `AdminGate.cs` — gates admin-only functionality.
- `AdminPanel.cs` — runtime admin panel UI.
- `CelestialOrbitSpeed.cs` — admin orbital-speed control (designer preview offset; pairs with `CelestialClock.DesignerOffsetSeconds`, see [[code_map_macro]]).

## `Assets/Scripts/Utilities/` (2 files)
- `DummyTargetDrift.cs` — test-target drift mover.
- `InfiniteBackground.cs` — tiling starfield background.

## `Assets/Help Scripts/Editor/` (~21 files)
Editor automation bots & recovery tools (sibling of `Assets/Editor/` — same idea, older vintage):
- Setup bots: `SetupMenuBot`, `SetupDashboardBot`, `SetupTestSimBot` — scene UI scaffolding (built the original dashboard/menu objects).
- Ship fixers: `FixALLShipOffsets`, `FixShipCollider`, `FixShipOffset`, `HardpointGizmoViewer`, `GenerateFreighter`, `ThrusterDiagnoser`, `DebugThrusterBot`.
- Material recovery: `PinkMaterialDiagnoser(+Scene)`, `PinkMaterialRecoveryTool`, `PinkSceneMaterialFixer`, `ForgeURPMaterialFixer` — URP pink-material triage suite.
- Misc: `ForgeRunner` (MCP/CLI entry point), `ForceFusionTableRebuild`, `SplitSceneArchitecture`, forge smoke/turret recovery tools.

## Traps
- BRIDGEs noted here: PlayFab-auth promotion of local identity (`LocalPlayer`), PlayerPrefs → PlayFab persistence, Addressables migration in helper loads.
- Help Scripts bots predate the schema pipeline — prefer `Assets/Editor/` `*_Setup.cs` patterns ([[code_map_schemas_editor]]) for new tooling.
