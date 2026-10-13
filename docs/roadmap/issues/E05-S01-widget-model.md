---
id: E05-S01
title: "Widget 实例模型与尺寸档"
labels: [enhancement, phase-3-widgets, area/widget, area/kmp]
type: Task
parent: E05
milestone: "P3 · Widgets 首页"
blocked-by: [E03-S01]
---

> 本文的类型名、文件位置与职责边界以 `docs/design/workbench-architecture.md` 第 7 节为准。
> 本文的接口契约见 `E10-S04`（`ADR-007`）。

## 背景

组件需要一个可序列化的实例模型。模型要能嵌进 `PaneInstance`。
现有模型的写法在 `kmpDomain/src/com/wyz/covio/core/Models.kt`。
该文件要求每个可序列化类型提供 `companion { fun defaults() }`。

## 目标

定义组件实例、组件类型与尺寸档。

## 实施要点

1. 新增 `WidgetInstance`。字段至少包含 `id`、`kind`、`size`、`column`、`row`、`settings`。
2. 新增 `WidgetKind` 枚举。初始成员对应 `E05-S05` 的五个组件。
3. 新增 `WidgetSize` 枚举。建议三档：`small`、`medium`、`large`。
4. `WidgetSize` 携带它在网格中占用的列数与行数。
5. 为每个类型提供 `defaults()`。
6. 尺寸档的具体列数与行数由 `E05-S02` 确认，本 issue 先定义结构。

## 验收标准

1. `WidgetInstance` 可序列化，且提供 `defaults()`。
2. 序列化稳定，同一输入两次编码字节相同。
3. 未知的 `WidgetKind` 在读取时降级为占位组件，不导致整体读取失败。
4. Swift 侧可以构造并读回字段。
5. 有往返测试。

## 依赖

`E03-S01`。

**待裁决**：组件实例的标识符用 `WidgetInstance`，还是用骨架第 7 节的 `Widget`。归 `E10-S04`（`ADR-007`）。
