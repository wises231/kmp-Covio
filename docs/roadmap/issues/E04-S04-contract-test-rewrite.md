---
id: E04-S04
title: "改写页签顺序断言与合同测试"
labels: [enhancement, phase-2-workspace-model, area/test, area/contract]
type: Task
parent: E04
milestone: "P2 · 工作区模型"
blocked-by: []
---

## 背景

`macosApp/test/DesignContractTests.swift` 断言页签顺序与合同一致。
`kmpDomain/test/com/wyz/covio/core/DesignContractTest.kt` 有 19 条用例。
`macosApp/test/ContractConstantsTests.swift` 有 27 条用例。

页签改成数据驱动后，顺序断言的对象从枚举变成配置。
这些测试必须同步改写。

## 目标

在改造开始前改写断言，避免改造期间测试长期失败。

## 实施要点

1. 页签顺序断言改为断言“默认布局的顺序”与合同一致。
2. 合同新增的字段由 `E08` 提供。本 issue 先建立断言结构。
3. 保留“合同里的页签都在注册表里”的覆盖断言。
4. 增加一条断言：注册表里的每个 `PaneKind` 都有对应的视图构造器。

## 验收标准

1. 顺序断言针对默认布局，不针对枚举。
2. 存在一条断言检查注册表覆盖全部 `PaneKind`。
3. 改造期间 `DesignContractTests` 保持通过。
4. 新增断言在缺少视图构造器时失败。
5. 现有 12 条用例的语义不丢失。

## 依赖

无。本 issue 必须先于 `E04-S01` 完成。

## 顺序说明

本 issue 的 `blocked-by` 为空，但它是 `E04-S01` 的前置。
顺序由本 issue 与 `E04-S01` 的 `blocked-by` 关系共同保证。
