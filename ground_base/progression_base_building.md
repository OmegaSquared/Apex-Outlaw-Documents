# MMO Base Building & Core Progression

> **Phase 6.9 base placement model (canon as of 2026-05-29):** Bases are placed in real 3D world space inside the **Surface scene (Scene 3)** at their registered (lat, lon) coordinates on the planet's terrain mesh. The old 2D arc-based placement (`MacroSurfaceBasePoi` markers, `PlanetSurfaceBaseSpawner`, planet-rotation-driven view) is **retired**. Bases are **always physically rendered** in 3D — visual scouting can find them. However, their **HUD/minimap markers** are gated by `BaseNoiseEmitter` activity-noise stealth: a base shows up as a marker for an enemy player only when generating noise (smelter, forge, drone build) AND nearby enemy sensors detect it. Silent operations = off radar, NOT invisible. Full canon: [`../world/world_surface_scene.md`](../world/world_surface_scene.md).
>
> **Capital ship surface block** — capital chassis (flagged `canEnterAtmosphere = false`) cannot enter Scene 3; they stay in Low Orbit. So **all base modules below are for non-capital surface bases**. Capital-class facilities (Heavy Shipyard, citadel-scale Aegis) live as orbital structures in Scene 2 instead — see [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md).

## 1. The "Play Your Way" Economy
The game is completely agnostic to how a player earns their money. If a player absolutely hates the "Alchemy Matrix Scanner" mini-game, they never have to touch it. 
- *The Fighter* can hunt bounties, earn Credits, and buy a mathematically perfect `12,345` peak Railgun from the Hub City Market that a Researcher forged.
- *The Miner* can simply crack asteroids and use the raw material profits to buy entire ships off the market.

However, having the raw Credits means nothing if you don't have the **Infrastructure** to support your purchases.

---

## 2. Comprehensive Base Modules (The Progression Gate)
Instead of traditional "Class Levels" (e.g., reaching Level 20 to fly a Frigate), your progression is 100% determined by your **Base Modules**. You cannot buy, build, or field equipment that your personal Command Center (or Alliance Citadel) cannot physically accommodate or power.

### A. Docking & Mooring (Fleet Storage)
You cannot purchase a massive ship if you have nowhere to park it.
- **Internal Launch Pads:** Standard inside the station. Unlocks Interceptors and Heavy Fighters.
- **External Dry Docks:** Unlocks Frigates and Destroyers. Encases the ship in a protected repair scaffolding.
- **Orbital Mooring Tethers:** Cruisers and Dreadnoughts are too massive to physically dock. They must be tethered in zero-G orbit around the base, drawing power from the station via umbilical cords. *Risk:* If the base's Aegis Shield goes down in Null-Sec, tethered Capital ships are sitting ducks.

### B. Heavy Industry (The Builders)
If you rely on the Market, you only need Docks. If you want to *manufacture* your own fleet or sell fully-built ships, you need massive industrial infrastructure.
- **Component Assembler (Level 1-5):** Required to forge weapons, reactors, and jammers using Alchemy blueprints.
- **The Heavy Shipyard (Macro-Assembler):** Requires thousands of units of Steel, Titanium, and Super-Conductors over a multi-day span. Required to physically build Frigate and Cruiser hulls from scratch.
- **Smelters & Refineries:** Process raw asteroid ore into usable components directly at your base, completely bypassing the 35% Federation Hub tax.

### C. The Power Grid (Base Management)
A Base is constrained by its Total Power Output (`Capacitor Grid`). You cannot run every module at Level 5 simultaneously at the start.
- **Fusion Reactor (Level 1-3):** Basic base power.
- **Antimatter Core (Level 5):** Endgame base power. 
- *Routing Logic:* A solo player might aggressively route all Base Power to their `Heavy Shipyard` to finish a Frigate build in 12 hours, but doing so forces them to power down their `Orbital Mooring Tethers`, leaving them vulnerable to attack.

### D. Defensive Operations
For players building Citadels in Null-Sec (The Outlaw Rim), Federation Police will not save you.
- **Automated Flak / Torpedo Batteries:** Defend the orbital space around the base while the player is offline.
- **E-War Obfuscators (Jammers):** Scrambles the radar signature of the base so Pirates scanning the sector cannot easily pinpoint your coordinates.
- **Aegis Shield Generator:** Projects a massive protective dome over the station and any tethered Capital ships. Draws immense Reactor power.

### E. Intelligence & Storage
- **Storage Vaults / Cryo-Silos:** Expand base inventory limits. Cryo-silos (Level 3+) are required to safely store volatile Tier 3 materials (like High-Velocity Plasma) before they degrade. At Level 5, Vaults hold enough inventory for players to actively manipulate Hub City market scarcity.
- **Comms Array (Sub-Space Relay):** Allows the player to remotely view the Market Tickers of Hubs 5 jumps away, planning massive trade routes without flying blindly into volatile sectors.

### F. The Laboratory (For the Researchers)
If a player *chooses* the Alchemy path, they must upgrade their lab to synthesize higher tiers.
- **Lab Lvl 1 (Foundry):** Can melt Tier 1 elements into Steel.
- **Lab Lvl 3 (Cryo-Physics Lab):** Required to handle Nitrogen and Helium for Tier 3 components.
- **Lab Lvl 5 (Singularity Chamber):** Illegal in Federation space; required to synthesize Tier 4 Dark Matter items.

---

## 3. Maintenance & The Money Sink
Bases require continuous upkeep (Energy and Credits) relative to their size. 
- A fully maxed-out pirate who owns an Orbital Mooring, an Antimatter Core, and a Fleet of Cruisers must constantly hunt bounties or steal cargo to pay their weekly Base Maintenance. 
- If maintenance fails, Base Modules automatically shut down. The player cannot launch their Cruiser or build ships until they pay their debts, creating a dynamic, self-balancing economy.

---

## 4. Module Catalog & Consolidation

The `Assets/GameData/Bases/Modules/T1/` folder currently holds ~156 ScriptableObjects — a mix of true gameplay modules, door-state variants of the same module, turret pieces (body + barrel) authored separately, cosmetic billboards, and generic mesh fragments that belong to chassis-builder source pools. Before the build-cost + tech-tree wire-up (Phase 6.10) we collapse this to a canonical buildable set.

### 4.A Merge rules

**1. Door-state variants → one asset + `doorState` field.** Hangars with separate `*Module` / `*ModuleAnimated` / `*ForceField` SOs are the same module in different mesh states. Merge with a new `FacilityModuleSchema` field:

```csharp
public enum DoorState { None, Closed, Open, Animated }
public DoorState doorState = DoorState.None;
```

- `FighterHangarModule` + `FighterHangarModuleAnimated` + `FighterHangarForceField` → **1 asset**.
- `FrigateHangarModule` + `FrigateHangarDoorLower` + `FrigateHangarDoorUpper` + `FrigateHangarDoorAnimated` → **1 asset**.
- `MS2_Hangars_red` stays separate if visually distinct.

**2. Turret Body + Barrel splits → one turret per MK with variant fields.** `StationTurretMKI/II/III` each have separate `*Body` SOs and three `*Barrel*` variants (Static / Animated1 / Animated2). They're not independently buildable — body needs a barrel and vice versa. Merge to one asset per MK:

```csharp
public enum BarrelArmament { Standard, Missile, Torpedo }
public BarrelArmament barrelArmament = BarrelArmament.Standard;
public bool animatedBarrel = false;
```

- `StationTurretMKI Body` + `*BarrelMinigunStatic` → 1 asset.
- `StationTurretMKII Body` + `*BarrelAnimated1` + `*BarrelAnimated2` → 1 asset.
- `StationTurretMKIII Body` + `*BarrelStatic` + `*BarrelAnimated1` + `*BarrelAnimated2` → 1 asset.
- `StationMissileTurretBarrel` → variant on MKII/MKIII with `barrelArmament = Missile`.
- `StationTorpedoBankx2` / `x3` stay separate (different platform, not just a barrel swap).

**3. Cosmetic decor stays buildable** under a new `BaseModuleCategory.Cosmetic` bucket. Smuggler advertisements, station tops (`Top_*`), crew silhouettes (`CrewPart_*`), `FiveStars`, etc. remain placeable — they're part of the "make my base look how I want" loop. **No power draw, no crew cost, no facility gating** — small material cost only. Move into `T1/Cosmetic/` and tag `category = Cosmetic`.

**4. Generic mesh fragments → not modules.** `IndustrialPart_03/05/06/08/09`, `Farmland2/3`, `Farm1/2/4`, `Hangar_Central_Platform`, `Hangar_Extport_Structure`, `IndustrialSection` and similar are chassis-builder source pieces composed by `BaseChassisSchema`. Move to `Assets/GameData/Bases/ChassisPieces/` and remove from the module pool. If any double as buildable modules, author a proper module SO for that role.

### 4.B Schema additions

```csharp
[Header("Visual variants — multi-mesh modules")]
public DoorState doorState = DoorState.None;
public BarrelArmament barrelArmament = BarrelArmament.Standard;
public bool animatedBarrel = false;
```

```csharp
// in BaseModuleCategory.cs
/// <summary>H — cosmetic decor (billboards, station-top spines, crew silhouettes). No power/crew/gate. Pure flavor + small material cost.</summary>
Cosmetic = 7,
```

### 4.C Post-merge target

Canonical set: ~25–30 buildable gameplay modules across categories A–G, plus ~15–20 Cosmetic items. Authoring pass: copy/rename one canonical SO per merged group, point `prefabAddress` at the existing prefab, set the variant field(s), delete redundants.

---

## 5. Tech Tree & Unlock Gates

Module availability is **hybrid: named prereqs + same-family tier-count**. Mirrors the "based on what is built" progression model — every unlock is observable on the player's base.

### 5.A Schema additions

```csharp
[Header("Tech Tree")]
[Tooltip("Player must have built at least one of EACH listed module before this one unlocks.")]
public List<string> prereqModuleIds = new List<string>();

[Tooltip("Player must also have built this many modules of the same category at the previous tier. Default 2.")]
[Range(0, 10)] public int prereqSameCategoryAtPrevTier = 2;
```

### 5.B Unlock resolver

New service `BaseModuleUnlockResolver` queries the player's `MacroBaseRecord` on the body being built:

```csharp
public UnlockState Resolve(FacilityModuleSchema candidate, MacroBaseRecord baseState);
// UnlockState: Unlocked | LockedMissingPrereq(List<string>) | LockedNeedsMoreTierBelow(int)
```

Called by the build panel on every render (grey/ungrey cards) **and** at placement-confirm time. Server CloudScript runs the identical resolver against the canonical record — don't trust the client.

### 5.C UI contract

Locked modules **always show** in the build panel, greyed, with hover-tooltip listing missing prereqs. Players see the goal. **Do not hide locked content** — that breaks goal visibility and makes the tech tree opaque.

### 5.D Canonical T1 unlock map

**Structural pieces are always available — never gated.** Two asset families sit outside the tech-tree resolver, plus the two intro-delivered foundational pieces:
- **Conduits** ([`BaseConnectorSchema`](../../Assets/Scripts/Schemas/BaseConnectorSchema.cs)) — the structural skeleton modules snap to. Different asset type from modules; never enters the unlock resolver.
- **T1 Outpost chassis** ([`Outpost_Starter.asset`](../../Assets/GameData/Bases/Chassis/Outpost_Starter.asset)) — the player's first chassis. Built and placed by the player during the freighter intro (see § 5.E). Assembled AMINT pieces — landing pad + drone hangar + station body + dock + dock-full-storage + hangar + extport + drone-hangar-doors + two BaseSnapNeck conduits. The Outpost prefab lives at [`Assets/Prefabs/Bases/Chassis/Outpost_Starter/Outpost_Starter.prefab`](../../Assets/Prefabs/Bases/Chassis/Outpost_Starter/Outpost_Starter.prefab).
- **Construction Yard** ([`Construction_Yard_T1.asset`](../../Assets/GameData/Bases/Modules/T1/Construction_Yard_T1.asset)) — the bootstrap industrial module. Built and placed by the player during the freighter intro, right after the Outpost. Once the CY exists, normal drone routing (CY → site) takes over for all subsequent builds. CY has no prereqs.

The unlock map for everything else:

| Module | Prereqs (must have built) | Same-cat at prev tier |
|---|---|---|
| Construction Yard T1 | *(none — placed during intro)* | 0 |
| Fusion Reactor T1 | *(none — starter)* | 0 |
| Bunk Pod T1 | *(none — starter)* | 0 |
| Bulk Storage T1 | *(none — starter)* | 0 |
| Hydroponic Tray T1 | Bunk Pod T1 | 0 |
| Smelter T1 | Fusion Reactor T1 | 0 |
| Component Assembler T1 | Smelter T1 | 0 |
| Light Shipyard T1 | Component Assembler T1, Bulk Storage T1 | 0 |
| Foundry Lab T1 | Smelter T1, Fusion Reactor T1 | 0 |
| Sensor Array T1 | Fusion Reactor T1 | 0 |
| Communication Module T1 | Sensor Array T1 | 0 |
| Flak Battery T1 | Sensor Array T1 | 0 |
| Heavy Turret T1 | Sensor Array T1, Fusion Reactor T1 | 0 |
| Internal Launch Pad T1 | Fusion Reactor T1 | 0 |
| Fighter Hangar T1 | Internal Launch Pad T1 | 0 |
| Frigate Hangar T1 | Fighter Hangar T1, Light Shipyard T1 | 0 |
| Docking Arm T1 | Fighter Hangar T1 | 0 |

**Tier ladder.** To unlock any T(N+1) module, player needs 2× T(N) modules in the same category built and operational, **plus** the named prereqs of the T(N+1) module itself. So unlocking the Antimatter Core T5 means having walked the Power category from T1 through T4 (2× each tier) and met the named requirements at the top.

### 5.E Freighter intro bootstrap

The scene a new player walks into is **empty** — no chassis, no cargo, no drone. The bootstrap is a scripted cinematic the player watches, then participates in:

1. **Freighter arrives.** [`Target_Small_Freighter_MK1`](../../Assets/Prefabs/Hulls/Frieghter/Target_Small_Freighter_MK1.prefab) flies in along a scripted path, decelerates to a hover near the plot.
2. **Loader drone delivers cargo.** [`CB11LoaderDroneMasterPrefab`](../../Assets/Art_Assets/3D_Ships/Assets%20Ships/CivilianFreighterSpaceshipCollection/Prefabs/CB11LoaderDrone/CB11LoaderDroneMasterPrefab.prefab) shuttles between the freighter and the plot, depositing every cargo crate from the freighter pack (~20 `ScifiCargoContainer*` variants) in a grid on the ground.
3. **Freighter departs.** Loader drone returns, both fly off-screen.
4. **Smuggler frigate arrives.** [`Smuggler_Frigate_MK1`](../../Assets/Prefabs/Hulls/Frigate/Smuggler_Frigate_MK1.prefab) flies in, hovers above the plot.
5. **Player's construction drone deploys** from the frigate's hangar.
6. **Player picks where to place the Outpost.** Build panel reveals; player drags the [`Outpost_Starter`](../../Assets/GameData/Bases/Chassis/Outpost_Starter.asset) card onto the plot, clicks to confirm.
7. **Player's drone builds the Outpost.** Existing [`BaseDroneFleet`](../../Assets/Scripts/Macro/BaseDroneFleet.cs) lifecycle consumes pieces from the cargo crates (visual: crates shrink/dissolve as materials are pulled).
8. **Player picks where to place the Construction Yard.** Same flow — drag the `Construction_Yard_T1` card, click to place.
9. **Player's drone builds the CY.** Once the CY exists, normal build mode unlocks (`BaseBuildController.BuildStage = Building`).
10. **Smuggler frigate lands** on the Outpost's landing pad (`station_hangar_centr_platform` child of the Outpost prefab).

After the intro, the player has a working Outpost + CY and can continue with the rest of the T1 ladder (§ 5.F).

**Implementation.** The intro is orchestrated by [`IntroSequence.cs`](../../Assets/Scripts/Macro/IntroSequence.cs), a one-shot MonoBehaviour on a scene GameObject in `Base.unity`. It uses two helper scripts:
- [`CinematicShip.cs`](../../Assets/Scripts/Macro/CinematicShip.cs) — generic scripted-flight (FlyTo / Hover / FollowPath / LandOn). Pure transform interpolation; no physics, no AI.
- [`DeliveryEvent.cs`](../../Assets/Scripts/Macro/DeliveryEvent.cs) — reusable "freighter arrives, loader drone drops cargo, freighter leaves" coroutine. Designed to be invoked recurrently (post-FTUE resupply events use the same component).

**Recurring resupply.** The same `DeliveryEvent` plays whenever the player qualifies for / requests a resupply — the FTUE is just the first instance of the recurring mechanic. Trigger logic (cron-based? on-request? cost-gated?) is a Phase 6.10.+ design item; the system itself is designed reusable from day one.

**Skip on replay.** `IntroSequence` is intended to check a `PlayerProfile.introCompleted` flag at scene start and skip the cinematic if set. Currently a BRIDGE — the flag isn't on PlayerProfile yet, so the intro plays every scene load. Tracked in master_to_do under Phase 6.10.A.

**Cargo crates → ContainerInstance.** The crates delivered by the loader drone are visual scene objects today; the proper Slice-1 inventory wiring (each crate becomes a `ContainerInstance` row owned by the player, written via `cloudscript/inventory.js`) is a BRIDGE per CLAUDE.md "live or tracked" rule — tracked in master_to_do.

### 5.F T1 win condition

**Phase 6.10 / T1 design target: the player can build a Light Ship.** That's the explicit end-state for this design pass. The shortest path from spawn to Light Shipyard operational:

1. Watch freighter intro, place T1 Outpost chassis when prompted (§ 5.E).
2. Place Construction Yard when prompted (§ 5.E).
3. Lay conduits.
4. Build Fusion Reactor T1 (powers everything that follows).
5. Build Bunk Pod T1 (crew for production modules).
6. Build Smelter T1 (refines raw alloys → steel, ferro-titanium).
7. Build Component Assembler T1 (assembles components from refined alloys).
8. Build Light Shipyard T1 (requires Component Assembler T1 + Bulk Storage T1 — the pod's cargo bay satisfies the latter).
9. Queue a Light Ship build.

This 9-step path is the spine the T1 module catalog, costs, and unlock prereqs are tuned around. T2 chassis (HQ) and T2+ modules are deferred — see § 5.G.

### 5.G Out of scope for T1 (forward pointers)

Designed but **not** implemented in Phase 6.10:
- **T2 HQ — a separate second building on the plot, not an in-place upgrade of the T1 Outpost.** The Outpost is the player's first chassis; the HQ is a second chassis placed alongside it (possibly bridged via conduits — TBD). Open design questions deferred until T1 ships: does HQ have its own connector/module slots, or is it a single-purpose structure providing HQ-tier services (capital docking, alliance citadel role, longer mesh-network reach)? Does the player have multiple chassis on a plot once HQ lands, and if so how do they share power/crew/inventory? Authored in a later phase once those questions are decided.
- **T2+ modules** — every module in the canonical catalog has a T2/T3/T4/T5 slot reserved; only T1 is authored for Phase 6.10.
- **External Armor Layer** (§ 7) — design is canon, implementation deferred to **Phase 6.11**. Armor is not required for the T1 win condition, and the Defense category at T1 ships with active turrets only.

---

## 6. Build Resource Costs (Materials)

### 6.A Cost shape

Activate the reserved `buildCost` field on `FacilityModuleSchema` (currently commented out at [`FacilityModuleSchema.cs:78`](../../Assets/Scripts/Schemas/FacilityModuleSchema.cs)):

```csharp
[Header("Build economics")]
public List<RecipeInput> buildCost = new List<RecipeInput>();
```

`RecipeInput.resourceID` references existing `ResourceSchema` assets — there are already 33 authored (Tier-1 raws + Tier-2 refined) per the Slice 2 recipe pass. **No new material types needed** — the mining → refining → building chain reuses the same resource pool the rest of the economy already runs on.

### 6.B Material tier philosophy

- **Conduits / chassis pieces**: raw alloys (iron, aluminum, titanium). Cheap, bulk.
- **T1 Modules**: refined alloys (steel, ferro-titanium, super-conductor) + small qty of components. The Construction Yard can refine raws at build time if the player only has raw mats on hand.
- **T2–T3 Modules**: refined alloys + assembled components (which themselves need a Component Assembler module to forge). This is what makes the tech tree **physical**: you can't build a T2 Heavy Turret without first running a Component Assembler, and that module unlocked at T1.
- **T4–T5 Modules**: rare refined (gold ingot, electrum wire, aerogel mesh) + complex components.
- **Armor plates** (§ 7): same material tiers as defense modules, lighter qty per plate.

### 6.C Cost ladder (rough scale, exact numbers in authoring pass)

| Module class | Raw alloy | Refined alloy | Components |
|---|---|---|---|
| Conduit segment | 50 | — | — |
| T1 Storage / Sensor / Comms | 100 | 30 steel | — |
| T1 Reactor / Smelter / Turret | 200 | 60 steel + 20 ferro-ti | 5 |
| T1 Shipyard / Lab / Heavy Turret | 400 | 100 ferro-ti + 30 super-cond | 15 |
| T2 modules | ~2× T1 | ~2× | ~2× |
| T5 antimatter core | — | rare-only | 100+ |

### 6.D Validation

`BuildCostValidator` runs on placement-confirm:

1. Resolve `buildCost` → required `ResourceSchema` quantities.
2. Read base bulk storage (any installed `G8_Bulk_Storage_T1` instances) for available qty.
3. If satisfied: deduct, mark drone as carrying the load (visual: drone hauls glowing crates scaled to volume), build proceeds.
4. If not satisfied: ghost stays red, "Insufficient materials" tooltip lists shortfall by resource.

Same CloudScript-side check on the server (Double-Schema rule).

---

## 7. External Armor Layer

A new structural-armor system: **angled half-hex plates** that clad the exterior of conduits and modules. **HP-bearing, repairable** — the first system that lets a base meaningfully *absorb* a raid instead of just deflecting it with turrets.

### 7.A Geometry

- **Shape**: angled half-hexagon. One flat edge is the attach face (mates with an `ArmorSocket`); the hex perimeter projects outward at a slight outward angle. Reference silhouette: TIE fighter wing panels.
- **Size**: one plate covers one ArmorSocket. Conduit segment = ~4 sockets per segment (one per exposed side). Large module face = a 2×2 or 3×3 socket grid (4–9 sockets per face).
- **Tiers**: T1 thin plate, T2 layered, T3 composite — same silhouette, different material + emissive color so coverage tier is readable at a glance during raids.

### 7.B Schema

New file: `Assets/Scripts/Schemas/BaseArmorPlateSchema.cs`

```csharp
[CreateAssetMenu(fileName = "New Armor Plate", menuName = "Apex Outlaw/Schemas/Base Armor Plate Schema")]
public class BaseArmorPlateSchema : ScriptableObject
{
    public string plateID;
    public string displayName;
    [TextArea(2, 4)] public string description;
    [Range(1, 3)] public int tier = 1;

    [Header("Combat")]
    public int hp = 500;                          // per plate; tier scales
    public float incomingDamageMultiplier = 1.0f; // T2/T3 plates reduce incoming
    public float repairTimeSeconds = 30f;

    [Header("Build")]
    public List<RecipeInput> buildCost = new List<RecipeInput>();
    public List<RecipeInput> repairCost = new List<RecipeInput>(); // typically ~30% of build

    [Header("Visual")]
    public string prefabAddress;
    public float placementScale = 1f;
}
```

### 7.C ArmorSocket discovery

A new socket type — **separate** from `ConnectorEndpoint` so modules can be placed bare without armor:

```csharp
public class ArmorSocket : MonoBehaviour
{
    public string socketId;
    public float plateScale = 1f;
    [HideInInspector] public BaseArmorPlateSchema installedPlate;
    [HideInInspector] public GameObject installedPlateInstance;
}
```

Editor utility `BaseArmorSocketBuilder` (mirror of [`BaseSnapNeckBuilder.cs`](../../Assets/Editor/BaseSnapNeckBuilder.cs)) tiles `ArmorSocket` GameObjects across the exterior faces of every module/conduit prefab. Faces detected from mesh normals pointing outward; the tiler walks each face and places sockets on a regular grid sized to the plate's footprint.

### 7.D Placement flow

Build panel → **Armor tab** → pick tier → click a module or conduit exterior face. **The whole face auto-conforms**: every ArmorSocket on that face gets a ghost plate, click again to confirm, drones deliver and install plate-by-plate via the existing `BaseDroneFleet` pipeline. (Per-plate manual placement is a follow-up only if needed — auto-conform is the default and the only path Phase 6.10 ships.)

A "Strip armor" action removes plates from a face and refunds materials at 50% recovery.

### 7.E Combat damage routing

When a base module takes incoming combat damage:

1. Server queries `ArmorSocket` instances on the targeted module's faces.
2. If plates exist with HP > 0: damage routes to the nearest plate (along the incoming hit vector), drains `currentHp`, applies `incomingDamageMultiplier`.
3. When a plate's `currentHp` hits 0: plate destroyed, visual debris, exposes the module face behind it.
4. Damage that exceeds remaining plate HP overflows into the module HP itself.

(Implementation crosses into the Fusion combat layer when raid encounters are wired — out of scope for this doc; canon for combat damage routing lives in [`../combat/combat_damage_aggro.md`](../combat/combat_damage_aggro.md). This section defines the *base side* of the contract.)

### 7.F Repair

Destroyed plates rebuild via the existing `BaseDroneFleet` lifecycle: drone launches from CY → fabricates plate → carries to site → installs. Out-of-combat repair runs at `repairTimeSeconds` per plate (~30s default). In-combat repair is suppressed — drones don't fly during a live raid; they queue and dispatch once the encounter ends.

### 7.G Unlock gating

- **Armor T1**: unlocked when player has built 1× any Defense module.
- **Armor T2**: requires 2× Defense modules built at T1.
- **Armor T3**: requires 2× Defense modules built at T2.

Armor is intentionally locked behind the Defense category — players who go pure-economy don't get armor "for free." Defense investment buys both active turrets *and* the passive armor that protects the rest of the base.

---

## 8. Surface Build Interaction — Build Levels & View Culling (Floor Peel)

The surface tile builder ([`SurfaceTilePlacer.cs`](../../Assets/Scripts/Macro/SurfaceBase/SurfaceTilePlacer.cs)) builds in real 3D across stacked **levels**:

- **Build level control** — **Shift+W raises**, **Shift+S lowers** the active level (`currentBuildLayer`). L0 = surface; clamped to `[MinBuildLayer (−10), ∞)` so players can terrace *down* into the ground as well as up. The active level forces which layer square foundations land on and where the anchor's dashed grid guide is drawn.
- **View culling (floor peel)** *(Phase 6.12 prerequisite)* — when the active level changes, **all structure strictly above it hides** (Sims/RTS cutaway), restored as the level is raised back up. This is tied directly to `currentBuildLayer` (no separate "view level"). Every placed tile is its own GameObject under the base anchor carrying `layer` + `schema.role` ([`BaseTileInstance.cs`](../../Assets/Scripts/Macro/SurfaceBase/BaseTileInstance.cs)), so the peel is a visibility toggle over `layer > currentBuildLayer` — not a new subsystem (a small `SurfaceBaseLevelView` helper subscribing to the level change).

**Why:** multi-level bases bury lower floors (and anything routed along them — see the wire/conduit system, [`progression_wiring.md`](progression_wiring.md)) under the floors above. Peeling to the active level gives a clean birds-eye sightline to build, inspect, and wire the level you're on. General builder QoL; first *required* by Phase 6.12 wiring.

Scene/camera canon for the surface build view: [`../world/world_surface_scene.md`](../world/world_surface_scene.md).

---
