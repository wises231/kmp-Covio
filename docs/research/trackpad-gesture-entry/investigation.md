# 调研方法与技术分析

> 本文件承载调研方法、系统模型、现有能力矩阵、权限模型、产品分析和方案对比。

## 1. 调研方法

本主题用三步方法。

1. 读 Xcode 27 SDK 头文件，判定公开 API 的边界。头文件是 A 级来源。
2. 读 SDK 里的私有框架存根（`.tbd`），判定私有符号是否存在。存根是 A 级来源。
3. 在本机运行探针，判定私有符号在运行时是否可用。本机实验是 D 级来源。

第 3 步用 `scripts/probe-trackpad-gesture.sh`。脚本有四种模式：`symbols`、`devices`、`accessors` 和 `listen`。
前三种模式已经执行。`listen` 模式需要真人做手势，留给验证案例。

本机没有可用的联网检索。第三方文章和社区讨论没有进入本次调研。这一条记入已知缺口。

## 2. 来源范围

| 等级 | 来源 | 用途 |
| --- | --- | --- |
| A | `MacOSX.sdk/System/Library/Frameworks/AppKit.framework/Headers/NSEvent.h` | 公开事件类型、监视器语义、手势事件能力 |
| A | `MacOSX.sdk/System/Library/Frameworks/CoreGraphics.framework/Headers/CGEventTypes.h` | 事件流字段、滚动相位、事件字段编号 |
| A | `MacOSX.sdk/System/Library/PrivateFrameworks/MultitouchSupport.framework/Versions/A/MultitouchSupport.tbd` | 私有框架的导出符号表 |
| A | `MacOSX.sdk/System/Library/Frameworks/AppKit.framework/Headers/NSGestureRecognizer.h` | 手势识别器的可用版本 |
| B | 本仓库 `macosApp/src/NotchShell/PointerTrackingHost.swift` | 既有权限教训 |
| D | 本机实验，见 [evidence.md](evidence.md) | 运行时事实 |
| E | 无 | 本机没有可用的联网检索 |

## 3. 系统模型

触控板的输入经过四层。

```text
触控板硬件
  -> IOKit HID 驱动
  -> MultitouchSupport 私有框架（每帧接触数据）
  -> WindowServer（手势仲裁、系统手势）
  -> 应用可见的 NSEvent 流
```

关键点是 WindowServer 这一层。WindowServer 读系统手势偏好。
偏好的值决定它是否把手势交给应用。

本机的四指垂直轻扫偏好是 `2`。这个值表示调度中心。WindowServer 因此吞掉这个手势。
应用在 NSEvent 层看不到它。私有的 MultitouchSupport 层在 WindowServer 之下，所以不受影响。

## 4. 现有能力矩阵

| 能力 | 环境 | 用途 | 限制 |
| --- | --- | --- | --- |
| `NSEvent.addLocalMonitorForEvents` | 公开，macOS 10.6+ | 接收本应用窗口内的事件 | 只覆盖本应用。需要窗口在前台。 |
| `NSEvent.addGlobalMonitorForEvents` | 公开，macOS 10.6+ | 接收投递给其他应用的事件副本 | 不含手势事件。键盘事件需要辅助功能权限。 |
| `NSEventTypeGesture` / `NSEventTypeSwipe` | 公开，macOS 10.5+ | 手势事件类型 | 投递给光标下的视图或前台应用。 |
| `NSEvent.trackSwipeEventWithOptions` | 公开，macOS 10.7+ | 把滚动事件当作滑动来跟踪 | 需要本应用先收到滚动事件。 |
| `CGEvent.tapCreate` 监听 `scrollWheel` | 公开 | 全局读取滚动事件 | 需要输入监控权限。分不出手指数。 |
| `MTDeviceCreateList` 等 | 私有 | 读取每帧接触数据 | 私有 API。表面随系统版本变化。 |

## 5. 权限模型

三条路径的权限要求不同。

| 路径 | 权限 | 本机实测 |
| --- | --- | --- |
| 公开 `NSEvent` 本地监视器 | 无 | 不需要 |
| 公开 `NSEvent` 全局监视器，鼠标与手势事件 | 无 | 注册成功，投递范围受限于 WindowServer 仲裁 |
| 公开 `NSEvent` 全局监视器，键盘事件 | 辅助功能 | 未测 |
| `CGEvent.tapCreate` | 输入监控 | 本机 `CGPreflightListenEventAccess()` 为 true |
| 私有 `MTDeviceStart` | 未见权限检查 | 本机成功，但见下方限制 |

限制：本机实验跑在一个已经持有输入监控权限的进程里。
因此实验不能证明私有路径不需要权限。
这一条记入已知缺口，并列入验证案例。

## 6. 目标产品分析

本仓库现有的触发入口有三个。

- 刘海热区。见 `macosApp/src/NotchShell/ScreenGeometry.swift:39` 的 `hotZoneRect`。
- 全局快捷键。见 `macosApp/src/NotchShell/GlobalHotKey.swift:29` 的 Carbon `RegisterEventHotKey`。
- 菜单栏图标。

仓库没有多指手势代码。仓库有意不使用 `NSEvent.addGlobalMonitorForEvents`。
理由写在 `macosApp/src/NotchShell/PointerTrackingHost.swift:6`：
`AXIsProcessTrusted = false` 时全局监视器仍然返回非 nil 的句柄。注册成功不能作为拿到权限的依据。
本次实验复现了这条教训：手势掩码和键盘掩码都返回非 nil。

## 7. 候选方案分析

### 7.1 方案 A：公开 `NSEvent` 手势事件

做法是注册 `addLocalMonitorForEvents(matching: [.swipe, .gesture])`，读 `allTouches` 的手指数。

- 成本：低。
- 成熟度：高，API 自 macOS 10.5 存在。
- 限制：只覆盖本应用窗口。窗口不在前台时收不到。
- 限制：本机四指垂直轻扫被系统占用，事件根本不到应用。
- 证据：`E-02`、`E-08`、`E-09`、`E-15`。

判定：不能单独满足需求。可作为窗口内的补充。

### 7.2 方案 B：`CGEventTap` 监听滚动事件

做法是在 `cgSessionEventTap` 建立只读事件点击，读滚轮事件。

- 成本：中。
- 成熟度：高。
- 限制：需要输入监控权限。权限被拒时应用收不到任何事件。
- 限制：滚轮事件没有手指数。`kCGScrollWheelEventScrollCount` 字段存在，但头文件没有说明它的含义。
- 证据：`E-12`、`E-14`。

判定：不能区分两指滚动与四指滑动。不采用。

### 7.3 方案 C：私有 `MultitouchSupport.framework`

做法是 `dlopen` 私有框架，注册接触帧回调，自己识别手势。

- 成本：中。
- 成熟度：中。第三方工具长期使用这条路径，但苹果不提供任何保证。
- 限制：私有 API。表面随系统版本变化。
- 限制：本机四个 `MTDeviceGet*` 访问器直接崩溃，证明表面不稳定。
- 证据：`E-03`、`E-04`、`E-05`、`E-06`、`E-07`。

判定：采用。这是唯一同时满足“四指”和“应用失焦”的路径。

### 7.4 方案 D：让用户改系统手势设置

做法是引导用户关闭四指垂直轻扫。

- 成本：低。
- 限制：本机实测关闭四指垂直轻扫后，应用仍然收不到该手势。它只是不再触发调度中心。
- 限制：要求用户改系统设置，产品上不可接受。
- 证据：`E-02`。

判定：不采用。

## 8. 参考实现分析

公开资料里，BetterTouchTool 和 Swish 一类工具支持触控板多指手势。
这些工具在 Apple Silicon 机器上工作正常。
本主题没有联网检索能力，因此没有引用这些工具的源码或文档。
本机实验独立验证了同一套私有符号可用。
这一条记入已知缺口。

## 9. 反证和限制

反证一：本机实验跑在有输入监控权限的进程里。私有路径可能也需要权限。
反证二：`MTDeviceStart` 成功不等于能收到四指帧。本次实验的最大手指数是 0，因为没有人触摸触控板。
反证三：SDK 存根只说明符号被声明，不说明运行时被实现。四个 `MTDeviceGet*` 访问器正是这种情况。
反证四：`MTDeviceCreateList` 在 macOS 27 上返回 1 个设备。外接触控板的顺序未测。

## 10. 已知缺口

1. 没有联网检索。第三方实现和苹果官方文档没有进入本次调研。
2. 没有真人手势数据。四指帧的实际内容和识别阈值未测。
3. 私有路径是否需要输入监控权限未测。
4. `kCGScrollWheelEventScrollCount` 的含义未确认。
5. 外接触控板在 `MTDeviceCreateList` 中的顺序未测。
6. 四指下滑与系统调度中心手势的并发行为未测。
