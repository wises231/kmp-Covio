---
id: E06-S03
title: "设置搜索纳入工作区设置"
labels: [enhancement, phase-3-widgets, area/pane, area/swift]
type: Task
parent: E06
milestone: "P3 · Widgets 首页"
blocked-by: [E06-S02, E04-S01]
---

> 本文的类型名、文件位置与职责边界以 `docs/design/workbench-architecture.md` 第 6 节为准。
> 本文的接口契约见 `E10-S03`（`ADR-006`）。

## 背景

设置搜索的元数据在 `SettingsCatalog.entries`（`SettingsCatalog.swift:69`）。
搜索逻辑在 `SettingsSearchIndex.search`（`SettingsSearchIndex.swift:28`），
最多 8 条结果，高亮 1.2 秒。
行锚点用 `.settingsRowAnchor(_:)`，高亮通过环境值 `\.highlightedSettingsRow`。

工作区设置是数据，不在固定目录里。搜索索引需要动态构建。

## 目标

让工作区设置进入全局搜索，并能跳转并高亮。

## 实施要点

1. 搜索索引构建时遍历 `WorkbenchConfig` 里全部工作区的设置声明。
2. 结果的跳转目标包含工作区 id，跳转时先切换到该工作区。
3. 高亮时长沿用 1.2 秒。
4. 索引构建失败时退化为只搜索固定目录，不崩溃。
5. 搜索关键字包含中英文标题。

## 验收标准

1. 搜索能找到工作区设置项。
2. 选中结果后切换到对应工作区并高亮该行。
3. 高亮时长与 0.5.0 一致。
4. 结果数量上限保持 8。
5. 现有 `SettingsSearchTests` 的 19 条用例继续通过。
6. 新增覆盖工作区设置的搜索用例。

## 依赖

`E06-S02`、`E04-S01`。

**待裁决**：索引构建失败后的退化不在骨架第 9 节的三条降级路径内，其用户可见性与记录位置未定。归 `E10-S06`（`ADR-009`）。
