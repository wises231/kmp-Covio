---
id: E00-S02
title: "调研：移动端免打开入口"
labels: [research, phase-0-research, area/trigger, documentation]
type: Task
parent: E00
milestone: "P0 · 调研与决策"
blocked-by: []
---

## 背景

需求要求在 iOS 主页用上滑手势带出 bottom sheet。
系统不向第三方应用提供主屏手势入口。这条需求不能按原样实现。
本 issue 负责给出替代入口的完整结论。

本仓库的平台范围是 macOS。本 issue 不排任何 iOS 实现 issue。
结论用于后续单独评审。

## 目标

列出 iOS 上所有可行的免打开入口，并按可用性与成本排序。

## 必须回答的问题

1. 主屏手势、锁屏手势和边缘手势对第三方应用是否开放？
2. 控制中心控件（iOS 18 及以上 `ControlWidget`）能否一键打开应用并进入指定工作区？
3. 主屏与锁屏小组件（WidgetKit）的交互能力边界是什么？
4. “轻点背面”快捷指令能否触发应用内的动作？延迟是多少？
5. Action Button 能否触发应用意图？
6. App Intent 与 Shortcuts 的接入成本是多少？
7. 应用内的 `presentationDetents` bottom sheet 能否满足“上滑带出”的手感？
8. 每个入口在应用未启动时能否工作？

## 交付物

按 `docs/research/AUTHORING.md` 建立主题目录 `docs/research/mobile-ambient-entry/`。
章节与 `E00-S01` 相同。

## 验收标准

1. 每个入口标注：可用性、所需系统版本、是否需要用户手动配置、能否冷启动。
2. 结论给出推荐入口的优先级顺序。
3. 明确写出“主屏上滑手势不可实现”及其证据。
4. 结论不预设实现。实现留给后续单独评审。

## 依赖

无。
