---
id: E02-S02
title: "展开与收起动效对齐合同"
labels: [enhancement, phase-1-curtain-core, area/shell, area/contract]
type: Task
parent: E02
milestone: "P1 · 挂帘内核"
blocked-by: []
---

> 本文的类型名、文件位置与职责边界以 `docs/design/workbench-architecture.md` 第 5 节为准。
> 本文的接口契约见 `E10-S02`（`ADR-005`）。

## 背景

设计合同规定挂帘展开用 220 至 280 毫秒的弹性曲线，收起用 160 至 220 毫秒的缓出曲线。
减少动态效果时只改变透明度，时长 120 毫秒。
现有常量在 `macosApp/src/Design/HubMotion.swift` 与 `HubMetrics.swift`。

## 目标

让实际动效与合同一致，并让常量只有一个来源。

## 实施要点

1. 核对 `HubMotion` 的展开与收起时长是否落在合同区间内。
2. 核对减少动态效果的分支是否只改透明度。
3. 时长常量若来自 `kmpDomain`，Swift 侧不要另写字面量。
4. 增加预览态的动效。预览态用短渐显，不做位移。
5. 增加编辑态的过渡。

## 验收标准

1. 展开时长在 220 至 280 毫秒之间。
2. 收起时长在 160 至 220 毫秒之间。
3. 开启减少动态效果后没有位移和弹性。
4. 预览态与编辑态各有过渡效果。
5. 时长常量只有一个来源。
6. `ShelfMotionTests` 的 15 条用例继续通过。

## 依赖

无。
