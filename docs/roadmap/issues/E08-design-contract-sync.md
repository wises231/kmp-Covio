---
id: E08
title: "设计合同与文案同步"
labels: [epic, phase-5-quality, area/contract, documentation]
type: Goal
parent: null
milestone: "P5 · 质量与交付"
blocked-by: [E04]
---

## 背景

`docs/covio-design-contract.json` 是设计权威。
每个组件同时带 `composeMapping` 和 `swiftMapping`。
`macosApp/src/Design/ContractCopy.swift` 与 `ContractTokens.swift` 是生成文件，不要手改。

工作台引入了新组件、新状态和新文案。合同必须同步。
`scripts/validate-contract.py` 检查 schema 表达不了的跨节规则。
`scripts/generate-contract-constants.py` 重写 Swift 常量。

## 目标

让合同覆盖工作台的全部新界面元素，并让生成文件与合同一致。

## 范围

范围内：

- 新增组件条目与映射。
- 新增状态与交互路径。
- 新增文案键与中英对照。
- 重跑校验与生成脚本。
- 更新产品总稿相关章节。

范围外：

- 视觉设计本身。合同描述已确定的规格。

## 子项

- [ ] `E08-S01` 新增组件：`widget-card`、`widget-grid`、`pane-editor`
- [ ] `E08-S02` 新增状态与交互路径
- [ ] `E08-S03` 新增文案键与中英对照
- [ ] `E08-S04` 重跑校验与生成脚本

## 退出条件

1. `python3 scripts/validate-contract.py` 通过。
2. 生成文件已重跑，`ContractCopy.swift` 与 `ContractTokens.swift` 与合同一致。
3. 全部合同测试通过。
4. 产品总稿的 4.2、4.4 与 6.3 节已更新。

## 依赖

`E04`。合同条目可以在开发过程中逐步添加，本 epic 负责收口。
