---
id: E10-S03
type: Design
title: "工作区层契约：ADR-006"
labels: [documentation, phase-6-architecture, area/pane, area/architecture]
parent: E10
milestone: "P6 · 架构落地"
blocked-by: []
---

## 背景

骨架第 6 节给出了工作区层的六个类型，并说这一层替换三处硬编码：
`HubTab` 枚举、`HubTabContent` 的分发、导航栏的枚举遍历。
骨架只写到类型名和迁移提示。

三件事没有定。
第一，`PaneRegistry` 的样板。骨架第 6 节说照 `SettingsCatalog` 写。
而 `E05-S03` 把 `SettingsCatalog` 这个样板给了 `WidgetCatalog`。两份 issue 争同一个样板。
第二，工作区数量上限。路线图第 9.3 节把它列为未决项。
第三，用户能否删除内置工作区。路线图第 9.3 节同样列为未决项。

**边界**：`WidgetCatalog` 的层位与样板归 `E10-S04`（`ADR-007`）。
本条只定 `PaneRegistry` 的样板，以及两者是否共用一份样板时的**裁决入口**。

## 待决策

1. `PaneRegistry` 照 `SettingsCatalog` 写，还是另立一份。
2. 现有三个「硬编码」中的 `HubTab` 枚举去留。
   骨架第 6 节说本层替换它。`E04-S01` 说它可以保留。
3. 工作区数量上限是否设限，设限取几。
4. 用户能否删除内置工作区。不能删除时，界面上如何表达。
5. 本层若需要新端口，是否都加进 `Ports.kt`，不另建文件。

## 候选方案

### 方案 A：`PaneRegistry` 照 `SettingsCatalog` 写

沿用「声明式条目表」的形状：一张静态表列出条目，一个枚举或结构描述每条的键。

代价：若 `WidgetCatalog` 也照同一份样板写，两处会各抄一遍。样板是否抽公共层要另定。
适用条件：两张表的形状确实相同。

### 方案 B：`PaneRegistry` 另立形状

因为 `PaneRegistry` 映射的是「类型到视图」，`SettingsCatalog` 映射的是「键到文案与图标」。
两者语义不同，共用样板会把语义不同的东西塞进同一个抽象。

代价：失去现成样板，`E03-S05` 要多写一段。
适用条件：两张表的形状其实不同。

### 方案 C：共用样板，抽到共享层

在 `macosApp/src/` 下抽一份通用的声明式条目表，两处都用。

代价：为一个抽象多建一层。抽象只有两个使用点，收益不确定。
适用条件：第三个使用点已经可以预见。

## 判定依据

1. 骨架第 3 节的依赖规则：工作区层不认识 Widget 怎么画。
2. 骨架第 3.1 节的平台边界：工作区层的数据与纯逻辑在 Kotlin 侧，`PaneRegistry` 在 Swift 侧。
3. 改动态页签前先改写页签顺序断言。断言在 `macosApp/test/DesignContractTests.swift:63`。
4. 上限与删除规则要能在 `WorkbenchLogic` 里用纯函数表达，见骨架第 6 节的迁移第 2 条。

## 决策

待定。

## 证据

1. `macosApp/src/Hub/Settings/SettingsCatalog.swift:68`，现成的声明式条目表样板。
2. `macosApp/src/Hub/HubTab.swift:10`，六值枚举。
3. `macosApp/src/Hub/HubView.swift:194`，`HubTabContent` 的 `switch` 分发。
4. `macosApp/src/Hub/HubNavRail.swift:65`，`ForEach(HubTab.allCases)` 的枚举遍历。
5. `kmpDomain/src/com/wyz/covio/core/Ports.kt` 是 Kotlin 侧接口的集中位置。
6. 骨架第 10 节把「工作区数量上限」与「内置工作区能否删除」指派给 `ADR-006`。

以上均为事实，来自文件内容核对。

## 影响

1. 约束 `E03-S01` 到 `E03-S05`。
2. `E03-S05` 当前的正文把 `SettingsCatalog` 给了 `WidgetCatalog`，按结论改写。
3. `E04-S01` 关于 `HubTab` 去留的说法按结论改写。
4. `E05-S03` 与 `E10-S04` 的边界在结论里写清。
5. 骨架第 6 节与第 10 节按结论回填。

## 依赖

无。骨架第 6 节说本层不依赖触发层与外壳。
