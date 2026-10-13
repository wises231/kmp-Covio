---
id: E03-S01
title: "WorkbenchConfig 与 PaneInstance 数据模型"
labels: [enhancement, phase-2-workspace-model, area/pane, area/kmp]
parent: E03
milestone: "P2 · 工作区模型"
blocked-by: [E00-S03]
---

## 背景

工作台需要一份可序列化的配置。
现有模型的写法在 `kmpDomain/src/com/wyz/covio/core/Models.kt`。
该文件的既有约定有两条：每个可序列化类型都提供 `companion { fun defaults() }`，
因为 Kotlin 的默认参数不导出到 Swift；枚举在 Swift 侧导出为小写成员名。

## 目标

定义工作台配置的完整数据模型。

## 实施要点

1. 新增 `WorkbenchConfig`。字段至少包含 `schemaVersion`、工作区实例列表和当前选中项。
2. 新增 `PaneInstance`。字段至少包含 `id`、`kind`、`title`、`symbolName`、`enabled`、`settings`。
3. 新增 `PaneKind` 枚举。初始成员为 `widgets`、`clipboard`、`screenshots`、`files`、`devices`、`settings`。
4. 新增 `PaneSettings`。用一个可扩展的键值结构承载每个工作区自己的设置。
5. 为每个类型提供 `defaults()`。
6. 给 `PaneInstance` 预留组件布局字段，或明确该字段由 `E05-S01` 追加。
7. 保持 `Models.kt` 的注释风格：用中文说明字段用途。

## 验收标准

1. 每个类型可序列化，且提供 `defaults()`。
2. 序列化结果稳定：同一输入两次编码字节相同。
3. 未知字段被忽略，不导致读取失败。
4. Swift 侧可以构造 `PaneInstance` 并读回字段。
5. 有往返测试。

## 依赖

`E00-S03`。
