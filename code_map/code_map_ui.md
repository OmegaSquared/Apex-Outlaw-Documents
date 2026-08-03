---
status: canon
phase: "6.9"
last-reviewed: 2026-06-09
tags: [code-map, ui]
---

# Code Map — UI (`Assets/Scripts/UI/`)

~60 .cs files. The macro-game UI layer. **Mixed-framework**: legacy uGUI (Canvas/TMP), a custom procedural uGUI theme system (ThemedMenu/MenuHub), and newer UI Toolkit (UXML/USS) panels. The framework unification plan is [[architecture_ui_framework]] (DRAFT — proposes UI Toolkit `GameMenuBase` + `MenuRegistry`, retiring the chip-stack chrome). Screen-by-screen design taxonomy: [[social_menus_ui]].

## The three UI sub-systems as implemented

### 1. Persistent Global HUD (uGUI, addressable prefab)
| File | Role |
|---|---|
| `UI/GlobalHUDBootstrap.cs` | `RuntimeInitializeOnLoadMethod` boot: loads `UI/GlobalHUD` addressable prefab, `DontDestroyOnLoad`, hides on Login/Splash, wires Sector Map button → `SectorSceneLoader`. Singleton `Instance`. |
| `UI/DashboardUI.cs` | Top status bar: commander name (clickable → profile), credits, settings gear, inventory toggle (raw text dump). Several nav buttons still `Debug.Log` stubs. Routes profile/settings through `LoginScreenUI`. |
| `UI/GlobalNavHub.cs` | **NEW 2026-06-09.** Persistent section chips (Command Deck, Shipyard, Inventory, Alchemy Lab, Market, Alliance, Social) built on ThemedMenu; installed by GlobalHUDBootstrap; builds only when logged in. Stub panels list planned contents per [[social_menus_ui]] §2. |
| `UI/LoginScreenUI.cs` | Pre-game flow: PlayFab auth, profile, settings; loads `Shipyard` scene on login (line ~598). |
| `UI/FleetRosterHUD.cs`, `UI/DroneStatusHUD.cs` | Always-on overlays (legacy uGUI — migration debt per [[architecture_ui_framework]] §3). |

### 2. Theme system / chip-stack menus (procedural uGUI)
The current de-facto menu framework. **Read `Macro/MacroSyncMenu.cs` as the reference consumer** before building a new menu on it.

| File | Role |
|---|---|
| `UI/Theme/MenuHub.cs` | Singleton bottom-right chip stack on its own `DontDestroyOnLoad` canvas (sort 5000). `EnsureBootstrapped()`, `Register/Unregister(ThemedMenu)`, `RegisterAction(title, icon, cb)` for one-shot action chips. Tears down chips by source-scene name on scene unload. |
| `UI/Theme/ThemedMenu.cs` | Expandable in-stack menu; its RectTransform IS the chip. Self-registers on `OnEnable`. `AddSection()`, `Content`, `ExpandedChanged`. Procedural border/scroll chrome. |
| `UI/Theme/SceneMenuRegistry.cs` | Per-scene manifest component — lists ThemedMenus to activate for that scene. |
| `UI/Theme/ThemePalette.cs` (+ `ThemePaletteBootstrap.cs`) | Central accent color + font; `Changed` event re-themes everything. Target: becomes USS custom properties per [[architecture_ui_framework]] §5.4. |
| `UI/Theme/SceneActionChip.cs`, `UI/Theme/BaseLinkChip.cs` | Action-chip helpers. |

**Gotchas (hard-won):**
- `MenuHub.Unregister` (incl. via `OnDisable`) slide-out-animates **then destroys the menu GameObject**. Hiding = destroying; rebuild procedurally on re-show (GlobalNavHub does this).
- Add `CanvasGroup` explicitly before a ThemedMenu registers — Unity fake-null breaks MenuHub's `GetComponent ?? AddComponent` fallback (see MacroSyncMenu comment).
- Chips created under DontDestroyOnLoad roots persist across scene loads; scene-created chips are torn down by scene-name match on unload.
- `ThemedMenu.title` changes only render after `ApplyTheme()`.

### 3. UI Toolkit panels (the pattern the draft generalizes)
| File | Role |
|---|---|
| `UI/SmelterControlPanel.cs` | **Reference panel** — loads UXML/USS from `Resources/UI/Smelter/`. |
| `UI/DroneOperationsPanel.cs`, `UI/StorageYardControlPanel.cs`, `UI/OutpostControlPanel.cs`, `UI/FacilityControlPanel.cs` | Programmatic UI Toolkit (no UXML yet); share `Resources/UI/SharedRuntimePanelSettings.asset` + `FacilityPriorityControl` widget. |

## Other notable files
| File | Role |
|---|---|
| `UI/ShipyardUI.cs` | Shipyard scene controller; static `IsAdminMode` flag; loads `shipmanagerTestFleet` scene. |
| `UI/SectorSceneLoader.cs` / `UI/SolarSystemSceneLoader.cs` | Additive scene open/close for sector & solar map (`IsActiveOnScreen`, `OpenCurrent()`, `Close()`). |
| `UI/Inventory/` | `InventoryView`, `CrateInventoryPanel`, `InventoryRow`, `RemoteTerminalView` — crate/inventory inspectors (legacy uGUI). |
| `UI/Forge/ForgePanel.cs` + `RecipeRow.cs` | Forge crafting UI. |
| `UI/BaseBuildPanel.cs` | Base building palette (legacy uGUI, migration debt). |
| `UI/ColorCodeParser.cs` | Caret color-code → TMP rich text (shared by dashboard + macro fleet labels). |
| `UI/Crosshair/CrosshairController.cs` | Context-sensitive crosshair from `CrosshairCatalog`. |
| `UI/JumpGateDestinationPopup.cs`, `UI/SolarSystemJumpGateFilterPanel.cs` | Gate UI; the filter panels are the only **Michsky Shift** consumers. |

## Entry points
- Boot: `GlobalHUDBootstrap.InstallOnBoot()` (BeforeSceneLoad) → HUD prefab → `DashboardUI` + `GlobalNavHub`.
- Menus appear via: scene's `SceneMenuRegistry`, self-registering panels (ResourceScannerPanel bootstraps itself), or GlobalNavHub (global chips).
- Login: `MainMenu.unity` → `LoginScreenUI` → Shipyard scene.

## Cross-system touchpoints
- Reads `PlayFabManager.Instance.ActiveProfile` ([[code_map_backend]]) for name/credits/inventory.
- `MacroViewModeController` / `SectorSceneLoader` hand off to the Macro layer ([[code_map_macro]]).
- `GradeSchema.Default.BandFor(grade).shortCode` for grade chips ([[code_map_schemas_editor]]).

## Traps / status
- **Framework drift is the headline:** three frameworks coexist; don't add a fourth. New menus: follow [[architecture_ui_framework]] once canon; until then ThemedMenu is the de-facto pattern for chip menus, UI Toolkit for facility panels.
- `DashboardUI` stub buttons (`returnToBaseBtn`, `fleetCmdBtn`, `sectorRadarBtn`) just log.
- Michsky Shift ui assets exist under Plugins but are nearly unused — [[social_menus_ui]]'s Michsky framing is slated for supersession by [[architecture_ui_framework]].
- Missing vs design doc: notification center, premium currency / wanted-level display, commander portrait binding ([[social_menus_ui]] §2).
