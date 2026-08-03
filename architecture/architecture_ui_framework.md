---
status: draft
phase: "1–2"
last-reviewed: 2026-06-09
tags: [architecture, ui]
supersedes-on-approval: "[[social_menus_ui]]"
---

# UI & Menu System Architecture

> **Status: DRAFT / proposed (2026-06-09).** This is the agreed game plan for rebuilding the global nav bar in UI Toolkit (UXML/USS), unifying every macro menu under one framework, and sequencing the menus that don't exist yet. It becomes `canon` once Aaron signs off — at which point it **supersedes the framework premise of [[social_menus_ui]]** (that doc's per-screen taxonomy is absorbed into §8 below; its "build everything on Michsky Shift uGUI" framing is retired) and corrects the "UI uses Michsky Shift SCI-FI" line in [`../social/social_overview.md`](../social/social_overview.md). See §12.

## 1. Why this doc exists

The macro game is sprouting menus — Smelter, Drone Ops, Storage Yard, Outpost, CY/Facility, base-build dock, fleet roster, inventory inspectors — with more coming (Inventory, Shipyard, Market, Alchemy Lab, Alliance, Chat, Contracts, Dossier…). Today **each panel is a bespoke `MonoBehaviour` that re-invents the same plumbing** (show/hide/toggle, Escape handling, hotkey polling, `PanelSettings` loading, refresh loop). That duplication compounds: every new menu pays the tax again, and the nav bar has no single source of truth for what menus exist.

The fix is **one shared menu framework that the nav bar launches from** — composition, not inheritance. The nav bar does not *own* the menus; it is a **view over a registry** of menus, each of which subclasses one base. Adding a menu becomes "subclass + register once," and its launcher entry, Escape/hotkey wiring, scene-scoping, and theming come for free.

This is the same instinct as the project's [content pipelines](../pipelines/pipelines_overview.md): one schema, one base, auto-discovery, UI reads the catalog. We are applying it to menus themselves.

## 2. The three UI layers (the core mental model)

UI in Apex Outlaw splits into **three layers**. They are *not* unified into one — conflating them is the mistake this doc exists to prevent.

| Layer | What it is | Examples | Lives under the nav bar? |
|---|---|---|---|
| **Launcher** | The persistent global nav bar. A *view* over the menu registry. | `GlobalNavBar` (rebuild target) | It **is** the launcher |
| **Menus** | On-demand panels the player opens, works in, and closes. | Smelter, Drone Ops, Inventory, Shipyard, Market, Alchemy Lab, Alliance, Chat | **Yes — unified here** |
| **HUD** | Always-on ambient overlays. Non-interactive or lightly so, low sort order, `picking-mode: Ignore`. Never "opened." | `SurfaceCompassHUD`, `SurfaceMinimapHUD`, `DroneStatusHUD`, the Helion clock | **No — separate system** |

> **Rule: the nav bar is a launcher, not a parent.** Menus register *into* a registry the nav bar reads; the nav bar holds no menu logic. Making every menu a child of the nav bar produces a god-object that owns travel, drones, facilities, and HUDs all at once — the opposite of maintainable. A HUD is not a menu; the compass and minimap stay out of the launcher entirely. **Chat is the one deliberate hybrid** — see §7.

## 3. Current state (2026-06-09) — honest inventory

**Closest thing to a nav bar today:** `MenuHub` + `ThemedMenu` (`Assets/Scripts/UI/Theme/MenuHub.cs`, `ThemedMenu.cs`) — a right-edge collapsible **chip stack** built on uGUI (`Canvas` / `RectTransform` / `ScreenSpaceOverlay`). Menus self-register into it via `OnEnable`, and `SceneMenuRegistry` (`Assets/Scripts/UI/Theme/SceneMenuRegistry.cs`) declares which menus exist per scene. This is the **rebuild target** — the self-registration pattern is right; the uGUI chrome and chip-stack form get replaced (§5.3).

**Already on UI Toolkit (the good pattern to generalize):**
- `SmelterControlPanel` (`Assets/Scripts/UI/SmelterControlPanel.cs`) — the reference panel; loads UXML from `Resources/UI/Smelter/Smelter.uxml` + `Smelter.uss`.
- `DroneOperationsPanel`, `StorageYardControlPanel`, `OutpostControlPanel`, `FacilityControlPanel` — programmatic UI Toolkit (no UXML yet).
- All five share `Assets/Resources/UI/SharedRuntimePanelSettings.asset` and the `FacilityPriorityControl` widget. `ThemePalette` (`Assets/Scripts/UI/Theme/ThemePalette.cs`) centralizes color/font.

**Still legacy uGUI (migration debt):** `BaseBuildPanel`, `FleetRosterHUD`, `DroneStatusHUD`, the crate/part inspect panels.

**The actual pain — duplicated per panel, no shared base:** `Show()/Hide()/Toggle()`, `Esc`-to-close, hotkey polling in `Update()`, `Resources.Load<PanelSettings>(...)`, and the refresh loop. There is **no `GameMenuBase`**. That is the gap §5 fills.

## 4. What "convert everything to USS" actually means

Two distinct jobs, often conflated:
1. **Kill uGUI** — migrate the legacy `Canvas`/`TMP` panels (BaseBuildPanel, FleetRoster, inspectors, DroneStatusHUD) to UI Toolkit. This is the bigger lift and happens **per menu, as that menu's vertical slice comes up** (§9) — not in a big-bang.
2. **Author in UXML+USS, not programmatic C#** — the four programmatic UI-Toolkit panels build `VisualElement`s in code; standardize on UXML structure + USS styling like Smelter already does. This is consistency cleanup, done as each panel moves onto `GameMenuBase`.

## 5. The target framework

### 5.1 `GameMenuBase` — the shared menu base

A thin `MonoBehaviour` (or abstract component) every menu subclasses. It **owns the plumbing that's currently copy-pasted**:

- `UIDocument` + `SharedRuntimePanelSettings` wiring (one place, not N).
- `Show()` / `Hide()` / `Toggle()` / `IsOpen`, with an `OnOpened` / `OnClosed` event pair.
- Standard **Escape-to-close** and optional **hotkey** (declared in `MenuMeta`, dispatched centrally — no per-panel `Update()` polling).
- A `BuildUI()` hook the subclass implements (loads its UXML, queries elements, wires callbacks).
- A `Refresh()` hook + opt-in polling cadence (panels currently hand-roll 0.5 s loops).
- Reads its `MenuMeta` for id/title/icon/scene-scope so the registry and nav bar stay data-driven.

Migration target order: Smelter (reference) → the other four UI-Toolkit panels → uGUI panels as their slices land.

### 5.2 `MenuRegistry` + `MenuMeta` — the one source of truth

`MenuRegistry` is the single catalog of all menus. Each menu carries a `MenuMeta`:

| Field | Purpose |
|---|---|
| `id` | Stable string key (e.g. `"smelter"`, `"inventory"`). |
| `title`, `icon` | Display in the nav bar. Icons from `Assets/Art_Assets/Sci-Fi icons/PNG/grey/`. |
| `category` | Nav-bar grouping (§8): Operations / Fleet & Ships / Commerce / Research / Social / System. |
| `scenes` | Which scenes it appears in — `Solar` / `LowOrbit` / `Surface` / `Global` (§6). |
| `hotkey` | Optional toggle key, dispatched by the framework. |
| `backendFeature` | Which PlayFab/Photon system it depends on (§9) — drives the "is the live path ready?" gate. |

Registration extends today's self-registration: a `GameMenuBase` registers its `MenuMeta` on enable. The nav bar **never hard-codes a menu list** — it renders whatever is registered and in-scope. This is what makes alliance/chat/contracts/etc. drop-ins.

### 5.3 The nav bar as a *view* — `GlobalNavBar`

Rebuilt in **UXML/USS**, `GlobalNavBar` is a pure view over `MenuRegistry`:
- Reads registered `MenuMeta`, filters by current scene (§6), groups by `category`, builds a launcher entry per menu.
- Clicking an entry calls `GameMenuBase.Toggle()` on that menu. That's the entire coupling.
- Carries the **identity cluster** (commander name/portrait, credits, faction standing, notification bell) — the persistent "who am I" strip from [[social_menus_ui]] §2.

It replaces `MenuHub`/`ThemedMenu`'s uGUI chip stack. `ThemedMenu`'s per-menu chrome (title bar, close X, scroll body) is absorbed into `GameMenuBase` + a shared USS panel skin.

> **Open decision (Aaron):** the *visual form* of the launcher — persistent **top bar** with category fly-outs (genre-standard, matches [[social_menus_ui]]), a **left sidebar** hub, or a reworked version of the current **right-edge chip stack**. The architecture (registry-driven, USS, scene-filtered) is identical regardless; this is cosmetic and iterable. Recommended default: top identity bar + category-grouped launcher.

### 5.4 Shared USS theme

`ThemePalette` becomes the source for **USS custom properties** (`--ao-color-*`, font assets) consumed by every menu's USS, plus the shared `SharedRuntimePanelSettings`. One palette edit re-skins every menu. Aligns with the project rule: **new UI = UXML + USS + shared PanelSettings**, never bespoke uGUI.

## 6. Scene-scoping (the three-scene model)

Per the [three-scene world model](./architecture_overview.md#the-three-scene-world-model-phase-69--canon-as-of-2026-05-29), different scenes surface different menus. `MenuMeta.scenes` declares context; `GlobalNavBar` filters on scene load:
- **Solar (S1):** Route/Jump planner, Fleet, Commerce, Research, Social, System.
- **Low Orbit (S2):** Fleet, orbital-structure control, Social, System.
- **Surface (S3):** Operations (base build, Smelter, Storage, Outpost, CY, Drone Ops) + Social/System.
- **Global:** Profile, Settings, Inventory, Chat, Notifications — everywhere.

This centralizes what `SceneMenuRegistry` scatters today: scene membership becomes one field on the menu's meta, not a per-scene component list.

## 7. The HUD layer (explicitly out of the menu system)

HUDs are a separate concern and **do not register with `MenuRegistry`**. They are always-on overlays at low sort order with `picking-mode: Ignore`: `SurfaceCompassHUD`, `SurfaceMinimapHUD` (`Assets/Scripts/Macro/`), `DroneStatusHUD`, the Helion clock/calendar HUD. They may get a lightweight `HudRegistry` later for show/hide toggles, but that is a different system on a different layer.

> **Chat is the deliberate hybrid.** Functionally it is a persistent **docked strip** (HUD-like — always visible, channel tabs) that **expands into a full menu view** (registered in the nav bar under Social). Design it with both faces from the start: a minimized HUD presence + a `GameMenuBase` full view sharing one channel/data backend (Photon Chat). Retrofitting this later is painful.

## 8. The menu master plan (catalog)

Every macro menu, modernized from [[social_menus_ui]] onto this framework. **Status:** ✅ exists on UI Toolkit · 🟡 exists on legacy uGUI (migrate) · ⬜ not built. Per-screen interior detail (fitting-room analytics, autopsy modals, etc.) still lives in [[social_menus_ui]] until migrated here.

| Category | Menu | Scenes | Backend feature it needs | Status |
|---|---|---|---|---|
| **System** | Profile / Service Record / Titles | Global | PlayFab profile + [progression](../progression/progression_overview.md) | ⬜ |
| **System** | Settings / Options | Global | local | ⬜ |
| **System** | Notification Center | Global | PlayFab event feed | ⬜ |
| **Operations** | Base Build dock | Surface | local sim ([ground base](../ground_base/ground_base_overview.md)) | 🟡 `BaseBuildPanel` |
| **Operations** | Smelter | Surface | local sim | ✅ |
| **Operations** | Storage Yard | Surface | local sim | ✅ |
| **Operations** | Outpost Control | Surface | local sim | ✅ |
| **Operations** | Construction Yard / Facility | Surface | local sim | ✅ |
| **Operations** | Drone Operations | Surface | local sim | ✅ |
| **Fleet & Ships** | Fleet Management / Loadouts | Global | PlayFab fleet roster ([`ships_fleet_management.md`](../ships/ships_fleet_management.md)) | 🟡 `FleetRosterHUD` |
| **Fleet & Ships** | Shipyard / Fitting Room | Docked | PlayFab ship catalog + inventory | ⬜ |
| **Fleet & Ships** | Ship Builder (chassis+parts) | Docked | Phase 6.5+ ([part schema](../ships/ships_overview.md)) | ⬜ future |
| **Commerce** | Inventory / Cargo Hold | Global | PlayFab inventory | 🟡 inspect panels |
| **Commerce** | Market / Trade Terminal (DOM) | Docked | [economy exchange](../economy/economy_exchange_pricing.md) CloudScript | ⬜ |
| **Commerce** | Contracts Board | Docked | [freight contracts](../economy/economy_freight_contracts.md) | ⬜ |
| **Research** | Alchemy Lab (Scanner / Ledger / Crucible) | Docked | [12,345 matrix](../economy/economy_overview.md) backend | ⬜ |
| **Research** | Dossier / Infamy | Global | [progression](../progression/progression_overview.md) backend | ⬜ |
| **Research** | Department of War (R&D) | Docked | weapons/military R&D | ⬜ future |
| **Social** | Chat Terminal (hybrid §7) | Global | Photon Chat | ⬜ |
| **Social** | Alliance / Guild | Global | [alliance backend](../social/social_alliance_guild.md) (`ownerId`) | ⬜ Phase 5/5.5 |
| **Social** | Friends / Party | Global | PlayFab + Photon | ⬜ |
| **Navigation** | Route / Jump Planner | Solar | PlayFab jump network | ⬜ |

**Out of scope of the nav bar:** in-event combat UI (Tactical Arena HUD, Scavenger/Autopsy) lives in the **Fusion event layer**, not the macro menu system — see [`../combat/combat_overview.md`](../combat/combat_overview.md). The sector/system **map is a scene**, not a menu; only the Jump Planner is a menu.

## 9. Backend-pairing rule + sequencing

> **A menu is the front-end of a backend feature.** Inventory UI is a view over the inventory backend; Market UI over the economy CloudScript. Building all menus *before* their backends exist forces every one to stub fake data — which is exactly the scene-baked/stub anti-pattern [the live-data rule](./architecture_plan.md) forbids. We would be manufacturing N future migrations.

So the unit of work is **not** "all menus, then all backend." It is:

- **The framework is backend-independent** → build it 100% now (§5: `GlobalNavBar`, `GameMenuBase`, `MenuRegistry`, shared USS theme). No stubbing risk. *(Roadmap Phase 1–2 — UI infrastructure.)*
- **The backend foundation** → PlayFab data structs + CloudScript for the core loop (inventory, fleet, economy), per [`architecture_data_schemas.md`](./architecture_data_schemas.md) + [`architecture_backend_network.md`](./architecture_backend_network.md). *(Roadmap Phase 1 — this is the "build the backend now" instinct, and it's correct.)*
- **Each menu is a vertical slice** → schema → CloudScript → the menu that shows it, built together and registered into the nav bar as it lands. uGUI rewrites happen here, per slice.

The five Surface facility panels are the exception that can migrate onto `GameMenuBase` immediately — they already read live local sim state, so there is no stub risk.

## 10. Authoring a new menu (the pipeline)

Once the framework exists, every future menu — Alliance, Chat, Contracts, Dossier, any new one — is the same six steps:

1. **Define `MenuMeta`** — id, title, icon, category, `scenes[]`, optional hotkey, `backendFeature`.
2. **Subclass `GameMenuBase`** — implement `BuildUI()` and `Refresh()`. Inherit show/hide/Escape/hotkey/PanelSettings for free.
3. **Author UXML + USS** under `Assets/Resources/UI/<Menu>/` — structure in UXML, style via the shared USS theme.
4. **Register** the `MenuMeta` (self-registers on enable). It now appears in the nav bar, scene-filtered, no nav-bar edits.
5. **Wire to the live backend** for `backendFeature`. If the live path isn't ready, add `// BRIDGE: remove when <X> lands` + a `master_to_do.md` entry — never silent-stub.
6. **Verify** in each in-scope scene.

If a menu can't be wired to live data yet, **defer it** rather than ship a hollow shell.

## 11. Hard rules — UI

- **The nav bar is a launcher, not a parent.** Menu logic never lives in `GlobalNavBar`; menus register into `MenuRegistry`. (§2)
- **HUD ≠ menu.** Compass/minimap/drone-status/clock stay out of the launcher. Chat is the only sanctioned hybrid. (§7)
- **New UI = UXML + USS + shared `PanelSettings`.** No new uGUI `Canvas`/`TMP` menus; no Michsky Shift `MainPanelManager` (retired premise — §12).
- **No hollow menus.** A menu ships wired to live data or with a tracked `// BRIDGE`. No stubbed/fake data sitting in a menu "until the backend catches up." (§9)
- **One palette, one PanelSettings.** Theme via `ThemePalette` → USS custom properties + `SharedRuntimePanelSettings`. No per-menu hardcoded colors.
- **Scene-scope is data, not code branches.** Declare `MenuMeta.scenes`; let `GlobalNavBar` filter. Don't hand-gate menu visibility per scene.

## 12. Supersession & open decisions

**On approval, this doc supersedes (via `doc-sync`):**
- **[[social_menus_ui]]** — its *framework premise* ("definitive blueprint for Michsky Shift integration", `MainPanelManager`/`ModalWindowManager`) is retired. Its **per-screen taxonomy is absorbed into §8** and should migrate here over time; the legacy doc gets `status: superseded` + `superseded-by: [[architecture_ui_framework]]` and keeps the per-screen interior detail as a reference until migrated. It also carries **stale lore** ("Mars", "Federation/Mars/Pirate factions") to fix to FED/ICE/Outlaws during reconciliation.
- **[`../social/social_overview.md`](../social/social_overview.md)** — the "UI uses Michsky Shift SCI-FI … tab-based hierarchy" and `GlobalHUD` lines need correcting to the UI Toolkit/USS + `GlobalNavBar` model.

**Open decisions for Aaron:**
1. **Launcher visual form** — top bar (recommended) vs left sidebar vs reworked chip stack (§5.3).
2. **Build start point after this doc** — framework first (recommended) vs backend foundation first (§9).
3. **Chat docking** — confirm the hybrid HUD-strip + full-view model (§7).

## Cross-links
- [`architecture_overview.md`](./architecture_overview.md) — hybrid runtime, three-scene model.
- [`architecture_data_schemas.md`](./architecture_data_schemas.md), [`architecture_backend_network.md`](./architecture_backend_network.md) — where menu backends are defined.
- [[social_menus_ui]] — legacy per-screen taxonomy (being absorbed/superseded).
- [`../pipelines/pipelines_overview.md`](../pipelines/pipelines_overview.md) — the schema-driven pipeline pattern this mirrors.
- [`../meta/master_to_do.md`](../meta/master_to_do.md) — build tracking + bridge-code registry.
