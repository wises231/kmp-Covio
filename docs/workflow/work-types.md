# 工作类型

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.1` |
| 状态 | 待评审 |
| 日期 | `2026-10-13` |
| 适用范围 | 八种工作类型到产物、Issue Type 和 label 的映射 |

本文定义八种工作类型的判断依据和产物落位。
本文不定义流程步骤。流程见 [issue-first.md](issue-first.md)。
本文不定义路线图的立项、排期和收口。这些流程见 [roadmap-first.md](roadmap-first.md)。

## 1. 映射表

| 工作类型 | 判断依据 | 产物路径 | Issue Type | 必需 label | 关闭条件 |
| --- | --- | --- | --- | --- | --- |
| goal | 跨多个会话才能达成，要拆成多个 sub-issue，有可判定的退出条件，且归属且仅归属一个阶段 | `docs/roadmap/issues/E*-*.md` 和 `docs/roadmap/*.md` | `Goal` | `epic` 加 `phase-*` | 全部 sub-issue 已关闭，退出条件逐条打勾 |
| aim | 不是独立产物。是 Goal 正文的「目标」一节，或 PR 的「改了什么」一节 | 不产生文件 | 不建 issue | —— | 不适用 |
| design | 写代码之前要定取舍，有两条以上候选方案，结论约束后续实现 | `docs/adr/ADR-NNN-*.md`、`docs/design/<topic>.md` 或 `docs/research/<topic>/conclusion.md` | `Design` | `documentation` 加 `area/*` | ADR 状态改为「已接受」，或结论通过评审 |
| plan | 要排阶段、顺序和依赖，不产出可运行代码 | `docs/roadmap/*.md`、`docs/research/<topic>/solution.md` | `Plan` | `documentation` 加 `phase-*` | 计划合入集成分支，且被至少一个 Goal 引用 |
| task | 有明确验收标准的实现工作，一个会话能做完 | 源码和测试文件 | `Task` | `enhancement` 加 `phase-*` 加 `area/*` | 代码进集成分支，`scripts/test-all.sh` 全绿，验收标准逐条打勾 |
| problem | 实际行为与预期不符，有可复现步骤 | 修复和回归测试 | `Bug` | `bug` 加 `area/*` | 复现步骤不再复现，回归测试进 CI |
| optimization | 有一个可测量的基线数字，目标是改掉那个数字 | 改动和前后对比证据 | `Optimization` | `area/perf` 加 `phase-*` | 证据表记录前后数值且达标 |
| commit | 不是 issue。是 task、problem、optimization 的最小落地单位 | 一个 git commit | 不建 issue | —— | 不适用。由尾行 `Refs:` 挂到 issue 上 |

`phase-*` label 的格式和 milestone 标题的格式见 [../roadmap/AUTHORING.md](../roadmap/AUTHORING.md) 第 2 节。
sub-issue 的粒度规则见 [roadmap-first.md](roadmap-first.md) 第 2.4 节。

### 1.1 aim 和 commit

`aim` 和 `commit` 没有独立产物。
为它们建 issue 会产生无法关闭的空壳。

`aim` 写在 Goal 正文的「目标」一节。
`commit` 挂在所属 issue 的时间线上。

### 1.2 problem 和 optimization 的边界

有基线数字的叫 optimization。
没有基线数字的叫 problem。

`area/perf` 上的改动如果写不出基线数字，按 problem 走。

### 1.3 研究类的归类

`research` 和 `spike` label 的 issue 归入 `Task`。
产物路径是 `docs/research/<topic>/`。
研究方法见 `docs/research/AUTHORING.md`。

研究结论约束后续实现时，另建一个 `Design` 类型的 issue 承载结论。
不要把研究和决策放在同一个 issue 里。

### 1.4 Issue Type 依赖账号设置

GitHub 的 Issue Type 是账号级对象，不属于仓库。
账号里没有创建过自定义类型时，`gh issue create --type <T>` 会失败。
错误是 `type "<T>" not found; available types:`，冒号后面是空的。

`gh` 先建 issue，再单独设置 type。
因此 type 失败时 issue 已经建出来了，只是 type 是空的。
`--parent` 和后续步骤也可能跟着中断。

读账号里的类型要 `read:user` scope。建类型要 `user` scope。
`user` 包含 `read:user`，所以申请 `user` 一个就够。
scope 不足时 `gh api /user/issue-types` 返回 403。

修复分两步。第一步必须由人执行：

```sh
gh auth refresh -h github.com -s user
bash scripts/sync-issue-types.sh
```

`gh api /repos/<owner>/<repo>/issue-types` 不需要这个 scope。
它返回仓库已启用的类型，不是账号里的全部类型。
仓库默认带 GitHub 内置的 `Task`、`Bug`、`Feature` 三个。
`gh issue edit --type` 读的是账号级列表。
账号级列表读不到时，内置的三个也设不上。

`gh auth status` 显示的账号名可能是改名前的旧名。
判断当前身份用：

```sh
gh api /user --jq .login
```

**警告：** 账号没有对应类型时 `type:` 字段静默失效。
issue 建出来了，type 是空的。
建完 issue 后核对：

```sh
gh issue view <N> --json number,issueType
```

`issueType` 是 `null` 时，类型没有设上。

## 2. issue 正文模板

在 GitHub 上建 issue 时用 `.github/ISSUE_TEMPLATE/` 下的表单。
表单会自动设置 Issue Type 和 label。

在本仓库里建 issue 定义文件时用下面的模板。
文件放在 `docs/roadmap/issues/`，命名是 `<本地编号>-<slug>.md`。
front-matter 的字段定义见 `docs/roadmap/AUTHORING.md` 第 5 节。

### 2.1 Goal

```markdown
---
id: E10
type: Goal
title: "<标题>"
labels: [epic, phase-3-widgets]
parent: null
milestone: "P3 · Widgets 首页"
blocked-by: []
---

## 背景

<为什么需要这个目标。现状是什么。>

## 目标

<达成后世界是什么样。逐条写。>

## 范围

范围内：

- <包含什么。>

范围外：

- <不包含什么。>

## 子项

- [ ] `E10-S01` <子项标题>
- [ ] `E10-S02` <子项标题>

## 退出条件

1. <逐条可判定。>

## 依赖

<前置 issue 的本地编号。没有就写「无」。>

## 风险

<可能失败的点和缓解办法。>
```

### 2.2 Design

```markdown
---
id: E10-S01
type: Design
title: "<标题>"
labels: [documentation, phase-3-widgets, area/widget]
parent: E10
milestone: "P3 · Widgets 首页"
blocked-by: []
---

## 背景

<要定下什么。为什么现在定。>

## 待决策

1. <问题一。>
2. <问题二。>

## 候选方案

### 方案 A：<名称>

<做法、代价、适用条件。>

### 方案 B：<名称>

<做法、代价、适用条件。>

## 判定依据

<用什么标准选。标准要可验证。>

## 决策

<选哪个，为什么。未定时写「待定」。>

## 证据

<实测记录、外部资料、代码引用。标出哪些是事实，哪些是推论。>

## 影响

<决策约束了哪些后续工作。哪些 issue 因此改写或关闭。>

## 依赖

<前置 issue 的本地编号。没有就写「无」。>
```

产物是 ADR 时，按 `docs/adr/ADR-001-macos-ui-swiftui.md` 的格式写。
ADR 的头部用列表，不用表格。
ADR 的增量决策用 `- 补充：` 行追加。

### 2.3 Plan

```markdown
---
id: E10-S02
type: Plan
title: "<标题>"
labels: [documentation, phase-3-widgets]
parent: E10
milestone: "P3 · Widgets 首页"
blocked-by: []
---

## 背景

<计划覆盖什么范围。为什么需要计划。>

## 阶段划分

| 阶段 | 内容 | 完成判据 |
| --- | --- | --- |
| P0 | <内容> | <判据> |
| P1 | <内容> | <判据> |

## 依赖

<前置 issue 的本地编号。没有就写「无」。>

## 回滚

<阶段失败时怎么退回去。>
```

### 2.4 Task

```markdown
---
id: E10-S03
type: Task
title: "<标题>"
labels: [enhancement, phase-3-widgets, area/widget, area/swift]
parent: E10
milestone: "P3 · Widgets 首页"
blocked-by: [E10-S01]
---

## 背景

<现状是什么。为什么要改。>

## 目标

<改完之后是什么样。>

## 实施要点

1. <一步一件事。>
2. <写清文件和函数。>

## 验收标准

1. <逐条可判定。>
2. <需要测试时写明测试数量和覆盖范围。>

## 依赖

<前置 issue 的本地编号。没有就写「无」。>
```

### 2.5 Problem

```markdown
---
id: E10-S04
type: Problem
title: "<标题>"
labels: [bug, area/shell]
parent: null
milestone: "P3 · Widgets 首页"
blocked-by: []
---

## 复现步骤

1. <一步一个动作。>
2. <写明确切的操作和输入。>

## 预期

<应该发生什么。>

## 实际

<实际发生了什么。附错误信息和日志。>

## 环境

<系统版本、构建版本、硬件。>

## 影响范围

<影响哪些用户和功能。有没有数据丢失风险。>

## 回归测试

<要补哪个测试文件。防的是哪一类回归。>

## 依赖

无。
```

### 2.6 Optimization

```markdown
---
id: E10-S05
type: Optimization
title: "<标题>"
labels: [enhancement, area/perf]
parent: null
milestone: "P3 · Widgets 首页"
blocked-by: []
---

## 当前基线

<一个数。写清测量方法和环境。>

## 目标

<一个数。>

## 手段

1. <一步一件事。>

## 验证方法

<怎么测。测几次。在哪个环境测。>

## 证据放哪

<`evidence.md` 路径，或者 issue 评论。>

## 依赖

无。
```

## 3. 类型回填

`docs/roadmap/issues/` 下立项时的 58 个文件按下面的规则归类。

| 规则 | type | 数量 |
| --- | --- | --- |
| 有 `epic` label | `Goal` | 10 |
| 标题含 `ADR` | `Design` | 2 |
| 有 `area/contract` 和 `documentation` | `Design` | 4 |
| 有 `area/perf` | `Optimization` | 1 |
| 其余 | `Task` | 41 |

研究类和 Spike 类归入 `Task` 是过渡安排。
下次路线图评审时统一改为 `Design`。
