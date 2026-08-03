# Resource Roster & Composite-Ore Mining

> **Canon added 2026-07-05 (Aaron design session).** Two decisions live here:
> **(1) the resource roster exists to feed the BLIND tech tree** — variety is the alphabet of
> the crucible/alchemy discovery puzzle, not inventory busywork; **(2) mining is COMPOSITE** —
> one mining run yields *several* materials at once, weighted by where you're mining. Players
> never hunt sixteen different mine types; they prospect for *ground worth mining*.
>
> Related: [`economy_scanning_extraction.md`](./economy_scanning_extraction.md) (scanner anchors),
> [`economy_alchemy_research.md`](./economy_alchemy_research.md) (matrix + synthesis),
> [`economy_overview.md`](./economy_overview.md) (layer map).

---

## 1. Why the roster is big on purpose

The tech tree is **non-linear and fogged**: nothing ever lists what remains undiscovered.
Progression is combining ingredients in the crucible and reasoning about what the world's
materials *might* make. That only works if the ingredient alphabet is rich enough that the
recipe space feels unknowable:

- At 2–4 crucible slots, **20 ingredients ≈ 6,000 possible combinations**; 50 ingredients ≈
  250,000. Both are unsearchably large — nobody brute-forces either.
- Therefore the puzzle's real depth = the number of **meaningful** combinations (authored
  recipes), not the raw SKU count. Past ~20 well-chosen identities, extra SKUs add noise,
  not depth.
- Discovery is fun when players can **theorize** ("a plasma coil… copper windings, xenon
  gas?"). Materials must be *archetypal* — each one the answer to a question a player can ask
  out loud. Fifty interchangeable ores turn theories into lottery tickets.

**Combo-space budget (how depth scales without new SKUs):**

| Dimension | Status | Effect |
|---|---|---|
| Ingredient identity (the roster) | live | the base alphabet |
| Grade thresholds (min grade per recipe) | live (crucible canon) | same combo, better forge → different result |
| Quantity ratios (2 Fe + 1 C ≠ 1 Fe + 2 C) | planned | multiplies every combo ~×3 with zero new SKUs |
| Exotic keys (rare, location-locked materials) | planned | gate whole tech branches behind exploration |

## 2. Composite ore — multiple resources per mining run (CANON)

**The core idea (Aaron):** ore is not a single substance. One mining operation returns a
**yield vector** — e.g. a single run produces iron *and* carbon *and* copper — and the mix
depends on **where** the miner is working. Some ground runs copper-rich, some iron-rich.

```
   prospect site  ──►  ASSAY  ──►  yield vector (per site / biome band)
                                     iron 42% · silicates 30% · copper 18% · carbon 10%
   mining run     ──►  crate receives ALL of them, in those proportions,
                       grades rolled from the site's quality band
```

Rules that make it work:

1. **One verb, many nouns.** The player never needs sixteen mine types. Mining anywhere
   produces several materials; the *decision* is which ground to work, not which resource
   node to chase.
2. **Sparse vectors — 3 to 5 materials per site, never everything-everywhere.** If every
   site trickles all sixteen raws, no region is special and trade dies. A site's absences
   are as important as its riches.
3. **Location identity comes from the weights.** A copper basin, an iron shelf, a carbon
   seam. Regions rich in *different* things create prospecting gameplay, trade routes,
   territory worth fighting over, and a reason to found a base *here*.
4. **Grade rides the vein.** Site quality drives the **grade distribution** of everything it
   yields — a rich vein isn't just more copper, it's *better* copper. This welds mining
   location to endgame forging with no extra systems.
5. **Assay legibility.** Sampling a site returns a readable report (the vector above).
   Prospecting must feel like *reading the world*, not pulling a slot machine lever.
6. **Exotics are NOT in common ore.** The rare tier (see §4) only appears in dangerous or
   strange locations — that's the deepest layer of the tech-tree fog, and it stays
   exploration-locked.

**Already half-built:** biome bands carry exactly this shape — `BiomeBandAuthor` signatures
like `granite 6 · iron 4 · copper 3 · titanium 2 · carbon 2`. The surface stone crate
(`SurfaceStoneEconomy`) already emits multi-material yields (stone runs adding copper).
The model above is the generalization of what the code already wants to do.

**Fit with the per-player scanner** ([`economy_scanning_extraction.md`](./economy_scanning_extraction.md)):
scanner anchors answer "*where is MY high-grade iron*"; the composite model answers "*what
else comes up while I'm digging for it*." An anchor marks the site's **headline** material;
the assay reveals the full vector. The two systems compose — no contradiction.

## 3. Current census (2026-07-05, honest count)

From `Assets/Resources/Schemas/Resources/` + `ElementSymbolTable` + starter grants:

- **Raw elements (16):** hydrogen, helium-3, lithium, carbon, nitrogen, neon, sulfur,
  titanium, iron, nickel, copper, silver*, xenon, tungsten, gold*, uranium
  (*catalogued under Rare Materials with platinum)
- **Raw mixtures (5):** scrap metal, silicates, methane, water ice, iron ore (`ore_iron_01`)
- **Construction (2):** granite, regolith
- **Refined compounds (12):** steel, ferro-titanium, super conductor, electrum wire,
  nickel-iron plating, ion plasma, synthetic polymer, aerogel mesh, thermal paste,
  carbon-fiber glass, radar-absorbent pigment, ammonia
- **Ingot mirror (10):** copper/gold/iron/lithium/nickel/silver/titanium/tungsten/uranium
  ingots (+ recipes for each)
- **Components (6):** Actuator, Control Circuit, Hull Plating, Plasma Coil, Reactor Cell,
  Structural Frame
- **Housekeeping debt:** duplicate assets (`Iron` vs `iron_schema`, `Steel` vs
  `steel_schema`), a `Titatium` typo asset, and an unclassified `Isotopes` asset.

Roughly **50 distinct identities** before grades multiply them into stock rows.

## 4. Roster shape (PROPOSAL — needs Aaron sign-off before any asset work)

Keep the alphabet rich enough for the fog, cut only what adds lines without adding theories:

- **Keep the 16 elements as mining outputs.** Under composite ore they cost no gathering
  friction — several surface per run. Each keeps an archetype: iron = structure, copper =
  conduction, carbon = chemistry, xenon = exotic gas, etc.
- **Decide the ingot mirror.** Ten `*_ingot` SKUs duplicate every metal's identity. The
  grade ladder already expresses refinement ("refining raises grade" would delete ten SKUs
  and make the grade faucet the refinery — deeply canon). **But** 10 authored recipes and
  the alchemy synthesis model currently use ingots as the refined tier. Options:
  **(a)** refine-raises-grade, retire ingots (cleanest inventory, touches 10 recipes);
  **(b)** keep ingots as the smelter's output *identity* and accept the lines. This is the
  single biggest simplification lever either way.
- **Promote the rare tier to exotic keys.** silver, gold, platinum (+ uranium, xenon as
  candidates) become location-locked discovery keys with real recipes behind them —
  found only in dangerous space, gating tech branches. A rare with no recipe is dead weight.
- **Compounds stay** (they're the theorizable middle tier the crucible feeds on), but every
  compound should be wanted by at least one component/part recipe.
- **Litmus for any future material:** *is it the answer to at least one question a player
  can ask out loud?* (Where do I get it? What might it make? Why is this region worth
  holding?) If two materials mine the same, haul the same, and spend the same — they're one
  material with two names.
- **Cleanup regardless of decisions:** merge the duplicate iron/steel assets, fix
  `Titatium`, classify or cut `Isotopes`.

## 5. Grade provenance — "quality is MINED, not manufactured" (CANON 2026-07-05)

One law governs where grade comes from and how it moves: **grade originates in the ground;
everything downstream can only preserve it or lose it — never create it.**

1. **The vein sets a grade DISTRIBUTION, not a fixed grade.** A rich site rolls mostly B
   with occasional A; poor ground rolls D with a lucky C. Composes with the per-player
   scanner canon ([`economy_scanning_extraction.md`](./economy_scanning_extraction.md)): the
   player's alchemy seed answers *where* their best ground is, the vein answers *how good*,
   and coordinates stay untradeable. Prospecting is therefore the ONLY faucet where
   high grade enters the universe — rich territory is worth fighting over by construction,
   and the Miner role is structurally irreplaceable.
2. **Weakest-link propagation.** A component's grade is capped by its worst ingredient; a
   part by its worst component; a ship by its worst part. (`minimumGradeRequired` and the
   crucible thresholds already gesture at this — it is now the universal rule.) Demand for
   high grades cascades UP the chain: an A-grade turret needs A-grade steel needs A-grade
   iron needs somebody's exceptional vein. Interdependence enforced by arithmetic.
3. **Facilities buy PRESERVATION, not creation.** A crude smelter eats ~2 grades in the
   melt; a top-tier refinery is lossless. Infrastructure never mints quality the ground
   didn't provide — but bad infrastructure squanders what it did. That's the industrial
   player's ladder.
4. **The forge roll — where [Flaw] lives.** Fabrication rolls a small variance around the
   input-determined center: mostly ±0, occasionally −1, VERY rarely +1. **[Flaw] (grade 0)
   is a forge miracle, not a mineable material** — it can only emerge when every input is
   already flawless-adjacent. [Flaw] items are events people talk about, never products you
   farm.
5. **Salvage obeys the law.** Wreck drops (`salvageDropChance`, `SalvageItem`) carry the
   grade of the fitted part — combat RECYCLES existing quality into the market; pirates
   redistribute grade, they don't create it. Grade is conserved economy-wide.
6. **Rejected alternative:** grade from maker skill/stats — there is no XP anywhere in the
   design, and Maker's-Mark reputation is emergent from output data. Under weakest-link,
   a forger's consistent A-grade output IS the reputation, no stat needed.

## 6. Downstream hooks

- **Crucible** ([`economy_alchemy_research.md`](./economy_alchemy_research.md)): the roster
  is its alphabet; grade thresholds already live; quantity ratios are the next cheap
  depth-multiplier.
- **Trade/arbitrage** ([`economy_npc_arbitrage.md`](./economy_npc_arbitrage.md)): sparse
  yield vectors are what create regional price spreads worth hauling against.
- **Surface bases** ([`../ground_base/progression_base_building.md`](../ground_base/progression_base_building.md)):
  a base's site vector is its economic identity; smelter/refinery throughput consumes the
  local mix.
- **Wreck salvage (2026-07-05):** destroyed hulls roll `salvageDropChance` per fitted
  internal — salvage is a parallel *module* faucet, not a materials faucet; it feeds the
  wreck economy, not the roster.
