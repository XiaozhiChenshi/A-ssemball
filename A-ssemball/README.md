# A-ssemball

基于 Godot 4.5 的交互式关卡项目。项目入口是 `res://scenes/main_entry.tscn`，整体流程为：主菜单 -> 引导场景 -> 章节关卡序列。

## 运行环境

- Godot `4.5`（见 `project.godot` 的 `config/features`）
- Windows（仓库内包含已导出的 Windows 可执行文件）

## 启动方式

1. 用 Godot 打开项目根目录。
2. 运行主场景：`res://scenes/main_entry.tscn`。

## 项目结构

```text
A-ssemball/
├─ scenes/                         # 场景资源
│  ├─ main_entry.tscn              # 菜单与流程容器
│  ├─ intro_interactive.tscn       # 引导交互场景
│  ├─ chapter_1.tscn
│  ├─ chapter_3.tscn
│  └─ levels/                      # 分章节关卡与 source 场景
├─ scripts/                        # GDScript 逻辑
│  ├─ main_entry.gd                # 全局流程控制、章节切换、淡入淡出
│  ├─ intro_interactive.gd         # 引导交互、相机运动、点击白球过场
│  ├─ line_canvas_2d.gd            # 2D 绘制组件
│  ├─ levels/                      # 关卡脚本与桥接层
│  │  ├─ level_bridge.gd
│  │  ├─ chapter_1/
│  │  └─ chapter_2/
│  └─ structure/                   # 结构拓扑与网格构建
│     ├─ structure_shape_provider.gd
│     ├─ structure_mesh_builder.gd
│     ├─ structure_off_loader.gd
│     ├─ structure_shape_data.gd
│     ├─ structure_cell_data.gd
│     └─ goldberg_topology_generator.gd
├─ assets/                         # 模型、材质、UI 纹理、生成资源
│  ├─ generated/goldberg/          # Goldberg OFF/OBJ 资产
│  ├─ materials/
│  ├─ textures/
│  └─ ui/
├─ tools/
│  └─ generate_goldberg_assets.ps1 # 生成 Goldberg 资产脚本
├─ project.godot                   # Godot 项目配置
├─ export_presets.cfg              # 导出配置
└─ The Convergence Sphere*.exe/pck # 已导出的 Windows 产物
```

## 流程说明

- `main_entry.gd` 负责：
  - 菜单输入（空格开始、数字键跳转章节）
  - 引导场景实例化
  - 章节关卡按序推进
  - 章节完成信号 `chapter_completed` 的监听与切场

- `intro_interactive.gd` 负责：
  - 按住 `W` 前进的引导交互
  - 相机动态效果（呼吸 FOV、晃动、暗角）
  - 白球点击检测与转场特效
  - 完成时发出 `intro_finished`

## 输入映射（project.godot）

- `rotate_sphere_left`：`A` / Left
- `rotate_sphere_right`：`D` / Right
- 引导场景前进默认按键：`W`（由 `intro_interactive.gd` 导出参数控制）

## 资产生成

`tools/generate_goldberg_assets.ps1` 用于批量生成 `assets/generated/goldberg/` 下的几何资产（`.off/.obj`）。如需复现，请确保对应外部几何工具链已安装并可被脚本调用。

## 备注

- `.godot/` 与 `.idea/` 为编辑器/缓存目录，不是核心业务逻辑。
- 根目录已有 `work.md`，可作为开发过程记录。
