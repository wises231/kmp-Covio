---
id: E05-S03
title: "组件目录与添加流程"
labels: [enhancement, phase-3-widgets, area/widget, area/swift]
parent: E05
milestone: "P3 · Widgets 首页"
blocked-by: [E05-S02]
---

## 背景

用户需要一个地方浏览可添加的组件。
现有设置页有类似的声明式目录：`macosApp/src/Hub/Settings/SettingsCatalog.swift:69`
的 `SettingsCatalog.entries` 用一条 `SettingsCatalogEntry` 描述一行。

## 目标

提供组件目录和添加流程。

## 实施要点

1. 新增 `WidgetCatalog`，声明每个组件类型的名称、说明、图标和可用尺寸档。
2. 目录文案按 `E08-S03` 的键取值。
3. 添加入口：编辑模式下的“添加组件”按钮。
4. 添加流程：选择类型，选择尺寸，确认。新组件放在第一个空位。
5. 目录显示每个组件的可用尺寸档。不可用的档位置灰。
6. 组件类型重复添加的行为要明确。允许重复，或置灰已添加项。

## 验收标准

1. 目录列出全部组件类型。
2. 添加后组件出现在网格的空位。
3. 添加后立即持久化。
4. 组件说明与图标来自合同文案，不写死字符串。
5. 目录的覆盖有测试：每个 `WidgetKind` 都在目录里。

## 依赖

`E05-S02`。
