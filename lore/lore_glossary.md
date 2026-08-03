---
status: draft
canon: false
last-reviewed: 2026-06-12
tags: [lore, glossary, naming]
---

# Lore Glossary — name → mechanical role

The single place to look when a **name's fiction** changes. Each proper noun below has a stable
**mechanical role** (often a code identifier) and a **fiction** that is draft and can change.

> **Reminder:** changing the *fiction* of a name (what Concordia is like, why ICE exists) is a
> lore edit — do it here / in the story bible. Changing the *name itself* is a **code rename**
> (faction-id strings, `Helion*` scripts, scene assets) and must be tracked as a separate task,
> because the name is baked into the build. Precedent: the Federation was briefly "PACT" then
> reverted to "FED" — `FactionId.Normalize()` still carries the migration shim.

## Factions

| Name | Mechanical role (stable) | Fiction (draft) |
|---|---|---|
| **FED** / Federation | `FactionId.Federation = "FED"` (owner id). Legacy `"PACT"` normalized to this. | The warden beyond the gate: Sol's overpopulated home government; runs the Custos Gateway and exiles people to Helion; thin in-system presence (Concordia = customs/processing); 35% hub tax on the resource flow back to Sol. |
| **ICE** / Iron Core (Empire) | `FactionId.IronCoreEmpire = "ICE"` (owner id). | Renegade exiles who organized, armed up, and seized de-facto control of the colony — the inmates who run the prison. Stronghold Ferrum / Civitas Ferri. |
| **Outlaw(s)** | Owner-id `"Outlaw"`; the non-aligned third pole; also the product name (*Apex Outlaw*). | The twice-cast-out: exiles who kneel to neither FED nor ICE. Belters, smugglers, pirates in the deep belts. |
| Player alliance | Owner id = alliance UUID. A faction *is* an alliance run by AI; same one-field `ownerId` ownership model. | — |

## Places / bodies

| Name | Mechanical role (stable) | Fiction (draft) |
|---|---|---|
| **Helion** | The star system. Baked into `Helion*` scripts (`HelionCalendar`, `HelionClockHUD`, `HelionCameraController`, `HelionViewModeController`, …). | The empty frontier system FED colonizes-and-imprisons through the Custos Gateway — the game world. **Sol / Earth** is the named, overpopulated *origin* you were exiled from (off-screen). |
| **Concordia** | FED home body / inner-system hub cluster (registry entity). | FED's customs & exile-processing station — its foothold at the receiving end of the gate. |
| **Ferrum** | ICE home body (registry entity). | ICE stronghold; first exile-built foundry world; capital Civitas Ferri. |
| **Discordia** | Contested middle planet (registry entity). | War staging ground; moons Bellum (ICE) vs Pax (FED). |
| **Vesperion** | Sector / scene entity (appears in 30+ scripts). | — (sector flavor TBD). |
| **Alythar** | Planet / scene entity (`PlanetTest_Alythar.unity`; 15+ scripts). | — (planet flavor TBD). |
| Latro, Praedo, deep belts | Outer-system bodies / Outlaw citadel locations (registry entities). | Lawless belt hideouts. |
| Castor & Pollux | Jump-gate entities with effectively-permanent bonds. | Twin asteroids; ancient precursor gate-network anchors. |
| **Custos Gateway** | Largest jump-gate entity; effectively-permanent outer-system anchor (8,500-unit bubble). | **The great FED-controlled door linking Sol ↔ Helion** — the exile gate, opened only on FED's schedule (its periodic cycling is the in-fiction reason new players/resources enter). `custos` = Latin "warden." Also an in-system network anchor. |

## Concepts (pure fiction wrapping a real mechanic)

| Name | Mechanical role (stable) | Fiction (draft) |
|---|---|---|
| **Quantum Resonance / Player Seed / the "12,345" peak** | The alchemy / extraction-quality mechanic (`economy/economy_alchemy_research.md`). | In-universe reason ore quality is per-pilot. |
| **Gravity Exodus** *(retired premise)* | Worldbuilding only — still backs the "don't build on deep gravity wells" placement rule. | **Superseded 2026-06-22.** Was "the migration off the homeworld." New premise: Sol is overpopulated and Helion is a penal-colony frontier (story bible §1). The deep-gravity-well building rule survives on its own physics rationale. |
| **Helion Standard Time (HST) / Post-Expedition (PE)** | Pure relabeling of `CelestialClock` (fixed UTC epoch). `HelionCalendar` does the math. | In-fiction calendar (24h day, 36-day cycle, 360-day year). **PE now counts from the first exile fleet's arrival (Year 0)**; present ≈ early single-digit years (a young frontier). Abbreviation "PE" unchanged. |
| **Jump Gate Network / Tide Charts** | `JumpGateNetwork.BubbleReaches` + `PredictDisconnectSeconds` — deterministic per-frame connectivity from orbital positions. | Ancient precursor rings; "tide charts" = route predictions. |
| **Golden Logic** | The Outlaw repair-recipe / wreck-market economy (`economy_alchemy_research.md` §4). | Misnomer from early-access lore (see `lore_world_framing.md`). |
