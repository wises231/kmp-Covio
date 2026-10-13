# 推荐架构、接口与实施计划

> 本文件承载推荐架构、接口契约、流程、资源策略、安全、失败模式、验收和实施计划。

## 1. 推荐架构

### 1.1 路径选择

采用私有 `MultitouchSupport.framework`。
理由是只有这条路径同时满足“四指”和“应用失焦”，见 [conclusion.md](conclusion.md)。
公开 API 作为窗口内的补充，不作为主路径。

### 1.2 组件

| 组件 | 职责 | 环境 | 启动方式 |
| --- | --- | --- | --- |
| `MultitouchContactSource` | 封装私有框架。枚举设备、注册回调、启动与停止。 | macOS | 触发层启动时创建 |
| `TouchFrame` | 一帧接触数据的值类型。手指数、归一化位置、时间戳。 | 共享 | 回调内构造 |
| `GestureRecognizer` | 从连续帧判定四指下滑。纯逻辑。 | 共享 | 每帧调用 |
| `TrackpadGestureTrigger` | 实现 `CurtainTrigger`。把识别结果转成打开与收起事件。 | macOS | 注册到 `TriggerRegistry` |
| `TriggerAvailability` | 记录每条触发路径的可用性。启动时探测。 | macOS | 应用启动时运行 |

`MultitouchContactSource` 只调用四个私有函数：
`MTDeviceCreateList`、`MTRegisterContactFrameCallback`、`MTDeviceStart`、`MTDeviceStop`。
其余符号一律不调用。理由见 `E-07`。

### 1.3 调用路径

```text
触控板
  -> MultitouchSupport 接触帧回调
  -> MultitouchContactSource 构造 TouchFrame
  -> GestureRecognizer 判定四指下滑
  -> TrackpadGestureTrigger 发出打开事件
  -> TriggerRegistry
  -> CurtainController 展开挂帘
```

## 2. 接口契约

### 2.1 传输

私有框架用进程内 C 函数调用。不涉及网络和跨进程。
本主题不定义 JSON 协议。私有框架的接口是 C ABI，不是 JSON。
这一节说明理由：现有 `WorkspaceWire.kt` 的 JSON 控制通道用于跨设备暂存区，与本主题无关。

### 2.2 私有函数签名

```c
CFArrayRef MTDeviceCreateList(void);
void MTRegisterContactFrameCallback(MTDeviceRef device, MTContactCallbackFunction callback);
void MTDeviceStart(MTDeviceRef device, int mode);
void MTDeviceStop(MTDeviceRef device, int mode);
```

回调签名：

```c
int (*MTContactCallbackFunction)(MTDeviceRef device, MTTouch *touches,
                                 int numTouches, double timestamp, int frame);
```

### 2.3 内部值类型

```kotlin
// kmpDomain 共享层
data class TouchFrame(
    val fingerCount: Int,
    val meanNormalizedY: Double,
    val meanNormalizedX: Double,
    val timestamp: Double,
)
```

`fingerCount` 是本帧的手指数量。
`meanNormalizedY` 是本帧全部手指归一化纵坐标的均值。
`timestamp` 来自私有回调。

### 2.4 操作

| 操作 | 参数 | 返回 | 说明 |
| --- | --- | --- | --- |
| `start` | 无 | 可用设备数 | 枚举设备并启动全部设备 |
| `stop` | 无 | 无 | 停止全部设备并注销回调 |
| `isAvailable` | 无 | 布尔 | 私有符号是否全部存在 |

### 2.5 错误码

| 错误码 | 触发条件 | 可重试 | 人工处理 |
| --- | --- | --- | --- |
| `multitouch_framework_missing` | `dlopen` 失败 | 否 | 降级到其余入口 |
| `multitouch_symbol_missing` | 四个核心符号缺任意一个 | 否 | 降级到其余入口 |
| `multitouch_no_device` | `MTDeviceCreateList` 返回空 | 是 | 外接触控板后重试 |
| `multitouch_start_failed` | 启动后设备状态仍为 0 | 是 | 降级到其余入口 |

## 3. 流程

### 3.1 启动流程

1. 调用 `isAvailable` 探测四个核心符号。
2. 符号缺失时记 `multitouch_symbol_missing`，并跳过后续步骤。
3. 枚举设备。设备为空时记 `multitouch_no_device`。
4. 对每个设备注册回调。
5. 对每个设备调用 `MTDeviceStart`。
6. 读回设备状态。状态为 0 时记 `multitouch_start_failed`。

### 3.2 识别流程

1. 回调收到一帧接触数据。
2. 构造 `TouchFrame`。
3. 手指数不等于 4 时清空当前手势。
4. 手指数等于 4 时记录起始纵坐标。
5. 纵坐标位移超过阈值且方向向下时，判定为四指下滑。
6. 发一次打开事件，并进入冷却期。

### 3.3 冷却期

一次手势只发一个事件。
冷却期默认 600 毫秒。冷却期内忽略新的识别结果。

## 4. 资源策略

- 接触帧的采样率由硬件决定。识别器必须能在每帧内完成计算，不做内存分配。
- 回调运行在私有框架的线程上。识别结果必须切到主线程再改 UI。
- 应用进入后台时不停止设备。停止会让用户失去入口。

## 5. 安全设计

- 私有框架只读。实现不调用任何写入或注入类函数，例如 `MTDeviceInjectFrame`。
- 实现不申请输入监控权限。手势路径不需要它。
- 实现不修改系统手势偏好。
- 手势只触发挂帘。手势不执行删除、清空和退出类动作。

## 6. 失败模式

| 失败 | 表现 | 处理 |
| --- | --- | --- |
| 私有框架缺失 | `dlopen` 返回空 | 降级。其余入口仍可用。 |
| 核心符号缺失 | `dlsym` 返回空 | 降级。 |
| 访问器崩溃 | 进程收到信号 11 | 实现不调用访问器。这条失败模式在设计上排除。 |
| 设备启动失败 | 状态仍为 0 | 降级。 |
| 外接触控板热插拔 | 新设备没有回调 | 监听设备变化后重新枚举。首版不做，记入未决项。 |
| 误触发 | 两指滚动被判成四指 | 提高手指数判定为硬条件。 |
| 系统手势并发 | 挂帘展开的同时触发调度中心 | 未测。列入验证案例。 |

## 7. 验收标准

1. 应用失焦时四指下滑打开挂帘。
2. 系统手势偏好为默认值时仍然可用。
3. 两指滚动不触发挂帘。
4. 三指滑动不触发挂帘。
5. 私有符号缺失时应用正常启动，其余入口可用。
6. 应用不申请输入监控权限也能收到四指下滑。
7. 从接触开始到挂帘展开的延迟低于 150 毫秒。
8. 连续快速四指下滑不产生重复展开。

## 8. 实施计划

1. 在 `kmpDomain` 增加 `TouchFrame` 与 `GestureRecognizer`。识别器用纯函数，配单元测试。
2. 在 `macosApp` 增加 `MultitouchContactSource`。用 `dlopen` 加 `dlsym`，不静态链接。
3. 在 `macosApp` 增加 `TriggerAvailability`。启动时探测并记录结果。
4. 在 `macosApp` 增加 `TrackpadGestureTrigger`，实现 `E01-S01` 定义的 `CurtainTrigger`。
5. 执行 [validation/case-macos-trackpad-gesture.md](validation/case-macos-trackpad-gesture.md)，标定识别阈值。
6. 把阈值写进 `workbench.json`，并加设置项。
7. 更新 `E01-S02` 的验收标准。

用 `dlopen` 而不是静态链接的理由：静态链接会让应用在私有框架被移除时无法启动。
`dlopen` 让缺失变成可处理的运行时状态。

## 9. 回滚条件

以下任一条件成立时回滚到“只用悬停、快捷键和菜单栏图标”。

1. 真机验证发现四指帧的采样率不足以稳定识别。
2. 私有路径要求输入监控权限，且权限被拒时应用无法降级。
3. 私有路径导致系统不稳定，例如触控板失灵。
4. 误触发率高于每分钟一次，且调阈值无法改善。

回滚不需要改数据结构。手势入口与其他入口并列，去掉一个不影响其余。

## 10. 产品化条件

1. 真机验证案例全部通过。
2. 降级路径在私有框架被人为隐藏时可用。
3. 设置面提供手势开关和灵敏度调节。
4. 文档写明本应用使用私有 API，因此不上架 Mac App Store。
5. 无障碍评审确认手势入口有键盘替代。
