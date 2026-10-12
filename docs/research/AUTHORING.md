# Covio 研究文档编写方法论

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.1` |
| 状态 | 可评审 |
| 日期 | `2026-10-10` |
| 适用对象 | 自动化 agent、研发、测试、安全、运维、产品和研究人员 |
| 适用范围 | `docs/research/` 下的研究、审计、证据和验证资料 |
| 参考样例 | [macOS 后台 GUI 自动化与虚拟化控制](macos-background-gui-automation/README.md) |

本文定义一套通用研究文档方法。
自动化 agent 可以按本文生成同一类研究资料。
本文不绑定软件、平台、行业和单一案例。
本文不实现产品功能。
本文不修改应用 API。
本文不修改 Helper 协议。
本文不修改 LaunchAgent。

## 1. 目标

本文的目标是让 agent 产出可审计研究资料。
研究资料说明一类问题。
研究资料包含上下文、模型、调研、结论、方案、证据和验证计划。
研究资料不能只说明一个具体软件。
研究资料不能只说明一次事故。
具体软件、事故和环境作为案例。
案例验证一类问题。
参考资料必须支持复核。
验证结果必须能回填。

## 2. 适用范围

本文适用于需要研究结论和证据支持的任务。
任务可以来自任意技术领域。
任务可以来自任意产品阶段。
任务可以来自任意风险级别。
任务范围由研究问题决定。
任务范围不由工具、平台或案例决定。

以下任务可以使用本文。

- 技术选型和产品对比。
- 架构方案和迁移方案。
- 根因分析和系统限制分析。
- 安全、权限、合规和审计。
- 性能、可靠性、成本和容量分析。
- 自动化、集成和互操作分析。
- 平台差异和兼容性分析。
- 数据、模型、算法和评测分析。
- 流程、组织和用户体验研究。
- 方案验证、回滚和风险控制。

以下任务可以使用本文，但执行者按目标裁剪。

- 产品需求文档。
- 用户操作手册。
- 代码实现说明。
- 单次故障报告。
- 初步架构建议。

裁剪时保留四项内容。
四项内容是问题定义、证据、结论和验证边界。
缺少证据时，执行者写已知缺口。
缺少验证时，执行者写验证计划。
缺少结论时，执行者不发布确定性结论。

## 3. 核心原则

### 3.1 先定义问题类别

问题类别说明一类限制、需求或决策。
问题类别不绑定单一产品。
问题类别不绑定单一案例。
问题类别不绑定单一组织。
例如，`Case 1` 是验证案例。
`Case 1` 不定义方案边界。

### 3.2 先收集证据

结论必须有证据。
证据必须可复核。
证据必须记录来源。
证据必须记录环境和限制。
来源不足时，agent 写入已知缺口。
来源不足时，agent 不写确定性结论。

### 3.3 区分事实、推论和假设

事实是直接观察结果。
推论是从一个或多个事实得出的结论。
假设是未验证的前提。
文档必须分别标记事实、推论和假设。
文档不能把推论写成事实。
文档不能把假设写成结论。

### 3.4 分开计划和结果

计划步骤使用 `待执行` 或 `尚未执行`。
实际执行必须有时间、命令、输出摘要和结果。
未执行的步骤不能标记为通过。
失败必须保留错误码和原因。
部分成功必须列出通过项和失败项。

### 3.5 单一入口

`docs/research/` 是研究资料的唯一入口。
每个研究主题使用一个独立目录。
主题目录的 `README.md` 是统一索引。
主题索引必须包含六个章节。
六个章节必须链接对应子文档和证据链。
研究资料不建立第二套顶层归档入口。

### 3.6 安全边界

文档不写密码。
文档不写令牌。
文档不写设备序列号。
文档不写完整隐私日志。
文档不写受保护数据。
验证命令不能绑定公网服务。
验证命令不能产生未授权副作用。
临时系统设置必须恢复。
高风险操作必须有回滚步骤。

### 3.7 稳定术语

一个术语只表示一个概念。
一个概念只使用一个术语。
专有名词、命令、路径、API 和版本号保留原文。
`Case 1` 是验证案例编号。
`VMBridge` 是参考样例中的接口名称。
新主题可以定义自己的接口名称。
新主题必须登记术语表。

## 4. Agent 输入契约

自动化 agent 应先接收结构化输入。
结构化输入可以由用户提供。
结构化输入可以由 agent 从任务中提取。
缺少字段时，agent 记录缺口。
缺少关键字段时，agent 停止生成结论。
关键字段包括研究问题、问题类别、决策目标和验证边界。

```yaml
topic_id: <topic-id>
topic_title: <研究主题>
research_question: <需要回答的问题>
problem_class: <一类问题>
domain: <技术或业务领域>
decisions:
  - <需要做出的决策>
stakeholders:
  - <受影响角色>
scope:
  - <范围内事项>
out_of_scope:
  - <范围外事项>
system_model:
  - <系统组件>
  - <参与者>
  - <生命周期阶段>
  - <状态变化>
known_facts: []
assumptions: []
constraints:
  - <技术约束>
  - <合规约束>
  - <成本约束>
  - <时间约束>
evidence_sources:
  - <标准和规范>
  - <源码或配置>
  - <官方文档>
  - <本地实验>
environment:
  hardware: <硬件>
  os: <系统>
  runtime: <运行时>
  dependencies:
    - <依赖>
cases:
  - id: case-1
    name: <案例名称>
    file: case-<case-name>.md
validation:
  method: <验证方法>
  success_criteria:
    - <成功标准>
  cleanup:
    - <清理要求>
sensitive_data_policy: <脱敏要求>
status: 尚未执行
owner: 待填写
reviewer: 待填写
```

## 5. 输出结构

每个研究主题使用以下结构。

```text
docs/research/
  README.md
  AUTHORING.md
  <topic-id>/
    README.md
    context.md
    investigation.md
    conclusion.md
    solution.md
    evidence.md
    validation/
      README.md
      case-<case-name>.md
```

文件职责如下。

| 文件 | 职责 |
| --- | --- |
| `docs/research/README.md` | 研究归档入口和主题列表 |
| `AUTHORING.md` | 编写方法、agent 流程和验收规则 |
| `<topic-id>/README.md` | 主题统一索引和六个章节 |
| `context.md` | 前因、边界、模型、场景和成功标准 |
| `investigation.md` | 调研方法、来源、系统模型、方案矩阵和反证 |
| `conclusion.md` | 根因、结论、决策表、限制和未决项 |
| `solution.md` | 推荐方案、接口、流程、安全、验收和实施计划 |
| `evidence.md` | 来源、命令、观察、推论、置信度和缺口 |
| `validation/README.md` | 验证目标、范围、矩阵、风险和清理要求 |
| `validation/case-*.md` | 一个实际案例的执行记录和结果 |

## 6. 文件生成规则

### 6.1 `docs/research/README.md`

研究归档入口必须包含以下内容。

1. 职责。
2. 编写方法链接。
3. 研究主题表。
4. 归档规则。

主题表字段固定为：

| 主题 | 状态 | 索引 |
| --- | --- | --- |

编写方法链接固定为 `AUTHORING.md`。
主题链接使用相对路径。

### 6.2 主题 `README.md`

主题索引必须包含以下章节。

- `## 前因`
- `## 背景`
- `## 过程`
- `## 结果`
- `## 预期`
- `## 实现预期的手段`

每个章节必须链接至少一个子文档。
`结果` 必须链接 `conclusion.md` 和 `evidence.md`。
`预期` 必须链接 `solution.md` 和 `validation/README.md`。
`实现预期的手段` 必须链接 `solution.md`、`validation/README.md` 和 `evidence.md`。
主题索引必须包含子文档表。
主题索引必须包含证据链阅读顺序。
主题索引必须包含更新规则。

### 6.3 `context.md`

`context.md` 必须包含以下内容。

- 问题类别。
- 研究问题。
- 问题定义。
- 触发条件。
- 问题分类表。
- 适用范围。
- 范围外事项。
- 受影响角色。
- 系统模型。
- 状态矩阵。
- 场景定义。
- 成功标准。

状态矩阵按研究问题定义。
状态矩阵至少覆盖正常状态和异常状态。
状态矩阵至少覆盖边界条件。
状态矩阵至少覆盖失败条件。
状态矩阵字段使用领域的稳定术语。

### 6.4 `investigation.md`

`investigation.md` 必须包含以下内容。

- 调研方法。
- 来源范围。
- 领域模型。
- 约束模型。
- 控制路径。
- 信任边界。
- 原生工具或现有能力矩阵。
- 候选方案对比。
- 目标产品源码分析。
- 参考实现分析。
- 反证和限制。
- 已知缺口。

工具矩阵字段按领域定义。
工具矩阵至少包含能力、限制、依赖和证据来源。
候选方案对比至少包含成本、风险、成熟度和可维护性。
目标产品分析必须记录版本或 commit。

### 6.5 `conclusion.md`

`conclusion.md` 必须包含以下内容。

- 结论摘要。
- 主要根因或主要决策因素。
- 次要根因或次要决策因素。
- 根因证据链。
- 决策表。
- 不采用方案。
- 系统限制。
- 产品限制。
- 未决项。

每个根因必须有证据。
每个决策必须说明原因。
每个不采用方案必须说明风险。

### 6.6 `solution.md`

`solution.md` 必须包含以下内容。

- 推荐架构或推荐方法。
- 组件职责。
- 调用路径。
- 文件位置。
- 接口契约。
- 请求字段。
- 响应字段。
- 操作列表。
- 错误码。
- 关键流程。
- 安全设计。
- 合规设计。
- 可靠性设计。
- 失败模式。
- 验收标准。
- 实施计划。
- 回滚条件。
- 产品化条件。

接口契约必须包含传输、权限、协议和稳定字段。
首版可以只定义契约。
首版可以不实现契约。
无接口的方案可以省略接口章节。
省略时，agent 写出理由。

### 6.7 `evidence.md`

`evidence.md` 必须包含以下内容。

- 文档状态。
- 问题类别和案例映射。
- 来源等级。
- 环境事实。
- 复现命令。
- 证据索引。
- 证据详情。
- 逻辑证据链。
- 反证和限制。
- 已知缺口。
- 复核方法。
- 参考来源。
- 关联文档。

每条证据必须有唯一编号。
证据编号使用 `E-01`、`E-02` 格式。
每条证据必须记录来源、观察、推论、限制和置信度。

### 6.8 `validation/README.md`

验证目录必须包含以下内容。

- 文档状态。
- 案例索引。
- 验证目标。
- 范围内事项。
- 范围外事项。
- 当前事实。
- 成功标准。
- 前置条件。
- 风险。
- 测试矩阵。
- 证据要求。
- 清理步骤。
- 关联文档。

测试矩阵字段固定为：

| 编号 | 场景 | 当前状态 | 结果文件 |
| --- | --- | --- | --- |

测试编号使用 `V01`、`V02` 格式。
首版状态使用 `尚未执行`。
状态可以使用 `待执行`。
`待执行` 表示单个测试尚未开始。

### 6.9 `validation/case-*.md`

每个案例必须包含以下内容。

- 文档状态。
- 验证目标。
- 预检记录。
- 测试前采集。
- 每个步骤的前置条件。
- 每个步骤的命令或请求。
- 每个步骤的预期结果。
- 每个步骤的实际结果字段。
- 错误码。
- 结果汇总。
- 清理记录。
- 更新规则。
- 关联文档。

案例文件不能预填实验结果。
案例文件可以预填命令模板。
案例文件只能标记为 `尚未执行`。
执行后，agent 回填时间和实际结果。

## 7. 命名规则

主题目录使用小写英文和连字符。
固定文件名使用 `README.md`、`context.md`、`investigation.md`、`conclusion.md`、`solution.md` 和 `evidence.md`。
验证目录固定为 `validation/`。
案例文件名为 `case-<case-name>.md`。
案例编号使用 `Case 1`、`Case 2` 格式。
测试编号使用 `V01`、`V02` 格式。
证据编号使用 `E-01`、`E-02` 格式。
错误码使用小写英文和下划线。
操作名使用点号分层。
领域术语必须保持一致。

## 8. 状态规则

| 状态 | 含义 | 允许的结论 |
| --- | --- | --- |
| `尚未执行` | 只有计划 | 可以写预期，不能写结果 |
| `待执行` | 单个测试未开始 | 可以写计划，不能写结果 |
| `执行中` | 已开始，未完成 | 可以写已发生事实 |
| `通过` | 全部成功标准通过 | 可以写案例通过 |
| `部分通过` | 部分成功标准通过 | 必须列出失败项 |
| `失败` | 成功标准未通过 | 必须列出错误码和原因 |
| `阻塞` | 缺少外部条件 | 必须列出阻塞条件 |
| `已撤销` | 验证已回滚 | 必须记录清理原因 |

状态变化必须同步到以下文件。

- 主题 `README.md`。
- `validation/README.md`。
- `validation/case-*.md`。
- `conclusion.md`，如果结论变化。
- `evidence.md`，如果证据变化。
- `solution.md`，如果实施条件变化。

## 9. 来源等级

| 等级 | 来源 | 用途 | 置信度 |
| --- | --- | --- | --- |
| A | 标准、规范、法规、官方接口定义、本机 `man` | 权威行为和硬约束 | 高 |
| B | 目标项目固定版本的源码、配置、测试和发布制品 | 实现边界和可验证行为 | 高 |
| C | 官方项目文档、官方知识库、厂商文档 | 产品能力和操作方式 | 中 |
| D | 本机实验、日志、遥测和可复现样例 | 当前环境事实 | 高，但范围小 |
| E | 第三方文章、社区讨论和非正式报告 | 背景和线索 | 低 |

高影响结论必须有 A 或 B 证据。
D 证据只代表当前环境。
E 证据不能单独支持关键决策。
来源冲突时，使用高等级来源。
来源冲突未解决时，agent 写入已知缺口。
法规、安全和数据结论优先使用 A 来源。

## 10. 证据记录规则

证据条目使用以下模板。

````md
### E-XX：<证据主题>

来源等级：<A/B/C/D/E>
环境：<系统、版本、配置、数据范围或 commit>
命令或来源：`<命令>` 或 `<来源链接>`
关键输出：

```text
<输出摘要>
```

观察：<直接事实>
推论：<从事实得出的结论>
反证：<与结论冲突的观察>
限制：<适用边界>
置信度：<高/中高/中/低>
关联：<要求或验证步骤>
````

证据不能写入完整隐私日志。
证据不能写入密码或令牌。
证据不能把失败输出写成成功结果。
证据不能省略超时阈值。
证据不能省略版本和 commit。
证据不能省略采样范围。
证据不能省略失败样本。

## 11. 逻辑链规则

每个重要结论使用以下链路。

```text
研究问题
  -> 来源
  -> 观察
  -> 推论
  -> 决策
  -> 验证条件
  -> 回填位置
```

链路必须能从主题 `README.md` 到达。
链路必须能从 `evidence.md` 到达验证案例。
链路必须能从验证案例回到主题 `README.md` 和 `evidence.md`。
反证必须保留。
反证不能被删除。
反证影响结论时，agent 修改结论和置信度。

## 12. 链接规则

链接只使用相对路径。
链接目标必须存在。
主题 `README.md` 必须链接全部子文档。
子文档必须链接主题 `README.md`。
`evidence.md` 必须链接 `validation/README.md`。
验证目录必须链接 `evidence.md`。
案例文件必须链接验证目录、证据附录和主题索引。
禁止恢复 `docs/validation/`。
禁止使用旧路径跳转页。
禁止依赖绝对本地路径作为 Markdown 链接。
命令中的本地路径除外。

## 13. Agent 工作流

### 13.1 阶段一：接收任务

Agent 读取用户目标。
Agent 提取研究问题。
Agent 提取问题类别。
Agent 提取决策目标。
Agent 提取适用范围。
Agent 提取范围外事项。
Agent 提取已知事实。
Agent 提取验证环境。
Agent 提取案例列表。
Agent 生成 `topic_id`。
Agent 使用 `topic_id` 创建主题目录。

关口：没有明确研究问题时，agent 不生成结论。
关口：没有明确问题类别时，agent 不生成通用结论。

### 13.2 阶段二：定义边界

Agent 定义研究对象。
Agent 定义受影响角色。
Agent 定义系统组件。
Agent 定义生命周期。
Agent 定义状态矩阵。
Agent 定义成功标准。
Agent 定义失败标准。
Agent 定义范围外事项。

关口：状态矩阵没有覆盖用户场景时，agent 补充矩阵。
关口：成功标准不可验证时，agent 重写成功标准。

### 13.3 阶段三：收集事实

Agent 按来源等级收集资料。
Agent 优先阅读 A 和 B 来源。
Agent 记录命令、时间和输出摘要。
Agent 给每条事实分配证据编号。
Agent 删除敏感信息。
Agent 记录来源限制。

关口：高影响结论没有 A 或 B 证据时，agent 标记缺口。
关口：证据不可复现时，agent 记录环境缺口。

### 13.4 阶段四：建立模型

Agent 定义领域模型。
Agent 定义权限模型。
Agent 定义数据流。
Agent 定义控制流。
Agent 定义信任边界。
Agent 定义约束模型。
Agent 定义备选方案。
Agent 写出反证。

关口：模型不能解释关键观察时，agent 修改模型。
关口：反证不能解释时，agent 降低结论置信度。

### 13.5 阶段五：形成结论

Agent 从事实推导根因或决策因素。
Agent 区分主要因素和次要因素。
Agent 给每个因素引用证据编号。
Agent 写出决策表。
Agent 写出不采用方案。
Agent 写出限制和未决项。

关口：结论没有证据编号时，agent 不发布结论。
关口：决策没有风险和限制时，agent 补充风险和限制。

### 13.6 阶段六：设计解决路径

Agent 定义推荐架构或推荐方法。
Agent 定义组件职责。
Agent 定义接口契约。
Agent 定义调用路径。
Agent 定义安全边界。
Agent 定义合规边界。
Agent 定义可靠性边界。
Agent 定义失败码。
Agent 定义验收标准。
Agent 定义回滚条件。
Agent 定义产品化条件。

关口：方案依赖未授权权限时，agent 停止生成。
关口：方案声称不可靠能力可靠时，agent 停止生成。
关口：方案没有回滚路径时，agent 补充回滚路径。

### 13.7 阶段七：设计验证

Agent 建立验证目录。
Agent 建立案例索引。
Agent 建立测试矩阵。
Agent 定义前置条件。
Agent 定义成功标准。
Agent 定义证据要求。
Agent 定义清理步骤。
Agent 保持案例状态为 `尚未执行`。
Agent 不预填结果。

关口：验证步骤没有清理要求时，agent 补充清理要求。
关口：验证步骤有数据风险时，agent 补充备份和回滚。

### 13.8 阶段八：组装索引

Agent 生成主题 `README.md`。
Agent 写入六个必需章节。
Agent 在每章链接对应子文档。
Agent 加入子文档表。
Agent 加入证据链。
Agent 加入更新规则。
Agent 更新 `docs/research/README.md` 主题表。

关口：六个章节缺少任一章节时，agent 不提交。
关口：主题入口缺少证据链时，agent 补充证据链。

### 13.9 阶段九：验证输出

Agent 检查链接。
Agent 检查标题。
Agent 检查编号。
Agent 检查状态。
Agent 检查敏感信息。
Agent 检查 `git diff --check`。
Agent 输出文件清单。
Agent 输出验证结果。
Agent 输出未解决缺口。

## 14. Agent Prompt 模板

```text
你是 Covio 研究文档 agent。

任务：
为 <topic_title> 创建一套研究文档。

输入：
- topic_id: <topic_id>
- research_question: <research_question>
- problem_class: <problem_class>
- domain: <domain>
- decisions: <decisions>
- stakeholders: <stakeholders>
- 适用范围: <scope>
- 范围外事项: <out_of_scope>
- 系统模型: <system_model>
- 已知事实: <known_facts>
- 待验证假设: <assumptions>
- 约束: <constraints>
- 证据来源: <evidence_sources>
- 验证环境: <environment>
- 案例: <cases>
- 验证方法: <validation>
- 当前状态: <status>
- 负责人: <owner>
- 复核人: <reviewer>

必须输出：
- docs/research/README.md 的主题入口
- docs/research/<topic_id>/README.md
- docs/research/<topic_id>/context.md
- docs/research/<topic_id>/investigation.md
- docs/research/<topic_id>/conclusion.md
- docs/research/<topic_id>/solution.md
- docs/research/<topic_id>/evidence.md
- docs/research/<topic_id>/validation/README.md
- docs/research/<topic_id>/validation/case-<case_name>.md

必须遵守：
- 按 docs/research/AUTHORING.md 生成。
- 问题类别优先于单一案例。
- 结论必须有证据编号。
- 事实、推论和假设必须分开。
- 未执行验证必须标记为尚未执行。
- 不写密码、令牌、序列号和完整隐私日志。
- 不修改应用代码。
- 不恢复 docs/validation/。
- 链接使用相对路径。

完成后执行：
- 相对链接检查。
- 六个章节检查。
- 证据编号检查。
- 状态检查。
- git diff --check。
```

## 15. 文件模板

### 15.1 主题 `README.md`

````md
# <主题标题>

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 初稿，可评审 |
| 日期 | `<YYYY-MM-DD>` |
| 适用对象 | `<对象>` |
| 当前验证环境 | `<环境>` |
| 当前结论 | `<结论>` |
| 验证状态 | 尚未执行 |

## 前因

<问题背景>
前因、研究问题、问题类别、适用边界、场景和成功标准见 [context.md](context.md)。
证据链见 [evidence.md](evidence.md)。

## 背景

<系统背景>
技术说明、来源等级和证据字段见 [investigation.md](investigation.md)。
当前环境和原始观测见 [evidence.md](evidence.md)。

## 过程

<调研过程>
调研方法和方案矩阵见 [investigation.md](investigation.md)。
复现命令、来源、观察和推论见 [evidence.md](evidence.md)。
案例验证过程见 [validation/<case-file>.md](validation/<case-file>.md)。

## 结果

<主要结论>
根因、决策表和限制见 [conclusion.md](conclusion.md)。
证据索引和逻辑链见 [evidence.md](evidence.md)。

## 预期

<目标能力>
验收标准见 [solution.md](solution.md)。
验证目标、范围、矩阵和风险见 [validation/README.md](validation/README.md)。
证据链见 [evidence.md](evidence.md)。

## 实现预期的手段

<推荐架构或推荐方法>
推荐方案、接口契约、流程、安全、失败模式和实施计划见 [solution.md](solution.md)。
实际验证记录见 [validation/<case-file>.md](validation/<case-file>.md)。
证据链见 [evidence.md](evidence.md)。

## 子文档

| 文件 | 内容 |
| --- | --- |
| [context.md](context.md) | <内容> |
| [investigation.md](investigation.md) | <内容> |
| [conclusion.md](conclusion.md) | <内容> |
| [solution.md](solution.md) | <内容> |
| [evidence.md](evidence.md) | <内容> |
| [validation/README.md](validation/README.md) | <内容> |
| [validation/<case-file>.md](validation/<case-file>.md) | <内容> |

## 证据链

1. 从 [context.md](context.md) 阅读问题边界。
2. 从 [investigation.md](investigation.md) 阅读技术分析。
3. 从 [evidence.md](evidence.md) 阅读来源、命令和推论。
4. 从 [conclusion.md](conclusion.md) 阅读根因和限制。
5. 从 [solution.md](solution.md) 阅读推荐实现。
6. 从 [validation/README.md](validation/README.md) 阅读验证矩阵。
7. 从 [validation/<case-file>.md](validation/<case-file>.md) 阅读案例结果。

## 更新规则

执行验证后更新案例状态。
执行验证后更新验证矩阵。
执行验证后更新结论和限制。
执行验证后更新证据缺口。
执行验证后更新本索引。
```

````
### 15.2 `context.md`

````md
# 前因与问题边界

> 本文件承载前因、研究问题、问题类别、适用边界、场景和成功标准。

## 1. 问题类别与适用边界

### 1.1 研究问题

<研究问题>

### 1.2 问题定义

<一类问题的定义>

### 1.3 触发条件

1. <条件一>
2. <条件二>

### 1.4 问题分类

| 类别 | 表现 | 主要因素 | 推荐路径 |
| --- | --- | --- | --- |
| <类别> | <表现> | <因素> | <路径> |

### 1.5 状态矩阵

| 状态 | <能力一> | <能力二> | <能力三> |
| --- | --- | --- | --- |
| <正常状态> | <结果> | <结果> | <结果> |
| <异常状态> | <结果> | <结果> | <结果> |
| <边界状态> | <结果> | <结果> | <结果> |
| <失败状态> | <结果> | <结果> | <结果> |

### 1.6 解决路径

<路径说明>

## 2. 场景定义

### 2.1 <场景一>

<定义和限制>

### 2.2 <场景二>

<定义和限制>

## 3. 成功标准

<成功标准>
```

````
### 15.3 `investigation.md`

````md
# 调研方法与技术分析

> 本文件承载调研方法、系统模型、现有能力矩阵、权限模型、产品分析和方案对比。

## 1. 调研方法

<方法>

## 2. 来源范围

| 等级 | 来源 | 用途 |
| --- | --- | --- |
| A | <来源> | <用途> |
| B | <来源> | <用途> |

## 3. 系统模型

<参与者、组件、生命周期、状态和约束>

## 4. 现有能力矩阵

| 能力 | 环境 | 用途 | 限制 |
| --- | --- | --- | --- |
| <能力> | <环境> | <用途> | <限制> |

## 5. 权限模型

<权限模型>

## 6. 目标产品分析

<源码和官方文档分析>

## 7. 候选方案分析

<候选方案、依赖、证据、限制和风险>

## 8. 市场对比

| 产品 | 核心能力 | 自动化接口 | 风险 | 限制 |
| --- | --- | --- | --- | --- |
| <产品> | <能力> | <接口> | <风险> | <限制> |

## 9. 反证和限制

<反证和限制>

## 10. 已知缺口

<已知缺口>
```

````
### 15.4 `conclusion.md`

````md
# 根因、结论与限制

> 本文件承载结论摘要、根因、决策表、限制和不采用方案。

## 1. 结论摘要

<结论>

## 2. 根因或决策因素

### 2.1 主要因素

<主要因素和证据编号>

### 2.2 次要因素

<次要因素和证据编号>

## 3. 决策表

| 决策 | 选择 | 原因 | 备选路径 |
| --- | --- | --- | --- |
| <决策> | <选择> | <原因> | <备选> |

## 4. 逻辑证据链

### 4.1 观察一

观察：<事实>
推论：<推论>
置信度：<置信度>
证据：`E-XX`

## 5. 限制和未决项

### 5.1 系统限制

<限制>

### 5.2 产品限制

<限制>

### 5.3 未决项

<未决项>
```

````
### 15.5 `solution.md`

````md
# 推荐架构、接口与实施计划

> 本文件承载推荐架构、接口契约、流程、资源策略、安全、失败模式、验收和实施计划。

## 1. 推荐架构

### 1.1 路径选择

<路径选择>

### 1.2 组件

| 组件 | 职责 | 环境 | 启动方式 |
| --- | --- | --- | --- |
| <组件> | <职责> | <环境> | <方式> |

### 1.3 调用路径

```text
<调用路径>
```

## 2. 接口契约

### 2.1 传输

<传输>

### 2.2 请求

```json
{"request_id":"req-0001","op":"health","args":{}}
```

### 2.3 响应

```json
{"ok":true,"data":{},"error_code":null,"error_message":null}
```

### 2.4 操作

| 操作 | 参数 | 返回 | 说明 |
| --- | --- | --- | --- |
| `health` | 无 | 状态 | 健康检查 |

### 2.5 错误码

| 错误码 | 触发条件 | 可重试 | 人工处理 |
| --- | --- | --- | --- |
| `<error_code>` | <条件> | <是或否> | <处理> |

## 3. 流程

<关键流程>

## 4. 电源或资源策略

<策略>

## 5. 安全设计

<安全设计>

## 6. 失败模式

<失败模式>

## 7. 验收标准

<验收标准>

## 8. 实施计划

<实施计划>
```

````
### 15.6 `evidence.md`

````md
# 证据附录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 审计记录，可复核 |
| 日期 | `<YYYY-MM-DD>` |
| 主文 | [主题索引](README.md) |
| 验证目录 | [验证目录](validation/README.md) |
| 案例 | [案例](validation/<case-file>.md) |

## 1. 来源等级

| 等级 | 来源 | 用途 | 置信度 |
| --- | --- | --- | --- |
| A | <来源> | <用途> | <置信度> |

## 2. 环境事实

| 项目 | 值 | 命令 | 置信度 |
| --- | --- | --- | --- |
| <项目> | <值> | `<命令>` | <置信度> |

## 3. 证据索引

| 编号 | 主题 | 来源 | 结论 | 置信度 |
| --- | --- | --- | --- | --- |
| E-01 | <主题> | <来源> | <结论> | <置信度> |

## 4. 证据详情

### E-01：<主题>

来源等级：<等级>
环境：<环境>
命令或来源：`<命令>`
关键输出：

```text
<输出摘要>
```

观察：<事实>
推论：<推论>
反证：<反证>
限制：<限制>
置信度：<置信度>
关联：<关联>

## 5. 逻辑证据链

<逻辑链>

## 6. 反证和限制

<反证和限制>

## 7. 已知缺口

<缺口>

## 8. 复核方法

1. <复核步骤>

## 参考来源

- [<来源>](<URL>)

## 9. 关联文档

- [主题索引](README.md)
- [验证目录](validation/README.md)
- [案例](validation/<case-file>.md)
```

````
### 15.7 `validation/README.md`

````md
# <主题标题>验证目录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 状态 | 尚未执行 |
| 日期 | `<YYYY-MM-DD>` |
| 目标环境 | <环境> |
| 问题类别 | <问题类别> |
| 主方案 | [主题索引](../README.md) |
| 证据附录 | [证据附录](../evidence.md) |
| 验证记录 | [Case 1](case-<case-file>.md) |

## 1. 案例索引

| 编号 | 案例 | 状态 | 记录 |
| --- | --- | --- | --- |
| Case 1 | <案例> | 尚未执行 | [case-<case-file>.md](case-<case-file>.md) |

## 2. 目标

<验证目标>

## 3. 范围

### 3.1 范围内

<范围内事项>

### 3.2 范围外

<范围外事项>

## 4. 当前事实

<当前事实>

## 5. 成功标准

<成功标准>

## 6. 前置条件

<前置条件>

## 7. 风险

<风险>

## 8. 测试矩阵

| 编号 | 场景 | 当前状态 | 结果文件 |
| --- | --- | --- | --- |
| V01 | <场景> | 待执行 | `case-<case-file>.md` |

## 9. 证据要求

<证据要求>

## 10. 清理步骤

<清理步骤>

## 11. 关联文档

- [主题索引](../README.md)
- [证据附录](../evidence.md)
````

### 15.8 `validation/case-*.md`

````md
# <案例名称>验证记录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 状态 | 尚未执行 |
| 执行人 | 待填写 |
| 复核人 | 待填写 |
| 环境 | <环境> |
| 版本 | <版本> |
| 主方案 | [主题索引](../README.md) |
| 证据附录 | [证据附录](../evidence.md) |
| 目录说明 | [验证目录](README.md) |

## 1. 验证目标

<目标>

## 2. 预检记录

| 项目 | 值 | 状态 |
| --- | --- | --- |
| <项目> | <值> | <状态> |

## 3. 测试前采集

```sh
<命令>
```

记录字段：

```text
<字段>:
```

## 4. 验证步骤

### V01：<步骤名称>

前置：<前置条件>

请求：

```json
{"request_id":"v01","op":"<op>","args":{}}
```

记录：

```text
Start time:
End time:
Response:
Error code:
Result: PENDING
```

通过条件：<条件>

## 5. 结果汇总

<结果汇总>

## 6. 清理记录

<清理记录>

## 7. 更新规则

<更新规则>

## 8. 关联文档

- [主题索引](../README.md)
- [证据附录](../evidence.md)
- [验证目录](README.md)
````

## 16. 自动化验收命令

以下命令可由 agent 执行。

### 16.1 检查目录

```sh
find docs/research -maxdepth 4 -type f | sort
test ! -d docs/validation
```

### 16.2 检查主题索引章节

```sh
TOPIC="${TOPIC:-<topic-id>}"
for h in 前因 背景 过程 结果 预期 实现预期的手段; do
  rg -q "^## ${h}$" "docs/research/${TOPIC}/README.md"
done
```

### 16.3 检查相对链接

```sh
python3 - <<'PY'
import re
import sys
from pathlib import Path
from urllib.parse import unquote

root = Path('docs/research')
errors = []
count = 0
for path in root.rglob('*.md'):
    lines = path.read_text(encoding='utf-8').splitlines()
    fence_char = None
    fence_len = 0
    for line in lines:
        fence = re.match(r'^\s*(`{3,}|~{3,})', line)
        if fence:
            run = fence.group(1)
            char = run[0]
            length = len(run)
            if fence_char is None:
                fence_char = char
                fence_len = length
            elif char == fence_char and length >= fence_len:
                fence_char = None
                fence_len = 0
            continue
        if fence_char is not None:
            continue
        for match in re.finditer(r'(?<!!)\[[^\]]+\]\(([^)]+)\)', line):
            target = match.group(1).strip()
            if target.startswith(('#', 'http://', 'https://', 'mailto:')):
                continue
            target = target.split('#', 1)[0]
            if not target:
                continue
            count += 1
            resolved = (path.parent / unquote(target)).resolve()
            if not resolved.exists():
                errors.append((path, target))
if errors:
    for path, target in errors:
        print('missing:', path, '->', target)
    sys.exit(1)
print('relative links:', count)
PY
```

### 16.4 检查未执行状态

```sh
TOPIC="${TOPIC:-<topic-id>}"
rg -n "尚未执行|待执行|PENDING" "docs/research/${TOPIC}"
```

### 16.5 检查敏感信息

```sh
TOPIC="${TOPIC:-<topic-id>}"
rg -n -i "password|passwd|token|secret|serial|BEGIN (RSA|OPENSSH|PRIVATE)" "docs/research/${TOPIC}"
```

### 16.6 检查 Markdown 空白

```sh
git diff --check
```

## 17. 失败处理

| 失败 | Agent 动作 | 文档动作 |
| --- | --- | --- |
| 研究问题不清 | 停止写强结论 | 写入未决项 |
| 缺少来源 | 停止写强结论 | 写入已知缺口 |
| 来源冲突 | 使用高等级来源 | 写入反证 |
| 命令超时 | 记录阈值和环境 | 写入限制 |
| 权限不足 | 停止高风险操作 | 写入权限要求 |
| 数据风险高 | 停止验证 | 写入备份和回滚 |
| 验证无事前条件 | 不执行验证 | 标记 `尚未执行` |
| 结果部分通过 | 保留失败证据 | 标记 `部分通过` |
| 需要改代码 | 停止文档任务 | 生成后续实施项 |
| 缺少清理步骤 | 不执行验证 | 补充清理步骤 |

## 18. 禁止事项

禁止把单一产品写成问题类别。
禁止把单一案例写成通用保证。
禁止把案例结论写成跨环境保证。
禁止把本地实验写成平台规范。
禁止把计划写成结果。
禁止把失败写成通过。
禁止删除反证。
禁止隐藏已知缺口。
禁止绕过权限控制。
禁止声称未验证能力可靠。
禁止暴露敏感接口到公网。
禁止永久修改系统设置。
禁止写入密码、令牌、序列号或完整隐私日志。
禁止恢复 `docs/validation/`。
禁止保留旧路径跳转页。

## 19. Definition of Done

以下条件全部满足时，agent 才可提交。

1. 主题目录存在。
2. 九个文件存在。
3. 主题索引包含六个必需章节。
4. 每个章节链接有效。
5. 子文档链接有效。
6. 证据编号唯一。
7. 测试编号唯一。
8. 状态值有效。
9. 未执行验证标记为 `尚未执行`。
10. 每个结论引用证据。
11. 每个证据记录来源和限制。
12. 每个验证步骤有清理要求。
13. 文档无密码、令牌、序列号和完整隐私日志。
14. `docs/validation/` 不存在。
15. `git diff --check` 通过。
16. 文件清单和验证结果交给用户。

## 20. 参考样例映射

| 方法论产物 | 当前样例 |
| --- | --- |
| 研究入口 | [docs/research/README.md](README.md) |
| 主题索引 | [macos-background-gui-automation/README.md](macos-background-gui-automation/README.md) |
| 前因和边界 | [context.md](macos-background-gui-automation/context.md) |
| 调研分析 | [investigation.md](macos-background-gui-automation/investigation.md) |
| 根因结论 | [conclusion.md](macos-background-gui-automation/conclusion.md) |
| 推荐方案 | [solution.md](macos-background-gui-automation/solution.md) |
| 证据附录 | [evidence.md](macos-background-gui-automation/evidence.md) |
| 验证目录 | [validation/README.md](macos-background-gui-automation/validation/README.md) |
