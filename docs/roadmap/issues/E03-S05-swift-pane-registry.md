---
id: E03-S05
title: "Swift 侧 PaneRegistry 与 WorkbenchStoreClient"
labels: [enhancement, phase-2-workspace-model, area/pane, area/swift]
parent: E03
milestone: "P2 · 工作区模型"
blocked-by: [E03-S03]
---

## 背景

Swift 侧访问 Kotlin 存储已有固定做法。
`macosApp/src/Workspace/WorkspaceStoreClient.swift:22` 用 `WorkspaceStore.companion.create(directory:)`
并加一层 `NSLock`。
运行时的写法参考 `macosApp/src/Workspace/WorkspaceRuntime.swift`。

Kotlin 的 `copy` 导出为 `doCopy`，`copyXxx` 导出为 `doCopyXxx`。
命名时要避开这个坑。

## 目标

在 Swift 侧提供工作台配置的读写入口与工作区类型注册表。

## 实施要点

1. 新增 `WorkbenchStoreClient`，封装 `WorkbenchStore` 并加锁。
2. 新增 `PaneRegistry`，把 `PaneKind` 映射到 SwiftUI 视图构造器。
3. `PaneRegistry` 提供 `view(for:instance:)` 与 `icon(for:)`。
4. 注册表对未知 `PaneKind` 返回一个占位视图，不崩溃。
5. 新增 `WorkbenchRuntime`，持有当前配置并对外发布变更。
6. 配置变更后立即持久化。

## 验收标准

1. 未知的 `PaneKind` 渲染为占位视图，不崩溃。
2. 注册表的读写有单元测试，使用临时目录。
3. 配置变更后立刻落盘。
4. 并发读写不产生数据竞争。
5. 现有 `WorkspaceTests.swift` 的 23 条用例继续通过。

## 依赖

`E03-S03`。
