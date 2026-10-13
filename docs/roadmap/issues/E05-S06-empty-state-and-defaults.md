---
id: E05-S06
title: "空状态与首次启动默认布局"
labels: [enhancement, phase-3-widgets, area/widget, area/swift]
parent: E05
milestone: "P3 · Widgets 首页"
blocked-by: [E05-S05]
---

## 背景

首次启动时首页是空的。用户需要知道可以添加组件。
现有页面已有空状态写法，参考 `macosApp/src/Hub/ClipboardTabView.swift` 的空态分支。

## 目标

定义空状态界面与首次启动的默认布局。

## 实施要点

1. 空状态显示一句说明和一个“添加组件”按钮。
2. 说明文案按 `E08-S03` 的键取值。
3. 首次启动生成默认布局：电源组件（中档）加剪切板组件（中档）。
4. 默认布局由 `E03-S02` 的 `defaultLayout()` 产生，不在 Swift 里写死。
5. 用户删光全部组件后回到空状态，不自动恢复默认布局。

## 验收标准

1. 空状态显示说明与添加按钮。
2. 首次启动出现两个默认组件。
3. 用户删光组件后显示空状态，且重启后仍是空状态。
4. 默认布局定义在 `kmpDomain`，Swift 侧不写死。
5. 有覆盖默认布局的测试。

## 依赖

`E05-S05`。
