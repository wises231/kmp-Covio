# 调研过程与技术边界

> 本文件承载调研方法、会话模型、原生工具、TCC、UTM、无界面后端和市场对比。
> 原研究文档的章节编号保留，便于后续证据引用。

## 3. 调研方法和证据等级

### 3.1 来源优先级

1. 使用 Apple 官方文档和本机 `man` 页面。
2. 使用 UTM 源码和固定 commit。
3. 使用 UTM、QEMU 和虚拟化项目的官方仓库。
4. 使用上游 issue 和 pull request。
5. 使用本机可重放实验。
6. 使用厂商文档作为市场对比资料。

### 3.2 证据字段

每条证据应有命令。
每条证据应有执行时间。
每条证据应有输出摘要。
每条证据应有解释。
每条证据应有推论。
每条证据应有置信度。
证据附录记录命令和输出。
证据附录不记录密码和令牌。

### 3.3 事实边界

本机事实只代表当前环境。
当前环境为 Apple Silicon。
当前环境为 macOS 27.0.1。
当前环境为 UTM 4.7.5。
当前环境为 `MacBookPro18,2`。
Intel Mac 行为可能不同。
旧版 macOS 行为可能不同。
UTM 新版本行为可能不同。
企业 MDM 策略可能改变行为。
FileVault 登录窗口可能改变行为。
安全输入模式可能改变输入行为。
因此，发布前必须运行验收测试。

## 4. macOS 会话模型

### 4.1 `launchd` 域

| 域 | 用途 | GUI 能力 | 生命周期 |
| --- | --- | --- | --- |
| `system` | 系统服务 | 无用户 GUI | 系统启动到关机 |
| `user/<uid>` | 用户域 | 取决于子域 | 用户登录期间 |
| `gui/<uid>` | Aqua GUI 域 | 有 Aqua 连接 | GUI 登录期间 |
| `session/<asid>` | 登录会话域 | 由会话类型决定 | 会话期间 |
| `pid/<pid>` | 进程域 | 继承目标进程 | 目标进程期间 |

`user/501` 可以包含 `gui/501` 子域。
但 `user/501` 的当前会话不一定是 Aqua。
本机 `launchctl print user/501` 显示 `session = Background`。
本机 `launchctl print gui/501` 显示 `session = Aqua`。
因此，调用方必须区分用户域和 GUI 域。

### 4.2 `launchctl` 工具

`launchctl asuser <uid> <program>` 进入用户 bootstrap。
`asuser` 不保证进入 Aqua 域。
`launchctl bsexec <pid> <program>` 进入目标进程的 bootstrap。
`bsexec` 不修改 UID 和 GID。
`bsexec` 不继承环境变量。
`launchctl print gui/501` 可以检查 Aqua 域。
`launchctl print user/501` 可以检查用户域。
`launchctl print pid/<pid>` 可以检查目标进程上下文。

### 4.3 LaunchAgent

`LaunchAgent` 可以安装到用户目录。
路径为 `~/Library/LaunchAgents/`。
`LimitLoadToSessionType = Aqua` 限定 GUI 会话。
`RunAtLoad` 控制加载时启动。
`KeepAlive` 控制退出后重启。
`Sockets` 支持按需启动。
`MachServices` 提供 Mach 服务名。
Aqua agent 随 GUI 登录加载。
Background agent 可在 GUI 登录前加载。
因此，UTM 桥接必须使用 Aqua 类型。

### 4.4 `SMAppService`

macOS 13 和后续版本提供 `SMAppService`。
`SMAppService.agent` 可以注册登录项。
`SMAppService.daemon` 可以注册系统服务。
注册后仍需检查会话类型。
注册后仍需检查 TCC。
注册后仍需检查 LaunchAgent 状态。
首版使用 LaunchAgent。
`SMAppService` 作为后续产品化候选。

### 4.5 会话隔离结论

Aqua agent 可以访问 WindowServer。
Aqua agent 可以接收 AppleEvent。
Aqua agent 可以启动 GUI 应用。
Background 进程不能可靠使用 GUI 服务。
Background 进程不能可靠发送合成输入。
锁屏会保留 Aqua 会话。
锁屏会阻止用户输入。
锁屏不会自动把 Background 进程加入 Aqua。
因此，桥接进程必须提前加载。

## 5. macOS 原生工具能力矩阵

| 工具或 API | 锁屏后可用性 | 主要限制 | 推荐用途 |
| --- | --- | --- | --- |
| `launchd` 用户域 | 可用 | 不保证 Aqua | 管理后台任务 |
| `launchd` GUI 域 | 通常可用 | 需要登录会话 | 承载 Aqua 桥接 |
| `launchctl asuser` | 可用 | 不保证 Aqua | 用户域操作 |
| `launchctl bsexec` | 条件可用 | 目标进程必须存在 | 复用目标上下文 |
| Aqua LaunchAgent | 通常可用 | 注销后卸载 | 启动桥接 |
| `SMAppService` | 条件可用 | 仍受会话和 TCC 限制 | 产品化注册 |
| `osascript` | 条件可用 | 目标应用和 TCC 决定结果 | 发送 AppleEvent |
| AppleEvent | 条件可用 | 复杂访问可能阻塞 | 控制 UTM |
| Accessibility | 锁屏下不可靠 | 禁止后台绕过 | 解锁后 GUI 自动化 |
| Screen Recording | 锁屏下有限 | 权限和显示上下文限制 | 解锁后截图 |
| `caffeinate` | 可用 | 只创建电源断言 | 防止空闲睡眠 |
| `pmset` | 可用 | 全局修改需要 root | 电源状态和断言 |
| IOKit | 可用 | 需要正确匹配服务 | 监听盒盖和电源事件 |
| QEMU QMP | 通常可用 | 不是 macOS 原生工具 | 无界面 VM 控制 |
| QEMU VNC | 通常可用 | 需要本机绑定和认证 | 客机 GUI 和输入 |

## 6. 权限和 TCC 模型

### 6.1 Automation

Automation 权限允许应用发送 AppleEvent。
Automation 权限弹窗需要用户交互。
锁屏时不能可靠显示并批准弹窗。
SSH 进程不能代替用户批准。
`osascript` 的调用方可能触发 Automation 检查。
审批对象通常是调用应用和发送目标。
因此，首次调用应在解锁状态完成。

### 6.2 Accessibility

Accessibility 权限允许读取和控制系统 UI。
Accessibility 权限不能由后台进程绕过。
锁屏时系统 UI 不可操作。
合成宿主键盘和鼠标输入不可靠。
客机输入应走 UTM 或 VNC。
宿主 GUI 自动化应在解锁后执行。

### 6.3 Screen Recording

Screen Recording 权限允许捕获屏幕内容。
授权弹窗需要用户交互。
锁屏后屏幕内容不是普通桌面。
客机截图应使用 VNC 或 QEMU。
宿主桌面截图应标记为锁屏后不支持。

### 6.4 Full Disk Access

Full Disk Access 允许读取受保护文件。
Full Disk Access 不授予 GUI 会话。
Full Disk Access 不授予 AppleEvent 权限。
Full Disk Access 不授予 Accessibility。
因此，Full Disk Access 不能解决本问题。

### 6.5 TCC 结论

TCC 是用户授权边界。
原生工具不能绕过 TCC。
桥接进程不能绕过 TCC。
服务不能绕过 TCC。
安装器不能静默获得 TCC。
产品必须在解锁状态完成引导。
产品必须在锁屏前验证权限。

## 8. Case 1：UTM 分析

### 8.1 UTM 版本和包

本机 UTM 路径为 `/Applications/UTM.app`。
本机 UTM 版本为 `4.7.5`。
本机 `utmctl` 路径为 `/Applications/UTM.app/Contents/MacOS/utmctl`。
UTM 文档包使用 `.utm` 目录包。
主配置为 `config.plist`。
数据目录为 `Data`。
QEMU 配置版本为 `4`。
QEMU 后端值为 `QEMU`。

### 8.2 AppleScript 能力

AppleScript 支持创建 VM。
AppleScript 支持导入 VM。
AppleScript 支持启动 VM。
AppleScript 支持停止 VM。
AppleScript 支持删除 VM。
AppleScript 支持读取和更新配置。
AppleScript 支持输入键盘。
AppleScript 支持输入鼠标点击。
键盘和鼠标输入只支持 QEMU 后端。
AppleScript 不能保证锁屏时可靠。
AppleScript 首次调用需要正确会话和 TCC。

### 8.3 `utmctl` 能力

`utmctl` 使用 ScriptingBridge。
`ScriptingBridge` 使用 AppleEvent。
`utmctl` 不是独立 VM 管理进程。
`utmctl` 依赖 UTM 的交互实例。
`utmctl` 在 SSH 会话中可能失败。
本机测试中 `utmctl list` 超时。
因此，`utmctl` 不应作为唯一后台接口。

### 8.4 UTM Remote Server

Remote Server 使用消息协议。
Remote Server 可以列出 VM。
Remote Server 可以启动 VM。
Remote Server 可以停止 VM。
Remote Server 可以暂停和恢复 VM。
Remote Server 可以处理快照。
Remote Server 可以传输包文件。
Remote Server 不提供创建 VM 消息。
Remote Server 有 `ServerAutostart`。
因此，Remote Server 适合已有 VM 控制。
因此，Remote Server 不适合首版新 VM 创建。

### 8.5 Case 1 推荐用法

已有 VM 使用 UTM GUI 管理。
锁屏控制使用 Aqua 桥接。
新 Linux VM 使用 QEMU 无界面后端。
如需 UTM 格式，由桥接创建 `.utm` 包。
如需 UTM 管理，由桥接调用 AppleScript 导入。
所有调用记录请求 ID。
所有调用记录返回码。
所有调用记录目标 VM ID。
所有失败保留原始错误。

## 9. 无界面虚拟化后端

### 9.1 QEMU 适用性

QEMU 可以无 GUI 运行。
QEMU 可以关闭显示。
QEMU 可以提供 VNC。
QEMU 可以提供 QMP。
QEMU 可以提供 monitor socket。
QEMU 可以连接串口日志。
QEMU 可以使用 HVF 加速。
QEMU 可以挂载只读 ISO。
QEMU 可以创建 `qcow2` 磁盘。
QEMU 适合锁屏任务。
QEMU 不依赖 WindowServer。
QEMU 不依赖 AppleEvent。
QEMU 不依赖宿主 GUI 输入。

### 9.2 推荐组件

| 组件 | 作用 | 路径或地址 |
| --- | --- | --- |
| 磁盘 | 保存客机系统 | `~/VMs/<name>/disk.qcow2` |
| ISO | 安装介质 | `~/Downloads/archboot-...iso` |
| QMP | 控制接口 | `~/VMs/<name>/qmp.sock` |
| VNC | 客机 GUI | `127.0.0.1:5900` |
| 串口日志 | 安装日志 | `~/VMs/<name>/serial.log` |
| PID 文件 | 进程状态 | `~/VMs/<name>/qemu.pid` |
| 元数据 | 创建参数 | `~/VMs/<name>/metadata.json` |

### 9.3 参考 QEMU 命令

以下命令只作为设计参考。
当前环境尚未安装 `qemu-system-aarch64`。
执行前必须验证 QEMU 版本和 UEFI 固件路径。

```sh
qemu-system-aarch64 \
  -machine virt,accel=hvf \
  -cpu host \
  -smp 4 \
  -m 4096 \
  -bios /opt/homebrew/share/qemu/edk2-aarch64-code.fd \
  -drive if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-aarch64-code.fd \
  -drive if=virtio,format=qcow2,file="$HOME/VMs/archboot/disk.qcow2" \
  -drive if=none,id=cdrom0,format=raw,readonly=on,file="$HOME/Downloads/archboot-2026.10.08-02.27-7.2.9-1-aarch64-ARCH-aarch64.iso" \
  -device virtio-scsi-pci,id=scsi0 \
  -device scsi-cd,bus=scsi0.0,drive=cdrom0 \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -display none \
  -vnc 127.0.0.1:5900 \
  -qmp unix:"$HOME/VMs/archboot/qmp.sock",server=on,wait=off \
  -serial file:"$HOME/VMs/archboot/serial.log" \
  -pidfile "$HOME/VMs/archboot/qemu.pid"
```

### 9.4 QEMU 边界

QEMU 不提供 UTM 的产品界面。
QEMU 不自动生成 UTM `.utm` 包。
QEMU 需要单独维护磁盘和配置。
QEMU 需要单独处理 UEFI 固件。
QEMU 需要单独处理网络和端口。
QEMU 需要单独处理 VNC 认证。
QEMU 需要单独处理 QMP 权限。
QEMU 需要单独处理进程清理。
因此，`VMBridge` 必须封装 QEMU。

## 10. 市场方案对比

| 方案 | 创建 VM | 无界面控制 | 锁屏适用性 | 主要限制 | 决策 |
| --- | --- | --- | --- | --- | --- |
| UTM | 支持 | 条件支持 | 已有 VM 较好 | AppleEvent、TCC、交互实例 | 保留 GUI 路径 |
| QEMU | 支持 | 支持 | 较高 | 集成工作量大 | 首选无界面后端 |
| Tart | 支持 | 支持 | 条件适用 | 主要面向 CI 和 VZ | 备选 |
| Lima | 支持 | 支持 | 条件适用 | 主要面向 Linux VM | 备选 |
| vfkit | 支持 | 支持 | 条件适用 | 集成能力有限 | 调研 |
| VMware Fusion | 支持 | 支持 | 未验证 | Apple Silicon 支持有限 | 备选 |
| Parallels | 支持 | 支持 | 未验证 | 商业授权 | 备选 |
| VirtualBox | 支持 | 支持 | 低 | Apple Silicon 支持弱 | 不推荐主路径 |

### 10.1 UTM

UTM 保留完整 GUI。
UTM 支持 AppleScript。
UTM 支持已有 VM 控制。
UTM 的创建路径依赖 AppleEvent。
UTM 的 Remote Server 不创建 VM。
结论：保留 UTM，增加 Aqua 桥接。

### 10.2 QEMU

QEMU 可以独立运行。
QEMU 提供 QMP 和 VNC。
QEMU 适合锁屏无界面任务。
QEMU 的集成成本最高。
结论：作为首版无界面后端。

### 10.3 Tart

Tart 使用 Apple Virtualization.Framework。
Tart 面向 macOS 和 CI 场景。
Tart 提供无图形模式。
Tart 提供 VNC 和串口。
Tart 不兼容完整 UTM 工作流。
结论：作为 macOS/Linux CI 备选。

### 10.4 Lima

Lima 是 CLI 驱动的 Linux VM 管理器。
Lima 默认在 macOS 上使用 Virtualization.Framework。
Lima 适合 SSH 工作负载。
Lima 不提供通用 UTM GUI 管理。
结论：作为 Linux SSH 任务备选。

### 10.5 vfkit

vfkit 是 Apple Virtualization.Framework 的 CLI。
vfkit 可以启动 VM。
vfkit 的通用管理能力有限。
结论：后续研究。

### 10.6 商业虚拟化

VMware Fusion 提供 `vmrun` 和 `vmcli`。
Parallels 提供 `prlctl`。
本文未在本机验证这两个产品。
官方资料链接存在变更。
因此，置信度低。
结论：只作为备选。
