# Resource Card Pipeline

**Status: Live** — every `ResourceSchema` automatically renders as a periodic-table-style card at runtime. No per-resource art needed.

Thin extension to the [resource pipeline](pipeline_resource.md). Documents how the procedurally-rendered card icon is generated and how to override it.

---

## What you get for free

The instant a new `ResourceSchema` is authored, it shows up in the inventory / smelter / forge UI as a 256×256 periodic card:

```
┌──────────────────┐
│ 26               │  ← atomic number (top-left, hidden for compounds)
│                  │
│      Fe          │  ← chemical symbol (large, center)
│                  │
│     Iron         │  ← displayName
│     55.85        │  ← atomic mass
└──────────────────┘
```

- Background color from `phase`: Solid = neutral metallic gray, Liquid = blue, Gas = pale cyan
- Ingot variant (cardKind = Ingot): brushened-metal background + diagonal `INGOT` corner stripe
- Compound variant (cardKind = Compound): hides atomic number, uses a 2-letter fake alloy code

---

## Schema fields

Added to [`ResourceSchema`](../../Assets/Scripts/Schemas/ResourceSchema.cs) for the card pipeline:

| Field | Purpose |
|---|---|
| `chemicalSymbol` | Overrides the card symbol. Leave blank for elements + known compounds — `ElementSymbolTable` resolves automatically. |
| `atomicNumber` | Overrides the top-left number. Leave 0 to auto-resolve, or 0 explicitly for compounds (hides the number). |
| `cardKind` | `Element` (default for raws), `Ingot` (adds the stripe), `Compound` (fake alloy code, no number). |
| `iconOverride` | Designer escape hatch — if set, the cache returns this Sprite verbatim and never bakes a card. Use for bespoke art (mission rewards, lore items). |

---

## Element + compound table

[`ElementSymbolTable`](../../Assets/Scripts/UI/ResourceCards/ElementSymbolTable.cs) — hardcoded lookup mapping `resourceID` to `(symbol, atomicNumber, atomicMass)`:

- 16 known pure elements (Fe, Cu, Ni, C, H, N, U, S, W, Li, Ne, Xe, He, Ti, Au, Ag) with real periodic-table values
- 17 known compounds (Steel = St, FerroTi = Fr, SuperConductor = Sc, etc.) with fake 2-letter codes
- Ingot suffix rule: `iron_ingot` auto-resolves to `iron` lookup — no separate ingot entries needed

**To add a new element** to the table:
1. Add the resourceID to the `Elements` dictionary in `ElementSymbolTable.cs` with real periodic values
2. Authoring the schema with blank `chemicalSymbol` + `atomicNumber` picks it up automatically

**To add a new compound** code:
1. Add the resourceID to the `Compounds` dictionary with a 2-letter symbol (atomic number stays 0)
2. Set `cardKind = Compound` on the schema

**Per-resource override**: skip the table and author `chemicalSymbol` / `atomicNumber` directly on the schema. The schema's authored values win.

---

## Runtime renderer

[`ResourceCardCache`](../../Assets/Scripts/UI/ResourceCards/ResourceCardCache.cs) — lazy-init singleton that bakes cards on first request and caches them.

- Offscreen Camera + ScreenSpaceCamera Canvas + 256×256 ARGB32 RenderTexture
- Card UI built procedurally in code — no prefab dependency
- `schema.GetCardSprite()` extension method — drop-in replacement for `schema.icon`
- `iconOverride` short-circuits the bake when set
- `WarmUp()` method pre-bakes every resource — call during loading screen to amortize TMP / RT cost off the hot path

First-render cost is ~2ms per resource. Steady-state is free (sprite lookup from dictionary).

---

## UI consumers

All resource-icon rendering goes through `schema.GetCardSprite()`:

- [`CrateInventoryPanel.cs`](../../Assets/Scripts/UI/Inventory/CrateInventoryPanel.cs) — row icon, stack title icon, stack tile watermark
- [`InventoryRow.cs`](../../Assets/Scripts/UI/Inventory/InventoryRow.cs) — resource-bind icon (line 38)

The legacy `ResourceSchema.icon` field is retained but no longer read by the card-rendering path. It's deprecated in favor of `iconOverride`.

---

## When NOT to use this pipeline

- **ItemSchema** (weapons, modules, ship parts) — out of scope; they keep their authored sprite assets. Items have stronger thematic identity (a railgun isn't a Re-26 atom); a periodic card doesn't communicate equipment shape.
- **Faction emblems / mission badges** — keep as authored sprites.
- **Bespoke lore items** — use `iconOverride` on a per-resource basis.

---

## Authoring checklist (new resource)

1. Create the `ResourceSchema` per [pipeline_resource.md](pipeline_resource.md) — set resourceID, displayName, phase, mass, etc.
2. If it's a pure element NOT yet in `ElementSymbolTable` → add it to the `Elements` dictionary
3. If it's a compound NOT yet in `ElementSymbolTable` → add to the `Compounds` dictionary, set `cardKind = Compound`
4. If it's an ingot → set `cardKind = Ingot`; the symbol auto-resolves from the raw element via the `_ingot` strip rule
5. Test in the inventory panel — the card should appear automatically

No code changes for new resources. No baked PNGs to commit.
