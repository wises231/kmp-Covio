---
id: E04-S02
title: "导航栏渲染动态页签"
labels: [enhancement, phase-2-workspace-model, area/pane, area/swift]
type: Task
parent: E04
milestone: "P2 · 工作区模型"
blocked-by: [E04-S01]
---

## 背景

`macosApp/src/Hub/HubNavRail.swift:65` 用 `ForEach(HubTab.allCases)` 渲染。
选中态的滑动背景用 `matchedGeometryEffect`，标识是 `selectionID`（第 218 行）。
导航栏宽 200 点，顶部是搜索框，底部是运行状态、设置、语言与退出。

## 目标

导航栏渲染工作区实例列表，并支持拖动排序。

## 实施要点

1. 列表来源改为工作区实例。
2. 每一项显示图标与标题。标题过长时截断。
3. 选中态沿用 `matchedGeometryEffect`，标识改为实例 id。
4. 底部组保持不变。
5. 工作区数量超出可视高度时导航栏内部滚动。
6. 拖动排序只在编辑模式下启用。

## 验收标准

1. 页签数量与顺序来自配置。
2. 选中态动画与 0.5.0 一致。
3. 标题过长时截断，不撑破导航栏。
4. 工作区超过 10 个时导航栏可滚动。
5. 非编辑模式下拖动不改变顺序。
6. `HubMetricsTests` 的 9 条用例继续通过。

## 依赖

`E04-S01`。
