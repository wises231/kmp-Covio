---
id: E08-S02
title: "新增状态与交互路径"
labels: [documentation, phase-5-quality, area/contract]
type: Design
parent: E08
milestone: "P5 · 质量与交付"
blocked-by: [E02-S03]
---

## 背景

合同 `states.menuBarAndNotchHub.hubStates` 当前定义六个挂帘状态。
`E02-S03` 增加了 `PREVIEW` 与 `EDITING`。
`states.swiftRuntimeMapping` 把状态机映射到具体 Swift 文件与类型。

## 目标

让合同状态与实现逐字对应。

## 实施要点

1. `hubStates` 增加 `PREVIEW` 与 `EDITING`，各带 `copyKey` 与 `contractKey`。
2. `interactionPath` 更新为完整的迁移路径，包含新状态的进出。
3. 新增组件状态：组件网格的空状态、编辑态、拖动落位预览。
4. 新增页面状态矩阵行：`Widgets` 首页与工作区编辑器。
   现有矩阵的行在 `states.pageStateMatrix.rows`。
5. 更新 `states.swiftRuntimeMapping`，指向改名后的状态机文件。
6. 更新 `states.notchOutputHub` 的说明，明确它与挂帘状态正交。

## 验收标准

1. `hubStates` 有八个状态，且与 `HubStateMachine` 的实现一致。
2. `interactionPath` 无死状态，无不可达状态。
3. 页面状态矩阵覆盖 `Widgets` 首页与工作区编辑器，七列齐全。
4. `swiftRuntimeMapping` 的文件路径真实存在。
5. `python3 scripts/validate-contract.py` 通过。

## 依赖

`E02-S03`。
