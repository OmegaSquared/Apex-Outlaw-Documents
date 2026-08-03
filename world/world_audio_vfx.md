# MMO Audio & VFX Design Guidelines

## 1. The Realism Paradigm (No Fire, Limited Sound)
Because this game utilizes a gritty, grounded Sci-Fi aesthetic (an underbuilt exile frontier), space phenomena should feel terrifyingly clinical rather than arcade-like.

---

## 2. Audio Design Rules (Vibration over Atmosphere)
Space is a vacuum. Sound does not travel. The only audio the player hears is the vibration of their own hull and systems.

- **Weapons Fire:** You do not hear an enemy's laser. You hear your ship's hull violently clicking and groaning as the ambient heat from the impact melts your armor. When you fire *your* railgun, the audio is a massive, bass-heavy metallic clank vibrating through the chassis.
- **Thrusters:** Engine sounds are muffled, low-frequency rumbles inside the cockpit rather than roaring jets.
- **Explosions:** When an enemy ship dies, there is absolute silence from the exterior space. The only sound is the proximity warning alarm in your own cockpit pinging the debris cloud.

### The UI Soundscape (Shift Integration)
- **Menu Clicks:** Crisp, high-frequency digital chirps. 
- **Warnings:** If a Jammer targets you, the audio abruptly spikes with violent, jarring analog static—violating the silence of space to create immediate panic.

---

## 3. VFX Design Rules (Physics over Flash)
Because combat runs in ECS, GameObjects and Particle Systems are spawned entirely as "visual puppets" reacting to the data.

- **Explosions (Zero-Oxygen):** 
  - There are no rolling, fiery mushroom clouds. 
  - An explosion is an instantaneous, blinding flash of white/blue plasma that expands outward incredibly fast, leaving trailing chunks of molten metal that instantly cool to grey slag in the vacuum.
- **Weapon Beams & Projectiles:**
  - **Kinetic Slugs:** Invisible, except for the massive plume of ionized gas leaving the barrel and the violent impact spark.
  - **Plasma/Energy:** Extremely bright, leaving a temporary retina-burn (post-processing lens flare) as it shrieks across the void.
- **Shield Impacts:** 
  - Shields are invisible until struck. 
  - When hit, a hexagonal mesh briefly flares out precisely where the projectile impacted, utilizing Unity's URP depth-buffer shaders to wrap the ship geometry before fading out.
