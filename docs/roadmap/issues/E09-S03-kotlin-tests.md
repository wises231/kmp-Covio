---
id: E09-S03
title: "Kotlin 测试补齐"
labels: [enhancement, phase-5-quality, area/test, area/kmp]
type: Task
parent: E09
milestone: "P5 · 质量与交付"
blocked-by: [E03-S03, E05-S02]
---

## 背景

`kmpDomain/test/` 有 24 个测试文件，在 jvm 与 macosArm64 两个目标上运行。
`kmpDomain/test@macosArm64/` 目前为空。
测试用 `withTemporaryDirectory` 建临时目录，不碰用户真实目录。

工作台新增了 `WorkbenchLogic`、`WorkbenchStore` 与 `WidgetGridLogic`。
这些是纯逻辑与持久化，必须在 `kmpDomain` 侧测透。

## 目标

补齐工作台相关的 Kotlin 测试。

## 待补的测试

| 测试文件 | 覆盖对象 | 最少用例数 |
| --- | --- | --- |
| `WorkbenchLogicTest.kt` | 增删改序、校验、默认布局 | 20 |
| `WorkbenchStoreTest.kt` | 读写、原子写、损坏恢复、迁移 | 15 |
| `WidgetGridLogicTest.kt` | 吸附、冲突、补位、压缩 | 25 |
| `WorkbenchModelTest.kt` | 序列化往返、未知字段、未知类型降级 | 10 |

## 实施要点

1. 测试在 jvm 与 macosArm64 两个目标上都能运行。
2. 不使用 `java.util.UUID` 或 `java.nio.file`。
3. 每个测试用独立的临时目录。
4. 损坏恢复的测试要断言 `.corrupt-` 副本已生成。
5. 边界用例齐全：空列表、单项列表、越界索引、超长标题。

## 验收标准

1. 四个测试文件齐全，用例数达到上表要求。
2. `./kotlin test` 在两个目标上通过。
3. 测试之间不共享状态。
4. 不写入用户真实目录。
5. 现有 24 个测试文件继续通过。

## 依赖

`E03-S03`、`E05-S02`。
