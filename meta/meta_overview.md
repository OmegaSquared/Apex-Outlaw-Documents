# Meta — Category Overview

The meta category holds the **process docs**: what gets built when (roadmap), what's actively in flight (todo list), and shared style/reference material. Nothing in here changes game design — it's how the project tracks itself.

## Docs in this category

| Doc | Purpose |
|---|---|
| [`meta_roadmap.md`](./meta_roadmap.md) | High-level development phases (0 → 6+) with the goal of each phase. The compass. |
| [`master_to_do.md`](./master_to_do.md) | Granular checklist of work items, organized in **likely build order** to reach a ready game. The map. |
| [`meta_colortext.md`](./meta_colortext.md) | Faction color palette and text styling reference. |
| [`meta_hotkeys.md`](./meta_hotkeys.md) | Living list of every keyboard / mouse binding across scenes (camera, build, drone, tactical). |

## How to use roadmap vs. todo

- **Roadmap = phases.** When asking "are we ready for combat work yet?" — that's a roadmap question.
- **Todo = tasks.** When asking "what's the next thing I should work on?" — that's a todo question.

The todo list is the source of truth for active work. The roadmap is the framing.

## Bridge code rule (canon)
Per [`../../CLAUDE.md`](../../CLAUDE.md) "Building durably — no throwaway code", every temporary scaffold must be **comment-flagged** in code with `// BRIDGE: remove when <X> lands`, **listed** in [`master_to_do.md`](./master_to_do.md) under a "Bridge code to remove" subsection, and **time-boxed** to the phase that obviates it. No indefinite scaffolds, no piles of half-finished features.
