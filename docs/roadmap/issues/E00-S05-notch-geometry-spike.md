---
id: E00-S05
title: "Spike：刘海几何与多显示器实测"
labels: [spike, phase-0-research, area/shell]
type: Task
parent: E00
milestone: "P0 · 调研与决策"
blocked-by: []
---

## 背景

挂帘的触发区依赖屏幕几何。
`macosApp/src/NotchShell/ScreenGeometry.swift:39` 的 `hotZoneRect` 已区分刘海屏与非刘海屏。
刘海识别、外接屏和全屏 Space 的取值需要真机数据确认。

## 目标

采集本机在各显示器组合下的真实几何值，作为 `E01-S03` 与 `E01-S04` 的输入。

## 待采集的字段

对每一块屏幕记录：

1. `NSScreen.frame`
2. `NSScreen.visibleFrame`
3. `NSScreen.safeAreaInsets`
4. `NSScreen.auxiliaryTopLeftArea`
5. `NSScreen.auxiliaryTopRightArea`
6. 是否存在刘海（由前两项推断）
7. 菜单栏高度

## 覆盖场景

1. 内置刘海屏单独使用。
2. 外接非刘海屏单独使用。
3. 内置屏加外接屏，主屏分别为两块屏幕。
4. 外接屏位于内置屏的左侧和上方。
5. 进入全屏 Space。
6. 显示器分辨率改变后。

## 交付物

把原始数据写入 `docs/research/trackpad-gesture-entry/evidence.md`，
或按 `docs/research/AUTHORING.md` 另建主题目录。
结论写入 `conclusion.md`，并给出 `hotZoneRect` 的修正建议。

## 验收标准

1. 每个场景都有命令、输出摘要和观察。
2. 记录 macOS 版本与机型。
3. 给出非刘海屏热区的推荐尺寸。
4. 给出全屏 Space 抑制的判定条件。
5. 不写入设备序列号等敏感信息。

## 依赖

无。
