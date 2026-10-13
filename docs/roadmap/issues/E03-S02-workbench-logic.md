---
id: E03-S02
title: "WorkbenchLogic 纯逻辑"
labels: [enhancement, phase-2-workspace-model, area/pane, area/kmp]
parent: E03
milestone: "P2 · 工作区模型"
blocked-by: [E03-S01]
---

## 背景

工作区的增删改序、校验和默认布局是纯逻辑。
现有代码里同类逻辑写成纯函数对象，例如 `WorkspaceLogic`（`WorkspaceStore.kt:611`）
和 `ClipboardLogic`（`ClipboardStore.kt:84`）。这些逻辑不做 IO，便于测试。

## 目标

把工作台的全部规则写成纯函数。

## 实施要点

1. 新增 `object WorkbenchLogic`。
2. 实现 `add(config, kind)`，生成新 id 并追加。
3. 实现 `remove(config, id)`。至少保留一个工作区。
4. 实现 `rename(config, id, title)`，标题去空白并限长。
5. 实现 `reorder(config, fromIndex, toIndex)`。
6. 实现 `normalize(config)`：修正越界索引、补齐缺失字段、去重 id。
7. 实现 `defaultLayout()`，返回首次启动的默认工作区列表。
8. id 生成不用 `java.util.UUID`。参考
   `kmpDomain/test/com/wyz/covio/core/TemporaryDirectories.kt` 的做法，
   让同一份代码在两个目标上都能运行。

## 验收标准

1. `WorkbenchLogic` 不做任何文件或网络 IO。
2. 删除最后一个工作区时返回错误，不产生空列表。
3. 排序越界时返回错误或钳制，行为明确且有测试。
4. `normalize` 对损坏输入不抛异常。
5. 测试在 jvm 与 macosArm64 两个目标上通过。
6. 测试用例不少于 20 条。

## 依赖

`E03-S01`。
