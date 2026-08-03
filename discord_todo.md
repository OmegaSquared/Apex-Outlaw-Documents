# 🚀 Apex Outlaw — Development Progress Update

**Last Updated:** May 21, 2026

Hey everyone — here's where we stand on the build. Each phase unlocks the next, so order matters. Items marked ✅ are done and in the build. Items marked ⏳ are next up.

---

## Phase 0 — Project Setup
**Status:** ██████████ Done (in practice)
> Unity 6 project is live, URP pipeline active, all third-party packages imported (PlayFab, Photon Fusion, Shift UI, Photon Chat, DOTS). Folder structure established. Formal checkboxes were never ticked but the work is done.

---

## Phase 1 — Core Database & Foundation
**Progress:** ████░░░░░░ ~23% (20/88)

### ✅ Completed
- **Double-Schema system** — Item, Ship, Weapon, and Player Profile schemas all built with the split client/server stat model
- **PlayFab backend** — Login, authentication, player data read/write all wired
- **Inventory system** — Full container model with mass-cap math, cargo capacity on ships, CloudScript handlers for insert/extract/move
- **Inventory UI** — InventoryView, RemoteTerminalView panels built
- **33 Resource assets authored** — All Tier-1 raw materials (Iron, Copper, Titanium, Uranium, Helium-3, etc.) plus Tier-2 refined outputs (Steel, Carbon-Fiber Glass, Super-Conductor, etc.)
- **Recipe & Refining system (Slice 2)** — 14 canon recipes, RecipeSchema, facility-tier gating, server-validated RunRecipe CloudScript handler
- **Forge UI** — Recipe browser, detail panel, run-with-toast feedback, tier-locked row display
- **Maker's Mark system (Slice 3a)** — Every forged item stamps the crafter's identity with tamper-proof v3 checksums
- **Dev seed migration** — New accounts auto-populate with starter inventory

### ⏳ Still To Do
- Server math validation prototype (formula checking)
- PlayFab starting inventory migration (move hardcoded grants to CloudScript)
- CloudScript deploy to PlayFab GameManager
- Author mass values on all resource & ship assets
- Utility modules (Mining Laser, Salvage Beam)
- Hacking & Intel module chain (11 modules — waiting on Alliance system)
- External Crates & Crate-Push Rail system
- Transporter hull family (Light Hauler → Bulk Hauler)
- Mining Outpost deployable structures
- **Full economy systems** — DOM exchange, freight contracts, currency model, repair system, NPC auto-arbitrage, faction standing, loans, taxes, permits (these are massive — Phase 5+ scope living under Phase 1's tracking)

---

## Phase 2 — Dashboard & Shipyard
**Progress:** ██████░░░░ 66% (4/6)

### ✅ Completed
- **Main Dashboard** — Login → dashboard scene transition using Shift UI
- **Top Bar HUD** — Commander name, PlayFab ID, live Credits / Premium currency display
- **Shipyard visuals** — Ship hulls and hardpoints rendered from PlayFab inventory data
- **Ship Visualizer** — Top-down orthographic blueprint camera with RenderTexture

### ⏳ Still To Do
- Notification system for server status / live updates
- **Drag-and-drop hardpoint editing** — Drag a weapon onto a slot, write back to PlayFab

---

## Phase 2.5 — Fleet Roster & Launcher
**Progress:** ░░░░░░░░░░ 0% (0/3)

### ⏳ Still To Do
- Launched Fleet Roster bar (bottom HUD)
- Fleet Launcher dock (right-edge panel)
- SectorMapHUD controller (range rings, beacons, waypoints, gate overlay)

---

## Phase 3 — Resource Scanning & Extraction
**Progress:** ███████░░░ 71% (10/14)

### ✅ Completed
- **Grade system** — Quality grades with Flaw shortcodes
- **Graded inventory** — GradedStack, MaxDiscoveredGoods, anomaly schemas, mining laser schema
- **6 anomaly assets** — Iron, carbon, silicates, titanium, helium-3, platinum with tuned grade probability curves
- **CloudScript scanning** — Server-side `ResolveMaterialAnchors` handler, per-player deterministic from alchemy seed
- **Resource Scanner UI** — Panel + markers that track orbiting asteroid rocks
- **CloudScript deploy bundle auto-generator** — Editor menu item
- **Canon docs updated** — Scanning & extraction design doc rewritten
- **Deployed & smoke tested** — PlayFab revision 8, marker visualization confirmed working ✓

### ⏳ Still To Do
- Remove hardcoded catalog mirrors (waiting on title-data export pipeline)
- Replace programmatic scanner UI with designer-authored prefab
- Wire graded inventory paths

---

## Phase 4 — Combat (Photon Fusion)
**Progress:** ░░░░░░░░░░ 0% (0/9)

### ⏳ Still To Do
- Fusion SDK integration & architecture boundary
- Sector serverless map (PlayFab-only, no Fusion outside events)
- **Battle Room system** — 3v3 combatant cap + 10 spectator slots
- Spectator role (read-only view)
- Combatant overflow / instance spilling rules
- Mining-op Fusion instances
- Hardware loadout → Fusion entity translation
- **Flight & combat dynamics** — F=MA physics in Fusion networked state

---

## Phase 4.5 — Anti-Cheat & Authority
**Progress:** ░░░░░░░░░░ 0% (0/5)

### ⏳ Still To Do
- Convert TacticalHitbox to NetworkBehaviour
- Server-authoritative damage application via RPC
- Authority gate audit across all networked writes
- Capacitor/power-out server validation
- Remove client-side damage guesses

---

## Phase 4.6 — Fog of War & Sensors
**Progress:** ░░░░░░░░░░ 0% (0/6)

### ⏳ Still To Do
- Sensor schema assets
- Fleet vision aggregator (server-authoritative)
- Wallhack mitigation (server-side transform filtering)
- Spectator vision system
- Jammer/ECCM integration
- Nebula visibility penalties

---

## Phase 5 — Economy & Alliances
**Progress:** ░░░░░░░░░░ 0% (0/4)

### ⏳ Still To Do
- Hub pricing model (supply/demand scarcity)
- Economy taxes (3% Escrow, 35% FED Tax)
- Alliance registration & diplomacy
- **The Golden Towing Sequence** — Wreck dragging, speed penalties, forensic deconstruction

---

## Phase 5.5 — Sovereignty & Territory
**Progress:** ░░░░░░░░░░ 0% (0/9)

### ⏳ Still To Do
- Sector control = 100% POI ownership
- Planetary defense systems (destructible orbital platforms)
- Alliance faction-claim system (50+ member gate)
- Faction defeat & AI respawn mechanics
- Planet-level ownership (50% rule)
- Planet residency / access gates
- Non-member planetary tax

---

## Phase 6.0 — Celestial Engine
**Progress:** █░░░░░░░░░ 6% (2/30)

### ✅ Completed
- **Time-anchored orbit evaluator** — All orbital positions computed as pure function of `(now − epoch)`. Two clients sync to the second.

### ⏳ Still To Do
- Registry-driven scene building (replace hand-authored bodies)
- Alliance-built POI system
- PlayFab title data seeding (epoch, registry, CloudScript)
- Owner schema unification (faction = alliance, single `ownerId`)
- End-to-end multi-client verification

---

## Phase 6.7 — Planet Scenes & Helion Split
**Progress:** █████░░░░░ 50% (14/28)

> **⚠ SUPERSEDED 2026-05-29 by Phase 6.9 (three-scene world architecture).** Helion unified-world was removed 2026-05-17; the per-planet Vega-Conflict-style 2D scenes were retired by the three-scene split (Solar / Low Orbit / Surface). The "Still To Do" items below referencing Helion, planet click → roster popup, and per-planet scenes are **archival only** — the equivalent work tracks now live under Phase 6.9.A–H in [`meta/master_to_do.md`](meta/master_to_do.md). See [`world/world_low_orbit_scene.md`](world/world_low_orbit_scene.md) + [`world/world_surface_scene.md`](world/world_surface_scene.md) for canon.

### ✅ Completed
- Sensor sync radius system
- Sync mesh proximity graph & clustering
- Party trust group service
- FOW union refactor (cluster + party-based)
- **Helion camera & view system** — Fleet / PlanetSystem / SolarSystem zoom tiers
- Notification manager (toast UI with auto-dismiss)
- Sync visualizer (rings + cluster edge lines + toasts)
- Planet player roster schema
- **Planet Avernus prototype scene** — First planet scene built (Vega Conflict-style near-orbit view) — **RETIRED 2026-05-29** by the three-scene architecture (Phase 6.9). Replaced by `LowOrbit.unity` + `Surface.unity` template scenes; see [`world/world_low_orbit_scene.md`](world/world_low_orbit_scene.md) + [`world/world_surface_scene.md`](world/world_surface_scene.md).

### ⏳ Still To Do
- Hand-author Helion.unity scene
- CloudScript AoI spatial grid system
- Server-FOW filtered entity payloads
- Logout persistence (auto-travel-to-safety)
- Planet roster client + CloudScript dock/undock handlers
- Helion planet click → roster popup
- Launch flow (planet → undock → Helion)
- Remaining planet scenes

---

## Phase 6.8 — Registry-Driven World
**Progress:** █░░░░░░░░░ 12% (2/16)

### ✅ Completed
- **Asteroid belt registry migration** — Belts now spawn from celestial registry data, not hand-authored scene objects

### ⏳ Still To Do
- Schema extensions for planet/moon properties
- Buildable slot system per body
- CloudScript build/demolish handlers
- Full CelestialSpawner integration
- FOW-driven asteroid lazy spawning
- Asteroid depletion & regeneration
- New-account onboarding flow

---

## Phase 6.9 — Resource Geography
**Progress:** █░░░░░░░░░ 13% (3/22)

### ✅ Completed
- **Resource geography doc** — Frost-line principles, Tier-1 location matrix, body signature resources
- **Future ideas doc** — Fleet Graveyard, Generation Ship, Black Hole, Rogue Planet concepts
- Main Belt category refinement (removed pre-frost-line ice families)

### ⏳ Still To Do
- Surface mining per-body resource composition
- Radiation hazard mechanics (Avernus uranium)
- Lore-coded moon resource leans
- The Ring (Castor) — Ancient Alloy debris, intact arc segments, precursor resources
- Outlaw hub at Praedo (black market, hidden asteroid interior)
- Wandering body system (5-10 bodies with unique compositions)
- Per-asteroid hand-tuned material lists for 7 named asteroids

---

## Phase 7 — Pre-Launch Polish
**Progress:** ░░░░░░░░░░ 0% (0/8)

### ⏳ Still To Do
- First-time user experience (tutorial loop)
- NPC content (behavior trees, wave encounters)
- Hull & weapon catalog fill + balance pass
- Audio & VFX pass (vacuum-authentic sound design)
- Monetization wiring (cosmetic shop, FED License)
- Live-ops infrastructure (crash reporting, telemetry)
- Pre-launch testing (closed → open beta → soft launch)
- **BRIDGE code sweep** — Every temporary scaffold must ship or be replaced before launch

---

## 📊 Overall Summary

| Phase | Description | Progress |
|-------|-------------|----------|
| 0 | Project Setup | ✅ Done |
| 1 | Core Database & Foundation | 23% |
| 2 | Dashboard & Shipyard | 66% |
| 2.5 | Fleet Roster & Launcher | 0% |
| 3 | Resource Scanning | 71% |
| 4 | Combat (Fusion) | 0% |
| 4.5 | Anti-Cheat & Authority | 0% |
| 4.6 | Fog of War & Sensors | 0% |
| 5 | Economy & Alliances | 0% |
| 5.5 | Sovereignty & Territory | 0% |
| 6.0 | Celestial Engine | 6% |
| 6.7 | Planet Scenes & Helion | 50% |
| 6.8 | Registry-Driven World | 12% |
| 6.9 | Resource Geography | 13% |
| 7 | Pre-Launch Polish | 0% |

**Current active work:** Phases 1–3 (foundation, shipyard, scanning) + Phase 6.7–6.8 (world building)

---

*Questions? Drop them in the thread. 🛸*
