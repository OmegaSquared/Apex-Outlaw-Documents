# Blueprint Slot Model — "Frame + Slots" (canon 2026-07-20)

Aaron: "the blueprint does not actually load the item on the ship, it is just
listing out what slots are available… actually adding the parts takes place in
the shipyard."

## The split

A **blueprint is a schematic**, not a loadout. It defines the ship's frame and
WHERE parts can go — it never commits forged instances.

| Tier | Parts | Designed in | Committed at |
|---|---|---|---|
| **FRAME** | midframe hull, wings | Blueprint Design (placed as geometry) | BUILD — auto-consumed from forged stock (they ARE the shape) |
| **SLOTS** | engines, thrusters, reactor, battery, internal bays, weapons/turrets | Blueprint Design places them as **slot positions** (geometry markers) | Shipyard fitting — player plugs a forged instance into each ⊕, choosing WHICH instance (grade!) goes in |

## Consequences

1. **Blueprint Design** lays out geometry + slots. The reactor/battery/internal
   ⊕ strip no longer *fills* anything there — the designer only establishes that
   the slots exist (capacity still derives from placed hulls). Requirements
   (≥1 engine socket, ≥6 side thrusters, ≥1 energy slot…) stay — they validate
   the LAYOUT.
2. **Shipyard fitting** presents every slot from the blueprint: engine and
   thruster positions become ⊕ slots exactly like weapon hardpoints; reactor /
   battery / bays keep the internal strip. Fitting pulls from PlayerPartsStore
   (stock-only sidebar) and the player picks the specific instance — grade
   choice is explicit, at the yard, per part.
3. **BUILD** consumes: the frame parts (auto, best grade) + exactly the fitted
   instances. Blocked until the layout's minimum slots are filled.
4. Blueprints are reusable knowledge — build many hulls from one schematic,
   each fitted from whatever stock exists that day. Pairs with the pre-build
   affordability badges and the Fabrication "buildable now" filter.

## Refitting (Aaron 2026-07-20 clarification)

The shipyard "picks what engine goes into the engine slots and so forth" — and
that applies to EXISTING ships, not just first builds. Changing the weapon (or
engine, thruster, reactor…) on a built ship happens here:

- Open a fleet ship in the shipyard → its slots show the currently-fitted
  instances (✓ with grade).
- Swap: removed instance returns to PlayerPartsStore (it's a real forged part —
  nothing evaporates); replacement is consumed from stock.
- The ship record updates in place (same id — fleet groups, insurance, and
  cloud sync follow the existing record-update path).
- Frame stays fixed — changing hull/wings means a new ship from the blueprint,
  not a refit.

## Status

- Decided 2026-07-20 (Aaron picked "Frame + slots" over "everything is a slot"
  and "minimal change").
- Implementation pending — current interim behavior: BUILD auto-consumes ALL
  blueprint parts best-grade-first; only weapons/turrets/internals are hand-fitted.
