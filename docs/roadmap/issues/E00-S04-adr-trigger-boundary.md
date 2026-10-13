---
id: E00-S04
title: "ADR-003：触发层的抽象边界"
labels: [documentation, phase-0-research, area/trigger, area/shell]
type: Design
parent: E00
milestone: "P0 · 调研与决策"
blocked-by: []
---

## 背景

现有触发逻辑散落在三处：热区在 `ScreenGeometry` 与 `PointerTrackingHost`，
快捷键在 `GlobalHotKey`，菜单栏在 `StatusItemController`。
三者都直接调用 `NotchShellController.toggle()`。

改造后要接入四指手势，后续还要接入 Windows 的固定热区。
触发逻辑需要一个统一的边界。

## 待决策

1. `CurtainTrigger` 协议包含哪些成员？候选：`id`、`displayName`、`requiredPermission`、`events`。
2. 触发源向挂帘发送事件还是直接调用方法？
3. 触发源的生命周期由谁管理？
4. 权限被拒时，触发源如何向用户报告？
5. 多个触发源同时触发时的去重规则是什么？
6. 触发源是否参与持久化？用户能否单独关闭某个触发源？

## 约束

- 挂帘外壳只订阅一个注册表。外壳不认识任何具体触发源。
- 新增平台时只增加触发源实现，外壳代码不变。
- 本仓库不使用 `NSEvent.addGlobalMonitorForEvents`，除非 `E00-S01` 给出反证。

## 交付物

`docs/adr/ADR-003-trigger-layer-boundary.md`。

## 验收标准

1. ADR 给出协议的完整成员列表。
2. ADR 给出事件流图，覆盖触发、去重、降级和错误。
3. ADR 明确写出 Windows 与 iOS 如何接入同一协议。
4. 状态为“已接受”。

## 依赖

无。与 `E00-S01` 并行。结论冲突时以 `E00-S01` 为准。
