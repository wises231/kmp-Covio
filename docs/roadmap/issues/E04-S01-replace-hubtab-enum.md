---
id: E04-S01
title: "用工作区实例替换 HubTab 枚举"
labels: [enhancement, phase-2-workspace-model, area/pane, area/swift]
type: Task
parent: E04
milestone: "P2 · 工作区模型"
blocked-by: [E03-S05, E04-S04]
---

> 本文的类型名、文件位置与职责边界以 `docs/design/workbench-architecture.md` 第 6 节为准。
> 本文的接口契约见 `E10-S03`（`ADR-006`）。

## 背景

`macosApp/src/Hub/HubTab.swift:10` 的 `HubTab` 被三处使用：
`HubNavRail` 的渲染、`HubView` 的内容分发、`CurtainController` 的 `selection` 字段。

## 目标

用 `PaneInstance` 的 id 替换 `HubTab` 作为选中标识。内容分发改走 `PaneRegistry`。

## 实施要点

1. `CurtainController.selection` 的类型从 `HubTab` 改为工作区实例 id。
2. `HubView` 的 `HubTabContent` 改为向 `PaneRegistry` 查询视图。
3. 删除 `HubView.swift:224` 的 `HubPlaceholderView` 兜底分支，改用注册表的占位视图。
4. `HubTab` 枚举可以保留，仅用于承载 `PaneKind` 的默认标题与图标，或整体删除。
5. 选中项被删除时自动切换到相邻工作区。
6. 保留设置页的搜索跳转能力。搜索结果需要能定位到工作区实例。

## 验收标准

1. `HubView` 的内容分发不再使用枚举 `switch`。
2. 删除当前选中的工作区后，选中项自动切换到相邻项。
3. 设置搜索仍能跳转并高亮目标行。
4. 现有 `SettingsSearchTests` 的 19 条用例继续通过。
5. 编译无 `HubTab` 残留引用，或有明确保留理由的注释。

## 依赖

`E03-S05`、`E04-S04`。

**待裁决**：`HubTab` 枚举是删除还是保留。归 `E10-S03`（`ADR-006`）。
**待裁决**：工作区数量的上限，以及内置工作区能否删除。归 `E10-S03`（`ADR-006`）。
