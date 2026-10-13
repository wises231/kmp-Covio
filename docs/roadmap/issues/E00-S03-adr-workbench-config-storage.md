---
id: E00-S03
title: "ADR-002：工作台配置的存储位置与版本策略"
labels: [documentation, phase-0-research, area/pane, area/kmp]
parent: E00
milestone: "P0 · 调研与决策"
blocked-by: []
---

## 背景

工作台配置包含工作区列表、顺序、每个工作区的设置和组件布局。
这份数据需要一个存放位置和一套版本策略。

`kmpDomain/src/com/wyz/covio/core/Models.kt` 的 `AppConfig.schemaVersion` 当前是 `3`。
`macosApp/test/ConfigCompatibilityTests.swift` 有 15 条用例守住 `config.json` 的兼容性。
`README.md` 声明 `config.json` 与 0.4.2 双向兼容。

## 待决策

1. 工作台配置放进 `config.json` 并把 `schemaVersion` 升到 `4`，还是放进独立文件 `workbench.json`？
2. 独立文件放在哪个目录？
3. 读取失败时回退到什么状态？
4. 版本升级与回滚的处理方式是什么？
5. 用户降级回 0.5.0 时，工作台配置如何处理？

## 倾向方案

新建 `workbench.json`，放在 `~/Library/Application Support/com.wyz.covio/`。
理由：`config.json` 的兼容性承诺不动，工作台配置可以独立演进。
本 ADR 必须记录该倾向的取舍，或给出更好的方案。

## 交付物

`docs/adr/ADR-002-workbench-config-storage.md`。
格式对齐现有 `docs/adr/ADR-001-macos-ui-swiftui.md`。

## 验收标准

1. ADR 包含背景、决策、理由、备选方案和后果。
2. 决策明确写出文件路径、版本字段名和损坏恢复行为。
3. 明确写出对 `ConfigCompatibilityTests.swift` 的影响。
4. 状态为“已接受”或“已否决并给出新方案”。

## 依赖

无。
