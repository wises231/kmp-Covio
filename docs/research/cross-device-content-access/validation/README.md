# 验证计划

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 尚未执行 |
| 日期 | `2026-10-12` |
| 主题 | 跨设备内容读取能力 |
| 负责人 | 待填写 |
| 复核人 | 待填写 |

本目录只存放计划。
本目录不预填执行结果。
执行后由执行者回填时间、命令与结果。

## 1. 案例索引

| 编号 | 案例 | 覆盖测试 | 结果文件 |
| --- | --- | --- | --- |
| Case 1 | macOS 本机内容读取 | V01、V02 | [case-macos-local-content.md](case-macos-local-content.md) |
| Case 2 | 桌面局域网发现、配对与传输 | V03、V04、V05、V06、V07 | [case-desktop-lan-transfer.md](case-desktop-lan-transfer.md) |
| Case 3 | Windows 运行时边界 | V08、V09 | [case-windows-runtime-boundary.md](case-windows-runtime-boundary.md) |
| Case 4 | 移动端前台边界 | V10、V11、V12 | [case-mobile-foreground-boundary.md](case-mobile-foreground-boundary.md) |

## 2. 验证目标

验证 [conclusion.md](../conclusion.md) 第 3 节的决策是否成立。
验证 [solution.md](../solution.md) 第 9 节的验收标准是否可达。
目标分四项。

1. 确认桌面端三类内容的读取条件。
2. 确认移动端三类内容的读取边界。
3. 确认跨设备路径在桌面端可用。
4. 确认系统限制项与文档描述一致。

## 3. 范围内事项

1. macOS 端剪切板读取与截图目录监视。
2. macOS 与 Windows 之间的局域网发现与配对。
3. 桌面端之间的内容推送与断点续传。
4. Windows 的账户权限与运行时状态。
5. iOS 与 Android 的前台读取与后台限制。

## 4. 范围外事项

1. 云端中继与账号体系。
2. 跨网段与公网传输。
3. 商店上架审核。
4. 性能与电池的长期测量。
5. 厂商定制系统的全覆盖。
6. 任意账号或任意设备的批量测试。

## 5. 当前事实

以下事实来自 [evidence.md](../evidence.md)，尚未在本机复现。

| 事实 | 来源 | 状态 |
| --- | --- | --- |
| macOS 剪切板读取当前无需授权 | `E-02` | 已在本机观察 |
| macOS 截图目录需要文件夹授权 | `E-08`、`E-09` | 未验证 |
| Apple 平台本地网络需要授权声明 | `E-13` | 未验证 |
| iOS 剪切板读取需要用户动作 | `E-10` | 未验证 |
| Android 剪切板只对焦点应用开放 | `E-18` | 未验证 |
| Windows 剪切板读取无需授权 | `E-24` | 未验证 |
| Windows 标准用户无法放行入站监听 | `E-37` | 未验证 |
| Windows 快速启动终止托盘应用 | `E-39` | 未验证 |

## 6. 成功标准

1. 每个测试有明确的通过或失败判定。
2. 失败项保留错误码与原始输出摘要。
3. 每个结论回填到 [evidence.md](../evidence.md)。
4. 与文档冲突的观察写入反证章节。
5. 临时设置与临时文件全部恢复。

## 7. 前置条件

1. 两台可安装测试构建的设备，一台 macOS，一台 Windows。
2. 一台 iOS 设备与一台 Android 设备。
3. 四台设备处于同一局域网。
4. macOS 设备有管理员权限。
5. Windows 设备同时准备管理员账户与标准用户账户。
6. 测试构建使用固定签名，构建号记录在案例文件。
7. 设备上没有正在进行的备份或同步任务。
8. 测试前记录系统版本与构建号。

## 8. 风险

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| 读取真实剪切板内容 | 内容可能含敏感信息 | 只用测试文本，不记录内容 |
| 读取真实截图 | 截图可能含敏感信息 | 只记录文件名与摘要，不打开文件 |
| 修改防火墙或系统设置 | 系统状态被改变 | 记录原值，测试后恢复 |
| 使用公共服务 | 数据离开局域网 | 只在局域网内测试 |
| 提升权限操作 | 系统风险 | 只在测试机执行，测试后撤销 |
| 真实设备被误重置 | 数据丢失 | 不使用"抹掉所有内容"类操作 |
| 标准用户测试需要新建账户 | 账户残留 | 测试后删除测试账户 |

**警告：** 执行前备份测试设备的接收目录。测试会写入文件。

## 9. 测试矩阵

| 编号 | 场景 | 当前状态 | 结果文件 |
| --- | --- | --- | --- |
| V01 | macOS 剪切板读取与计数变化 | 尚未执行 | [Case 1](case-macos-local-content.md) |
| V02 | macOS 截图目录监视与元数据判定 | 尚未执行 | [Case 1](case-macos-local-content.md) |
| V03 | macOS 本地网络授权与 mDNS 浏览 | 尚未执行 | [Case 2](case-desktop-lan-transfer.md) |
| V04 | 配对：二维码与短码，确认码一致 | 尚未执行 | [Case 2](case-desktop-lan-transfer.md) |
| V05 | 配对：确认码不一致时终止 | 尚未执行 | [Case 2](case-desktop-lan-transfer.md) |
| V06 | 桌面之间剪切板推送端到端 | 尚未执行 | [Case 2](case-desktop-lan-transfer.md) |
| V07 | 传输中断后的断点续传与校验 | 尚未执行 | [Case 2](case-desktop-lan-transfer.md) |
| V08 | Windows 入站放行：管理员与标准用户 | 尚未执行 | [Case 3](case-windows-runtime-boundary.md) |
| V09 | Windows 注销与快速启动后的常驻状态 | 尚未执行 | [Case 3](case-windows-runtime-boundary.md) |
| V10 | iOS 前台剪切板读取与后台拒绝 | 尚未执行 | [Case 4](case-mobile-foreground-boundary.md) |
| V11 | iOS 相册截图读取与本地网络拒绝 | 尚未执行 | [Case 4](case-mobile-foreground-boundary.md) |
| V12 | Android 焦点与后台剪切板读取 | 尚未执行 | [Case 4](case-mobile-foreground-boundary.md) |

## 10. 证据要求

1. 每个测试记录开始时间与结束时间。
2. 每个测试记录系统版本、构建号与账户类型。
3. 每个测试记录使用的命令或界面路径。
4. 每个测试记录观察到的输出摘要。
5. 内容只记录类型、大小与摘要，不记录正文。
6. 截图与文件只记录文件名与哈希，不记录预览。
7. 失败项保留错误码与完整错误信息。
8. 与预期不符的观察写入反证。

## 11. 清理步骤

1. 删除测试写入的接收目录内容。
2. 删除测试创建的配对记录与设备密钥。
3. 恢复测试前的防火墙规则。
4. 恢复测试前修改的系统设置。
5. 删除为测试新建的系统账户。
6. 关闭测试期间打开的局域网服务。
7. 在案例文件中记录清理时间与结果。

## 12. 关联文档

- [主题索引](../README.md)
- [前因与问题边界](../context.md)
- [调研方法与技术分析](../investigation.md)
- [结论与限制](../conclusion.md)
- [推荐架构与实施计划](../solution.md)
- [证据附录](../evidence.md)
