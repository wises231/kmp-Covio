# 合盖睡眠与特权组件验证记录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 状态 | 尚未执行 |
| 执行人 | 待填写 |
| 复核人 | 待填写 |
| 环境 | MacBook Pro 18,2，Apple M1 Max，macOS 27.0.1（26A434） |
| 版本 | 待填写 |
| 主方案 | [主题索引](../README.md) |
| 证据附录 | [证据附录](../evidence.md) |
| 目录说明 | [验证目录](README.md) |

## 1. 验证目标

确认电源来源分流按预期工作，确认卸载不留残留，并回答 `SMAppService` 的签名要求。

## 2. 预检记录

| 项目 | 值 | 状态 |
| --- | --- | --- |
| 机型 | 待填写 | 待填写 |
| 系统版本 | 待填写 | 待填写 |
| 电源来源 | 待填写 | 待填写 |
| `SleepDisabled` | 待填写 | 待填写 |
| helper 安装状态 | 待填写 | 待填写 |
| 外接显示器 | 待填写 | 待填写 |

## 3. 测试前采集

```sh
sw_vers
pmset -g | grep -i SleepDisabled
pmset -g assertions | grep -E "PreventSystemSleep|PreventUserIdleSystemSleep"
system_profiler SPDisplaysDataType | grep -E "Display Type|Connection Type"
pgrep -x caffeinate
```

记录字段：

```text
ProductVersion:
BuildVersion:
SleepDisabled:
PreventSystemSleep:
DisplayCount:
CaffeinatePids:
```

## 4. 验证步骤

### V01：持有断言时合盖

前置：没有 `com.apple.powermanagement.lidopen` 断言。机器接电源。不接外接显示器。

命令：

```sh
rm -f /tmp/lid-heartbeat.txt
caffeinate -s -t 300 &
sleep 2
pmset -g assertions | grep PreventSystemSleep
```

合盖前记录时间。合盖保持 120 秒。开盖后采集：

```sh
pmset -g log | grep -E "Clamshell Sleep|Entering Sleep state" | tail -10
```

记录：

```text
Start time:
Lid closed at:
Lid opened at:
End time:
Assertion state:
Log lines:
Result: PENDING
```

通过条件：日志出现 `Entering Sleep state due to 'Clamshell Sleep'`，复现 `E-05`。
不通过条件：120 秒内没有出现完全睡眠记录。此时记录 DarkWake 停留时长，并复查是否有其他断言。

### V02：插电合盖不睡

前置：helper 已安装。配置里 `disableLidSleepInCharging` 为 `true`。机器接电源。

命令：

```sh
pmset -g | grep -i SleepDisabled
```

合盖保持 120 秒。开盖后采集：

```sh
pmset -g log | grep -E "Clamshell Sleep|Entering Sleep state" | tail -10
pmset -g | grep -i SleepDisabled
```

记录：

```text
Start time:
Lid closed at:
Lid opened at:
End time:
SleepDisabled before:
SleepDisabled after:
Log lines:
Result: PENDING
```

通过条件：`SleepDisabled` 为 `1`，并且日志里 120 秒内没有 `Entering Sleep state due to 'Clamshell Sleep'`。

### V03：电源切换时的标志翻转

前置：`V02` 通过。配置里 `disableLidSleepOnBattery` 为 `false`。

命令：

```sh
pmset -g | grep -i SleepDisabled   # 拔电源前
# 拔掉电源
sleep 10
pmset -g | grep -i SleepDisabled   # 拔电源后
pmset -g batt
```

记录：

```text
Start time:
Unplugged at:
SleepDisabled before unplug:
SleepDisabled after unplug:
Power source after unplug:
End time:
Result: PENDING
```

通过条件：拔电源后 10 秒内 `SleepDisabled` 变为 `0`。
不通过条件：值保持 `1`。此时记录 `Engine.onPowerChanged()` 是否被调用。

### V04：`SMAppService` 在自签名证书下注册

前置：现有 helper 已卸载。应用用自签名证书构建。

命令：

```sh
codesign -d -r- /Applications/Covio.app
# 在应用里触发 SMAppService.daemon(plistName:).register()
```

记录：

```text
Start time:
Signing identity:
Designated requirement:
Register return value:
Error code:
Error message:
System Settings entry appears:
End time:
Result: PENDING
```

通过条件：注册返回成功，并且 helper 进程以 root 启动。
不通过条件：返回 `kSMErrorInvalidSignature` 或其他错误。此时记录错误码，并判定换形式的路径不可行。

**警告：** 执行前先卸载现有 helper。
两种安装方式同时存在会让两个 LaunchDaemon 争同一个套接字。

### V05：卸载后的清理完整性

前置：helper 已安装，`SleepDisabled` 为 `1`。

命令：

```sh
# 在应用里触发卸载
pmset -g | grep -i SleepDisabled
ls -la /Library/LaunchDaemons/com.wyz.covio.helper.plist
ls -la "/Library/Application Support/Covio"
launchctl print system/com.wyz.covio.helper
```

记录：

```text
Start time:
SleepDisabled after uninstall:
Plist exists:
Directory exists:
launchctl output:
End time:
Result: PENDING
```

通过条件：`SleepDisabled` 为 `0`，plist 不存在，安装目录不存在，`launchctl print` 报未找到。

## 5. 结果汇总

待填写。

## 6. 清理记录

1. 确认 `pmset -g` 的 `SleepDisabled` 为 `0`。
2. 确认 `pmset -g assertions` 里 `PreventSystemSleep` 为 `0`。
3. 确认 `pgrep -x caffeinate` 没有输出。
4. 确认 helper 已卸载。
5. 删除 `/tmp/lid-heartbeat.txt`。
6. 合盖 30 秒，确认机器能正常睡眠。

```text
Cleanup time:
SleepDisabled:
PreventSystemSleep:
CaffeinatePids:
Helper removed:
Sleep verified:
```

## 7. 更新规则

执行后回填每个步骤的实际结果。
执行后更新 [验证目录](README.md) 的测试矩阵。
执行后更新 [证据附录](../evidence.md) 的已知缺口。
结论变化时更新 [conclusion.md](../conclusion.md)。
实施条件变化时更新 [solution.md](../solution.md)。

## 8. 关联文档

- [主题索引](../README.md)
- [证据附录](../evidence.md)
- [验证目录](README.md)
