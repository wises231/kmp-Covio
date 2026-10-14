# 证据附录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 审计记录，可复核 |
| 日期 | `2026-10-13` |
| 主文 | [主题索引](README.md) |
| 验证目录 | [验证目录](validation/README.md) |
| 案例 | [Case 1](validation/case-macos-trackpad-gesture.md) |

## 1. 问题类别和案例映射

问题类别：系统保留手势的再获取。
案例：本仓库需要一个四指下滑入口，用来打开挂帘工作台。
案例不定义方案边界。其他应用面对同一类问题时，候选路径相同。

## 2. 来源等级

| 等级 | 来源 | 用途 | 置信度 |
| --- | --- | --- | --- |
| A | Xcode 27 SDK 头文件 `NSEvent.h` | 公开事件类型与监视器语义 | 高 |
| A | Xcode 27 SDK 头文件 `CGEventTypes.h` | 事件字段编号 | 高 |
| A | Xcode 27 SDK 头文件 `NSGestureRecognizer.h` | 手势识别器可用版本 | 高 |
| A | Xcode 27 SDK 存根 `MultitouchSupport.tbd` | 私有框架导出符号表 | 高 |
| B | 本仓库源码 | 既有实现与教训 | 高 |
| D | 本机实验 | 运行时事实 | 高，但只代表本机 |
| E | 无 | 本机没有可用的联网检索 | 不适用 |

## 3. 环境事实

| 项目 | 值 | 命令 | 置信度 |
| --- | --- | --- | --- |
| 系统版本 | macOS 27.0.1，构建号 26A434 | `sw_vers` | 高 |
| 机型 | MacBook Pro 18,2 | `system_profiler SPHardwareDataType` | 高 |
| 芯片 | Apple M1 Max | `system_profiler SPHardwareDataType` | 高 |
| SDK 路径 | `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk` | `xcrun --show-sdk-path` | 高 |
| Swift 版本 | 6.4 | `swift --version` | 高 |
| 触控板设备数 | 1，内建 | `bash scripts/probe-trackpad-gesture.sh devices` | 高 |

## 4. 复现命令

```sh
sw_vers
system_profiler SPHardwareDataType
xcrun --show-sdk-path

defaults read com.apple.AppleMultitouchTrackpad | grep -iE "swipe|gesture"

bash scripts/probe-trackpad-gesture.sh symbols
bash scripts/probe-trackpad-gesture.sh devices
bash scripts/probe-trackpad-gesture.sh accessors
bash scripts/probe-trackpad-gesture.sh listen 20
```

最后一条会启动内建触控板并采集接触帧。它需要真人做手势。

## 5. 证据索引

| 编号 | 主题 | 来源 | 结论 | 置信度 |
| --- | --- | --- | --- | --- |
| E-01 | 本机环境 | D | macOS 27.0.1，Apple M1 Max | 高 |
| E-02 | 系统手势偏好 | D | 四指垂直轻扫绑定调度中心 | 高 |
| E-03 | 私有框架可加载 | D | 17 个核心符号全部存在 | 高 |
| E-04 | SDK 存根声明私有符号 | A | 存根列出 `_MTDeviceCreateList` 等符号 | 高 |
| E-05 | 设备枚举 | D | 返回 1 个内建设备 | 高 |
| E-06 | 设备启动 | D | 状态 0 变为 1，框架识别设备 | 高 |
| E-07 | 访问器崩溃 | D | 4 个 `MTDeviceGet*` 以信号 11 退出 | 高 |
| E-08 | 公开手势事件类型 | A | `NSEventTypeGesture` 与 `NSEventTypeSwipe` 是公开 API | 高 |
| E-09 | 旧手势事件已废弃 | A | `BeginGesture` 与 `EndGesture` 不再投递 | 高 |
| E-10 | 全局监视器语义 | A | 注释只对键盘事件提权限要求 | 高 |
| E-11 | 监视器返回值 | D | 手势掩码与键盘掩码都返回非 nil | 高 |
| E-12 | 输入监控权限 | D | `CGPreflightListenEventAccess` 为 true | 高 |
| E-13 | 新版系统无全局手势 API | A | macOS 26 与 27 的新增手势 API 都不提供全局入口 | 中高 |
| E-14 | 滚轮事件字段 | A | `kCGScrollWheelEventScrollCount` 存在但无说明 | 中 |
| E-15 | 手势事件带触摸对象 | A | `allTouches` 对手势事件有效 | 高 |
| E-16 | 仓库既有教训 | B | 未授权时全局监视器仍返回非 nil | 高 |

## 6. 证据详情

### E-01：本机环境

来源等级：D
环境：本机开发机
命令或来源：`sw_vers`、`system_profiler SPHardwareDataType`、`xcrun --show-sdk-path`
关键输出：

```text
ProductName:    macOS
ProductVersion: 27.0.1
BuildVersion:   26A434
Model Identifier: MacBookPro18,2
Chip: Apple M1 Max
Target: arm64-apple-macosx27.0.0
```

观察：本机是 Apple Silicon，系统版本 27.0.1。
推论：本机实验结论适用于 macOS 27 与 Apple Silicon。
反证：无。
限制：单机单版本。不能外推到 Intel 或其他系统版本。
置信度：高
关联：全部本机实验

### E-02：系统手势偏好

来源等级：D
环境：本机用户偏好域
命令或来源：`defaults read com.apple.AppleMultitouchTrackpad`
关键输出：

```text
TrackpadFourFingerVertSwipeGesture = 2;
TrackpadFourFingerHorizSwipeGesture = 2;
TrackpadFourFingerPinchGesture = 2;
TrackpadThreeFingerVertSwipeGesture = 0;
TrackpadThreeFingerHorizSwipeGesture = 0;
TrackpadThreeFingerTapGesture = 0;
TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
```

观察：四指垂直轻扫的值是 `2`。三指垂直轻扫和三指水平轻扫的值都是 `0`。
推论：WindowServer 把四指垂直轻扫保留给系统功能。三指轻扫未被占用。
反证：偏好的数值含义来自系统设置的界面文案对应关系，没有苹果文档直接确认。
限制：偏好值到系统功能的映射没有 A 级来源。这一条是推论，不是事实。
置信度：中高
关联：`E-06`、验证 `V03`

### E-03：私有框架可加载

来源等级：D
环境：本机，macOS 27.0.1
命令或来源：`bash scripts/probe-trackpad-gesture.sh symbols`
关键输出：

```text
MTDeviceCreateList                             存在
MTDeviceCreateDefault                          存在
MTDeviceStart                                  存在
MTDeviceStop                                   存在
MTDeviceIsRunning                              存在
MTRegisterContactFrameCallback                 存在
MTUnregisterContactFrameCallback               存在
```

观察：`dlopen` 成功。17 个查询的符号全部存在。
推论：私有框架在 macOS 27 上仍然存在并可加载。
反证：符号存在不等于实现存在。见 `E-07`。
限制：只代表 macOS 27.0.1。
置信度：高
关联：`E-04`、`E-06`

补充：框架目录里只有 `Resources` 和 `_CodeSignature`，没有二进制文件。
原因是系统框架的二进制存放在 dyld 共享缓存里。
因此不能用 `ls` 或 `nm` 判断可用性，只能用 `dlopen`。

### E-04：SDK 存根声明私有符号

来源等级：A
环境：Xcode 27 SDK
命令或来源：`MacOSX.sdk/System/Library/PrivateFrameworks/MultitouchSupport.framework/Versions/A/MultitouchSupport.tbd`
关键输出：

```text
install-name:    '/System/Library/PrivateFrameworks/MultitouchSupport.framework/Versions/A/MultitouchSupport'
current-version: 10400.44
symbols:         [ ... _MTDeviceCreateList, _MTDeviceCreateListFromDeviceUsagePairs,
                   _MTRegisterContactFrameCallback, _MTRegisterContactFrameCallbackWithRefcon,
                   _MTDeviceStart, _MTDeviceStop, ... ]
```

观察：SDK 提供私有框架的存根库，版本号 10400.44，符号表完整。
推论：可以在构建时用 `-framework MultitouchSupport` 链接私有框架。
反证：存根只描述链接期的符号表，不描述运行时的实现。
限制：存根随 Xcode 版本变化。
置信度：高
关联：`E-03`、`E-07`

### E-05：设备枚举

来源等级：D
环境：本机，内建触控板
命令或来源：`bash scripts/probe-trackpad-gesture.sh devices`
关键输出：

```text
设备数：1
  [0] 内建=1 运行中=0 可用=1
```

观察：`MTDeviceCreateList` 返回 1 个设备，该设备是内建的，可用。
推论：私有路径能拿到本机触控板句柄。
反证：外接触控板未测。
限制：设备顺序不保证稳定。
置信度：高
关联：`E-06`

### E-06：设备启动

来源等级：D
环境：本机，内建触控板
命令或来源：`bash scripts/probe-trackpad-gesture.sh listen 1`
关键输出：

```text
*** Recognized (0x69) family*** (30 cols X 22 rows)
已启动。运行中=1。
汇总
  总帧数：0
  最大手指数：0
```

观察：`MTDeviceStart` 后 `MTDeviceIsRunning` 返回 1。框架打印设备识别信息。
采集期间没有人触摸触控板，所以帧数为 0。
推论：私有路径的启动链路完整可用。接触帧的采集需要真人验证。
反证：帧数为 0。本证据只证明启动成功，不证明能收到四指帧。
限制：本次运行的进程已经持有输入监控权限。无法区分私有路径是否需要该权限。
置信度：高（对启动链路），低（对帧采集）
关联：`E-03`、`E-12`、验证 `V01`

### E-07：访问器崩溃

来源等级：D
环境：本机，macOS 27.0.1
命令或来源：`bash scripts/probe-trackpad-gesture.sh accessors`
关键输出：

```text
MTDeviceIsBuiltIn              1        正常
MTDeviceIsRunning              0        正常
MTDeviceIsAlive                0        正常
MTDeviceIsAvailable            1        正常
MTDeviceGetFamilyID            139      崩溃（信号 11）
MTDeviceGetDeviceID            139      崩溃（信号 11）
MTDeviceGetTransportMethod     139      崩溃（信号 11）
MTDeviceGetVersion             139      崩溃（信号 11）
```

观察：四个 `MTDeviceGet*` 访问器以信号 11 退出。四个 `MTDeviceIs*` 判定函数正常。
推论：私有符号的存在不等于实现的存在。实现必须限制调用范围。
反证：崩溃可能来自调用约定不匹配，而不一定是函数未实现。两种原因都要求不调用这些函数。
限制：只测了 8 个符号。其余符号未测。
置信度：高
关联：`E-04`、[solution.md](solution.md) 第 1.2 节

### E-08：公开手势事件类型

来源等级：A
环境：Xcode 27 SDK
命令或来源：`grep -nE "Swipe|Gesture" MacOSX.sdk/System/Library/Frameworks/AppKit.framework/Headers/NSEvent.h`
关键输出：

```text
NSEventTypeGesture API_AVAILABLE(macos(10.5)) = 29,
NSEventTypeSwipe   API_AVAILABLE(macos(10.5)) = 31,
NSEventMaskGesture API_AVAILABLE(macos(10.5)) = 1ULL << NSEventTypeGesture,
NSEventMaskSwipe   API_AVAILABLE(macos(10.5)) = 1ULL << NSEventTypeSwipe,
```

观察：手势与滑动事件类型是公开 API，自 macOS 10.5 存在。
推论：应用可以声明对手势事件感兴趣。投递范围是另一个问题。
反证：无。
限制：头文件不描述投递范围。
置信度：高
关联：`E-10`、`E-15`

### E-09：旧手势事件已废弃

来源等级：A
环境：Xcode 27 SDK
命令或来源：`NSEvent.h`
关键输出：

```text
NSEventTypeBeginGesture API_DEPRECATED("NSEventTypeBeginGesture is no longer delivered.
  Use the phase property on NSEvent or NSGestureRecognizer instead.", macos(10.5, ...)) = 19,
NSEventTypeEndGesture   API_DEPRECATED("NSEventTypeEndGesture is no longer delivered. ...") = 20,
```

观察：开始手势与结束手势事件不再投递。
推论：手势的起止必须用 `phase` 属性或 `NSGestureRecognizer` 判断。
反证：无。
限制：无。
置信度：高
关联：`E-08`

### E-10：全局监视器语义

来源等级：A
环境：Xcode 27 SDK
命令或来源：`NSEvent.h:545`
关键输出：

```text
Use +addGlobal to install an event monitor that receives copies of events posted to other
applications. Events are delivered asynchronously to your app and you can only observe the
event; you cannot modify or otherwise prevent the event from being delivered to its original
target application. Key-related events may only be monitored if accessibility is enabled or
if your application is trusted for accessibility access (see AXIsProcessTrusted in
AXUIElement.h). Note that your handler will not be called for events that are sent to your
own application.
```

观察：注释只对键盘事件提出辅助功能权限要求。注释没有提到手势事件。
推论：头文件层面没有禁止全局监视手势事件。但注释也没有承诺投递手势事件。
反证：注释不是完整规范。缺少对手势事件的说明不等于允许。
限制：本机没有联网检索，无法核对苹果在线文档的补充说明。
置信度：中高
关联：`E-11`、`E-13`

### E-11：监视器返回值

来源等级：D
环境：本机，Swift 6.4
命令或来源：`NSEvent.addGlobalMonitorForEvents(matching:)` 与 `addLocalMonitorForEvents(matching:)`
关键输出：

```text
addGlobalMonitorForEvents(swipe/gesture/scrollWheel) -> non-nil
addGlobalMonitorForEvents(keyDown)                  -> non-nil
addLocalMonitorForEvents(swipe/gesture/scrollWheel) -> non-nil
```

观察：全局监视器对手势掩码和键盘掩码都返回非 nil 的对象。
推论：返回值不能用来判断权限。
反证：无。
限制：本进程已经持有输入监控权限，所以本实验不能区分“未授权时是否也返回非 nil”。
仓库的 `E-16` 在未授权环境下观察到同样的行为。
置信度：高
关联：`E-16`、[solution.md](solution.md) 第 3.1 节

### E-12：输入监控权限

来源等级：D
环境：本机
命令或来源：`CGPreflightListenEventAccess()`、`CGEvent.tapCreate`
关键输出：

```text
CGPreflightListenEventAccess = true
CGPreflightPostEventAccess   = true
CGEvent.tapCreate(scrollWheel, listenOnly)          -> non-nil
```

观察：本进程持有输入监控权限，可以建立只读事件点击。
推论：`CGEventTap` 路径在本机可用。
反证：本进程的权限状态不代表新装应用的权限状态。
限制：本实验不能证明私有路径不需要权限。这一条是本次调研最大的缺口。
置信度：高（对本进程），不适用（对私有路径的权限要求）
关联：`E-06`、验证 `V05`

### E-13：新版系统无全局手势 API

来源等级：A
环境：Xcode 27 SDK
命令或来源：`grep -nE "API_AVAILABLE\(macos\((26|27)" NSEvent.h NSGestureRecognizer.h`
关键输出：

```text
NSEvent.h:64:  NSEventTypeMouseCancelled API_AVAILABLE(macos(26.0)) = 40,
NSEvent.h:496: @property (class, readonly, getter=isTouchSwipeNavigationEnabled)
                 BOOL touchSwipeNavigationEnabled API_AVAILABLE(macos(27));
NSGestureRecognizer.h:77: @property (getter=isCancellableByScrollGesture)
                            BOOL cancellableByScrollGesture API_AVAILABLE(macos(27.0));
NSGestureRecognizer.h:84: @property (nullable, copy) NSString *name API_AVAILABLE(macos(26.0));
NSGestureRecognizer.h:85: @property (readonly) NSEventModifierFlags modifierFlags API_AVAILABLE(macos(26.0));
```

观察：macOS 26 与 27 新增的手势相关 API 有五个。没有一个提供全局多指手势入口。
`touchSwipeNavigationEnabled` 是只读偏好查询，不是事件入口。
推论：不能指望新系统版本提供公开的全局手势入口。
反证：SDK 只覆盖 AppKit 和 CoreGraphics 的两个头文件。其他框架未扫描。
限制：扫描范围是 `NSEvent.h` 和 `NSGestureRecognizer.h`。
置信度：中高
关联：`E-08`、`E-10`

### E-14：滚轮事件字段

来源等级：A
环境：Xcode 27 SDK
命令或来源：`CGEventTypes.h`
关键输出：

```text
kCGScrollWheelEventScrollPhase = 99,
/* rdar://11259169 */
kCGScrollWheelEventScrollCount = 100,
kCGScrollWheelEventMomentumPhase = 123,
```

观察：存在一个编号 100 的字段 `kCGScrollWheelEventScrollCount`。头文件只有一条内部缺陷编号，没有说明。
推论：该字段可能携带手指数或事件合并数。含义未确认。
反证：字段存在不等于被填充。
限制：头文件无说明。本机无法用真实滚动事件验证字段内容。
置信度：中
关联：[investigation.md](investigation.md) 第 7.2 节

### E-15：手势事件带触摸对象

来源等级：A
环境：Xcode 27 SDK
命令或来源：`NSEvent.h`
关键输出：

```text
/* Only valid for NSEventTypeGesture events. Equivalent to
   [event touchesMatchingPhase:NSTouchPhaseAny inView:nil] */
- (NSSet <NSTouch *> *)allTouches API_AVAILABLE(macos(10.12));
```

观察：`allTouches` 对手势事件有效，返回 `NSTouch` 集合。
推论：公开手势事件带手指数和每指位置。前提是应用能收到该事件。
反证：无。
限制：前提是投递成功。
置信度：高
关联：`E-08`、`E-10`

### E-16：仓库既有教训

来源等级：B
环境：本仓库，`feature/swiftui-macos` 分支
命令或来源：`macosApp/src/NotchShell/PointerTrackingHost.swift:6`
关键输出：

```text
/// 为什么不用全局鼠标监听：M0 实测在 `AXIsProcessTrusted = false` 时
/// `NSEvent.addGlobalMonitorForEvents` 仍然返回非 nil 的 token。
/// 注册成功不能作为拿到权限的依据。窗口自己的 tracking area 不依赖辅助功能权限。
/// 见 `docs/adr/adr-0001-macos-ui-swiftui.md` 实测 10。
```

观察：仓库在未授权环境下实测过同样的行为，并因此不使用全局监视器。
推论：本次 `E-11` 的结果与仓库既有结论一致。
反证：无。
限制：以上是源码注释的原文引用。原文里的“token”指监视器返回的不透明对象，不是凭据。
第 16.5 节的敏感信息检查会命中这个词，属于误报。
置信度：高
关联：`E-11`

## 7. 逻辑证据链

```text
研究问题：应用能否全局检测四指下滑
  -> 来源 A：SDK 头文件没有全局手势入口（E-08、E-09、E-10、E-13）
  -> 来源 D：系统偏好把四指垂直轻扫绑给调度中心（E-02）
  -> 观察：公开层无法交付
  -> 来源 A：SDK 存根声明私有符号（E-04）
  -> 来源 D：私有框架可加载、可枚举、可启动（E-03、E-05、E-06）
  -> 观察：私有层可以交付
  -> 来源 D：部分私有访问器崩溃（E-07）
  -> 决策：只用四个核心函数，并提供降级路径
  -> 验证条件：V01 到 V06，见 validation/README.md
  -> 回填位置：conclusion.md 第 1 节、solution.md 第 7 节
```

## 8. 反证和限制

1. 私有路径的权限要求未测。本次实验的进程已经持有输入监控权限。
2. 四指帧的实际内容未测。`E-06` 的最大手指数是 0。
3. `E-02` 的偏好值到系统功能的映射是推论，没有 A 级来源。
4. `E-13` 的扫描范围只覆盖两个头文件。
5. `E-14` 的字段含义未确认。
6. 本机没有联网检索。苹果在线文档和第三方实现没有进入本次调研。

## 9. 已知缺口

| 编号 | 缺口 | 影响 | 补齐方式 |
| --- | --- | --- | --- |
| `G-01` | 私有路径的权限要求 | 决定是否需要申请输入监控 | 验证 `V05` |
| `G-02` | 四指帧的采样率与内容 | 决定识别阈值是否可行 | 验证 `V01` |
| `G-03` | 偏好值到系统功能的映射 | 影响 `E-02` 的置信度 | 人工核对系统设置界面 |
| `G-04` | 苹果在线文档 | 缺少 C 级来源 | 有网络后补 |
| `G-05` | 外接触控板的枚举顺序 | 影响多设备注册 | 验证 `V06` |
| `G-06` | 系统手势与应用的并发行为 | 影响用户体验 | 验证 `V03` |

## 10. 复核方法

1. 运行 `bash scripts/probe-trackpad-gesture.sh symbols`，核对 17 个符号。
2. 运行 `bash scripts/probe-trackpad-gesture.sh devices`，核对设备数。
3. 运行 `bash scripts/probe-trackpad-gesture.sh accessors`，核对四个崩溃。
4. 运行 `bash scripts/probe-trackpad-gesture.sh listen 20`，做四指下滑，核对帧数。
5. 用 `xcrun --show-sdk-path` 定位 SDK，重跑第 4 节的 `grep` 命令。
6. 按 [validation/case-macos-trackpad-gesture.md](validation/case-macos-trackpad-gesture.md) 回填结果。

## 参考来源

本机没有可用的联网检索，因此本文件不列 URL。全部来源是本地文件。

- Xcode 27 SDK：`MacOSX.sdk/System/Library/Frameworks/AppKit.framework/Headers/NSEvent.h`
- Xcode 27 SDK：`MacOSX.sdk/System/Library/Frameworks/AppKit.framework/Headers/NSGestureRecognizer.h`
- Xcode 27 SDK：`MacOSX.sdk/System/Library/Frameworks/CoreGraphics.framework/Headers/CGEventTypes.h`
- Xcode 27 SDK 存根：`MacOSX.sdk/System/Library/PrivateFrameworks/MultitouchSupport.framework/Versions/A/MultitouchSupport.tbd`
- 本仓库：`macosApp/src/NotchShell/PointerTrackingHost.swift`
- 本仓库：`scripts/probe-trackpad-gesture.sh`

## 11. 关联文档

- [主题索引](README.md)
- [验证目录](validation/README.md)
- [案例](validation/case-macos-trackpad-gesture.md)
