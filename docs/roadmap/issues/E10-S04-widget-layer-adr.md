---
id: E10-S04
type: Design
title: "Widget 层契约：ADR-007"
labels: [documentation, phase-6-architecture, area/widget, area/architecture]
parent: E10
milestone: "P6 · 架构落地"
blocked-by: [E10-S03]
---

## 背景

骨架第 7 节给出了 Widget 层的三个条目：`Widget`、网格引擎、`WidgetCatalog`。
骨架第 10 节把三件事指派给 `ADR-007`：组件尺寸档取几档、网格列数与吸附规则、
`WidgetCatalog` 放在哪一侧。

骨架自己还有一处内部矛盾，归本条裁决。
第 3.1 节说「Widget 层的模型跟随工作区层」，即模型在 Kotlin 侧。
第 7 节又让 `WidgetCatalog` 照 `SettingsCatalog` 写，而 `SettingsCatalog` 在 Swift 侧。
两处对 `WidgetCatalog` 的层位结论相反。

issue 侧还有两处不一致。
`E05-S01` 到 `E05-S04` 把组件实例写成 `WidgetInstance`，骨架里叫 `Widget`。
`E05-S05` 出现 `WidgetRegistry`，骨架里没有这个名字，只有 `WidgetCatalog`。

## 待决策

1. `Widget` 与 `WidgetInstance` 二选一。另一个不进代码。
2. `WidgetCatalog` 放在 Kotlin 侧还是 Swift 侧。这直接裁决骨架第 3.1 节与第 7 节的矛盾。
3. `WidgetRegistry` 是否保留。保留时它与 `WidgetCatalog` 的分工。
4. 组件尺寸档取几档。路线图第 9.3 节列为未决项。
5. 网格列数与吸附规则。列数是固定值还是随窗口宽度变。
6. 本条与 `E10-S03` 对 `SettingsCatalog` 样板的边界。

## 候选方案

### 方案 A：模型与目录都放 Kotlin 侧

`Widget` 与 `WidgetCatalog` 都在 `kmpDomain`。Swift 只负责渲染。

代价：`WidgetCatalog` 要声明「渲染哪个视图」，视图名是 Swift 侧的概念，跨语言传递要靠字符串键或枚举。
适用条件：组件目录的增减不需要动 Swift 代码。

### 方案 B：模型在 Kotlin 侧，目录在 Swift 侧

`Widget` 在 `kmpDomain`，`WidgetCatalog` 照 `SettingsCatalog` 写在 `macosApp/src/`。

代价：与骨架第 3.1 节「Widget 层的模型跟随工作区层」的字面表述冲突。
适用条件：目录本质是「声明式条目表」，与 `SettingsCatalog` 同类。

### 方案 C：整层都放 Kotlin 侧

代价：渲染映射必须跨语言，且与骨架第 3.1 节「渲染在 Swift 侧」冲突。
适用条件：不成立。列出以便排除。

## 判定依据

1. 骨架第 3 节的依赖规则 1 与 2：依赖只能向下，下层不引用上层。
2. 设计合同能否表达尺寸档。`docs/covio-design-contract.json` 的组件同时带 `composeMapping` 与 `swiftMapping`。
3. `E05` 的六个 sub-issue 能否各自独立开工。
4. 纯逻辑可在 `jvm` 上跑测试，不需要起窗口。这是骨架第 3.1 节的理由。

## 决策

待定。

## 证据

1. 骨架第 3.1 节与第 7 节对 `WidgetCatalog` 层位的两处相反表述。
2. 骨架第 10 节的「本文内部待裁决」段，已把该矛盾归 `ADR-007`。
3. `macosApp/src/Hub/Settings/SettingsCatalog.swift:68`。
4. `E05-S01` 到 `E05-S04` 的正文使用 `WidgetInstance`。
5. `E05-S05` 的正文出现 `WidgetRegistry`。
6. 路线图第 9.3 节把「组件尺寸档取几档」列为未决项。

以上 3 到 6 为事实，来自文件内容核对。1 与 2 为骨架文档自身的矛盾陈述。

## 影响

1. 约束 `E05-S01` 到 `E05-S05`。
2. `E05-S01` 到 `E05-S04` 正文里的 `WidgetInstance` 按结论改写。
3. `E05-S05` 正文里的 `WidgetRegistry` 按结论改写。
4. 骨架第 3.1 节与第 7 节按结论回填，矛盾消除。
5. 路线图第 9.3 节的未决项 4 与 5 按结论移除。

## 依赖

`E10-S03`。两条都涉及 `SettingsCatalog` 样板的归属，先定工作区层再定本条。
