---
id: E09
title: "质量、测试与交付"
labels: [epic, phase-5-quality, area/test, area/a11y, area/perf]
type: Goal
parent: null
milestone: "P5 · 质量与交付"
blocked-by: [E05]
---

## 背景

工作台引入了新的界面结构、新的持久化文件与新的输入通道。
现有测试套件覆盖的是 0.5.0 的行为。
交付前需要补齐测试、无障碍、性能与文档。

## 目标

让工作台达到与 0.5.0 相同的质量门槛。

## 范围

范围内：

- 无障碍与键盘操作。
- 性能与资源预算。
- Kotlin 与 Swift 两侧的测试补齐。
- 打包、CI 与文档。

范围外：

- 功能实现。见前面各 epic。

## 子项

- [ ] `E09-S01` 无障碍与键盘操作
- [ ] `E09-S02` 性能与资源预算
- [ ] `E09-S03` Kotlin 测试补齐
- [ ] `E09-S04` Swift 测试补齐
- [ ] `E09-S05` 文档、发布说明与验收清单

## 退出条件

1. `bash scripts/test-all.sh` 通过。
2. 产品总稿 6.8 节的无障碍条目逐条通过。
3. 性能预算写入文档并有实测数据。
4. `README.md`、`RELEASE_NOTES.md` 与真机验收清单同步。

## 依赖

`E05`。本 epic 的子项可以随开发进度提前开始。

## 风险

Swift 测试套件在多个会话同时运行时会在 `build/xcode-dd` 上冲突。
并行开发时注意这一条。
