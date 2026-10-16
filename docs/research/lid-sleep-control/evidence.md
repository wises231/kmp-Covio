# 证据附录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 审计记录，可复核 |
| 日期 | `2026-10-16` |
| 主文 | [主题索引](README.md) |
| 验证目录 | [验证目录](validation/README.md) |

## 1. 来源等级

| 等级 | 来源 | 用途 | 置信度 |
| --- | --- | --- | --- |
| A | `IOPMLib.h`，Xcode 27 SDK | 断言类型的权威定义 | 高 |
| A | `man caffeinate` | 参数语义 | 高 |
| A | `man pmset` | 参数语义和文档缺口 | 高 |
| A | `SMAppService.h`，Xcode 27 SDK | 注册接口的签名、公证和批准要求 | 高 |
| A | `SMErrors.h`，Xcode 27 SDK | 注册错误的错误码 | 高 |
| B | 本仓库源码，commit `9d47e12` | 实现边界 | 高 |
| B | `docs/adr/adr-0005-local-code-signing.md` | 现有签名配置 | 高 |
| D | 本机对照实验 | 当前环境行为 | 高，范围小 |
| D | 本机注册探针 | 当前环境的注册结果 | 高，范围小 |

## 2. 环境事实

| 项目 | 值 | 命令 | 置信度 |
| --- | --- | --- | --- |
| 机型 | `MacBookPro18,2` | `system_profiler SPHardwareDataType` | 高 |
| 芯片 | Apple M1 Max，10 核 | 同上 | 高 |
| 内存 | 64 GB | 同上 | 高 |
| 系统 | macOS 27.0.1（26A434） | `sw_vers` | 高 |
| 架构 | `arm64` | `uname -m` | 高 |
| SDK | `MacOSX.sdk`（Xcode 27） | `xcrun --show-sdk-path` | 高 |
| 显示器 | 1 个内建，3456 × 2234 | `system_profiler SPDisplaysDataType` | 高 |
| 电源 | AC 接入，电量 80% | `pmset -g batt` | 高 |
| 源码版本 | `9d47e12` | `git rev-parse --short HEAD` | 高 |

## 3. 证据索引

| 编号 | 主题 | 来源 | 结论 | 置信度 |
| --- | --- | --- | --- | --- |
| E-01 | `PreventSystemSleep` 的废弃状态 | A | 断言在任何版本都不受支持 | 高 |
| E-02 | 断言类型全集 | A | 没有合盖专用断言 | 高 |
| E-03 | `caffeinate -s` 的语义 | A | `-s` 创建 `PreventSystemSleep` | 高 |
| E-04 | `man pmset` 的文档缺口 | A | 没有 `disablesleep` 条目 | 高 |
| E-05 | 实验 1：持有断言合盖 | D | 系统进入完全睡眠 | 高 |
| E-06 | 实验 2：无断言合盖 | D | 5 秒进入完全睡眠 | 高 |
| E-07 | 断言登记与判定的分离 | D | 登记存在，判定不读它 | 中高 |
| E-08 | `SleepDisabled` 的作用域 | D | 系统级，非每电源 | 高 |
| E-09 | `pmset -g custom` 的键分布 | D | 两段都没有 `disablesleep` | 高 |
| E-10 | 合盖配置的两个字段 | B | 合同已区分插电与电池 | 高 |
| E-11 | 合盖策略的判定逻辑 | B | 按电池状态二选一 | 高 |
| E-12 | 现有实现的边界注释 | B | 代码已记录这个边界 | 高 |
| E-13 | 卸载脚本的顺序 | B | 先清标志再删组件 | 高 |
| E-14 | helper 命令白名单 | B | 只有三个命令 | 高 |
| E-15 | 无外接显示器 | D | 排除 clamshell mode 混淆 | 高 |
| E-16 | `SMAppService` 的公证要求 | A | 含 LaunchDaemon 的应用必须公证 | 高 |
| E-17 | 手写 plist 路径的地位 | A | Apple 明确保留，且不需批准 | 高 |
| E-18 | 安装后的批准要求 | A | 守护进程要等管理员批准 | 高 |
| E-19 | 更新后的重新注册要求 | A | 改 plist 或可执行文件后要重注册 | 高 |
| E-20 | 探针的注册结果 | D | 两种签名配置都注册失败 | 高 |
| E-21 | 卸载脚本的 root 依赖 | B | 清标志仍然需要 root | 高 |

## 4. 证据详情

### E-01：`PreventSystemSleep` 的废弃状态

来源等级：A
环境：Xcode 27 SDK，`MacOSX.sdk`
命令或来源：`IOPMLib.h:1013-1023`
关键输出：

```text
@define          kIOPMAssertionTypePreventSystemSleep
@deprecated      Deprecated in 10.9. This assertion is not supported in any OS X releases.
@abstract        This assertion is deprecated. Do not use it.
```

观察：Apple 明确写明这个断言在任何版本都不受支持。
推论：以它为基础的功能不会生效。
反证：无。
限制：这是头文件说明，不是行为记录。行为由 `E-05` 和 `E-06` 补充。
置信度：高
关联：`conclusion.md` 2.1

### E-02：断言类型全集

来源等级：A
环境：Xcode 27 SDK
命令或来源：`grep -n "kIOPMAssertionType" IOPMLib.h`
关键输出：

```text
1004:#define kIOPMAssertionTypePreventUserIdleSystemSleep  kIOPMAssertPreventUserIdleSystemSleep
1011:#define kIOPMAssertionTypePreventUserIdleDisplaySleep kIOPMAssertPreventUserIdleDisplaySleep
1023:#define kIOPMAssertionTypePreventSystemSleep           CFSTR("PreventSystemSleep")
1030:#define kIOPMAssertionTypeNoIdleSleep                  CFSTR("NoIdleSleepAssertion")
1037:#define kIOPMAssertionTypeNoDisplaySleep               CFSTR("NoDisplaySleepAssertion")
```

观察：头文件定义的全部断言类型都与空闲睡眠或显示器睡眠相关。
推论：公开 API 里没有合盖专用断言。
反证：无。
限制：只覆盖公开头文件。私有框架未查。
置信度：高
关联：`investigation.md` 4

### E-03：`caffeinate -s` 的语义

来源等级：A
环境：macOS 27.0.1
命令或来源：`man caffeinate`
关键输出：

```text
-s      Create an assertion to prevent the system from sleeping. This
        assertion is valid only when system is running on AC power.
```

观察：`-s` 创建「阻止系统睡眠」断言，并且只在 AC 供电时有效。
推论：`-s` 创建的断言就是 `E-01` 里那个不受支持的断言。文档还额外限制了电源来源。
反证：无。
限制：man 页没有写明断言类型的常量名。常量名的对应关系由 `E-07` 的断言列表补充。
置信度：高
关联：`conclusion.md` 2.1

### E-04：`man pmset` 的文档缺口

来源等级：A
环境：macOS 27.0.1
命令或来源：`man pmset | col -b | grep -c -i disablesleep`
关键输出：

```text
327          # man 页总行数
0            # disablesleep 出现次数
```

观察：`man pmset` 有 327 行，其中没有 `disablesleep`。
推论：Covio 依赖的这个键没有官方文档。
反证：无。
限制：缺文档不等于键不稳定。行为证据见验证矩阵。
置信度：高
关联：`conclusion.md` 5.1

### E-05：实验 1，持有断言合盖

来源等级：D
环境：macOS 27.0.1，AC 供电，电量 80%，无外接显示器
命令或来源：

```sh
caffeinate -s -t 900 &
pmset -g assertions | grep PreventSystemSleep
```

关键输出：

```text
PreventSystemSleep   1
pid 61002(caffeinate): ... PreventSystemSleep named: "caffeinate command-line tool"

# pmset -g log
10:04:42 Sleep  Entering DarkWake state due to 'Clamshell Sleep':TCPKeepAlive=active
10:09:02 Sleep  Entering Sleep state due to 'Clamshell Sleep':TCPKeepAlive=active
```

观察：断言处于持有状态时，合盖后系统仍然在 10:09:02 进入完全睡眠。
推论：`PreventSystemSleep` 不参与合盖判定。
反证：10:02:57 到 10:04:32 之间系统停在 DarkWake，看起来像断言生效。当时另有一个 `com.apple.powermanagement.lidopen` 断言，它在 10:09:09 超时。延迟的归属未确认，不采纳。
限制：合盖时刻由人工操作，时间点不精确。
置信度：高
关联：`conclusion.md` 2.1

### E-06：实验 2，无断言合盖

来源等级：D
环境：同 `E-05`，但断言已释放
命令或来源：

```sh
kill 61002
pmset -g assertions | grep PreventSystemSleep   # 输出 0
```

关键输出：

```text
PreventSystemSleep   0

# pmset -g log
10:10:51 Sleep  Entering DarkWake state due to 'Clamshell Sleep':TCPKeepAlive=active
10:10:56 Sleep  Entering Sleep state due to 'Clamshell Sleep':TCPKeepAlive=active
```

观察：没有断言时，合盖后 5 秒进入完全睡眠。
推论：实验 1 和实验 2 的终点相同。断言只影响到达终点的时间，不影响结果。
反证：无。
限制：两个实验的合盖时刻不同，环境中的其他断言不完全一致。
置信度：高
关联：`conclusion.md` 2.1

### E-07：断言登记与判定的分离

来源等级：D
环境：macOS 27.0.1
命令或来源：`pmset -g assertions`
关键输出：

```text
PreventSystemSleep             1
pid 61002(caffeinate): [0x000567b000018402] 00:06:05 PreventSystemSleep named: "caffeinate command-line tool"
PreventUserIdleSystemSleep     1
pid 61607(caffeinate): ... PreventUserIdleSystemSleep named: "caffeinate command-line tool"
```

观察：断言出现在 `powerd` 的登记列表里，带 pid 和持有时长。
推论：列表只说明登记存在。实验 1 证明这个登记不参与合盖判定。
反证：这是支持「断言生效」假设的最强观察，必须保留。
限制：无法从列表读出每个断言是否参与判定。
置信度：中高
关联：`conclusion.md` 2.2；`investigation.md` 9

### E-08：`SleepDisabled` 的作用域

来源等级：D
环境：macOS 27.0.1
命令或来源：`pmset -g`
关键输出：

```text
System-wide power settings:
 SleepDisabled		0
Currently in use:
 standby              1
 hibernatemode        3
 ...
```

观察：`SleepDisabled` 在 `System-wide power settings` 段。其余键在 `Currently in use` 段。
推论：`disablesleep` 是系统级设置，不是每电源一份。
反证：无。
限制：分段是输出格式，不是接口定义。作用域由 `E-09` 交叉确认。
置信度：高
关联：`conclusion.md` 2.2

### E-09：`pmset -g custom` 的键分布

来源等级：D
环境：macOS 27.0.1
命令或来源：`pmset -g custom`
关键输出：

```text
Battery Power:
 hibernatemode        3
 sleep                1
 displaysleep         2
AC Power:
 hibernatemode        3
 sleep                0
 displaysleep         10
```

观察：`hibernatemode`、`sleep`、`displaysleep` 在 AC 段和电池段各有一份。两段都没有 `disablesleep`。
推论：按电源来源分流只能由应用侧完成。系统不提供每电源的合盖设置。
反证：无。
限制：未验证 `pmset -b disablesleep` 是否被接受。该命令需要 root，未执行。
置信度：高
关联：`conclusion.md` 2.2；`solution.md` 4

### E-10：合盖配置的两个字段

来源等级：B
环境：commit `9d47e12`
命令或来源：`kmpDomain/src/com/wyz/covio/core/Models.kt:28-29`
关键输出：

```kotlin
@SerialName("disableLidSleepInCharging") val disableLidSleepInCharging: Boolean = false,
@SerialName("disableLidSleepOnBattery") val disableLidSleepOnBattery: Boolean = false,
```

观察：合同里插电合盖和电池合盖是两个独立字段，默认值都是 `false`。
推论：插电与电池的区分不需要新设计。
反证：无。
限制：只说明合同形状，不说明运行行为。
置信度：高
关联：`conclusion.md` 4.4；`solution.md` 4

### E-11：合盖策略的判定逻辑

来源等级：B
环境：commit `9d47e12`
命令或来源：`kmpDomain/src/com/wyz/covio/core/Engine.kt:382-387`
关键输出：

```kotlin
val powerPolicy = when {
    battery?.state?.isCharging == true -> config.disableLidSleepInCharging
    battery?.isDischarging == true -> config.disableLidSleepOnBattery
    else -> false
}
return manualLidHold || lidCancelAtMillis != null || powerPolicy
```

观察：判定读电池状态，再选对应字段。`onPowerChanged()` 在电源变化时重新判定。
推论：电源来源分流的执行点已经存在。
反证：无。
限制：未在真机上验证电源切换时的行为。该场景不在本主题的验证范围内。
置信度：高
关联：`conclusion.md` 4.4；`solution.md` 3.1

### E-12：现有实现的边界注释

来源等级：B
环境：commit `9d47e12`
命令或来源：`macosApp/src/Platform/MacSleepController.swift:12-13`
关键输出：

```swift
/// 阻止空闲睡眠用 `NoIdleSleepAssertion`，这是唯一不需要 root 的机制。
/// 阻止合盖睡眠必须用 `pmset disablesleep`，那条路径由 helper 走。
```

观察：现有代码已经记录了这个边界。
推论：本主题的结论与既有实现一致。本主题补上了证据。
反证：无。
限制：注释不是证据，只是线索。结论由 `E-01` 到 `E-06` 支持。
置信度：高
关联：`investigation.md` 6

### E-13：卸载脚本的顺序

来源等级：B
环境：commit `9d47e12`
命令或来源：`kmpDomain/src/com/wyz/covio/core/HelperInstallScript.kt:57-64`
关键输出：

```kotlin
fun uninstallScript(): String = buildString {
    append("set -e\n")
    append("/usr/bin/pmset -a disablesleep 0 || true\n")
    append("/bin/launchctl bootout system '$plistPath' 2>/dev/null || true\n")
    append("rm -f '$plistPath'\n")
    append("rm -rf '${shellEscaped(HELPER_DIRECTORY)}'\n")
}
```

观察：卸载脚本第一步清 `disablesleep`，之后才删组件。
推论：实现已经处理了「组件删掉后标志无人能清」的问题。
反证：无。
限制：脚本中断时仍可能残留标志。见 `solution.md` 6。
置信度：高
关联：`solution.md` 3.2、6

### E-14：helper 命令白名单

来源等级：B
环境：commit `9d47e12`
命令或来源：`kmpDomain/src/com/wyz/covio/core/HelperContract.kt:54`
关键输出：

```kotlin
val HELPER_ALLOWED_COMMANDS: Set<String> = setOf("version", "setDisableSleep", "setHibernateMode")
```

观察：特权组件只接受三个命令，全部与睡眠设置相关。
推论：特权面很小。替代方案的价值主要在形式，不在权限收窄。
反证：无。
限制：只覆盖命令名。参数校验在 `HelperWire.kt`。
置信度：高
关联：`solution.md` 2.4、5

### E-15：无外接显示器

来源等级：D
环境：macOS 27.0.1
命令或来源：`system_profiler SPDisplaysDataType`
关键输出：

```text
Color LCD:
  Display Type: Built-in Liquid Retina XDR Display
  Resolution: 3456 x 2234 Retina
  Connection Type: Internal
```

观察：系统只有内建显示器。
推论：合盖实验不受 clamshell mode 影响。接了外接显示器时合盖本来就不睡，那会让实验失去意义。
反证：无。
限制：实验期间未复查显示器状态。
置信度：高
关联：`E-05`、`E-06`

### E-16：`SMAppService` 的公证要求

来源等级：A
环境：Xcode 27 SDK，`MacOSX.sdk`
命令或来源：`SMAppService.h:49,55`
关键输出：

```text
L49   Apps that use SMAppService APIs must be code signed.
L55   For SMAppServices initialized as LaunchDaemons, the register and unregister APIs provide a
      replacement for installing plists in /Library/LaunchDaemons. Apps that contain LaunchDaemons
      must be notarized.
```

观察：Apple 要求用 `SMAppService` 注册 LaunchDaemon 的应用必须公证。
推论：拿不到公证的应用无法满足这个要求。
反证：无。
限制：这是接口要求，不是行为记录。行为由 `E-20` 补充。
置信度：高
关联：`conclusion.md` 3、5.3；`investigation.md` 7

### E-17：手写 plist 路径的地位

来源等级：A
环境：Xcode 27 SDK
命令或来源：`SMAppService.h:57-58`
关键输出：

```text
L57   Legacy LaunchDaemons installed in /Library/LaunchDaemons will continue to be bootstrapped without
L58   explicit approval in System Settings since writing to /Library is protected  with filesystem permissions.
```

观察：Apple 说明手写 plist 的旧路径继续有效，而且不需要 System Settings 批准。
推论：保留现状不承担兼容性风险。这条路径不是过渡方案。
反证：无。
限制：没有写明保留期限。Apple 可以随时改。
置信度：高
关联：`conclusion.md` 3；`solution.md` 1.1

### E-18：安装后的批准要求

来源等级：A
环境：Xcode 27 SDK
命令或来源：`SMAppService.h:160-162`
关键输出：

```text
L160  If the service corresponds to a LaunchDaemon, the LaunchDaemon will not be bootstrapped until an
L161  admin approves the LaunchDaemon in System Settings. LaunchDaemons registered with this API
L162  and approved by an admin will be bootstrapped on each subsequent boot.
```

观察：注册成功后守护进程不会立刻运行。管理员要到 System Settings 里批准。
推论：换形式之后，管理员动作从安装时的弹窗移到 System Settings 开关。动作没有消失。
反证：无。
限制：未验证批准后的实际引导行为。本机无法批准，因为注册就没成功。
置信度：高
关联：`conclusion.md` 3；`solution.md` 8

### E-19：更新后的重新注册要求

来源等级：A
环境：Xcode 27 SDK
命令或来源：`SMAppService.h:60-62`
关键输出：

```text
L60   If an app updates either the plist or the executable for a LaunchAgent or LaunchDaemon, the SMAppService
L61   must be re-registered or it may not launch. It is recommended to also call unregister before
L62   re-registering if the executable has been changed.
```

观察：应用更新后必须重新注册。否则守护进程可能不启动。
推论：每次发版都要重新注册。这是新增的失败面。
反证：无。
限制：没有写明重新注册是否再次触发管理员批准。
置信度：高
关联：`conclusion.md` 3；`solution.md` 8

### E-20：探针的注册结果

来源等级：D
环境：macOS 27.0.1，`/tmp` 下的探针应用包，两种签名配置
命令或来源：`SMAppService.daemon(plistName:).register()`
关键输出：

```text
配置 A：Covio Dev 自签名证书
  status before: 3 (NotFound)
  register: FAILED
  domain: SMAppServiceErrorDomain   code: 1
  description: The operation couldn't be completed. Operation not permitted
  status after: 2 (RequiresApproval)

配置 B：ad-hoc，与 CI 和 package-macos-swift.sh 一致
  status before: 2
  register: FAILED
  同样的错误
  status after: 2

launchctl print system/com.wyz.covio.testdaemon
  Could not find service "com.wyz.covio.testdaemon" in domain for system

系统日志：
  smd: Job is not allowed to bootstrap
  backgroundtaskmanagementd: disposition=[enabled, disallowed, not notified], have LWCR=true
```

观察：两种签名配置都注册失败。系统建了 BTM 条目，但标记为 `disallowed`，拒绝引导。
推论：自签名证书和 ad-hoc 签名都过不了 `SMAppService` 的签名门槛。这与 `E-16` 的要求一致。
反证：无。
限制：探针从 `/tmp` 运行，不在 Apple 建议的 `/Applications`（`SMAppService.h:127-129`）。路径的影响没有单独隔离。`E-16` 的公证要求是无条件的，所以这个限制不改变结论。
置信度：高
关联：`E-16`；`conclusion.md` 3；验证步骤 `V04`

### E-21：卸载脚本的 root 依赖

来源等级：B
环境：commit `9d47e12`
命令或来源：`HelperInstallScript.kt:57-64`、`HelperInstaller.swift:22-26,59-65`
关键输出：

```kotlin
append("/usr/bin/pmset -a disablesleep 0 || true\n")
append("/bin/launchctl bootout system '$plistPath' 2>/dev/null || true\n")
append("rm -f '$plistPath'\n")
```

```swift
static func uninstall(logger: (String) -> Void = { _ in }) -> Bool {
    let script = uninstallScript()
    logger("Uninstalling privileged helper")
    return runWithAdministrator(script)
}
```

观察：卸载脚本的第一步清 `disablesleep`。整个脚本以 root 运行。
推论：`SMAppService.unregister()` 只能替换后三步。清标志仍然需要 root。
反证：无。
限制：没有测试过由守护进程自己在退出前清标志。那条路径要求守护进程存活。
置信度：高
关联：`conclusion.md` 3；`solution.md` 3.2、8

## 5. 逻辑证据链

```text
研究问题：能否不提权阻止合盖睡眠
  -> E-02：公开断言清单里没有合盖类型
  -> E-01：唯一的候选断言被标为不受支持
  -> E-03：caffeinate -s 用的正是这个断言
  -> E-05：持有断言时合盖仍然完全睡眠
  -> E-06：无断言时结果相同
  -> 推论：断言路径无效
  -> E-08、E-09：disablesleep 是系统级键，需要 root
  -> 决策：保留特权组件
  -> E-10、E-11：电源来源分流由应用侧完成

第二个问题：特权组件用哪种形式
  -> E-16：SMAppService 要求公证
  -> B 级：ADR-0005 记录本机没有 Developer ID
  -> E-20：两种签名配置都注册失败
  -> 推论：SMAppService 路径被阻断
  -> E-17：手写 plist 路径被 Apple 保留，且不需要批准
  -> E-18、E-19、E-21：换形式另有批准、重注册和清标志三项成本
  -> 决策：保留现有 helper 形式
  -> 验证条件：V04（已完成，见 E-20）
  -> 回填位置：conclusion.md 3
```

## 6. 反证和限制

| 编号 | 反证 | 处理 |
| --- | --- | --- |
| `EC-01` | 断言出现在 `powerd` 的登记列表里 | 保留。列表只证明登记，不证明参与判定。见 `E-07`。 |
| `EC-02` | 实验 1 里系统在 DarkWake 停留 4 分 20 秒 | 保留。归属未确认，不采纳为证据。见 `E-05`。 |

## 7. 已知缺口

1. `pmset -b disablesleep` 是否被接受未验证。该命令需要 root。
2. 电池合盖不睡的电量代价未量化。
3. 市场对比缺失。`WebSearch` 在本机返回 403。
4. 实验只在一台机器和一个系统版本上做过。
5. 探针从 `/tmp` 运行，没有单独隔离 `/Applications` 路径的影响。见 `E-20`。
6. 有 Developer ID 的机器上注册是否成功未验证。本机没有 Developer ID。

## 8. 复核方法

1. 读 `IOPMLib.h`，核对 `E-01` 和 `E-02` 的原文。
2. 跑 `man caffeinate`，核对 `E-03`。
3. 跑 `man pmset | col -b | grep -c -i disablesleep`，核对 `E-04` 返回 0。
4. 跑 `pmset -g`，核对 `SleepDisabled` 的分段。
5. 跑 `pmset -g custom`，核对两段的键分布。
6. 重跑 `E-05` 和 `E-06` 的对照实验。合盖前先确认没有 `lidopen` 断言。
7. 读 `SMAppService.h`，核对 `E-16` 到 `E-19` 的原文。
8. 重建探针应用包，重跑注册，核对 `E-20` 的错误码。
9. 注册探针之后必须注销。用 `status` 模式确认返回值是 0。

**警告：** 重跑实验前确认 `disablesleep` 为 0。
为 1 时机器不会睡，电池会耗尽。

## 参考来源

- `IOPMLib.h`，Xcode 27 SDK，路径 `MacOSX.sdk/System/Library/Frameworks/IOKit.framework/Headers/pwr_mgt/IOPMLib.h`
- `man caffeinate`，macOS 27.0.1
- `man pmset`，macOS 27.0.1
- `SMAppService.h`，Xcode 27 SDK，路径 `MacOSX.sdk/System/Library/Frameworks/ServiceManagement.framework/Versions/A/Headers/SMAppService.h`
- `SMErrors.h`，同目录
- `docs/adr/adr-0005-local-code-signing.md`，本仓库

## 9. 关联文档

- [主题索引](README.md)
- [验证目录](validation/README.md)
