---
id: E02-S01
title: "面板层级与 Space 行为收口"
labels: [enhancement, phase-1-curtain-core, area/shell, area/swift]
type: Task
parent: E02
milestone: "P1 · 挂帘内核"
blocked-by: []
---

## 背景

`macosApp/src/NotchShell/ShellPanels.swift:16` 的 `ShellPanel` 是全部面板的基类。
第 26 行先设 `isFloatingPanel`，第 27 行再设 `level = .statusBar`。
顺序颠倒会把层级重置为 3。这条约束记录在 `ADR-001`。

`HubPanel` 的 `canBecomeKey` 是 `true`，`becomesKeyOnlyIfNeeded` 是 `false`。
工作台需要键盘输入，同时不应抢走前台应用的焦点。

## 目标

确认工作台面板的层级、焦点与 Space 行为，并把这些行为固化为测试。

## 实施要点

1. 保持 `isFloatingPanel` 在 `level` 之前。
2. `collectionBehavior` 保持 `[.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]`。
3. 确认面板在菜单栏之上，且不遮挡菜单栏的点击。
4. 确认面板展开时前台应用的键盘焦点不被抢走，除非用户主动点击面板。
5. 增加一条测试，断言初始化顺序颠倒时层级会变化，防止后人误改。

## 验收标准

1. 挂帘显示在菜单栏之上。
2. 挂帘展开后，前台应用仍能接收键盘输入，直到用户点击挂帘。
3. 切换 Space 时挂帘不跟随移动。
4. `ShellPanelTests` 的 9 条用例继续通过。
5. 新增一条覆盖层级顺序约束的测试。

## 依赖

无。
