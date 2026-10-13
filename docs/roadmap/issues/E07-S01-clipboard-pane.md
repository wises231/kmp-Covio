---
id: E07-S01
title: "剪切板工作区"
labels: [enhancement, phase-4-module-panes, area/pane, area/swift]
parent: E07
milestone: "P4 · 模块工作区化"
blocked-by: [E06-S01]
---

## 背景

剪切板页面已存在：`macosApp/src/Hub/ClipboardTabView.swift`。
运行时的逻辑在 `macosApp/src/Clipboard/ClipboardRuntime.swift`。
存储与策略在 `kmpDomain` 的 `ClipboardStore` 与 `ClipboardLogic`。
胶囊动作在 `ClipboardCapsuleActions`（`ClipboardTabView.swift:118`）。

## 目标

把剪切板页面接入工作区体系，并补上设置项与组件联动。

## 实施要点

1. 页面改为由 `PaneRegistry` 提供。
2. 保留现有全部交互：单选复制、双击粘贴、置顶、删除、清空、暂停。
3. 胶囊动作保持不变。
4. 新增设置项：保留条数、保留天数、容量上限、暂停状态、两个快捷键。
5. 设置项写进工作区设置，读取时覆盖 `ClipPolicy` 的默认值。
6. 首页的剪切板组件点击后切换到本工作区。

## 验收标准

1. 现有 `ClipboardTests.swift` 的 42 条用例继续通过。
2. 全部现有交互行为不变。
3. 五项设置可改且立即生效。
4. 界面不显示剪切板正文以外的内容。产品总稿 6.5 节约束保持。
5. 首页组件能切换到本工作区。
6. 快捷键冲突时显示注册失败。

## 依赖

`E06-S01`。
