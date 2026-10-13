---
id: E03-S03
title: "WorkbenchStore 持久化"
labels: [enhancement, phase-2-workspace-model, area/pane, area/kmp]
type: Task
parent: E03
milestone: "P2 · 工作区模型"
blocked-by: [E03-S01, E00-S03]
---

> 本文的类型名、文件位置与职责边界以 `docs/design/workbench-architecture.md` 第 6 节为准。
> 本文的接口契约见 `E10-S03`（`ADR-006`）。

## 背景

持久化已有统一做法。`WorkspaceStore` 与 `ClipboardStore` 都用 okio 加 kotlinx JSON。
写入流程是：写 `.tmp`，再原子改名。
Amper 0.12.1 没有 SQLDelight 插件，所以不要引入数据库。

## 目标

实现 `workbench.json` 的读写。

## 实施要点

1. 新增 `class WorkbenchStore(directory, fileSystem, json)`。
2. 提供 `load()`。读取失败时返回默认配置，不抛异常。
3. 提供 `save(config)`。写入用 `.tmp` 加原子改名。
4. 提供 `clear()`。
5. JSON 配置沿用现有约定：`prettyPrint`、`ignoreUnknownKeys`、`encodeDefaults`。
6. 提供 `companion.create(directory)` 与 `companion.defaultDirectory()`。
7. 文件路径由 `E00-S03` 的 ADR 决定。

## 验收标准

1. `load()` 在任何读取失败下都返回默认配置。
2. `save()` 后立刻 `load()` 得到相同内容。
3. 写入中断不会留下半个文件。
4. 目录不存在时自动创建。
5. 测试使用 `withTemporaryDirectory`，不碰用户真实目录。
6. 测试在 jvm 与 macosArm64 两个目标上通过。

## 依赖

`E03-S01`、`E00-S03`。
