---
id: E07-S03
title: "文件与暂存工作区"
labels: [enhancement, phase-4-module-panes, area/pane, area/swift]
type: Task
parent: E07
milestone: "P4 · 模块工作区化"
blocked-by: [E06-S01]
---

## 背景

文件页面已存在：`macosApp/src/Hub/FilesTabView.swift`。
共享暂存区的存储与传输在 `kmpDomain` 的 `WorkspaceStore` 与 `WorkspaceTransfer`。
Swift 侧的运行时在 `macosApp/src/Workspace/`。

本工作区展示共享暂存区的内容。
暂存区的协议与生命周期见 `docs/research/shared-transfer-workspace/`。

## 目标

把文件页面接入工作区体系，并补上设置项与组件联动。

## 实施要点

1. 页面改为由 `PaneRegistry` 提供。
2. 保留现有交互：拖入、打开、置顶、删除、过期提示。
3. 新增设置项：保留天数、容量上限、按需取回阈值、单文件上限。
4. 设置项写进工作区设置，读取时覆盖 `WorkspacePolicy` 的默认值。
5. 配额与过期策略的纯逻辑在 `kmpDomain`，不在 Swift 里重写。
6. 首页的文件组件点击后切换到本工作区。
7. 界面不显示文件的完整路径。产品总稿 6.5 节约束保持。

## 验收标准

1. 现有 `WorkspaceTests.swift` 的 23 条用例继续通过。
2. 拖入、打开、置顶、删除行为不变。
3. 四项设置可改且立即生效。
4. 界面不显示完整路径。
5. 剩余空间不足时给出原因与下一步。
6. 首页组件能切换到本工作区。

## 依赖

`E06-S01`。
