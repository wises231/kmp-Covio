---
id: E06-S01
title: "工作区设置 schema 与声明式渲染"
labels: [enhancement, phase-3-widgets, area/pane, area/swift]
type: Task
parent: E06
milestone: "P3 · Widgets 首页"
blocked-by: []
---

## 背景

现有设置行的渲染控件已齐备，都在 `macosApp/src/Hub/HubComponents.swift`：
`MacCard`、`MacSettingRow`、`MacSwitch`、`MacNumberField`、`MacSegmented`、`MacButton`。
设置页的渲染在 `macosApp/src/Hub/Settings/SettingsShell.swift`。

工作区设置需要一套声明结构，让每个工作区类型描述自己的设置项。

## 目标

定义设置项的声明结构，并用现有控件渲染。

## 实施要点

1. 新增 `PaneSettingDescriptor`，描述一行设置。字段至少包含
   `key`、`titleKey`、`summaryKey`、`control` 和默认值。
2. `control` 覆盖现有控件类型：开关、数字输入、分段选择、按钮。
3. 新增 `PaneSettingsSchema`，由每个工作区类型提供。
4. 渲染器把声明映射到 `MacSettingRow` 加对应控件。
5. 值存进 `PaneInstance.settings` 的键值结构。
6. 文案从合同文案键取值，不写死字符串。
7. 不支持未来新增的控件类型时显示只读占位，不崩溃。

## 验收标准

1. 四种控件类型都能渲染并写回值。
2. 值变更后立即持久化。
3. 未知控件类型渲染为只读占位。
4. 文案全部来自合同文案键。
5. 渲染器有单元测试。
6. 现有 `SettingsFormatTests` 继续通过。

## 依赖

无。
