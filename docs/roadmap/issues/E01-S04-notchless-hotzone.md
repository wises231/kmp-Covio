---
id: E01-S04
title: "非刘海屏热区与全屏 Space 抑制"
labels: [enhancement, phase-1-curtain-core, area/trigger, area/shell]
parent: E01
milestone: "P1 · 挂帘内核"
blocked-by: [E00-S05, E01-S01]
---

## 背景

非刘海屏没有刘海，热区改成菜单栏下方的一条透明带。
`ScreenGeometry.hotZoneRect` 已返回 200×6 点的矩形。
尺寸取自 `HubMetrics.notchlessHotZoneWidth` 与 `notchlessHotZoneHeight`。

全屏 Space 中不应出现热区。现有判断在 `ScreenGeometry.isMenuBarVisible`。

## 目标

用实测数据确认非刘海屏热区的尺寸与位置，并收口全屏抑制逻辑。

## 实施要点

1. 按 `E00-S05` 的实测结论调整热区尺寸。
2. 热区必须避开菜单栏本身的点击区域，避免抢走菜单栏的鼠标事件。
3. 全屏 Space 切换时立即隐藏热区。
4. 显示器参数变化时重建热区。
5. 多显示器下每块屏幕各有一个热区，指针所在屏幕优先。

## 验收标准

1. 非刘海屏上鼠标移到菜单栏下方能打开挂帘。
2. 鼠标移到菜单栏本身时，菜单栏行为不变。
3. 进入全屏 Space 后热区不出现。
4. 退出全屏 Space 后热区恢复。
5. 拔掉外接屏后不残留热区面板。
6. 显示器分辨率改变后热区位置正确。

## 依赖

`E00-S05`、`E01-S01`。
