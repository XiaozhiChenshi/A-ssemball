# A-ssemball

Godot 4.5 project.

## Runtime Flow
1. Start scene: `res://scenes/main_entry.tscn`
2. Intro scene: `res://scenes/intro_interactive.tscn`
3. Level flow (3 chapters x 2 levels):
   - `res://scenes/levels/chapter_1/level_1.tscn`
   - `res://scenes/levels/chapter_1/level_2.tscn`
   - `res://scenes/levels/chapter_2/level_1.tscn`
   - `res://scenes/levels/chapter_2/level_2.tscn`
   - `res://scenes/levels/chapter_3/level_1.tscn`
   - `res://scenes/levels/chapter_3/level_2.tscn`

## Main Structure
- `scenes/`
  - `main_entry.tscn`: boot/menu and scene flow control
  - `intro_interactive.tscn`: intro interaction scene
  - `levels/chapter_1..3/level_1..2.tscn`: six-level main progression
- `scripts/`
  - `main_entry.gd`: intro -> level sequence switch
  - `intro_interactive.gd`: intro camera/motion/transition logic
  - `levels/chapter_1/level_1.gd`: chapter 1 level 1 core gameplay (implemented)
  - `levels/chapter_1/level_2.gd`: chapter 1 level 2 placeholder gameplay (in progress)
  - `levels/chapter_2/level_1.gd`: chapter 2 level 1 template gameplay logic
  - `levels/level_bridge.gd`: bridge wrapper for level completion and placeholders
  - `line_canvas_2d.gd`: 2D line rendering control
- `assets/`
  - images and generated mesh assets
- `tools/`
  - generation scripts (for topology/assets)

## Input
Defined in `project.godot`:
- `rotate_sphere_left`
- `rotate_sphere_right`

## Notes
- Old 6-chapter placeholder path and old `levels/act_*` path were removed.
- If you add more levels later, append scenes in `scripts/main_entry.gd` sequence (or use `chapter_scene_overrides`).
