---
status: draft
canon: false
last-reviewed: 2026-06-12
tags: [lore, index]
---

# Lore — NON-CANON narrative vault

This folder holds **world-fiction**: backstory, faction history, the in-universe justification
for mechanics, art/narrative direction, and the project's proper-noun naming. It was split out
of the design docs on 2026-06-12 because **the lore is still up in the air and is not canonized**,
while the game mechanics are. Keeping them apart means we can rewrite the story freely without
churning the mechanics docs.

## The rule

- **Mechanics docs (`combat/`, `economy/`, `ships/`, `world/`, `progression/`, `social/`,
  `pipelines/`, `architecture/`, `ground_base/` …) are canon.** They describe *how the game works*
  and they mirror the code.
- **Everything in `lore/` is `status: draft`, `canon: false`.** It describes *the fiction wrapped
  around* those mechanics. Treat nothing here as locked.
- A mechanics doc may **reference** lore (e.g. a one-line "in-universe framing" pointer to a file
  here), but its mechanics must never **depend** on the lore being true. If the lore changes, no
  mechanics doc should need to change.

## Names are NOT genericized — and why

The proper nouns (**Helion**, **FED**, **ICE**, **Concordia**, **Ferrum**, **Vesperion**,
**Alythar**, **Discordia**, the faction tags) are deliberately **left in the mechanics docs**,
because they are **baked into the code as identifiers** — e.g. `FactionId.cs` (`"FED"`/`"ICE"`/
`"Outlaw"`), the `Helion*` macro scripts (`HelionCalendar`, `HelionCameraController`, …), and
scene/registry entities named `Vesperion` / `Alythar`. Genericizing them in docs would desync the
docs from the build and break the "docs mirror code" rule.

So: **the names live in two layers.**

- As **mechanical identifiers** (faction IDs, scene names, class names) they stay in the mechanics
  docs and the code — that is their canonical, stable form.
- As **fiction** (what `Concordia` *is*, why `ICE` exists, what `Quantum Resonance` *means*) they
  live here and can change.

If you ever decide a name itself must change (not just its backstory), that is a **code rename**,
not a doc edit — track it as its own task. See [`lore_glossary.md`](./lore_glossary.md) for the
name → mechanical-role map.

## Contents

| Doc | What it is |
|---|---|
| [`lore_story_bible.md`](./lore_story_bible.md) | The full story bible — the **penal-colony premise** (overpopulated Sol exiles colonists & convicts through the Custos Gateway into the empty Helion frontier), the Quantum Matrix mystery, FED/ICE/Outlaw history, faction sovereignty fiction, the Jump Gate Network fiction, player-as-exile journey. (Rewritten 2026-06-22; mechanics referenced here are canon elsewhere, the *story* is draft.) |
| [`lore_art_narrative.md`](./lore_art_narrative.md) | Visual & narrative direction — faction aesthetics, "technology is dangerous not magical" pillar. |
| [`lore_world_framing.md`](./lore_world_framing.md) | In-universe "framing" notes extracted from the mechanics docs (why NPC patrols exist, the "Golden Logic" name, the invisible-hand fiction, etc.). Each entry says which mechanics doc it was pulled from. |
| [`lore_glossary.md`](./lore_glossary.md) | Proper noun → mechanical role / code reference. The single place to look when a name's *fiction* changes. |
