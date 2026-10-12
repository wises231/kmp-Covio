# Case 3：Windows 运行时边界

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 案例编号 | `Case 3` |
| 状态 | 尚未执行 |
| 覆盖测试 | V08、V09 |
| 日期 | 待填写 |
| 执行人 | 待填写 |
| 复核人 | 待填写 |

本文件不预填结果。
执行后由执行人回填时间、命令与输出摘要。

## 1. 验证目标

确认 Windows 入站监听在管理员与标准用户下的差别。
确认注销与快速启动对常驻进程的影响。
验证 [solution.md](../solution.md) 第 9 节第 13、14 项。
证据编号对应 `E-37`、`E-39`。

## 2. 预检记录

| 项目 | 值 |
| --- | --- |
| Windows 版本与构建号 | 待填写 |
| 应用构建号 | 待填写 |
| 当前账户类型 | 待填写 |
| 管理员账户可用性 | 待填写 |
| 快速启动当前状态 | 待填写 |
| 测试机是否可重建 | 待填写 |

## 3. 测试前采集

```powershell
# 记录防火墙当前状态与已有规则
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
Get-NetFirewallRule -DisplayName 'Covio*' | Select-Object DisplayName, Direction, Action, Enabled
```

```powershell
# 记录快速启动状态
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' `
  -Name HiberbootEnabled
```

```powershell
# 记录截图相关已知文件夹
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' |
  Select-Object '{B7BEDE81-DF94-4682-A7D8-57A717845556}'
```

采集后记录原值，供清理时恢复。

## 4. V08：入站放行

### 4.1 前置条件

1. 测试机存在管理员账户与标准用户账户。
2. 防火墙使用默认入站策略。
3. 应用首次监听前没有 Covio 相关规则。

### 4.2 命令或请求

```powershell
# 管理员账户下启动监听并记录提示
Start-Process -FilePath '<应用路径>' -Verb RunAs
```

```powershell
# 记录自动生成的规则
Get-NetFirewallRule -DisplayName 'Covio*' | Select-Object DisplayName, Action, Profile
```

```text
切换到标准用户账户，重复启动监听
记录是否出现提示
记录对端是否能够连接
```

### 4.3 预期结果

1. 管理员账户下允许后生成允许规则。
2. 标准用户账户下即使点击允许也生成阻止规则。
3. 标准用户下对端连接被拒绝。
4. 界面给出管理员放行指引，错误码为 `firewall_blocked` 或 `admin_required`。

### 4.4 实际结果

| 项目 | 值 |
| --- | --- |
| 管理员下规则动作 | 待填写 |
| 标准用户下规则动作 | 待填写 |
| 标准用户下对端能否连接 | 待填写 |
| 界面提示内容 | 待填写 |
| 错误码 | 待填写 |
| 判定 | 待填写 |

### 4.5 错误码

待填写。
无错误时写 `无`。

## 5. V09：注销与快速启动

### 5.1 前置条件

1. V08 已完成。
2. 应用以托盘方式运行。
3. 对端可查询设备在线状态。

### 5.2 命令或请求

```powershell
# 记录应用进程
Get-Process -Name 'Covio*' | Select-Object Id, SessionId
```

```text
执行注销，重新登录后记录应用进程
执行锁定屏幕，恢复后记录应用进程
关闭快速启动后执行完全关机，再开机后记录应用进程
开启快速启动后执行关机，再开机后记录应用进程
每次在对端记录设备在线状态与耗时
```

### 5.3 预期结果

1. 注销后托盘应用不存活。
2. 锁屏期间应用存活，但不能显示确认对话框。
3. 快速启动后的开机等同于注销，托盘应用不存活。
4. 对端在 30 秒内把该设备标记为离线。
5. 待发任务进入排队状态。

### 5.4 实际结果

| 项目 | 值 |
| --- | --- |
| 注销后进程是否存在 | 待填写 |
| 锁屏后进程是否存在 | 待填写 |
| 快速启动后进程是否存在 | 待填写 |
| 对端标记离线的耗时 | 待填写 |
| 待发任务状态 | 待填写 |
| 判定 | 待填写 |

### 5.5 错误码

待填写。
无错误时写 `无`。

## 6. 结果汇总

| 测试 | 状态 | 通过项 | 失败项 |
| --- | --- | --- | --- |
| V08 | 尚未执行 | 待填写 | 待填写 |
| V09 | 尚未执行 | 待填写 | 待填写 |

## 7. 清理记录

| 项目 | 值 |
| --- | --- |
| 删除的防火墙规则 | 待填写 |
| 恢复的快速启动状态 | 待填写 |
| 删除的测试账户 | 待填写 |
| 恢复的系统设置 | 待填写 |
| 清理时间 | 待填写 |

## 8. 更新规则

1. 执行后把状态改为 `通过`、`部分通过` 或 `失败`。
2. 状态变化同步到 [validation/README.md](README.md) 的测试矩阵。
3. 新观察回填到 [evidence.md](../evidence.md)。
4. 与文档冲突的观察回填到证据附录的反证章节。
5. 结论变化时同步更新 [conclusion.md](../conclusion.md)。

## 9. 关联文档

- [主题索引](../README.md)
- [验证目录](README.md)
- [证据附录](../evidence.md)
