---
id: E01-S03
title: "刘海悬停触发精修"
labels: [enhancement, phase-1-curtain-core, area/trigger, area/shell]
parent: E01
milestone: "P1 · 挂帘内核"
blocked-by: [E00-S05, E01-S01]
---

## 背景

现有热区已经覆盖刘海区域。缺少三项能力。
第一项是悬停预览态。指针进入后先出现预览，停留后才展开。
第二项是停留时长的可配置化。
第三项是权限与降级的明确处理。

设计合同已定义六个挂帘状态：`HIDDEN`、`HOVER`、`OPEN`、`ACTIVE`、`EXIT`、`ERROR`。
`HOVER` 状态当前没有实现。

## 目标

把刘海悬停做成一个完整的触发源，并实现 `HOVER` 预览态。

## 实施要点

1. 把 `PointerTrackingHost` 与 `ScreenGeometry.hotZoneRect` 的逻辑包成一个触发源。
2. 指针进入热区后发出预览事件。停留超过阈值后发出打开事件。
3. 停留阈值放进 `kmpDomain`，与 `ShelfPresencePolicy` 的常量风格一致。
4. 指针离开热区后取消预览。
5. 复用 `HubMetrics.notchlessHotZoneWidth` 与 `notchlessHotZoneHeight` 的现有常量。

## 验收标准

1. 指针进入刘海区域后出现预览态。
2. 停留达到阈值后展开。
3. 未达阈值就离开时不展开。
4. 预览态在开启“减少动态效果”时只改变透明度。
5. 阈值常量来自 `kmpDomain`，不在 Swift 里写字面量。
6. `ScreenGeometryTests` 的 14 条用例继续通过。

## 依赖

`E00-S05`、`E01-S01`。
