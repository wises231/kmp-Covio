# macOS 后台 GUI 自动化证据附录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `3.0` |
| 状态 | 审计记录，可复核 |
| 日期 | `2026-10-10` |
| 主文 | [macOS 后台 GUI 自动化与虚拟化控制通用方案](README.md) |
| 验证目录 | [后台 GUI 自动化验证目录](validation/README.md) |
| Case 1 | [UTM 与 Archboot](validation/case-utm-archboot.md) |
| 采集范围 | 当前 Mac、当前会话、UTM 4.7.5、UTM commit 7eadb05、Case 1 |
| 未执行范围 | UTM VM 创建、Archboot 安装、盒盖验证 |

本文保存可复核证据。
本文不保存密码。
本文不保存令牌。
本文不保存完整隐私日志。
本文不保存设备序列号。
本文的观测只代表当前环境。
本文区分事实、推论和假设。

## 0. 问题类别与案例映射

本文证据用于 macOS 后台 GUI 自动化一类问题。
证据对象包括会话隔离、TCC、WindowServer、电源和虚拟化控制。
`Case 1` 验证 UTM 和 Archboot。
证据等级和复现命令继续用于后续案例。
本文把 UTM 证据标为 `Case 1`。
本文不把 UTM 行为写成所有虚拟化产品的保证。

## 1. 来源等级

| 等级 | 来源 | 用途 | 置信度 |
| --- | --- | --- | --- |
| A | Apple 官方文档和本机 `man` | 会话、权限、系统行为 | 高 |
| B | UTM 源码固定 commit | UTM 能力边界 | 高 |
| B | UTM 官方仓库和 issue | 产品行为补充 | 中高 |
| C | 官方项目文档 | 市场方案对比 | 中 |
| D | 本机实验 | 当前环境事实 | 高，但范围小 |
| E | 第三方文章 | 背景资料 | 低，需交叉验证 |

来源优先级为 A、B、C、D、E。
高影响结论必须包含 A 或 B 证据。
D 证据不能替代 A 或 B 证据。
E 证据不能单独支持关键决策。

## 2. 环境事实

| 项目 | 值 | 命令 | 置信度 |
| --- | --- | --- | --- |
| 操作系统 | macOS 27.0.1 | `sw_vers` | 高 |
| 构建版本 | `26A434` | `sw_vers` | 高 |
| 架构 | `arm64` | `uname -m` | 高 |
| 硬件模型 | `MacBookPro18,2` | `sysctl -n hw.model` | 高 |
| UTM 版本 | `4.7.5` | `defaults read /Applications/UTM.app/Contents/Info CFBundleShortVersionString` | 高 |
| UTM 路径 | `/Applications/UTM.app` | `test -x` | 高 |
| `utmctl` 路径 | `/Applications/UTM.app/Contents/MacOS/utmctl` | `test -x` | 高 |
| UTM 源码 commit | `7eadb056ae0f91d979059544d0ddcd2d5a40be92` | `git rev-parse HEAD` | 高 |
| UTM 源码日期 | `2026-09-24` | `git log -1` | 高 |
| 当前控制台用户 | `wyz` | `stat -f '%Su' /dev/console` | 高 |
| 当前用户 ID | `501` | `launchctl print user/501` | 高 |
| 当前用户会话 | `Background` | `launchctl print user/501` | 高 |
| GUI 会话 | `Aqua` | `launchctl print gui/501` | 高 |
| 锁屏状态 | 锁定 | `ioreg -n Root -d1 -r` | 高 |
| 电源状态 | AC 供电 | `pmset -g batt` | 高 |
| 电池容量 | 80% | `pmset -g batt` | 高 |
| `SleepDisabled` | `0` | `pmset -g` | 高 |

### 2.1 复现命令

```sh
sw_vers
uname -m
sysctl -n hw.model
defaults read /Applications/UTM.app/Contents/Info CFBundleShortVersionString
launchctl print user/501
launchctl print gui/501
ioreg -n Root -d1 -r
pmset -g batt
pmset -g
```

### 2.2 环境结论

当前 shell 不在 Aqua。
当前 Mac 存在 Aqua 域。
当前 Mac 处于锁屏。
当前 UTM 进程存在于 Aqua 域。
因此，当前环境适合检查跨会话问题。

## 3. 证据索引

| 编号 | 主题 | 来源 | 结论 | 置信度 |
| --- | --- | --- | --- | --- |
| E-01 | 锁屏状态 | 本机实验 | 屏幕和控制台均已锁定 | 高 |
| E-02 | 用户会话 | 本机实验 | 当前用户域为 Background | 高 |
| E-03 | GUI 会话 | 本机实验 | `gui/501` 为 Aqua | 高 |
| E-04 | UTM 进程 | 本机实验 | UTM 在 GUI 登录上下文中运行 | 中高 |
| E-05 | 简单 AppleEvent | 本机实验 | 返回 UTM 版本 | 高 |
| E-06 | VM 枚举 AppleEvent | 本机实验 | 5 秒看门狗超时 | 中高 |
| E-07 | `utmctl list` | 本机实验 | 5 秒看门狗超时 | 中高 |
| E-08 | `utmctl version` | 本机实验 | 5 秒看门狗超时 | 中高 |
| E-09 | `launchctl` 会话规则 | 本机 `man` | Background 和 Aqua 分离 | 高 |
| E-10 | Case 1：UTM 创建实现 | UTM 源码 | 创建走 AppleScript 实现 | 高 |
| E-11 | Case 1：UTM Remote Server | UTM 源码 | 可启动已有 VM，无创建消息 | 高 |
| E-12 | Case 1：UTM 输入实现 | UTM 源码 | 输入只支持 QEMU 后端 | 高 |
| E-13 | Archboot ISO | 本机实验 | `aarch64`、可启动、BLAKE2b 匹配 | 高 |
| E-14 | TCC 授权 | Apple 文档 | 首次授权需要用户交互 | 高 |
| E-15 | 电源断言 | 本机实验 | 当前有显示和用户活动断言 | 高 |

## 4. 证据详情

### E-01：锁屏状态

命令：

```sh
ioreg -n Root -d1 -r
```

关键输出：

```text
"IOConsoleLocked" = Yes
"CGSSessionScreenIsLocked"=Yes
"kCGSSessionUserIDKey"=501
"kCGSSessionIDKey"=257
```

观察：控制台锁定。
观察：图形会话屏幕锁定。
观察：用户 ID 为 501。
推论：当前机器处于锁屏状态。
置信度：高。

### E-02：当前用户域为 Background

命令：

```sh
launchctl print user/501
```

关键输出：

```text
user/501 = {
    session = Background
    subdomains = {
        gui/501
    }
}
```

观察：用户域会话为 `Background`。
观察：用户域包含 `gui/501` 子域。
推论：当前 shell 属于用户域。
推论：当前 shell 不属于 GUI 会话。
置信度：高。

### E-03：GUI 域为 Aqua

命令：

```sh
launchctl print gui/501
```

关键输出：

```text
session = Aqua
```

观察：GUI 域存在。
观察：GUI 域会话为 `Aqua`。
推论：锁屏没有销毁 GUI 域。
推论：Aqua 域可承载桥接任务。
置信度：高。

### E-04：UTM 进程存在

命令：

```sh
ps -ax -o pid=,state=,etime=,command= | rg '/Applications/UTM\.app'
launchctl print pid/20617
```

关键输出：

```text
PID=20617
/Applications/UTM.app/Contents/MacOS/UTM
uid = 501
asid = 100015
```

观察：UTM 进程正在运行。
观察：UTM 属于 UID 501。
观察：UTM 的安全审计 ID 为 `100015`。
推论：UTM 在目标用户的登录上下文中运行。
限制：`launchctl print pid` 输出没有直接写 `Aqua`。
置信度：中高。

### E-05：简单 AppleEvent 可返回版本

命令：

```sh
osascript -e 'tell application id "com.utmapp.UTM" to get version'
```

关键输出：

```text
4.7.5
```

观察：简单 AppleEvent 成功。
推论：AppleEvent 路径没有完全断开。
推论：简单的目标属性读取可以到达 UTM。
限制：该结果不能证明 VM 操作可用。
置信度：高。

### E-06：VM 枚举超时

命令：

```sh
osascript -e 'tell application id "com.utmapp.UTM" to get name of every virtual machine'
```

测试方法：后台启动命令。
测试方法：等待 5 秒。
测试方法：超时后结束进程。

结果：

```text
timeout=yes
```

观察：VM 枚举没有在 5 秒内返回。
推论：复杂 AppleEvent 可能阻塞。
限制：5 秒是测试阈值。
限制：慢机器可能超过阈值。
置信度：中高。

### E-07：`utmctl list` 超时

命令：

```sh
/Applications/UTM.app/Contents/MacOS/utmctl list
```

测试方法：后台启动命令。
测试方法：等待 5 秒。
测试方法：超时后结束进程。

结果：

```text
timeout=yes
```

观察：`utmctl list` 没有在 5 秒内返回。
推论：`utmctl` 依赖的路径在 Background 中不可靠。
推论：后台客户端不能直接依赖 `utmctl`。
置信度：中高。

### E-08：`utmctl version` 超时

命令：

```sh
/Applications/UTM.app/Contents/MacOS/utmctl version
```

测试方法：后台启动命令。
测试方法：等待 5 秒。
测试方法：超时后结束进程。

结果：

```text
timeout=yes
```

观察：`utmctl version` 没有在 5 秒内返回。
推论：问题不只出现在 VM 枚举。
推论：`utmctl` 的初始化路径也可能阻塞。
限制：5 秒是测试阈值。
置信度：中高。

### E-09：`launchctl` 会话规则

来源：本机 `man launchctl` 和 `man launchd.plist`。

关键输出：

```text
Relevant sessions are Aqua (the default), Background and LoginWindow.
Background agents may be loaded independently of a GUI login.
Aqua agents are loaded only when a user has logged in at the GUI.
```

观察：Aqua 与 Background 是不同会话类型。
观察：Aqua agent 需要 GUI 登录。
观察：Background agent 不依赖 GUI 登录。
推论：Background 不能自动获得 Aqua 服务。
推论：桥接必须声明 Aqua。
置信度：高。

### E-10：Case 1 UTM 创建路径

来源：`/tmp/utm-src.QZwTVu/Scripting/UTMScriptingCreateCommand.swift`。
源码 commit：`7eadb056ae0f91d979059544d0ddcd2d5a40be92`。
关键行：约 `74` 到 `91`。

关键代码：

```swift
config.qemu.hasHypervisor = true
config.qemu.hasUefiBoot = true
config.drives.append(UTMQemuConfigurationDrive(forArchitecture: architecture, target: target, isExternal: true))
var fixed = UTMQemuConfigurationDrive(forArchitecture: architecture, target: target)
fixed.sizeMib = 64 * bytesInGib / bytesInMib
config.drives.append(fixed)
var serial = UTMQemuConfigurationSerial()
serial.mode = .ptty
config.serials = [serial]
config.displays = []
config.sound = []
```

观察：创建逻辑设置 HVF。
观察：创建逻辑设置 UEFI。
观察：创建逻辑添加默认外部盘。
观察：创建逻辑添加 64 GiB 固定盘。
观察：创建逻辑添加 PTTY 串口。
观察：创建逻辑删除默认显示和声音。
推论：UTM 新建 VM 走脚本创建命令。
推论：该路径依赖 UTM 的交互实例。
置信度：高。

### E-11：Case 1 UTM Remote Server 能力

来源：`/tmp/utm-src.QZwTVu/Remote/UTMRemoteMessage.swift`。
来源：`/tmp/utm-src.QZwTVu/Remote/UTMRemoteServer.swift`。
源码 commit：`7eadb056ae0f91d979059544d0ddcd2d5a40be92`。

关键消息：

```swift
case listVirtualMachines
case getVirtualMachineInformation
case getQEMUConfiguration
case startVirtualMachine
case stopVirtualMachine
case restartVirtualMachine
case pauseVirtualMachine
case resumeVirtualMachine
case saveSnapshotVirtualMachine
case deleteSnapshotVirtualMachine
case restoreSnapshotVirtualMachine
case changePointerTypeVirtualMachine
```

观察：Remote Server 可以管理已有 VM。
观察：Remote Server 没有创建 VM 消息。
推论：Remote Server 不能解决新建 VM。
推论：新建 VM 仍需 Aqua 桥接或其他后端。
置信度：高。

### E-12：Case 1 UTM 输入能力

来源：`/tmp/utm-src.QZwTVu/Scripting/UTM.sdef`。
关键行：约 `993` 和 `1010`。

关键描述：

```text
input keystroke ... Only supported on QEMU backend.
input mouse click ... Only supported on QEMU backend.
```

观察：AppleScript 可以发送键盘输入。
观察：AppleScript 可以发送鼠标点击。
观察：输入只支持 QEMU 后端。
推论：Apple 后端不能依赖该输入路径。
推论：GUI 自动化需要增加 VNC 路径。
置信度：高。

### E-13：Archboot ISO

路径：

```text
/Users/wyz/Downloads/archboot-2026.10.08-02.27-7.2.9-1-aarch64-ARCH-aarch64.iso
```

命令：

```sh
ls -lh /Users/wyz/Downloads/archboot-2026.10.08-02.27-7.2.9-1-aarch64-ARCH-aarch64.iso
file /Users/wyz/Downloads/archboot-2026.10.08-02.27-7.2.9-1-aarch64-ARCH-aarch64.iso
python3 - <<'PY'
import hashlib
from pathlib import Path
p = Path('/Users/wyz/Downloads/archboot-2026.10.08-02.27-7.2.9-1-aarch64-ARCH-aarch64.iso')
h = hashlib.blake2b()
with p.open('rb') as f:
    for chunk in iter(lambda: f.read(1024 * 1024), b''):
        h.update(chunk)
print(h.hexdigest())
PY
```

关键输出：

```text
469M
ISO 9660 CD-ROM filesystem data (DOS/MBR boot sector) 'ARCHBOOT' (bootable)
64dfed8faef876d815c7b049d93663cacfc97209953aca5a3d5f5b1f8e178dce388220b193192b704e8bfdd434b36cb98702671b275b227f4f7b769667f7c1c7
```

清单文件：

```text
/Users/wyz/Downloads/archboot-b2sum.txt
```

清单记录：

```text
BLAKE2b (iso/archboot-2026.10.08-02.27-7.2.9-1-aarch64-ARCH-aarch64.iso) = 64dfed8faef876d815c7b049d93663cacfc97209953aca5a3d5f5b1f8e178dce388220b193192b704e8bfdd434b36cb98702671b275b227f4f7b769667f7c1c7
```

观察：ISO 大小为 469 MiB。
观察：ISO 文件系统为 ISO 9660。
观察：ISO 名为 `ARCHBOOT`。
观察：ISO 标记为 bootable。
观察：BLAKE2b 值与官方清单一致。
限制：当前环境缺少 `signify-openbsd`。
限制：当前环境无法验证 `.sig` 文件。
结论：哈希校验通过。
结论：数字签名验证未完成。
置信度：哈希高，签名待确认。

### E-14：TCC 授权边界

来源类型：Apple 官方隐私和安全文档。
关联页面：<https://support.apple.com/guide/mac-help/change-privacy-security-settings-on-mac-mchl211c911f/mac>。

观察：Automation 权限由用户批准。
观察：Accessibility 权限由用户批准。
观察：Screen Recording 权限由用户批准。
观察：批准界面需要交互式用户会话。
推论：首次授权必须在解锁状态完成。
推论：后台进程不能静默批准。
推论：Aqua 桥接也不能绕过 TCC。
置信度：高。

### E-15：电源断言

命令：

```sh
pmset -g assertions
pmset -g batt
pmset -g
```

关键输出：

```text
PreventUserIdleDisplaySleep    1
InternalPreventDisplaySleep    1
PreventUserIdleSystemSleep     0
Now drawing from 'AC Power'
 SleepDisabled       0
 hibernatemode       3
```

观察：当前没有永久禁用睡眠。
观察：当前有显示空闲睡眠断言。
观察：当前使用 AC 电源。
推论：盒盖测试需要单独控制电源策略。
推论：验证时应记录 `SleepDisabled` 原值。
置信度：高。

## 5. 逻辑证据链

### 5.1 结论一：当前调用方不在 Aqua

前提 1：`launchctl print user/501` 显示 `Background`。
前提 2：`launchctl print gui/501` 显示 `Aqua`。
前提 3：Aqua 和 Background 是不同会话类型。
结论：当前调用方不在 Aqua。
置信度：高。

### 5.2 结论二：UTM GUI 路径属于 Aqua

前提 1：UTM GUI 进程正在运行。
前提 2：UTM 使用 UID 501。
前提 3：当前 GUI 域为 `gui/501`。
前提 4：GUI 应用注册 AppleEvent。
结论：UTM GUI 路径属于 Aqua。
置信度：中高。

### 5.3 结论三：跨会话 AppleEvent 不稳定

前提 1：简单 `get version` 成功。
前提 2：VM 枚举 5 秒超时。
前提 3：`utmctl version` 5 秒超时。
前提 4：`utmctl list` 5 秒超时。
结论：跨会话 AppleEvent 不稳定。
置信度：中高。

### 5.4 结论四：UTM 创建依赖 AppleEvent

前提 1：UTM 源码定义创建命令。
前提 2：UTM 源码实现创建命令。
前提 3：UTM Remote Server 没有创建消息。
前提 4：`utmctl` 使用脚本接口。
结论：UTM 新建 VM 依赖 AppleEvent。
置信度：高。

### 5.5 结论五：锁屏不是唯一根因

前提 1：锁屏后 Aqua 仍存在。
前提 2：Background 与 Aqua 分离。
前提 3：简单 AppleEvent 可以成功。
前提 4：复杂 AppleEvent 可以超时。
结论：问题是跨会话和首次连接。
结论：锁屏只是触发条件之一。
置信度：高。

### 5.6 结论六：需要 Aqua 桥接

前提 1：UTM 创建依赖交互实例。
前提 2：Background 调用不稳定。
前提 3：TCC 需要交互授权。
前提 4：TCC 不能后台绕过。
结论：需要预先加载 Aqua 桥接。
结论：桥接必须在锁屏前完成授权。
置信度：高。

## 6. 反证和限制

### 6.1 简单 AppleEvent 成功

反证：`get version` 返回 `4.7.5`。
影响：不能写“所有 AppleEvent 都不可用”。
修正：写“复杂 AppleEvent 不稳定”。

### 6.2 看门狗阈值

限制：测试使用 5 秒看门狗。
影响：不能区分永久阻塞和慢响应。
修正：后续记录 5 秒、15 秒和 30 秒结果。

### 6.3 当前系统版本较新

限制：当前系统为 macOS 27.0.1。
影响：旧系统行为可能不同。
修正：产品支持矩阵必须分版本测试。

### 6.4 UTM 源码为固定 commit

限制：源码引用为 `7eadb05`。
影响：新版本可能改变实现。
修正：升级 UTM 后重新审计源码。

### 6.5 UTM VM 尚未创建

限制：当前没有执行 `utm.create`。
影响：创建结论来自源码和会话证据。
修正：执行 Archboot 验证后更新证据。

### 6.6 盒盖尚未验证

限制：当前只记录电源状态。
影响：无法确认完整盒盖流程。
修正：按验证目录执行测试。

## 7. 已知缺口

缺少 VMware Fusion 官方稳定链接。
缺少 Parallels `prlctl` 官方稳定链接。
缺少 UTM VM 创建实验。
缺少 Archboot 图形安装实验。
缺少 VNC 输入实验。
缺少 QEMU QMP 实验。
缺少盒盖实验。
缺少电池模式实验。
缺少快速切换用户实验。
缺少 FileVault 登录窗口实验。
缺少 MDM 策略实验。
缺少不同 macOS 版本实验。
缺少不同 UTM 版本实验。
缺少桥接签名和公证实验。

## 8. 复核方法

1. 使用同一 macOS 版本。
2. 使用 UTM 4.7.5。
3. 使用 UTM commit `7eadb05`。
4. 使用同一 ISO。
5. 运行环境命令。
6. 运行会话命令。
7. 运行锁屏命令。
8. 运行 AppleEvent 探测。
9. 运行 `utmctl` 探测。
10. 比较输出和错误码。
11. 记录差异。
12. 更新证据附录。

## 参考来源

以下来源用于本方案和证据附录。
访问日期为 `2026-10-10`。

### Apple 和本机文档

- 本机 `man launchctl`。
- 本机 `man launchd.plist`。
- [Apple launchd Introduction](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/Introduction.html)
- [Apple Creating Launchd Jobs](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
- [Apple ServiceManagement](https://developer.apple.com/documentation/servicemanagement)
- [Apple SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [Apple Privacy](https://www.apple.com/privacy/)
- [Apple macOS privacy controls](https://support.apple.com/guide/mac-help/change-privacy-security-settings-on-mac-mchl211c911f/mac)

### UTM

- [UTM website](https://getutm.app/)
- [UTM documentation](https://docs.getutm.app/)
- [UTM repository](https://github.com/utmapp/UTM)
- [UTM.sdef at commit 7eadb05](https://github.com/utmapp/UTM/blob/7eadb056ae0f91d979059544d0ddcd2d5a40be92/Scripting/UTM.sdef)
- [UTMScriptingCreateCommand.swift at commit 7eadb05](https://github.com/utmapp/UTM/blob/7eadb056ae0f91d979059544d0ddcd2d5a40be92/Scripting/UTMScriptingCreateCommand.swift)
- [UTMRemoteMessage.swift at commit 7eadb05](https://github.com/utmapp/UTM/blob/7eadb056ae0f91d979059544d0ddcd2d5a40be92/Remote/UTMRemoteMessage.swift)
- [UTM issue 5377](https://github.com/utmapp/UTM/issues/5377)
- [UTM issue 2280](https://github.com/utmapp/UTM/issues/2280)
- [UTM issue 4331](https://github.com/utmapp/UTM/issues/4331)
- [UTM pull request 7855](https://github.com/utmapp/UTM/pull/7855)
- [UTM issue 7757](https://github.com/utmapp/UTM/issues/7757)

### 虚拟化工具

- [QEMU documentation](https://www.qemu.org/docs/master/)
- [QEMU invocation](https://www.qemu.org/docs/master/system/invocation.html)
- [QMP specification](https://www.qemu.org/docs/master/interop/qmp-spec.html)
- [Tart repository](https://github.com/cirruslabs/tart)
- [Lima documentation](https://lima-vm.io/)
- [vfkit repository](https://github.com/crc-org/vfkit)
- [VMware Fusion documentation](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/fusion-pro/13-0.html)
- [Parallels Desktop documentation](https://download.parallels.com/desktop/v20/docs/en_US/Parallels_Desktop_Users_Guide/)
- [VirtualBox manual](https://www.virtualbox.org/manual/)

## 9. 关联文档

- [主方案](README.md)
- [后台 GUI 自动化验证目录](validation/README.md)
- [Case 1：UTM 与 Archboot 验证记录](validation/case-utm-archboot.md)
