# A-ssemball

基于 **Godot 4.5** 的交互式关卡项目。核心玩法是“左侧 3D 结构交互 + 右侧 2D 信息/线稿联动”，并通过章节顺序驱动流程。

## 一、整体运行架构

运行入口在 `project.godot`：

- 主场景：`res://scenes/main_entry.tscn`
- 脚本：`res://scripts/main_entry.gd`

运行链路如下：

1. `main_entry.tscn`（菜单与黑幕过渡）
2. `intro_interactive.tscn`（引导交互）
3. 章节关卡序列（默认 6 关）：
   - `chapter_1/level_1`
   - `chapter_1/level_2`
   - `chapter_2/level_1`
   - `chapter_2/level_2`
   - `chapter_3/level_1`
   - `chapter_3/level_2`

`main_entry.gd` 通过 `chapter_completed` 信号推进下一关，统一处理淡入淡出、场景装载、流程控制。

## 二、目录与模块分层

```text
A-ssemball/
├─ scenes/                    # 场景层（UI/3D节点装配）
│  ├─ main_entry.tscn         # 启动菜单与流程容器
│  ├─ intro_interactive.tscn  # 引导场景
│  └─ levels/                 # 关卡场景（桥接层 + source 实际关卡）
├─ scripts/                   # 逻辑层
│  ├─ main_entry.gd           # 关卡流程总控
│  ├─ intro_interactive.gd    # 引导场景交互与过渡特效
│  ├─ line_canvas_2d.gd       # 2D线段绘制组件
│  ├─ levels/                 # 关卡脚本与关卡桥接
│  └─ structure/              # 几何结构数据/网格生成链路
├─ assets/                    # 美术与生成资源（含 goldberg OFF/OBJ）
├─ tools/                     # 外部资源生成脚本（PowerShell）
└─ project.godot              # Godot 项目配置
```

## 三、流程控制层（Flow Layer）

### 1) `scripts/main_entry.gd`

- 负责菜单输入（空格开局、数字键跳关）。
- 负责 Intro 场景与章节场景切换。
- 维护章节列表（可通过 `chapter_scene_overrides` 覆盖）。
- 监听关卡的 `chapter_completed`，并推进到下一个章节场景。

### 2) `scripts/intro_interactive.gd`

- 引导阶段相机前进、呼吸 FOV、暗角、目标球点击判定。
- 完成后发出 `intro_finished` 信号交还给 `main_entry.gd`。
- 支持“从菜单直接跳过引导演出效果”的入口调用。

## 四、关卡层（Level Layer）

### 1) 关卡桥接脚本：`scripts/levels/level_bridge.gd`

`level_bridge.gd` 是统一关卡壳层，职责：

- 可挂载 `source_scene`（真实关卡场景）。
- 如果 source 场景本身会发 `chapter_completed`，桥接层转发该完成事件。
- 如果没有 source，则展示占位 UI，按 `Enter` 触发完成（便于流程联调）。

### 2) 当前关卡接线状态

- Chapter 1
  - `level_1.tscn` -> `source_level_1.tscn`（已接入真实玩法：`level_1.gd`）
  - `level_2.tscn` -> `source_level_2.tscn`（已接入真实玩法：`level_2.gd`）
- Chapter 2
  - `level_1.tscn`（当前为桥接占位，未绑定 source）
  - `level_2.tscn`（桥接占位）
  - `source_level_1.tscn`（存在真实脚本 `level_1.gd`，可后续接入）
- Chapter 3
  - `level_1.tscn`、`level_2.tscn`（桥接占位）

## 五、结构几何层（Structure Layer）

核心目录：`scripts/structure/`

- `structure_shape_provider.gd`
  - 对外统一提供 `dodecahedron / icosahedron / goldberg(m,n)` 结构数据。
  - 管理形状缓存，避免重复构建。
- `structure_off_loader.gd`
  - 从 `assets/generated/goldberg/*.off` 读取多面体面数据并转换为运行时结构。
- `structure_mesh_builder.gd`
  - 基于 cell 数据构建：
  - `body_mesh`（主体网格）
  - `edge_mesh`（动态边线网格）
  - `static_edge_mesh`（Goldberg 脚手架边线）
  - 同时计算 cell 邻接关系（`neighbors`）。
- `structure_shape_data.gd` / `structure_cell_data.gd`
  - 结构体数据定义（形状级、cell 级）。
- `goldberg_topology_generator.gd`
  - 通过几何算法在运行时生成 Goldberg 拓扑（当前主流程主要使用 OFF 资产加载）。

## 六、工具链与资产生成

`tools/generate_goldberg_assets.ps1`：

- 依赖 Antiprism 工具链（`geodesic.exe / pol_recip.exe / off2obj.exe / off_report.exe`）。
- 批量生成 `g_m_n.off/.obj` 到 `assets/generated/goldberg/`。
- 目前脚本内置生成集合：`(2,1) (3,0) (3,3) (4,4) (8,8) (1,4)`。

## 七、输入与交互映射

`project.godot` 已定义动作：

- `rotate_sphere_left`（A / Left）
- `rotate_sphere_right`（D / Right）

部分关卡还直接读取 `WASD` 与鼠标左键用于旋转、点击或拖拽交互。

## 八、后续扩展建议（按当前架构）

1. 新增关卡：优先新增 `source_level_x.tscn + 对应脚本`，再由 `level_bridge.tscn` 接线。
2. 新增章节流程：在 `main_entry.gd` 的章节数组追加场景，或通过 `chapter_scene_overrides` 覆盖。
3. 新增结构类型：在 `structure_shape_provider.gd` 扩展 shape_id 分派，并复用 `structure_mesh_builder.gd` 输出统一网格格式。
