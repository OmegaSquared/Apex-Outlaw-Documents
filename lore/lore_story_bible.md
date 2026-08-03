---
status: draft
canon: false
last-reviewed: 2026-06-22
tags: [lore, narrative]
note: "NON-CANON — narrative / world-fiction, subject to change. Game mechanics do NOT depend on this doc; see lore/README.md."
---

# MMO Lore & Story Bible

> **⚠ Premise rewrite (2026-06-22, Aaron).** The setting pivoted from a centuries-old "Gravity Exodus"
> to a **penal-colony frontier**. Core premise now:
> - **Sol is full.** Earth's home system is catastrophically overpopulated. The Federation (FED) runs it.
> - **Helion is the relief valve.** FED found a fresh, empty star system on the far side of a colossal
>   jump gate and is using it as **two things at once: a colonization expansion and a prison.** Population
>   overflow, debtors, dissidents, convicted criminals, and even petty offenders are loaded onto exile
>   fleets and shipped through the gate to Helion — a one-way ticket, for most.
> - **You are an exile.** The game begins with you being dumped through the gate into an unknown system
>   as a prisoner / outcast. Everyone you meet is some flavor of cast-out.
> - **ICE runs the prison from the inside.** The Iron Core (ICE) are renegade exiles who organized,
>   armed up, and seized de-facto control of Helion and its convict population. FED sends people in;
>   ICE decides what happens to them once they arrive.
> - **The frontier is barely built.** Helion has only been receiving fleets for a few years. There is
>   almost no infrastructure — a handful of foundries, depots, and shanty-hubs thrown together by
>   exiles. *(This is the in-fiction reason the world is sparse: it's new.)*
>
> **What this rewrite does NOT change:** every game *mechanic* and every code-baked *name* stays.
> FED, ICE, Outlaws, Helion, Concordia, Ferrum, Civitas Ferri, the Custos Gateway, the jump-gate
> network, Quantum Resonance / the Player Seed, HST / the PE calendar, hub pricing, sovereignty —
> all intact. Only the *story wrapped around them* changed. See [`README.md`](./README.md).

> **⚠ Three-scene world model (still compatible).** Nothing in this premise depends on the retired
> 2D rotating-planet view. Where the fiction lands in the three-scene model:
> - **The great gate + hyperspace travel** (§5) — Solar map (Scene 1). The **Custos Gateway** (the
>   Sol↔Helion exile gate) and the in-system precursor gate network both live here as fleet routing.
> - **Hubs, depots, ICE foundries, exile shanty-towns** (§1, §3) — sit on bodies, entered via Low
>   Orbit (Scene 2) for capitals and Surface (Scene 3) for ground gameplay.
> - **Outlaw hideouts** (§3.C) — orbital `Citadel` structures at outer bodies, Scene 2, FOW-gated.
>
> Cross-refs: [`world_low_orbit_scene.md`](../world/world_low_orbit_scene.md),
> [`world_surface_scene.md`](../world/world_surface_scene.md).

This document details the narrative history, the current sociopolitical climate of the Helion system,
and the in-universe justification for the game's core mechanics (the Player Seed / Quantum Alchemy,
the Jump Gate Network, the Hub economy, and faction sovereignty).

---

## 1. The Cradle is Full — Why Helion Exists

By the mid-22nd century **Sol — Earth's home system — is choking.** Every viable rock from Mercury to
the Kuiper belt has been settled, strip-mined, and packed past capacity. Orbital habitats stack people
by the million. The **Federation (FED)**, the bureaucratic super-state that governs Sol, spends most of
its budget managing scarcity: housing queues, ration tiers, and an ever-growing prison population it
can no longer afford to hold.

Then FED's deep-survey fleets found the **Custos Gateway** — a colossal, ancient jump ring drifting at
the edge of Sol, far larger than the precursor gates scattered through known space. When FED engineers
finally cycled it, it bridged to a star system no human had ever touched: **Helion.** Empty. Unclaimed.
Resource-rich. A whole frontier on the far side of one gate.

FED's answer to overpopulation wrote itself. Helion would be **both expansion and exile** — a colony to
bleed off Sol's surplus population, and a prison to bleed off its surplus problems. The two policies are
the same pipeline:

- **Colonists** — volunteers, debtors working off passage, families priced out of Sol.
- **Exiles** — convicted criminals, political dissidents, and, as the quotas tightened, people guilty of
  little more than being inconvenient: petty offenders, defaulters, "population-management transfers."

All of them go through the Custos Gateway the same way: loaded onto an exile fleet, run through the
ring, and dropped into Helion with a survival kit and a registry tag. For the vast majority it is a
**one-way trip.** The gate is FED's, and FED only opens it on its own schedule.

> **The frontier is new.** Helion has only been taking fleets for a handful of years. There are no
> great cities yet — just first foundries, salvage depots, and exile shanty-hubs. Everything the
> player sees was thrown together recently, by people who arrived with nothing. *(In-fiction reason
> for the sparse, half-built world: it genuinely is half-built.)*

---

## 2. The Anomaly That Changed the Sentence — "The Quantum Matrix" (the Alchemy Mechanic)

Helion was supposed to be a dumping ground. Then the first exile mining crews discovered why FED's
survey instruments had flagged the system in the first place: **Quantum Resonance.**

- **The Seed:** Every human carries a unique, unalterable biometric resonance frequency — a **Player
  Seed.** When a specific pilot scans a Helion asteroid field, the molecular structure of the ore
  reacts to *their* frequency. Two pilots mining the same rock pull different quality out of it.
- **The "12,345" Anomaly:** Most extracted material is "Junk." But specific coordinates yield
  mathematically perfect structures, peaking at a theoretical purity of `12,345`. The effect is far
  stronger in Helion's untouched belts than anywhere in worked-out Sol.
- **The Inversion:** Overnight, the worthless penal frontier became the most valuable real estate
  humanity had ever found. The most important people in Helion are no longer wardens or officers but
  **"Alchemists"** — exiles who can map their own resonance matrix and synthesize god-tier materials.
  Suddenly a one-way sentence looks like a gold rush.

This is the engine of the whole game: it gives FED a reason to keep the pipeline open (resources flow
*back* through the gate to a starving Sol), it gives ICE a reason to control who mines what, and it
gives every exile a reason to stop being a prisoner and start being a power.

> Mechanics canon: [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md),
> [`../economy/economy_scanning_extraction.md`](../economy/economy_scanning_extraction.md).

### Timekeeping — Helion Standard Time (HST)

The **first exile fleet's arrival** is **Year 0**. Dates in Helion are counted in **Post-Expedition
(PE)** years; the present is the **early single digits PE** — only a few years on the frontier, which
is exactly why so little is built. *(The abbreviation "PE" is unchanged; only what it counts from
changed — see the glossary.)*

Helion keeps **one system-wide clock — Helion Standard Time (HST)** — used everywhere regardless of
which body you stand on. Planets spin at their own rates, so *local* day length varies; the **calendar**
is shared and fixed:

- A **day** = 24 hours.
- A **cycle** (the month unit) = **36 days**.
- A **year** = **10 cycles = 360 days** (≈ one real year).

Dates read **`6 PE · Cycle 4, Day 22 · 14:08`**.

> **Implementation (out-of-fiction).** HST is a pure relabeling of the canonical
> [`CelestialClock`](../../Assets/Scripts/Macro/Celestial/CelestialClock.cs) — a fixed UTC epoch with
> time computed as `UtcNow − epoch` — so it advances 1:1 with real time, is identical for every
> client, and never drifts. `HelionCalendar` does the math; `HelionClockHUD` shows it. The same epoch
> drives planet day/night ([`PlanetDayNightCycle`](../../Assets/Scripts/Macro/PlanetDayNightCycle.cs)).
> Unit lengths (cycle/year) and the displayed epoch are tunable on the HUD.

---

## 3. The Three Powers

> **Ownership / sovereignty mechanics moved.** The canonical ownership model (faction = AI-run
> alliance, one `ownerId` field) and the full sovereignty system are design canon in
> [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) §3. This section
> keeps only the *narrative* of who the three powers are.

### A. FED — Federation (The Warden Beyond the Gate)
- **Seat of power:** **Sol**, the overpopulated home system — and, inside Helion, the customs-and-
  processing station **Concordia**, FED's foothold at the receiving end of the gate.
- **Role:** FED is the authority that *sends you here.* It runs the Custos Gateway, processes every
  inbound fleet, registers every exile's Seed, and skims the resource flow heading back to Sol. It is
  powerful but **thin on the ground** — FED governs the gate and the paperwork, not the surface. Most
  exiles never see a FED officer after processing.
- **Power Structure:** A distant bureaucracy. In Helion it manifests as Concordia's registry, customs
  tariffs (the brutal **35% FED Hub Tax** on anything traded through its sanctioned hubs), and
  periodic FED Police sweeps when something threatens the resource pipeline.
- **Symbology / Color:** FED blue. Faction tag: `[FED]`.
- **Motivation:** Order, registry, and extraction. FED wants Helion to stay productive and quiet —
  enough mining to feed Sol, not enough organization to become a rival. It would rather the colony
  police itself, which is precisely the opening ICE exploited.

### B. ICE — Iron Core (The Inmates Who Took the Prison)
- **Stronghold:** **Ferrum** — an industrial fortress world wreathed in storm clouds; its capital
  **Civitas Ferri** ("Iron State") was the first real city exiles built in Helion, raised around the
  earliest foundries.
- **History:** ICE began as exiles — the same convicts and cast-outs as everyone else. But where
  others scattered, the Iron Core **organized.** They seized the first foundries, armed their
  dockworker crews, and turned industrial output into military power. By the time FED noticed, the
  Iron Core had become the de-facto government of the colony floor: the renegades who **run the prison
  population FED keeps shipping in.**
- **Power Structure:** A ruthless, meritocratic convict-empire. Rank is earned through combat
  proficiency or industrial output; loyalty is enforced. ICE decides which crews mine which belts,
  who eats, and who gets thrown back to the void.
- **Symbology / Color:** Iron-red. Faction tag: `[ICE]`.
- **Motivation:** **Sovereignty.** ICE wants Helion to belong to the people sentenced to it — not to
  the wardens beyond the gate. They tolerate FED's tariffs only as long as they must, stockpiling
  tungsten railguns against the day they can hold the Custos Gateway themselves and stop being a
  colony at all. Their pressure point is the contested middle planet **Discordia**, where their
  garrison moon **Bellum** ("war") shadows FED's toehold moon **Pax** ("peace") in the same orbit.

### C. The Outlaws (The Twice-Cast-Out)
- **Bases:** No homeworld — the Helion belts and outer bodies (Latro, Praedo, the deep belts) shelter
  a constellation of hidden citadels.
- **History:** Exiles who would not kneel to FED *or* ICE. Cast out of Sol, then cast out of the Iron
  Core's order, they live off the grid in the lawless belts — the bottom of a world already made of
  rejects.
- **Power Structure:** Decentralized crews and alliances, surviving by hacking, smuggling, and piracy.
- **Motivation (The Golden Logic):** Locked out of FED's research registries and ICE's foundry
  access, Outlaws survive by interdicting FED and ICE freighters and **Towing** the wrecks to hidden
  Citadels. They strip intact components and pry loose **Repair Recipes** — the maintenance ratios
  that keep stolen masterpieces running forever. They cannot *manufacture* what they steal (that path
  is locked behind the original Researcher's Seed, §2) but a refurbished, immortal hardpoint is the
  next best thing, and it is the entire economic basis of the Outlaw fleet. See
  [`../economy/economy_alchemy_research.md`](../economy/economy_alchemy_research.md) §4 for the
  canonical rule.

---

## 4. Faction Sovereignty, Alliance Claims & Defeat

> **Moved to design canon.** The sovereignty *system* — faction claims (50-member gate, two-way
> defense + tax), planetary-defense defeat, faction respawn, the planet-level 50% control rule,
> residency grandfathering, and the non-member tax ceiling — is canonical mechanics and now lives in
> [`../world/world_faction_sovereignty.md`](../world/world_faction_sovereignty.md) §4. Only the
> fiction stays here: in Helion, "claiming" a body means an alliance holds it against FED's tariff
> reach and ICE's enforcers alike — carving out a patch of the colony that answers to you.

---

## 5. The Jump Gate Network — One Great Door, and a Living Constellation

Travel across Helion on conventional thrusters takes years. Two kinds of gate make the system playable.

**The Custos Gateway — the Door from Sol.** The great ring at Helion's outer rim is the *only* link
back to the home system, and it is **FED's.** It opens on FED's schedule, not yours: every so often it
cycles, and a new exile fleet, a resupply convoy, or a shipment of fresh registry tags comes through —
and a trickle of refined Helion wealth goes back the other way. *(Out-of-fiction: this is the in-world
reason new players and new resources periodically enter the system, and the reason the game world is
effectively bounded by Helion — the door home is rarely open and never yours.)* `custos` is old
Earth-Latin for **warden**; the name was not an accident.

**The in-system network — the precursor gates.** Inside Helion, travel uses an older infrastructure:
colossal ancient rings left by an unknown precursor race, one fixed beside every major body. There is
**no central hub.** Each gate projects an invisible *bubble of reach*; any other gate that drifts inside
that bubble becomes a possible destination. As the bodies orbit, the bubbles sweep and the connectivity
graph **rewrites itself in real time.**

- **Bubble radii vary by body.** Small mining-belt gates reach 1,500–2,500 units; important bodies
  reach further. The Custos Gateway's enormous bubble (8,500 units) also makes it the system's anchor
  hub when geometry aligns, bridging to Glacies and the deep belts.
- **The graph is alive.** A route from Concordia → Bellum that exists now may vanish in thirty minutes
  as Discordia carries the receiving bubble out of reach, then return when the bodies swing back.
  Pilots learn the system's **rhythm** the way old sailors learned tides.
- **A few bonds are effectively permanent.** The twin asteroids **Castor and Pollux** lock in a tight
  binary; their gates reach each other constantly. The Custos Gateway's reach keeps it stably tied to
  several outer anchors regardless of the calendar. These permanent edges are the spine the rest of
  the network bends around.
- **Smuggling and stealth.** FED and ICE post patrols at the gates they care about, but neither can
  lock the network — only ambush it. Outlaws read the gate-rotation tables (or pay Researchers who do)
  and slip distant routes during brief unwatched windows. The black-market **"Tide Charts"** sold in
  Outlaw citadels are exactly that: predictions of when each gate-pair will next be in bubble-range.
- **Implementation reference (out-of-fiction).** This is computed each frame from live planetary
  positions — see [`../architecture/architecture_plan.md`](../architecture/architecture_plan.md) §1.
  The lore wraps a real, deterministic mechanic.

---

## 6. The Player's Journey

You wake up in a transit pod with a registry tag on your wrist and the Custos Gateway shrinking behind
you. Whatever you did back in Sol — a real crime, a political inconvenience, an unpaid debt, or nothing
you'd call a crime at all — the Federation decided you were surplus. Now you're an **exile**, dropped
into Helion with a survival kit, a beat-up ship, and the one thing FED couldn't take: your unique
**Quantum Seed.**

What you make of the sentence is the game:

- Become a legendary **Alchemist**, mapping the perfect `12,345` peaks and selling forged masterworks
  no one else can make — blueprints never trade, only the parts that carry them (destroy one to learn
  it, if its maker didn't sign it) — value the wardens beyond the gate will pay real freedom for.
- Become an industrial **Miner**, chewing through untouched belts and hauling bulk cargo to starving
  hubs for the capital to buy your way up from prisoner to power.
- Become a **Privateer / Outlaw**, hovering at the radar's edge in silicate dust to ambush freighters
  and strip their Golden Logic — answering to no one, FED or ICE.
- Or **swear to a power**: rise through the **Iron Core**, the convicts who took the prison and mean to
  take the gate — or cut a deal with **FED** itself, and become the warden's hand inside the colony.

You came here with nothing, as nothing. Helion doesn't care what you were sentenced for. It only cares
what you build before the next fleet comes through the gate.
