# 根因、结论与限制

> 本文件承载结论摘要、根因逻辑、决策表、限制和不采用方案。
> 原研究文档的章节编号保留，便于后续证据引用。

## 结论摘要

锁屏不是唯一根因。
主要根因是 macOS 登录会话隔离。
主要风险还包括 TCC 授权、WindowServer 输入和电源策略。
当前调用方在 `Background` 会话。
UTM 的图形进程在 `gui/501` 的 `Aqua` 会话。
因此，部分 AppleEvent 可以到达 UTM。
因此，VM 列表、创建、首次连接和输入自动化不可靠。
`utmctl` 依赖 AppleEvent。
`utmctl` 在 `Background` 会话中会超时或失败。
macOS 原生工具不能绕过 TCC。
macOS 原生工具不能伪造已授权的 GUI 会话。
推荐方案是 `VMBridge.app` 加 Aqua LaunchAgent。
`VMBridge` 在 Aqua 会话中启动 GUI 应用。
`VMBridge` 完成首次 AppleEvent 连接。
无界面任务使用 QEMU、QMP、VNC 和串口。
需要宿主 GUI 的任务使用受控的 `host.appleevent`。
已有 UTM VM 使用 `Case 1` 中的 Aqua 桥接路径。
首版只交付文档。
首版不实现代码。
首版不修改数据库、应用 API 和 Helper 协议。

### 决策表

| 需求 | 首选路径 | 原因 | 备选路径 |
| --- | --- | --- | --- |
| 后台创建 GUI 应用 | Aqua 桥接 | 后台进程缺少 GUI 域 | 无界面后端 |
| 后台发送首次 AppleEvent | 解锁后预授权和 Aqua 桥接 | TCC 需要用户交互 | 人工在解锁状态完成 |
| 锁屏后使用已有 UTM VM | UTM 加 Aqua 桥接 | 保留 UTM 管理能力 | UTM Remote Server |
| 锁屏后创建 UTM VM | Aqua 桥接 | AppleEvent 必须到达交互实例 | QEMU 配置生成器 |
| 锁屏后启动无界面 Linux VM | QEMU | 无 GUI 依赖 | Apple Virtualization Framework |
| 客机 GUI 自动化 | VNC 加 QMP | 不依赖宿主 GUI 输入 | 串口和 SSH |
| 宿主 GUI 自动化 | 解锁后执行 | macOS 阻止合成输入 | 无 |
| 盒盖保活 | `caffeinate`、`pmset`、IOKit | 使用系统电源管理 | 外部显示器和电源 |
| 首次 TCC 授权 | 解锁后完成 | 系统要求用户交互 | 无 |
| 注销后自动操作 | 不支持 | Aqua 会话已结束 | 用户重新登录 |

## 7. 根因和逻辑证据链

### 7.1 观察一：调用方不在 Aqua

观察：`launchctl print user/501` 显示 `session = Background`。
观察：`launchctl print user/501` 显示子域包含 `gui/501`。
推论：当前调用方属于用户域，但不属于 Aqua 会话。
置信度：高。

### 7.2 观察二：屏幕已锁定但 Aqua 仍在

观察：`ioreg` 显示 `IOConsoleLocked = Yes`。
观察：`ioreg` 显示 `CGSSessionScreenIsLocked = Yes`。
观察：`launchctl print gui/501` 显示 `session = Aqua`。
推论：锁屏保留 GUI 登录域。
推论：锁屏不是注销。
置信度：高。

### 7.3 观察三：简单 AppleEvent 可达

命令：`osascript -e 'tell application id "com.utmapp.UTM" to get version'`。
结果：返回 `4.7.5`。
推论：简单 AppleEvent 可以到达运行中的 UTM。
推论：AppleEvent 不是全部不可用。
置信度：高。

### 7.4 观察四：VM 访问会阻塞

命令：`osascript -e 'tell application id "com.utmapp.UTM" to get name of every virtual machine'`。
结果：5 秒看门狗超时。
命令：`/Applications/UTM.app/Contents/MacOS/utmctl list`。
结果：5 秒看门狗超时。
推论：复杂 AppleEvent 和 `utmctl` 不稳定。
推论：首次连接和 VM 枚举不能依赖当前调用路径。
置信度：中高。

### 7.5 观察五：UTM 创建依赖脚本接口

源码：`Scripting/UTM.sdef` 定义 AppleScript 命令。
源码：`Scripting/UTMScriptingCreateCommand.swift` 实现创建。
源码：创建逻辑设置 `hasHypervisor`。
源码：创建逻辑设置 `hasUefiBoot`。
源码：创建逻辑添加 64 GiB 磁盘。
源码：创建逻辑删除默认显示和声音。
推论：UTM 新建 VM 的关键路径是 AppleEvent。
置信度：高。

### 7.6 观察六：UTM Remote Server 不支持新建

源码：`Remote/UTMRemoteMessage.swift` 列出远程消息。
源码：消息包含 `startVirtualMachine`。
源码：消息包含 `stopVirtualMachine`。
源码：消息不包含创建 VM。
源码：`Remote/UTMRemoteServer.swift` 只处理已有 VM 控制。
推论：Remote Server 不能替代创建路径。
置信度：高。

### 7.7 观察七：TCC 不能后台绕过

来源：Apple Privacy 和 Security 文档。
事实：Automation、Accessibility、Screen Recording 需要用户授权。
事实：授权弹窗需要交互。
推论：首次授权必须解锁。
推论：无 TCC 的后台服务不能可靠控制 GUI 应用。
置信度：高。

### 7.8 综合根因

根因是跨会话调用。
锁屏放大了跨会话错误。
锁屏不是唯一原因。
UTM 的 AppleEvent 路径需要交互实例。
复杂 AppleEvent 可能阻塞。
TCC 又限制首次连接。
因此，单靠 `utmctl` 不能稳定解决。
因此，需要 Aqua 桥接。
因此，需要无界面后端处理新 VM。

## 19. 限制和未决项

### 19.1 系统限制

登录窗口可能阻止普通用户任务。
FileVault 登录前无 Aqua 用户域。
安全输入模式可能阻止输入。
锁屏策略可能因 macOS 版本变化。
TCC 行为可能因应用签名变化。
TCC 行为可能因调用方变化。
企业 MDM 策略可能拒绝授权。
系统更新可能改变 AppleEvent 行为。
系统更新可能改变 `launchd` 行为。
系统更新可能改变电源行为。

### 19.2 产品限制

`VMBridge` 不是 Apple 官方支持的接口。
`VMBridge` 需要用户安装 LaunchAgent。
`VMBridge` 无法绕过 TCC。
`VMBridge` 无法在注销后保持 Aqua。
`VMBridge` 无法保证宿主 GUI 自动化。
QEMU 集成需要额外维护。
UTM AppleEvent 行为依赖 UTM 版本。
UTM Remote Server 不支持创建 VM。

### 19.3 未决项

VMware Fusion 和 Parallels 需要官方来源补充。
QEMU UEFI 参数需要按 Homebrew 路径验证。
VNC 认证方案需要产品安全评审。
VMBridge 的签名和公证需要发布评审。
`SMAppService` 的迁移需要独立 ADR。
Archboot 安装验证尚未执行。
实际 UTM VM 创建验证尚未执行。
实际盒盖测试尚未执行。
