# 跨设备内容读取能力研究

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 初稿，可评审 |
| 日期 | `2026-10-12` |
| 适用对象 | Covio 产品、研发、测试和安全人员 |
| 当前验证环境 | Apple Silicon Mac，macOS 27.0.1 |
| 当前结论 | 推送模型覆盖四个平台，拉取模型只用于桌面常驻对等端 |
| 验证状态 | 尚未执行 |

## 前因

Covio 计划提供跨设备的文件共享、剪切板和最近截图能力。
安装 Covio 之后，用户能否读取其他设备的这三类内容，需要先确认。
四个平台对内容读取的授权、前台状态和后台执行限制不同。
平台自带能力又覆盖了一部分场景。
因此需要先划定能力边界，再设计实现路径。
问题定义、适用边界、场景和成功标准见 [context.md](context.md)。
证据链见 [evidence.md](evidence.md)。

## 背景

剪切板、截图和文件属于不同的内容源。
系统用运行时权限、前台状态和后台限制控制读取。
系统授权服务包括 TCC、本地网络、相册和媒体库。
桌面端与移动端的限制强度不同。
移动端还受 Doze、后台冻结和商店政策限制。
专业说明、来源等级和工具矩阵见 [investigation.md](investigation.md)。
当前环境和原始观测见 [evidence.md](evidence.md)。

## 过程

调研分三路并行执行。
第一路覆盖 Apple 平台的接口文档、技术说明和本机 SDK。
第二路覆盖 Android 与 Windows 的官方文档、行为变更页和 AOSP 源码。
第三路覆盖同类产品的源码、协议文档和标准文本。
本机实验只覆盖 macOS 端。
每一格能力结论都带证据编号。
调研方法和来源范围见 [investigation.md](investigation.md)。
复现命令、来源、观察和推论见 [evidence.md](evidence.md)。
验证计划见 [validation/README.md](validation/README.md)。

## 结果

桌面端三类内容都可以在本机读取。
移动端只有前台可读，且 iOS 需要用户动作。
拉取模型在移动端不成立。
推送模型是唯一覆盖四个平台的路径。
系统原生能力只覆盖同账号或同生态场景。
跨生态组合没有被原生能力覆盖。
Android 17 的本地网络权限和 Windows 的标准用户限制是两个高风险项。
结论摘要、决策表、不采用方案和限制见 [conclusion.md](conclusion.md)。
证据索引、逻辑链和已知缺口见 [evidence.md](evidence.md)。

## 预期

目标能力是桌面端常驻读取剪切板与截图。
目标能力是设备发现与一次性配对。
目标能力是内容推送、校验与断点续传。
目标能力是移动端在前台或唤醒后参与同步。
目标能力是权限缺失时给出明确原因和降级路径。
目标能力是快速启动或注销后的设备被正确标记为离线。
验收标准见 [solution.md](solution.md)。
验证目标、范围、矩阵和风险见 [validation/README.md](validation/README.md)。
证据链见 [evidence.md](evidence.md)。

## 实现预期的手段

传输使用 TLS 1.3 与双向认证。
发现分三层，依次是 mDNS、自定义组播和二维码或手动输入。
配对以二维码携带公钥为主，短码为辅并限速。
剪切板在桌面端常驻监听，在移动端只于前台读取。
截图通过目录监视与元数据判定获取。
文件通过分块传输、SHA-256 校验和断点续传完成。
移动端由用户动作或系统唤醒触发。
推荐架构、接口契约、流程、安全和实施计划见 [solution.md](solution.md)。
实际验证记录见 [validation/case-macos-local-content.md](validation/case-macos-local-content.md)。
证据链见 [evidence.md](evidence.md)。

## 子文档

| 文件 | 内容 |
| --- | --- |
| [context.md](context.md) | 前因、研究问题、问题分类、状态矩阵、场景和成功标准 |
| [investigation.md](investigation.md) | 调研方法、系统模型、约束模型、能力矩阵、产品分析和方案对比 |
| [conclusion.md](conclusion.md) | 结论摘要、决策因素、决策表、不采用方案、限制和未决项 |
| [solution.md](solution.md) | 推荐架构、接口契约、流程、安全、可靠性、失败模式和实施计划 |
| [evidence.md](evidence.md) | 来源、命令、观察、推论、置信度、反证和已知缺口 |
| [validation/README.md](validation/README.md) | 验证目标、范围、测试矩阵、风险和清理要求 |
| [validation/case-macos-local-content.md](validation/case-macos-local-content.md) | `Case 1`：macOS 本机内容读取 |
| [validation/case-desktop-lan-transfer.md](validation/case-desktop-lan-transfer.md) | `Case 2`：桌面局域网发现、配对与传输 |
| [validation/case-windows-runtime-boundary.md](validation/case-windows-runtime-boundary.md) | `Case 3`：Windows 运行时边界 |
| [validation/case-mobile-foreground-boundary.md](validation/case-mobile-foreground-boundary.md) | `Case 4`：移动端前台边界 |

## 证据链

1. 从 [context.md](context.md) 阅读问题边界与状态矩阵。
2. 从 [investigation.md](investigation.md) 阅读约束模型与能力矩阵。
3. 从 [evidence.md](evidence.md) 阅读来源、命令和推论。
4. 从 [conclusion.md](conclusion.md) 阅读决策与限制。
5. 从 [solution.md](solution.md) 阅读推荐实现与接口契约。
6. 从 [validation/README.md](validation/README.md) 阅读验证矩阵。
7. 从 [validation/case-macos-local-content.md](validation/case-macos-local-content.md) 开始阅读案例结果。

## 更新规则

执行验证后更新案例状态。
执行验证后更新验证矩阵。
执行验证后更新结论和限制。
执行验证后更新证据缺口。
执行验证后更新本索引。
