---
status: canon
phase: "6.9"
last-reviewed: 2026-06-09
tags: [code-map]
---

# Code Map — Overview & Index

This category maps the **C# codebase** (`Assets/Scripts/`, `Assets/Editor/`, `cloudscript/`) the way the other ten categories map the design. Design docs say what the game *should be*; the code map says **where it actually lives**: key files, entry points, singletons, cross-system handoffs, and legacy traps. Its job is to make any agent or human productive in an unfamiliar system in one read — no exploratory grepping.

**These docs describe the code as-is.** When a code map disagrees with the build, the code map is stale — fix it (bump `last-reviewed`), don't trust it over the compiler. Reconcile on touch via the `doc-sync` skill like every other doc.

## The maps

| Map | Covers | Folder(s) |
|---|---|---|
| [[code_map_ui]] | Macro-game UI: HUD, menus, panels, theme system | `Assets/Scripts/UI/` |
| [[code_map_macro]] | Strategic layer: sectors, fleets, celestial orbits, jump gates, FOW, surface bases | `Assets/Scripts/Macro/` |
| [[code_map_tactical]] | Micro-game combat: Photon Fusion event instances + DOTS visual subsystem | `Assets/Scripts/Tactical/`, `Assets/Scripts/ECS/` |
| [[code_map_backend]] | PlayFab auth/profile/CloudScript, FleetSnapshot bridge | `Assets/Scripts/Networking/`, `cloudscript/` |
| [[code_map_schemas_editor]] | Schema-driven content pipeline code: ScriptableObjects, catalogs, one-shot bakers | `Assets/Scripts/Schemas/`, `Assets/Editor/`, `Assets/GameData/` |
| [[code_map_support]] | Small support folders: player identity, admin, shared helpers, editor bots | `Assets/Scripts/{Player,Common,Utilities,Admin}/`, `Assets/Help Scripts/` |

## How to use (agent workflow)

1. **Starting work in a system?** Read its map first — it names the entry points, the singletons, and the trap list.
2. **Map says X, code says Y?** Code wins. Update the map in the same task.
3. **Adding a significant file/system?** Add a row to the relevant map's key-files table while the context is fresh.
4. Design intent still lives in the design categories — the map links to the canonical design doc per system; read both for anything non-trivial.

## Codebase shape at a glance (2026-06-09)

| Folder | ~.cs files | One-liner |
|---|---|---|
| `Assets/Scripts/Macro/` | 211 | The bulk of the game — PlayFab-backed strategic layer |
| `Assets/Editor/` | 336 | One-shot bakers, scene patchers, diagnostics (pipeline stage 2 tooling) |
| `Assets/Scripts/Schemas/` | 69 | ScriptableObject schemas + catalog loaders (source of truth for data) |
| `Assets/Scripts/UI/` | 60 | Macro UI — mixed uGUI / UI Toolkit (see [[code_map_ui]] § migration) |
| `Assets/Scripts/Tactical/` | 29 | Fusion combat instances (beta-functional) |
| `Assets/Scripts/Networking/` | 7 | PlayFabManager + clients |
| `cloudscript/` | 9 (.js) | Server-authoritative handlers |
| `Assets/Scripts/ECS/` | 1 | Damage accumulation → GPU arrays only |
| Support folders | ~8 | [[code_map_support]] |

Related canon: [`architecture/architecture_plan.md`](../architecture/architecture_plan.md) §3.0 (What Runs Where) for the *intended* layering; this category for the *implemented* reality.
