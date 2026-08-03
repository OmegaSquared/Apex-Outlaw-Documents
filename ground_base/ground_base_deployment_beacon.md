---
status: superseded
phase: 6.9
last-reviewed: 2026-06-11
---

# Base Deployment Beacon — Canon Design

> **SUPERSEDED (Aaron, 2026-06-11) — drone-led base founding.** The beacon-as-consumable
> is retired before being built. Instead, the **ZR7 drone is a permanent HOME card in
> fleet-bar slot 1**: clicking it deselects the fleet (free-roam camera) and jumps to the
> base; double-click tracks it; with **no base**, clicking opens a notification asking
> where to set up the base and leads into site placement, with a pulsing screen-edge
> guide until the site is placed. Implementation: `DroneHomeCard.cs` (DroneCardLink +
> BaseSiteNotification + BaseSetupEdgeGuide), `GlobalFleetRosterFeed` drone card,
> `BeaconBuildGate` (build menu hidden until site/anchor). The freighter starter-kit
> drop below REMAINS the plan, now triggered by site placement instead of a beacon item.
>
> **Claim delivery (Aaron 2026-06-11, final):** claim founds the anchor immediately
> (circle + BASE tab + hidden ZR7) and the player's FRIGATE sets course to hover over the
> site and unload the research drone. Green smoke burns ~5 s → camera takes an
> establishing shot above the player's ship with the GATE in frame → the supply freighter
> (MassiveFreighter, scale 0.016 so one cargo crate ≈ 1.2×3 m = build-grid fit) drops
> THROUGH the gate ring on screen → camera switches to tracking. Flight: 40 u/s (slower
> than the 60 u/s frigate), all wide turns — through ring → cruise altitude → wide arc →
> vertical low approach → hover 45 m. Loader drones peel the crates (space-intro
> choreography); released crates settle under RADIAL GRAVITY onto the terrain. Departure
> mirrors entry: forward out of the base zone → climb to cruise → wide turn → out the
> ring. Temporary **DELIVERY** fleet card while inbound. ~12 min for a 30 km claim is
> accepted pacing. Water clicks never prompt a claim (land only).
> **Protection rule (build after combat wiring):** on a protected planet (faction- or
> alliance-controlled), attacking the delivery freighter is ILLEGAL — triggers a patrol
> response to defend it. Unprotected planets: fair game.
>
> Original spec follows for the starter-kit / claim mechanics that still apply.
>
> **Status: proposed spec (not built).** The single item that starts a surface base. The player deploys a green-smoke **Deployment Beacon** on the planet surface; it establishes the base anchor + buildable claim, summons a freighter that drops a starter kit of materials, and unlocks the build tools. This is the realization of the **Probe / claim item** the surface-tile canon always planned for — see [`../pipelines/pipeline_surface_tile.md`](../pipelines/pipeline_surface_tile.md) §3.6 — and it **retires the "first foundation acts as the probe-stand-in" shim** documented there.
>
> Locked decisions (Aaron, 2026-06-09): one item only (no relocation variant); freighter brings a standard starter kit; beacon is a **carried inventory deployable** (consumed on deploy), not a ship module; authored as a **new `BeaconSchema`**.

## 1. The one item

A **Base Deployment Beacon** — a deployable carried by a fleet. There is exactly one variant. It is **not** a base piece (it doesn't live in the surface build panel) and it is **not** a ship module — it's a consumable deployable in the fleet's cargo, surfaced in the fleet selection bar while flying.

**No relocation variant — by design.** There is no "move an existing base" beacon. To build somewhere new, the player hauls materials to the new site and deploys a fresh beacon there. That friction is the point: it forces players to **physically move materials**, which is what makes the transporter / logistics loop matter (per the economy pillar — Transporters as a player specialization).

## 2. Player flow

1. **Equip** — the beacon sits in the fleet's cargo as a carried deployable.
2. **Fly** — while in flight (sector / planet view), the equipped beacon appears in the **fleet selection bar** ([`FleetRosterHUD`](../../Assets/Scripts/UI/FleetRosterHUD.cs) / the planned Fleet Launcher Dock, [`../meta/master_to_do.md`](../meta/master_to_do.md) 2.5.2).
3. **Select + deploy** — the player picks the beacon and deploys it on the planet surface. A **green smoke** plume marks the site.
4. **Establish** — the deploy point becomes the base **anchor** + **claim disc** (replacing first-foundation-establishes-anchor; see §4).
5. **Resupply** — a freighter flies in and its loader drones drop a **standard starter kit** of material crates at the smoke. Reuses the existing [`DeliveryEvent`](../../Assets/Scripts/Macro/DeliveryEvent.cs) (built for exactly this — "designed for both the FTUE intro and recurring resupply events") + [`StartingCrateLoadout`](../../Assets/Scripts/Macro/StartingCrateLoadout.cs).
6. **Build** — the surface build tools unlock. The HUD nudge flips from "deploy your beacon" → building. Foundations/walls/floors are placed inside the claim and the construction drone builds them from the delivered materials, consuming `buildCost`.
7. The beacon is **consumed** on deploy.

## 3. What it replaces

The surface-tile pipeline currently uses the **first foundation as a probe-stand-in**: the player places a foundation on bare terrain, and that act establishes the anchor + claim ([`../pipelines/pipeline_surface_tile.md`](../pipelines/pipeline_surface_tile.md) §3.1, §3.6). That doc explicitly flagged this as temporary:

> *"The eventual world model: the player drops a dedicated Probe item to claim a region of terrain… The first-foundation-as-probe shim collapses into 'probe placed → spawns anchor' at that point."*

**This beacon is that Probe.** On ship:
- The first-foundation special-casing in [`SurfaceTilePlacer`](../../Assets/Scripts/Macro/SurfaceBase/SurfaceTilePlacer.cs) (the pre-anchor "place a foundation on terrain to establish the anchor" path, the mouse-wheel vertical placement of the first foundation) is retired. Foundations become ordinary in-claim tiles.
- `claimRadiusMetres` moves off the `SurfaceBaseAnchor` BRIDGE onto `BeaconSchema` — resolving the BRIDGE that §3.6 names (*"Replace with `ProbeSchema.claimRadiusMetres` when the Probe schema lands"*). `BeaconSchema` **is** the anticipated `ProbeSchema`.

## 4. Architecture — layer breakdown

The bridge does **not** cross layers as formulas; each layer owns its slice (per [`../architecture/architecture_plan.md`](../architecture/architecture_plan.md) §3.0).

| Layer | Responsibility | Status |
|---|---|---|
| **Macro / PlayFab** | `BeaconSchema` deployable item · carried in fleet cargo (inventory) · deploy dispatch (which body + surface position) | **build** — fleet-equip + server dispatch are `// BRIDGE` until base persistence + auth land |
| **Fleet bar UI** | Equipped-beacon entry in [`FleetRosterHUD`](../../Assets/Scripts/UI/FleetRosterHUD.cs); select → deploy | **build** — extend the existing HUD |
| **Surface scene** | Beacon deploy → establish [`SurfaceBaseAnchor`](../../Assets/Scripts/Macro/SurfaceBase/SurfaceBaseAnchor.cs) + claim → becomes the construction-drone delivery origin → trigger the freighter | **build** — reuses the pre-anchor terrain-placement path; retires first-foundation anchor logic |
| **Freighter + cargo** | Fly in, loader drones drop the starter-kit crates at the smoke site | **reuse** — [`DeliveryEvent`](../../Assets/Scripts/Macro/DeliveryEvent.cs) + [`StartingCrateLoadout`](../../Assets/Scripts/Macro/StartingCrateLoadout.cs) |
| **Green-smoke VFX** | Beacon marker + plume the freighter homes on | **build** — small prefab |

## 5. Data model — `BeaconSchema`

A new ScriptableObject schema (its own authoring pipeline doc, per the schema-driven content rule). Proposed fields:

| Field | Purpose |
|---|---|
| `beaconID` | Stable id. |
| `displayName`, `description` | UI. |
| `prefabAddress` | The deployed beacon prop + green-smoke VFX (Addressable). |
| `claimRadiusMetres` | The buildable claim disc this beacon establishes. **Moved here from the `SurfaceBaseAnchor` BRIDGE** (§3). Default 120 m. |
| `starterKit` | The guaranteed materials the freighter delivers — list of `(resourceID, tons)` + total crate count. Fed to `StartingCrateLoadout` (guaranteed list = **surface starter materials**, *not* the old CY/Outpost set). |
| `massPerUnitKg` | Carried-cargo mass (it lives in the fleet hold). |
| `tier` | Future: bigger beacons = larger claim / richer kit. |

It is **not** a `BaseTileSchema` (it doesn't snap to the grid or appear in the build panel) and **not** a ship module. It's a deployable item in inventory.

## 6. Reuse vs. build vs. bridge

- **Reuse (already built):** `DeliveryEvent` (freighter + loader drones + crate drop), `StartingCrateLoadout` (guaranteed + weighted-random grades), `SurfaceBaseAnchor` / `SurfaceBaseStore` / `SurfaceBaseRenderer` (anchor + claim + record), `FleetRosterHUD` (fleet bar), `CrateInstance` (delivered crate contents).
- **Build new:** `BeaconSchema` + its pipeline doc; the green-smoke beacon prefab; the surface **deploy flow** (place on terrain → establish anchor + claim → spawn smoke → trigger `DeliveryEvent`); the fleet-bar equipped-beacon entry + deploy action; redefine the `StartingCrateLoadout` guaranteed list for surface materials.
- **Bridge (`// BRIDGE: remove when <X> lands`, tracked in [`../meta/master_to_do.md`](../meta/master_to_do.md)):** fleet equip + server-authoritative deploy dispatch are local/stubbed until base persistence + auth ship; starter kit served client-side until the resupply CloudScript handler exists.

## 7. Open questions (resolve at build time)

- ~~Exact inventory mechanism for "carried deployable" — a dedicated deployables slot vs. ordinary cargo with a deploy affordance.~~ **RESOLVED (Aaron, 2026-06-09): ordinary cargo with a deploy affordance.** No new slot taxonomy. The beacon is a normal cargo item (mass counts against the hold); the fleet bar / fleet menu scans the active fleet's cargo for deployables and surfaces a card with a context-gated Deploy action (enabled when the fleet is over a buildable body). Rationale: ships equip modules because modules modify the ship; deployables modify nothing — they're freight with an action. Scales to future deployables (telemetry beacons, depots, mines) without new slots.
- Server-authoritative deploy: which CloudScript handler validates "deploy a beacon on body X at (lat,lon)" and writes the base record.
- Green-smoke VFX source (existing particle asset vs. authored).
- Whether deploy is allowed only on player-territory bodies (per the inhabitable-sectors rule — faction-core + hostile bodies off-limits).

## 8. See also

- [`../pipelines/pipeline_surface_tile.md`](../pipelines/pipeline_surface_tile.md) — the surface tile system this beacon front-ends (§3.1/§3.6 superseded for base start).
- [`ground_base_overview.md`](ground_base_overview.md) — ground-base category home.
- [`../architecture/architecture_plan.md`](../architecture/architecture_plan.md) §3.0 — layer boundaries.
- Code: [`DeliveryEvent`](../../Assets/Scripts/Macro/DeliveryEvent.cs), [`StartingCrateLoadout`](../../Assets/Scripts/Macro/StartingCrateLoadout.cs), [`SurfaceBaseAnchor`](../../Assets/Scripts/Macro/SurfaceBase/SurfaceBaseAnchor.cs), [`SurfaceTilePlacer`](../../Assets/Scripts/Macro/SurfaceBase/SurfaceTilePlacer.cs), [`FleetRosterHUD`](../../Assets/Scripts/UI/FleetRosterHUD.cs).
