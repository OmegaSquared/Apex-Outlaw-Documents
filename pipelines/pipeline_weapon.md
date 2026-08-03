# Weapon Pipeline

**Status: Partial** — schema exists, several weapon classes documented in canon, but no instance assets authored yet (Phase 4 combat hasn't landed). The full pipeline (setup scripts for weapon hardpoint prefabs, projectile prefabs, ammo schemas, per-shot effects) is not yet codified.

**Schemas:** [`WeaponSchema`](../../Assets/Scripts/Schemas/WeaponSchema.cs) (primary weapon archetypes — kinetic, energy, missile, etc.) and the planned `AmmunitionSchema` (consumable ammo for missile / mass-driver / interceptor / etc.).

**Storage:** `Assets/GameData/Weapons/` for schemas; `Assets/Prefabs/Weapons/<Family>/<WeaponName>.prefab` for the visual hardpoint prefabs; `Assets/Prefabs/Projectiles/` for projectile / VFX prefabs.

**Pipeline gaps to close (when this is filled out):**
- Single setup-script template per weapon family (hardpoint prefab + projectile prefab + schema + ammo schema if applicable)
- Catalog consumption — Shipyard, hardpoint UI, and combat all need to read weapons from the same auto-discovery catalog
- Hardpoint snap geometry (which sockets a weapon fits, kind / size match)
- Per-weapon projectile spawn point + recoil + audio + muzzle flash hookup
- Ammo consumption flow (`ammoSchema` reference + per-shot decrement against ship's stackable inventory)

**Canon to fold in when this doc is filled:** [`../ships/ships_weapon_schema.md`](../ships/ships_weapon_schema.md), [`../ships/ships_weapons_armaments.md`](../ships/ships_weapons_armaments.md) (long catalog of every weapon class with doctrinal notes).

**Author this pipeline doc fully before:** the Phase 4 combat ramp — authoring weapon instances without a pipeline doc will compound into the same ad-hoc-content debt this rule exists to prevent.
