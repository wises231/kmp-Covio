---
id: E05-S02
title: "网格布局引擎"
labels: [enhancement, phase-3-widgets, area/widget, area/kmp]
type: Task
parent: E05
milestone: "P3 · Widgets 首页"
blocked-by: [E05-S01]
---

> 本文的类型名、文件位置与职责边界以 `docs/design/workbench-architecture.md` 第 7 节为准。
> 本文的接口契约见 `E10-S04`（`ADR-007`）。

## 背景

`Widget` 要吸附到网格，不能任意摆放。
吸附、占位冲突和自动补位是纯逻辑。纯逻辑放在 `kmpDomain` 才能测试。
现有同类做法的样例是 `WorkspaceLogic`（`WorkspaceStore.kt:611`）与
`ClipboardLogic`（`ClipboardStore.kt:84`）。

## 目标

实现网格的列数计算、吸附、冲突检测与自动补位。

## 实施要点

1. 新增 `object WidgetGridLogic`。
2. 列数由可用宽度与最小组件宽度计算。建议 4 列，宽屏 6 列。
3. 实现 `snap(position, size, columns)`。
4. 实现 `canPlace(placed, candidate, columns)` 冲突检测。
5. 实现 `firstFreeSlot(placed, size, columns)` 自动补位。
6. 实现 `compact(placed, columns)` 去除空洞。
7. 组件缩放后重新计算位置。放不下时回退到原位。
8. 全部函数是纯函数，不做 IO。

## 验收标准

1. 组件吸附到整数格。
2. 两个组件不重叠。
3. 添加组件时自动找到空位。
4. 删除组件后下方组件自动上移。
5. 缩放放不下时回退，不产生重叠。
6. 测试用例不少于 25 条，在 jvm 与 macosArm64 两个目标上通过。

## 依赖

`E05-S01`。
