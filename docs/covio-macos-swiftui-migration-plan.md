# Covio macOS UI 迁移 SwiftUI 实施计划

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 已定稿，执行中 |
| 日期 | `2026-10-12` |
| 适用对象 | Covio 研发、测试和发布人员 |
| 迁移策略 | 集成分支承接全部短分支，阶段收口时一次合入主干 |
| 切换版本 | `0.5.0` |
| 当前阶段 | `M6` 已完成 |
| 完成判据 | 每阶段结束 `/bin/sh ./kotlin test` 全绿 |

### 文档链

| 层级 | 文件 | 职责 |
| --- | --- | --- |
| 设计合同 | [covio-design-contract.json](covio-design-contract.json) | 机器可读设计权威 |
| 合同解释 | [covio-product-design.md](covio-product-design.md) | 解释设计合同 |
| 迁移计划 | 本文档 | macOS UI 迁移的范围、阶段和判据 |

## 1. 背景与目标

Covio 是 macOS 功能中枢应用。
目标交互是刘海触发、窗帘式展开的 Hub 面板。

当前实现用 Compose Multiplatform 画 macOS 界面。
Compose 与 macOS 平台的接缝很脆弱。
`app/src/com/wyz/covio/app/platform/MacShelfNative.kt` 通过反射拿到 AWT `Component.peer`，再用 `objc_msgSend` 发消息。
Hub 需要非激活面板、鼠标穿透、全宽工具条。
这些能力在 Compose Desktop 上很难做。

本次迁移把 macOS 界面层换成原生 SwiftUI。
KMP 保留为共享底座。
截图工作区集成 tendedero。
剪贴板集成 dodoclip。

预期结果：

1. Hub 挂帘可用。
2. 截图与剪贴板两个模块落地。
3. `libCovioDrag.dylib` 从 macOS 路径消失。

第 3 项原文写的是「`libCovioDrag.dylib` 与 JNA」。JNA 只去掉了一半：
`HelperServer` 仍用它做 Unix 域套接字的 `getpeereid`。见 §13 的 D7。

## 2. 前提修正

方案描述里有三处与仓库事实不符。
本计划以事实为准。

| 方案描述 | 事实 | 证据 |
| --- | --- | --- |
| 构建链路是 Gradle | 构建系统是 Amper 0.12.1 | `project.yaml`、`app/module.yaml`、CLI 包装脚本 `./kotlin` |
| 当前是多个 Swift 原生项目的集合 | 仓库零个 Swift 文件 | 无 `.swift`、无 `.xcodeproj`、无 `Package.swift` |
| KMP 共享层产出 Native Framework 供 Swift 调用 | `core` 只有 JVM target | `core/module.yaml` 的 `platforms: [jvm]` |

另有四处现状落差：

1. Hub 挂帘、剪贴板、临时文件、局域网互传全部零实现。代码里只有睡眠控制、截图工具栏、Tray 菜单、设置窗口。
2. 产品需求写死「macOS 宿主 = Compose Desktop 加平台桥接」。本次迁移必须先改这一条。已在 M5 改为「SwiftUI 加 KMP 共享层」。
3. 设计合同 `docs/covio-design-contract.json` 的 22 条 `components` 都带 `composeMapping`。`composeMapping` 在 schema 的 `$defs.component.required` 里。`platformMapping.status` 是单值枚举 `["native-source-mapped"]`。已在 M5 加 `swiftMapping`、加宽枚举、加 `swiftRuntimeTarget`。
4. 设计合同没有 motion token。已在 M5 补进 `token/motion/*`。

### 本次沉淀时的复核修正

| 项目 | 计划原文 | 仓库实测 | 影响 |
| --- | --- | --- | --- |
| `app/src/com/wyz/covio/app/platform/` 文件数 | 21 | 22 | M6 删除清单的判据 |
| `app/test/com/wyz/covio/` 测试文件数 | 19 | 18 | M6 保留清单的判据 |
| `copy/notch-hub/*` 文案键数 | 23 | 14 | M1 状态机文案覆盖的判据 |

`copy/notch-hub/*` 的 14 条键含 11 条状态键与 3 条布局键。
11 条状态键覆盖 `menuBarAndNotchHub` 的 6 个状态与 `notchOutputHub` 的 6 个状态，其中 `error` 与 `copy/notch-hub/state/error` 共用。

## 3. 已确认决策

| 决策项 | 结论 |
| --- | --- |
| 迁移策略 | 一次性切换。集成分支是 `feature/swiftui-macos`。每个 issue 切一条短分支，阶段收口时一次合入主干 |
| KMP 边界 | `kmpDomain` 加 `macosArm64`，产出 framework 供 Xcode 链接 |
| 平台实现 | 与操作系统相关的引擎和底层按平台分开实现，由 KMP 统一管理接口 |
| 剪贴板数据 | `kmpDomain` common 模型 + SQLDelight |
| 交付范围 | Notch Shell + 现有 4 项能力 + 截图 Panel + 剪贴板 Panel |
| 外部源码 | 复制源码并署名。tendedero 与 dodoclip 都是 MIT |
| 设计合同 | 分阶段加字段，不改既有字段语义 |

## 4. 已核实的关键事实

这些事实是本计划的依据。

1. **Amper 0.12.1 支持 Apple native target。** 平台枚举含 `macosArm64`、`macosX64`、`iosArm64`、`apple`、`native`。证据：`~/Library/Caches/JetBrains/Kotlin/cli/kotlin-cli-0.12.1/lib/schema-jvm.jar` 的 `DeclarationOfEnumPlatform`。
2. **本机有可直接照抄的同构先例。** `/Users/wyz/repo/kmp-translator/iosApp/` 用 `product: type: ios/app`，把 `module.xcodeproj` 提交进 git，Swift 源码放 `src/`。
3. **本机有 SQLDelight 的 Amper 配置模板。** `/Users/wyz/repo/kmp-translator/shared/module.yaml` 用 `plugins: sqldelight-codegen: enabled`，按平台引 `native-driver` / `sqlite-driver` / `android-driver`。版本是 sqldelight `2.3.2`、okio `3.18.1`。
4. **dodoclip 是 MIT。** DodoApps/dodoclip，29 个 Swift 文件，macOS 14+。`Package.swift` 里只有 `executableTarget`，没有 library product。因此不能作为包依赖，只能复制源码。
5. **tendedero 是 MIT。** alejandrobujan/tendedero。`THIRD_PARTY_NOTICES.md` 已含 MIT 全文与「不使用名称、图标、文档图片」的声明。
6. **合同已有两套 Hub 状态词汇。** `states.menuBarAndNotchHub.hubStates = HIDDEN/HOVER/OPEN/ACTIVE/EXIT/ERROR`。`states.notchOutputHub` 的状态是 `COLLAPSED/READY/EXPANDED/DRAG TARGET/PROCESSING/ERROR`。`copy/notch-hub/*` 段已有 14 条对应文案键。
7. **合同的 schema 约束很严。** 根与 `$defs.component` 都是 `additionalProperties: false`。`components` 的 `minProperties = maxProperties = 22`。`composeMapping` 在 `required` 里。
8. **Figma 工具链存在。** `.git/covio-figma/proto_status.mjs` 与 `verify_text.mjs` 都在。
9. **现有面板常量。** `PANEL_COLLECTION_BEHAVIOR = 0x51`（`canJoinAllSpaces | stationary | fullScreenAuxiliary`）。`FLOATING_WINDOW_LEVEL = 3`。
10. **现有全局快捷键用 Carbon。** `GlobalHotKey.kt` 用 `RegisterEventHotKey`，键码 `17` = `T`。Carbon 不需要辅助功能权限。

## 5. 目标架构

```text
macosApp (SwiftUI + AppKit)          ← 新增，macOS 唯一 UI
├── NotchShell/                      NSPanel + 状态机 + 热区
├── Hub/                             Tab 容器 + 模块协议
├── Modules/Now|Clipboard|Files|Screenshots|Devices|Settings
├── Platform/                        Ports 的 macOS 实现（Swift）
└── Vendored/                        dodoclip、tendedero 复制来的源码
        │ 链接 kmpDomain.framework
kmpDomain (KMP)                      ← 新增
├── commonMain                       模型 + Ports 接口 + Engine 状态机 + 纯几何
├── macosArm64Main                   仅放非 OS 的 macOS 相关纯逻辑
└── (未来) androidMain / mingwX64Main
        ▲
core (KMP, jvm)                      ← 保留，服务 app 与未来平台
app  (jvm/lib, Compose)              ← 保留，未来 Windows/Android 宿主的界面件与 helper 协议
```

### 5.1 平台实现的分工

`kmpDomain` common 定义 Ports 接口与 Engine 状态机。
macOS 侧实现这 9 个接口，实现用 Swift 写。

选 Swift 的原因：IOKit、IOPMAssertion、SMAppService、UNUserNotificationCenter 在 Swift 里是原生 API。
在 Kotlin/Native 里要写 cinterop 与 `.def` 文件。

Kotlin/Native 导出 interface 为 Objective-C protocol。
Swift 类可以实现并回传实例。
这是标准的依赖注入模式。

退路：如果 M0 验证发现 Swift 实现 Kotlin protocol 有阻碍，就在 Kotlin/Native 写 `actual`。
退路的代价是约 600 到 1000 行 cinterop 代码。

## 6. 工程结构改动

### 6.1 新增文件

| 路径 | 说明 |
| --- | --- |
| `project.yaml` | 改 `modules` 为 `[app, core, kmpDomain, macosApp]` |
| `kmpDomain/module.yaml` | `product: kmp/lib`，`platforms: [jvm, macosArm64]`，`plugins: sqldelight-codegen: enabled` |
| `kmpDomain/src/` | `commonMain` 与 `macosArm64Main` 源码 |
| `kmpDomain/src@macosArm64/` | Amper 平台源集用目录后缀 |
| `kmpDomain/sqldelight/` | `.sq` 文件 |
| `macosApp/module.yaml` | `product: type: macos/app` |
| `macosApp/module.xcodeproj/` | 提交进 git，照抄 `kmp-translator/iosApp` |
| `macosApp/src/*.swift` | SwiftUI 与 AppKit 源码 |
| `macosApp/src/Info.plist` | 含 `LSUIElement` |
| `macosApp/src/Assets.xcassets/` | 资源目录 |
| `scripts/build-macos-swift.sh` | `./kotlin build` + `xcodebuild` |
| `scripts/package-macos-swift.sh` | `xcodebuild archive` + `codesign` + `diskutil image create` |
| `scripts/test-macos-swift.sh` | `xcodebuild test` |
| `.github/workflows/ci.yml` | Kotlin 测试 + Swift 测试 |
| `doc/adr/adr-0001-macos-ui-swiftui.md` | 架构决策记录 |

**已按实际情况修正：** 上表是计划原文，保留作历史记录。以下四行与实际不符，以实际为准。

- `project.yaml` 的实际值是 `modules: [app, kmpDomain]`。`core` 并入了 `kmpDomain`。`macosApp` 是 Xcode-only 工程，按 ADR-001 决策 4 有意不注册进 Amper。
- `kmpDomain/module.yaml` 的 `plugins: sqldelight-codegen: enabled` 未落地。Amper 0.12.1 没有该插件，理由见 D1。
- `kmpDomain/sqldelight/` 未创建，与上一行同一原因。
- `macosApp/module.yaml` 未创建。`product: type: macos/app` 不是 SwiftUI 宿主，理由见 ADR-001 实测 4。

**注意：** Amper 的平台源集用目录后缀，不是 Gradle 的 `commonMain`。
写法是 `src@macosArm64/`、`test@jvm/`。参照 `/Users/wyz/repo/kmp-translator/shared/`。

**注意：** Xcode 工程的两处 `ARCHS` 写死为 `arm64`。
`kmpDomain.framework` 只有 `macosArm64` 一个切片，Release 默认按 `ARCHS_STANDARD` 出双架构会链接失败。
`scripts/package-macos-swift.sh` 另在命令行传一次 `ARCHS=arm64`。

### 6.2 不改动的文件

`app/module.yaml`、`core/module.yaml`、`scripts/package-macos.sh`、`scripts/create-release.sh` 在 M6 之前不动。
Compose 版继续是发布物。

### 6.3 引入 Xcode 硬依赖

`README.md` 第 137 行的 Requirements 要更新。
最低系统版本从 macOS 12 提到 macOS 14。

理由：dodoclip 要求 macOS 14。
SwiftUI 的 `@Observable` 要求 macOS 14。

## 7. 阶段划分

每个阶段结束都要满足：`/bin/sh ./kotlin test` 全绿。

### M0 — Spike 与脚手架

交付：

1. `kmpDomain` 模块，`platforms: [jvm, macosArm64]`，含一个 `@ObjCName` 导出的最小类。
2. `macosApp` 模块，`product: type: macos/app`，含 `@main` SwiftUI 空窗口。
3. Xcode 工程链接 `kmpDomain` framework，Swift 成功调用该 Kotlin 类。
4. 一个 spike 打印 `NSScreen.safeAreaInsets`、`auxiliaryTopLeftArea`、`NSWorkspace.frontmostApplication`。
5. `ADR-001` 记录 M0 结论。

完成判据：

- `xcodebuild` 产出 `.app`，窗口显示，Kotlin 函数返回正确值。
- `/bin/sh ./kotlin build` 仍然全绿。
- 下面 5 个未知项全部结案，结论写进 `ADR-001`。

必须在 M0 结案的未知项：

| 未知项 | 确认方法 |
| --- | --- |
| Amper 是否产出 `macosArm64` 的 framework 任务 | `./kotlin build` 后 `ls -R build/tasks/`，对照现有 `build/tasks/_app_executableJarJvm` 命名规律 |
| Swift 类能否实现 Kotlin 导出的 protocol 并注入 | 写一个接口 + Swift 实现 + 回传，跑通即可 |
| `.mouseMoved` 全局监听是否免辅助功能权限 | 注册监听，看系统设置里的辅助功能列表是否新增条目 |
| `NSPanel` 相对系统 UI 的正确 level | spike 打印 `CGWindowListCopyWindowInfo` 的层级 |
| 全屏 Space 的最可靠检测方式 | 移植现有 `MacShelfNative.isFullScreenSpaceActive`（用 `CGSCopyManagedDisplaySpaces` 判 `type == 4`），已跑通 |

**风险：** 若第 1 项失败，退到「手写 Xcode 工程 + Run Script 调 `./kotlin build`」这条经典 KMP 路线。退路的代价是多维护一份 pbxproj 链接配置。

此阶段不触碰 Compose 版。发布物仍是 `0.4.2`。

### M1 — Notch Shell 骨架

交付：

1. `NSStatusItem` 菜单栏图标，`LSUIElement = true`。
2. 热区检测与 `NSPanel` 状态机。
3. 6 个页签按顺序全部占位：Now、Clipboard、Files、Screenshots、Devices、Settings。
4. 非刘海屏降级热区。

`NSPanel` 配置：

| 项 | 值 | 理由 |
| --- | --- | --- |
| `styleMask` | `[.nonactivatingPanel, .borderless]` | 非激活是粘贴回填的硬前提。见 M4 |
| `level` | `.statusBar` | 必须高于菜单栏。现有 Compose 的 `3` 太低 |
| `collectionBehavior` | `[.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]` | 对齐现有 `0x51`，补 `.ignoresCycle` |
| `isFloatingPanel` | `true` | 标准做法 |
| `hidesOnDeactivate` | `false` | 产品要求：编辑与拖拽时不收起 |
| `isMovable` / `hasShadow` | `false` / `false` | 沿用现有实现 |
| `ignoresMouseEvents` | 动态 | 折叠态 `true` 穿透；展开态 `false` |

状态机用合同词汇，不造新词。

- `hubStates`（`HIDDEN`/`HOVER`/`OPEN`/`ACTIVE`/`EXIT`/`ERROR`）管 `NSPanel` 的可见性与生命周期。
- `notchOutputHub`（`COLLAPSED`/`READY`/`EXPANDED`/`DRAG TARGET`/`PROCESSING`/`ERROR`）管内容区。
- 两个状态机正交。合同已给出各自独立的 `interactionPath`，说明设计者本来就当它们是两台机器。

时序如下：

| 动作 | 时长与曲线 |
| --- | --- |
| 展开 | 220–280 ms 弹性 |
| 收起 | 160–220 ms 缓出 |
| 页签切换 | 160 ms |
| 减弱动态 | 120 ms，仅改透明度 |
| 指针移出后收起 | 500 ms |
| Escape 收起 | 立即 |

多显示器用单面板。显示时重定位到指针所在屏。
全屏 Space 隐藏顶部热区。

完成判据：

- 热区在指针所在屏正确开合。
- 非刘海屏降级可用。
- Compose 版与 SwiftUI 版可同时运行（两版用不同的 lock 文件路径）。

### M2 — 能力平迁

交付：

1. `kmpDomain` 收 `Models.kt`、`Ports.kt`、`Version.kt`、`UpdatePolicy.kt`、`PmsetWakeLogParser.kt`、`ShelfLogic.kt` 的几何部分、`Engine.kt` 的状态机。
2. `ConfigStore` 与 `ShelfStore` 改用 okio，放 `kmpDomain`。
3. macOS 的 9 个 Ports 实现用 Swift 写在 `macosApp/src/Platform/`。
4. 特权 helper 的 client 与 server、登录项、通知，迁到 Swift。
5. `SettingsWindow.kt`（495 行）迁到 SwiftUI。

`Engine.kt` 的改造点：

| 现状 | 改造 |
| --- | --- |
| 约 30 处 `synchronized` | Kotlin/Native 不存在。改成 kotlinx.coroutines 的单一 dispatcher 加 `Mutex` |
| `AtomicBoolean` | 换 `kotlinx.atomicfu` |
| `Thread.sleep` | 换 `delay` |

完成判据：

- `core/test/com/wyz/covio/EngineTest.kt` 的断言在 XCTest 里全部重建并通过。这是行为基线。
- `config.json` 与 `0.4.2` 双向兼容。做法：Swift 的 `Codable` 对缺失键给默认值，对未知键容忍。
- helper 可安装、卸载、判定 `OUTDATED`。新增 `scripts/verify-helper-cutover.sh` 做断言。

**警告：** 特权 helper 是 LaunchDaemon `com.wyz.covio.helper`。它的 `ProgramArguments[0]` 是旧可执行文件的绝对路径。切换二进制前先卸载旧 helper。否则新 app 判定版本不匹配。

### M3 — 截图模块与切换

交付：

1. Screenshots 页签内嵌横向晾衣线区域。
2. 全宽 210 pt 独立工具条面板保留。
3. 复制 tendedero 的相关源码进 `macosApp/src/Vendored/Tendedero/`。
4. `CovioDrag.m` 的能力用 Swift 重写。删除 `libCovioDrag.dylib` 与 JNA。
5. `ScreenshotWatcher`、`ScreenshotPreferenceStore`、`ShelfClipboard`、`ShelfFileOperations` 迁到 Swift。

两种形态共享同一套几何。
`ShelfLogic.kt` 的 `slotX` / `sag` / `ropeY` / `cardBounds` 都把 `screenWidth` 当参数传入。
抽出一个 `ClotheslineView(containerWidth:count:)`。
全宽面板传屏宽，Hub 面板传面板内容宽度。

原有常量 `CARD_WIDTH=144`、`CARD_HEIGHT=112`、`SPACING=164`、`PHOTO_MAX_WIDTH=136`、`PHOTO_MAX_HEIGHT=104` 要在 Swift 重建。
与合同 `nativeSize` 冲突时以合同为准。
把这条校验写成 XCTest 断言。

完成判据：

- 与 `component/screenshot-card` 和 `component/clothespin` 的 `nativeSize` 逐值断言通过。
- 捕获 650 ms 与复制 1200 ms 摆动符合设计合同。
- 拖拽到 Finder、桌面、废纸篓行为符合 `README.md` 第 76 到 81 行。

**这是切换点。** SwiftUI 版成为发布物，建议版本 `0.5.0`。Compose 版进维护分支。

### M4 — 剪贴板模块

交付：

1. `kmpDomain` 的剪贴板模型：条目、分类（链接/图片/颜色）、置顶、粘贴栈、保留策略。
2. SQLDelight 表结构与 `native-driver` 接入。
3. 复制 dodoclip 的相关源码进 `macosApp/src/Vendored/DodoClip/`。
4. 剪贴板监听用 `NSPasteboard` 变更通知。
5. OCR 用 Vision 的 `VNRecognizeTextRequest`，结果写回共享表。
6. 全局快捷键 `⇧⌘V` 与 `⇧⌘C` 用 Carbon，沿用现有 `GlobalHotKey.kt` 的做法。
7. 粘贴回填用 `CGEvent` 合成 `⌘V`。
8. 辅助功能权限引导。

**警告：** 粘贴回填必须先捕获 `NSWorkspace.shared.frontmostApplication`，再显示 Hub。Hub 面板必须是非激活面板。否则 Hub 一弹出就改变前台应用，`⌘V` 无处可发。这条约束同时决定 M1 的面板配置。

**警告：** 全局快捷键与其它 App 冲突时 Carbon 静默失败。设置页必须暴露「注册失败」状态并允许改键。

数据划分：

| 部分 | 位置 |
| --- | --- |
| 条目模型、分类、置顶、粘贴栈、保留策略 | `kmpDomain` common |
| 元数据与文本 | SQLite，文件在 `~/Library/Application Support/com.wyz.covio/` |
| 图片等二进制 | 文件系统，沿用 `Screenshots/` 目录惯例 |
| 剪贴板读取、OCR、权限探测 | Swift |

完成判据：

- 粘贴回填在原生 App、Electron、终端、安全输入框四类目标中验证。
- `⇧⌘V` 冲突时设置页可见失败。
- 权限被拒后有降级路径。

### M5 — 合同与文档同步

严格按 `docs/covio-product-design.md` 的 ①→⑩ 顺序执行。

合同改动：

| 动作 | 内容 |
| --- | --- |
| `$defs.component.properties` | 增加 `swiftMapping: { target, behavior }`，与 `composeMapping` 同构。22 个组件逐个补齐 |
| `$defs.component.required` | 保持 `composeMapping` 不变。它继续描述未来 Compose 宿主，Figma 交付脚本依赖它 |
| `$defs.platformMapping.properties.status` | 枚举加宽为 `["native-source-mapped", "swift-source-mapped", "dual-source-mapped"]`。加宽不改语义，已有 25 条仍合法 |
| `$defs.platformMapping.properties` | 增加 `swiftRuntimeTarget`，25 条逐个补齐 |
| `$defs` | 增加 `motionToken` 与 `swiftStateMapping`。动效令牌没有 Figma 变量，塞进 `$defs.token` 会把两个必填的变量 ID 撑坏，所以单开一个定义，根 `tokens` 段用 `oneOf` 接住两类 |
| `tokens` | 补 9 条动效参数，另补「指针移出后收起」1 条 |
| `states` | 增加 `swiftRuntimeMapping`：`hubStates` 与 `notchOutputHub` 各自到 Swift 类型的映射 |
| `metadata.knownDifferences` | 增一条：macOS 运行时由 Compose 换为 SwiftUI |
| `metadata.kotlinInterfaces` | 4 个接口的 `status` 由 `future-not-implemented` 改为 `implemented`，并加 `path` |
| `schemaVersion` | `1.2.0` → `1.3.0` |

不改动：`runtimeTarget` 的语义、任何既有字段名、`figmaNodeMap`、`platformMapping` 已有 25 条的 `status` 值。

**警告：** schema 无法表达「macOS 下 `swiftMapping` 必填」。这条要求写进了新脚本 `scripts/validate-contract.py`，并由 `scripts/test-macos-swift.sh` 与 `scripts/test-all.sh` 调用。
同一份检查在 Kotlin 的 `DesignContractReader` 与 Swift 的 `ContractConstantsTests` 里各有一遍：三处口径一致，任一处漏写都会被拦下。

`metadata.kotlinInterfaces` 的 4 个接口（`DesignContract` / `DesignContractReader` / `DesignContractValidationResult` / `DesignContractDiagnostic`）本次落地。
它们是纯序列化代码，正好作为 `macosArm64` framework 管线的最小验证负载。
放 `kmpDomain` common 的 `DesignContract.kt`，未来 Compose 宿主也能用。
Swift 侧有测试直接调 `DesignContractReader.shared.readFile(path:)`，同时验证导出。

`components` 的 `minProperties = maxProperties = 22` 意味着不能新增组件。
Hub 若需要合同外的新组件，只能映射到已有的 `component/tab-bar` 或 `component/window-shell`。
否则要改这两个数字。

文档改动：

- `docs/covio-product-design.md`：新增「SwiftUI 映射」一节；「修改流程」由 10 步扩为 12 步，加入合同校验器与常量生成器。
- `doc/adr/adr-0001-macos-ui-swiftui.md`：「阶段」一行由「M0 结案，M1 结案」改为指向本文档的进度表。
- `README.md`：更新 Requirements、构建命令、目录说明。
- 设计合同的修改顺序是：先改 contract → 更新 schema → 校验 → 再改 Figma。本次视觉不变，Figma 步骤评估为 no-op，但要在提交信息里显式记录。

### M6 — 退役 Compose macOS 宿主

交付：

- 删除 `scripts/package-macos.sh`，新建 `scripts/package-macos-swift.sh`。
- 删除 `app/src/com/wyz/covio/app/platform/` 下 22 个文件。
- 删除失去被测对象的 10 个测试文件。
- 删除 `native/`：`CovioDrag.h`、`CovioDrag.m`、`libCovioDrag.dylib`。
- 删除 Compose 宿主的入口与三个只服务它的界面文件：`Main.kt`、`ui/AppRuntime.kt`、`ui/ShelfWindow.kt`、`ui/SettingsWindow.kt`。

删除的 10 个测试：

| 测试 | 被测对象 |
| --- | --- |
| `GithubUpdateCheckerTest` | `GithubUpdateChecker` |
| `GlobalHotKeyTest` | `GlobalHotKey` |
| `IdleSleepTimeoutCacheTest` | `IdleSleepTimeoutCache` |
| `MacLoginItemTest` | `MacLoginItem` |
| `PmsetWakeLogReaderTest` | `PmsetWakeLogReader` |
| `ScreenshotPreferenceStoreTest` | `MacScreenshotPreferenceStore` |
| `ScreenshotTakeoverControllerTest` | `ScreenshotTakeoverController`，断言里带真的 `ScreenshotPreferenceStore` |
| `ScreenshotWatcherTest` | `ScreenshotWatcher` |
| `ShelfFileOperationsTest` | `ShelfFileOperations` |
| `SingleInstanceLockTest` | `SingleInstanceLock` |

这 10 项的被测对象在 Swift 侧重写。
多数接手方在 `macosApp/test` 的既有文件里：`ShelfPlatformTests`、`ShelfRuntimeTests`、`AppRuntimeTests`、`AppPathsTests`、`ClipboardTests`。
`PmsetWakeLogReader` 的解析部分在 `kmpDomain`，由 `PmsetWakeLogParserTest` 接手。

三个被测对象在 Swift 侧一个测试都没有。本次补上：

| 新增测试 | 被测对象 | 移植自 |
| --- | --- | --- |
| `UpdateCheckerTests` | `GithubUpdateChecker.parseRelease` | `GithubUpdateCheckerTest` |
| `SleepControllerTests` | `IdleSleepTimeoutCache` | `IdleSleepTimeoutCacheTest` |
| `LoginItemTests` | `MacLoginItem` | `MacLoginItemTest` |

三处的实现本来就留了注入口：可注入的 `URLSession`、时钟、命令执行器。
所以新测试不碰网络、不碰真的 LaunchAgents 目录、不跑真的 `launchctl`。

保留：

- `app` 模块与 `core` 模块，服务未来 Windows/Android。
- `app/test` 的 8 个测试文件。

`app` 的 `product` 由 `jvm/app` 降为 `jvm/lib`。
`app/module.yaml` 去掉 `kotlinx.coroutines.swing`，改引 `kotlinx.coroutines.core`。
JNA 保留：`HelperServer` 用它做 Unix 域套接字的 `getpeereid`。

两处搬迁，避免删掉别的测试还要用的代码：

| 原位置 | 新位置 | 使用者 |
| --- | --- | --- |
| `app/ui/AppRuntime.kt` 的 `awaitHelperStatus` | `app/helper/HelperStatusAwait.kt` | `HelperStatusAwaitTest` |
| `app/ui/AppRuntime.kt` 的 `formatBattery` | `app/ui/TrayPresentation.kt` | `TrayPresentationTest` |

完成判据：`./kotlin build` 与 `./kotlin test` 仍通过；`core` 的测试仍通过。

## 8. 风险清单

| 编号 | 风险 | 验证手段 |
| --- | --- | --- |
| R1 | Amper 的 `macosArm64` framework 管线无本机先例 | M0 spike。失败则退到手写 Xcode 工程加 Run Script |
| R2 | 面板行为回归：鼠标穿透、非激活、全屏 Space | 手工矩阵：刘海与非刘海 × 单双显示器 × 全屏 Space × 明暗 × 减少动态开关。插桩 HUD 常显 `hubState` 与 `frontmostApplication` |
| R3 | 集成分支期间无 CI、Swift 侧零测试 | 已在集成分支上建 XCTest target 与 `.github/workflows/ci.yml`。短分支合入集成分支前 CI 必须全绿 |
| R4 | 特权 helper 割接断裂 | `scripts/verify-helper-cutover.sh`。检查 LaunchDaemon plist、`APP_PATH_FILE`、`VERSION_PATH` |
| R5 | 两版共存互相干扰 | 新 app 用不同的 lock 文件路径。`config.json` 双向兼容测试 |
| R6 | 集成分支与主干的合并冲突集中爆发 | 集成分支每两周 rebase 一次主干。短分支只存活一个 issue 的时长，冲突面因此收窄。M3 切换窗口尽量短 |
| R7 | 最低系统版本从 12 提到 14，影响存量用户 | 在 README 与发布说明中明示。`0.4.x` 继续服务 macOS 12 |

## 9. 验证方案

每个阶段结束执行：

```sh
/bin/sh ./kotlin test
/bin/sh ./kotlin build
```

M0 之后叠加：

```sh
bash scripts/build-macos-swift.sh
bash scripts/test-macos-swift.sh
```

M2 之后叠加：

```sh
bash scripts/verify-helper-cutover.sh
```

M6 之后叠加：

```sh
bash scripts/package-macos-swift.sh
```

打包脚本自己断言：`ARCHIVE SUCCEEDED`、`codesign --verify --deep --strict` 通过、DMG 内同时有 `Covio.app` 与指向 `/Applications` 的链接、`hdiutil verify` 报 checksum VALID。

M5 之后执行合同校验：

```sh
python3 -m json.tool docs/covio-design-contract.json > /dev/null
python3 -m json.tool docs/covio-design-contract.schema.json > /dev/null
python3 -I scripts/validate-contract.py        # schema 表达不了的跨段规则
python3 -I scripts/generate-contract-constants.py --check
# 用一个 Draft 2020-12 校验器跑 contract 对 schema
node .git/covio-figma/proto_status.mjs    # 期望 42 reactions
node .git/covio-figma/verify_text.mjs     # 期望 1259 文字节点
git diff --check
```

端到端验收用 `README.md` 第 261 到 307 行的 41 项清单。
清单里的截图、睡眠、helper 项在 SwiftUI 版上逐条重跑。

## 10. 未确认项

M0 阶段提出的五项，结论已记入 `doc/adr/adr-0001-macos-ui-swiftui.md`。

| 未确认项 | 结论 |
| --- | --- |
| Amper `macos/app` 在 `compose.enabled: false` 且入口是手写 SwiftUI `@main` 时的行为 | 不走 Amper。`macosApp` 是独立 Xcode 工程，Amper 只管 `kmpDomain` |
| Amper 是否产出 `macosArm64` 的 framework 打包任务 | 不产出。framework 由 `scripts/build-kmp-framework.sh` 调 `konanc` 生成 |
| `.mouseMoved` 全局监听在 macOS 27 是否免辅助功能权限 | 见 ADR 实测记录 |
| `NSScreen.auxiliaryTopLeftArea` 在 macOS 27 的可用性与返回值 | 见 ADR 实测记录 |
| Swift 实现 Kotlin protocol 并注入的实际摩擦 | 可用。摩擦集中在异常边界与 `@Sendable` 闭包，见 ADR |

尚未完成的人工验收：

| 项目 | 状态 |
| --- | --- |
| `bash scripts/verify-helper-cutover.sh all` | 待人工执行。需要管理员授权，执行期间会短暂失去合盖保护 |
| M4 粘贴回填在原生 App、Electron、终端、安全输入框四类目标中的验证 | 待人工执行。自动化测试覆盖到「写回剪贴板」与「合成 ⌘V 的调用」，覆盖不到目标应用是否接受合成事件 |
| `README.md` 的 41 项真机验收清单 | 待人工执行。第 34 到 41 项是 M8 的 Hub 外壳 |
| `node .git/covio-figma/proto_status.mjs` 与 `verify_text.mjs` | 待人工执行。两个脚本要连本机 `127.0.0.1:3055` 的 Figma 桥。桥没开时连接被拒。本次视觉不变，预期结果是 42 reactions 与 1259 文字节点 |


## 11. 关键文件

| 文件 | 作用 |
| --- | --- |
| `app/src/com/wyz/covio/app/ui/AppRuntime.kt` | 892 行。状态编排的唯一大脑。Swift 侧 `HubStore` 的对照物与行为基线来源。M6 已删除 |
| `app/src/com/wyz/covio/app/platform/MacShelfNative.kt` | 232 行。JNA 加 AWT peer 反射加 `objc_msgSend`。迁移收益最集中的删除目标。M6 已删除 |
| `core/src/com/wyz/covio/Engine.kt` | 632 行。`synchronized` / `Thread` / `AtomicBoolean` 集中地。决定 KMP native 可行性的关键 |
| `core/src/com/wyz/covio/Ports.kt` | 73 行。9 个端口接口。Swift 侧 macOS 实现的契约 |
| `core/src/com/wyz/covio/ShelfLogic.kt` | 204 行。晾衣线几何。参数化后可复用于全宽面板与 Hub 内嵌 |
| `docs/covio-design-contract.schema.json` | `additionalProperties: false` 加 22 条数量锁加单值枚举。M5 全部约束的来源 |
| `/Users/wyz/repo/kmp-translator/iosApp/` | Amper 原生 app 的可照抄模板 |
| `/Users/wyz/repo/kmp-translator/shared/module.yaml` | SQLDelight 与多平台的 Amper 配置模板 |

## 12. 阶段进度

| 阶段 | 状态 | 完成日期 |
| --- | --- | --- |
| M0 Spike 与脚手架 | 已完成。结论见 `doc/adr/adr-0001-macos-ui-swiftui.md` | 2026-10-12 |
| M1 Notch Shell 骨架 | 已完成 | 2026-10-12 |
| M2 能力平迁 | 已完成。helper 割接脚本待人工执行 | 2026-10-12 |
| M3 截图模块与切换 | 已完成。版本切到 `0.5.0` | 2026-10-12 |
| M4 剪贴板模块 | 已完成。交付偏差见下节 | 2026-10-12 |
| M5 合同与文档同步 | 已完成。交付偏差见下节 | 2026-10-12 |
| M6 退役 Compose macOS 宿主 | 已完成。交付偏差见下节 | 2026-10-12 |
| M7 对齐共享层边界 | 已完成。结论见 `doc/adr/adr-0001-macos-ui-swiftui.md` 实测 26 到 28 | 2026-10-12 |
| M8 Hub 外壳按 macOS 27 版式重做 | 已完成。结论见同文件实测 31 到 33。真机清单未跑 | 2026-10-12 |

## 12.1 M8：Hub 外壳按 macOS 27 版式重做

用户要求设置界面按 macOS 27 的样子重写：左侧悬浮导航栏，顶部悬浮紧凑胶囊。范围是整个 Hub，不只是设置页。

### 版式

卡片从「横向页签栏加内容」改成两栏：

```
┌────────────────────────────────────────────┐
│ ╭──────────╮  ╭──────────────────────────╮ │
│ │ 搜索      │  │ 胶囊：页标题加页动作       │ │
│ ├──────────┤  ╰──────────────────────────╯ │
│ │ 六个页签  │  ╭──────────────────────────╮ │
│ ├──────────┤  │                          │ │
│ │ 呼吸灯    │  │ 页内容                    │ │
│ │ 设置      │  │                          │ │
│ │ 语言      │  ╰──────────────────────────╯ │
│ │ 退出      │                              │ │
│ ╰──────────╯                              │
└────────────────────────────────────────────┘
```

| 项 | 值 | 来源 |
| --- | --- | --- |
| 卡片宽 | 960 | M8 版式 |
| 导航栏 | 200 × 370 | 合同 `component/tab-bar` |
| 顶部胶囊 | 高 40 | 沿用合同 `component/toolbar` 的高度 |
| 内容列宽 | 712 | 卡片宽减两倍内边距减导航栏宽减栏间距 |
| 卡片圆角 | 沿用 `MacTheme.cardRadius` | 设计令牌 |

胶囊的内容按页签区分。设置页的胶囊只放六个分节切换，不放页标题：内容列 712 点放不下 420 点的标题加六个分节。其余页签放页标题加该页动作。页标题因此从页内容移到胶囊里。

### 新增与删除的文件

新增：

| 文件 | 职责 |
| --- | --- |
| `macosApp/src/Hub/HubNavRail.swift` | 左侧导航栏。搜索框、六个页签、底部组 |
| `macosApp/src/Hub/HubToolbarCapsule.swift` | 胶囊容器、胶囊标题、六个分节切换 |
| `macosApp/src/Hub/RuntimePulse.swift` | 底部呼吸灯 |
| `macosApp/src/Hub/HubChromeModel.swift` | 外壳的共享状态：搜索文字、设置分节、高亮行、滚动目标 |
| `macosApp/src/Hub/Settings/SettingsCatalog.swift` | 设置项目的目录表，搜索的唯一数据源 |
| `macosApp/src/Hub/Settings/SettingsSearchIndex.swift` | 纯函数搜索 |
| `macosApp/src/Hub/Settings/SettingsRowAnchor.swift` | 行的环境键与描边 |
| `macosApp/src/Hub/Settings/SettingsSearchResults.swift` | 结果浮层 |
| `macosApp/src/Hub/Settings/SettingsSection.swift` | 分节枚举 |
| `macosApp/src/Hub/Settings/SettingsShell.swift` | 设置页外壳 |
| `macosApp/src/Hub/Settings/SettingsFormat.swift` | 数值与状态的格式化 |
| `macosApp/src/Hub/Settings/SettingsRows.swift` | 复用行件 |
| `macosApp/src/Hub/Settings/pages/*.swift` | 六个分节页 |
| `macosApp/src/Design/GlassSurface.swift` | 玻璃的薄封装，带 `.glass` 与 `.material` 开关 |

删除：`HubTabBar.swift`、`SettingsTabView.swift`（731 行，按分节拆开）。

### 合同改动

组件总数保持 22。两个版式复用同一批组件记录：

| 合同键 | 改动 |
| --- | --- |
| `component/tab-bar` | `nativeSize` 改成 200×370；映射目标改成 `HubNavRail` |
| `component/page-title` | `nativeSize` 改成 420×40；映射目标改成 `HubCapsuleTitle` |

`platformMapping[key].swiftRuntimeTarget` 同步改。Figma 侧仍是旧尺寸，记进 `metadata.knownDifferences`。

新增文案键集中在 `copy/nav/` 段：搜索占位、搜索无结果、搜索结果、导航栏无障碍名、运行中、已暂停、退出。占位页提示语另加 `copy/hub/placeholder-notice`。每个键都有中英两份，`scripts/generate-contract-constants.py` 重新生成了 `ContractCopy.swift`。

### 部署目标

`MACOSX_DEPLOYMENT_TARGET` 从 `14.0` 改成 `26.0`。原因是 Liquid Glass 的三个 API 都要 26 以上。CI 的 Swift 作业从 `macos-15` 改成 `macos-26`。Kotlin 与合同校验两个作业不动。见 ADR 实测 31。

### 测试

新增纯类型套件：`HubMetricsTests`、`SettingsCatalogTests`、`SettingsSearchIndexTests`、`SettingsRowAnchorCoverageTests`。`ScreenshotsTabTests` 与 `ContractConstantsTests` 的高度加法按新公式改写。Swift 测试从 332 条增加到 375 条，全绿。375 这个数含并行工作流 M1 的 Files 页签与其测试。

`ScreenGeometryTests` 随后补了三条用例，把 CI 运行器的屏幕形状钉下来。`HubChromeModelTests` 与 `ShellPanelTests` 又补了八条，覆盖 Escape 的两段行为。Swift 测试因此是 386 条。见下条。

`SettingsRowAnchorCoverageTests` 是补漏后加的。它扫源码文本，核对每个锚点常量都挂在视图上。起因与自证见 ADR 实测 34。

### 首次 CI 的两个失败

推送后 `macOS SwiftUI` 作业失败两次。两次都不是本机能复现的缺陷，因为本机与运行器的环境不同。

| 次 | 失败步骤 | 根因 | 记录 |
| --- | --- | --- | --- |
| 1 | Build | 冷缓存下 `konanc` 找不到。发现排在了 Amper 解压之前 | ADR 实测 35 |
| 2 | Test | 11 条断言写死屏幕坐标。运行器是 1024 × 768 的无刘海屏 | ADR 实测 36 |

第三次全绿：三个作业 success，378 条测试，0 失败。见 ADR 实测 37。

`NotchShellControllerTests` 里有几条等异步状态的断言。原来用固定时长等，机器被别的编译占满时误报过三次。现在换成轮询，上限 3 秒。见 ADR 实测 39。

**警告：** 新外壳没有视图测试。XCTest 不构建 SwiftUI 视图。几何值、目录表、搜索索引与退出动作都写成纯类型并配了测试，其余靠真机清单。

## 13. 交付偏差

执行过程中有十二处与本文档原文不一致。以本节为准。

| 编号 | 原计划 | 实际 | 原因 |
| --- | --- | --- | --- |
| D1 | 剪贴板用 SQLDelight 加 `native-driver` | 用 `@Serializable` 加 okio，落盘方式与 `shelf.json` 一致 | Amper 0.12.1 没有 SQLDelight 插件。已核实 CLI 的 jar 里没有相关实现 |
| D2 | 复制 tendedero 源码进 `macosApp/src/Vendored/Tendedero/` | 未执行 | 外部源码未获授权进入仓库。截图挂帘按计划的行为描述重建 |
| D3 | 复制 dodoclip 源码进 `macosApp/src/Vendored/DodoClip/` | 未执行 | 同上。因此 `THIRD_PARTY_NOTICES.md` 不加 dodoclip 条目：没有复制任何文件，也没有据此实现 |
| D4 | 剪贴板监听用 `NSPasteboard` 变更通知 | 按 `NSPasteboard.changeCount` 轮询，间隔 0.5 秒 | AppKit 在 `NSPasteboard` 上没有通知、代理或 KVO，只有这个计数器 |
| D5 | `kmpDomain` 的 `metadata.kotlinInterfaces` 四个接口本次落地 | 已在 M5 落地 | M5 的合同改动。见 `kmpDomain/src/com/wyz/covio/core/DesignContract.kt` |
| D6 | 补 9 条动效参数 | 补了 10 条，多的 1 条是「指针移出后收起」 | `HubMotion` 里已有「指针移出后收起 500 毫秒」。不补进合同，这条数值就没有权威来源，测试也覆盖不到 |
| D7 | M3 交付「删除 `libCovioDrag.dylib` 与 JNA」 | 删了 `native/`，JNA 保留 | `HelperServer` 用 JNA 调 `getpeereid` 校验 Unix 域套接字的对端 UID。`libCovioDrag.dylib` 的那个用途已由 Swift 重写，JNA 的另一个用途还在 |
| D8 | M6「移除 `scripts/package-macos.sh` 的发布职责」 | 删除该脚本，另建 `scripts/package-macos-swift.sh` | `app` 的 `product` 已降为 `jvm/lib`，没有 main class，`jpackage` 那条链路无法执行。留一个跑不通的脚本比删掉更糟 |
| D9 | M6「保留 `app/test` 的 18 个测试文件」 | 保留 8 个，删除 10 个 | 10 个测试的被测对象都在 `platform/` 里。删除清单见 §7 的 M6 一节 |
| D10 | M8 的界面改动记在 `0.6.0` 名下 | 并入 `0.5.0` 的说明 | `0.5.0` 还没发布（见 §13.2），`APP_VERSION` 还是 `0.5.0`。另开一个版本号会描述一个不存在的版本 |
| D11 | M8 把三个 CI 作业都移到 `macos-26` | 只移 Swift 作业 | Kotlin 与合同校验两个作业不构建宿主应用，也不受部署目标影响。少依赖一个未确认的运行器标签 |
| D12 | M8 的胶囊在设置页放页标题加六个分节 | 设置页只放六个分节 | 内容列 712 点放不下 420 点的标题加六个分节。选中的分节本身就是标题 |

改键功能另有两处范围限定，需要写进合同与用户文档：

1. 界面给每个动作四个候选组合，不做自由录制。
2. 组合写法是 `shift+cmd+V` 这样的字符串，存在 `config.json` 的
   `clipboardPasteStackHotKey` 与 `clipboardCaptureHotKey`。只认字母与数字键。

### 13.1 M5 遗留的一处不一致（已解决）

**2026-10-12 结案。** 下面是原记录，留作历史。

> 界面文案有两个来源：合同 `copy` 段（生成到 `ContractCopy.swift`）与三个手写文件
> `HubCopy.swift`、`ShelfCopy.swift`、`ClipboardCopy.swift`。
> 后者的条目不带合同键，所以合同校验器覆盖不到它们。
>
> 计划原文没有要求合并这两处，本次也没有合并。
> 后果是：改这三处文案不会让任何测试失败，也不会和合同比对。
> 合同里已有的同名文案（例如 `copy/notch-hub/state/*`）与这三个文件里的写法可以漂移。

收口按原记录给出的下一步执行，共四步。

1. 删除 `macosApp/src/Design/HubCopy.swift`、`ShelfCopy.swift`、`ClipboardCopy.swift`。
2. 三个类型 `LocalizedCopy`、`AppLanguage`、`CopyLocale` 移到 `macosApp/src/Design/LocalizedCopy.swift`。这个文件只放类型，不放文案。
3. 调用点改用生成的 `ContractCopy`。
4. 缺口补进 `docs/covio-design-contract.json` 的 `copy` 段：剪贴板全部文案、六个 Hub 页签名与摘要、顶部晾衣线的标题与错误文案。这些键没有 Figma 节点，已记进 `metadata.knownDifferences` 的 `Native-only interface copy` 一条。

漂移现在有两道拦截：

- `macosApp/test/CopySingleSourceTests.swift` 扫 `macosApp/src/Design/*.swift`。生成文件与 `LocalizedCopy.swift` 之外出现 `LocalizedCopy(` 就失败。
- `scripts/validate-contract.py` 有同一条规则。没有 Xcode 的环境也能拦住漂移。

### 13.2 发布说明仍是 0.4.2

`RELEASE_NOTES.md` 描述的是 `0.4.2`：macOS 12、Compose 宿主、`Covio-0.4.2.dmg`。
`scripts/create-release.sh` 按 `APP_VERSION` 发布，现在读到的是 `0.5.0`。
所以直接执行发布流程会发一个 `v0.5.0` 的标签，配一份 `0.4.2` 的说明。

本次没有改写 `RELEASE_NOTES.md` 的正文：发布说明要写「已通过真机验收」，而 §10 的 41 项清单还没跑。
2026-10-12 补：头部警告已按 M8 更新，并列出 0.5.0 会改什么。正文仍是 `0.4.2` 的描述。
顺序应该是先跑完真机清单，再按结果改写发布说明。

2026-10-12 加了一条头部警告，指向本节。正文仍是 `0.4.2` 的描述。

