# A-ssemball

Godot 4.5 项目，包含一个开场交互场景与主交互场景：
- 开场：按住 `W` 前进，带有相机运动/呼吸/FOV 与暗角效果。
- 主场景：左侧 3D 球体与右侧 2D 线稿联动，支持键盘与拖拽旋转。

## 环境要求
- Godot `4.5`（项目配置为 `Mobile` 渲染管线）

## 运行方式
1. 使用 Godot 打开项目目录。
2. 直接运行主场景（`res://scenes/main_entry.tscn`，已在 `project.godot` 设为 `run/main_scene`）。
3. 首屏按 `Space` 开始流程。

## 操作说明
- 开场场景：
  - 按住 `W`：向前移动。
  - 到达终点后：鼠标左键点击白色球体，触发过场（震屏三次 -> 黑屏覆盖 -> 中线升起并短暂发光）后切换到主场景。
- 主场景（`Chapter1`）：
  - `A` / `Left`：向左旋转球体
  - `D` / `Right`：向右旋转球体
  - 鼠标左键在左侧 3D 视图拖拽：
    - 水平拖拽：分步旋转
    - 垂直拖拽：触发上/下面预览（短暂停留后回正）

## 项目结构
- `scenes/`
  - `main_entry.tscn`：入口场景（菜单 + 淡入淡出 + 场景切换）
  - `intro_interactive.tscn`：开场交互场景
  - `chapter_1.tscn`：主联动场景
- `scripts/`
  - `main_entry.gd`：流程控制与场景切换
  - `intro_interactive.gd`：开场相机运动与视觉效果
  - `chapter_1.gd`：3D/2D 联动交互逻辑
  - `line_canvas_2d.gd`：2D 线条绘制
- `assets/ui/`：界面图片资源

## 输入配置
本项目输入动作在 `project.godot` 中定义：
- `rotate_sphere_left`
- `rotate_sphere_right`

如需改键位，请在 Godot 编辑器中打开 `Project Settings > Input Map` 进行修改。

## 已完成的结构优化
- 水平旋转与垂直预览动画已拆分为独立 Tween，避免相互中断。
- 输入映射改为项目配置驱动，不再在运行时动态写入 `InputMap`。
