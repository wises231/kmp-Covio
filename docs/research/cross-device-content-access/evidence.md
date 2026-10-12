# 跨设备内容读取能力证据附录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 审计记录，可复核 |
| 日期 | `2026-10-12` |
| 主文 | [主题索引](README.md) |
| 验证目录 | [验证目录](validation/README.md) |

本次调研的网页来源访问日期均为 `2026-10-12`。
来源等级按 [AUTHORING.md](../AUTHORING.md) 第 9 节。
A 是官方规范、接口定义和源码。
B 是固定版本的源码、配置和发布说明。
C 是官方文档和知识库。
D 是本机实验。
E 是第三方文章和社区讨论。

## 1. 来源等级

| 等级 | 来源 | 用途 | 置信度 |
| --- | --- | --- | --- |
| A | Apple 接口文档、Apple TN3179、AOSP 源码、Android CDD、Microsoft Learn、RFC | 权威行为和硬约束 | 高 |
| B | 本机 SDK 头文件、本机二进制字符串、Android 行为变更页、项目源码与配置 | 实现边界 | 高 |
| C | Apple 支持文章、Apple 论坛 Apple 工程师回复、Google Play 政策页、Microsoft Windows Insider 博客 | 产品能力和操作方式 | 中 |
| D | 本机 macOS 27.0.1 实验 | 当前环境事实 | 高，范围小 |
| E | 社区讨论、第三方文章、逆向工程报道 | 背景和线索 | 低 |

高影响结论使用 A 或 B 证据。
仅凭 E 证据的判断已标记为推测。

## 2. 环境事实

| 项目 | 值 | 命令 | 置信度 |
| --- | --- | --- | --- |
| 系统版本 | macOS 27.0.1，build `26A434` | `sw_vers` | 高 |
| 内核 | Darwin 27.0.0 | `uname -a` | 高 |
| 架构 | arm64 | `uname -m` | 高 |
| 截图偏好键 | `location-screenshot`、`target-screenshot`、`location-screenrecording`、`target-screenrecording` | `defaults read com.apple.screencapture` | 高 |
| 截图目标 | `file` | 同上 | 高 |
| 录屏目录 | `~/Library/Application Support/Covio/Screenshots` | 同上 | 高 |
| 剪切板读取 | 成功，无系统提示 | `swift pb.swift` | 高 |
| TCC 数据库 | 打不开 | `sqlite3 .../TCC.db` | 高 |
| 本地网络偏好域 | 不存在 | `defaults read com.apple.network.local-network` | 高 |

### 2.1 复现命令

```sh
sw_vers
uname -m
defaults read com.apple.screencapture
strings /usr/sbin/screencapture | grep -E '^(location|target)(-screenshot|-screenrecording)?$'
plutil -p /System/Library/ExtensionKit/Extensions/SecurityPrivacyExtension.appex/Contents/Resources/TCCServiceList.plist | grep -iE 'pasteboard|localnetwork'
sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" 'select count(*) from access;'
defaults read com.apple.network.local-network
```

剪切板探针脚本：

```swift
import AppKit
let pb = NSPasteboard.general
print("changeCount=\(pb.changeCount)")
print("types=\((pb.pasteboardItems ?? []).flatMap { $0.types.map(\.rawValue) }.sorted().joined(separator: ","))")
print("hasString=\(pb.string(forType: .string) != nil)")
```

### 2.2 环境结论

结论适用于 macOS 27.0.1。
macOS 26 及更早版本需要单独复核。
剪切板探针只读取类型和长度，未记录内容。
剪切板类型列表含其他应用的私有类型。
因此类型层面可读，不只限于文本。

## 3. 证据索引

| 编号 | 主题 | 来源 | 结论 | 置信度 |
| --- | --- | --- | --- | --- |
| E-01 | 本机环境 | D | macOS 27.0.1，arm64 | 高 |
| E-02 | 本机剪切板读取 | D | 无需授权，无提示 | 高 |
| E-03 | 截图偏好键 | D | macOS 27 使用新键名 | 高 |
| E-04 | 权限状态不可读 | D | TCC 与本地网络域在当前权限下不可读 | 高 |
| E-05 | macOS 27 隐私面板 | D | 已存在剪切板和本地网络两个面板 | 高 |
| E-06 | Covio 现有实现 | B | 剪切板轮询与截图目录监视已实现 | 高 |
| E-07 | macOS 剪切板读取闸门 | A/B | 读取无需授权，但已有闸门 API | 高 |
| E-08 | macOS 截图事件 | A/B/D | 无公开事件 API，有元数据属性 | 高 |
| E-09 | macOS 受保护文件夹 | A | 桌面、文稿和下载受 TCC 保护 | 高 |
| E-10 | iOS 剪切板读取 | A | 前台读取需用户确认 | 高 |
| E-11 | iOS 相册截图 | A | 需相册授权，或走选择器 | 高 |
| E-12 | iOS 截图通知 | A | 只在应用运行时触发 | 高 |
| E-13 | Apple 本地网络权限 | A | 出站连接和 Bonjour 需要授权 | 高 |
| E-14 | Apple 组播权限 | A | iOS 需要申请，macOS 不需要 | 高 |
| E-15 | iOS 后台接收 | C | 后台监听 socket 不可靠 | 中高 |
| E-16 | ad-hoc 签名 | A | 身份不稳定会导致授权失效 | 高 |
| E-17 | 通用剪贴板 | A | 无公开接口 | 高 |
| E-18 | Android 剪切板焦点限制 | A/B | 非焦点应用读不到内容 | 高 |
| E-19 | Android 剪切板提示与后台路径 | A/B | 读取有提示，后台无合法路径 | 高 |
| E-20 | Android 截图识别 | A | 无截图标记，靠路径和文件名 | 高 |
| E-21 | Android 媒体权限与检测 API | A/B | 权限分三级，检测 API 只覆盖自身 | 高 |
| E-22 | Android 17 本地网络权限 | A/B | 目标 SDK 37 时强制 | 高 |
| E-23 | Android 后台网络 | A/B | Doze 断网，无可用 WifiLock | 中高 |
| E-24 | Windows 剪切板读取 | A | 无需授权，需要消息窗口 | 高 |
| E-25 | Windows 剪切板历史 | A | 有历史接口，无云剪贴板接口 | 高 |
| E-26 | Windows 截图路径 | A/C | 有已知文件夹和目录监视 | 高 |
| E-27 | Windows 截图协议 | A | 需 MSIX 包身份，且只能自身发起 | 高 |
| E-28 | Windows 发现与会话 | A | 原生 DNS-SD，服务可跨登录运行 | 高 |
| E-29 | 拉取先例 | A/B/C | 无产品支持对端无动作时拉取 | 高 |
| E-30 | LocalSend | A/B | 自建发现，无配对 | 高 |
| E-31 | KDE Connect | A | 手机到电脑剪切板不通 | 高 |
| E-32 | Syncthing | A/B | 唯一持续拉取模型 | 高 |
| E-33 | 系统原生能力 | A/C | 同账号前提覆盖部分场景 | 高 |
| E-34 | iOS 26 Wi-Fi Aware | A | 新增点对点路径 | 中高 |
| E-35 | 安全模型先例 | A/B | 低熵短码需要 PAKE 或限速 | 高 |
| E-36 | 应用商店政策 | A/C | 无剪切板条款，有后台服务条款 | 高 |
| E-37 | Windows 防火墙入站规则 | A | 标准用户无法创建允许规则 | 高 |
| E-38 | Windows 局域网应用发现实现 | B | 五款主流应用都不用系统 DNS-SD 接口 | 高 |
| E-39 | Windows 注销与快速启动语义 | A/B | 注销终止会话进程，快速启动等同注销 | 高 |
| E-40 | Windows 已知文件夹边界 | A | WinRT 无截图文件夹成员 | 高 |
| E-41 | 就近共享接口边界 | A/B | 只有 Android 发送端，无接收接口 | 高 |
| E-42 | Android 截图元数据更正 | A | 时间字段单位不一致，CDD 引用不成立 | 高 |

## 4. 证据详情

### E-01：本机环境

来源等级：D
环境：本机 macOS，Apple Silicon
命令或来源：`sw_vers`、`uname -m`
关键输出：

```text
ProductName:      macOS
ProductVersion:   27.0.1
BuildVersion:     26A434
arm64
```

观察：本机系统为 macOS 27.0.1，架构为 arm64。
推论：本文件中的本机实验结论只适用于 macOS 27。
反证：无。
限制：单机、单版本、单用户。
置信度：高
关联：E-02、E-03、E-04、E-05

### E-02：本机剪切板读取

来源等级：D
环境：macOS 27.0.1，独立编译的 Swift 命令行程序
命令或来源：`swift pb.swift`
关键输出：

```text
changeCount=153
types=org.chromium.internal.source-rfh-token,org.chromium.source-url,public.utf8-plain-text
hasString=true
```

观察：命令行程序读到剪切板计数、全部类型和文本。
观察：系统没有弹出授权提示。
观察：类型列表包含其他应用的私有类型。
推论：macOS 27 上普通进程读取通用剪切板不需要 TCC 授权。
推论：读取能看到完整类型列表，不只文本。
反证：未测试沙盒应用。未测试全新 bundle ID 的公证应用。
限制：命令行进程不经过 App Sandbox，结论不能直接外推到沙盒应用。
置信度：高
关联：E-07、E-06

### E-03：截图偏好键

来源等级：D
环境：macOS 27.0.1
命令或来源：`defaults read com.apple.screencapture`、`strings /usr/sbin/screencapture`
关键输出：

```text
"location-screenrecording" => "/Users/wyz/Library/Application Support/Covio/Screenshots"
"target-screenrecording" => "file"
"target-screenshot" => "file"

location-screenrecording
location-screenshot
target-screenrecording
target-screenshot
```

观察：本机偏好里没有裸键 `location` 和 `target`。
观察：系统二进制只含四个带后缀的键名。
观察：Covio 已把录屏目录指向自己的支持目录。
推论：macOS 27 使用 `location-screenshot` 与 `target-screenshot`。
推论：旧教程里的 `defaults write com.apple.screencapture location` 在 macOS 27 不生效。
限制：无法确定改名发生在哪个具体版本。
置信度：高
关联：E-08、E-06

### E-04：权限状态不可读

来源等级：D
环境：macOS 27.0.1，普通用户权限
命令或来源：`sqlite3 .../TCC.db`、`defaults read com.apple.network.local-network`
关键输出：

```text
Error: unable to open database ".../TCC.db": unable to open database file
Error: Domain 'com.apple.network.local-network' not found.
```

观察：TCC 数据库需要 Full Disk Access 才能打开。
观察：本地网络偏好域在普通权限下不存在。
推论：授权状态只能用系统界面查看。
推论：文档和脚本不能依赖命令行读取授权状态。
限制：域不存在也可能是写入方式不同，不一定是未创建。
置信度：高
关联：E-13、E-16

### E-05：macOS 27 隐私面板

来源等级：D
环境：macOS 27.0.1
命令或来源：`plutil -p .../SecurityPrivacyExtension.appex/Contents/Resources/TCCServiceList.plist`、同目录 `Localizable.loctable`
关键输出：

```text
"serviceClass" => "PrivacyLocalNetworkService"
"serviceClass" => "PrivacyPasteboardService"

"PASTEBOARD_ACCESS" => "Paste from Other Apps"
"PASTEBOARD_ACCESS_SUMMARY" => "Allow the applications below to access pasteboard contents from other applications at any time."
"LOCAL_NETWORK" => "Local Network"
"LOCAL_NETWORK_SUMMARY" => "Allow the applications below to find and communicate with devices on your local network."
```

观察：系统设置扩展里已存在剪切板访问面板和本地网络面板。
观察：面板文案说明用户可逐个应用授予长期访问。
推论：macOS 已把剪切板读取纳入隐私模型。
推论：剪切板自由读取随时可能变为默认询问。
限制：面板存在不等于默认开启拦截。
置信度：高
关联：E-07、E-13

### E-06：Covio 现有实现

来源等级：B
环境：仓库快照，分支 `feature/swiftui-macos`
命令或来源：`macosApp/src/Clipboard/ClipboardMonitor.swift`、`macosApp/src/Shelf/ScreenshotWatcher.swift`、`macosApp/src/Info.plist`
关键输出：

```text
ClipboardMonitor: 每 0.5 秒比对 changeCount，计数变化后才读取内容
ScreenshotWatcher: DispatchSource 监视目录，用 getxattr 读 kMDItemIsScreenCapture
Info.plist: 只有 LSUIElement，无 NSLocalNetworkUsageDescription 与 NSBonjourServices
```

观察：剪切板监视用轮询，代码注释说明 AppKit 没有剪切板变更通知。
观察：截图识别依赖扩展属性，只对落盘文件有效。
观察：应用当前没有声明任何本地网络用途。
推论：三类能力中只实现了本机读取，跨设备部分尚未开始。
推论：跨设备能力需要新增本地网络权限声明。
限制：仓库处于迁移中，实现细节可能变化。
置信度：高
关联：E-02、E-03、E-13

### E-07：macOS 剪切板读取闸门

来源等级：A/B
环境：macOS 27.0.1，本机 SDK `MacOSX27.0.sdk`
命令或来源：`NSPasteboard.accessBehavior` 文档、`NSPasteboard.h`、`macos-27_2-release-notes`
关键输出：

```text
accessBehavior: default / ask / alwaysAllow / alwaysDeny，macOS 15.4 起
macOS 27.2 发布说明：EnablePasteboardPrivacyDeveloperPreview 已移除
本机实测：accessBehavior 返回 alwaysAllow
```

观察：Apple 已提供剪切板访问行为的查询接口。
观察：开发者预览开关在 macOS 27.2 被移除。
观察：本机 ad-hoc 签名的测试应用读不到 `.default`，实际为 `.alwaysAllow`。
推论：macOS 正在建立剪切板访问闸门，但当前默认仍是允许。
推论：应用应查询 `accessBehavior`，不假设永远允许。
反证：头文件注释与实测不一致，原因未确定。
限制：未在公证的 App Store 分发应用上复现。
置信度：高
关联：E-05、E-02

### E-08：macOS 截图事件与元数据

来源等级：A/B/D
环境：macOS 27.0.1，本机 SDK
命令或来源：`AppKit` 头文件、`mdls -name kMDItemIsScreenCapture`、`mdfind`
关键输出：

```text
mdls: kMDItemIsScreenCapture = 1
mdls: kMDItemScreenCaptureType = "selection"
AppKit 无 Screenshot 相关通知符号
```

观察：系统没有截图完成通知。
观察：落盘截图带 Spotlight 元数据属性。
观察：目标为剪切板、邮件或预览时截图不落盘。
推论：第三方应用只能靠目录监视加元数据判断新截图。
推论：不落盘的截图无法检测。
限制：属性只在文件写完后存在。
置信度：高
关联：E-06、E-03

### E-09：macOS 受保护文件夹

来源等级：A
环境：macOS 10.15 及以后
命令或来源：`NSDesktopFolderUsageDescription` 文档、Apple Platform Security
关键输出：

```text
"The first time your app tries to access a file in the user's Desktop folder without implied user consent, the system prompts the user for permission to access the folder's contents." — macOS 10.15 起
```

观察：桌面、文稿和下载三个目录受 TCC 保护。
观察：截图默认保存到桌面。
推论：默认配置下，截图监视会触发文件夹授权提示。
推论：用户拒绝后，截图目录监视失效。
反证：Apple Platform Security 表格把文件与文件夹标为不提示，与接口文档冲突。
限制：未在本机触发该提示验证。
置信度：高
关联：E-08、E-03

### E-10：iOS 剪切板读取

来源等级：A
环境：iOS 14 至 iOS 27
命令或来源：`UIPasteboard` 文档、`UIPasteControl` 文档、`detectPatterns` 与 `detectedValues` 文档
关键输出：

```text
"Starting in iOS 14, the system notifies the user when an app gets general pasteboard content that originates in a different app without user intent."
"In iOS 16 and later, programmatic pasting raises a user alert that prompts the user for approval…"
detectPatterns: 不提示，但不给内容
detectedValues: 给内容，但提示
UIPasteControl: 唯一免提示的内容读取通道，需要用户点击
```

观察：iOS 上程序化读取内容必须经过用户同意。
观察：免提示的接口拿不到内容。
观察：类型和数量等元数据读取不触发提示。
推论：iOS 上没有后台静默读取剪切板内容的路径。
推论：iOS 侧只能由用户动作触发读取。
限制：未在真机验证各版本的提示差异。
置信度：高
关联：E-19、E-06

### E-11：iOS 相册截图

来源等级：A
环境：iOS 9.0 及以后，`PHPickerViewController` 为 iOS 14+
命令或来源：`PHAssetMediaSubtype.photoScreenshot`、`PHPickerViewController`、`PHAuthorizationStatus.limited`
关键输出：

```text
PHAssetMediaSubtypePhotoScreenshot API_AVAILABLE(ios(9))
PHAssetCollectionSubtypeSmartAlbumScreenshots = 211
limited: 应用只能访问用户选中的资源
```

观察：照片库有截图子类型和截图智能相簿。
观察：权限分为完整访问、受限访问和仅添加。
观察：选择器不需要相册授权。
推论：枚举最近截图需要相册授权。
推论：受限访问下只能看到用户选中的截图。
限制：受限访问是否保留截图子类型未经 Apple 确认。
置信度：高
关联：E-21、E-12

### E-12：iOS 截图通知

来源等级：A
环境：iOS 7.0 及以后
命令或来源：`UIApplication.userDidTakeScreenshotNotification`
关键输出：

```text
"This notification doesn't contain a userInfo dictionary. This notification posts after the screenshot is taken."
iOS 26 起另有 UserDidTakeScreenshotMessage
```

观察：通知存在，但不携带内容。
观察：通知只在应用运行时发出。
推论：该通知不能替代目录或相册扫描。
推论：应用未运行时截图完全不可见。
限制：未验证后台或挂起状态下的行为。
置信度：高
关联：E-11

### E-13：Apple 本地网络权限

来源等级：A
环境：iOS 14 及以后，macOS 15 及以后
命令或来源：Apple TN3179《Understanding local network privacy》，`2026-10-06` 修订
关键输出：

```text
需要授权：发出 TCP 连接、发送 UDP、连接 UDP socket、接收 UDP 组播或广播、解析 .local 名称、Bonjour 注册与浏览
不需要授权：监听并接受进入的 TCP 连接、接收进入的 UDP 单播
iOS 后台执行本地网络操作时不弹提示，系统直接拒绝且不记录决定
macOS：launchd daemon、root 进程、终端与 SSH 命令行工具自动放行；该例外不适用于 launchd agent
```

观察：权限按操作方向区分，出站需要，被动接收 TCP 不需要。
观察：iOS 后台无法补弹提示。
观察：macOS 按用户账号分别保存状态。
推论：设备发现必须在前台完成并取得授权。
推论：应用需要 `NSLocalNetworkUsageDescription` 和 `NSBonjourServices`。
推论：命令行工具放行会让开发测试误判正式应用的行为。
限制：Apple Platform Security 与 TN3179 对 MDM 配置能力的说法冲突，未解决。
置信度：高
关联：E-14、E-22、E-06

### E-14：Apple 组播权限

来源等级：A
环境：iOS 14 及以后；macOS 不适用
命令或来源：`com.apple.developer.networking.multicast` 文档、TN3179
关键输出：

```text
"Your app must have this entitlement to send or receive IP multicast or broadcast on iOS. It also allows your app to browse and advertise arbitrary Bonjour service types. This entitlement requires permission from Apple before you can use it in your app."
TN3179: "The multicast entitlement isn't required on macOS."
浏览已声明的 Bonjour 服务类型：不需要组播权限
浏览全部服务类型或使用原始组播：需要
```

观察：iOS 上原始组播和任意服务类型需要向 Apple 申请权限。
观察：声明具体服务类型后可免该权限。
推论：跨平台发现应在 `NSBonjourServices` 中列出确切服务类型。
推论：不能依赖通配符或服务类型枚举。
限制：申请批准标准和周期未核实。
置信度：高
关联：E-13、E-30

### E-15：iOS 后台接收

来源等级：C
环境：iOS，Apple 开发者论坛答复
命令或来源：Apple 工程师 Quinn 的论坛答复，线程 `840808`
关键输出：

```text
已注册 Bonjour 的 NWListener 在应用挂起时被判为 defunct，收到 .failed
未注册 Bonjour 的 NWListener 不被判为 defunct，但静默停止监听
后台模式清单中没有适配的能力
唯一可靠的唤醒路径是 APNs
```

观察：后台监听 socket 没有契约保证。
观察：后台 URLSession 只支持 HTTP 且是出站角色。
推论：iOS 上不能常驻接收局域网传入连接。
推论：跨设备推送在 iOS 需要唤醒后主动拉取。
限制：作者明确说明这是当前实现，不是 API 契约。
置信度：中高
关联：E-10、E-19、E-23

### E-16：ad-hoc 签名与授权身份

来源等级：A
环境：macOS 15 及以后
命令或来源：TN3179 代码签名章节、Apple 论坛答复 `695689`
关键输出：

```text
"To ensure that local network privacy reliably tracks the identity of your macOS program, sign it with an Apple-issued code-signing identity."
"If your main executable has no UUID, or shares a UUID with other programs, local network privacy may behave weirdly."
TCC 同样按代码签名判断版本是否同一程序
```

观察：本地网络授权和 TCC 都用代码签名标识程序。
观察：ad-hoc 签名每次重建可能产生新身份。
推论：内测的 ad-hoc 构建每次重建都可能要求用户重新授权。
推论：跨设备能力依赖稳定签名，越早接入签名越省事。
限制：未在本机重建构建验证授权是否丢失。
置信度：高
关联：E-13、E-09

### E-17：通用剪贴板

来源等级：A
环境：macOS 10.12 及以后，iOS 10 及以后
命令或来源：`NSPasteboard` 文档、Apple 支持文章 `102430`
关键输出：

```text
"The general pasteboard … automatically participates with the Universal Clipboard feature… There is no macOS API for interacting with this feature."
要求：同一 Apple Account、蓝牙与 Wi-Fi 开启、接力开启、设备靠近
```

观察：通用剪贴板由系统驱动，没有第三方接口。
观察：要求同一 Apple 账号。
推论：Covio 无法借用系统通道，只能自建通道。
推论：系统通道覆盖的是苹果生态内部场景，跨生态仍有空位。
限制：支持文章未说明是否要求双重认证。
置信度：高
关联：E-33

### E-18：Android 剪切板焦点限制

来源等级：A/B
环境：Android 10（API 29）及以后
命令或来源：Android 10 行为变更页、Android 16 CDD 9.8.7、AOSP `ClipboardService.java`
关键输出：

```text
"Unless your app is the default input method editor (IME) or is the app that currently has focus, your app cannot access clipboard data on Android 10 or higher."
CDD：设备不得向非默认输入法且非焦点应用返回剪切板数据
AOSP：拒绝路径记录 "application is not in focus nor is it a system service"
AOSP：dispatchPrimaryClipChanged 同样受该闸门控制
```

观察：非焦点应用的读取返回空值。
观察：变更监听器对不合格应用根本不触发。
观察：写入不受限制。
推论：Android 上不存在被动剪切板监听。
推论：唯一合法常驻读取方是默认输入法。
反证：多处社区资料称监听器会触发但内容为空，与 AOSP 源码不符。
限制：未在真机验证。
置信度：高
关联：E-19、E-10

### E-19：Android 剪切板提示与后台路径

来源等级：A/B
环境：Android 12 至 17
命令或来源：Android 复制粘贴指南、Android 13 行为变更页、AOSP
关键输出：

```text
Android 12+：读取他应用内容时显示 "APP pasted from your clipboard" 提示
Android 13+：写入剪切板时显示系统预览浮层
EXTRA_IS_SENSITIVE 只做遮罩，不改变行为
默认输入法：CDD 允许读取
前台服务：只延长进程寿命，不授予焦点
无障碍服务：AOSP 中无剪切板豁免
```

观察：读取和写入都有面向用户的可见反馈。
观察：前台服务不能替代焦点。
观察：绕过路径都要抢占焦点或依赖签名权限。
推论：Android 上剪切板同步只能由用户动作触发。
推论：强行后台读取会触发提示并带来商店审核风险。
限制：Android 17 是否改变用户主动粘贴的提示未确认。
置信度：高
关联：E-18、E-10

### E-20：Android 截图识别

来源等级：A
环境：AOSP 主干，Android 14 至 17
命令或来源：AOSP `ImageExporter.java`、`MediaStore` 文档
关键输出：

```text
写入路径：Environment.DIRECTORY_PICTURES + "/Screenshots"，即 Pictures/Screenshots
文件名模板：Screenshot_%1$tY%<tm%<td-%<tH%<tM%<tS.%2$s
MediaStore 无 IS_SCREENSHOT 列
```

观察：系统截图写入图片库的 Screenshots 目录。
观察：媒体库没有截图标记列。
观察：厂商路径可能不同。
推论：识别最近截图需要按路径和文件名启发式匹配。
推论：该启发式对第三方应用保存的图片可能误判。
限制：厂商路径差异未核实。
置信度：路径与列表为高，厂商差异为低。
关联：E-21、E-08

### E-21：Android 媒体权限与检测接口

来源等级：A/B
环境：Android 13 至 17
命令或来源：Android 14 部分照片访问文档、Android 14 截屏检测文档
关键输出：

```text
Android 13+：READ_MEDIA_IMAGES 为全库权限
Android 14+：READ_MEDIA_VISUAL_USER_SELECTED 为部分访问，授权会过期
系统照片选择器：不需要任何权限
registerScreenCaptureCallback：仅对自身可见 Activity 生效，仅限硬件按键截屏，不返回图像
```

观察：媒体库权限分为全库、部分和无权限三级。
观察：截屏检测接口只覆盖应用自己的界面。
推论：读取最近截图必须获得媒体库授权。
推论：检测接口对跨应用场景无用。
限制：部分访问是否能看到截图子类型未核实。
置信度：高
关联：E-20、E-11

### E-22：Android 17 本地网络权限

来源等级：A/B
环境：Android 16（API 36）为选择加入，Android 17（API 37）为强制
命令或来源：Android 本地网络权限文档，`2026-10-02` 更新；`Manifest.permission` 参考
关键输出：

```text
"Starting in Android 17, local network protections are mandatory and enforced for apps targeting Android 17 or higher."
权限名：ACCESS_LOCAL_NETWORK，protection level 为 dangerous，属于 NEARBY_DEVICES 组
受控操作：出站 TCP、接受入站 TCP、UDP 收发、组播与广播、NsdManager、.local 解析
失败表现：TCP 超时，UDP 返回 EPERM
目标 SDK 36 及以下：不加该权限，也不要申请
替代路径：NsdManager 加 FLAG_SHOW_PICKER 的系统选择器，授权跨重启保留
```

观察：新权限位于网络栈内部，对所有网络接口生效。
观察：权限按目标 SDK 版本强制。
观察：WebView 继承宿主应用的权限状态。
推论：Covio 升级到目标 SDK 37 时必须新增权限申请与降级路径。
推论：系统选择器是一条免权限的发现路径。
限制：该常量在抓取的 AOSP `main` 分支清单中未找到，与接口参考不一致。
置信度：高
关联：E-13、E-28、E-30

### E-23：Android 后台网络

来源等级：A/B
环境：Android 14 至 17
命令或来源：Android 前台服务类型文档、Doze 文档、`WifiManager.WifiLock` 参考、AOSP `WifiMulticastLockManager.java`
关键输出：

```text
Doze：暂停网络访问，忽略唤醒锁
dataSync 前台服务：24 小时内累计 6 小时上限
connectedDevice 前台服务：无时长上限，且不在 Android 15 的 BOOT_COMPLETED 禁止列表
WIFI_MODE_FULL_HIGH_PERF 在 API 34 废弃，替换为仅前台可用的低延迟模式
MulticastLock 只关闭驱动过滤，不持有 WifiLock 或唤醒锁
```

观察：Doze 状态下网络不可用。
观察：Android 14 起没有后台可用的 Wi-Fi 保持模式。
观察：`connectedDevice` 类型适合局域网接收。
推论：Android 后台接收不可靠，需要用户解锁或回到前台后恢复。
推论：常驻等待不符合前台服务的政策取向。
限制：Doze 前台服务与设备状态两张官方表格冲突，未解决。
置信度：中高
关联：E-15、E-22

### E-24：Windows 剪切板读取

来源等级：A
环境：Windows Vista 及以后
命令或来源：`AddClipboardFormatListener`、`WM_CLIPBOARDUPDATE`、`OpenClipboard`、`GetClipboardSequenceNumber` 文档
关键输出：

```text
AddClipboardFormatListener 必须传 HWND，没有无窗口模式
消息窗口：CreateWindowEx 传 HWND_MESSAGE
WM_CLIPBOARDUPDATE = 0x031D，通过消息投递
GetClipboardSequenceNumber 可在无窗口时轮询
OpenClipboard 读取可传 NULL，写入需要真实 HWND
MSIX 能力列表中没有剪切板能力
```

观察：剪切板访问不需要任何权限。
观察：消息监听需要一个窗口句柄。
观察：托盘应用可用消息窗口满足该要求。
推论：Windows 桌面端可以做常驻剪切板监听。
推论：写入路径需要一个真实窗口。
限制：锁屏状态下的剪切板行为没有官方说明。
置信度：高
关联：E-25、E-06

### E-25：Windows 剪切板历史

来源等级：A
环境：Windows 10 1809（10.0.17763.0）及以后
命令或来源：`Windows.ApplicationModel.DataTransfer.Clipboard` 参考、Windows 应用能力声明文档
关键输出：

```text
可用接口：GetHistoryItemsAsync、DeleteItemFromHistory、ClearHistory、SetHistoryItemAsContent
IsHistoryEnabled、IsRoamingEnabled
结果状态：Success、AccessDenied、ClipboardHistoryDisabled
该类型不在"需要包身份"的 API 列表中
云剪贴板：只有读取本机设置和标记自身内容是否漫游的接口
```

观察：第三方应用可以读取本机剪切板历史。
观察：没有枚举其他设备同步内容的接口。
观察：组策略可以关闭历史。
推论：Windows 端可读取本地历史，但不能借用系统的跨设备通道。
推论：需要处理历史被策略关闭的情况。
限制：不支持包身份的结论是"未找到"而非官方否认。
置信度：高
关联：E-24、E-33

### E-26：Windows 截图路径

来源等级：A/C
环境：Windows 8 及以后
命令或来源：`KNOWNFOLDERID` 文档、`ReadDirectoryChangesW` 文档
关键输出：

```text
FOLDERID_Screenshots = {b7bede81-df94-4682-a7d8-57a52620b86f}
默认路径 %USERPROFILE%\Pictures\Screenshots
FOLDERID_CameraRoll = {AB5FB87B-7CE2-4F83-915D-550846C9537B}
ReadDirectoryChangesW 需要目录句柄带 FILE_LIST_DIRECTORY
缓冲区溢出时事件静默丢弃，需重新枚举
```

观察：系统定义了截图已知文件夹。
观察：目录监视不需要特殊权限。
观察：监视有缓冲区溢出风险。
推论：Windows 端能用已知文件夹加目录监视识别新截图。
推论：实现必须处理事件丢失并周期性重扫。
限制：Xbox Game Bar 与 OneDrive 重定向路径未核实。
置信度：高
关联：E-08、E-27

### E-27：Windows 截图协议

来源等级：A
环境：Windows 11，协议于 `2025-05-01` 替换旧协议
命令或来源：Microsoft Learn《Launch Snipping Tool》
关键输出：

```text
协议：ms-screenclip://，支持 discover 主机查询能力
回调：redirect-uri 返回 code、reason 与 file-access-token
"This protocol requires a packaged Windows app (MSIX)… Unpackaged (Win32) callers cannot receive responses via redirect-uri."
该协议由应用发起，不能观察用户自行截取的截图
```

观察：新协议提供截图回传能力。
观察：该能力要求打包身份。
观察：协议不能用于被动观察。
推论：Windows 端截图输入只能靠目录监视，不能靠系统协议。
推论：若用该协议，应用必须打包为 MSIX，与当前 ad-hoc 分发方式冲突。
限制：未验证当前分发方式的兼容性。
置信度：高
关联：E-26、E-16

### E-28：Windows 发现与会话

来源等级：A
环境：Windows 10 桌面版及以后
命令或来源：`DnsServiceRegister`、`DnsServiceBrowse`、Windows 防火墙文档、服务文档
关键输出：

```text
windns.h 提供 DNS-SD，最低支持 Windows 10 桌面版，不需要 Bonjour
防火墙默认阻止入站，允许出站；监听端口会触发提示
服务运行在会话 0，登录注销不影响服务
服务默认不能与用户交互
用户会话的托盘应用在注销时结束
```

观察：Windows 有原生服务发现接口。
观察：监听端需要一次防火墙授权。
观察：服务可以跨登录持续运行，但不能直接显示界面。
推论：Windows 端常驻接收需要服务加一个用户会话进程。
推论：只做用户在登录状态下的接收时，托盘应用足够。
限制：未签名的可执行文件是否影响防火墙提示未核实。
置信度：高
关联：E-22、E-26

### E-29：拉取先例

来源等级：A/B/C
环境：2026-10-12 的产品文档与源码
命令或来源：各产品官方文档与仓库，见 E-30 至 E-34
关键输出：

```text
没有任何产品允许设备 A 在对端无动作时读取对端的剪切板或截图目录
所有产品都要求对端有已授权且运行中的应用
唯一例外是同账号的系统功能
唯一的持续拉取模型是文件夹同步
```

观察：跨设备内容流动全部是推送或被同步模型。
观察：接收确认是常态。
推论：Covio 的拉取模型只适用于桌面常驻对等端。
推论：移动端必须采用推送。
限制：样本限于公开文档的产品。
置信度：高
关联：E-30、E-31、E-32、E-33

### E-30：LocalSend

来源等级：A/B
环境：LocalSend `1.18.2`，协议 `2.2`
命令或来源：LocalSend 官方仓库与协议文档
关键输出：

```text
发现：自定义 UDP 组播 224.0.0.167:53317，另有子网扫描；不使用 mDNS
传输：TCP 53317，HTTPS 与自签证书，指纹为证书 SHA-256
配对：无配对步骤，可选 PIN
平台限制：不支持空目录；Windows 需专用网络；AP 隔离与 VPN 会阻断
Android 清单含 ACCESS_LOCAL_NETWORK 与 FOREGROUND_SERVICE_DATA_SYNC，未声明 CHANGE_WIFI_MULTICAST_STATE
macOS 权限含 app-sandbox、network.client、network.server，未用组播权限
```

观察：该产品回避 mDNS，改用自定义组播加扫描。
观察：该产品不做配对，只做接收确认。
观察：该产品已为 Android 17 权限做准备。
推论：自定义组播是绕过 Bonjour 限制的可行方案。
推论：无配对模型的代价是任何人都能向本机发起请求。
限制：协议 `v3` 内容尚未写入文档。
置信度：高
关联：E-35、E-22、E-14

### E-31：KDE Connect

来源等级：A
环境：KDE Connect 协议 v8
命令或来源：KDE Connect 官方仓库与用户文档、KDE bug 436329
关键输出：

```text
传输：TCP 1716；发现：UDP 广播 1716 加 mDNS
配对：TLS 自签证书固定，首次信任；短码为双方公钥按字母序拼接加时间戳的 SHA-256 前 8 个十六进制字符
手机到电脑的剪切板同步失效，原因是 Android 10 的焦点限制
```

观察：该产品同时使用广播和 mDNS。
观察：该产品的配对算法复杂且依赖时间戳同步。
观察：剪切板同步在 Android 10 之后只支持电脑到手机方向。
推论：Android 焦点限制已在真实产品上造成功能缺失。
推论：配对短码算法应选择更简单的标准方案。
限制：未阅读全部源码。
置信度：高
关联：E-18、E-35

### E-32：Syncthing

来源等级：A/B
环境：Syncthing `2.1.6`
命令或来源：Syncthing 官方文档与 FAQ
关键输出：

```text
发现：IPv4 广播与 IPv6 组播 21027，不使用 mDNS
传输：TCP 与 QUIC 22000
配对：设备 ID 为证书 SHA-256 的 base32，双方都必须添加对方
模型：持续文件夹同步
```

观察：该产品是唯一实现持续拉取的产品。
观察：代价是双方都要显式添加对方，且持续同步而非按需读取。
推论：如果需求是"随时看到对端的截图目录"，同步模型可用。
推论：同步模型的代价是持续占用资源和明文落在接收端。
限制：未验证移动端后台同步的实际行为。
置信度：高
关联：E-29、E-20

### E-33：系统原生能力

来源等级：A/C
环境：2026-10-12
命令或来源：Apple 支持文章、Google 支持文章、Microsoft Learn
关键输出：

```text
通用剪贴板：同一 Apple 账号、蓝牙与 Wi-Fi、接力开启
快速分享：接收方确认；同账号设备自动接收并自动复制剪切板
就近共享：接收方需要保存确认；微软文档只描述 PC 到 PC
手机连接：需要微软账号，剪切板只支持部分品牌，图片超过 1MB 会压缩
隔空投送：接收方可接受或拒绝
```

观察：系统原生能力都建立在同账号或同生态之上。
观察：跨生态的组合没有原生覆盖。
观察：手机连接依赖云中继。
推论：跨生态的局域网方案仍有空位。
推论：Covio 的增量在于免账号和跨生态。
限制：系统能力随版本变化。
置信度：高
关联：E-17、E-34

### E-34：iOS 26 Wi-Fi Aware

来源等级：A
环境：iOS 26，WWDC25 场次 228
命令或来源：Apple `WiFiAware` 框架文档与 `DeviceDiscoveryUI`
关键输出：

```text
框架提供发布、订阅、设备选择与配对视图
连接在 Wi-Fi 层认证和加密
不依赖传统网络基础设施
服务名不超过 15 个字符，走 TCP 或 UDP，Apple 建议做 IANA 注册
```

观察：Apple 新增了点对点连接框架。
观察：该框架不经过局域网基础设施。
推论：该框架可绕过路由器隔离和子网问题。
推论：该框架只在 Apple 生态内部可用，不能替代跨生态局域网。
限制：未评估与 Android 设备的互通。
置信度：中高
关联：E-33、E-13

### E-35：安全模型先例

来源等级：A/B
环境：2026-10-12
命令或来源：KDE Connect 配对文档、Syncthing FAQ、RFC 9382、Wi-Fi Easy Connect 规范
关键输出：

```text
6 位短码的熵为 20 位
KDE Connect 用证书固定加短码比对
Syncthing 用双方添加设备 ID
SPAKE2 把低熵口令转换为高熵密钥，成功概率为 65536 分之一
Wi-Fi Easy Connect 在二维码中放公钥
```

观察：低熵短码单独使用不适合作为唯一凭证。
观察：成熟方案要么用 PAKE，要么用二维码携带公钥。
推论：Covio 的 6 位短码需要配合 PAKE 或严格限速。
推论：二维码携带公钥是更简单的替代。
限制：未评估具体实现的性能。
置信度：高
关联：E-31、E-30

### E-36：应用商店政策

来源等级：A/C
环境：2026-10-12
命令或来源：App Store 审核指南、Google Play 政策页
关键输出：

```text
App Store 审核指南全文没有 clipboard、paste、local network、Bonjour 字样
最接近的条款是 2.5.4 后台服务用途限制与 2.4.5(iii) 关于未经同意常驻进程
Google Play 要求 Android 14 及以上为每个前台服务声明类型
Play 要求前台服务由用户发起或对用户可见
Play 的 QUERY_ALL_PACKAGES 政策把点对点共享列为需要说明的用途
```

观察：两家商店都没有专门的剪切板条款。
观察：两家商店都限制常驻后台行为。
推论：合规风险来自后台常驻，不来自剪切板本身。
推论：文档应把常驻能力限制在桌面端。
限制：未找到成文的拒审案例。
置信度：高
关联：E-19、E-23

### E-37：Windows 防火墙入站规则

来源等级：A
环境：2026-10-12，Windows 11 24H2 文档基线
命令或来源：Microsoft Learn 防火墙规则文档 `learn.microsoft.com/windows-server/security/windows-firewall/rules`
关键输出：

```text
用户不是本地管理员时，无论选择哪个选项，系统都创建阻止规则
只有管理员在 UAC 提示后才能创建允许规则
提示由监听或绑定调用触发，不由 mDNS 浏览触发
出站默认允许，入站默认阻止
预授权路径：netsh、MSIX 的 desktop2 windows.firewallRules 扩展、INetFwPolicy2 COM
本地规则仅在本地策略合并开启时生效
```

观察：标准用户无法为入站监听创建允许规则。
观察：触发点是监听或绑定调用。
推论：标准用户账户上的局域网接收方会被系统阻断。
推论：设备发现与接收需要预先授权或需要管理员一次性配置。
限制：触发条件是否包含代码签名未在文档中列出，此处为推论。
置信度：高
关联：E-28、E-38、V08

### E-38：Windows 局域网应用发现实现

来源等级：B
环境：2026-10-12，各产品公开源码与协议文档
命令或来源：LocalSend、Syncthing、KDE Connect、Warpinator、PairDrop 的源码清单与协议说明
关键输出：

```text
LocalSend：自定义组播组 224.0.0.167，端口 53317，不是 mDNS
Syncthing：IPv4 广播加 IPv6 组播，端口 21027
KDE Connect：UDP 广播加自带 mDNS 库，源码注释说明未使用系统 mDNS 接口
Warpinator：python zeroconf，UDP 5353，唯一使用标准 mDNS
PairDrop：服务端信令的 WebRTC
五款产品都没有使用 Win32 DNS-SD 接口
自定义组播在 Windows 上常需要显式指定网络接口
```

观察：五款主流局域网应用都不使用系统 DNS-SD 接口。
推论：系统 DNS-SD 接口在 Windows 上的实际可用性低于文档描述。
推论：实现应保留自定义组播作为主要路径之一，而不是只依赖 mDNS。
限制：源码清单未覆盖全部版本，结论限于已核对的产品。
置信度：高
关联：E-28、E-37、E-30

### E-39：Windows 注销与快速启动语义

来源等级：A/B
环境：2026-10-12，Windows 11 24H2 文档基线
命令或来源：Microsoft Learn `ExitWindowsEx`、`WTSRegisterSessionNotification`、快速启动说明
关键输出：

```text
调用方在交互用户登录会话中时，注销终止该会话的全部进程
锁定屏幕不终止进程，但锁屏期间不能显示确认对话框
快速启动是注销，不是睡眠；内核会话内容写入磁盘
托盘应用不在快速启动后存活，会话 0 服务存活
从服务提升到用户界面需要 WTSQueryUserToken、DuplicateTokenEx、CreateProcessAsUserW
```

观察：注销与快速启动都会终止托盘应用。
推论：快速启动后的设备应视为离线。
推论：常驻接收方需要会话 0 服务，或依赖用户重新登录。
限制：未验证具体机型上快速启动的默认开关状态。
置信度：高
关联：E-26、E-28、V09

### E-40：Windows 已知文件夹边界

来源等级：A
环境：2026-10-12，WinRT 与 .NET 接口文档
命令或来源：WinRT `Windows.Storage.KnownFolders`、.NET `Environment.SpecialFolder`、`KNOWNFOLDERID`
关键输出：

```text
WinRT KnownFolders 有 CameraRoll、SavedPictures、AppCaptures，没有 Screenshots
.NET Environment.SpecialFolder 没有 Screenshots 成员
只有 Win32 SHGetKnownFolderPath 能取到 FOLDERID_Screenshots
FOLDERID_AppCaptures 在 WinRT 中存在，在官方 KNOWNFOLDERID 表中没有对应行
Xbox Game Bar 截图保存在 %USERPROFILE%\Videos\Captures
OneDrive 的"截图保存到 OneDrive"功能已从设置中移除，移除日期未核实
```

观察：截图文件夹只能通过 Win32 接口取得。
推论：Windows 端截图路径要使用 SHGetKnownFolderPath。
推论：候选路径至少有三个，需要探测而不是写死。
限制：OneDrive 功能的移除日期未核实。
置信度：高
关联：E-26、V09

### E-41：就近共享接口边界

来源等级：A/B
环境：2026-10-12，Microsoft 开放规范与官方仓库
命令或来源：`[MS-CDP]` Connected Devices Platform Protocol v3、Microsoft 官方仓库 issue
关键输出：

```text
就近共享底层协议是 [MS-CDP] v3，发现用 UDP 广播与组播加 BLE 信标
唯一的官方开发者接口在 Android 侧：NearShareSender，只有发送方法，没有接收端
官方仓库 issue 原话：接口只支持从 Android 到 Windows 的单向
Windows.System.RemoteSystems 是另一套传输，未接入就近共享界面
Windows.ApplicationModel.DataTransfer 共享契约只用于同机应用之间
存在 GPL-3.0 的第三方重新实现，说明官方接口缺失
```

观察：就近共享没有公开的 Windows 收发接口。
推论：Covio 不能把就近共享当作可用通道。
推论：跨生态场景仍需自建传输。
限制：Android 快速分享与 Windows 就近共享的互通状态未核实。
置信度：高
关联：E-33、E-27

### E-42：Android 截图元数据更正

来源等级：A
环境：2026-10-12，Android 接口参考与 CDD 文本
命令或来源：`MediaStore` 字段文档、Android 12 至 15 的 CDD 正文
关键输出：

```text
DATE_ADDED 单位是秒，DATE_TAKEN 单位是毫秒
两种时间字段直接比较会出错
OEM_METADATA 自 API 36 起存在，是 JSON 列，没有厂商记录在案的截图标记
此前引用的"Android 12 CDD 强制 Pictures/Screenshots"来自草案，未出现在已发布的 12 至 15 CDD 中
三星的 DCIM/Screenshots 路径仍然有效
```

观察：时间字段单位不一致。
观察：CDD 强制路径的引用不成立。
推论：截图识别必须同时匹配多个候选路径。
推论：不能依据 CDD 条款推断厂商必须使用统一路径。
限制：厂商路径未逐一核实。
置信度：高
关联：E-20、E-21、V12

## 5. 逻辑证据链

```text
研究问题：安装 Covio 能否跨设备读取文件共享、剪切板和最近截图
  -> 来源：E-02、E-06、E-18、E-24、E-10
  -> 观察：桌面端本机读取全部可行，移动端本机读取受会话与授权限制
  -> 推论：跨设备能力的天花板由移动端决定
  -> 决策：采用推送模型，拉取模型只用于桌面常驻对等端
  -> 验证条件：V01 至 V12
  -> 回填位置：conclusion.md 第 3 节、solution.md 第 1 节
```

```text
研究问题：移动端能否常驻接收
  -> 来源：E-15、E-23、E-18
  -> 观察：iOS 后台监听无契约保证，Android 后台无网络且剪切板不可读
  -> 推论：移动端不能作为被动接收方
  -> 决策：移动端只在用户动作或唤醒后工作
  -> 验证条件：V10、V12
  -> 回填位置：solution.md 第 6 节
```

```text
研究问题：设备发现如何实现
  -> 来源：E-13、E-14、E-22、E-28
  -> 观察：Apple 需要声明具体服务类型，Android 17 需要新权限，Windows 原生支持
  -> 推论：单一发现机制不能覆盖四个平台
  -> 决策：mDNS 为主，自定义组播为辅，二维码与短码兜底
  -> 验证条件：V04、V05、V06
  -> 回填位置：solution.md 第 3 节
```

## 6. 反证和限制

### 6.1 本机剪切板实测与 Apple 文档不符

Apple 文档描述 `accessBehavior` 的默认值为询问。
本机 ad-hoc 签名应用实测为 `alwaysAllow`。
原因未确定。
该反证不影响"macOS 当前默认允许读取"的结论。
该反证影响"默认值语义"的结论。

### 6.2 搜索配额耗尽

三路调研共用 200 次网页搜索上限。
首轮交付时以下项目未核实。
其中四项已在后续补充调研中核实，见第 6.7 节。
仍未核实的项目见第 7 节。

- 厂商截图路径差异。
- Windows Xbox Game Bar 与 OneDrive 的截图路径。
- Windows 未签名应用的防火墙提示行为。
- 是否存在公开的就近共享接口。
- iOS 相册受限访问是否保留截图子类型。
- iOS 17 的"最近截图"界面行为。

### 6.3 单机验证范围

本机实验只有 macOS 端。
iOS、Android 和 Windows 的结论全部来自官方文档。
没有真机交叉验证。

### 6.4 事件缺失的负向证据

"没有公开接口"这类结论是未找到证据，不是官方否认。
受影响的条目是 E-08、E-18、E-25 的一部分。

### 6.5 Android 常量与抓取源码不一致

`ACCESS_LOCAL_NETWORK` 在接口参考中标注为 API 37。
该常量在抓取的 AOSP `main` 分支清单中未找到。
两者冲突，未解决。

### 6.6 Windows 结论的两处更正

第一处：早前判断"Windows 首次监听只触发一次提示，用户允许即可"。
更正为"标准用户无法创建允许规则"（`E-37`）。
影响：标准用户账户上的接收方不可用。
影响：设备发现与接收需要预先授权。

第二处：早前判断"Windows 有原生 DNS-SD，可以直接采用"。
更正为"五款主流局域网应用都不使用系统 DNS-SD 接口"（`E-38`）。
影响：mDNS 在 Windows 上仍是候选路径，但不能作为唯一路径。

### 6.7 已解决的未核实项

第 6.2 节列出的事项中，以下四项已核实：

1. Windows 未签名应用的防火墙提示行为，见 `E-37`。
2. 是否存在公开的就近共享接口，见 `E-41`。
3. Windows 的 Xbox Game Bar 与 OneDrive 截图路径，见 `E-40`。
4. Android 截图路径的 CDD 依据，见 `E-42`。

## 7. 已知缺口

1. 没有移动端真机验证。
2. 没有两个真实设备之间的端到端验证。
3. 厂商定制系统的截图路径与后台策略未核实。
4. macOS 27 的剪切板闸门在公证应用上的默认值未核实。
5. 组播权限的申请周期与批准标准未核实。
6. Windows 防火墙提示的窗口标题与复选框文案未核实。
7. Windows 内置 mDNS 与 Bonjour 防火墙规则名称未核实。
8. 用户自定义的截图工具保存目录所在注册表位置未核实。
9. Android 快速分享与 Windows 就近共享在 2026 年的互通状态未核实。
10. Android 17 的通用剪切板接口只有逆向报告，没有官方文档。
11. Android 17 的实际发布时间与 Play 强制时间点未核实。

## 8. 复核方法

1. 在 macOS 27 上运行本文件第 2.1 节的命令。
2. 用 `defaults read com.apple.screencapture` 确认截图键名。
3. 编译第 2.1 节的 Swift 探针，确认剪切板读取行为。
4. 按 [validation/README.md](validation/README.md) 执行测试矩阵。
5. 网页来源按参考来源列表逐条打开。

## 参考来源

- [Apple TN3179：Understanding local network privacy](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)
- [Apple：NSPasteboard](https://developer.apple.com/documentation/appkit/nspasteboard)
- [Apple：NSPasteboard.AccessBehavior](https://developer.apple.com/documentation/appkit/nspasteboard/accessbehavior-swift.enum)
- [Apple：UIPasteboard](https://developer.apple.com/documentation/uikit/uipasteboard)
- [Apple：UIPasteControl](https://developer.apple.com/documentation/uikit/uipastecontrol)
- [Apple：PHAssetMediaSubtype.photoScreenshot](https://developer.apple.com/documentation/photos/phassetmediasubtype/photoscreenshot)
- [Apple：UIApplication.userDidTakeScreenshotNotification](https://developer.apple.com/documentation/uikit/uiapplication/userdidtakescreenshotnotification)
- [Apple：multicast entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.networking.multicast)
- [Apple：NSDesktopFolderUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nsdesktopfolderusagedescription)
- [Apple 支持：Universal Clipboard](https://support.apple.com/en-us/102430)
- [Apple：App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple：Wi-Fi Aware](https://developer.apple.com/documentation/wifiaware)
- [Android 10 隐私变更](https://developer.android.com/about/versions/10/privacy/changes#clipboard-data)
- [Android 13 复制粘贴](https://developer.android.com/about/versions/13/features/copy-paste)
- [Android 14 部分照片访问](https://developer.android.com/about/versions/14/changes/partial-photo-video-access)
- [Android 14 截屏检测](https://developer.android.com/about/versions/14/features/screenshot-detection)
- [Android 本地网络权限](https://developer.android.com/privacy-and-security/local-network-permission)
- [Android 前台服务类型](https://developer.android.com/develop/background-work/services/fgs/service-types)
- [Android：NsdManager](https://developer.android.com/reference/android/net/nsd/NsdManager)
- [Android 16 CDD](https://source.android.com/docs/compatibility/16/android-16-cdd)
- [AOSP ClipboardService.java](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/services/core/java/com/android/server/clipboard/ClipboardService.java)
- [Microsoft：AddClipboardFormatListener](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-addclipboardformatlistener)
- [Microsoft：Clipboard（WinRT）](https://learn.microsoft.com/en-us/uwp/api/windows.applicationmodel.datatransfer.clipboard)
- [Microsoft：KNOWNFOLDERID](https://learn.microsoft.com/en-us/windows/win32/shell/knownfolderid)
- [Microsoft：Launch Snipping Tool](https://learn.microsoft.com/en-us/windows/apps/develop/launch/launch-snipping-tool)
- [Microsoft：DnsServiceRegister](https://learn.microsoft.com/en-us/windows/win32/api/windns/nf-windns-dnsserviceregister)
- [LocalSend](https://github.com/localsend/localsend)
- [KDE Connect](https://invent.kde.org/network/kdeconnect-kde)
- [Syncthing](https://docs.syncthing.net/)
- [RFC 9382：SPAKE2](https://www.rfc-editor.org/rfc/rfc9382)

## 9. 关联文档

- [主题索引](README.md)
- [验证目录](validation/README.md)
