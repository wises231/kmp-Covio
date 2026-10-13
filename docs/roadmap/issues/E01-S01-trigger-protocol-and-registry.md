---
id: E01-S01
title: "定义 CurtainTrigger 协议与 TriggerRegistry"
labels: [enhancement, phase-1-curtain-core, area/trigger, area/swift]
type: Task
parent: E01
milestone: "P1 · 挂帘内核"
blocked-by: [E00-S04]
---

> 本文的类型名、文件位置与职责边界以 `docs/design/workbench-architecture.md` 第 4 节为准。
> 本文的接口契约见 `E10-S01`（`ADR-004`）。

## 背景

触发源现在各自调用 `CurtainController.toggle()`。
新增触发源前需要一个统一边界。协议形状由 `E00-S04` 的 ADR 决定。

## 目标

建立协议与注册表。挂帘外壳只与注册表交互。

## 实施要点

1. 在 `macosApp/src/NotchShell/` 下新增 `CurtainTrigger` 协议文件。
2. 协议按 `ADR-003` 定义。至少包含标识、显示名、权限需求和事件流。
3. `TriggerRegistry` 持有触发源列表，并向订阅者发出“打开”与“收起”两种事件。
4. 注册表实现去重。同一帧内的多次触发只发一个事件。
5. 把现有 `GlobalHotKey` 与 `StatusItemController` 的调用改为通过注册表。
6. `CurtainController` 的 `toggle()`、`show()`、`requestCollapse()` 保持公开，
   但只由注册表调用。

## 验收标准

1. 协议与注册表各有独立的单元测试。
2. 注册表的去重行为有测试覆盖。
3. 注册表可以注入假触发源，测试不依赖真实鼠标或键盘。
4. 现有 `NotchShellControllerTests` 的 11 条用例继续通过。
5. 触发源不直接引用 `CurtainController`。

## 依赖

`E00-S04`。

**待裁决**：`NotchShellControllerTests` 测试文件是否随类型改名。 归 `E10-S02`（`ADR-005`）。
**待裁决**：四个触发源的确切接口签名。 归 `E10-S01`（`ADR-004`）。
