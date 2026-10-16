# 合盖睡眠控制与权限边界验证目录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 状态 | 部分执行。`V04` 已完成，其余待执行。 |
| 日期 | `2026-10-16` |
| 目标环境 | MacBook Pro 18,2，Apple M1 Max，macOS 27.0.1（26A434） |
| 问题类别 | 系统级电源策略的非特权替代 |
| 主方案 | [主题索引](../README.md) |
| 证据附录 | [证据附录](../evidence.md) |
| 验证记录 | [Case 1](case-macos-lid-sleep.md) |

## 1. 案例索引

| 编号 | 案例 | 状态 | 记录 |
| --- | --- | --- | --- |
| Case 1 | 合盖睡眠与特权组件验证 | 尚未执行 | [case-macos-lid-sleep.md](case-macos-lid-sleep.md) |

## 2. 目标

补齐本机实验无法回答的问题。

1. 电源来源切换时，标志是否按预期翻转。
2. 卸载后系统是否回到默认睡眠行为。
3. `SMAppService.daemon` 在自签名证书下能否注册。已完成，见 `E-20`。

## 3. 范围

### 3.1 范围内

- 插电与电池两种电源来源下的合盖行为。
- 电源来源切换时的标志翻转。
- helper 安装与卸载的完整性。
- `SMAppService.daemon` 的注册结果。

### 3.2 范围外

- 空闲睡眠的行为。已在 `E-12` 覆盖。
- 休眠模式的具体取值。
- 其他机型和系统版本。
- 非 Apple Silicon 机器。

## 4. 当前事实

`E-05` 和 `E-06` 显示，有无 `PreventSystemSleep` 断言，合盖后都会进入完全睡眠。
`E-08` 和 `E-09` 显示，`disablesleep` 是系统级键。
`E-16` 和 `E-20` 显示，`SMAppService` 要求公证，两种签名配置都注册失败。
本机没有 Developer ID，只有自签名证书。
详见 [evidence.md](../evidence.md)。

## 5. 成功标准

1. `V01` 复现 `E-05`：持有断言时合盖，日志出现 `Entering Sleep state due to 'Clamshell Sleep'`。
2. `V02` 插电合盖不睡，`pmset -g` 显示 `SleepDisabled 1`。
3. `V03` 拔掉电源后，电池字段为 `false` 时 `SleepDisabled` 回到 `0`。
4. `V04` 记录 `SMAppService` 注册的成功或失败，失败时记录错误码。
5. `V05` 卸载后 `SleepDisabled` 为 `0`，plist 和安装目录都不存在。

## 6. 前置条件

1. 一台 Apple Silicon MacBook，带内建显示器，不接外接显示器。
2. macOS 版本与第 2 节一致，或者记录实际版本。
3. 机器接在电源上。
4. 执行 `V01` 前确认没有 `com.apple.powermanagement.lidopen` 断言。

## 7. 风险

| 编号 | 风险 | 缓解 |
| --- | --- | --- |
| `VR-01` | 合盖不睡期间电量耗尽 | 插电执行。电池测试限制在 5 分钟内。 |
| `VR-02` | `disablesleep` 残留，机器不再睡眠 | 每步结束后跑 `pmset -g` 核对。残留时跑 `sudo pmset -a disablesleep 0`。 |
| `VR-03` | `SMAppService` 注册失败留下半装状态 | 注册后调用 `unregister()`，再用 `status` 核对返回 0。 |
| `VR-04` | 反复合盖开盖影响其他工作 | 每个测试集中执行，中间不穿插其他任务。 |
| `VR-05` | 断言未释放导致机器不睡 | 测试脚本带 `-t` 时限。结束后核对断言列表。 |

## 8. 测试矩阵

| 编号 | 场景 | 当前状态 | 结果文件 |
| --- | --- | --- | --- |
| V01 | 持有断言时合盖 | 待执行 | `case-macos-lid-sleep.md` |
| V02 | 插电合盖不睡 | 待执行 | `case-macos-lid-sleep.md` |
| V03 | 电源切换时的标志翻转 | 待执行 | `case-macos-lid-sleep.md` |
| V04 | `SMAppService` 在自签名证书下注册 | 已完成，见 `E-20` | [evidence.md](../evidence.md) |
| V05 | 卸载后的清理完整性 | 待执行 | `case-macos-lid-sleep.md` |

## 9. 证据要求

1. 每个测试记录开始时间、结束时间和命令。
2. `V01` 记录 `pmset -g log` 里的状态迁移行。
3. `V02`、`V03` 记录 `pmset -g` 的 `SleepDisabled` 值。
4. `V04` 记录注册的返回值和错误码。已完成，见 `E-20`。
5. `V05` 记录 `ls` 的输出和 `pmset -g` 的值。
6. 不记录设备序列号。
7. 不记录完整的系统日志。只记录状态迁移行。

## 10. 清理步骤

1. 确认 `disablesleep` 为 0。跑 `pmset -g`，核对 `SleepDisabled 0`。
2. 确认没有残留断言。跑 `pmset -g assertions`，核对 `PreventSystemSleep 0`。
3. 确认没有残留的 `caffeinate` 进程。跑 `pgrep -x caffeinate`。
4. 卸载 helper。确认 plist 和安装目录都不存在。
5. 删除 `/tmp/lid-heartbeat.txt`。
6. 确认机器能正常睡眠。合盖 30 秒，核对日志出现睡眠记录。
7. 确认注册探针已注销。跑 `status` 模式，核对返回值是 0。
8. 确认 `/Library/LaunchDaemons` 下没有探针的 plist。

## 11. 关联文档

- [主题索引](../README.md)
- [证据附录](../evidence.md)
