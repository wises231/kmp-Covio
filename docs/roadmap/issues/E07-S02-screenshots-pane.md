---
id: E07-S02
title: "截图工作区"
labels: [enhancement, phase-4-module-panes, area/pane, area/swift]
type: Task
parent: E07
milestone: "P4 · 模块工作区化"
blocked-by: [E06-S01]
---

## 背景

截图页面已存在：`macosApp/src/Hub/ScreenshotsTabView.swift`。
顶栏工具条与卡片交互在 `macosApp/src/Shelf/` 下。
运行时在 `ShelfRuntime.swift`（695 行），卡片交互在 `ScreenshotCardView.swift`。
截图接管写入系统设置，相关策略在 `kmpDomain` 的 `ScreenshotTakeover` 与
`ScreenshotPreferencePolicy`。

## 目标

把截图页面接入工作区体系，并补上设置项与组件联动。

## 实施要点

1. 页面改为由 `PaneRegistry` 提供。
2. 保留现有全部交互：复制、预览、标记、右键菜单、拖放四种去向。
3. 新增设置项：接管开关、工具条高度、卡片数量上下限、显示时长。
4. 设置项写进工作区设置。
5. 首页的截图组件点击后切换到本工作区。
6. 截图接管关闭时，设置项显示为不可用并说明原因。

**警告：** 截图接管会改写系统的三个 `com.apple.screencapture` 键。
改动这一段的代码前先确认回滚路径仍然可用。

## 验收标准

1. 现有 `ScreenshotsTabTests.swift` 与 `ShelfRuntimeTests.swift` 继续通过。
2. 拖放到应用、文件夹、桌面与废纸篓四种行为不变。
3. 四项设置可改且立即生效。
4. 关闭接管后系统键恢复原值。
5. 首页组件能切换到本工作区。

## 依赖

`E06-S01`。
