---
id: E08-S01
title: "新增组件：widget-card、widget-grid、pane-editor"
labels: [documentation, phase-5-quality, area/contract]
type: Design
parent: E08
milestone: "P5 · 质量与交付"
blocked-by: []
---

## 背景

合同里的组件都带 `composeMapping` 与 `swiftMapping` 两项映射。
`scripts/validate-contract.py` 检查 `swiftMapping` 在 macOS 上必须存在。
这条规则 schema 表达不了，所以由脚本检查。

## 目标

为工作台的新界面元素添加组件条目。

## 待添加的组件

| 组件键 | 用途 |
| --- | --- |
| `component/widget-card` | 网格中的一块组件。含选中、拖动、缩放、禁用状态。 |
| `component/widget-grid` | 组件网格容器。含空状态与编辑态。 |
| `component/pane-editor` | 工作区管理界面。含添加、改名、排序、删除确认。 |
| `component/trigger-settings-row` | 触发源开关行。含权限缺失状态。 |

## 实施要点

1. 每个组件条目包含状态变体、令牌引用与两项映射。
2. `composeMapping` 指向 Compose 侧的等价实现或注明不适用。
3. `swiftMapping` 指向实际的 Swift 类型与文件路径。
4. 令牌引用只用合同 `tokens` 里已有的键。缺令牌时先加令牌。
5. 组件计数等 `metadata.counts` 字段同步更新。

## 验收标准

1. 四个组件条目齐全，字段完整。
2. 每个组件都有 `swiftMapping`。
3. `python3 scripts/validate-contract.py` 通过。
4. `metadata.counts` 与实际数量一致。
5. 没有引用不存在的令牌键。

## 依赖

无。
