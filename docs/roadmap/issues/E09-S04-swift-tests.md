---
id: E09-S04
title: "Swift 测试补齐"
labels: [enhancement, phase-5-quality, area/test, area/swift]
parent: E09
milestone: "P5 · 质量与交付"
blocked-by: [E01-S01, E04-S02, E05-S04]
---

## 背景

`macosApp/test/` 有 30 个测试文件，目标 `CovioTests` 以真实宿主应用为测试宿主。
测试通过注入假对象来避免移动真实鼠标或写真实配置。
现有假对象样例：`FakeShelfPanel`、`FakeHotKeyRegistrar`、`FakeLoginItem`。
`NotchShellControllerTests` 通过注入固定的 `pointerLocation` 来测试。

工作台新增了触发注册表、动态导航栏与网格编辑。
这些需要在 Swift 侧测试。

## 目标

补齐工作台相关的 Swift 测试。

## 待补的测试

| 测试文件 | 覆盖对象 |
| --- | --- |
| `TriggerRegistryTests.swift` | 注册、注销、去重、降级、权限缺失 |
| `PaneRegistryTests.swift` | 视图解析、未知类型占位、覆盖完整性 |
| `WorkbenchStoreClientTests.swift` | 并发读写、临时目录、落盘 |
| `NavRailTests.swift` | 页签数量与顺序、截断、滚动、拖动开关 |
| `WidgetEditModeTests.swift` | 拖动结果、缩放回退、撤销 |
| `PaneSettingsRenderTests.swift` | 四种控件渲染、未知控件占位 |

## 实施要点

1. 沿用现有假对象注入方式。测试不移动真实鼠标，不写真实配置。
2. 宿主应用是测试宿主。注意不要走阻塞的启动路径，否则整个套件会失败。
3. 需要时给运行时增加注入缝，与现有 `ShelfEnvironment` 的风格一致。
4. 每个测试用独立的临时目录。

## 验收标准

1. 六个测试文件齐全。
2. `bash scripts/test-macos-swift.sh` 通过。
3. 测试不移动真实鼠标，不读写真实配置。
4. 测试不阻塞宿主启动路径。
5. 现有 30 个测试文件继续通过。
6. 新增测试有覆盖权限缺失与未知类型的失败路径。

## 依赖

`E01-S01`、`E04-S02`、`E05-S04`。

## 注意

两个会话同时运行 Swift 套件时会在 `build/xcode-dd` 上冲突，
出现假的 `TEST FAILED`。并行开发时错开运行。
