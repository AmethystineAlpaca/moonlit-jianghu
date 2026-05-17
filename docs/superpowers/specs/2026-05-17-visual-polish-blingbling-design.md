# Visual Polish — Blingbling Xianxia Design

## Goal

Layer a cohesive "blingbling" aesthetic across the entire game: translucent glow, fluorescent light, and cold-vs-hot contrast. The player reads as a cool ice-blue celestial swordsman; skeleton enemies burn with hot red/gold soul-fire; the world breathes with moonlit spirit energy. Every hit, skill, and idle moment should feel alive with light.

## Visual Direction

**Palette logic:**
- Player / celestial: ice-blue, frost-white, cyan (`#40e0d0`, `#b0e8ff`)
- Skeleton enemies: red/gold soul-fire accent per existing identity colors
- Zombie allies: green corruption glow layered over inherited skeleton accent
- Environment: deep blue-black night sky, cold-green grass glow, pale-blue moonlight

**Core feeling:** Blingbling = translucent glow layers + fluorescent self-emission + cold/hot contrast at points of impact.

## Implementation Priority

**D → A → B → C** — each layer is delivered and validated before the next begins.

---

## D — Environment (Moonlit Spirit Realm)

The scene is permanently set at night. Light comes from the moon; the ground and grass emit ambient spirit energy.

### 1. Grass Glow + Wind

Extend the existing `grass_wind.gdshader` with an `emission_strength` uniform. Grass tips blend from base green toward `rgba(40, 200, 100, 0.5)` cold-green at the tip. Dense grass patches emit a soft green ambient glow visible against the dark ground.

### 2. Ambient Spirit Particles

Add a `GPUParticles2D` to `World.tscn`. Parameters:
- Color: ice-blue to transparent
- Lifetime: 3–5 seconds
- Motion: slow upward drift with random horizontal wander
- Count: 50–80 particles, sparse distribution
- Slightly denser near the player position

### 3. Moon Beam + Ground Glow

Place a `DirectionalLight2D` angled from the upper-right (~-30°). Color: cold blue-white (`#b0c8ff`), energy 0.15–0.25 — atmospheric only, not realistic. Add a semi-transparent elliptical `CanvasItem` at ground level beneath the light source to simulate a soft ground pool of moonlight.

### 4. Obstacle Soft Shadows

Each tree, crate, and obstacle node gets a child ellipse `Sprite2D` — black, semi-transparent, gaussian-blurred — positioned at the base. Combined with existing Y-sort, near objects occlude their own shadow. No `LightOccluder2D` needed (better performance).

---

## A — Character Visuals

All visuals remain procedurally generated via `Image` / `ImageTexture` in GDScript. No external sprite sheets.

### Player

- Robe edge pixels get a cyan outline (`#40e0d0`) with a subtle glow shader on the `CanvasItem` material
- Sword blends white-to-ice-blue gradient; sword tip emits 1–3 micro-particles continuously
- Movement leaves 1–2 semi-transparent blue-white afterimage frames that fade quickly
- Dash increases afterimage count to 3–4 frames; sword light stretches into a short streak

### Skeleton Enemies (BasicEnemy / FastEnemy)

- Eye sockets and joint pixels lit with each enemy's accent color (red for Basic, gold/orange for Fast)
- Idle jitter slightly amplified to feel more restless
- On hit: accent glow flashes brighter (layered on existing hit flash)
- During hit stun: body rotation nudge backward (~0.1–0.15s recovery)

### Corpses and Zombies

- Corpses: accent color preserved, brightness reduced ~40%, slight desaturation ("extinguished" feeling)
- Zombies: accent color base with green corruption overlay (`modulate` blended toward `#40ff80`); faint green glow halo; leave brief green footprint particles while walking

---

## B — Combat Hit Effects

**Philosophy:** cold-meets-hot at every impact. Player strikes land in ice-blue; enemy strikes land in enemy accent color; the collision point flashes white.

### Slash Trail

On attack start, spawn a thin arc `Line2D` or `Polygon2D` along the sword path:
- Normal attack: cyan-white, fades in 0.1s
- Counter attack: wider, brighter, white outer edge, fades in 0.15s
- Back hit: purple-tinted arc (visually distinct read)

### Hit Sparks

Parameterize existing `HitSpark` to accept color, size, and particle count:
- Normal hit: 8–12 ice-blue + white particles scatter outward
- Counter hit: 16–20 particles, larger, plus a 0.05s white circular flash at impact point
- Enemy hits player: particles use enemy's accent color (red/gold)

### Hit Pause (tiered)

| Hit type | Pause duration |
|----------|---------------|
| Normal | 0.06s (current) |
| Counter / back hit | 0.12s |
| Skill hit | 0.18s |

### Screen Shake

Drive via `Camera2D.offset`, no plugin needed:
- Normal attack: ±2px, 1–2 frames
- Counter / major skill: ±5px, 3–4 frames with decay

### Guard Feedback

- Normal block: small cyan-white shield flash, no shake
- Perfect guard: cyan-white ring expands outward from player (0.2s expand + fade), enemy visibly launched back

---

## C — Skill Effects

### Resurrection Puppet (TransformSkillEffect)

Triggers at the corpse's position — no beam from player.

1. **Burst**: green light ring expands outward from corpse (~0.3s)
2. **Column**: brief upward green light column at corpse position (0.3s, fades up)
3. **Post-resurrection**: zombie gains a continuous green glow halo and leaves faint green footprint particles

### Protective Divine Light (ProtectiveDivineLightEffect)

1. **Activation**: two gold-white rings expand outward — first ring fast, second ring slow
2. **Active state**: semi-transparent gold shield around player pulses every 1.5s
3. **Hit absorbed**: shield flashes gold-white, resumes pulsing
4. **Shield break**: shield shatters into gold particles that scatter outward

### General Skill Convention (future skills)

- Each skill has one primary hue: cold = player buff, warm = damage/attack
- Three-beat rhythm: **gather** (inward) → **burst** (outward) → **echo** (particle settle)
- Skill hit pause: 0.18s

---

## Architecture Notes

- Environment effects live in `World.tscn` / `Grassland.gd`
- Slash trail and hit spark variants added to `PlayerController.gd` and existing `HitSpark` scene
- Screen shake via `Camera2D` offset in `PlayerController.gd`
- Character glow via shader on existing `Sprite2D` body nodes — no new scene structure
- Skill effect classes extend existing `SkillEffect.gd` pattern

## Non-Goals

- No external sprite sheets or art pipeline
- No new combat mechanics
- No realistic lighting system (no shadow maps, no normal maps)
- No changes to enemy AI or combat rules
- No style shift away from retro pixel aesthetic
