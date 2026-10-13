# Covio 工作流

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.1` |
| 状态 | 待评审 |
| 日期 | `2026-10-13` |
| 适用对象 | 自动化 agent、研发、测试和发布人员 |
| 适用范围 | 本仓库的全部代码、文档和配置改动 |

本目录定义 Covio 的 issue-first 工作流。
本目录是工作流规则的唯一入口。
本目录不定义产品行为。产品行为放在 `docs/covio-product-master.md`。
本目录不定义架构决策。架构决策放在 `docs/adr/`。
本目录不定义研究方法。研究方法放在 `docs/research/AUTHORING.md`。
本目录不定义路线图文档和 issue 定义文件的格式。格式放在 `docs/roadmap/AUTHORING.md`。

## 铁律

1. 没有 issue 就不改代码。先建 issue，再建分支。
2. 一条分支只做一个 issue。分支名带 issue 本地编号。
3. 每次提交引用 issue。commit 尾行写 `Refs:`。
4. 短分支合回集成分支后，显式执行 `gh issue close`。`Closes` 关键字不会自动关闭。
5. 完成后回填 issue：勾选子项、写结论、更新 `docs/roadmap/README.md` 的状态。
6. 大工作先立路线图。一个路线图分成有序阶段，一个阶段一个 milestone。

## 文件索引

| 文件 | 职责 |
| --- | --- |
| 本文档 | 索引、铁律、术语表 |
| [issue-first.md](issue-first.md) | issue 生命周期、分支命名、commit 格式、PR 规则、例外清单 |
| [roadmap-first.md](roadmap-first.md) | 路线图的立项、拆解、排期、进度汇总、阶段收口和变更 |
| [work-types.md](work-types.md) | 八种工作类型到产物和 Issue Type 的映射，以及 issue 正文模板 |
| [issue-first-flow.html](issue-first-flow.html) | 流程图。两幅图：主流程和分支拓扑。用浏览器打开。 |

`issue-first-flow.html` 是上面三份文档的图示，不是规则来源。
图与正文不一致时，以正文为准。

agent 的强制契约在仓库根目录的 `AGENTS.md`。
`CLAUDE.md` 只有一行 `@AGENTS.md`，供 Claude Code 导入。

## 术语表

一个术语只表示一个概念。一个概念只使用一个术语。

| 术语 | 含义 |
| --- | --- |
| 路线图 | 覆盖一个可判定产品结果的文档。放在 `docs/roadmap/<slug>.md`。 |
| 阶段 | 路线图内的一段有序工作。用一个 `P<n>` 编号标识。 |
| 阶段编号 | 阶段的标识，形如 `P0`、`P1`。只在所属路线图内唯一。 |
| 阶段名称 | 阶段的中文名，形如「工作区模型」。 |
| 里程碑 | 阶段在 GitHub 上的投影。一个阶段对应一个 milestone。 |
| 阶段 label | 阶段在 issue 上的标记，形如 `phase-2-workspace-model`。 |
| 本地编号 | issue 定义文件里的编号，形如 `E03` 或 `E03-S02`。 |
| GitHub 编号 | issue 在 GitHub 上的数字编号，形如 `#27`。 |
| 映射 | 本地编号到 GitHub 编号的对应关系。存放在 `docs/roadmap/issues/.created.json`。 |
| 集成分支 | 承接全部短分支的长期分支。当前是 `feature/swiftui-macos`。 |
| 短分支 | 为一个 issue 开的分支。完成后合回集成分支。 |
| epic | 带 sub-issue 的大颗粒工作包。归属且仅归属一个阶段。本地编号形如 `E03`。 |
| sub-issue | epic 下的工作项。本地编号形如 `E03-S02`。 |
| Issue Type | GitHub 原生字段。取值 `Goal`、`Design`、`Plan`、`Task`、`Bug`、`Feature`、`Optimization`。 |
| 尾行 | commit message 最后一段的 `Refs:` 或 `Closes:` 行。 |
| 豁免 | 不建 issue 的改动。豁免仍要写尾行和 `Waiver:` 理由。 |

## 工作类型速查

八种工作类型的完整定义见 [work-types.md](work-types.md)。

| 类型 | 有独立 issue | Issue Type |
| --- | --- | --- |
| goal | 有 | `Goal` |
| aim | 无。写在 Goal 正文里 | —— |
| design | 有 | `Design` |
| plan | 有 | `Plan` |
| task | 有 | `Task` |
| problem | 有 | `Bug` |
| optimization | 有 | `Optimization` |
| commit | 无。挂在所属 issue 上 | —— |

`aim` 和 `commit` 没有独立产物，所以不占 Issue Type。
不要为 `aim` 或 `commit` 建 issue。

## 一页流程

1. 找 issue。没有就按 [work-types.md](work-types.md) 的模板建一个。
2. 切分支。`git switch -c feature/E03-S02-workbench-store feature/swiftui-macos`。
3. 实现。改动只覆盖这个 issue 的范围。
4. 提交。commit 尾行写 `Refs: E03-S02`。
5. 开 PR。目标是集成分支。body 里写 `Refs #27`。
6. 合回集成分支后关闭 issue。`gh issue close 27 --comment "已合入 <sha>。"`。

细节见 [issue-first.md](issue-first.md)。

### 大工作

目标需要 3 个或更多 epic 时，先走路线图流程，再走上面的单 issue 流程。

1. 立项。判定、拆解、切阶段。见 [roadmap-first.md](roadmap-first.md) 第 2 节。
2. 排期。建 milestone 和阶段 label，给 issue 挂 milestone。见第 3 节。
3. 汇总。进度从 sub-issue 的实际状态推导，不手写。见第 4 节。
4. 收口。milestone 全关且退出条件满足后，集成分支一次合入 `main`。见第 5 节。

路线图文档和 issue 定义文件的格式见 [../roadmap/AUTHORING.md](../roadmap/AUTHORING.md)。
