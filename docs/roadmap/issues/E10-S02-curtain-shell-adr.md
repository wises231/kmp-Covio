---
id: E10-S02
type: Design
title: "挂帘外壳契约：ADR-005"
labels: [documentation, phase-6-architecture, area/shell, area/architecture]
parent: E10
milestone: "P6 · 架构落地"
blocked-by: [E10-S01]
---

## 背景

骨架第 5 节要求把 `NotchShellController` 改名为 `CurtainController`，
并给 `HubStateMachine` 增加 `PREVIEW` 和 `EDITING` 两个状态，共八态。
骨架只写到状态名。

两件事没有定。
第一，改名的范围。当前类型在 `macosApp/src/NotchShell/NotchShellController.swift:14`，
目录名是 `NotchShell`。新概念在中文里叫「挂帘」，目录名与概念已经脱节。
第二，`PREVIEW` 与 `EDITING` 的进入与退出条件。状态机现在只有迁移表，没有新状态的迁移边。

这两件事定不下来，`E02` 的四个 sub-issue 无法开工。

## 待决策

1. 改名的范围：只改类型名，还是连文件与目录一起改。
2. `PREVIEW` 的进入条件与退出条件。它与 `HOVER` 的边界画在哪里。
3. `EDITING` 的进入条件与退出条件。编辑模式下 `ACTIVE` 是否仍然可达。
4. `ERROR` 在八态迁移表里的位置。
5. 外壳改为持有「当前工作区编号」后，`HubTab` 字段的移除范围。

## 候选方案

### 方案 A：只改类型名

文件仍叫 `NotchShellController.swift`，目录仍是 `NotchShell/`。

代价：文件名与类型名不一致。目录名与产品概念脱节。
适用条件：改名只求概念对齐，不求路径对齐。

### 方案 B：类型名、文件名与目录名一起改

改成 `macosApp/src/Curtain/CurtainController.swift`。

代价：一次改动跨多个文件与构建配置。历史 blame 断裂。
适用条件：改名趁早做，避免后续改动叠加。

### 方案 C：改类型名与文件名，目录名不动

代价：折中方案，仍留一层不一致。
适用条件：目录改名会牵动构建配置，代价高于收益。

## 判定依据

1. 与骨架第 3.1 节的平台边界一致。
2. 改动的可评审性：一次 PR 能否看完。
3. 不扩大 `E02-S01` 的范围。`E02-S01` 已要覆盖现有 9 条 `ShellPanelTests`，见路线图第 9.2 节的 `R-04`。
4. 状态数增加后，迁移表仍能逐条手工核对。

## 决策

待定。

## 证据

1. `macosApp/src/NotchShell/NotchShellController.swift:14`。
2. `macosApp/src/NotchShell/HubStateMachine.swift:8` 是六态，`:108` 是迁移表。
   迁移表当前是 `HIDDEN → HOVER → OPEN → ACTIVE → EXIT → HIDDEN`，另有 `ERROR → OPEN`。
3. `macosApp/src/NotchShell/ShellPanels.swift:16` 的 `ShellPanel`。第 26 行先设 `isFloatingPanel`，再设 `level = .statusBar`。顺序颠倒会把层级重置为 3。
4. 骨架第 5 节的类型表与四条迁移说明。

以上 1 到 3 为事实，来自文件内容核对。

## 影响

1. 约束 `E02-S01` 到 `E02-S04`。
2. `E01`、`E01-S01`、`E01-S06`、`E04-S01` 正文里的 `NotchShellController` 按结论改写。
3. `E02-S03` 当前把迁移表写成 `HubStateMachine.swift:101`，按结论改为 `:108`。
4. 骨架第 5 节按结论回填改名范围与迁移表。

## 依赖

`E10-S01`。外壳只认识 `CurtainTrigger` 协议，协议的边界先定。
