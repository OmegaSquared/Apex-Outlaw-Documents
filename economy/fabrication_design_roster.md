---
status: generated reference
last-generated: 2026-07-14 (rev 4 — post parts-cleanup: turret mounts + cargoship + destroyer retired; reactor/battery models wired; white materials fixed)
---

# Fabrication Design Roster — every design baked into the game, its recipe, and its visual

Auto-extracted from live schemas + verified by rendering (design_roster_contact_sheet.png is rev-2-era; regenerate if needed).
★ = starter knowledge. ✅ real model / ❌ no visual / ⚠️ placeholder.

## Components (from raw materials)

| ID | Name | Recipe (raw materials) | Visual |
|---|---|---|---|
| `comp_control_circuit` ★ | Control Circuit | copper ×2 + silicates ×1 | ✅ prefab |
| `comp_hull_plating` ★ | Hull Plating | iron ×6 + carbon ×2 | ✅ prefab |
| `comp_structural_frame` ★ | Structural Frame | iron ×8 + nickel ×2 | ✅ prefab |

## Structural parts (from components)

| ID | Name | Class/Size | Bill (components) | Visual |
|---|---|---|---|---|
| `battery_large_01` | Battery Mk-L | Battery/Large | control_circuit ×4 | ✅ prefab |
| `battery_medium_01` | Battery Mk-M | Battery/Medium | control_circuit ×3 | ✅ prefab |
| `battery_small_01` | Battery Mk-S | Battery/Small | control_circuit ×2 | ✅ prefab |
| `cargo_hold_internal_01` | Cargo Hold (Physical) | CargoPod/Small | structural_frame ×1 + hull_plating ×2 | ❌ no prefab |
| `corsair_armor_wings` | Iron Core Corsair Armor Wings | Wing/Medium | structural_frame ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `corsair_bottom_engines` | Iron Core Corsair Bottom Engines | EnginePod/Medium | structural_frame ×1 + control_circuit ×1 | ✅ prefab+mirror |
| `corsair_cargo_bays` | Iron Core Corsair Cargo Bays | CargoPod/Medium | structural_frame ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `corsair_front_cannon_mounts` | Iron Core Corsair Front Cannon Mounts | WeaponMount/Medium | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `corsair_front_weapon_hardpoints` | Iron Core Corsair Front Weapon Hardpoints | WeaponMount/Medium | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `corsair_main_hull` | Iron Core Corsair Main Hull | Midframe/Medium | structural_frame ×2 + hull_plating ×2 | ✅ prefab |
| `corsair_small_wings` | Iron Core Corsair Small Wings | Wing/Medium | structural_frame ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `corsair_thrusters` ★ | Iron Core Corsair Thrusters | DriveSection/Medium | structural_frame ×1 + control_circuit ×1 | ✅ prefab+mirror |
| `corsair_top_engines` | Iron Core Corsair Top Engines | EnginePod/Medium | structural_frame ×1 + control_circuit ×1 | ✅ prefab+mirror |
| `drone_constructor_01` | Construction Drone | Drone/Small | structural_frame ×1 + control_circuit ×2 + hull_plating ×1 | ✅ prefab |
| `drone_miner_cb11` | CB11 Loader Drone | Drone/Small | structural_frame ×1 + control_circuit ×1 + hull_plating ×2 | ✅ prefab |
| `drone_ore_gatherer_t1` | Mining Drone T1 | CargoPod/Small | structural_frame ×1 + hull_plating ×1 | ✅ prefab |
| `drone_ore_gatherer_t2` | Mining Drone T2 | CargoPod/Small | structural_frame ×1 + hull_plating ×1 | ✅ prefab |
| `drone_ore_gatherer_t3` | Mining Drone T3 | CargoPod/Small | structural_frame ×1 + hull_plating ×1 | ✅ prefab |
| `drone_ore_gatherer_t4` | Mining Drone T4 | CargoPod/Small | structural_frame ×1 + hull_plating ×1 | ✅ prefab |
| `drone_zr7_research` | ZR7 Research Drone | Drone/Small | structural_frame ×1 + hull_plating ×1 | ✅ prefab [UNIQUE-NEVER-FAB] |
| `gas_tank_internal_01` | Gas Tank | CargoPod/Small | hull_plating ×2 + control_circuit ×1 | ❌ no prefab |
| `marauder_hull` | Marauder Cruiser MK1 | Midframe/Medium | structural_frame ×3 + hull_plating ×3 | ✅ prefab |
| `marauder_hull_ext` | Smuggler Marauder Hull Extension | CargoPod/Medium | structural_frame ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `marauder_rear_engine_bottom` | Smuggler Marauder Rear Engine (Bottom) | EnginePod/Medium | structural_frame ×1 + control_circuit ×1 | ✅ prefab+mirror |
| `marauder_rear_engine_top` | Smuggler Marauder Rear Engine (Top) | EnginePod/Medium | structural_frame ×1 + control_circuit ×1 | ✅ prefab+mirror |
| `marauder_sensor_array` | Marauder Internal Sensor Array | SensorArray/Medium | structural_frame ×1 + control_circuit ×2 | ⚠️ grey-cube placeholder |
| `marauder_wing_engine` | Smuggler Marauder Wing Engine | Wing/Medium | structural_frame ×1 + hull_plating ×1 + control_circuit ×1 | ✅ prefab+mirror |
| `reactor_large_01` | Reactor Mk-L | Reactor/Large | structural_frame ×2 + control_circuit ×4 | ✅ prefab |
| `reactor_medium_01` | Reactor Mk-M | Reactor/Medium | structural_frame ×1 + control_circuit ×3 | ✅ prefab |
| `reactor_small_01` | Reactor Mk-S | Reactor/Small | structural_frame ×1 + control_circuit ×2 | ✅ prefab |
| `scanner_array_01` | Scanner | SensorArray/Small | structural_frame ×1 + control_circuit ×2 | ✅ prefab |
| `shippart_bomber_engine_pod_mk1` | Bomber Engine Pod | EnginePod/Small | structural_frame ×1 + control_circuit ×1 | ✅ prefab+mirror |
| `shippart_bomber_hull_mk1` | Bomber Hull | Midframe/Small | structural_frame ×2 + hull_plating ×2 | ✅ prefab |
| `shippart_bomber_missile_launcher_mk1` | Bomber Missile Launcher | MissileLauncher/Small | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab |
| `shippart_bomber_plasma_cannon_mk1` | Bomber Front Mounted Weapon | WeaponMount/Small | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `shippart_bomber_rear_engine_mk1` | Bomber Rear Engine | EnginePod/Small | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `shippart_bomber_wing_mk1` | Bomber Wing | Wing/Small | structural_frame ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `shippart_fighter_cannon_socket_mk1` | Fighter Front Mounted Weapon | WeaponMount/Small | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `shippart_fighter_engine2_pod_mk1` | Fighter Engine Pod II | EnginePod/Small | structural_frame ×1 + control_circuit ×1 | ✅ prefab+mirror |
| `shippart_fighter_engine_pod_mk1` | Fighter Engine Pod | EnginePod/Small | structural_frame ×1 + control_circuit ×1 | ✅ prefab+mirror |
| `shippart_fighter_hull_mk1` | Fighter Hull | Midframe/Small | structural_frame ×2 + hull_plating ×2 | ✅ prefab |
| `shippart_fighter_wing_mk1` | Fighter Wing | Wing/Small | structural_frame ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `shippart_smuggler_hull_mk1` ★ | Corvette Hull | Midframe/Medium | structural_frame ×2 + hull_plating ×2 | ✅ prefab |
| `shippart_smuggler_medium_engine_mk1` ★ | Corvette Medium Engine | EnginePod/Medium | structural_frame ×1 + control_circuit ×1 | ✅ prefab+mirror |
| `shippart_smuggler_wing_engine_mk1` ★ | Corvette Wing Engine | EnginePod/Small | structural_frame ×1 + control_circuit ×1 | ✅ prefab+mirror |
| `shippart_smuggler_wing_mk1` ★ | Corvette Wing | Wing/Medium | structural_frame ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `shippart_transporter_cockpit_mk1` | Transporter Cockpit | Cockpit/Medium | structural_frame ×1 + hull_plating ×1 | ✅ prefab |
| `shippart_transporter_crate_rail_mk1` | Transporter Crate-Push Rail | CrateRail/Medium | structural_frame ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `shippart_transporter_drive_section_mk1` | Transporter Drive Section | DriveSection/Medium | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `shippart_transporter_engine_wing_mk1` | Transporter Engine Wing | Wing/Medium | structural_frame ×1 + hull_plating ×1 | ✅ prefab+mirror |
| `shippart_transporter_midframe_mk1` | Transporter Midframe | Midframe/Medium | structural_frame ×2 + hull_plating ×2 | ✅ prefab |
| `thruster_front_capital` | Front Thruster (Capital Ship) | DriveSection/Capital | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `thruster_front_large` | Front Thruster (Large) | DriveSection/Large | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `thruster_front_medium` ★ | Front Thruster (Medium) | DriveSection/Medium | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `thruster_front_small` ★ | Front Thruster (Small) | DriveSection/Small | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `thruster_rear_capital` | Rear Thruster (Capital Ship) | DriveSection/Capital | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `thruster_rear_large` | Rear Thruster (Large) | DriveSection/Large | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `thruster_rear_medium` ★ | Rear Thruster (Medium) | DriveSection/Medium | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `thruster_rear_small` ★ | Rear Thruster (Small) | DriveSection/Small | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `thruster_side_capital` | Side Thruster (Capital Ship) | DriveSection/Capital | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `thruster_side_large` | Side Thruster (Large) | DriveSection/Large | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `thruster_side_medium` ★ | Side Thruster (Medium) | DriveSection/Medium | structural_frame ×1 + control_circuit ×1 | ✅ prefab |
| `thruster_side_small` ★ | Side Thruster (Small) | DriveSection/Small | structural_frame ×1 + control_circuit ×1 | ✅ prefab |

## Modules

| ID | Name | Kind | Bill (components) | Visual |
|---|---|---|---|---|
| `wpn_corvette_plasma_turret_01` | Corvette Plasma Turret | Weapon | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab (weaponPrefab) |
| `wpn_flak_turret_01` | Flak Turret | Weapon | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab (weaponPrefab) |
| `wpn_gatling_turret_01` | Gatling Turret | Weapon | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab (weaponPrefab) |
| `wpn_gauss_railgun_01` | Gauss Railgun | Weapon | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab (weaponPrefab) |
| `wpn_laser_beam_aa_01` | HELOS Laser | Weapon | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab (weaponPrefab) |
| `wpn_laser_pd_01` | PD Laser Turret | Weapon | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab (weaponPrefab) |
| `wpn_marauder_plasma_double_01` | Double Plasma Cannon | Weapon | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab (weaponPrefab) |
| `wpn_plasma_cannon_front_01` | Light Plasma Cannon | Weapon | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab (weaponPrefab) |
| `wpn_plasma_lance_01` | Plasma Lance | Weapon | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab (weaponPrefab) |
| `wpn_scrapper_autocannon_01` | Scrapper Combo Cannon | Weapon | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab (weaponPrefab) |
| `wpn_scrapper_interceptor_pod_01` | SR Interceptor Pod | Weapon | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ❌ no prefab |
| `commercial_plasma_engine_01` | Light Commercial Plasma Engine | Engine | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `small_plasma_engine_01` | Overclocked Plasma Engine | Engine | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `standard_engine_01` | Standard Rear Engine | Engine | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `thruster_maneuver_capital_01` | Capital Maneuvering Thruster | ThrusterProfile | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `thruster_maneuver_large_01` | Maneuvering Thruster Array (L) | ThrusterProfile | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `thruster_maneuver_medium_01` | Maneuvering Thruster (M) | ThrusterProfile | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `thruster_maneuver_small_01` | Maneuvering Thruster (S) | ThrusterProfile | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `thruster_steel_small_01` | Steel Thruster | ThrusterProfile | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `shield_kinetic_deflector_01` | Kinetic Deflector | Shield | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `shield_kinetic_deflector_capital_01` | Capital Kinetic Deflector | Shield | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `shield_kinetic_deflector_heavy_01` | Heavy Kinetic Deflector | Shield | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `shield_kinetic_deflector_light_01` | Light Kinetic Deflector | Shield | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `power_core_capital_01` | Capital Power Core | PowerCore | structural_frame ×1 + control_circuit ×4 | ✅ prefab (prefabIdentifier) |
| `power_core_fusion_01` | Heavy Fusion Core | PowerCore | structural_frame ×1 + control_circuit ×3 | ✅ prefab (prefabIdentifier) |
| `power_core_fusion_capital_01` | Capital Fusion Core | PowerCore | structural_frame ×1 + control_circuit ×4 | ✅ prefab (prefabIdentifier) |
| `power_core_fusion_medium_01` | Fusion Core | PowerCore | structural_frame ×1 + control_circuit ×2 | ✅ prefab (prefabIdentifier) |
| `power_core_fusion_small_01` | Light Fusion Core | PowerCore | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `power_core_large_01` | Heavy Power Core | PowerCore | structural_frame ×1 + control_circuit ×3 | ✅ prefab (prefabIdentifier) |
| `power_core_medium_01` | Power Core | PowerCore | structural_frame ×1 + control_circuit ×2 | ✅ prefab (prefabIdentifier) |
| `power_core_small_01` | Light Power Core | PowerCore | structural_frame ×1 + control_circuit ×1 | ✅ prefab (prefabIdentifier) |
| `power_core_standard_01` | Standard Power Core | PowerCore | structural_frame ×1 + control_circuit ×2 | ✅ prefab (prefabIdentifier) |
| `marauder_sensor_array` | Light Forward Array (Internal) | Sensor | structural_frame ×1 + control_circuit ×2 | ✅ prefab (prefabIdentifier) |
| `radar_array_medium_01` | Radar Array | Sensor | structural_frame ×1 + control_circuit ×2 | ✅ prefab (prefabIdentifier) |
| `scanner_array_01` | Scanner | Sensor | structural_frame ×1 + control_circuit ×2 | ❌ no prefab (systemic) |
| `sensor_wideband_radar_turret_01` | Wide-Band Radar (Turret) | Sensor | structural_frame ×1 + control_circuit ×1 + hull_plating ×1 | ✅ prefab (prefabIdentifier) |
| `sonar_array_medium_01` | Sonar Array | Sensor | structural_frame ×1 + control_circuit ×2 | ✅ prefab (prefabIdentifier) |

## Notes (2026-07-14 rev 4)

- RETIRED this rev: TurretMount parts (sockets are baked hull markers), the entire cargoship
  and destroyer families (destroyer superseded by the marauder cruiser; cargoship to be redone).
  FBX source art kept for reuse.
- Reactors wear fusion-core models; batteries wear std-core drums (library power-core prefabs).
- White-material sweep fixed: scanner dish, marauder Heavy-Laser-X2 slots, plasma lance, control circuit.
- Prefab-less INTERNAL containers (cargo hold, gas tank) stay intentional. Interceptor pod still visual-less.
- Recipe depth still comes from authoring per-part componentCost — most bills remain class-default.
