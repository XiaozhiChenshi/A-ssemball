---
name: godot-cyber-intro-sequence
description: Use this skill when designing or implementing a Godot 4.x sci-fi/cyberpunk intro sequence with pursuit pacing, distorted assembly-ball imagery, procedural block corridors, glyph subtitles, FOV speed pull, observation locks, particles, and goal-entry transitions.
---

# Godot Cyber Intro Sequence

Use this skill for Godot 4.x intro/prologue scenes that should feel like a playable cyberpunk pursuit rather than a static cutscene. It is especially suited to sequences centered on a mysterious distorted sphere, procedural corridor reconstruction, symbolic subtitles, speed perception, and an end-state camera pull into the target.

## Core Intent

Build the intro as an interactive rhythm:

1. The world appears from absence.
2. The player runs toward a distorted object.
3. The object repeatedly allows approach, forces observation, then escapes.
4. Text appears as unstable fragments, not ordinary UI.
5. The finale pulls the camera into the object.

Prefer systems that produce readable rhythm over isolated one-off effects.

## Visual Direction

- Use a restrained dark sci-fi palette: black geometry, gray environment, white or silver outlines, gold circuit pulses, occasional red text corruption.
- Make the main object feel deep, damaged, and unstable. Its body should be dark enough that white/silver outline and silhouette effects matter.
- Avoid decorative noise that has no gameplay or compositional role.
- Avoid cheap constant jitter as the primary distortion. Use form changes, staged degradation, flicker bursts, vertex/mesh changes, and silhouette contrast.
- Do not make the scene a flat tile floor if the desired read is a massive constructed corridor. Use thick, opaque, varied cuboids with real height and depth.

## Recommended Sequence Pattern

Use these loops as the main structure:

```text
intro blackout
-> corridor reconstructs near-to-far
-> player runs
-> target gets close
-> observe lock
-> particle build-up
-> particle clear + target escapes
-> repeat
-> final click
-> camera enters target
-> flash / blackout / next scene
```

For the target object itself:

```text
long degradation
-> short violent flicker
-> next distinct form
-> long degradation
```

The long phase should be seconds long and legible. The short phase can be fast and aggressive.

## Movement And Camera

- Use FOV expansion for speed pull. Avoid stretching the whole viewport unless explicitly requested.
- Keep head-bob subtle. Excessive lateral sway makes the player feel non-human.
- Let the player run, but slow or stop them near the target so the target can be inspected.
- A good observe lock is about 5-6 seconds: long enough to read the object, short enough to keep pursuit momentum.
- When the target escapes, use a large, fast displacement. Do not let it simply maintain a constant distance.

## Target Pursuit

Use a small state machine:

```text
RUNNING
OBSERVE_LOCK
BURST_ESCAPE
RUNNING
```

Guidelines:

- Trigger observe lock only when the player is very close to the target.
- During observe lock, reduce movement to near zero and keep the target observable.
- During the lock, emit silver particles around the target. Particles should rise, decelerate, shrink, and fade.
- At the peak, clear all particles suddenly, then let the target escape.
- Alternate target escape positions left and right. Use random amplitude and height, but do not allow repeated same-side stops.

## Target Forms

The target should have multiple distinct visual states. Do not rely on one fixed broken sphere.

Good forms include:

- Missing shell: dark sphere-like shell with absent panels.
- Offset slices: vertical or radial slabs offset from one another.
- Orbiting rings: broken ring segments around a damaged core.
- Imploded core: shard structures pulled inward or outward.
- Polyhedral remains: angular fragments implying failed reconstruction.

Each form should support:

- A complete or near-complete state.
- A degraded state.
- A transform path from complete to degraded.
- High-contrast outline or rim treatment.

## Road And Surface

For a reconstructed corridor:

- Use thick cuboids, not thin tiles.
- Let block widths, depths, heights, and grouping vary.
- Blocks should fit together enough to read as a route, while still feeling assembled.
- Reveal blocks from near to far at the start.
- While running, reveal only nearby future blocks to preserve the feeling of ongoing reconstruction.

For gold surface lines:

- Prefer face-bound circuit paths over floating lines.
- Dense fine line networks can work better than a few thick moving lines.
- If using pulses, make lines mostly persistent and let brightness waves travel through them.
- Avoid obvious repeated short path templates.

## Subtitles

Subtitles should feel like unstable fragments or signals.

Recommended approach:

- Build subtitles from per-character UI nodes or particles.
- Assemble each character from a nearby trail, then hold, then break apart.
- Give each character small rotation and scale variation.
- Keep important text ordered when narrative sequence matters.
- For emphasis, mark semantic keywords and render them as larger red unstable characters.
- Increase spacing around emphasized characters so large red glyphs do not collide.

Example ordered fragment list:

```text
缺失之物。
球记得它的碎片。
你已经沉溺于此太久了。
你不记得水里的尸体。
归于完整。
拼装它的残躯。
```

Suggested emphasized keywords:

```text
缺失
碎片
太久
尸体
完整
残躯
```

## Final Entry Transition

On final target click:

- Disable normal player control and hints.
- Lock camera attention to the target.
- Move camera toward the target over roughly 1.6-2.2 seconds.
- Increase FOV dramatically, enough to imply entering the object.
- Add mild roll or spiral disturbance.
- Accelerate the target's degradation/flicker cycle during the pull-in.
- Then use flash, blackout, or scene transition.

The final effect should read as entering the target, not merely clicking a button.

## Godot Implementation Notes

- Prefer Node3D, MeshInstance3D, ImmediateMesh, Camera3D, and GDScript state machines.
- Use real geometry for major visual elements when depth matters.
- Use ShaderMaterial for local distortion or glyph glitching when a shader is already appropriate.
- Use StandardMaterial3D emission for simple glowing particles and outlines.
- Keep effect state explicit with booleans/timers rather than scattered random triggers.
- Run a headless scene load after edits when possible:

```powershell
& '.\The Convergence Sphere.console.exe' --path . --headless --scene res://scenes/intro_corridor_v2.tscn --quit
```

Adjust the executable and scene path to the current project.

## Common Failure Modes

- The floor reads as flat tiles instead of massive cuboids.
- The target distortion is only jitter and has no form language.
- The target keeps a constant distance and never creates pursuit rhythm.
- The player moves too fast to read pulses or object states.
- Subtitles are ordinary labels rather than unstable visual events.
- Red emphasized glyphs overlap because layout does not reserve extra width.
- The final click is a plain fade instead of a camera-entry event.

