# Change Log

## 2026-05-09

### Document purpose

- This file is the handoff log for code changes made in this workspace during the current task sequence.
- Entries below are written as final behavior, not just commit-by-commit intent.
- Where earlier console output showed garbled Chinese filenames, this document uses functional descriptions so another developer can still trace the logic safely.

### Baseline review

- Reviewed project structure and entry points before making changes:
  - `project.godot`
  - `scenes/main_entry.tscn`
  - `scripts/main_entry.gd`
  - `scripts/intro_interactive.gd`
  - `scripts/levels/**`

---

## Intro

### Fixed intro BGM playback

- Scope:
  - `scripts/intro_interactive.gd`
- Final behavior:
  - The intro opening BGM stays active for the entire pre-finish traversal phase.
  - Releasing the movement key or pausing movement before the end point no longer stops the BGM.
  - The BGM now stops only when the intro reaches completion or when the goal-click transition begins.
- Reason:
  - Prevented mid-path audio dropouts that made the intro feel incorrectly paused.
- Regression check:
  - Start the intro, move forward, stop midway, then continue: BGM should remain continuous.
  - Reach the white sphere / start the transition: BGM should stop at transition start, not earlier.

---

## Chapter 2-2

### Adjusted `StageInstrument_5` (tuba) placement

- Scope:
  - `scenes/levels/chapter_2/source_level_2.tscn`
- Final transform:
  - Position: `(348, 131)`
  - Size: `(104, 122)`
- Scene offsets:
  - `offset_left = 348`
  - `offset_top = 131`
  - `offset_right = 452`
  - `offset_bottom = 253`
- Regression check:
  - Open Chapter 2-2 right panel and confirm the tuba icon aligns with the intended target slot artwork.

### Hid the top-right `AuditionButton`

- Scope:
  - `scenes/levels/chapter_2/source_level_2.tscn`
  - `scripts/levels/chapter_2/level_2.gd`
- Final behavior:
  - The visible top-right `AuditionButton` is hidden in scene data.
  - The same button is also forced hidden at runtime.
  - Audition remains available through:
    - `Space`
    - clicking the right-side panel
- Reason:
  - Removed redundant UI without removing the existing audition paths.
- Regression check:
  - In Chapter 2-2, the top-right button should not be visible.
  - Pressing `Space` should still audition.
  - Clicking the right-side panel should still audition.

---

## Chapter 2-1

### Refactored orbit-cube click / drag input and feedback

- Scope:
  - `scripts/levels/chapter_2/level_1.gd`
- Input logic:
  - Orbit cube interaction was split into separate press, click-release, and delayed drag-start paths.
  - Single click and drag no longer share the same immediate mouse-down behavior.
- Final click behavior:
  - Single-clicking a small orbit cube now:
    - plays that cube's preview / block-hint audio
    - triggers a short glow pulse
  - Click feedback is glow only.
  - The earlier oversized click-time scale-up was removed.
- Final drag behavior:
  - Dragging past the movement threshold still enters the original drag-to-anchor flow.
  - Click preview does not block snapping or matching.
- Audio resources introduced for block preview:
  - piano block preview sound
  - flute block preview sound
  - cello block preview sound
  - drum block preview sound
- Regression check:
  - Single-click each of the four Chapter 2-1 orbit cubes: each should play its own preview sound.
  - Single-click should glow briefly, but should not visibly enlarge the cube.
  - Dragging a cube to the anchor should still work as before.

### Fixed preview-audio bleed into match-success audio

- Scope:
  - `scripts/levels/chapter_2/level_1.gd`
- Final behavior:
  - Starting an orbit-cube drag stops any active click-preview / block-hint audio.
  - Match-success playback also stops any active click-preview / block-hint audio before playing the success / frame-match audio.
- Reason:
  - Prevented preview audio from leaking into the black-frame placement result when the player clicks and then quickly drags.
- Regression check:
  - Click a non-cello cube, then immediately drag it into the black-white frame.
  - On successful match, only the success / match audio should remain audible.

### Fixed cello cube audio routing

- Scope:
  - `scripts/levels/chapter_2/level_1.gd`
- Final resource responsibility:
  - Cello click-preview audio:
    - dedicated cello block-preview sound
  - Cello successful frame-match audio:
    - dedicated cello disc / placement sound
- Final behavior:
  - Clicking the cello orbit cube prefers the cello preview sound.
  - Matching the cello cube into the black-white frame prefers the cello disc / placement sound.
  - The cello match-success path is resolved before any generic fallback block-sound route can override it.
- Important distinction:
  - Cello preview sound is only for click preview.
  - Cello disc sound is only for successful frame placement / match result.
- Regression check:
  - Single-click the cello cube: should play the cello preview sound.
  - Place the cello cube into the black-white frame successfully: should play the cello disc sound.
  - Non-cello cubes should continue using their own original match-success audio when placed successfully.

---

## Chapter 3-1

### Added dedicated audio players for stage-specific SFX

- Scope:
  - `scripts/levels/chapter_3/level_1.gd`
- Dedicated audio responsibilities:
  - rolling loop player:
    - `assets/audio/第三幕/球滚动.mp3`
  - color pickup player:
    - `assets/audio/第三幕/收集色彩提示音2.mp3`
  - mirror break player:
    - `assets/audio/第三幕/镜子碎裂.mp3`
- Implementation notes:
  - Rolling, collect, and mirror-break playback each use a separate `AudioStreamPlayer`.
  - This prevents one effect from cutting off another.
  - The rolling stream is duplicated and loop-enabled at runtime before being assigned to the rolling player.

### Corrected rolling-audio stage binding

- Scope:
  - `scripts/levels/chapter_3/level_1.gd`
- Final behavior:
  - The rolling loop does not play during the first three pre-paint-roll paintings.
  - The rolling loop is driven by the moving paint-roll ball in the last three paintings.
  - In the paint-roll section, rolling audio starts when the paint-roll ball has meaningful movement velocity.
  - Rolling audio stops when:
    - the paint-roll ball slows back down
    - a paint-roll stage transition begins
    - the chapter completes
- Reason:
  - The first hookup incorrectly attached rolling audio to the early reticle-movement phase instead of the later paint-roll ball phase.
- Regression check:
  - In Chapter 3-1 paintings 1 to 3, moving the reticle should not produce the rolling loop.
  - In Chapter 3-1 paintings 4 to 6, moving the paint-roll ball should produce the rolling loop.
  - Let the paint-roll ball coast to a stop; the rolling loop should stop with it.

### Added color-pickup audio with short combo pitch rise

- Scope:
  - `scripts/levels/chapter_3/level_1.gd`
- Final behavior:
  - Collecting a color spot plays `收集色彩提示音2.mp3`.
  - Consecutive spot pickups inside a short combo window slightly raise playback pitch.
  - If the player pauses long enough or the stage changes, the combo pitch resets to the base level.
- Implementation notes:
  - Combo state is reset on:
    - normal stage apply
    - paint-roll stage apply
    - chapter completion
- Regression check:
  - Collect several color spots in quick succession; later pickups should sound slightly higher than earlier ones.
  - Wait briefly between pickups; the next pickup should return to the base pitch.

### Added mirror-break audio and tuned the three shatters

- Scope:
  - `scripts/levels/chapter_3/level_1.gd`
- Final behavior:
  - Each mirror-layer shatter in the last painting plays `镜子碎裂.mp3` when that layer actually breaks.
  - Pitch is intentionally varied by mirror-break order:
    - first break: base pitch
    - second break: slightly higher
    - third break: lower than the first
- Implementation note:
  - Mirror-break playback now receives the current mirror layer index and sets per-layer `pitch_scale` before replaying the same break sound.
- Regression check:
  - In the final Chapter 3-1 mirror painting, break the three mirror layers in order.
  - Confirm the second shatter sounds higher than the first.
  - Confirm the third shatter sounds lower than the first.

### Final rolling-loop loudness after all adjustments

- Scope:
  - `scripts/levels/chapter_3/level_1.gd`
- Final value:
  - The Chapter 3-1 paint-roll rolling loop player is set to `volume_db = -0.5`.
- Adjustment history captured during tuning:
  - initial rolling loop level for this task pass: `-8.0 dB`
  - raised to `-4.5 dB`
  - then raised to `-1.5 dB`
  - final value: `-0.5 dB`
- Final behavior:
  - The rolling loop is noticeably louder than the initial pass.
  - Timing and trigger logic are unchanged by the loudness-only adjustments.
- Regression check:
  - In Chapter 3-1 paintings 4 to 6, confirm the rolling loop is easy to notice during motion.
  - Confirm the rolling loop does not clip and does not overpower color-pickup or mirror-break feedback.

---

## Final handoff summary

- Files changed during this task sequence:
  - `change.md`
  - `scripts/intro_interactive.gd`
  - `scripts/levels/chapter_2/level_1.gd`
  - `scripts/levels/chapter_2/level_2.gd`
  - `scripts/levels/chapter_3/level_1.gd`
  - `scenes/levels/chapter_2/source_level_2.tscn`
- Highest-risk areas for regression:
  - Chapter 2-1 orbit cube click vs drag interaction
  - Chapter 2-1 cello preview vs placement audio separation
  - Chapter 3-1 paint-roll rolling-loop trigger timing
  - Chapter 3-1 mirror-layer break pitch ordering
