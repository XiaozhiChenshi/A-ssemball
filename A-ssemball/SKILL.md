# A-ssemball 项目协作技能说明

本文件用于约束 AI/协作者在本仓库中的改动方式，减少误改与结构漂移。

## 目标

- 在不破坏既有流程的前提下迭代关卡、交互和结构生成逻辑。
- 保持 `scenes/`（场景装配）与 `scripts/`（行为逻辑）分层清晰。

## 快速上下文

- 引擎：Godot 4.5
- 项目入口：`res://scenes/main_entry.tscn`
- 主流程脚本：`scripts/main_entry.gd`
- 引导场景脚本：`scripts/intro_interactive.gd`

## 目录职责

- `scenes/`：节点组织、UI 与 3D 场景装配。
- `scripts/`：可复用逻辑与关卡行为实现。
- `scripts/levels/level_bridge.gd`：关卡桥接层（承接 source 场景与完成信号）。
- `scripts/structure/`：结构数据、拓扑加载、网格构建。
- `assets/generated/goldberg/`：结构几何资产输入（OFF/OBJ）。
- `tools/generate_goldberg_assets.ps1`：几何资产生成脚本。

## 改动规范

1. 新增关卡时，优先新增 `source_level_x.tscn + 对应脚本`，再通过 bridge 场景接入流程。
2. 不要直接改 `.godot/` 与 `.idea/` 下文件。
3. 对结构系统的改动应保持以下接口稳定：
   - shape provider -> shape data
   - off loader -> cell data
   - mesh builder -> 可渲染网格 + 邻接关系
4. 涉及切场流程时，优先沿用信号驱动（`intro_finished` / `chapter_completed`），避免硬编码等待时间。
5. 仅在必要时改动 `project.godot` 输入映射；改动后需同步文档。

## 验证清单

- 能从 `main_entry.tscn` 正常进入引导与后续关卡。
- 章节完成后可稳定切到下一关，不出现重复连接信号的问题。
- 新增或修改的结构资源可正常加载，不触发空网格或索引越界。
- 关键路径无报错：菜单开始、引导完成、关卡推进。

## 文档同步要求

- 若改动了目录结构、入口场景、输入映射、工具链，必须同步更新 `README.md`。
- 若改动了本文件约束本身，提交中要说明“规范变更原因”。
