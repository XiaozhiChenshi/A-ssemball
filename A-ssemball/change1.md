# Change Log 1

## 2026-05-10

### Chapter 2-1 completion flow changed from manual continue button to timed music-driven transition

- Scope:
  - `scripts/levels/chapter_2/level_1.gd`
- New audio resource:
  - `assets/audio/2-1turned.mp3`
- Final behavior:
  - After all four small cubes in Chapter 2-1 are matched successfully, the old `Continue` button is no longer shown.
  - Once all four cubes are complete, the script waits until existing Chapter 2-1 stage audio has finished.
  - After that audio has fully finished, the script waits an extra `2` seconds before starting `2-1turned.mp3`.
  - Existing stage audio here includes:
    - block preview / SFX player
    - match-success players
    - disc music player
  - When those sounds have ended and the extra `2` second delay has passed, `2-1turned.mp3` starts automatically.
  - The transition into Chapter 2-2 begins `2` seconds before `2-1turned.mp3` reaches the end.
- Implementation notes:
  - Added a dedicated completion music player for the final Chapter 2-1 wrap-up track so it does not reuse the match/disc players.
  - Added a one-shot completion-sequence guard to avoid duplicate triggering if the all-complete state is reached more than once through deferred callbacks.
  - The previous `_show_continue_button()` path is no longer used by the all-complete branch; all-complete now calls the automatic completion sequence instead.
  - When the final close transition starts, any visible `Continue` button is explicitly hidden and disabled in case it exists from earlier state.
- Handoff expectation:
  - This change assumes the existing `chapter_completed.emit(chapter_index)` path is the handoff into the Chapter 2-2 transition flow.
  - The code now treats that emit point as the start of the Chapter 2-2 cutscene / transition animation.
- Regression check:
  - Match all four Chapter 2-1 cubes.
  - Confirm no `Continue` button appears.
  - Confirm the last black-frame match / disc audio is allowed to finish first.
  - Confirm there is then an additional `2` second quiet gap.
  - Confirm `2-1turned.mp3` starts only after that gap.
  - Confirm the Chapter 2-2 transition begins approximately 2 seconds before that track ends.

### Extended the Chapter 2-2 help prompt popup downward by one more line

- Scope:
  - `scripts/levels/chapter_2/level_2.gd`
- Final behavior:
  - The Chapter 2-2 left-side help prompt popup is taller, with enough extra vertical space for roughly two additional lines of content compared with the original height.
- Implementation note:
  - Increased the popup size from `Vector2(480.0, 252.0)` to `Vector2(480.0, 332.0)`.
  - Width was kept unchanged; only the downward height was extended.
- Regression check:
  - Open Chapter 2-2 and trigger the help prompt popup.
  - Confirm the popup extends farther downward than before.
  - Confirm the existing prompt text still fits cleanly and is not clipped at the bottom.
