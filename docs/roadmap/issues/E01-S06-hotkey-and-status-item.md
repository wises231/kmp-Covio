---
id: E01-S06
title: "快捷键与菜单栏入口收口"
labels: [enhancement, phase-1-curtain-core, area/trigger, area/swift]
type: Task
parent: E01
milestone: "P1 · 挂帘内核"
blocked-by: [E01-S01]
---

## 背景

现有入口有三处：`GlobalHotKey` 的 `Control+Option+T`、
`StatusItemController` 的菜单栏图标，以及菜单里的项。
这些入口在 `AppDelegate.swift:51` 直接绑定到 `shell.toggle()`。

## 目标

把三处入口改为注册表上的触发源，并允许用户配置快捷键。

## 实施要点

1. 快捷键触发源复用现有 `GlobalHotKey` 的 Carbon 实现。
2. 快捷键字符串沿用现有格式，例如 `shift+cmd+V`。解析逻辑已在 `GlobalHotKey.Spec`。
3. 默认值保持 `Control+Option+T`，不改变现有用户习惯。
4. 菜单栏图标触发源调用同一注册表。
5. 菜单栏菜单增加“打开工作台”项。
6. 快捷键配置写进工作台配置，不写进 `config.json`。

## 验收标准

1. `Control+Option+T` 行为与 0.5.0 一致。
2. 用户可以在设置里改快捷键。
3. 改完立即生效，无需重启。
4. 快捷键被占用时显示注册失败。
5. 菜单栏图标的“打开工作台”项可用。
6. `AppDelegate` 不再直接持有 `toggle()` 调用。

## 依赖

`E01-S01`。
