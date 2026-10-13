---
id: E02-S03
title: "状态机扩展：PREVIEW 与 EDITING"
labels: [enhancement, phase-1-curtain-core, area/shell, area/contract]
type: Task
parent: E02
milestone: "P1 · 挂帘内核"
blocked-by: []
---

> 本文的类型名、文件位置与职责边界以 `docs/design/workbench-architecture.md` 第 5 节为准。
> 本文的接口契约见 `E10-S02`（`ADR-005`）。

## 背景

`macosApp/src/NotchShell/HubStateMachine.swift:108` 的迁移表当前是
`HIDDEN → HOVER → OPEN → ACTIVE → EXIT → HIDDEN`，另有 `ERROR → OPEN`。

设计合同 `states.menuBarAndNotchHub.hubStates` 定义六个状态：
`HIDDEN`、`HOVER`、`OPEN`、`ACTIVE`、`EXIT`、`ERROR`。
合同另有一个正交的状态机 `states.notchOutputHub`，由 `HubOutputState` 实现。

工作台需要两个新状态：悬停预览与布局编辑。

## 目标

扩展状态机，并同步设计合同。

## 实施要点

1. 新增 `PREVIEW`：指针进入热区但未达停留阈值。
2. 新增 `EDITING`：用户正在编辑工作区布局。
3. `EDITING` 状态下禁止指针移出自动收起。
4. `EDITING` 状态由 Escape 或“完成”按钮退出。
5. 更新 `docs/covio-design-contract.json` 的 `hubStates` 与 `interactionPath`。
6. 更新合同中的 `swiftRuntimeMapping`，指向新的状态机文件。

## 验收标准

1. 迁移表覆盖全部八个状态，且没有死状态。
2. `EDITING` 状态下指针移出不会收起挂帘。
3. Escape 退出 `EDITING`，再按 Escape 收起挂帘。
4. `HubStateMachineTests` 的 13 条用例更新并通过。
5. 合同与实现逐字对应。

## 依赖

无。

**待裁决**：`PREVIEW` 与 `EDITING` 的进入与退出条件，以及完整八态迁移表。归 `E10-S02`（`ADR-005`）。
