# 挂帘式工作台路线图

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.1` |
| 状态 | 待评审 |
| 日期 | `2026-10-13` |
| 适用对象 | 产品、研发、测试和无障碍评审人员 |
| 适用范围 | macOS 宿主。Windows 与 iOS 只保留抽象接口和一份调研结论。 |
| 当前基线 | `0.5.0`，分支 `feature/swiftui-macos` |
| 交付物 | 本文档、`issues/` 下的 issue 定义、`scripts/create-roadmap-issues.sh` |
| 上游文档 | [产品设计总稿](../covio-product-master.md)、[设计合同](../covio-design-contract.json)、[SwiftUI 迁移计划](../covio-macos-swiftui-migration-plan.md) |

## 1. 结论摘要

目标是把 Hub 从固定六页签改造成可编辑的挂帘工作台。
改造按第 6 节的六个阶段推进。
阶段零是调研。触控板四指手势的可行入口没有确定答案。
调研结论决定触发层能否满足需求。调研结论不成立时，阶段一缩小范围。
代码标识符必须换名。现有 `Workspace*` 指跨设备共享暂存区。
新概念在代码里叫 `Pane`，在中文里叫“工作区”。第 4 节给出完整对照。
工作台配置放进新文件 `workbench.json`。`config.json` 保持 0.4.2 双向兼容。
iOS 的主页上滑手势不可实现。系统不向第三方应用提供该入口。
本路线图覆盖 macOS。Windows 与 iOS 各留一份调研结论和一个抽象接口。
本路线图共 10 个 epic 和 49 个 sub-issue。

## 2. 需求拆解

用户提出的四项目标与对应能力。

| 序号 | 需求 | 能力 | 现状 |
| --- | --- | --- | --- |
| R1 | 触控板四指下滑打开 | 全局多指手势触发 | 无。现有触发只有热区、快捷键和菜单栏图标。 |
| R2 | 鼠标悬停刘海区域触发 | 刘海几何识别与悬停触发 | 部分。`ScreenGeometry.hotZoneRect` 已返回刘海矩形。缺少预览态和权限处理。 |
| R3 | 展开后是层级最高的组合式工作区域 | 顶层非激活面板与多工作区容器 | 部分。`ShellPanel` 已在 `.statusBar` 层级。容器只有固定页签。 |
| R4 | 页签显示不同工作区，首页是 Widgets | 数据驱动的页签与 Widget 网格 | 无。`HubTab` 是六值枚举。 |
| R5 | 每个工作区支持编辑和设置 | 工作区编辑器与每工作区设置面 | 无。设置只有固定的六节目录。 |
| R6 | Windows 用固定区域触发 | 触发层抽象 | 无。Windows 宿主尚未存在。 |
| R7 | iOS 主页上滑带出 bottom sheet | 系统级免打开入口 | 不可行。见第 9 节 `U-01`。 |

## 3. 现状基线

以下是本次改造要动到的现有代码。路径相对仓库根目录。

### 3.1 触发与外壳

- `macosApp/src/NotchShell/ScreenGeometry.swift:39` 的 `hotZoneRect` 已区分刘海屏与非刘海屏。
  刘海屏返回刘海矩形。非刘海屏返回菜单栏下方 200×6 点的透明带。
- `macosApp/src/NotchShell/PointerTrackingHost.swift:6` 记录了既有教训：
  `NSEvent.addGlobalMonitorForEvents` 在未获授权时也返回非空对象，所以本仓库不使用它。
- `macosApp/src/NotchShell/ShellPanels.swift:16` 的 `ShellPanel` 是全部面板的基类。
  第 26 行先设 `isFloatingPanel`，再设 `level = .statusBar`。顺序颠倒会把层级重置为 3。
- `macosApp/src/NotchShell/HubStateMachine.swift:101` 的迁移表是
  `HIDDEN → HOVER → OPEN → ACTIVE → EXIT → HIDDEN`，另有 `ERROR → OPEN`。
- `macosApp/src/NotchShell/GlobalHotKey.swift:29` 用 Carbon `RegisterEventHotKey` 注册
  `Control+Option+T`。签名是 `'COVI'`。
- 全屏 Space 的抑制由 `ScreenGeometry.isMenuBarVisible` 判断。

### 3.2 页签与导航

- `macosApp/src/Hub/HubTab.swift:10` 的 `HubTab` 是六值枚举：
  `Now`、`Clipboard`、`Files`、`Screenshots`、`Devices`、`Settings`。
- 页签顺序由 `macosApp/test/DesignContractTests.swift` 断言。改成动态页签必须同时改写这条断言。
- `macosApp/src/Hub/HubView.swift:186` 的 `HubTabContent` 用 `switch` 渲染页面。
  当前没有注册表机制。
- `macosApp/src/Hub/HubNavRail.swift:65` 用 `ForEach(HubTab.allCases)` 渲染导航栏。

### 3.3 配置与持久化

- `kmpDomain/src/com/wyz/covio/core/Models.kt` 的 `AppConfig.schemaVersion` 当前是 `3`。
- `macosApp/src/App/AppRuntime.swift:663` 的 `ConfigDraft` 是 `AppConfig` 全部字段的可变镜像。
- `macosApp/test/ConfigCompatibilityTests.swift` 有 15 条用例守住 `config.json` 的兼容性。
- 持久化统一用 okio 加 kotlinx JSON，写入用 `.tmp` 加原子改名。
  `WorkspaceStore` 与 `ClipboardStore` 是现成样例。
- Amper 0.12.1 没有 SQLDelight 插件，所以不要引入数据库。

### 3.4 设计合同

- `docs/covio-design-contract.json` 是设计权威。每个组件同时带 `composeMapping` 和 `swiftMapping`。
- `scripts/validate-contract.py` 检查 schema 表达不了的跨节规则。
- `scripts/generate-contract-constants.py` 重写 `ContractCopy.swift` 与 `ContractTokens.swift`。
  这两个文件是生成的，不要手改。
- `kmpDomain/test/com/wyz/covio/core/DesignContractTest.kt` 有 19 条用例。
  `macosApp/test/ContractConstantsTests.swift` 有 27 条用例。

### 3.5 名称冲突

现有代码里的 `Workspace` 全部指跨设备共享暂存区，不指页签。

| 现有标识符 | 位置 | 含义 |
| --- | --- | --- |
| `WorkspaceKind` | `Models.kt:248` | 暂存条目的内容类型 |
| `WorkspaceEntry` | `Models.kt:280` | 一个内容寻址的暂存条目 |
| `WorkspacePolicy` | `Models.kt:334` | 配额、淘汰与过期策略 |
| `WorkspaceStore` | `WorkspaceStore.kt:42` | 暂存区的索引与内容存储 |
| `WorkspaceRuntime.swift` | `macosApp/src/Workspace/` | 暂存区的 Swift 运行时 |
| `workspace.*` | `WorkspaceWire.kt:18` | 控制通道的操作名 |

磁盘目录 `~/Library/Application Support/Covio/Workspace/` 也属于暂存区。

## 4. 命名决策

新概念必须换标识符。理由见 3.5 节。直接复用 `Workspace` 会与现有类型重名。

| 概念 | 代码标识符 | 中文 | 说明 |
| --- | --- | --- | --- |
| 整个产品形态 | `Workbench` | 挂帘工作台 | 触发层、挂帘外壳、工作区容器的总称。 |
| 一个页签 | `Pane` | 工作区 | 用户看到的一个页签。首页是一个 Widgets 工作区。 |
| 工作区的类型 | `PaneKind` | 工作区类型 | 例如 `widgets`、`clipboard`、`screenshots`。 |
| 工作区的一个实例 | `PaneInstance` | 工作区实例 | 带自己的 id、标题、图标和设置。 |
| 网格上的一块 | `Widget` | 组件 | 最小展示与交互单元。 |
| 跨设备共享暂存区 | `Workspace` | 共享暂存区 | 保持现有标识符不变。 |
| 工作台配置 | `WorkbenchConfig` | 工作台配置 | 存进 `workbench.json`。 |

警告：文档里写“工作区”时指页签。写“共享暂存区”时指现有 `Workspace`。
不要混用这两个词。

## 5. 目标架构

分四层。上层依赖下层。下层不认识上层。
本节只列层与类型名。完整的职责、边界、依赖方向和现有代码迁移见
[挂帘工作台架构骨架](../design/workbench-architecture.md)。

### 5.1 触发层

- 一个协议 `CurtainTrigger`。协议描述触发源的名字、权限需求和事件流。
- 一个注册表 `TriggerRegistry`。注册表持有全部触发源，并向挂帘外壳发出唯一的“打开”与“收起”事件。
- macOS 的触发源实现四个：`NotchHoverTrigger`、`TrackpadGestureTrigger`、`HotKeyTrigger`、`StatusItemTrigger`。
- 挂帘外壳只订阅注册表。外壳不认识任何具体触发源。
- 新增平台时只增加触发源实现。外壳代码不变。

### 5.2 挂帘外壳

- 复用现有 `NotchShellController` 与 `HubStateMachine`，改名为 `CurtainController`。
- 状态机增加两个状态：`PREVIEW` 和 `EDITING`。
- 面板复用 `ShellPanel` 的层级与 Space 设置。
- 外壳只负责可见性、位置、动效和键盘焦点。

### 5.3 工作区层

- `WorkbenchConfig` 保存工作区列表、顺序、每个工作区的设置和 Widget 布局。
- `WorkbenchLogic` 是纯函数模块。它实现增删改序、校验和默认布局。
- `WorkbenchStore` 用 okio 加 JSON 持久化，写入用原子改名。
- Swift 侧 `PaneRegistry` 把 `PaneKind` 映射到 SwiftUI 视图。
- 导航栏渲染 `PaneRegistry` 的实例列表，不再渲染枚举。

### 5.4 Widget 层

- `Widget` 描述一个组件实例：类型、尺寸档、位置和设置。
- 网格引擎把组件位置吸附到列。
- `WidgetCatalog` 声明可添加的组件类型。
- 编辑模式支持拖动、缩放和删除。

## 6. 阶段与里程碑

milestone 是阶段在 GitHub 上的投影。一个阶段对应一个 milestone。
milestone 的标题格式是 `P<n> · <阶段名称>`。分隔符是 U+00B7 中点。
阶段 label 的颜色是 `C5DEF5`。
阶段是概念，里程碑是投影，两者不是两个概念。格式见 [AUTHORING.md](AUTHORING.md) 第 2 节。

| 阶段 | 阶段名称 | label | 目标 | 退出条件 |
| --- | --- | --- | --- | --- |
| P0 | 调研与决策 | `phase-0-research` | 判定手势入口可行性，定下命名与存储方案 | 两份调研结论和两份 ADR 通过评审 |
| P1 | 挂帘内核 | `phase-1-curtain-core` | 触发层抽象落地，四指手势与刘海悬停可用 | 四个触发源在真机通过验收 |
| P2 | 工作区模型 | `phase-2-workspace-model` | 页签变成数据，可增删改名排序 | `workbench.json` 往返无损，迁移可回滚 |
| P3 | Widgets 首页 | `phase-3-widgets` | 首页是可编辑的组件网格 | 组件可添加、移动、缩放、删除 |
| P4 | 模块工作区化 | `phase-4-module-panes` | 现有六个页面搬进工作区 | 六个工作区功能不回归 |
| P5 | 质量与交付 | `phase-5-quality` | 合同、无障碍、性能与文档收口 | `scripts/test-all.sh` 通过，验收清单更新 |

## 7. Epic 与 sub-issue 索引

每个 epic 是一个父 issue。每个 sub-issue 是它的子 issue。
完整的 issue 正文在 `issues/` 目录。文件名前缀就是 issue 编号。

| 编号 | 标题 | 阶段 | 子项数 |
| --- | --- | --- | --- |
| `E00` | 调研与决策：挂帘工作台的前置结论 | P0 | 6 |
| `E01` | 触发层：统一的打开入口 | P1 | 6 |
| `E02` | 挂帘外壳：层级、动效与多屏 | P1 | 4 |
| `E03` | 工作区模型：把页签变成数据 | P2 | 5 |
| `E04` | 动态页签与工作区编辑器 | P2 | 4 |
| `E05` | Widgets 首页与网格引擎 | P3 | 6 |
| `E06` | 每工作区设置面 | P3 | 4 |
| `E07` | 现有模块工作区化 | P4 | 5 |
| `E08` | 设计合同与文案同步 | P5 | 4 |
| `E09` | 质量、测试与交付 | P5 | 5 |

## 8. 依赖关系

箭头方向是“被依赖 → 依赖”。

```text
E00 ──> E01 ──> E02
 │       │       │
 │       └───────┴──> E03 ──> E04 ──> E05 ──> E06
 │                              │
 └──> E08 <─────────────────────┘
                                │
                    E07 <───────┘
                                │
                    E09 <───────┘
```

关键路径是 `E00 → E01 → E03 → E04 → E05 → E06`。
`E08` 与 `E09` 贯穿全程，不阻塞功能开发，但必须在发布前完成。

## 9. 风险与未决项

### 9.1 阻断级风险

**`U-01`：iOS 的主页上滑手势不可实现。**
系统不向第三方应用提供主屏手势入口。

**结论已出（2026-10-13）。** 见 [iOS 免打开入口](../research/mobile-ambient-entry/README.md)。
主屏手势、锁屏手势和边缘手势都不开放。`E00-S02` 的八个问题已全部回答。
替代入口按优先级排序：

1. 主屏交互小组件，iOS 17.0 及以上。
2. 锁屏交互小组件，iOS 17.0 及以上。
3. 控制中心控件配 `OpenIntent`，iOS 18.0 及以上。这是唯一能一键进入指定工作区的入口。
4. Action Button，iOS 17.0 或 18.0 及以上，机型受限。
5. 轻点背面加快捷指令，iOS 14.0 及以上。
6. 应用内 `presentationDetents` bottom sheet。这不是免打开入口。

前四项共用同一套 App Intent。本路线图仍不为 iOS 排实现 issue。
实现留给后续单独评审。

**`U-02`：触控板四指下滑没有公开接口。**
系统把四指下滑默认映射给调度中心。应用收不到这个手势。
候选路径有三条：让用户改系统手势设置、用 `CGEventTap` 捕获滚轮事件、用私有
`MultitouchSupport.framework`。
第一条不可靠。第二条只能看到两指滚动。第三条有效但属于私有 API。

**结论已出（2026-10-13）。** 见 [触控板多指手势入口](../research/trackpad-gesture-entry/README.md)。
四指下滑**可交付**，路径是私有 `MultitouchSupport.framework`。
本机实测：框架可 `dlopen`，`MTDeviceCreateList` 返回内建设备，
`MTRegisterContactFrameCallback` 加 `MTDeviceStart` 成功。
公开 API 无替代路径。macOS 26 与 27 没有新增全局多指手势接口。
私有表面不稳定：四个 `MTDeviceGet*` 访问器在本机以信号 11 崩溃。
因此 `E01-S02` 保留，实现范围限定在四个核心函数。
降级路径仍是快捷键与刘海悬停。私有路径失效时由降级路径承担。
私有路径是否需要输入监控权限尚未验证，列为验证案例 `V05`。

**`U-03`：手势与悬停需要输入监控权限。**
本仓库已在 `PointerTrackingHost.swift:6` 记录过相关教训。
权限被拒时必须降级到快捷键和菜单栏图标。降级路径必须在 `E01-S05` 实现。

### 9.2 一般风险

| 编号 | 风险 | 缓解 |
| --- | --- | --- |
| `R-01` | 动态页签破坏 `DesignContractTests` 的页签顺序断言 | `E04-S04` 先改写断言，再改渲染 |
| `R-02` | 工作台配置写坏导致启动失败 | 读取失败时回退默认布局，并保留损坏文件副本 |
| `R-03` | `config.json` 兼容性回归 | 工作台配置放独立文件，`schemaVersion` 不动 |
| `R-04` | 面板层级与全屏 Space 行为回归 | `E02-S01` 覆盖现有 9 条 `ShellPanelTests` |
| `R-05` | 组件网格在低端机器上掉帧 | `E09-S02` 设定展开耗时与空闲 CPU 预算 |

### 9.3 未决项

1. 私有 `MultitouchSupport.framework` 是否可接受。这决定四指手势能否交付。
2. 工作区数量上限是否设限。
3. 用户能否删除内置工作区。
4. 组件尺寸档取几档。
5. 编辑模式是就地编辑还是独立页面。
6. 工作区设置是否参与全局搜索。
7. Windows 的固定热区尺寸与位置。
8. iOS 的替代入口优先做哪一个。已由 `E00-S02` 给出优先级，见 `U-01`。

## 10. 不在范围内

- Windows 与 iOS 的实现。本路线图只留抽象接口和调研结论。
- Android。当前没有目标，也不建 issue。
- 共享暂存区的协议与存储。见 `docs/research/shared-transfer-workspace/`。
- 电源、合盖与 DarkWake 功能。这些功能保持现状。
- 云端账号与云同步。产品约束禁止。

## 11. 验收标准

改造完成后逐条核对。

1. 触控板四指下滑打开挂帘。若 `E00-S01` 判定不可行，则此条改为快捷键与悬停。
2. 鼠标移到刘海区域，挂帘出现预览态，停留后展开。
3. 非刘海屏在菜单栏下方出现热区，行为与刘海屏一致。
4. 挂帘展开后位于菜单栏之上，且不抢走前台应用的键盘焦点。
5. 首页显示 Widgets 网格。网格中的组件可以拖动、缩放和删除。
6. 导航栏的页签来自 `workbench.json`，不是硬编码枚举。
7. 用户可以添加、删除、改名和排序工作区。
8. 每个工作区有自己的设置入口，设置立即生效并持久化。
9. 删除工作区后重启应用，删除结果保留。
10. `workbench.json` 损坏时应用能启动，并回退到默认布局。
11. `config.json` 与 0.4.2 保持双向兼容。
12. 全屏 Space 中不显示热区。
13. 多显示器下挂帘出现在指针所在屏幕。
14. 开启“减少动态效果”后，展开与收起只改变透明度。
15. 键盘可以完成全部主要动作。焦点始终可见。
16. `bash scripts/test-all.sh` 通过。
17. `python3 scripts/validate-contract.py` 通过。
18. `README.md`、`RELEASE_NOTES.md` 与真机验收清单同步更新。

## 12. 用法

`issues/` 目录里的每个文件是一个 issue 定义。文件用 YAML front-matter 描述标题、
标签、父 issue 和阻塞关系。正文就是 issue 正文。

issue 定义文件的字段格式见 [AUTHORING.md](AUTHORING.md) 第 5 节。
立项、排期、进度汇总和阶段收口的流程见 [roadmap-first.md](../workflow/roadmap-first.md)。
本路线图的进度从 GitHub 上 sub-issue 的实际状态推导，本文档不记录进度。

预览将创建的 issue，不写入 GitHub：

```sh
bash scripts/create-roadmap-issues.sh --dry-run
```

创建全部 issue：

```sh
bash scripts/create-roadmap-issues.sh
```

脚本先建标签，再建 epic，再建 sub-issue，最后回填阻塞关系。
脚本把编号映射写入 `docs/roadmap/issues/.created.json`。
脚本可以重复运行。已创建的 issue 会跳过。

**警告：** 本仓库是公开仓库。执行脚本会把全部 issue 发布到 GitHub。
执行前先运行 `--dry-run` 并确认输出。
