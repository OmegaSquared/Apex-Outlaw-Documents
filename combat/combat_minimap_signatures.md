# Minimap & Radar Signatures — Reference

The minimap is a screen-space tactical overview anchored to the **bottom-left corner**. It shows the **entire sector** with no fog of war — every ship that's broadcasting a detectable radar signature renders as a colored dot, sized by signature strength. Stealth ships either render as a tiny dot or don't render at all.

> **Key inversion vs. classic RTS minimap:** the minimap intentionally bypasses FOW. Information asymmetry comes from the **`radarSignature`** stat, not from vision range. Stealth-class ships pay for low signatures; brute-force ships are bigger pings the moment they enter the sector.

This pairs with the FOW system in [combat_fog_of_war.md](combat_fog_of_war.md) — FOW gates the **main view** (rendering + targeting), while the minimap gives a **strategic snapshot** that stealth can mask.

> **Phase 6.9 minimap canon for Surface scene (Scene 3):** Surface bases have a separate visibility model from ship signatures. Bases appear as minimap markers ONLY when generating noise (smelter, forge, drone build active) AND within an enemy's `sensorRadius`. Silent bases stay off-minimap but **remain physically rendered in the 3D world** — visual scouting is a valid attacker counter-strategy. Defenders trade production noise for radar exposure. Implementation: `BaseNoiseEmitter` MonoBehaviour. Canon: [`combat_fog_of_war.md`](combat_fog_of_war.md) "Activity-noise radar stealth" + [`../world/world_surface_scene.md`](../world/world_surface_scene.md).

> **Surface *navigation* HUD (top-center compass strip + corner nav-minimap) is a separate macro-layer component** — see [`../world/world_surface_navigation.md`](../world/world_surface_navigation.md). It reuses the conventions here (procedural data-driven blips, owner-relationship colors, FOW gating) but reads macro/registry data (bases, gates, resources), not Fusion ship signatures.

---

## At a glance

```
                     +------------------------+
                     |    bottom-left HUD     |
                     |   +----------------+   |
                     |   |  ·   ·         |   |   tiny dots = stealth
                     |   |        ●       |   |   ●  = your fleet (highlighted)
                     |   |   ·   ·    ·   |   |   ·  = signature-detected ships
                     |   |       ·  ●     |   |
                     |   |  ·   ·         |   |
                     |   +----------------+   |
                     +------------------------+
                              (no FOW — entire sector visible)
```

---

## Radar signature

A new stat on `ShipSchema`:

| Field | Type | Notes |
|---|---|---|
| `radarSignature` | AnchorCurve | "Loudness" of this hull on enemy radar. **Lower = stealthier.** F = noisiest (worst-forge); Fl = quietest (best-forge stealth tuning). Default range tuned per hull class — interceptors quieter than freighters. |

Per-grade because forge tuning matters: a smuggler's well-forged hull bleeds less detectable energy than a budget knockoff. Fl-grade hull = best stealth.

### Signature → dot size mapping

```
SIGNATURE_INVISIBLE_THRESHOLD = 5     // below this, no dot at all
SIGNATURE_DOT_FLOOR_PX        = 2     // smallest visible dot in pixels
SIGNATURE_DOT_CEILING_PX      = 12    // largest dot (huge cap ship signature)
SIGNATURE_DOT_SCALING_REF     = 100   // signature value that maps to ceiling

// pixel size = lerp(floor, ceiling, sig / scaling_ref), clamped, OR 0 if sig <= invisible_threshold
```

Tuning: a stealth interceptor with `signature=3` is **invisible**. A signature=10 dot is `~3px` (subtle ping). A `signature=100` capital ship dot is `12px` (impossible to miss). Tune the constants in one place (`TacticalMinimap`) so balance can be adjusted without poking the schemas.

### Signature modulation (TODO)

Future levers — not in v1:
- **Active-fire bump**: firing weapons / engines at full burn briefly raises signature. Stealth ships have to choose between offense and concealment.
- **Cloaking module** (`EWarfareSchema` variant): lowers effective signature while active. Adds capacitor draw. Disabled when firing.
- **Sector-modifier nebulas**: Silicate Nebulas reduce all signatures inside the volume. Pairs with the existing `SensorSchema.piercesNebulaDust` flag.

For v1, signature is a flat per-grade stat read off the hull. Modulation lands when stealth modules + firing-state tracking ship.

---

## Visibility rules

The visibility gate runs through the relationship resolver — **trusted** relationships bypass it entirely.

| Relationship | Always visible? | Dot size | Dot color |
|---|---|---|---|
| `Self` | yes | ceiling (white) | white |
| `Friend` (same fleet) | yes | ceiling | blue |
| `Alliance` | yes | ceiling | green |
| `Foe` | only if `signature > 5` | scales with signature | red |
| `Neutral` | only if `signature > 5` | scales with signature | gray |
| (Spectator override) | yes for ALL | scales with signature | per-relationship as above |

> Relationships are perspective-relative. A Mars player and a Federation player viewing the same Belt freighter could see different colors depending on their respective alliances — the resolver runs per-viewer.

---

## UI layout

| Property | v1 default |
|---|---|
| **Anchor** | Bottom-left of the screen. |
| **Size** | `200 × 200 px` (square). Scales with screen DPI. |
| **Shape** | Square with a 1px faction-neutral border. Round-clipped variant available later if a circular HUD aesthetic wins out. |
| **World scale** | Map covers the entire tactical sector. Sector bounds come from a `TacticalSectorBounds` MonoBehaviour or a fallback fixed `5km × 5km` if absent. |
| **Background** | Faint grid tiled over a dark translucent panel — readable but not overpowering. |
| **Dot rendering** | One `Image` per visible ship, parented to a `RectTransform` mask. Dot positions update each frame from `worldPos.xz → minimap UV`. |
| **Self indicator** | Player's own ship dot is rendered with a small directional triangle instead of a circle so heading is visible at a glance. |

The minimap is independent of the worldspace ship HUD — it's a screen-space canvas that doesn't move with the camera.

---

## Dot colors — relationship-driven

Color is **perspective-relative**, not faction-relative. A Federation player and a Mars player both see "friends as blue" rather than having to memorize each faction's hue. The viewer doesn't think "is that Mars red on my minimap?" — they think "is that red?" and the answer means "shoot it."

| Relationship | Color | Meaning |
|---|---|---|
| `Self` | `#ffffff` (white) | The local player's own ship. Always rendered at ceiling size with a distinctive shape so you can locate yourself at a glance. |
| `Friend` | `#3aa2ff` (blue) | Same fleet as the viewer. Always visible regardless of stealth. |
| `Alliance` | `#7be07b` (green) | Allied faction / fleet (peace-treaty trust, not shared vision normally — but trusted enough to render on the minimap). Always visible regardless of stealth. |
| `Foe` | `#ff5333` (red) | Hostile to the viewer. Signature-gated — stealth ships shrink or vanish. |
| `Neutral` | `#bbbbbb` (gray) | No allegiance to either side (Civilian craft, NPC freighters). Signature-gated. **Upgrades to Foe (red) if the viewer has dealt damage to it** — provoked-neutral rule, standard MMO mechanic: you make your own enemies. The upgrade is per-viewer (other players still see Neutral until they also pull a trigger). State persists for the engagement; no expiry in v1. |

### Trust gate

Self / Friend / Alliance always render — they bypass the signature gate AND draw at ceiling size for legibility. Foe / Neutral are signature-gated AND signature-sized, so stealth reads visually.

### Provoked neutrals

Aggressor tracking lives on `TacticalFlightEngine.aggressors` (per-victim `HashSet<Transform>` of attacker roots). `TacticalProjectile` and `TacticalMissileEntity` (both primary impact + splash) call `victim.RegisterAggressor(firedByRoot)` after damage is applied. The minimap resolver checks `ship.HasAggressor(viewer.transform)` when classifying neutrals and upgrades the relationship to `Foe` if true.

Splash damage counts — AOE'ing a neutral makes it hostile. Self-damage is filtered (your own splash can't make you your own enemy).

No expiry in v1. Cleared explicitly via `TacticalFlightEngine.ClearAggressors()` if a despawn / sector-jump / pardon mechanic eventually wants to forget grudges.

### v1 limitations

Until fleet membership and faction-relationship tables wire up:
- **Friend** falls back to "same non-Civilian faction as the viewer" (stand-in for fleet).
- **Alliance** is implemented via the `TacticalFactionRelations` static registry. PlayFab persistence and an alliance-management UI are still TODO.

When the relationship data lands, the only file that needs updating is `TacticalMinimap.ResolveRelationship` — the rendering layer just reads the resolved relationship.

---

## Runtime architecture

### `TacticalMinimap` (screen-space UI, one per scene)
Scans all `TacticalFlightEngine` instances each frame, computes per-ship visibility for the local viewer (faction / fleet / spectator role), projects world XZ → minimap UV, and pools `Image` dots from a small pre-allocated cache (no per-frame allocation).

Lives on a screen-space canvas — typically attached to the scene's UI root, not parented to any ship. Auto-creates its dots, faction palette, and the background panel procedurally so no UI prefab authoring is required.

### `TacticalSectorBounds` (optional, scene-level)
Provides the world-space bounds the minimap maps from. If absent, the minimap falls back to `5km × 5km` centered at world origin. When sectors get authored as proper objects this component reads off them.

### Hooks needed on existing components
- `ShipSchema.radarSignature` — new `AnchorCurve` field (added now, even if signature modulation isn't wired yet — keeps assets future-proof).
- `TacticalFlightEngine` — exposes `radarSignatureGrade` (the equipped hull's instance grade) so the minimap can resolve signature without re-walking the loadout.

---

## Tunables (single source of truth)

Locked on `TacticalMinimap` for v1; promote to a config asset if balance tuning becomes frequent:

| Constant | Default | Meaning |
|---|---|---|
| `SIGNATURE_INVISIBLE_THRESHOLD` | `5` | Below this signature value, no dot. Pure stealth. |
| `SIGNATURE_DOT_FLOOR_PX` | `2` | Smallest visible dot. |
| `SIGNATURE_DOT_CEILING_PX` | `12` | Largest dot (cap ships, sieges). |
| `SIGNATURE_DOT_SCALING_REF` | `100` | Signature value that maps to ceiling. |
| `MINIMAP_SIZE_PX` | `200` | Square edge length. |
| `SECTOR_FALLBACK_HALF_EXTENT` | `2500m` | Half-edge of the assumed sector if no `TacticalSectorBounds` is present. |

---

## Open threads

- **Signature modulation.** v1 reads the hull's static curve. Active-fire bumps + cloaking-module integration come with the stealth-loadout pass.
- **Network bandwidth.** Sending every ship's worldpos + faction + fleet + signature to every viewer scales as `O(ships)` per tick. With the combat-instance ceiling of 3v3 + 10 spectators (16 players) this is trivial, but flagging for future review if instance sizes ever change.
- **Round vs. square.** Square is easier to implement and read. If a curved HUD aesthetic is chosen project-wide, a circular mask + edge-clip is a one-day refactor.
- **Click-to-jump-camera.** Standard RTS feature: clicking the minimap snaps the camera to that world position. Easy to add — gated until camera control gets centralized.
- **Dot-overlap clustering.** With many ships in a small area, dots overlap into mush. Post-v1: cluster dots within `Npx` and render a count badge.
- **Stealth fairness.** A signature=4 ship is invisible to enemies on the minimap AND inside their FOW (if it stays out of sensor range). Layered stealth — make sure the design doesn't produce uncounterable ships. Counterplay: scout sweeps with high-grade Internal directional radars (FOW system) + sector-wide passive scans (future faction-asset deployable).
