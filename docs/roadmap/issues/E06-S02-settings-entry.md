---
id: E06-S02
title: "工作区设置入口"
labels: [enhancement, phase-3-widgets, area/pane, area/swift]
type: Task
parent: E06
milestone: "P3 · Widgets 首页"
blocked-by: [E06-S01]
---

> 本文的类型名、文件位置与职责边界以 `docs/design/workbench-architecture.md` 第 6 节为准。
> 本文的接口契约见 `E10-S03`（`ADR-006`）。

## 背景

挂帘顶部有一个胶囊，显示页标题与当前页动作（`HubToolbarCapsule.swift:11`）。
设置页的胶囊当前放六节分段选择器（`HubToolbarCapsule.swift:63`）。
工作区需要自己的设置入口。

## 目标

提供进入当前工作区实例（`PaneInstance`）设置的入口。

## 实施要点

1. 胶囊右侧增加一个齿轮按钮，打开当前工作区的设置面板。
2. 导航栏条目的右键菜单增加“工作区设置”。
3. 设置面板用弹层呈现，不切换页签。用户关掉弹层回到原工作区。
4. 设置面板标题显示工作区标题。
5. 设置面板底部提供“恢复默认”。
6. 用 Escape 关闭弹层，且不收起挂帘。

## 验收标准

1. 两个入口都能打开设置面板。
2. 关闭弹层后回到原工作区，选中项不变。
3. 面板标题正确。
4. Escape 关闭弹层，挂帘保持展开。
5. 没有设置项的工作区显示“此工作区没有设置”说明。
6. 设置项为空时不显示空面板。

## 依赖

`E06-S01`。
