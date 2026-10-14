# 挂帘工作台架构骨架

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 待评审 |
| 日期 | `2026-10-13` |
| 适用范围 | macOS 宿主。Windows 与 iOS 只保留抽象接口。 |
| 当前基线 | `0.5.0`，分支 `feature/swiftui-macos` |
| 上游文档 | [产品设计总稿](../covio-product-master.md)、[设计合同](../covio-design-contract.json)、[ADR-0001](../../docs/adr/adr-0001-macos-ui-swiftui.md) |
| 下游文档 | ADR-002 工作台配置的存储位置与版本策略、ADR-003 触发层的抽象边界、ADR-004 到 ADR-009（分层契约，分工见第 10 节） |

本文描述**目标形态**，不描述现状。现状以代码为准。

## 1. 目标与非目标

目标是给出四层的职责、边界、依赖方向和关键类型名。读完本文能回答：有几层、每层负责什么、不认识什么、依赖谁、关键类型叫什么、现有代码怎么搬过去。

非目标：

1. 不给函数签名。
2. 不给数据字段清单。
3. 不给状态迁移表。
4. 不给错误码表。
5. 不给时序图。

以上五项在 ADR 和实现类 issue 里定。

## 2. 需求映射

| 需求 | 承担层 | 关键类型 |
| --- | --- | --- |
| R1 触控板四指下滑打开 | 触发层 | `TrackpadGestureTrigger` |
| R2 鼠标悬停刘海区域触发 | 触发层 | `NotchHoverTrigger` |
| R3 展开后是层级最高的组合式工作区域 | 挂帘外壳 | `CurtainController`、`ShellPanel` |
| R4 页签显示不同工作区，首页是 Widgets | 工作区层、Widget 层 | `PaneRegistry`、`WorkbenchConfig` |
| R5 每个工作区支持编辑和设置 | 工作区层 | `WorkbenchLogic`、`PaneRegistry` |
| R6 Windows 用固定区域触发 | 触发层 | `CurtainTrigger` 的新实现 |
| R7 iOS 主页上滑带出 bottom sheet | 无 | 无 |

R6 和 R7 只影响触发层的形状，不增加新层。R7 没有承担层：系统不向第三方应用开放主屏手势入口，iOS 侧只能改用交互小组件。结论见 [iOS 免打开入口](../research/mobile-ambient-entry/README.md)。

## 3. 分层与依赖方向

四层。上层依赖下层，下层不认识上层。

```text
触发层        不认识外壳，不认识工作区
   |
挂帘外壳      不认识具体触发源，不认识工作区的内容
   |
工作区层      不认识 Widget 怎么画
   |
Widget 层     不认识任何上层
```

依赖规则三条：

1. 依赖只能向下。
2. 下层不引用上层。
3. 同层之间不互相依赖。四个触发源彼此不认识。

自查用三条。出现任一条，说明分层被破坏：

| 现象 | 说明 |
| --- | --- |
| 触发源里出现 `CurtainController` | 违反规则 1。触发源只发事件。 |
| 外壳里出现 `TrackpadGestureTrigger` | 违反规则 2。外壳只认识 `CurtainTrigger` 协议。 |
| 工作区层里出现 `NSView` 或 SwiftUI 类型 | 层选错了。工作区层是数据与纯逻辑。 |

### 3.1 平台边界

触发层和挂帘外壳在 Swift 侧，放在 `macosApp/src/`。
工作区层的数据模型和纯逻辑在 Kotlin 侧，放在 `kmpDomain/src/com/wyz/covio/core/`。
Widget 层的模型跟随工作区层，渲染在 Swift 侧。

理由：工作区的增删改序、校验和默认布局是纯逻辑。放在 `kmpDomain` 可以在 `jvm` 上跑测试，不需要起窗口。

### 3.2 命名

概念名如下。

| 概念 | 标识符 | 中文 |
| --- | --- | --- |
| 整个产品形态 | `Workbench` | 挂帘工作台 |
| 一个页签 | `Pane` | 工作区 |
| 页签的类型 | `PaneKind` | 工作区类型 |
| 页签的一个实例 | `PaneInstance` | 工作区实例 |
| 网格上的一块 | `Widget` | 组件 |
| 跨设备共享暂存区 | `Workspace` | 共享暂存区，标识符不变 |
| 工作台配置 | `WorkbenchConfig` | 工作台配置 |

**警告：** 现有 `Workspace*` 指跨设备共享暂存区，不指页签。新代码不要复用这个前缀。

## 4. 触发层

**职责**：把多个来源归一成「打开」和「收起」两个事件。

**边界**：不认识外壳，不认识工作区，不知道挂帘长什么样、有多大、画在哪里。

**依赖**：无。本层是最底层。

**关键类型**：

| 类型 | 职责 |
| --- | --- |
| `CurtainTrigger` | 一个触发源。描述名字、权限需求和事件流。 |
| `TriggerRegistry` | 持有全部触发源，向订阅者发出唯一的打开与收起事件。实现去重。 |
| `NotchHoverTrigger` | 指针进入刘海热区。 |
| `TrackpadGestureTrigger` | 触控板四指下滑。 |
| `HotKeyTrigger` | 全局快捷键。 |
| `StatusItemTrigger` | 菜单栏图标。 |

**现有代码的迁移**：

1. `TriggerRegistry` 照 `GlobalHotKeyCenter` 写。见 `macosApp/src/NotchShell/GlobalHotKey.swift:177`。它已经是「编号到回调」的注册表加分派，形状可以直接复用。
2. `NotchHoverTrigger` 复用 `PointerTrackingHost` 与 `ScreenGeometry.hotZoneRect`。
   - `PointerTrackingHost` 在 `macosApp/src/NotchShell/PointerTrackingHost.swift`。
   - `hotZoneRect` 在 `macosApp/src/NotchShell/ScreenGeometry.swift:39`，已区分刘海屏与非刘海屏。
3. `HotKeyTrigger` 包装现有 `GlobalHotKey`。
4. `StatusItemTrigger` 包装现有 `StatusItemController`。
5. 现有 `NotchShellController.toggle()` 改为只由注册表调用。

**一条既有教训**：`PointerTrackingHost.swift:6` 记录了不使用 `NSEvent.addGlobalMonitorForEvents` 的理由。它在未获授权时也返回非空对象。新触发源不要改回这个做法。

**降级**：`TrackpadGestureTrigger` 走私有框架，可能失效。失效时由 `HotKeyTrigger` 和 `NotchHoverTrigger` 承担。降级逻辑属于触发层内部，外壳不知情。

## 5. 挂帘外壳

**职责**：可见性、位置、动效、键盘焦点。

**边界**：不认识任何具体触发源。不认识工作区的内容，只认识当前选中的工作区编号。

**依赖**：触发层。

**关键类型**：

| 类型 | 职责 |
| --- | --- |
| `CurtainController` | 由 `NotchShellController` 改名。每屏一个热区面板，全局一个挂帘面板。 |
| `HubStateMachine` | 保留。状态从 6 个增到 8 个。 |
| `ShellPanel` | 保留。层级与 Space 设置不动。 |

**现有代码的迁移**：

1. `NotchShellController`（`macosApp/src/NotchShell/NotchShellController.swift:14`）改名为 `CurtainController`。职责不变。
2. `HubStateMachine`（`macosApp/src/NotchShell/HubStateMachine.swift:8`）当前六态：`HIDDEN`、`HOVER`、`OPEN`、`ACTIVE`、`EXIT`、`ERROR`。新增 `PREVIEW` 和 `EDITING`，共八态。迁移表在 `:108`。
3. `ShellPanel`（`macosApp/src/NotchShell/ShellPanels.swift:16`）不动。**顺序不能换**：先设 `isFloatingPanel`，再设 `level = .statusBar`。反序会把层级重置为 3。
4. `HubTab` 字段从外壳移出。外壳改为持有当前工作区编号。

## 6. 工作区层

**职责**：保存工作区列表与顺序，实现增删改序与校验，把工作区类型映射到视图。

**边界**：不认识 Widget 怎么画。不认识面板与窗口。

**依赖**：无。本层不依赖触发层与外壳。

**关键类型**：

| 类型 | 职责 | 位置 |
| --- | --- | --- |
| `PaneKind` | 工作区的类型。例如 `widgets`、`clipboard`。 | Kotlin |
| `PaneInstance` | 工作区的一个实例。带自己的编号、标题、图标和设置。 | Kotlin |
| `WorkbenchConfig` | 工作区列表、顺序、每工作区设置和 Widget 布局。 | Kotlin |
| `WorkbenchLogic` | 纯函数。增删改序、校验、默认布局。 | Kotlin |
| `WorkbenchStore` | 持久化。读写 `workbench.json`。 | Kotlin |
| `PaneRegistry` | 把 `PaneKind` 映射到 SwiftUI 视图。 | Swift |

**现有代码的迁移**：

1. `WorkbenchStore` 照 `WorkspaceStore` 写。原子写入的样板在 `kmpDomain/src/com/wyz/covio/core/WorkspaceStore.kt:138`。
2. `WorkbenchLogic` 照 `object WorkspaceLogic`（`WorkspaceStore.kt:611`）写：无 IO 的纯逻辑对象，配独立测试。
3. `PaneRegistry` 照 `SettingsCatalog` 写。见 `macosApp/src/Hub/Settings/SettingsCatalog.swift:68`。它是「声明式条目表」的现成样板。
4. 本层替换三处硬编码：
   - `HubTab` 枚举，`macosApp/src/Hub/HubTab.swift:10`。
   - `HubTabContent` 的分发，`macosApp/src/Hub/HubView.swift:194`。
   - 导航栏的枚举遍历，`macosApp/src/Hub/HubNavRail.swift:65`。
5. 改动态页签前先改写页签顺序断言。断言在 `macosApp/test/DesignContractTests.swift:63`。

**Kotlin 侧的命名习惯**：接口集中在 `kmpDomain/src/com/wyz/covio/core/Ports.kt`。本层若需要新端口，加进这个文件，不要另建文件。

## 7. Widget 层

**职责**：描述组件实例，把组件位置吸附到网格列，声明可添加的组件类型。

**边界**：不认识任何上层。不认识页签。

**依赖**：无。

**关键类型**：

| 类型 | 职责 |
| --- | --- |
| `Widget` | 一个组件实例。描述类型、尺寸档、位置和设置。 |
| 网格引擎 | 把组件位置吸附到列。纯计算，无渲染。 |
| `WidgetCatalog` | 声明可添加的组件类型。 |

**现有代码的迁移**：无。本层是全新代码。`WidgetCatalog` 照 `SettingsCatalog` 的声明式条目表写。

## 8. 数据模型与持久化

**存放位置**：工作台配置放独立文件 `workbench.json`。具体路径、版本字段和损坏恢复行为由 ADR-002 定。

不放进 `config.json` 的理由：`config.json` 已声明与 0.4.2 双向兼容，`schemaVersion` 当前是 `3`（`kmpDomain/src/com/wyz/covio/core/Models.kt:18`）。`macosApp/test/ConfigCompatibilityTests.swift` 有 15 条用例守住这份兼容性。工作台配置放进去会牵动这 15 条。

**写入方式**：okio 加 kotlinx JSON，写入用 `.tmp` 加原子改名。全仓库统一，见 `ShelfStore`、`ClipboardStore`、`WorkspaceStore` 三份样例。

**读失败的行为**：回退默认布局，并保留损坏文件副本。读失败不抛异常。理由：Kotlin 异常跨到 Swift 没有接收方会终止进程。这条在 `WorkspaceStore` 里有多处注释。

**不使用数据库**：Amper 0.12.1 没有 SQLDelight 插件。

**现有路径，供 ADR-002 参照**：

| 数据 | 路径 | 命名依据 |
| --- | --- | --- |
| `config.json` | `~/Library/Application Support/com.wyz.covio/` | `APP_ID` |
| 晾衣线 `shelf.json` | `~/Library/Application Support/Covio/Screenshots/` | `APP_NAME` |
| 共享暂存区 | `~/Library/Application Support/Covio/Workspace/` | `APP_NAME` |

三个路径用了两种命名依据。这是 0.4.2 的既有布局，不能改。

## 9. 扩展点、边界与降级

**新增一个平台**：只增加 `CurtainTrigger` 的实现，再加一个宿主的挂帘外壳。工作区层和 Widget 层不变。

**新增一个工作区类型**：在 `PaneKind` 加一个值，在 `PaneRegistry` 注册一个视图。不改外壳。

**新增一个组件类型**：在 `WidgetCatalog` 加一条。不改网格引擎。

**降级路径三条**，按可用性排序：

1. 触控板手势失效时，快捷键与刘海悬停承担。
2. 输入监控权限被拒时，快捷键与菜单栏图标承担。
3. `workbench.json` 损坏时，回退默认布局。

降级对用户可见。降级发生时，外壳不显示错误面板，只在设置页记录。

**扩展点不做的**：不为扩展点预留抽象接口。加平台时再抽。

## 10. 未决项与 ADR 分工

**交给 ADR-002**：

1. `workbench.json` 的完整路径。
2. 版本字段名与升级策略。
3. 用户降级回旧版时工作台配置的处理。
4. 损坏时的恢复细节。

**交给 ADR-003**：

1. `CurtainTrigger` 协议的边界画在哪里。
2. 触发源与注册表之间的事件形状。
3. 去重在哪一层做。

**交给分层 ADR**（`ADR-004` 到 `ADR-009`）：

| 本文节 | ADR | 要定的事 |
| --- | --- | --- |
| 第 4 节 | `ADR-004` | 四个触发源的接口签名。不重复裁 `ADR-003` 的范围。 |
| 第 5 节 | `ADR-005` | `CurtainController` 的改名范围，`PREVIEW` 与 `EDITING` 的迁移表。 |
| 第 6 节 | `ADR-006` | `PaneRegistry` 的样板，工作区数量上限，内置工作区能否删除。 |
| 第 7 节 | `ADR-007` | 组件尺寸档取几档，网格列数与吸附规则，`WidgetCatalog` 放在哪一侧。 |
| 第 8 节 | `ADR-008` | 这层的字段清单与损坏恢复细节。不重复裁 `ADR-002` 的范围。 |
| 第 9 节 | `ADR-009` | 扩展点的做法，以及本文第 9 节与 `ADR-003` 的冲突。 |

**本文内部待裁决**：`WidgetCatalog` 放在哪一侧。
第 3.1 节说「Widget 层的模型跟随工作区层」，第 7 节又让 `WidgetCatalog` 照 `SettingsCatalog` 写，而 `SettingsCatalog` 在 Swift 侧。两处矛盾。归 `ADR-007`。

**留给实现期**：

1. 编辑模式是就地编辑还是独立页面。

**本文不回答的**：`WorkbenchConfig` 的字段清单。字段在实现时定，定完回填本文第 6 节。
