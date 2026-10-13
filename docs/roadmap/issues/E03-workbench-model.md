---
id: E03
title: "工作区模型：把页签变成数据"
labels: [epic, phase-2-workspace-model, area/pane, area/kmp]
parent: null
milestone: "P2 · 工作区模型"
blocked-by: [E00]
---

## 背景

`macosApp/src/Hub/HubTab.swift:10` 的 `HubTab` 是六值枚举。
页面渲染是 `HubView.swift:186` 里的 `switch`。
需求要求页签可增删改名排序，并支持每个工作区独立设置。
枚举无法承载这些能力。

## 目标

把页签从枚举改成数据。数据放在 `kmpDomain`，Swift 侧只做渲染。

## 范围

范围内：

- 数据模型、纯逻辑与持久化。
- 配置迁移与损坏恢复。
- Swift 侧的注册表与存储客户端。

范围外：

- 导航栏渲染与编辑器界面。见 `E04`。
- 组件网格。见 `E05`。
- 每工作区设置界面。见 `E06`。

## 命名约束

新标识符用 `Pane`，不用 `Workspace`。
现有 `WorkspaceStore`、`WorkspaceEntry`、`WorkspaceKind`、`WorkspaceRuntime.swift`
全部指跨设备共享暂存区。直接复用会重名。
完整对照见路线图第 4 节。

## 子项

- [ ] `E03-S01` `WorkbenchConfig` 与 `PaneInstance` 数据模型
- [ ] `E03-S02` `WorkbenchLogic` 纯逻辑
- [ ] `E03-S03` `WorkbenchStore` 持久化
- [ ] `E03-S04` 迁移、回退与损坏恢复
- [ ] `E03-S05` Swift 侧 `PaneRegistry` 与 `WorkbenchStoreClient`

## 退出条件

1. 工作台配置可以无损往返读写。
2. 损坏的配置文件不会阻止应用启动。
3. `WorkbenchLogic` 是纯函数，可以在两个目标上测试。
4. Swift 侧没有硬编码的工作区列表。

## 依赖

`E00-S03` 决定存储位置。

## 风险

模型设计要一次留足扩展位，否则组件布局会带来第二次迁移。
`E05-S01` 的组件模型要能直接嵌进 `PaneInstance`。
