---
id: E00-S01
title: "调研：macOS 触控板多指手势入口"
labels: [research, phase-0-research, area/trigger, documentation]
type: Task
parent: E00
milestone: "P0 · 调研与决策"
blocked-by: []
---

## 背景

需求要求用户在触控板上四指下滑打开挂帘。
macOS 把“四指下滑”默认映射给调度中心。前台应用和后台应用都收不到这个手势。
本仓库已经在 `macosApp/src/NotchShell/PointerTrackingHost.swift:6` 记录了相关教训：
`NSEvent.addGlobalMonitorForEvents` 在未获授权时也返回非空对象，所以本仓库不使用它。

## 目标

判定四指下滑能否交付。给出可行路径、权限要求、失效条件和降级方案。

## 必须回答的问题

1. `NSEvent.addGlobalMonitorForEvents(matching: .swipe)` 在什么条件下能收到事件？
2. 用户把系统手势改成“关闭”后，应用能否收到四指手势？
3. `CGEventTap` 监听 `.scrollWheel` 能否区分两指滚动与四指滑动？
4. 私有 `MultitouchSupport.framework`（`MTDeviceCreateList`、`MTRegisterContactFrameCallback`）
   在本机 macOS 版本上是否可用？需要哪个权限？
5. 每条路径在 App Sandbox 关闭、ad-hoc 签名、DMG 分发的条件下是否可用？
6. 输入监控权限被拒时的行为是什么？
7. 是否存在公开的替代方案，例如 `NSEvent` 的 `.gesture` 类型或 macOS 26 新增接口？

## 交付物

按 `docs/research/AUTHORING.md` 建立主题目录 `docs/research/trackpad-gesture-entry/`。
必须包含 `README.md`、`context.md`、`investigation.md`、`conclusion.md`、
`solution.md`、`evidence.md` 和 `validation/README.md`。

## 验收标准

1. 每条候选路径都有证据编号，来源标注等级。
2. 结论明确写出“可交付”或“不可交付”。
3. 结论为“可交付”时，`solution.md` 给出接口形状与权限申请时机。
4. 结论为“不可交付”时，`conclusion.md` 写出降级方案。
5. 未验证的推断标记为假设，不写成结论。

## 影响

结论为“不可交付”时关闭 `E01-S02`。
本路线图第 11 节验收标准第 1 条同时改写。

## 依赖

无。
