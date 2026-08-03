---
status: canon
phase: "6.9"
last-reviewed: 2026-06-07
tags: [meta, dashboard]
---

# 📋 Doc Health Dashboard

Live drift radar for the design vault. Maintained by the `doc-sync` skill; powered by the frontmatter
lifecycle every doc carries (`status` / `phase` / `last-reviewed` / `supersedes` / `superseded-by`).

> **How the vault stays true:** when Aaron confirms a task is complete, the `doc-sync` skill reconciles every
> affected doc, refreshes its frontmatter, and surfaces it here. Retired canon is marked **superseded** — never
> deleted — so the trail stays intact. See `.claude/skills/doc-sync/`.

## Lifecycle legend

| `status` | meaning |
|---|---|
| `canon` | current truth — safe to build against |
| `draft` | being written, not yet authoritative |
| `superseded` | retired, replaced by `superseded-by` — follow the link |
| `deprecated` | retired, no direct replacement |

---

## 🔴 Retired docs (don't build against these)

```query
["status":"superseded"] OR ["status":"deprecated"]
```

## 🟡 Drafts (not yet canon)

```query
["status":"draft"]
```

## 🔎 Flagged for review

```query
tag:#needs-review
```

## 🌉 Bridge-code docs (tracked scaffolds)

```query
tag:#bridge-code
```

---

## 📊 Richer views — requires the Dataview plugin

The blocks below render as plain code until **Dataview** is installed (Obsidian → Settings → Community plugins
→ Dataview). With it on, you get tables + date math the core search can't do — the single highest-value
upgrade for this vault.

**Stale canon — not reviewed in 60+ days** (needs a `doc-sync` pass):

````
```dataview
TABLE status, phase, last-reviewed
FROM "Design_Documents"
WHERE status = "canon" AND last-reviewed <= date(today) - dur(60 days)
SORT last-reviewed ASC
```
````

**Docs missing a lifecycle (no frontmatter yet — backfill on next touch):**

````
```dataview
TABLE file.folder AS folder
FROM "Design_Documents"
WHERE status = null
SORT file.folder ASC
```
````

**Supersession trail (what replaced what):**

````
```dataview
TABLE superseded-by AS "replaced by", deprecated-on
FROM "Design_Documents"
WHERE superseded-by
```
````

---

> Query syntax uses Obsidian's property search (`[status:value]`); if a block shows no results on your
> Obsidian version, the property-search punctuation may differ slightly — adjust and the `doc-sync` skill will
> learn it.
