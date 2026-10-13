# 根因、结论与限制

> 本文件承载结论摘要、根因、决策表、限制和不采用方案。

## 1. 结论摘要

四指下滑**可交付**。交付路径是私有 `MultitouchSupport.framework`。
公开 API 没有全局多指手势入口。系统把四指垂直轻扫保留给调度中心。
私有框架在本机可加载、可枚举设备、可启动、可注册接触帧回调。
私有框架的表面不稳定。本机四个 `MTDeviceGet*` 访问器直接崩溃。
因此实现必须只用四个核心函数，并且必须提供降级路径。
降级路径是刘海悬停、全局快捷键和菜单栏图标。

置信度：主结论高。副结论（私有路径不需要权限）未验证，标记为假设。

## 2. 根因或决策因素

### 2.1 主要因素

**因素一：系统占用四指垂直轻扫。**

本机偏好 `TrackpadFourFingerVertSwipeGesture = 2`。值 `2` 表示调度中心。
WindowServer 读这个偏好，并把手势交给调度中心。
应用在 NSEvent 层看不到这个手势。
证据：`E-02`。

**因素二：公开 API 没有全局多指手势入口。**

`NSEventTypeGesture` 和 `NSEventTypeSwipe` 是公开 API，但它们投递给光标下的视图。
全局监视器不含手势事件。SDK 注释只对键盘事件提出辅助功能权限要求，对手势事件只说投递范围。
macOS 26 与 27 没有新增全局多指手势接口。新增的手势相关 API 只有
`NSGestureRecognizer.name`、`NSGestureRecognizer.modifierFlags`、`cancellableByScrollGesture`
和 `NSEvent.touchSwipeNavigationEnabled`。这四个都不提供全局入口。
证据：`E-08`、`E-09`、`E-10`、`E-13`、`E-15`。

**因素三：私有框架在本机可用。**

私有框架可 `dlopen`。`MTDeviceCreateList` 返回 1 个内建设备。
`MTRegisterContactFrameCallback` 和 `MTDeviceStart` 成功。
启动后设备状态从 0 变为 1。框架打印 `Recognized (0x69) family (30 cols X 22 rows)`。
这条路径在 WindowServer 之下，因此不受系统手势偏好影响。
证据：`E-03`、`E-04`、`E-05`、`E-06`。

### 2.2 次要因素

**因素四：私有表面不稳定。**

`MTDeviceGetFamilyID`、`MTDeviceGetDeviceID`、`MTDeviceGetTransportMethod` 和 `MTDeviceGetVersion`
在本机全部以信号 11 崩溃。符号在 SDK 存根里存在，在运行时却没有实现。
证据：`E-07`。

**因素五：监视器的返回值不能证明权限。**

本仓库已经在 `PointerTrackingHost.swift:6` 记录过这条教训。
本次实验复现：手势掩码和键盘掩码都返回非 nil 的句柄。
证据：`E-11`、`E-16`。

## 3. 决策表

| 决策 | 选择 | 原因 | 备选路径 |
| --- | --- | --- | --- |
| 手势入口的实现层 | 私有 `MultitouchSupport.framework` | 唯一同时满足四指和应用失焦 | 刘海悬停、快捷键、菜单栏图标 |
| 是否要求用户改系统手势偏好 | 不要求 | 改动系统设置不可接受，且改后应用仍收不到手势 | 无 |
| 是否用 `CGEventTap` 识别手势 | 不用 | 滚轮事件没有手指数 | 只用于读取滚动，不用于识别手势 |
| 调用的私有函数范围 | 只限 `MTDeviceCreateList`、`MTRegisterContactFrameCallback`、`MTDeviceStart`、`MTDeviceStop` | 其余访问器在本机崩溃 | 无 |
| 私有路径失效时的行为 | 启动时检测，降级到其余入口 | 用户不能因为一次系统升级失去全部入口 | 无 |
| 手势识别的输入 | 手指数、归一化位置、时间戳 | 私有帧直接提供这三项 | 无 |

## 4. 逻辑证据链

### 4.1 观察一：系统占用四指垂直轻扫

观察：`defaults read com.apple.AppleMultitouchTrackpad` 返回 `TrackpadFourFingerVertSwipeGesture = 2`。
推论：WindowServer 把四指垂直轻扫交给调度中心，应用收不到该手势。
置信度：高。
证据：`E-02`。

### 4.2 观察二：公开 API 没有全局手势入口

观察：SDK 头文件里 `NSEventTypeGesture` 和 `NSEventTypeSwipe` 存在，但没有对应的全局投递保证。
macOS 26 与 27 的新增手势 API 没有一个提供全局入口。
推论：公开 API 无法满足需求。
置信度：中高。
证据：`E-08`、`E-09`、`E-13`。

### 4.3 观察三：私有路径可启动

观察：`MTDeviceStart` 后 `MTDeviceIsRunning` 返回 1。框架打印设备识别信息。
推论：私有路径的启动链路在本机完整可用。
置信度：高。
证据：`E-06`。

### 4.4 观察四：私有表面部分失效

观察：四个 `MTDeviceGet*` 访问器以信号 11 退出。
推论：私有符号的存在不等于实现的存在。实现必须限制调用范围，并容忍崩溃。
置信度：高。
证据：`E-07`。

### 4.5 观察五：返回值不证明权限

观察：`addGlobalMonitorForEvents` 对手势掩码和键盘掩码都返回非 nil。
推论：实现不能用返回值判断权限。权限判断必须用 `AXIsProcessTrusted` 或 `CGPreflightListenEventAccess`。
置信度：高。
证据：`E-11`、`E-16`。

## 5. 限制和未决项

### 5.1 系统限制

1. 四指垂直轻扫在系统偏好里默认被占用。应用无法从公开层取得它。
2. 私有框架不提供任何兼容性承诺。任何系统升级都可能改变它。
3. 私有框架的部分函数在本机已经失效。

### 5.2 产品限制

1. 应用不能上架 Mac App Store。私有 API 会被审核拒绝。
2. 应用必须准备一套不依赖手势的入口。用户在没有触控板的机器上只能使用这些入口。
3. 手势识别阈值必须可调。不同用户的四指动作差异大。

### 5.3 未决项

1. 私有路径是否需要输入监控权限。本次实验的进程已经持有该权限，无法区分。
2. 四指帧的实际采样率和内容未测。
3. 识别阈值的取值未定。
4. 四指下滑与调度中心手势是否并发触发未测。
5. 外接触控板的枚举顺序未测。
6. 私有路径失效时是启动时检测还是运行时检测。
7. 是否把“关闭系统四指手势”写进产品引导。

## 6. 不采用方案

| 方案 | 风险 | 不采用原因 |
| --- | --- | --- |
| 要求用户改系统手势偏好 | 产品体验差。改后应用仍收不到手势。 | 不能解决问题 |
| `CGEventTap` 读滚轮事件识别手势 | 滚轮事件没有手指数，无法区分两指与四指 | 能力不足 |
| 只用公开 `NSEvent` 手势事件 | 只覆盖前台窗口，且被系统手势占用 | 能力不足 |
| 依赖 `MTDeviceGet*` 访问器读取设备属性 | 本机已崩溃 | 直接导致崩溃 |
| 用 `NSEvent.addGlobalMonitorForEvents` 判断权限 | 未授权时也返回非 nil | 判断不可靠 |
