# 跨设备共享暂存工作区研究

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 初稿，可评审 |
| 日期 | `2026-10-12` |
| 适用对象 | Covio 产品、研发、测试和安全人员 |
| 当前验证环境 | Apple Silicon Mac，macOS 27.0.1 |
| 当前结论 | 本地优先副本加内容寻址，四个平台各有一个免授权放入入口 |
| 遗留决策 | HTTP 端点的覆盖范围、Windows 的打包发行 |
| 验证状态 | 尚未执行 |

## 前因

Covio 已有本地临时文件区与局域网互传两个独立模块。
用户希望把两者合并成一个跨设备共享的暂存工作区。
用户在一台设备上把文件、图片、音频、PDF 或文本放入工作区。
其他已配对设备能看到并取出这些内容。
体验目标接近隔空投送。
问题定义、适用范围、角色和状态矩阵见 [context.md](context.md)。
上一主题的能力边界见 [跨设备内容读取能力](../cross-device-content-access/README.md)。
证据链见 [evidence.md](evidence.md)。

## 背景

工作区是一组已配对设备共享的临时内容集合。
工作区不是云盘，也不依赖账号。
现有晾衣线只记录用户文件的路径，不复制内容。
现有条目模型缺少摘要、大小和来源设备字段。
各平台对私有目录、缓存清理和后台传输的限制不同。
Windows 的分享面板需要打包身份。
Android 的缓存目录会被系统清理。
iOS 的分享面板只列出扩展，扩展与主应用不能直接互读容器。
专业说明、约束模型和能力矩阵见 [investigation.md](investigation.md)。
当前环境与原始观测见 [evidence.md](evidence.md)。

## 过程

调研分两路并行执行。
第一路覆盖 Android 与 Windows 的官方文档、AOSP 文档和商店政策。
第二路覆盖 Apple 平台的扩展机制与后台执行限制。
本机只读实验覆盖现有实现与存储保护。
每一条结论都带证据编号。
调研方法和来源范围见 [investigation.md](investigation.md)。
复现命令、来源、观察和推论见 [evidence.md](evidence.md)。
验证计划见 [validation/README.md](validation/README.md)。

## 结果

共享工作区可行。
现有晾衣线不能直接扩展成工作区。
工作区需要独立的存储与索引。
副本放在应用私有数据目录，不放在缓存目录或临时目录。
四个平台各有一个不需要额外授权的放入入口。
移动端的大文件传输有系统配额。
Windows 的分享面板入口需要打包身份。
iOS 的放入入口是分享扩展，扩展与主应用用共享容器交换文件。
iOS 的后台会话只支持 HTTP 与 HTTPS，现有协议不能在后台使用。
隔空投送不提供共享副本与过期，也没有第三方接口。
结论摘要、决策表、不采用方案和限制见 [conclusion.md](conclusion.md)。
证据索引、逻辑链和已知缺口见 [evidence.md](evidence.md)。

## 预期

目标能力是四个平台都有可用的放入入口。
目标能力是条目在已配对设备之间保持一致。
目标能力是超过阈值的内容按需取回。
目标能力是离线设备上线后补齐条目。
目标能力是配额、过期与删除有确定规则。
目标能力是权限被拒或空间不足时给出原因与下一步。
验收标准见 [solution.md](solution.md)。
验证目标、范围、矩阵和风险见 [validation/README.md](validation/README.md)。
证据链见 [evidence.md](evidence.md)。

## 实现预期的手段

新增 `WorkspaceStore`，保存索引与内容。
新增 `WorkspacePolicy`，实现配额、淘汰与过期的纯逻辑。
内容按摘要命名，相同内容只存一份。
索引与内容分离，先传索引再传内容。
控制通道沿用上一主题的会话层，新增 `workspace.*` 操作。
iOS 的放入由分享扩展完成，传输由主应用完成。
iOS 的后台传输需要 HTTP 端点，或限制在前台。
删除全局传播，并保留 30 天删除标记。
置顶是本机属性，不传播。
推荐架构、接口契约、流程、安全和实施计划见 [solution.md](solution.md)。
实际验证记录见 [validation/case-desktop-workspace-ingest.md](validation/case-desktop-workspace-ingest.md)。
证据链见 [evidence.md](evidence.md)。

## 子文档

| 文件 | 内容 |
| --- | --- |
| [context.md](context.md) | 问题类别、研究问题、范围、角色、系统模型、状态矩阵、场景和成功标准 |
| [investigation.md](investigation.md) | 调研方法、领域模型、约束模型、能力矩阵、源码分析和方案对比 |
| [conclusion.md](conclusion.md) | 结论摘要、决策因素、决策表、不采用方案、限制和未决项 |
| [solution.md](solution.md) | 推荐架构、接口契约、流程、安全、可靠性、失败模式和实施计划 |
| [evidence.md](evidence.md) | 来源、命令、观察、推论、置信度、反证和已知缺口 |
| [validation/README.md](validation/README.md) | 验证目标、范围、测试矩阵、风险和清理要求 |
| [validation/case-desktop-workspace-ingest.md](validation/case-desktop-workspace-ingest.md) | `Case 1`：桌面端放入入口 |
| [validation/case-mobile-workspace-ingest.md](validation/case-mobile-workspace-ingest.md) | `Case 2`：移动端放入入口与后台传输 |
| [validation/case-replication-and-lifecycle.md](validation/case-replication-and-lifecycle.md) | `Case 3`：复制、取回与生命周期 |

## 证据链

1. 从 [context.md](context.md) 阅读问题边界与状态矩阵。
2. 从 [investigation.md](investigation.md) 阅读约束模型与能力矩阵。
3. 从 [evidence.md](evidence.md) 阅读来源、命令和推论。
4. 从 [conclusion.md](conclusion.md) 阅读决策与限制。
5. 从 [solution.md](solution.md) 阅读推荐实现与接口契约。
6. 从 [validation/README.md](validation/README.md) 阅读验证矩阵。
7. 从 [validation/case-desktop-workspace-ingest.md](validation/case-desktop-workspace-ingest.md) 开始阅读案例结果。

## 更新规则

执行验证后更新案例状态。
执行验证后更新验证矩阵。
执行验证后更新结论和限制。
执行验证后更新证据缺口。
执行验证后更新本索引。
