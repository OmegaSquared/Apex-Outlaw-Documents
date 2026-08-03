# Ships — Category Overview

This category owns everything that defines the **kit a player flies**: hull schemas, weapon schemas, the ship-class taxonomy, the weapons catalog, and ship AI behavior. It does *not* own combat math (that's [`../combat/`](../combat/combat_overview.md)) or world AI (that's [`../world/world_npc_ai.md`](../world/world_npc_ai.md)).

## The double-schema, applied to ships

Following the architecture rule (see [`../architecture/architecture_plan.md`](../architecture/architecture_plan.md) §4):

- **Static blueprints** (`ShipSchema`, `WeaponSchema`, hull/weapon ScriptableObjects) define *what something is* — base stats, hardpoint counts, mass, mount classes.
- **Per-player instances** (the JSON in PlayFab) store only `ModuleID + ResearchValue + Checksum`. The server recomputes effective stats authoritatively.

When you add a new hull or weapon, **edit the schema first**, then add the ScriptableObject instance. Don't bake balance numbers into combat code.

## Key concepts

- **Hardpoints** are typed mounts (Turret / Internal / Missile / Utility). A hull's silhouette and obstruction limits are part of the schema, not the prefab.
- **Mount classes** govern what fits where — a Capital-class turret won't go on a Frigate slot.
- **Signature** is a hull property that drives minimap visibility and stealth play. See [`../combat/combat_minimap_signatures.md`](../combat/combat_minimap_signatures.md).
- **Ship Class Index** is the doctrinal taxonomy (Probe → Mothership), distinct from raw hull stats — it governs how fleets compose and how alliances think about doctrine.
- **Surface entry eligibility (Phase 6.9 canon)** — `ShipChassisSchema.canEnterAtmosphere` (new bool) gates whether a hull can drop into the Surface scene (Scene 3). **Capital-class ships are flagged `false`** — they stay in Low Orbit (Scene 2) and can never enter Scene 3. Permit-gated transition from Low Orbit → Surface is enforced server-side via `PlanetSurfacePermitCheck`. Canon: [`../world/world_surface_scene.md`](../world/world_surface_scene.md), [`../world/world_low_orbit_scene.md`](../world/world_low_orbit_scene.md).

## Docs in this category

| Doc | Purpose |
|---|---|
| [`ships_schema.md`](./ships_schema.md) | The C# `ShipSchema` struct — hardpoint counts, mass, hull obstruction, signature curves. |
| [`ships_hulls_classes.md`](./ships_hulls_classes.md) | Hull catalog from Interceptor through Dreadnought — base stats, role notes. |
| [`ships_class_index.md`](./ships_class_index.md) | Doctrinal taxonomy — Probe, Frigate, Cruiser, Battleship, Carrier, Mothership, plus stations and the alliance StatCom. |
| [`ships_ai.md`](./ships_ai.md) | NPC ship AI behavior trees — patrol, engage, flee, distress-join window. (See also [`../world/world_npc_ai.md`](../world/world_npc_ai.md) for higher-level NPC doctrine.) |
| [`ships_weapon_schema.md`](./ships_weapon_schema.md) | The C# `WeaponSchema` struct — servo speeds, tracking arcs, cooldowns. |
| [`ships_weapons_armaments.md`](./ships_weapons_armaments.md) | Weapon catalog — Kinetic, Energy, Tactical, and Outlaw weapon families. |

## Where this category sits in the build order
Ship and weapon **schemas** are **Phase 1** ([`meta/meta_roadmap.md`](../meta/meta_roadmap.md)) — they're foundational data shapes the macro UI and combat sim both depend on. Catalog content (hulls, weapons) lands incrementally as combat (Phase 4) needs targets.
