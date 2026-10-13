# iOS 免打开入口证据附录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 审计记录，可复核 |
| 日期 | `2026-10-13` |
| 主文 | [主题索引](README.md) |
| 验证目录 | [验证目录](validation/README.md) |
| 案例 | [Case 1](validation/case-ios-ambient-entry.md) |

本次调研的网页来源访问日期均为 `2026-10-13`。
来源等级按 [AUTHORING.md](../AUTHORING.md) 第 9 节。
A 是官方接口定义。
C 是官方项目文档、官方知识库和厂商文档。
D 是本机实验。
E 是第三方文章和社区讨论。

等级映射说明：
本主题把 Apple 接口参考页（含平台版本表与接口定义）记为 A。
本主题把 Apple 使用手册、支持文章、Human Interface Guidelines 和 WWDC 讲稿记为 C。
本主题没有 B 来源，因为仓库没有 iOS 工程目标。
本主题没有 E 来源，因为本次调研没有可用的网页搜索。

## 1. 问题类别和案例映射

| 项目 | 内容 |
| --- | --- |
| 问题类别 | 系统空间入口的开放边界 |
| 案例 | `Case 1`：iOS 免打开入口可用性 |
| 案例文件 | [validation/case-ios-ambient-entry.md](validation/case-ios-ambient-entry.md) |
| 覆盖测试 | `V01` 至 `V12` |

## 2. 来源等级

| 等级 | 来源 | 用途 | 置信度 |
| --- | --- | --- | --- |
| A | Apple 接口参考页，含平台版本表与接口定义 | 权威可用性与接口语义 | 高 |
| C | Apple 使用手册、支持文章、Human Interface Guidelines、WWDC 讲稿 | 产品能力与用户操作方式 | 中高 |
| D | 本机 macOS 27.0.1 与仓库快照 | 当前环境事实 | 高，范围小 |

高影响结论使用 A 或 C 来源。
只有 C 来源支撑的结论标记为中高置信度。
负向证据单独标注。

## 3. 环境事实

| 项目 | 值 | 命令 | 置信度 |
| --- | --- | --- | --- |
| 系统版本 | macOS 27.0.1，build `26A434` | `sw_vers` | 高 |
| 架构 | arm64 | `uname -m` | 高 |
| Xcode 版本 | 27.0，build `27A266a` | `xcodebuild -version` | 高 |
| 分支 | `feature/swiftui-macos` | `git branch --show-current` | 高 |
| commit | `f7d0453` | `git rev-parse --short HEAD` | 高 |
| 顶层模块 | `app`、`kmpDomain`、`macosApp` | `ls` | 高 |
| iOS 工程目标 | 不存在 | `ls` | 高 |
| iOS 真机 | 没有 | 人工确认 | 高 |

### 3.1 复现命令

```sh
sw_vers
uname -m
xcodebuild -version
git rev-parse --short HEAD
git branch --show-current
ls
```

读取 Apple 接口参考页：

```sh
curl -sS -H 'User-Agent: Mozilla/5.0' \
  'https://developer.apple.com/tutorials/data/documentation/widgetkit/controlwidget.json' \
  -o controlwidget.json
```

读取 WWDC 讲稿页：

```sh
curl -sSL -H 'User-Agent: Mozilla/5.0' \
  'https://developer.apple.com/videos/play/wwdc2024/10157/' \
  -o wwdc2024-10157.html
```

检索 Apple 支持文章：

```sh
curl -sSL -H 'User-Agent: Mozilla/5.0' \
  'https://support.apple.com/kb/index?page=search&q=back%20tap&locale=en_US' \
  -o support-search.html
```

### 3.2 环境结论

结论适用于 Apple 在 `2026-10-13` 发布的文档。
接口参考页的 JSON 数据接口是文档站内部接口，不是公开契约。
使用手册的正文由浏览器脚本渲染，命令行读取只得到搜索摘要。
WWDC 讲稿页为服务端渲染，命令行可以读取正文。

## 4. 证据索引

| 编号 | 主题 | 来源 | 结论 | 置信度 |
| --- | --- | --- | --- | --- |
| E-01 | 调研环境与仓库范围 | D | 仓库只有 macOS 目标，没有 iOS 目标 | 高 |
| E-02 | 主屏与锁屏手势无注册接口 | A/C | 负向证据，未找到任何注册入口 | 中高 |
| E-03 | App Intents 的系统集成面清单 | A | 清单不含手势入口 | 高 |
| E-04 | WidgetKit 的放置位置清单 | A | 位置清单不含主屏手势 | 高 |
| E-05 | 主屏图标快速操作 | A/C | 主屏唯一第三方交互面，最多 4 个 | 高 |
| E-06 | 系统手势属于系统行为 | C | 应用不得与系统手势冲突 | 中高 |
| E-07 | ControlWidget 的平台门槛 | A | iOS 18.0 及以上 | 高 |
| E-08 | ControlWidgetButton 的语义 | A | 无状态，用于执行动作或启动应用 | 高 |
| E-09 | ControlWidgetToggle 与 SetValueIntent | A | 开关控件用 SetValueIntent | 高 |
| E-10 | 控件可打开应用并进入指定位置 | A | 用实现 OpenIntent 的意图 | 高 |
| E-11 | 意图的 Target Membership 要求 | A | 必须同时属于主应用与扩展 | 高 |
| E-12 | 控件与小组件的执行进程 | A | 由 Widget 扩展进程执行 | 高 |
| E-13 | 控件需要用户手动添加 | C | 用户从图库添加 | 中高 |
| E-14 | 控件可要求设备认证 | C | 可遮蔽标题与状态 | 中高 |
| E-15 | 交互小组件的版本门槛 | A | iOS 17.0 及以上 | 高 |
| E-16 | 支持交互的小组件尺寸 | A | 六个尺寸，含两个 accessory 尺寸 | 高 |
| E-17 | 小组件只支持 Button 和 Toggle | C | 其他控件不生效 | 中高 |
| E-18 | 锁定设备上交互不生效 | A | 需认证并解锁 | 高 |
| E-19 | 小组件点击打开应用 | A | widgetURL、Link 或 NSUserActivity | 高 |
| E-20 | 交互必定重载时间线 | A | 交互触发的重载有保证 | 高 |
| E-21 | 轻点背面的版本与机型门槛 | C | iOS 14 起，iPhone 8 及以后 | 中高 |
| E-22 | 轻点背面可绑定快捷指令 | C | 动作列表含快捷指令 | 中高 |
| E-23 | 轻点背面延迟无官方数据 | C | 负向证据，未找到延迟数据 | 中 |
| E-24 | Action Button 的机型范围 | C | iPhone 15 Pro 及以后 | 中高 |
| E-25 | Action Button 需要长按 | C | 按下时显示提示 | 中高 |
| E-26 | Action Button 可运行 App Shortcut | A/C | 也可放置控件 | 高 |
| E-27 | App Intent 与 App Shortcuts 的接入方式 | A | 声明式，安装后自动可用 | 高 |
| E-28 | App Intent 的前台与后台模式 | A | openAppWhenRun 与 supportedModes | 高 |
| E-29 | OpenIntent 的语义与版本 | A | iOS 16.0 起，自动进入前台 | 高 |
| E-30 | presentationDetents 的语义与版本 | A | iOS 16.0 起，默认只有 large | 高 |
| E-31 | 快捷指令可添加到主屏 | C | 由 Shortcuts 应用提供 | 中高 |
| E-32 | 锁屏小组件的尺寸家族 | A | accessoryCircular、accessoryRectangular、accessoryInline | 高 |
| E-33 | 系统空间的自定义入口 | C | 控制中心与锁屏由用户自定义 | 中高 |
| E-34 | 控件可放到 Action Button | C | 用户长按触发 | 中高 |

## 5. 证据详情

### E-01：调研环境与仓库范围

来源等级：D
环境：仓库快照，分支 `feature/swiftui-macos`，commit `f7d0453`；本机 macOS 27.0.1
命令或来源：`sw_vers`、`uname -m`、`xcodebuild -version`、`git rev-parse --short HEAD`、`ls`
关键输出：

```text
ProductName:      macOS
ProductVersion:   27.0.1
BuildVersion:     26A434
arm64
Xcode 27.0
Build version 27A266a
f7d0453
app  assets  build  dist  docs  kmpDomain  libs.versions.toml  macosApp  project.yaml  scripts
```

观察：本机是 Apple Silicon Mac，系统为 macOS 27.0.1。
观察：仓库顶层模块是 `app`、`kmpDomain`、`macosApp`。
观察：仓库没有 iOS 工程目标，没有 Widget 扩展目标。
推论：本调研没有 iOS 编译级验证，也没有真机验证。
推论：本主题没有 B 来源。
反证：无。
限制：单机、单版本、单用户。
置信度：高
关联：E-02、E-03

### E-02：主屏与锁屏手势无第三方注册接口

来源等级：A/C
环境：Apple 接口参考页与设计指南，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/appintents`、`https://developer.apple.com/documentation/widgetkit`、`https://developer.apple.com/design/human-interface-guidelines/gestures`
关键输出：

```text
App Intents 概述列出的系统面：Siri、Spotlight、Shortcuts、Apple Pencil、Action button、Widgets、Controls、Live Activities、Focus
WidgetKit 概述：Extend the reach of your app by creating widgets, watch complications, Live Activities, and controls.
HIG Gestures：Avoid conflicting with gestures that access system UI.
```

观察：App Intents 概述列出系统能调用应用动作的全部系统面。
观察：该清单不含主屏手势、锁屏手势和边缘手势。
观察：WidgetKit 概述列出的产物只有小组件、表盘复杂功能、实时活动和控件。
观察：设计指南要求应用避免与访问系统 UI 的手势冲突。
推论：iOS 没有公开 API 让第三方应用在主屏、锁屏或屏幕边缘注册手势入口。
推论：产品需求“主屏上滑带出 bottom sheet”没有对应的系统能力。
反证：这是负向证据，不是 Apple 的官方否认。
反证：未检索全部 Apple 文档，也未检索 iOS SDK 符号表。
限制：本结论只覆盖 `2026-10-13` 可检索到的 Apple 公开文档。
置信度：中高
关联：E-03、E-04、E-05、E-06、V01

### E-03：App Intents 的系统集成面清单

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/appintents`
关键输出：

```text
People can interact with your app's content through Siri.
Spotlight helps people navigate to your data directly from search results.
The Shortcuts app helps people configure workflows that include your app's actions.
People can configure Apple Pencil or the Action button on iPhone to perform your app's actions when pressed.
Widgets, controls, and Live Activities can use your app's actions to perform relevant tasks.
You can define custom Focus modes, and respond to Focus changes.
```

观察：Apple 列出 App Intent 的全部系统接入面。
观察：清单含 Siri、Spotlight、Shortcuts、Apple Pencil、Action button、Widgets、Controls、Live Activities 和 Focus。
观察：清单不含任何主屏或锁屏手势。
推论：App Intent 是第三方应用动作进入系统空间的统一通道。
推论：系统空间入口的候选集合由该清单决定。
限制：清单随系统版本变化。
置信度：高
关联：E-02、E-27、E-29

### E-04：WidgetKit 的放置位置清单

来源等级：A
环境：Apple 接口参考页与设计指南，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/widgetkit`、`https://developer.apple.com/design/human-interface-guidelines/widgets`
关键输出：

```text
System small: Home Screen, Today View, StandBy, and CarPlay
Accessory circular / accessory inline / accessory rectangular: Lock Screen
Controls: Control Center, the Lock Screen, and the Action button
On Mac: desktop and Notification Center
```

观察：小组件与控件可以出现的位置有明确清单。
观察：清单含主屏、Today View、StandBy、CarPlay、锁屏、控制中心、Action Button、桌面、通知中心和 Smart Stack。
观察：清单不含“主屏手势”。
推论：第三方应用在主屏的可见面是图标、小组件和快捷指令书签。
推论：主屏手势不在 WidgetKit 的能力范围内。
限制：清单随系统版本变化。
置信度：高
关联：E-02、E-07、E-32

### E-05：主屏图标快速操作

来源等级：A/C
环境：Apple 接口参考页与设计指南，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/design/human-interface-guidelines/home-screen-quick-actions`、`https://developer.apple.com/documentation/uikit/uiapplicationshortcutitem`
关键输出：

```text
People can get a menu of available quick actions when they touch and hold an app icon.
People tend to expect every app to provide at least one useful quick action; you can provide a total of four.
```

观察：主屏图标长按会显示快速操作菜单。
观察：每个应用最多提供四个快速操作。
观察：快速操作由 `UIApplicationShortcutItem` 提供。
推论：这是主屏上唯一的第三方交互面。
推论：快速操作会打开应用，不是免打开入口。
推论：快速操作可以作为工作区的第二个主屏入口。
限制：未验证快速操作与 App Intent 的绑定细节。
置信度：高
关联：E-02、E-04、E-31

### E-06：系统手势属于系统行为

来源等级：C
环境：Apple 设计指南，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/design/human-interface-guidelines/gestures`
关键输出：

```text
Avoid conflicting with gestures that access system UI. Several platforms offer gestures for accessing system behaviors... It's important to avoid defining custom gestures that might conflict with these interactions, as people expect these controls to work consistently.
```

观察：设计指南把访问系统 UI 的手势定义为系统行为。
观察：指南要求应用不要定义与这些手势冲突的自定义手势。
推论：屏幕边缘和主屏手势保留给系统。
推论：第三方应用不应把边缘手势作为入口。
限制：设计指南不是接口定义，不构成硬约束。
置信度：中高
关联：E-02

### E-07：ControlWidget 的平台门槛

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/swiftui/controlwidget`、`https://developer.apple.com/documentation/widgetkit/controls-collection`
关键输出：

```text
iOS 18.0、iPadOS 18.0、Mac Catalyst 18.0、macOS 26.0、watchOS 26.0
The configuration and content of a control widget to display in system spaces such as Control Center, the Lock Screen, and the Action Button.
Controls act as a button that initiates an action from your app or opens your app to a specific view, or as a toggle.
```

观察：`ControlWidget` 自 iOS 18.0 起可用。
观察：控件出现在控制中心、锁屏和 Action Button。
观察：控件可以是按钮或开关。
推论：控制中心控件是 iOS 18 及以上设备的新入口。
推论：iOS 17 及以下设备不能使用控件。
限制：未验证 iPadOS 上的控件位置差异。
置信度：高
关联：E-08、E-09、E-10、E-13

### E-08：ControlWidgetButton 的语义

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/widgetkit/controlwidgetbutton`
关键输出：

```text
iOS 18.0 及以上
Buttons don't have state; use them for fire-and-forget actions such as playing a sound or launching an app.
```

观察：`ControlWidgetButton` 无状态。
观察：Apple 建议把它用于一次性动作或启动应用。
推论：按钮控件适合“打开工作区”这类动作。
推论：需要状态反馈的动作应改用 `ControlWidgetToggle`。
限制：未验证按钮控件在长动作下的表现。
置信度：高
关联：E-07、E-09、E-10

### E-09：ControlWidgetToggle 与 SetValueIntent

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system`、`https://developer.apple.com/documentation/appintents/setvalueintent`
关键输出：

```text
Use AppIntent or OpenIntent for control buttons and SetValueIntent for control toggles.
The system populates the value parameter of a SetValueIntent with the value that reflects the new state of the control toggle.
```

观察：控件按钮用 `AppIntent` 或 `OpenIntent`。
观察：控件开关用 `SetValueIntent`。
观察：系统填充 `SetValueIntent` 的 `value` 参数。
推论：开关控件的状态由系统与共享容器共同决定。
推论：应用不应自行管理 `value` 参数。
限制：未验证开关控件在快速连续触发下的行为。
置信度：高
关联：E-07、E-08、E-12

### E-10：控件可打开应用并进入指定位置

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system`、`https://developer.apple.com/documentation/appintents/openintent`
关键输出：

```text
Set your control's action to an app intent that conforms to OpenIntent to open your app when someone uses a control.
Using OpenIntent allows you to take someone to a specific area of your app when a control performs its action.
The system requires the Target Membership of the app intent to be set to both the app and the widget extension to open the app.
OpenIntent 自 iOS 16.0 起可用。
The system automatically brings your app to the foreground to run this app intent.
```

观察：控件按钮可以绑定实现 `OpenIntent` 的 App Intent。
观察：`OpenIntent` 的 `target` 参数用于指定要显示的条目。
观察：系统会自动把应用带到前台。
推论：控件是唯一能“一键打开应用并进入指定工作区”的入口。
推论：工作区通过 `target` 参数传递。
限制：未验证 `target` 支持的类型范围。
置信度：高
关联：E-07、E-11、E-29、V07

### E-11：意图的 Target Membership 要求

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system`
关键输出：

```text
The system requires the Target Membership of the app intent to be set to both the app and the widget extension to open the app.
If you adopt the AppIntent protocol, add your custom app intent to your widget extension target and your app target.
```

观察：控件用的 App Intent 必须同时属于主应用目标和 Widget 扩展目标。
观察：小组件用的 App Intent 也有相同要求。
推论：接入成本包含一份扩展目标的配置。
推论：共享逻辑应放在共享包中，避免重复实现。
限制：未验证在 Swift Package 中定义意图时的目标归属细节。
置信度：高
关联：E-10、E-12、E-27

### E-12：控件与小组件的执行进程

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities`、`https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system`
关键输出：

```text
By default, the system runs the app intent in the same process as the widget extension.
The system loads a control when someone adds it to a system space from the controls gallery.
When someone interacts with a control, it performs its action using an app intent you specify.
The system queries for the state of a control when perform() returns.
```

观察：小组件与控件的 App Intent 默认在 Widget 扩展进程中执行。
观察：控件在用户从图库添加时由系统加载。
观察：系统在 `perform()` 返回后查询控件状态。
推论：入口不要求主应用进程正在运行。
推论：所有系统空间入口都支持冷启动。
推论：`perform()` 返回前必须写完状态。
限制：未验证扩展进程被系统终止时的重试行为。
置信度：高
关联：E-10、E-11、E-20、V02、V06

### E-13：控件需要用户手动添加

来源等级：C
环境：Apple 设计指南，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/design/human-interface-guidelines/controls`
关键输出：

```text
People can add controls to Control Center by pressing and holding in an empty area of Control Center, to the Lock Screen by customizing their Lock Screen, and to the Action button by configuring the Action button in the Settings app.
```

观察：控件不会自动出现在系统空间。
观察：用户必须从图库把控件拖到控制中心、锁屏或 Action Button。
观察：控件在添加时可以选择配置。
推论：入口的首次可用性依赖一次用户操作。
推论：产品需要提供添加引导。
限制：未验证引导跳转到图库的可行方式。
置信度：中高
关联：E-07、E-33、E-34

### E-14：控件可要求设备认证

来源等级：C
环境：Apple 设计指南，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/design/human-interface-guidelines/controls`
关键输出：

```text
For added privacy, require device authentication before a control performs its action, as well as redact the text in a control when the device is locked.
Hide sensitive information when the device is locked.
```

观察：控件可以声明在动作前要求设备认证。
观察：控件可以在锁定状态下遮蔽标题与值。
推论：锁定状态下的控件行为由应用声明。
推论：有副作用的动作应在锁定状态下要求认证。
限制：未读到控件在锁定设备上执行语义的接口定义。
置信度：中高
关联：E-13、E-18

### E-15：交互小组件的版本门槛

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/swiftui/button/init(_:intent:)-7urde`、`https://developer.apple.com/videos/play/wwdc2023/10028/`
关键输出：

```text
SwiftUI Button 的 init(_:intent:) 自 iOS 17.0 起可用。
WWDC23 场次 10028：Interactivity allows your user to directly manipulate the data in your widget... you can use controls that you are already familiar with, like Button and Toggle, to make part of your widget interactive.
```

观察：接收 App Intent 的 `Button` 初始化器自 iOS 17.0 起可用。
观察：Apple 在 WWDC23 发布小组件交互能力。
观察：交互在 iOS 17 引入，不在 iOS 16。
推论：主屏交互小组件要求 iOS 17 及以上。
推论：iOS 16 及以下设备只能使用点击打开应用的入口。
限制：未在真机验证 iOS 17 与更高版本的行为差异。
置信度：高
关联：E-16、E-17、E-18

### E-16：支持交互的小组件尺寸

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities`、`https://developer.apple.com/documentation/widgetkit/widgetfamily`
关键输出：

```text
Widgets of the following sizes can include buttons and toggles: systemSmall、systemMedium、systemLarge、systemExtraLarge、systemExtraLargePortrait、accessoryCircular on iPhone and iPad、accessoryRectangular on iPhone and iPad
Live Activities can include buttons or toggles in the expanded and the Lock Screen presentation.
```

观察：支持交互的尺寸有五个系统尺寸和两个 accessory 尺寸。
观察：`accessoryCircular` 和 `accessoryRectangular` 在 iPhone 和 iPad 上支持交互。
观察：`accessoryInline` 不在支持清单中。
推论：主屏和锁屏都可以放交互小组件。
推论：锁屏上的交互面是圆形和矩形两种 accessory 尺寸。
限制：未验证 iPad 锁屏上的实际表现。
置信度：高
关联：E-15、E-17、E-18、E-32

### E-17：小组件只支持 Button 和 Toggle

来源等级：C
环境：Apple WWDC 讲稿，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/videos/play/wwdc2023/10028/`
关键输出：

```text
Note that only Button and Toggle using AppIntent are supported in interactive widgets. Other controls won't work.
```

观察：小组件中的交互控件只有 `Button` 和 `Toggle`。
观察：两者都必须使用接收 App Intent 的初始化器。
观察：其他 SwiftUI 控件在小组件中不生效。
推论：小组件不能承载任意 SwiftUI 交互。
推论：小组件上的“上滑”手势不可用，因为手势视图不是受支持的交互控件。
限制：讲稿为 `2023` 年内容，后续版本可能扩展。
置信度：中高
关联：E-15、E-16、E-30

### E-18：锁定设备上交互不生效

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities`
关键输出：

```text
On a locked device, buttons and toggles are inactive and the system doesn't perform actions unless a person authenticates and unlocks their device.
```

观察：锁定设备上小组件的按钮和开关不执行动作。
观察：系统要求用户认证并解锁后才执行。
推论：锁屏入口在锁定状态下不可用于免打开动作。
推论：锁屏入口的实际价值是“解锁后少走一步”。
限制：未在真机验证认证流程的具体表现。
置信度：高
关联：E-14、E-16、V04、V05

### E-19：小组件点击打开应用

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/widgetkit/linking-to-specific-app-scenes-from-your-widget-or-live-activity`
关键输出：

```text
By default, tapping or clicking your widget or Live Activity opens its corresponding app.
To open a specific screen in your app, add the widgetURL(_:) modifier to a view in the view hierarchy of your widget.
For widgets with enough space for more than one interaction target — accessoryRectangular, systemSmall, and larger system family sizes — add one or more Link controls.
```

观察：点按小组件非交互区域会打开应用。
观察：用 `widgetURL(_:)` 指定要打开的界面。
观察：空间足够时可以用多个 `Link` 控件分别指定目标。
推论：小组件同时提供“免打开执行动作”和“打开应用并定位”两条路径。
推论：一个 `widgetURL` 加多个 `Link` 是标准组合。
限制：视图层级中有多个 `widgetURL` 时行为未定义。
置信度：高
关联：E-10、E-20、V03

### E-20：交互必定重载时间线

来源等级：A
环境：Apple 接口参考页与 WWDC 讲稿，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities`、`https://developer.apple.com/videos/play/wwdc2023/10028/`
关键输出：

```text
Interactions with a toggle or button always guarantee a timeline reload.
Make sure any code that's necessary for the timeline update runs before you return from perform().
```

观察：按钮或开关的交互一定触发时间线重载。
观察：重载发生在 `perform()` 返回之后。
观察：Apple 要求状态写入在返回前完成。
推论：入口的状态一致性依赖 `perform()` 的写入顺序。
推论：界面更新会有一次往返延迟。
限制：未验证 iPhone 小组件在 Mac 上的额外延迟。
置信度：高
关联：E-12、E-19

### E-21：轻点背面的版本与机型门槛

来源等级：C
环境：Apple 支持文章 `111772`，发布日期 `2023-12-27`，访问日期 `2026-10-13`
命令或来源：`https://support.apple.com/en-us/111772`
关键输出：

```text
With Back Tap in iOS 14 or later, a quick double or triple tap on the back of your iPhone can open Control Center, take a screenshot, trigger accessibility-specific actions, and more.
Check that you have the latest version of iOS on your iPhone 8 or later. Go to Settings > Accessibility > Touch, and tap Back Tap.
Tap Double Tap or Triple Tap and choose an action.
```

观察：轻点背面自 iOS 14 起可用。
观察：要求 iPhone 8 或更新机型。
观察：设置路径是设置 > 辅助功能 > 触控 > 轻点背面。
观察：可选双击或三击，各绑定一个动作。
推论：轻点背面是版本门槛最低的候选入口。
推论：动作数量上限是两个。
限制：未验证机壳厚度对识别率的影响。
置信度：中高
关联：E-22、E-23、V11

### E-22：轻点背面可绑定快捷指令

来源等级：C
环境：Apple 支持文章与 Apple 支持检索，访问日期 `2026-10-13`
命令或来源：`https://support.apple.com/en-us/111772`、`https://support.apple.com/guide/shortcuts/run-shortcuts-tapping-iphone-apd897693606/ios`
关键输出：

```text
You can even set a double or triple tap to trigger an Accessibility Shortcut to quickly access features like AssistiveTouch, Siri Shortcuts, Magnifier, Reachability, and VoiceOver.
Apple 支持检索结果摘要：You can run a shortcut using the Back Tap Accessibility action on your phone.
```

观察：轻点背面的动作列表包含快捷指令。
观察：Apple 的 Shortcuts 使用手册有一节专门说明用轻点背面运行快捷指令。
观察：该使用手册页由浏览器脚本渲染，命令行只读到检索摘要。
推论：轻点背面可以触发 App Intent，因为快捷指令可以调用 App Intent。
推论：轻点背面与 Action Button 共用同一套 App Shortcut。
限制：使用手册正文未逐句核对。
置信度：中高
关联：E-21、E-26、E-27、V11

### E-23：轻点背面延迟无官方数据

来源等级：C
环境：Apple 支持文章与设计指南，访问日期 `2026-10-13`
命令或来源：`https://support.apple.com/en-us/111772`、`https://developer.apple.com/design/human-interface-guidelines/gestures`
关键输出：

```text
支持文章只说明“a quick double or triple tap”，没有给出识别延迟或执行延迟数值。
设计指南没有给出辅助功能手势的延迟指标。
```

观察：Apple 没有公开轻点背面的延迟数据。
观察：支持文章没有给出触发成功率或误触率。
推论：延迟只能通过真机实测得到。
推论：本次调研不能给出延迟结论。
反证：无，因为这是负向证据。
限制：本次调研没有可用的网页搜索，未纳入第三方实测数据。
置信度：中
关联：E-21、E-22、V11

### E-24：Action Button 的机型范围

来源等级：C
环境：Apple 支持文章 `105103`，发布日期 `2026-04-01`，访问日期 `2026-10-13`
命令或来源：`https://support.apple.com/en-us/105103`、`https://developer.apple.com/design/human-interface-guidelines/action-button`
关键输出：

```text
3: Action button: You can choose what you want this button to do, including opening the Camera app or turning on the flashlight. By default, the Action button turns Silent mode on or off.
With the Action button on iPhone 17e, iPhone 16e, and iPhone 15 Pro models...
HIG Action button: On a supported device, people can use the Action button to run App Shortcuts or access system-provided functionality.
HIG: Not supported in iPadOS, macOS, tvOS, or visionOS.
```

观察：Action Button 存在于 iPhone 15 Pro 及以后的支持机型。
观察：支持文章列举 iPhone 17e、iPhone 16e 和 iPhone 15 Pro 系列。
观察：iPadOS 不支持 Action Button。
推论：Action Button 入口的覆盖面小于小组件和控件。
推论：产品需要为不支持该按钮的机型提供其他入口。
限制：未核对该支持文章是否覆盖全部新机型。
置信度：中高
关联：E-25、E-26、E-34、V09

### E-25：Action Button 需要长按

来源等级：C
环境：Apple 设计指南与 WWDC 讲稿，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/design/human-interface-guidelines/action-button`、`https://developer.apple.com/videos/play/wwdc2024/10157/`
关键输出：

```text
When someone presses the Action button, the system displays hint text to help them understand what happens when they press and hold.
When someone presses and holds the Action button, the system performs the action configured to it.
WWDC24：the system synthesized "Hold to Turn On" and "Hold to Turn Off" action hints
```

观察：Action Button 的动作由长按触发。
观察：按下时系统显示动作提示文字。
观察：提示文字可以自定义。
推论：Action Button 不是单击入口，触发成本高于点按。
推论：提示文字需要写清楚动作结果。
限制：未验证长按的判定时长。
置信度：中高
关联：E-24、E-26、V10

### E-26：Action Button 可运行 App Shortcut

来源等级：A/C
环境：Apple 接口参考页与设计指南，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/appintents/hardware-interactions`、`https://developer.apple.com/design/human-interface-guidelines/action-button`、`https://support.apple.com/guide/shortcuts/run-shortcuts-with-the-action-button-apdfea15680b/ios`
关键输出：

```text
On supported iPhone models, people can run custom actions quickly using the Action button. This button is configurable in Settings, so people can assign any App Shortcuts you create to quickly access your app's features.
HIG: You don't need to offer an App Shortcut that opens your app, because the system provides this function already.
```

观察：用户可以把 Action Button 绑定到一个 App Shortcut。
观察：系统已经提供“打开应用”这一默认功能。
观察：Apple 的 Shortcuts 使用手册有一节说明用 Action Button 运行快捷指令。
推论：Action Button 可以触发应用意图。
推论：产品不需要为“打开应用”单独做一个快捷指令。
限制：使用手册正文未逐句核对。
置信度：高
关联：E-24、E-25、E-27、V09

### E-27：App Intent 与 App Shortcuts 的接入方式

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/appintents/appintent`、`https://developer.apple.com/documentation/appintents/app-shortcuts`
关键输出：

```text
Implement this protocol in a new type or existing type in your app, app extension, framework, or Swift package.
In your type, use the perform() method to perform the action and return a result back to the system.
You create App Shortcuts programmatically in your code, and the compiler generates the information the rest of the system needs to use it.
This approach means that the shortcuts you create are available as soon as someone installs your app, and you don't have to register them yourself.
Specify your shortcuts in your code by defining a custom type that adopts the AppShortcutsProvider protocol.
```

观察：一个动作只需要一个实现 `AppIntent` 协议的类型。
观察：输入用 `@Parameter` 声明，动作写在 `perform()` 中。
观察：`AppShortcutsProvider` 用静态数据声明快捷指令。
观察：编译器生成元数据，用户安装应用后快捷指令立即可用。
观察：不需要手动登记。
推论：接入成本主要是一次性定义，后续入口复用同一套意图。
推论：小组件、控件、Shortcuts 和 Action Button 可以共用一份实现。
限制：未估算实际编码工作量。
置信度：高
关联：E-03、E-11、E-22、E-26、E-28、V09

### E-28：App Intent 的前台与后台模式

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/appintents/appintent/supportedmodes`、`https://developer.apple.com/documentation/appintents/appintent/openappwhenrun`
关键输出：

```text
supportedModes 自 iOS 26.0 起可用。
Specify background to run the action entirely in the background. Specify the immediate foreground mode to bring the app to the foreground before the action runs.
openAppWhenRun 自 iOS 16.0 起可用，自 iOS 26.0 起废弃。This property is deprecated. Use supportedModes instead.
```

观察：前台与后台行为由 `openAppWhenRun` 或 `supportedModes` 声明。
观察：`openAppWhenRun` 在 iOS 26.0 起废弃。
观察：`supportedModes` 自 iOS 26.0 起可用，取值含后台、立即前台、动态前台和延迟前台。
推论：同一个动作可以选择后台执行或进入前台。
推论：产品需要决定每个动作的模式。
限制：未验证 iOS 26 之前用 `supportedModes` 的兼容写法。
置信度：高
关联：E-27、E-29、V02、V07

### E-29：OpenIntent 的语义与版本

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/appintents/openintent`
关键输出：

```text
iOS 16.0 及以上
Use this protocol to create an app intent that opens the app and displays a specific item.
The target property contains the item to display and is typically an AppEntity or AppEnum type you define.
The system automatically brings your app to the foreground to run this app intent.
If your app intent adopts the TargetContentProvidingIntent or UISceneAppIntent protocol, the system also directs the app intent to one of your app's scenes first.
```

观察：`OpenIntent` 用于打开应用并显示指定条目。
观察：目标用 `target` 属性表达，类型通常是 `AppEntity` 或 `AppEnum`。
观察：系统自动把应用带到前台。
观察：系统可以先把请求路由到一个场景。
推论：工作区可以用 `AppEnum` 表达，并通过 `target` 传递。
推论：控件、小组件和快捷指令都可以复用同一个 `OpenIntent`。
限制：未验证 `target` 与场景路由的组合细节。
置信度：高
关联：E-10、E-27、E-28、V07

### E-30：presentationDetents 的语义与版本

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:)`
关键输出：

```text
iOS 16.0 及以上
A set of supported detents for the sheet. If you provide more that one detent, people can drag the sheet to resize it.
By default, sheets support the large detent.
```

观察：`presentationDetents` 自 iOS 16.0 起可用。
观察：默认只有一个 `large` detent。
观察：提供多个 detent 时用户可以拖动改变高度。
推论：应用内可以实现“从底部上滑带出面板”的手感。
推论：该手感只在应用已在前台并呈现 sheet 时可用。
推论：它不是免打开入口。
限制：未评估与系统边缘返回手势的冲突。
置信度：高
关联：E-17、V12

### E-31：快捷指令可添加到主屏

来源等级：C
环境：Apple 支持检索与 Shortcuts 使用手册，访问日期 `2026-10-13`
命令或来源：`https://support.apple.com/guide/shortcuts/add-a-shortcut-to-the-home-screen-apd735880972/ios`
关键输出：

```text
Apple 支持检索结果摘要：Add a shortcut to the Home Screen on iPhone or iPad — You can add shortcuts to the Home Screen.
```

观察：Shortcuts 应用允许把快捷指令添加到主屏。
观察：添加后主屏出现一个可点按的图标。
观察：该使用手册页由浏览器脚本渲染，命令行只读到检索摘要。
推论：主屏可以有第二类第三方入口。
推论：该入口会执行快捷指令，可以触发 App Intent。
限制：使用手册正文未逐句核对。
置信度：中高
关联：E-05、E-27、V09

### E-32：锁屏小组件的尺寸家族

来源等级：A
环境：Apple 接口参考页，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/documentation/widgetkit/widgetfamily`、`https://developer.apple.com/design/human-interface-guidelines/widgets`
关键输出：

```text
Accessory families: accessoryCircular、accessoryCorner、accessoryRectangular、accessoryInline
HIG：Accessory circular — iPhone 与 iPad 的 Lock Screen；Accessory rectangular — iPhone 与 iPad 的 Lock Screen；Accessory inline — iPhone 与 iPad 的 Lock Screen
```

观察：锁屏小组件使用 accessory 家族。
观察：iPhone 和 iPad 的锁屏支持圆形、矩形和内联三种 accessory 尺寸。
观察：`accessoryCorner` 只用于 Apple Watch。
推论：锁屏的交互入口是圆形和矩形两种尺寸。
推论：内联尺寸不支持交互。
限制：未验证 iPad 锁屏小组件的交互表现。
置信度：高
关联：E-16、E-18、V04

### E-33：系统空间的自定义入口

来源等级：C
环境：Apple 使用手册，访问日期 `2026-10-13`
命令或来源：`https://support.apple.com/guide/iphone/use-and-customize-control-center-iph59095ec58/ios`、`https://support.apple.com/guide/iphone/create-a-custom-lock-screen-iph4d0e6c351/ios`
关键输出：

```text
Apple 支持检索结果摘要：Use and customize Control Center on iPhone — You can customize Control Center by adding controls.
Apple 支持检索结果摘要：Create a custom iPhone Lock Screen — Make your iPhone Lock Screen more personal and helpful by adding a picture, widgets, and colors.
```

观察：控制中心由用户自定义。
观察：锁屏由用户自定义，可以添加小组件。
观察：两处使用手册页由浏览器脚本渲染，命令行只读到检索摘要。
推论：控制中心和锁屏上的入口都需要一次用户添加。
推论：产品需要提供添加引导。
限制：使用手册正文未逐句核对。
置信度：中高
关联：E-13、E-07、E-34

### E-34：控件可放到 Action Button

来源等级：C
环境：Apple 设计指南与 WWDC 讲稿，访问日期 `2026-10-13`
命令或来源：`https://developer.apple.com/design/human-interface-guidelines/controls`、`https://developer.apple.com/videos/play/wwdc2024/10157/`
关键输出：

```text
People can add controls ... to the Action button by configuring the Action button in the Settings app.
On iPhone devices with a control assigned to the Action button, pressing and holding it displays the control's symbol in the Dynamic Island, as well as its value (if present).
```

观察：控件可以放到 Action Button。
观察：长按时系统在灵动岛显示控件的符号和值。
观察：同一份控件代码可以出现在控制中心、锁屏和 Action Button。
推论：Action Button 入口可以复用控件实现。
推论：Action Button 与控件可以一起交付。
限制：未验证灵动岛在无灵动岛机型上的替代显示方式。
置信度：中高
关联：E-07、E-13、E-24、E-25、V10

## 6. 逻辑证据链

```text
研究问题：主屏上滑手势能否带出 bottom sheet
  -> 来源：E-02、E-03、E-04、E-05、E-06
  -> 观察：系统集成面清单和放置位置清单都不含主屏手势
  -> 推论：iOS 不向第三方应用提供主屏手势注册接口
  -> 决策：主屏上滑手势不采用
  -> 验证条件：V01
  -> 回填位置：conclusion.md 第 3.1 节、conclusion.md 第 6 节
```

```text
研究问题：哪个入口能一键打开应用并进入指定工作区
  -> 来源：E-07、E-08、E-10、E-11、E-29
  -> 观察：控件按钮可以绑定实现 OpenIntent 的意图，系统自动进入前台
  -> 推论：控制中心控件是唯一满足该要求的入口
  -> 决策：推荐控制中心控件配 OpenIntent
  -> 验证条件：V07、V08
  -> 回填位置：conclusion.md 第 3.2 节、solution.md 第 2 章
```

```text
研究问题：哪个入口不打开应用就能执行动作
  -> 来源：E-12、E-15、E-16、E-17、E-18、E-20
  -> 观察：小组件按钮在 Widget 扩展进程执行，iOS 17 起可用，锁定状态不生效
  -> 推论：主屏交互小组件是免打开程度最高的入口
  -> 决策：推荐主屏交互小组件为第一优先级
  -> 验证条件：V02、V03
  -> 回填位置：conclusion.md 第 3.3 节、conclusion.md 第 4 节
```

```text
研究问题：接入成本是否可复用
  -> 来源：E-03、E-11、E-27、E-28、E-29
  -> 观察：一套 App Intent 同时供小组件、控件、Shortcuts 和 Action Button 使用
  -> 推论：组合采用多个入口的边际成本低
  -> 决策：按一套意图加多个系统空间入口交付
  -> 验证条件：V02、V06、V09
  -> 回填位置：solution.md 第 1 节、solution.md 第 10 节
```

```text
研究问题：应用内 bottom sheet 能否替代主屏上滑
  -> 来源：E-17、E-30
  -> 观察：presentationDetents 只在应用内生效，小组件不支持任意手势控件
  -> 推论：应用内 bottom sheet 不是免打开入口
  -> 决策：只作为应用内体验保留
  -> 验证条件：V12
  -> 回填位置：conclusion.md 第 3.7 节
```

## 7. 反证和限制

### 7.1 负向证据

“主屏手势不可用”和“轻点背面延迟未知”都是未找到证据，不是官方否认。
受影响的条目是 `E-02` 和 `E-23`。
本次调研没有可用的网页搜索，第三方资料未纳入。
Apple 文档站的数据接口是内部接口，不是公开契约。

### 7.2 使用手册正文未逐句核对

Apple 使用手册的正文由浏览器脚本渲染。
命令行读取只得到 Apple 支持检索返回的摘要。
受影响的条目是 `E-22`、`E-31`、`E-33`。
这些条目只用于支撑辅助结论，不用于支撑高影响结论。

### 7.3 没有真机验证

本机是 macOS。
仓库没有 iOS 工程目标。
所有结论来自 Apple 官方文档，没有真机交叉验证。

### 7.4 版本时效

Apple 文档随系统版本变化。
本文件的结论只对应 `2026-10-13` 的文档状态。
`openAppWhenRun` 已在 iOS 26.0 起废弃，`supportedModes` 已替代它。
后续版本可能新增或移除接入面。

## 8. 已知缺口

1. 轻点背面到动作执行的实测延迟（`E-23`）。
2. 轻点背面的误触率与识别成功率。
3. 锁屏小组件按钮在锁定状态下的实际表现。
4. 控件在锁定设备上的认证语义细节。
5. 各入口在低电量模式下的行为。
6. 各入口在系统重启后第一次触发时的行为。
7. Action Button 在 iPhone 17e 与 iPhone Air 上的可用功能清单。
8. 应用被卸载重装后用户已添加入口的状态。
9. iOS 27 是否新增主屏手势接入面。
10. 主屏快捷指令书签与 App Intent 的绑定细节。
11. iPadOS 上锁屏小组件与控件的实际行为。
12. 入口在小部件图库中的排序规则。

## 9. 复核方法

1. 按第 3.1 节的命令确认本机环境。
2. 用第 3.1 节的 `curl` 命令重新读取 Apple 接口参考页，核对平台版本表。
3. 打开参考来源列表中的页面，逐条核对本文引用。
4. 按 [validation/README.md](validation/README.md) 执行测试矩阵。
5. 在真机上执行 [validation/case-ios-ambient-entry.md](validation/case-ios-ambient-entry.md) 的步骤并回填结果。

## 参考来源

- [Apple：App Intents](https://developer.apple.com/documentation/appintents)
- [Apple：App Intents 硬件交互](https://developer.apple.com/documentation/appintents/hardware-interactions)
- [Apple：App Intents 小部件、实时活动与控件](https://developer.apple.com/documentation/appintents/widgets-live-activities-and-controls)
- [Apple：App Shortcuts](https://developer.apple.com/documentation/appintents/app-shortcuts)
- [Apple：AppIntent](https://developer.apple.com/documentation/appintents/appintent)
- [Apple：AppIntent.supportedModes](https://developer.apple.com/documentation/appintents/appintent/supportedmodes)
- [Apple：AppIntent.openAppWhenRun](https://developer.apple.com/documentation/appintents/appintent/openappwhenrun)
- [Apple：OpenIntent](https://developer.apple.com/documentation/appintents/openintent)
- [Apple：SetValueIntent](https://developer.apple.com/documentation/appintents/setvalueintent)
- [Apple：WidgetKit](https://developer.apple.com/documentation/widgetkit)
- [Apple：为小部件和实时活动添加交互](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)
- [Apple：从小部件链接到应用场景](https://developer.apple.com/documentation/widgetkit/linking-to-specific-app-scenes-from-your-widget-or-live-activity)
- [Apple：Controls](https://developer.apple.com/documentation/widgetkit/controls-collection)
- [Apple：创建跨系统的控件](https://developer.apple.com/documentation/widgetkit/creating-controls-to-perform-actions-across-the-system)
- [Apple：ControlWidget](https://developer.apple.com/documentation/swiftui/controlwidget)
- [Apple：ControlWidgetButton](https://developer.apple.com/documentation/widgetkit/controlwidgetbutton)
- [Apple：WidgetFamily](https://developer.apple.com/documentation/widgetkit/widgetfamily)
- [Apple：Button init(_:intent:)](https://developer.apple.com/documentation/swiftui/button/init(_:intent:)-7urde)
- [Apple：presentationDetents](https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:))
- [Apple：UIApplicationShortcutItem](https://developer.apple.com/documentation/uikit/uiapplicationshortcutitem)
- [Apple HIG：Controls](https://developer.apple.com/design/human-interface-guidelines/controls)
- [Apple HIG：Widgets](https://developer.apple.com/design/human-interface-guidelines/widgets)
- [Apple HIG：Action button](https://developer.apple.com/design/human-interface-guidelines/action-button)
- [Apple HIG：Home Screen quick actions](https://developer.apple.com/design/human-interface-guidelines/home-screen-quick-actions)
- [Apple HIG：Gestures](https://developer.apple.com/design/human-interface-guidelines/gestures)
- [Apple：WWDC23 场次 10028 Bring widgets to life](https://developer.apple.com/videos/play/wwdc2023/10028/)
- [Apple：WWDC24 场次 10157 Extend your app's controls across the system](https://developer.apple.com/videos/play/wwdc2024/10157/)
- [Apple 支持：Use Back Tap on your iPhone](https://support.apple.com/en-us/111772)
- [Apple 支持：Use the Action button, side button, and other controls on your iPhone](https://support.apple.com/en-us/105103)
- [Apple 使用手册：Run shortcuts by tapping the back of your iPhone](https://support.apple.com/guide/shortcuts/run-shortcuts-tapping-iphone-apd897693606/ios)
- [Apple 使用手册：Run shortcuts with the Action button](https://support.apple.com/guide/shortcuts/run-shortcuts-with-the-action-button-apdfea15680b/ios)
- [Apple 使用手册：Add a shortcut to the Home Screen](https://support.apple.com/guide/shortcuts/add-a-shortcut-to-the-home-screen-apd735880972/ios)
- [Apple 使用手册：Use and customize Control Center on iPhone](https://support.apple.com/guide/iphone/use-and-customize-control-center-iph59095ec58/ios)
- [Apple 使用手册：Create a custom iPhone Lock Screen](https://support.apple.com/guide/iphone/create-a-custom-lock-screen-iph4d0e6c351/ios)
- [Apple 使用手册：Use and customize the Action button on iPhone](https://support.apple.com/guide/iphone/use-and-customize-the-action-button-iphe89d61d66/ios)

## 10. 关联文档

- [主题索引](README.md)
- [前因与问题边界](context.md)
- [调研方法与技术分析](investigation.md)
- [结论与限制](conclusion.md)
- [推荐入口与契约草案](solution.md)
- [验证目录](validation/README.md)
- [Case 1：iOS 免打开入口可用性](validation/case-ios-ambient-entry.md)
