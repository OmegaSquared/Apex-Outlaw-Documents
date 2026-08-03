# MMO Alchemy & Research Mechanics TDD

## 1. The Core Alchemy Philosophy
The single unique defining feature of this MMO is that high-tier equipment cannot be predictably farmed. It must be discovered organically through the "Alchemy" Matrix. A player's progression is tied intrinsically to a unique, hidden numerical seed tied to their account.

---

## 2. The 10,000 x 10,000 Matrix
Every base element (Iron, Helium, Carbon) generates a massive 2D matrix of "Quality" based on the player's seed via procedural noise (e.g., Perlin/Simplex).

- **The Variables:**
  - 95% of the matrix returns "Junk" values (e.g., Quality 1-500).
  - "False Peaks" exist to distract players (Quality ~1,000).
  - Exact localized "True Peaks" reach the maximum theoretical limit of `12,345`.
- **The Loop:** The player clicks around a UI grid (or drives a specialized sensor-ship) to uncover coordinates. Once they find a 12,345 peak coordinate, they lock it in on their *Best Found Ledger*. That element is forever optimized for them.

---

## 3. Synthesis & "Child" Elements
Finding raw elements is only Step 1. Crafting high-tier items requires synthesizing elements.

- **Synthesis Rules:**
  - `Iron [Best: 12,000]` + `Carbon [Best: 11,500]` = `Steel Blueprint Unlocked`.
- Once Steel is unlocked, it generates its *own* unique 10,000x10,000 matrix. The player must now scan the *Steel Matrix* to find high-quality steel.
- The base quality of the "Parent" elements acts as a multiplier ceiling for the "Child" matrix. If your Iron and Carbon are terrible, your maximum possible Steel peak will be severely kneecapped until you find better parent materials.

---

## 3.5. Quality Grading (Player-Facing Tiers)

The underlying integer quality (0-12345) drives ALL combat math via `Mathf.Lerp(min, max, quality / 12345)`. Players never see the raw number — they see a **letter grade** that maps to a band of qualities. This achieves two things:
1. **Inventory readability.** Without grades, every forged variant of "Plasma Cannon" would clutter the inventory as a separate row (one per integer roll). Banding by grade collapses the list — "5x [D] Plasma Cannon" stacks all D-band rolls into one entry.
2. **Discoverability gating.** The top tiers occupy a *narrow* slice of the 12345 range, so even players who have unlocked a recipe almost never roll into the top bands. The full statistical curve is preserved (math still uses the integer); only the player's *visible signal* is grade-banded.

The 16 grades, top to bottom:

| Grade | Code | Band (default curve) | Player-facing tier |
|---|---|---|---|
| Flawless    | Fl  | 12100 - 12345 | Vanishingly rare. Only attainable when every parent material in the synthesis chain rolls an Fl-tier peak. |
| Epic        | E   | 11700 - 12099 | World-class. Reserved for veteran grinders with deep alchemy chains. |
| Super       | S   | 11000 - 11699 | Top-tier. Universally desired. |
| Grandmaster | A+  | 10000 - 10999 | Elite endgame. |
| Master      | A   |  9100 -  9999 | High-end. |
| Elite       | A-  |  8100 -  9099 | Strong. |
| Exemplary   | B+  |  6900 -  8099 | Above-average raid gear. |
| Excellent   | B   |  5700 -  6899 | Solid mid-tier. |
| Strong      | B-  |  4500 -  5699 | Reliable mid. |
| Refined     | C+  |  3300 -  4499 | Workhorse. |
| Standard    | C   |  2300 -  3299 | Default mid. |
| Decent      | C-  |  1500 -  2299 | Just-above-floor. |
| Solid       | D+  |   900 -  1499 | Floor-tier-plus. |
| Average     | D   |   400 -   899 | The default forge result for early players. |
| Awful       | D-  |   100 -   399 | Bad rolls / failed synthesis. |
| Failed      | F   |     0 -    99 | Total junk. Sometimes vendored or recycled. |

Bands are authored in `Resources/Schemas/Grades/grade_table_default.asset` (a `GradeSchema` ScriptableObject). The curve is **tunable in the Inspector**, not in code — designers can re-shape the rarity distribution in real time. Top-tier slices are intentionally narrow so almost every roll lands in F → C territory; Fl occupies only ~2% of the integer range, and most of THAT is gated behind needing all parent materials at peak quality.

Quality 700 (the default seed grant for fresh accounts) lands in the **D band** — confirms that brand-new accounts forge "Average" gear, not C / B / A.

---

## 3.6. Graded raws vs Bulk commodities (`MaterialClass`)

**Reconciliation (canon 2026-06-07).** Earlier framing held that *all* raw resources are ungraded ("a unit of Iron is a unit of Iron"), with grade living only on manufactured parts — see the still-stale `ResourceSchema` docstring. That was superseded by the scanned-grade model. Current canon splits raws via `MaterialClass { Graded, Bulk }`:

- **Graded** (ores, isotopes, gases — iron, helium-3, titanium…) carry a grade = the per-player Matrix quality at the *location* they were extracted from. This is the spatial reification of §2's element matrix: a scanned high-grade rock/deposit **is** a discovered peak. That value is the material's "Best Found" quality that then ceilings synthesis (§3), and is tracked in `maxDiscoveredGoods`.
- **Bulk** (construction commodities — granite, regolith, water, scrap metal) are genuinely ungraded — pure tonnage, no Matrix, no scan, no discovery. They are **excluded from the min-grade purity cascade** (count for tonnage, never drag a forged part's grade down).

Surface-gathering specifics (on-planet A− cap, drone-gather vs miner-scan discovery split) live in [`../world/world_surface_gathering.md`](../world/world_surface_gathering.md).

---

## 4. Harvesting Enemy Tech ("Golden Logic")
How do PvP players progress if they hate scanning grids? **By stealing — but stealing has hard limits.**

> **Canonical rule (read this carefully).** A stolen component is a **single physical item**. The pirate gets *that* component into their inventory and can fit it, repair it, or sell it intact. They **cannot manufacture additional copies of it.** The only path to *producing* a high-quality component is the Matrix Scanner research path (§§1–3 above) — and that requires the player to do their own peak hunting against their own Seed. A pirate who never researches will never *manufacture* anything; they will always be a consumer of items produced by Researchers (or by their own past kills). This is the load-bearing rule that keeps Researchers economically valuable.

### 4.1 What you can do with a stolen module
- **Fit it.** Drop the component into a hardpoint and use it as-is. Quality / grade / current Condition all transfer with the physical item.
- **Repair it.** Stolen modules degrade like any other module. If the wreck recovery yielded a viable **Repair Recipe** ("Golden Logic" — see §4.4), the owning player can refurbish the module at a Citadel or Sector Hub using *raw materials*, restoring Condition without consuming the module. Without the recipe, repair is partial / lossy.
- **Sell it.** Intact stolen components are tradeable on the open market and on the black market for a premium — they're often a Researcher's only path to a high-quality module they haven't synthesized yet.
- **Field Strip it.** Break it down for raw resources / scrap.

### 4.2 What you cannot do with a stolen module
- **You cannot manufacture a copy.** The component's *manufacturing* recipe (the Matrix peak coordinates that produced it) belongs to the Researcher who made it, keyed to *their* Seed. Stealing the component does not steal their Seed. A stolen masterpiece can be fitted, repaired, sold, or destroyed — but never duplicated.
- **You cannot transfer the manufacturing capability** to your own Researchers. They have to find their own peaks.

### 4.3 The Tow
- **The Mechanic:** When an enemy ship is destroyed, the wrecked chassis becomes a physics object in space.
- **The Tow:** Players tether the wreck. This broadcasts a "Pirate Beacon" to the sector and cuts thrust speed by 70%.
- **Deconstruction options:**
  - *Field Strip (Deep Space):* Immediate scrap/ore. No intact components recovered, no Repair Recipes.
  - *Forensic Decon (Sector Hub):* Takes 1 hour. Up to N intact stolen modules pulled from the wreck (configurable per module type), plus a 1% chance per module to learn its **Repair Recipe**.
  - *Citadel Decon (Alliance Base):* Takes 1 hour. Same intact-module recovery as Sector Hub, plus a 2% chance per module to learn the Repair Recipe.

### 4.4 Repair Recipes ("Golden Logic")
- **What it is.** A Repair Recipe documents the *maintenance ratios* of an enemy module — what raw materials a refurb cycle consumes and how Condition is restored. It does **not** document the manufacturing peaks (those live with the original Researcher's Seed).
- **What it unlocks.** Once a player learns the Repair Recipe for a module, every copy of that module they ever loot — including stolen masterpieces, Researcher-grade gear they bought legally, and anything an alliance member kicks in — can be refurbished cleanly at full Condition recovery.
- **Where it lives.** In the player's personal *Golden Logic Library*. Alliances also keep an alliance-shared Library that pools recipes contributed by members (subject to the rank gate in [`../social/social_alliance_guild.md`](../social/social_alliance_guild.md) §2.2).
- **Lore framing** (non-canon) → [`../lore/lore_world_framing.md`](../lore/lore_world_framing.md#repair-recipes--the-golden-logic-name) — why it's called "Golden Logic".

### 4.5 Why this matters economically
The whole game's role interdependence rests on this rule:
- **Researchers** produce new, high-quality components by hunting peaks. They are the *source* of supply.
- **Miners** feed Researchers raw materials.
- **Pirates / Mercenaries** redistribute existing components by violence — stealing intact items, recovering Repair Recipes that keep stolen items operational, and selling on the black market.
- **Pure-combat players who don't research** are *permanent customers* of the market — for new gear, for repairs, for anything they can't loot off a kill. This is by design.

> If you are *just* a fighter — never opening the Matrix Scanner, never running synthesis cycles — you will always rely on the store, on Researcher allies, or on what you can rip off a wreck. This is the load-bearing tension that keeps the economy alive.
