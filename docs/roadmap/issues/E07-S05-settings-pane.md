---
id: E07-S05
title: "设置工作区"
labels: [enhancement, phase-4-module-panes, area/pane, area/swift]
parent: E07
milestone: "P4 · 模块工作区化"
blocked-by: [E06-S01]
---

## 背景

设置页已存在：`macosApp/src/Hub/Settings/SettingsShell.swift`，
六个分节页面在 `macosApp/src/Hub/Settings/pages/` 下。
分节枚举是 `SettingsSection`（`SettingsSection.swift:9`）。

## 目标

把设置页接入工作区体系。设置本身保持六节。

## 实施要点

1. 页面改为由 `PaneRegistry` 提供。
2. 保留六个分节与全部现有设置行。
3. 胶囊上的分节分段选择器保持不变。
4. 新增一节“工作台”，集中放触发源开关、工作区管理与重置入口。
5. 搜索仍能跨节跳转与高亮。
6. 设置行锚点机制不变。

## 验收标准

1. 六个分节全部可用，现有设置行不丢失。
2. 新增“工作台”一节，包含触发源开关、工作区管理、重置。
3. 现有 `ContractConstantsTests.swift` 里的 `SettingsSectionTests` 更新并通过。
4. 搜索跨节跳转与 1.2 秒高亮保持。
5. 设置行锚点覆盖率测试继续通过。

## 依赖

`E06-S01`。
