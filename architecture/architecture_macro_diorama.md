# Macro Diorama — the real world beneath the chart

**Decision (Aaron, 2026-07-20):** the macro view uses the actual forge content — SGT
Planet Forge, Gas Giant Forge, Nebula Forge, ring systems — rendered at TRUE visual
scale on a layer *beneath* the gameplay plane. The chart (ships, markers, orders,
grid) stays a clean plane on top; the bird's-eye view reads the chart with the real
world glowing under it. Zooming in is a camera dive: the forge content grows into the
Borealos-style close views because it was physically there all along. One scene, no
visual cut. ("Kind of a play on camera angles and a little bit of magic.")

## The rig (why no hand-tuned depths)

Author the deco world at chart coordinates ×S (S = 225, the chart-unit→local-meter
factor already used by the sandbox dresser). Every frame:

    decoRoot.position = cameraPos × (1 − S)

Every deco point then sits exactly on the camera ray through its chart point, at S×
the distance — a similarity transform through the camera. Consequences:

- Perfect alignment under every chart marker at ANY pan/zoom (angles match for all
  points, not just screen center).
- Zoom lockstep for free: halve the camera altitude and the deco apparent size
  doubles exactly with the chart.
- The dive: FREEZE the rig and descend the camera — the world approaches at true
  scale, no scale animation needed.

## Camera conversion (P1 — load-bearing)

SGT breaks under the ortho map camera (ring/skybox flood — known since Vesperion).
The chart camera becomes a high-altitude narrow-FOV perspective camera:

- FOV ≈ 20° — near-parallel projection, chart play feels unchanged.
- Zoom metric abstraction `MacroZoom` (visible half-height = altitude·tan(fov/2))
  replaces every `orthographicSize` read/write: camera controller, ViewTier
  thresholds (Helion 15.5/18), StarFloor density, seam scripts, ChartCameraRestorer.
  Labels already carry a perspective branch.

## Phasing

- **P1** camera conversion + MacroZoom sweep.
- **P2** DioramaRig + HelionDioramaBuilder (Aaron: "we can do the entire system —
  just Rubicon, two moons and the sun right now"): walk every chart body generically —
  each body's visual subtree (CW_Body landscape planets, moon spheres) cloned ×S under
  the rig; Rubicon adds forge SgtRingSystem + SgtRingParticles (GasGiantForge
  RingSystem.mat — null = magenta) + SgtBeltSimple band; the sun becomes the deco's
  light source with SgtLight (SGT bodies ignore plain Unity lights). Chart-scale body
  visuals hidden once the deco lines up; chart keeps flat furniture (orbit rings,
  gates, labels).
- **P3** dive: past the enter threshold, freeze rig + descend + fade chart
  furniture; sandbox handoff fires at the bottom with matched framing. Later the
  handoff itself can dissolve (ships spawn in-scene) — north star.
- **P4+** rest of Helion (moons, nebula, gas bodies), seeded belt rocks shared with
  the sandbox dresser (same FNV-1a world-seed cells).

## Known interactions

- Sandbox dresser (SandboxBackdropDresser) already builds the true-scale local space
  from the same S — the diorama and the stage agree by construction.
- FOW overlay / quadrant grid / selection rings assume the flat chart — they stay on
  the chart plane, unaffected.
- Perspective picking: chart clicks already raycast to the Y=0 plane; verify the
  few places that assumed parallel rays.
