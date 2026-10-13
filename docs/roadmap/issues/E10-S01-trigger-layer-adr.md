---
id: E10-S01
type: Design
title: "触发层契约：ADR-004"
labels: [documentation, phase-6-architecture, area/trigger, area/architecture]
parent: E10
milestone: "P6 · 架构落地"
blocked-by: []
---

## 背景

骨架第 4 节给出了触发层的类型表：一个协议 `CurtainTrigger`，一个注册表 `TriggerRegistry`，
以及四个 macOS 实现 `NotchHoverTrigger`、`TrackpadGestureTrigger`、`HotKeyTrigger`、`StatusItemTrigger`。
骨架只写到类型名和一句话职责。

四个实现需要的输入彼此不同。刘海悬停要屏幕几何，手势要私有框架的句柄，
快捷键要键码，菜单栏图标要一个状态栏项。
这些输入的传递方式没有定。定不下来，`E01-S01` 到 `E01-S06` 就无法开工。

**边界**：骨架第 10 节把「`CurtainTrigger` 协议的边界画在哪里」「触发源与注册表之间的事件形状」
「去重在哪一层做」三项指派给了 `ADR-003`（`E00-S04`）。
本 issue 不重复裁这三项。本条只定四个实现各自的签名。

## 待决策

1. 四个实现各自需要哪些构造参数，以及参数从哪里来。
2. 协议是否要求 `start` 与 `stop` 生命周期。四个实现的生命周期差异怎么归一。
3. 权限需求如何声明：静态属性，还是运行时可查的方法。
4. 注册表在测试中如何替换实现。是否需要为测试留一个空的实现。

## 候选方案

### 方案 A：统一基类加协议

抽一个 `CurtainTriggerBase` 放共享的生命周期与权限样板，四个实现继承它。

代价：协议之外多一层继承。Swift 里协议扩展与基类是两套扩展机制，同时用会让替换点变模糊。
适用条件：四个实现的生命周期高度一致。

### 方案 B：纯协议，各实现自带生命周期

`CurtainTrigger` 只声明行为。四个实现各自写 `start` 与 `stop`。

代价：四处重复样板。新增平台时样板要再抄一遍。
适用条件：四个实现的生命周期差异大到无法归一。

### 方案 C：协议加默认实现

用 protocol extension 提供默认的 `start` 与 `stop`。需要时由实现覆盖。

代价：默认实现难以在需要时完全覆盖，测试时也不易替换成假实现。
适用条件：默认行为对四个实现都成立。

## 判定依据

1. 新增一个触发源的成本。骨架第 9 节要求「新增一个平台时只增加触发源实现」。
2. 外壳不感知具体触发源。这是骨架第 3 节的依赖规则 2。
3. 可测试性：能否在不起窗口的前提下测注册表的分派与去重。
4. 不重复 `ADR-003` 的范围。

## 决策

待定。

## 证据

1. 骨架第 4 节的类型表与五条迁移说明。
2. `macosApp/src/NotchShell/GlobalHotKey.swift:177` 的 `GlobalHotKeyCenter`，现成的「编号到回调」注册表加分派。
3. `macosApp/src/NotchShell/PointerTrackingHost.swift:6` 的授权教训：不使用 `NSEvent.addGlobalMonitorForEvents`。
4. `macosApp/src/NotchShell/ScreenGeometry.swift:39` 的 `hotZoneRect`，已区分刘海屏与非刘海屏。
5. `E01-S02` 的降级结论：私有路径限定在四个核心函数，需要一个句柄的传递方式。

以上均为事实，来自文件内容核对。

## 影响

1. 约束 `E01-S01` 到 `E01-S06` 的接口写法。
2. `E01-S02` 与 `E01-S03` 按结论改写：现在只有中文描述，没有标识符。
3. `E01`、`E01-S01`、`E01-S06` 正文里的 `NotchShellController` 按 `E10-S02` 的结论改写。
4. 骨架第 4 节按结论回填签名小节。

## 依赖

`E00-S04`（`ADR-003`）。协议边界未定之前，本条只登记候选，不定稿。
