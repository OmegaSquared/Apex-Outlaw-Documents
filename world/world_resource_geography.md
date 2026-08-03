# Resource Geography — Helion System Expansion Plan

This doc owns **what resources live where in Helion, and the phased plan for expanding the system to support them**. Pairs with [`world_solar_map.md`](./world_solar_map.md) (the rendered map) and [`world_sector_map.md`](./world_sector_map.md) (gate authoring + chain mining rule). The economy side — refining, recipes, market segmentation — lives in [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md).

## Why this exists

Resource scarcity isn't just "rare item drops at 0.1%." It's **geographic**: certain materials only exist in certain zones, and travel cost is part of the gameplay loop. Without explicit geography, every belt becomes the same belt and travel stops mattering. The 12,345 Alchemy Matrix layers a *per-player roll* on top of geography — together they create three nested scarcity dimensions (location, family, grade) that keep every player's economy slightly different.

This doc captures the **system-wide geographic plan** so future-Aaron, future-me, or anyone joining the project doesn't relitigate the principle each time a new body is added.

---

## Principles

### 1. The Frost Line is the system's natural divider

Real solar systems separate at the **frost line** — the radial distance where volatiles (water, methane, ammonia, nitrogen) transition from solid to gas. Inside the line, the sun's heat boils them away; outside, they stay frozen. This gives us a free, intuitive divider:

- **Hot zone (pre-frost-line):** dry rocks. Metals, silicates, sulfur, carbon. **No ice.** Aluminum + carbon-bearing chains. High-temperature minerals (tungsten, refractories).
- **Cold zone (post-frost-line):** ice + volatiles + cold-trapped exotics. Water ice, methane, ammonia, nitrogen. Helium-3 concentrates in cold reservoirs.
- **Hybrid / interface:** rocks at the boundary carry hydrated minerals + organics. Goldilocks-zone terrestrials sit here — liquid water + atmosphere.

Players learn the geography from the gameplay (where they find what), rather than memorizing arbitrary tables.

### 2. Multiple extraction channels — not just belts

Belt mining is one mechanism. The full set:

- **Belt mining** (drop a miner / outpost on small asteroids in a belt) — bulk metals + silicates from the inner Main Belt; ice + volatiles from outer ice belts.
- **Named asteroid mining** (large lore-coded bodies — Castor, Pollux, Latro, Praedo, etc.) — fixed, hand-tuned compositions tied to lore. These are individual *bonanza* targets, not random rocks. Different mechanic from belt streaming.
- **Gas extraction** (atmospheric scoop on a gas giant) — hydrogen, methane, ammonia, helium-3. Different ship loadout, different sector activity, different vulnerability profile (you're orbiting deep in a planet's gravity well).
- **Planet rings** (Saturn-style narrow ice/dust band) — a thin AsteroidBelt orbiting the planet itself. Mechanically identical to a belt, geometrically distinct.
- **Surface extraction** (planet-side mining base) — Tier-1 raw materials from a planet's crust. Volcanic worlds (Avernus) → sulfur + refractory metals; terrestrial worlds → carbon + iron + water; ice worlds → frozen volatiles. Tied to Phase 6.8 base-building. **The full gathering loop (biome → deposit → harvest → crate → forge), the on-planet A− grade cap, and the drone-gather-now / miner-scan-future split are canon in [`world_surface_gathering.md`](./world_surface_gathering.md).**

Different channels = different gear, different risks, different gameplay rhythms.

### 3. Scarcity gradient layered on geography

Three dimensions stack:

| Dimension | Mechanism | Example |
|---|---|---|
| **Geographic** | Resource only spawns in specific zones | Helium-3 doesn't exist in the Main Belt; you go cold-zone or gas-giant |
| **Family weight** | Within a zone, rare categories have low spawn weights | Crystal_Spikey @ weight=1 vs Cratered @ weight=25 in the Main Belt |
| **Per-player grade roll** | 12,345 Alchemy Matrix — same belt rolls different grades for different players | Player A sees mostly C-grade iron, Player B sees the Flawless apex |

The 12,345 Matrix is canon ([`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md)) and runs on top of whatever geographic layout this doc defines. Geography sets the menu; the Matrix sets the prices.

**On-planet grade cap (canon 2026-06-07):** planet-surface *graded-class* deposits never roll above **A− (Elite)** (ceiling ~9,099 on the 0–12,345 scale, per the grade table — never a magic number). Everything above A− — A (Master), A+ (Grandmaster), S, E, Fl — is **off-planet only** (belts, named asteroids, The Ring). This is the fourth scarcity lever: the best grades demand leaving the homestead for contested space. Full loop + the drone-vs-miner discovery split in [`world_surface_gathering.md`](./world_surface_gathering.md).

---

## Faction control doctrine

**Canon (2026-06-08 — supersedes the retired 2026-05-18 "Vesperion is ICE-only, FED elsewhere" framing):** Helion is **one shared star system** holding all three powers — **FED** (homeworld **Concordia**), **ICE** (homeworld **Ferrum**; its capital city is **Civitas Ferri**), and the **Outlaws** (the belts + outer system). The two faction homeworlds are formally controlled; **every other planet** (Avernus, Aridus, Tempestas, Caelum, Aether, Ultima, and future additions) is **CONTESTED** — no faction owns it; alliances claim it through the standard control mechanics ([`world_faction_sovereignty.md`](world_faction_sovereignty.md) §4 / [`../meta/master_to_do.md`](../meta/master_to_do.md) Phase 5.5). The detailed per-planet controlled-vs-contested split is finalized in Phase 5.5.

Why this canon:
- Helion is a single system, not faction-segregated — FED, ICE, and Outlaws all operate here ([`../lore/lore_story_bible.md`](../lore/lore_story_bible.md) §3–4). "Vesperion" was only ever the scene filename, never a separate system; the earlier ICE-only iteration is retired.
- ICE's grip is its inner industrial cluster around **Ferrum**; FED's is the **Concordia** hub cluster; both leave most of the system contested.
- The Main Belt and outer cold are Outlaw-leaning open territory — alliances vie for the contested gas giants and outer bodies.

The contested zone outnumbering the controlled zone is the **central design lever** for Helion gameplay: most of the system is alliance-claimable, which means most of the system is up for grabs.

---

## Current state (2026-06-08)

Helion has one authored star-system scene — **`SolarSystem.unity`** (formerly `Vesperion.unity`) — which is the **canonical body roster**. The registry (`seed.json`) is being reconciled to follow it (Phase 6.8.4). The system holds **8 planets + 23 moons + 20 named asteroids + 1 outer-cold belt**, all orbiting the star **Helion**:

| Planet (hot → cold) | Type | Faction | Moons / features |
|---|---|---|---|
| **Avernus** | Lava (inner) | Contested | Cinis, Fumus, Scoria · reference planet build per [`world_planet_authoring.md`](./world_planet_authoring.md) · player home "Outpost Aaron" |
| **Aridus** | Arid / desert | Contested | Pulvis, Saxum |
| **Tempestas** | Storm terrestrial | Contested | Pluvia, Grando, Nubes |
| **Ferrum** | Terrestrial (industrial) | **ICE** | Mons, Lapis · **capital city Civitas Ferri** (ICE seat of power) |
| **Caelum** | Gas giant | Contested | Cirrus, Stratus, Caligo, Nox, Cumulus, Tonitrus · **Saturn-style Ring** |
| **Aether** | Gas giant | Contested | Lumen, Umbra, Aurora, Vortex |
| **Ultima** | Outer ice | Contested | Pruina, Glaucus, Borealis |
| **Concordia** | Terrestrial | **FED** | FED homeworld — registry + docs canon; scene body not yet authored (`// BRIDGE`, see [`../meta/master_to_do.md`](../meta/master_to_do.md)) |

**Named asteroids (20):** Castor, Pollux, Latro, Praedo *(inner rocky)*; Algor, Frigus, Tenebrae, Niveus, Hiems, Crepusculum, Profundum, Polus, Silentium, Lethum *(cold / ice)*; Vagans, Errans, Crinitus, Profugus, Cometes *(wanderers — elliptical orbits)*. **Names stay Latin-meaningful** — Praedo = "plunderer," Latro = "robber," Castor/Pollux = Roman navigation gods, Algor = "cold," Niveus = "snowy," Vagans/Errans = "wandering," Cometes = "comet." Composition tied to lore (see Inner system identity below). *(The earlier Cautes/Custos/Petra/Speculum/Vallum list was superseded by this scene roster.)*

**Belt:** `Belt_Vesperion_OuterCold` — the outer cold ice belt. *(The ID still carries the legacy "Vesperion" tag; renaming it to `Belt_Helion_*` is tracked separately since it touches the registry + code.)*

**Registry source of truth:** [`Assets/GameData/Celestial/seed.json`](../../Assets/GameData/Celestial/seed.json) → pushed to PlayFab title-data `CelestialRegistry`. *(Reconciliation to the roster above is in progress — Phase 6.8.4.)*

## Inner system economic identity

Each inner-system body has a **signature resource set** that makes it economically distinct. Without exclusivity, every body becomes "the belt with extra steps." Lock-in for the inner system:

### Avernus (lava world) — refractories + sulfur
Real analog: Io / early Earth / Venus surface. Volcanic outgassing + exposed planetary core. Heat eliminates organics + volatiles, concentrates refractories.

| Tier | Resource | Notes |
|---|---|---|
| **Primary** | Sulfur | *The* signature lava-world resource. Volcanic outgassing produces sulfur in bulk. Belt has trace via Organic family; Avernus is the reliable source. |
| **Primary** | Tungsten | Refractory metal, survives extreme heat. Belt has it only via Rare Glowing family. Avernus is the reliable industrial-scale source. |
| **Rare/hazard** | Uranium | Concentrates in deep magma. Hazardous extraction (when surface-base mechanics land, Avernus uranium can carry a radiation hazard tag — slower extraction or risk to crew). |
| **Trace** | Iron | Volcanic exposes the core. Common but belt is more efficient. |
| **Trace** | Helium-3 | Mantle convection outgassing. Plausible trickle; not the primary source. |
| **Trace** | Gold, Silver | Volcanic hydrothermal deposits. Rare placer concentrations. |

### Avernus moons (Cinis, Fumus, Scoria) — volcanic byproducts
Latin names already lore-coded: *Cinis* = ashes, *Fumus* = smoke, *Scoria* = volcanic rock. Each moon leans toward one type so they're not interchangeable.

| Moon | Lean | Primary | Secondary |
|---|---|---|---|
| Cinis ("ashes") | Silicate-heavy | Silicates (cooled volcanic glass + obsidian-equivalent) | Sulfur trace ash |
| Fumus ("smoke") | Carbon-heavy | Carbon (volcanic graphite + soot deposits) | Sulfur trace |
| Scoria ("cinder") | Sulfur-heavy | Sulfur ash deposits | Silicates |

### Aridus (hot sand world) — lithium + bulk silicates
Real analog: Mercury daylight side / parts of Mars / desert evaporite environments. No atmosphere, no water, extreme dry concentration of evaporite minerals.

| Tier | Resource | Notes |
|---|---|---|
| **Primary (bulk)** | Silicates | Sand = SiO₂. Easy bulk source for early players; no risk, no faction tax if Outlaw-controlled. |
| **Primary** | Lithium | Evaporite deposits — earth's lithium pegmatites form in dry environments. Belt has it only via Rare Crystal; Aridus is the reliable mid-tier source. |
| **Primary** | Titanium | Titanium dioxide (rutile) common in sand. Matches or slightly exceeds belt yield. |
| **Common** | Iron | Hematite / red sand. Common but belt + Avernus are better. |
| **Uncommon** | Copper | Arid surface concentration (oxide ores). |
| **Trace** | Gold, Silver | Placer deposits in sand. Rare. |

### Main Belt (Belt_Vesperion_Outer, r=7000–9000) — metallic / silicate workhorse
Pre-frost-line dry rocky belt. Mars–Jupiter analog. Category distribution canon per [Phase 6.8.B](../meta/master_to_do.md):

| Tier | Resource | Source category |
|---|---|---|
| **Common (~78%)** | Iron, nickel, copper, titanium, cobalt, silicates, aluminum-equivalents | Cratered, Holed, Mineral, Soft |
| **Uncommon (~19%)** | Carbon, sulfur, water-trace (hydrated minerals only — no pure ice) | Organic |
| **Rare (~3%)** | Lithium (Crystal), platinum (Crystal_Spikey), helium-3 + tungsten (Glowing) | Crystal, Crystal_Spikey, Glowing |

**Hard rule: no ice in the Main Belt.** Pre-frost-line; ice sublimes. Ice/Ice_Spikey families excluded.

## Named features (locked in)

### The Ring (alien tech around Castor)

A partial alien-built ring orbits the named asteroid **Castor** — a massive structure of unknown construction, mostly intact but visibly damaged. Made of an alloy that can't be replicated with any known tech. Lore: **the precursors used Castor & Pollux as navigation anchors** (the Roman twin gods of sailors). The Ring was a transit / signal / observation array; something destroyed it during an event nobody remembers.

- **Geographic placement:** orbits Castor at the named asteroid's body-scale (small radius, ~50–80 units outward). Visible as a thin band from far. Composed of: a few large intact arc segments + a debris cloud spread along the rest of the ring's circumference.
- **Why a ring (not a planet-scale megastructure):** moon-scale alien tech is approachable, discoverable, and capturable. A sun-orbit ringworld would dominate the entire system; a Castor-orbit ring fits among other features.

**Mechanics:**

| Tier | Activity | What you get |
|---|---|---|
| Casual / immediate | Salvage the debris ring | Trickle of **Ancient Alloy** + occasional **Precursor Crystal** (new Tier-4+ catalysts, see Exotic Resources below). Mineable like a thin asteroid belt — anyone can do it. |
| Mid-tier | Investigate intact segments | Some segments hold pressure / atmosphere / partial function. Mini-dungeons inside. Drop lore archive entries + occasional intact Precursor modules. |
| Late-game | Crack the central function | The Ring isn't just debris — its surviving systems still do *something* (broadcast? observe? gate?). Discovering its function is an alliance-scale objective with unique reward. TBD what the prize is — could be a stable wormhole-style fast-travel, a sensor network covering Helion, or a power station that boosts nearby production. |

**Lore questions left open (deliberately):**
- Who built it? (Precursor aliens? Pre-Exodus human megaproject?)
- Why is it broken? (Combat damage? Self-destruct? Time?)
- What does it still do? (Active signal? Dormant?)
- Are the builders coming back? (The mystery generates player lore-speculation.)

### Praedo Pirate Stronghold (Outlaw faction content)

The named asteroid **Praedo** (Latin: "plunderer / pirate") is a hollowed-out Outlaw stronghold. Multi-deck interior, hidden docking bays, black market hub.

- **Geographic placement:** Praedo is already in the named asteroid list with an elliptical / smuggler-path orbit (per existing canon — `MacroEllipticalOrbiter`). The orbit fits the lore: Praedo is hard to predict, hard to ambush, comes and goes from inner / outer system.
- **Mechanics:**
  - **Outlaw faction hub** — black market trading post (no FED 35% tax, no ICE tariff, no 3% universal escrow). Accepts stolen / contraband goods that mainstream hubs reject. Per [`../economy/economy_exchange_pricing.md`](../economy/economy_exchange_pricing.md) §5 "Black Market."
  - **PvP siege target** — alliances can attack and capture Praedo (taking over its services + the alliance gains a major Outlaw-territory foothold). Defenders include the Outlaw NPCs that live there.
  - **Hidden from default scanners** — discovery required. Players who know Praedo's current orbital position have valuable intel.
  - **Hauler contracts / quest source** — Outlaws contract smuggling missions out of Praedo.
- **Why Praedo specifically:** name + elliptical orbit + outer-asteroid framing are all designed for this. Locked in.

**Secondary outlaw locations** (deferred but designed):
- **Latro** ("robber") — secondary stronghold or operational satellite of Praedo.
- **Speculum** ("lookout") — Outlaw sensor station / spy outpost.

### Wandering Bodies (elliptical-orbit asteroids)

Beyond Praedo (which has a smuggler-path elliptical orbit), Helion supports **wandering bodies** as a general mechanic: asteroids on highly eccentric orbits that swing from sun-grazing perihelion to deep-outer aphelion across months / years.

- **Mechanics:**
  - **Composition reflects orbital origin.** A wandering body that originated in the outer cold carries helium-3 / ice / volatiles — even if it's currently passing through the Main Belt. Limited-time mining opportunity.
  - **Stuck if you base on one.** Drift with the body through its entire orbit. Mining-base time-locked.
  - **Risk profile shifts with position.** At perihelion (sun-close): heat damage, fast orbital speed makes evacuation hard. At aphelion (deep outer): lawless space, no patrols, pirate ambush territory.
  - **Reward profile:** the wanderer's composition is a "package" — known resource mix for the price of orbit lockup. Pre-committed long-term mining.
- **Why it's fun:** introduces **timing as a gameplay axis**. "Catch wanderer X before it leaves the belt next week." Pirates know wanderer routes — they're prey corridors. Bases on wanderers are strategic gambles, not safe homesteads.
- **Status:** `MacroEllipticalOrbiter` component already exists (used by Praedo). Authoring more wandering bodies + the composition mechanic is Phase 6.8.x.

### Exotic resources (new — introduced by The Ring)

Two new resources above the canonical Tier-1 raws list. Both unique to alien tech features.

| Resource | Source | Role |
|---|---|---|
| **Ancient Alloy** | The Ring debris (salvage) + Hollow Moon / Dyson Moon (future) | Tier-4+ structural catalyst. Drives highest-tier weapon hulls + capital armor. Can't be manufactured — only recovered from precursor sources. |
| **Precursor Crystal** | The Ring intact segments + future alien features | Tier-4+ energy catalyst. Drives high-end shields, sensor arrays, fast-travel mechanics. Same "cannot manufacture" rule. |

Their scarcity is geographic (only at The Ring today) + structural (you can't make more, only find more). This creates a hard ceiling on top-tier production until more precursor content is added.

---

## Full system vision (forward-looking)

Helion will expand outward over multiple phases. Below is the concentric layout we're building toward:

```
Sun (Helion — the system's star)
│
├─ HOT INNER (pre-frost-line)
│  ├─ Avernus (lava world)     ← AUTHORED
│  └─ Aridus (arid world)      ← AUTHORED
│
├─ INNER MAIN BELT (pre-frost-line, dry rocky)
│  ├─ Belt_Vesperion_Outer     ← AUTHORED (r=7000–9000)
│  └─ Named asteroids inside the belt  ← AUTHORED (visual only)
│        Castor / Pollux / Latro / Praedo / Cautes /
│        Custos / Petra / Speculum / Vallum
│
├─ GOLDILOCKS ZONE (frost-line crossing)    ← FUTURE
│  ├─ Terrestrial planet(s) with liquid water + atmosphere
│  ├─ Moons of those planets
│  └─ Possible terrestrial moons of the gas giants
│
├─ GAS GIANT REGION (post-frost-line)        ← FUTURE
│  ├─ Gas giant(s) with atmosphere scoops
│  ├─ Saturn-style ring(s) — narrow ice/dust belt
│  ├─ Moons of the gas giants (some ice, some rocky)
│  └─ Trojan-clusters in Lagrange points (optional design)
│
└─ OUTER COLD (deep post-frost-line)         ← FUTURE
   ├─ Outer ice belt (water_ice, methane, nitrogen)
   ├─ Cold-trapped named asteroids (helium-3 concentrations)
   └─ Kuiper-like scattered bodies (long-period orbits)
```

Jump gates link these regions per the dynamic bubble-radius network ([`world_sector_map.md`](./world_sector_map.md) — Jump gate authoring canon). Most gates are short-window connections; a few stable pairs anchor reliable trade routes. **Outlaw belters and pirates concentrate in the Main Belt + outer cold** because faction patrols thin out away from the inner system.

---

## Resource → location matrix

What goes where. Materials follow canon from [`../economy/economy_alchemy_tech_tree.md`](../economy/economy_alchemy_tech_tree.md). Columns ordered inner → outer + special features.

| Resource | Avernus | Avernus moons | Aridus | Main Belt | The Ring (Castor) | Praedo | Wanderers | Goldilocks (future) | Gas Giants (future) | Outer Cold (future) |
|---|---|---|---|---|---|---|---|---|---|---|
| **Iron** | trace | — | common (hematite) | **primary** (Cratered/Holed common) | — | — | varies | trace surface | — | rare (cold metals) |
| **Copper** | — | — | uncommon (oxide) | **primary** (Mineral common) | — | — | varies | trace | — | — |
| **Titanium** | — | — | **primary** (rutile sand) | **primary** (Mineral common) | — | — | varies | — | — | — |
| **Nickel** | trace | — | — | **primary** (Cratered common) | — | — | varies | — | — | — |
| **Cobalt** | — | — | — | **primary** (Mineral common) | — | — | varies | — | — | — |
| **Lithium** | — | — | **primary** (evaporites) | rare (Crystal) | — | — | varies | — | — | — |
| **Tungsten** | **primary** (refractory) | — | — | rare (Glowing) | — | — | varies | — | — | — |
| **Uranium** | **rare/hazard** | trace ash | — | — | — | — | varies | — | — | rare (cold-trapped) |
| **Silicates** | — | **primary** (Cinis — volcanic glass) | **primary (bulk)** (sand) | common (Holed) | — | — | varies | trace | — | — |
| **Sulfur** | **primary (bulk)** | trace (Scoria-heavy) | — | uncommon (Organic) | — | — | varies | — | — | — |
| **Carbon** | — | **primary** (Fumus — graphite) | — | uncommon (Organic/Soft) | — | — | varies | trace (biological) | — | frozen organics |
| **Helium-3** | trace (mantle outgas) | — | — | rare (Glowing) | — | — | varies (cold-origin wanderers carry) | — | **primary** (atmosphere) | **primary** (cold trap) |
| **Hydrogen** | — | — | — | — | — | — | — | trace | **primary** (atmosphere) | — |
| **Nitrogen** | — | — | — | — | — | — | — | atmosphere | trace | uncommon (Ice_Spikey) |
| **Xenon** | — | — | — | — | — | — | — | — | trace | **rare** (cold-trapped) |
| **Neon** | — | — | — | — | — | — | — | — | trace | **rare** (cold-trapped) |
| **Methane** | — | — | — | — | — | — | — | trace | **primary** (atmosphere) | uncommon (Ice) |
| **Water Ice** | ✗ (sublimes) | ✗ | ✗ | ✗ | — | — | varies | **primary** (liquid water) | ring ice | **primary** (Ice family common) |
| **Ammonia** | ✗ | ✗ | ✗ | — | — | — | — | — | atmosphere scoop | frozen |
| **Gold** | rare (hydrothermal) | — | rare (placer) | trace | — | — | varies | — | — | — |
| **Silver** | rare (hydrothermal) | — | rare (placer) | trace | — | — | varies | — | — | — |
| **Scrap Metal** | — | — | — | — | — | — | — | — | — | — (PvP / salvage, not geography) |
| **Ancient Alloy** *(new)* | — | — | — | — | **primary** (Ring debris + intact segments) | — | — | — | — | rare (Hollow/Dyson Moon future) |
| **Precursor Crystal** *(new)* | — | — | — | — | **primary** (Ring intact segments) | — | — | — | — | rare (future alien content) |

Legend: ✓ / primary / common / uncommon / rare / trace / — (not present) / ✗ (unstable — sublimes or decays here).

**Helium-3 special case:** appears in 4+ geographic sources via different mechanisms. Intentional — it's the canon "exotic" resource that drives multiple gameplay loops (precious mining in the Main Belt, atmosphere scooping at gas giants, cold-trap mining in the deep outer system, occasional wanderer cargo). Each source has a different yield + risk profile.

**Wanderers column = "varies"** because each wandering body carries the resource mix of its orbital origin zone, not the zone it's currently passing through. A wanderer is a delivery vehicle, not a geography.

---

## Extraction channels — schemas + status

| Channel | Schema today | Status |
|---|---|---|
| **Belt mining (Main Belt)** | `MacroAsteroidBelt` + `AsteroidCategorySchema` w/ `defaultBeltWeight` | ✅ AUTHORED Phase 6.8.B |
| **Belt mining (Outer ice belt)** | Same schemas; new `AsteroidBelt` registry child | 📋 PLANNED — same pattern, different categories + position |
| **Named asteroid composition** | None — named asteroids are bare `CelestialParentRecord` today | 📋 PLANNED — needs new field on parent record OR a separate "MineableComposition" SO referenced by the parent |
| **Gas scoop (atmosphere)** | None | 📋 PLANNED — new `GasReservoir` schema per gas planet; new `GasScoop` ship module |
| **Planet rings** | Mechanically a `MacroAsteroidBelt` orbiting the planet | ✅ Pattern supported (just author the registry record); 📋 not yet authored |
| **Planet surface extraction** | Drone-gather MVP + record-driven deposit nodes per [`world_surface_gathering.md`](./world_surface_gathering.md); surface bases 3D-placed at lat/lon in Scene 3 ([`world_surface_scene.md`](world_surface_scene.md)); `BaseNoiseEmitter` radar-stealth tradeoff. **Cap A−; drone = no-discovery, future miner path = discovery.** | 📋 PLANNED — drone-gather loop is the near-term build (Phase 6.9.I) |

---

## Expansion phases

Phased rollout. Each phase adds geography + the schemas/mechanics needed to support it. Pair each phase with the relevant entry in [`../meta/master_to_do.md`](../meta/master_to_do.md).

### Phase A — Main Belt composition lockdown (NEAR-TERM)
- Trim `Belt_Vesperion_Outer` categories to remove ice families (Ice + Ice_Spikey). Keep 8 of 10.
- Confirm rarity tiers per Phase 6.8.B (Crystal/Crystal_Spikey/Glowing rare; Organic uncommon; commons unchanged).
- **Status:** Categories tuned + ice still included as of 2026-05-17. Trim is the next concrete step.

### Phase B — Inner-system surface extraction (NEAR-TERM)
- Avernus + Avernus moons + Aridus surface mining mechanic. Tied to Phase 6.8 base-building.
- Surface bases on each body produce the canonical signature resources per "Inner system economic identity" above.
- Hazard tag on Avernus uranium extraction.
- **Mechanic canon:** the gathering loop, the on-planet **A− cap**, and the **drone-gather (now) / miner-scan (future)** split are specified in [`world_surface_gathering.md`](./world_surface_gathering.md). Drone-gather MVP is tracked as Phase 6.9.I.
- **Status:** Signature resource sets locked. Drone-gather loop design locked 2026-06-07; build pending.

### Phase C — Named features authoring (NEAR-TERM)
- **The Ring authoring:** ring-style debris band around Castor + a small number of intact arc segments. Salvage layer (anyone) + interior segments (mid-tier exploration) + central-function reveal (alliance-scale endgame).
- **Praedo pirate stronghold:** hollowed-asteroid interior scene for Outlaw faction hub. Black market terminal, hidden-from-default-scanners flag, alliance-capture mechanic.
- Both depend on registry support for non-belt mineable / explorable features (new field on `CelestialChildRecord` or `CelestialParentRecord`).

### Phase D — Wandering bodies mechanic (NEAR-TERM)
- `MacroEllipticalOrbiter` already exists (used by Praedo). Authoring more wandering bodies + per-wanderer composition (carry origin-zone resources) is the design lock here.
- Schema: per-wanderer composition payload. Could be a new `CompositionSchema` SO referenced from the parent record OR a parallel-field set on the parent record.
- Pair with the named-asteroid composition schema (one mechanism serves both).

### Phase E — Named asteroid composition (NEAR-TERM)
- Per-named-asteroid hand-tuned material lists (Castor, Pollux, Latro, etc.).
- Lore-driven assignments — Praedo (pirate stronghold) doesn't need composition (it's a base, not a mining target); Castor hosts The Ring; the others get unique resource personalities.
- Hooks into the mining-op event instance ([`master_to_do.md`](../meta/master_to_do.md) Phase 4.2d).

### Phase F — Goldilocks zone (MEDIUM-TERM)
- Add 1–2 terrestrial planets in the habitable band (post-Main-Belt, pre-frost-line edge).
- Each gets a surface extraction profile (water + carbon + biological materials) tied to Phase 6.8 base-building.
- New moons for those planets per the moon ladder ([`master_to_do.md`](../meta/master_to_do.md) §6.8.A).
- New jump gates linking Main Belt → Goldilocks.

### Phase G — Gas giants + rings (MEDIUM-TERM)
- Add 1–2 gas giants beyond the Goldilocks zone (post-frost-line).
- New mechanic: **atmospheric gas scoop**. New ship module `GasScoop`, new `GasReservoir` schema per planet, new sector-side scoop activity.
- Ringed gas giant: thin `AsteroidBelt` orbiting the planet (Saturn-style), ice-heavy composition.
- Moons of gas giants — some ice, some rocky. Each authored per the named-asteroid composition pattern (Phase E).
- New jump gates linking Goldilocks → gas giants.

### Phase H — Outer cold (FAR-TERM)
- New outer ice belt (r ≈ 15000+ depending on system scale at that point) with Ice + Ice_Spikey families dominating.
- Cold-trapped named asteroids — helium-3 + uranium concentrations.
- Kuiper-style scattered named bodies with very long orbits (visible at SystemView, rare to visit).
- Outer cold is Outlaw territory by default — minimal NPC patrol presence.

### Phase I — Beyond Helion (FAR-FUTURE, post-launch)
- Per the master overview, the **Jump Gate Network is dynamic** ([`world_solar_map.md`](./world_solar_map.md)) — adding more bodies just extends the network.
- Hard limit: float32 world-coordinate precision (~10⁵ units). If the outer reaches push that, the celestial layer adds floating-origin recenter ([`master_to_do.md`](../meta/master_to_do.md) §6.7.C.2 contingency).

---

## Open design decisions

These need Aaron's call as we go:

1. **Single sun or multi-star future?** Helion's "Sun" is just the system's star. Are we ever adding a binary companion? Affects orbit math + frost-line shape.
2. **Goldilocks planet count.** 1 terrestrial (simpler economy) vs 2–3 (more variety, more diplomatic friction). Faction lore choices ride on this.
3. **Gas giant count.** 1 minimum for the gas scoop mechanic to land. 2+ if we want competition for limited gas-scoop sites.
4. **Outer cold gameplay framing.** Is it "Outlaw heartland" (lawless, high-risk, high-reward), "long-haul resource grind" (low-density, requires fleet logistics), or "endgame faction expansion target" (faction NPCs eventually move out there)? Could be all three.
5. **Helium-3 as the "currency" of late-game.** Helium-3 appears in 4+ zones with different mechanics. Should it converge as the universal Tier-3+ catalyst? Or remain four flavors with different downstream chains?
6. **Named asteroid composition format.** Hand-authored on a per-body field, OR keyed via an `AsteroidCompositionSchema` SO that can be re-used (e.g. "platinum bonanza" template for any rare-metal asteroid)? Composition templates make balance changes easier; per-body is more lore-flavored.
7. **The Ring's central function.** Salvage + intact-segment exploration are clear. The "alliance-scale endgame reveal" is open: stable wormhole? Sensor network? Power broadcast that boosts nearby production? An alien AI? Affects late-game gameplay tone.
8. **Ancient Alloy / Precursor Crystal supply cap.** Both are "found, not manufactured." Hard ceiling on supply = scarcity drives all top-tier production. But a single static cap with one Ring source means once cleared, the system stalls. Options: (a) periodic respawn (lore: drift in from other precursor sites); (b) destruction during use (consumed at high-tier crafting); (c) multiple precursor sites (Hollow/Dyson Moon graduate from `future_ideas.md` when needed).
9. **Praedo capture mechanics.** Alliances can capture Praedo from the Outlaws. What happens to the black market when a player alliance owns it — does the alliance gain its tax-free trading privilege, or does the location lose its Outlaw-faction status (no more contraband fence) when an alliance takes over? Affects PvP value.
10. **Wandering body authoring scale.** How many wandering bodies should exist in Helion at one time? 1 (Praedo + maybe Generation Ship) → 5–10 (a meaningful subset) → 20+ (significant gameplay loop)? Affects orbital math performance + how players plan around them.

---

## How this doc gets used

- **Before adding a body:** check the location matrix + extraction-channel table to see what mechanics it needs to support.
- **Before adding a resource:** add a row to the location matrix; pick which zones can produce it + which extraction channels apply.
- **Before tuning rarity:** confirm the geographic + family + grade scarcity dimensions are all in play; don't tune one in isolation.
- **When a new system phase ships:** update the "Current state" section + check off the phase under Expansion phases.

This doc is **canon**, not a wishlist. The Expansion phases section is the *forward plan* — once approved, it becomes the roadmap. Open design decisions get resolved over time and folded back in.
