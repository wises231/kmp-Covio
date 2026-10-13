# 内建触控板四指下滑采集与标定验证记录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 状态 | 尚未执行 |
| 执行人 | 待填写 |
| 复核人 | 待填写 |
| 环境 | MacBook Pro 18,2，Apple M1 Max，macOS 27.0.1（26A434） |
| 版本 | 分支 `feature/swiftui-macos`，commit 待填写 |
| 主方案 | [主题索引](../README.md) |
| 证据附录 | [证据附录](../evidence.md) |
| 目录说明 | [验证目录](README.md) |

## 1. 验证目标

补齐 [validation/README.md](README.md) 第 2 节列出的四个问题。
本案例不验证挂帘外壳。本案例只验证手势入口。

## 2. 预检记录

| 项目 | 值 | 状态 |
| --- | --- | --- |
| 系统版本 | 待填写 | 待执行 |
| 机型 | 待填写 | 待执行 |
| 内建触控板是否存在 | 待填写 | 待执行 |
| 外接触控板是否连接 | 待填写 | 待执行 |
| 输入监控权限 | 待填写 | 待执行 |
| 四指垂直轻扫偏好 | 待填写 | 待执行 |

## 3. 测试前采集

```sh
sw_vers
system_profiler SPHardwareDataType | grep -E "Model Identifier|Chip"
defaults read com.apple.AppleMultitouchTrackpad | grep -iE "swipe"
bash scripts/probe-trackpad-gesture.sh symbols
bash scripts/probe-trackpad-gesture.sh devices
```

记录字段：

```text
系统版本:
机型:
符号检查结果:
设备数:
运行中:
```

## 4. 验证步骤

### V01：内建触控板四指帧采集

前置：触控板空闲。没有其他应用占用多触点设备。

请求：

```sh
bash scripts/probe-trackpad-gesture.sh listen 30
```

采集期间做 5 次四指下滑、5 次三指下滑、5 次两指滚动。

记录：

```text
Start time:
End time:
总帧数:
最大手指数:
各手指数帧数分布:
四指段的 y 位移与时长:
Error code:
Result: PENDING
```

通过条件：出现手指数为 4 的帧。四指段的 y 位移方向一致。

### V02：识别阈值标定与误触发

前置：`V01` 通过。`GestureRecognizer` 已实现。

请求：

```sh
bash scripts/probe-trackpad-gesture.sh listen 60
```

采集期间做 10 次四指下滑、10 次两指滚动、10 次三指滑动。

记录：

```text
Start time:
End time:
四指下滑识别次数:
两指滚动误触发次数:
三指滑动误触发次数:
所选位移阈值:
所选时间窗:
Error code:
Result: PENDING
```

通过条件：四指下滑识别 10 次。两指与三指的误触发为 0 次。

### V03：系统手势并发行为

前置：系统手势偏好保持默认值。

请求：

```sh
bash scripts/probe-trackpad-gesture.sh listen 30
```

采集期间做 5 次四指下滑。观察屏幕是否进入调度中心。

记录：

```text
Start time:
End time:
四指帧数:
是否进入调度中心:
Error code:
Result: PENDING
```

通过条件：记录并发行为。并发触发不是失败条件，但必须记录。

### V04：私有符号缺失时的降级

前置：应用已接入 `TriggerAvailability`。

请求：

```sh
# 用 DYLD 插入一个假的 MultitouchSupport，使 dlopen 失败。
# 具体做法在实施后确定。不要修改 /System。
echo "做法待定"
```

记录：

```text
Start time:
End time:
应用是否启动:
dlopen 结果:
可用入口列表:
Error code:
Result: PENDING
```

通过条件：应用正常启动。悬停、快捷键和菜单栏入口可用。日志里有 `multitouch_framework_missing`。

### V05：未授权进程下的私有路径

前置：新建一个用户账户。该账户没有授予输入监控权限。

**警告：** 不要在主账户上重置 TCC。
重置输入监控权限会影响其他应用。
重置后需要重新授权其他应用。

请求：

```sh
# 在新账户里运行：
bash scripts/probe-trackpad-gesture.sh devices
bash scripts/probe-trackpad-gesture.sh listen 10
swift -e 'import CoreGraphics; print(CGPreflightListenEventAccess())'
```

记录：

```text
Start time:
End time:
CGPreflightListenEventAccess:
设备数:
设备是否启动:
是否收到帧:
Error code:
Result: PENDING
```

通过条件：记录私有路径在未授权进程里的行为。
私有路径可用则说明不需要权限。不可用则说明需要权限。

### V06：外接触控板枚举

前置：连接一台外接触控板。

请求：

```sh
bash scripts/probe-trackpad-gesture.sh devices
```

记录：

```text
Start time:
End time:
设备数:
内建设备下标:
外接设备下标:
两次运行的顺序是否一致:
Error code:
Result: PENDING
```

通过条件：外接设备被枚举。两次运行的顺序被记录。

## 5. 结果汇总

尚未执行。

## 6. 清理记录

```text
pgrep -fl probe
bash scripts/probe-trackpad-gesture.sh devices
```

记录字段：

```text
残留进程:
触控板运行中状态:
TCC 是否已恢复:
外接设备是否已断开:
临时账户是否已删除:
```

## 7. 更新规则

执行后回填每个步骤的实际结果和时间。
执行后更新 [validation/README.md](README.md) 的测试矩阵状态。
执行后更新 [evidence.md](../evidence.md) 的证据与缺口。
结论变化时更新 [conclusion.md](../conclusion.md)。
实施条件变化时更新 [solution.md](../solution.md)。
最后更新 [README.md](../README.md) 的文档状态。

## 8. 关联文档

- [主题索引](../README.md)
- [证据附录](../evidence.md)
- [验证目录](README.md)
