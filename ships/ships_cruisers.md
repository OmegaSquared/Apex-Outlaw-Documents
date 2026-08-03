# Ship Module, Hardpoint & Power Reference

How **any** ship (Corvette → Dreadnought) is assembled from **modules**, what **hardpoints** each module carries, and how **power** is the currency that balances the whole build. The architecture here is class-agnostic — it applies to every hull; the worked example happens to be a Corvette. This is the parts-assembly source of truth for the NPC_ShipBuilder authoring flow and the player ship builder — the doctrinal class taxonomy lives in [`ships_class_index.md`](./ships_class_index.md), hull numbers in [`ships_hulls_classes.md`](./ships_hulls_classes.md), the manufacturing pipeline in [`ships_manufacturing.md`](./ships_manufacturing.md), and weapon/fitting definitions in [`ships_weapons_armaments.md`](./ships_weapons_armaments.md).

> Status: design canon, actively being authored. The worked example — the **Smuggler Marauder** — is being cut from `SM7_Destroyer.FBX` into modules now (class TBD; the mesh is destroyer-sized). The player's first true combat ship is a **Corvette** — the smallest FTL-capable warship, per [`ships_class_index.md`](./ships_class_index.md#corvette). Schema backing is [`ShipPartSchema`](../../Assets/Scripts/Schemas/ShipPartSchema.cs).

---

## 1. The Three-Layer Model

A cruiser is built in three nested layers. Keeping them distinct is what makes "any medium turret fits any medium turret hardpoint" work.

| Layer | What it is | Schema |
|---|---|---|
| **Module** | A large structural part an admin/player bolts onto the ship — a side wing, a hull extension, a sensor array. Carries armor, mass, a power draw, and **provides hardpoints**. | `ShipPartSchema` (one per module), `ShipPartClass` enum |
| **Hardpoint** | A typed, **sized** socket on a module — a Medium turret mount, an Engine mount, a Sensor mount, a Missile tube. The module declares how many of each it provides. | `ShipPartSchema.providedSockets` (`FittingSocketClass` + count + size) |
| **Fitting** | The actual module that plugs into a hardpoint — a specific medium turret, an engine, a radar, a missile launcher. Draws power. | `WeaponSchema` / `EngineSchema` / `SensorSchema` / `ThrusterSchema` |

So: **modules are assembled into the ship; hardpoints are the slots they expose; fittings are what the player drops into those slots.** A module can also be *purely structural* (armor with no hardpoints) — it just adds HP and mass.

---

## 2. Power Is the Balance Currency — One Pool, Allocated Per Node

There is **one energy pool** for the entire ship, and the player **allocates it across every individual powered node**.

- The **main hull (Midframe)** carries the ship's one and only **reactor** — the `PowerCore` socket. There is **exactly one PowerCore per ship** ([`ShipPartSchema.cs`](../../Assets/Scripts/Schemas/ShipPartSchema.cs) `FittingSocketClass.PowerCore`). Its output is the **single pool** — the total energy budget for the whole hull.
- **Every fitted node draws from that one pool independently.** Not per-module — per *node*. A fully-kitted Marauder with **eight separate engines** exposes **eight engine nodes**, each individually allocated. Likewise **each individual turret**, the **shield**, the **radar**, the **sonar**, and every other piece of equipment is its own node in the allocation list.
- **A node's performance scales linearly with the power it's given** — 50% power ≈ 50% thrust / fire-rate / shield regen, down to 0 at no power (no hard cutoff). Cut a node to zero and it goes dark (a silent-running smuggler kills engine + radar power to stay quiet — ties into the acoustic-noise model).

### 2.1 Floor + Excess (setup floor, live excess)

Allocation is split into a pre-fight **floor** and an in-combat **excess** — one dial that spans "set-and-forget" to "micro everything," with no separate modes.

- **Setup phase — floors.** The player sets a guaranteed **floor** of power per node. Constraint: `sum(floors) ≤ reactor output` (validated at fit time — you can't pre-commit more than you generate).
- **Excess pool.** `excess = reactor output − sum(floors)`. Whatever isn't floored is the live budget.
- **In-flight — 4 sliders.** During combat the player splits the **excess** across four rails — **Engines / Weapons / Shields / Sensors** — in real time. The sliders **partition the excess** (they sum to what's available), so the ship can never draw more than the reactor makes.
- **The spectrum is the whole point.** Floor everything → zero excess → no micro, fully pre-set. Floor nothing (all 0) → the entire reactor is excess → run the whole ship off the four sliders. Any mix in between is the player's call.

**Distribution rules:**

1. **Node live power** = its floor + its share of its rail's excess. Output scales linearly off that total.
2. **Node max cap** — a node absorbs at most its own 100%; overflow spills to siblings in the same rail, or goes unused (no node can eat the whole pool).
3. **Within-rail split** — a rail's excess spreads across its nodes proportional to their floors (setup weighting carries through), falling back to an **even split when a rail's floors are all 0** (the "manage everything live" case).

**Stealth — power touches two of three signature channels:**

1. **Acoustic / engine noise** (passive "sonar") — driven by engine + thruster power. **Power-controlled:** keep engine floors at 0 and only spike them via the slider when you commit, staying quiet otherwise.
2. **Active-radar emission** — running your own active radar broadcasts a ping others can detect. **Power-controlled** via the Sensors rail (turn it down/off to go dark).
3. **Radar cross-section (RCS)** — how much you reflect *someone else's* active radar. **Fixed hull/part geometry** (summed `radarCrossSection`); power allocation does **not** change it. Shrinking RCS needs stealth coating / hull design, not the power dial.

Balancing a ship is therefore a pure **allocation problem against one number**: the reactor's pool has to cover every engine, turret, the shield, radar, sonar, and utility node at once. You can't run all eight engines, both turrets, the shield, and active radar at 100% on one reactor — so you choose. Want everything hot? Fit a bigger-reactor hull or drop nodes. This is the core fun of the builder, and it's continuous (no separate capacitor pool — a single budget keeps the mental model clean).

---

## 3. Cruiser Module Catalog

These are the structural modules a cruiser is assembled from. The first three are your list; the rest are the ones I'd add to round out a complete combat cruiser.

### Core (every cruiser has these)

- **Main Hull / Midframe** — the build anchor. Houses the **reactor (PowerCore)**, the spine all other modules clip onto, and the bulk of structural HP. Often carries a couple of integral hardpoints (the Marauder's **2× Medium turret mounts** live here).
- **Bridge / Command (Cockpit)** — the nose/command section. Defines the ship's **facing** (which way "forward" is — matters for fixed weapons and forward sensor cones) and the crew position. Natural home for an integrated forward sensor if you don't want a separate array.
- **Engines are uniform — mount location does not matter.** A wing-mounted engine and a rear/stern-mounted engine are the **same fitting class** and contribute thrust identically. The ship's total thrust is the sum of **all powered engine nodes**, wherever they sit. This means a Marauder with **just its wings on is already a functional ship** — the wing engines ARE valid propulsion; there is no separate "main drive" class the build depends on. Add more engine nodes (stern block, a second wing pair) and you simply get more thrust — up to eight engine nodes fully kitted.

### Modular (mix-and-match — your three, expanded)

- **Side Wings** *(mirror pair)* — extra armor + extra propulsion, and a mounting surface. **Marauder: each wing provides 2× Medium Engine hardpoints** (so the pair = 4 engine mounts). Can also carry side turret or sensor mounts. Always placed as a left/right mirror pair.
- **Hull Extensions** — bolt-on mid-body sections. Typically **extra cargo/storage** (`cargoCapacityKg`), but can also carry **a turret hardpoint**, an armor belt, or a capacitor bank. The "stretch the hull for more capability at the cost of mass/power" module.
- **Sensor Arrays** — mount **internal sensors**: a **nose radar** (forward-cone, non-turret — concealed, low-signature, you fly the cone) or a **sonar/acoustic** passive scanner (direction-not-distance, fully passive). Omnidirectional 360° radar instead goes on an exposed **turret mount** (longer range, but fragile). Provides `Sensor` hardpoints + an intrinsic `sensorRadius`. See [`combat_fog_of_war.md`](../combat/combat_fog_of_war.md) §"Two physical sensor envelopes."

### Optional combat/utility modules

- **Weapon Module** — a dedicated battery or **spinal mount** for guns bigger than the hull's integral turrets (broadside Large mounts, a fixed forward cannon). Use when the primary armament outclasses the standard medium turret hardpoints.
- **Missile / Ordnance Bay (MissileLauncher)** — belly/spine **missile or torpedo tubes** (`Missile` hardpoints). Turns a cruiser into the [Missile Cruiser](./ships_class_index.md) variant.
- **Bow Module (Utility)** — one bow-mount only: a **ramming/reinforced prow**, **pusher prow**, **crate-push rail**, or **tow** rig. Smuggler/Outlaw flavor.

---

## 4. Hardpoint Sizing

Hardpoints are **sized S / M / L / XL(Capital)** and a fitting can only occupy a hardpoint of its own size or smaller. A Medium turret hardpoint takes any Medium (or Small) turret; it will not take a Large gun. Sizes follow the weapon doctrine in [`ships_weapons_armaments.md`](./ships_weapons_armaments.md) §1:

- **Small** — point-defense, interceptor guns, small sensors.
- **Medium** — the cruiser/frigate backbone (the Marauder's turret hardpoints).
- **Large** — artillery, capital-cracking guns; slow tracking.
- **XL/Capital** — spinal mounts only (dreadnought tier).

> Implementation gap (see §6): `providedSockets` currently stores **class + count** but not **size**. Adding a `size` field to `ProvidedSocket` is what makes "2× Medium turret hardpoints" enforceable.

---

## 5. Worked Example — Smuggler Marauder Cruiser

The player's first true combat ship. A smuggler-built cruiser, cut from `SM7_Destroyer.FBX`. Module breakdown as authored so far:

| Module | Mirror? | Hardpoints provided | Notes |
|---|---|---|---|
| **Main Hull** | no | 2× **Medium turret** mounts; 1× **PowerCore** (reactor) | The spine + reactor. Integral medium turrets. |
| **Side Wing** | yes (L/R pair) | 2× **Medium Engine** mounts each (4 total) | Extra armor + the ship's engines. Cut from the destroyer's wing assembly. |
| **Sensor Array** | TBD | 1× **Sensor** (nose radar / sonar) | Forward-cone internal radar — smuggler "fly the cone" silhouette. |
| **Hull Extension** | TBD | extra storage; optional turret | Smuggler cargo flavor. |
| **Bridge / Main Drive** | TBD | — | To be identified during the cut. |

**Build status:** the side-wing module (2 medium engine mounts, with dual exhaust emitters) was cut and then removed pending this module model; everything else is still being identified piece-by-piece from the FBX. Engines on the wing are **Medium**-class.

---

## 6. Design Decisions

**Decided:**

- **One energy pool, allocated per node** (§2). No separate capacitor pool — a single reactor budget covers every engine, turret, shield, and sensor node.
- **Engines are uniform** (§3). Wing vs. stern is cosmetic; any powered engine node contributes thrust, so a wings-only ship flies.
- **Floor + excess allocation** (§2.1). Setup sets a guaranteed power **floor** per node (`sum(floors) ≤ reactor`); the leftover **excess** is split live in combat across four rails — **Engines / Weapons / Shields / Sensors** — by sliders that partition the excess. Floor-everything = no micro; floor-nothing = full live control. Within a rail, excess splits proportional to floors (even when all floors are 0).
- **Linear scaling.** A node's output scales **linearly** with its total power (floor + excess share): 50% power ≈ 50% thrust / fire-rate / regen, down to 0. No hard cutoff. Node caps at its own 100%; overflow spills to rail siblings.

**Still open:**

1. **Size on hardpoints** — add a `size` (S/M/L/XL) field to `ProvidedSocket` so a module can declare "2× Medium turret mounts" and the builder enforces fit. *Recommended yes — needed before turret hardpoints mean anything.*
2. **Weapons: integral vs. module** — do all guns sit on hardpoints provided by the hull/wings, or do bigger cruisers get a dedicated **weapon/spinal module** for Large guns?
