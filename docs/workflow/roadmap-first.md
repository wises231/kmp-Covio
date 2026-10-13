# roadmap-first 规范

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.1` |
| 状态 | 待评审 |
| 日期 | `2026-10-13` |
| 适用范围 | 路线图的立项、拆解、排期、进度汇总、阶段收口和变更 |

本文定义大工作的管理规则。
本文不定义单个 issue 的生命周期。生命周期见 [issue-first.md](issue-first.md)。
本文不定义路线图文档和 issue 定义文件的格式与模板。格式见 [../roadmap/AUTHORING.md](../roadmap/AUTHORING.md)。

## 1. 术语与层级

### 1.1 层级

```text
路线图 roadmap            docs/roadmap/<slug>.md
  └─ 阶段 phase           P0、P1 ……             概念
        ├─ 里程碑 milestone                     阶段在 GitHub 上的投影
        ├─ epic（Goal issue）  E00、E01 ……
        └─ sub-issue           E00-S01 ……
```

一个路线图分成有序的阶段。
一个阶段包含一个或多个 epic。
一个 epic 包含一个或多个 sub-issue。

### 1.2 术语表

| 术语 | 含义 |
| --- | --- |
| 路线图 | 覆盖一个可判定产品结果的文档。放在 `docs/roadmap/<slug>.md`。 |
| 阶段 | 路线图内的一段有序工作。用一个 `P<n>` 编号标识。 |
| 阶段编号 | 阶段的标识，形如 `P0`、`P1`。只在所属路线图内唯一。 |
| 阶段名称 | 阶段的中文名，形如「工作区模型」。 |
| 里程碑 | 阶段在 GitHub 上的投影。一个阶段对应一个 milestone。 |
| 阶段 label | 阶段在 issue 上的标记，形如 `phase-2-workspace-model`。 |
| epic | 带 sub-issue 的 Goal issue。本地编号形如 `E03`。 |
| sub-issue | epic 下的工作项。本地编号形如 `E03-S02`。 |
| 关键路径 | 依赖链上最长的一条。关键路径上的阶段不能并行。 |

### 1.3 阶段与里程碑的关系

**阶段是概念。里程碑是阶段在 GitHub 上的投影。两者不是两个概念。**

- 一个阶段对应且只对应一个 milestone。
- milestone 没有自己的名称、目标和退出条件。
- milestone 的标题就是阶段编号加阶段名称。
- 阶段的目标和退出条件写在路线图文档的第 6 节。
- 因此路线图文档的阶段表里没有「里程碑」这一列。

**警告：** 不要把阶段和里程碑写成两列。那会让同一个概念出现两个名字。

### 1.4 命名格式

| 对象 | 格式 | 正则 | 示例 |
| --- | --- | --- | --- |
| 路线图文件名 | `<slug>.md` | `^[a-z0-9-]+\.md$` | `curtain-workbench.md` |
| 阶段编号 | `P<n>` | `^P[0-9]{1,2}$` | `P2` |
| milestone 标题 | `P<n> · <阶段名称>` | `^P[0-9]{1,2} · .+$` | `P2 · 工作区模型` |
| 阶段 label | `phase-<n>-<slug>` | `^phase-[0-9]{1,2}-[a-z0-9-]+$` | `phase-2-workspace-model` |
| 计划的阶段编号 | `M<n>` | `^M[0-9]{1,2}$` | `M3` |

milestone 标题的分隔符是 U+00B7 中点，两侧各一个半角空格。
不要用 U+2022 圆点、U+30FB 片假名中点，或两侧没有空格的 U+00B7。
分隔符写错会让进度统计分成两组。

阶段 label 的颜色固定 `C5DEF5`。
阶段 label 的描述格式是 `阶段 <n> · <阶段名称>`。

完整的格式表见 [../roadmap/AUTHORING.md](../roadmap/AUTHORING.md) 第 2 节。

### 1.5 命名空间

**路线图的阶段用 `P<n>`。计划的阶段用 `M<n>`。两个命名空间不重叠。**

`P` 属于 `docs/roadmap/` 下的路线图。
`M` 属于 `docs/covio-macos-swiftui-migration-plan.md` 这类计划文档。

**警告：** 一个文档不要同时用两套编号。读者无法判断 `P1` 指哪一个。

## 2. 立项与拆解

### 2.1 入口：大功能 issue 触发立项

**立项的入口是一个 issue，不是一个空目录。**

用户为大功能提一个 issue。
工作流在提 issue 之后识别这项功能是否需要路线图。
判据用第 2.2 节的三条。三条全中时开新路线图，否则并入现有路线图。

识别后做五件事。

1. 把原 issue 提升为 epic。设置 Issue Type 为 `Goal`，加 `epic` 和 `phase-*` label，挂 milestone。
   不另建 epic。另建会让两个 issue 指向同一项功能。
2. 在原 issue 正文写路线图指针。至少写路线图文档路径、所属阶段和阶段退出条件。
3. 按第 2.3 节建路线图文档、milestone 和阶段 label。
4. 建 sub-issue，挂在提升后的 epic 下。
5. 在 `docs/roadmap/README.md` 的主题索引里加一行。

**一个 epic 对应一个原 issue。** 原 issue 就是 epic，不复制。

执行载体是 git 分支和 worktree。

1. 每个 sub-issue 从集成分支切一条短分支。分支名格式见 [issue-first.md](issue-first.md)。
2. 同一 epic 的 sub-issue 依次合入集成分支。一次一个，不合批。
3. 集成分支的全部 sub-issue 关闭后，开一条到 `main` 的 PR。
   在 PR body 里汇总写 `Closes #N`。这是 epic 的关闭点。
   `Closes` 只在目标分支是 `main` 时生效。短分支到集成分支的 PR 用 `Refs #N`。
4. 需要同时开两条分支时用 `git worktree`。一个 worktree 一条分支。
   worktree 让两条分支不争同一个工作目录，也不争同一份构建产物。

### 2.2 何时开新路线图

三条全中才开新路线图。否则并入现有路线图。

1. 覆盖一个可判定的产品结果。技术活动不算。
2. 需要 3 个或更多 epic。
3. 需要一段新的阶段编号序列。现有路线图的阶段装不下这项工作。

第 3 条是判定性的。
一个路线图一个 milestone 命名空间。
两个路线图共用 `P0` 会让 milestone 标题撞车。

**例外：工具与流程类工作不建路线图。**
构建工作流和文档规范的 Goal issue 直接建。
这类 issue 不挂 milestone，也不加 `phase-*` label。
原因是这类工作的结果不是产品行为，装不进任何产品阶段。

### 2.3 立项步骤

1. 写结果。用一句话说明完成后用户能做什么。
2. 写验收标准。每条必须可判定。
3. 拆需求。一条需求对应一个能力。
4. 切阶段。按依赖顺序切，不按时间切。
5. 建路线图文档。用 [../roadmap/AUTHORING.md](../roadmap/AUTHORING.md) 第 6 节的骨架。
6. 建 milestone。一个阶段一个。
7. 建阶段 label。一个阶段一个。
8. 建 epic issue。类型是 `Goal`。
9. 建 sub-issue。挂在对应 epic 下。
10. 填第 7 节索引、第 8 节依赖图和关键路径。
11. 在 `docs/roadmap/README.md` 的主题索引里加一行。

### 2.4 何时开新 epic

| 判断 | 结论 |
| --- | --- |
| 有独立退出条件，且需要 3 个或更多 sub-issue | 开新 epic |
| 一个会话能做完 | 加一个 sub-issue，挂到现有 epic |
| 一个会话以上，但不足 3 个 sub-issue | 拆成 2 到 3 个 sub-issue，挂到最接近的现有 epic。找不到就开新 epic |

### 2.5 sub-issue 粒度

**一个 sub-issue 必须能在一个会话内完成。**

一个 sub-issue 对应一条分支和一个 PR。
需要两个或更多 PR 的是 epic，不是 sub-issue。
小于一个会话的并入相邻 sub-issue。

### 2.6 拆解顺序

1. 写第 2 节需求拆解。
2. 一个能力一个 epic。
3. 一个 epic 拆成 sub-issue。
4. 每个 epic 归属且仅归属一个阶段。
5. 写第 7 节索引。
6. 写第 8 节依赖图。
7. 标关键路径。

### 2.7 编号规则

编号只追加，不回收。
退役的编号留空。
插队见第 6 节。

### 2.8 立项产物清单

一次立项产出以下内容。

- 路线图文档 `docs/roadmap/<slug>.md`。
- issue 定义文件 `docs/roadmap/issues/<本地编号>-*.md`。
- GitHub 上的 milestone，一个阶段一个。
- GitHub 上的阶段 label，一个阶段一个。
- GitHub 上的 epic issue，一个 epic 一个。
- GitHub 上的 sub-issue，一个 sub-issue 一个。
- `docs/roadmap/README.md` 主题索引里的一行。

## 3. 排期与里程碑

### 3.1 排期的单位是阶段

**排期的单位是阶段，不是日期。**
milestone 不设截止日期。
排期就是阶段顺序加依赖拓扑。

### 3.2 阶段排序

按依赖拓扑排序。
关键路径上的阶段不得并行。
默认同一时刻只有一个「进行中」阶段。
无依赖的阶段要并行，必须在路线图的第 8 节显式标注。

### 3.3 编号只追加不插队

milestone 标题和阶段 label 已经发布。
插队会让历史引用失效。
必须插队时走第 6 节的变更流程。
插队的代价是旧引用失效。接受这个代价才插。

### 3.4 创建 milestone

```sh
gh api repos/<owner>/<repo>/milestones -f title="P6 · 新阶段名称"
```

### 3.5 创建阶段 label

```sh
gh label create phase-6-new-slug --color C5DEF5 --description "阶段 6 · 新阶段名称"
```

### 3.6 把 issue 挂到 milestone

```sh
gh issue edit <N> --milestone "P6 · 新阶段名称"
```

### 3.7 排期步骤

1. 检查前置阶段的退出条件是否满足。
2. 检查 `blocked-by` 是否全部关闭。
3. 确认阶段顺序没有违反依赖拓扑。
4. 给 epic 挂 milestone。
5. 给 sub-issue 挂同一个 milestone。
6. 检查一个 issue 只挂一个 milestone。

**一个 issue 只挂一个 milestone。**
**一个 epic 只属于一个阶段。**
sub-issue 跟随它的 epic。

## 4. 进度汇总与阻塞

### 4.1 真相来源

**真相来源是 GitHub 上 sub-issue 的实际状态。**

路线图文档里的表是索引，不是进度。
禁止在路线图文档里手写进度数字。
禁止维护第二份进度表。

### 4.2 进度怎么读

milestone 的关闭率等于已关闭 issue 数除以该 milestone 下 issue 总数。

**关闭率只表示 issue 关闭率，不表示阶段完成。**
阶段完成的判据是路线图第 6 节的退出条件。
关闭率到 100% 但退出条件未满足时，阶段没有完成。

### 4.3 汇总命令

每个阶段的关闭数比总数：

```sh
gh issue list --state all --limit 200 --json milestone,state \
  --jq '[.[] | {m:(.milestone.title//"无"), c:(.state=="CLOSED")}]
        | group_by(.m) | .[] | "\(.[0].m)\t\([.[]|select(.c)]|length)/\(length)"'
```

某个阶段内的 issue：

```sh
gh issue list --milestone "P0 · 调研与决策" --state all --limit 100
```

阻塞关系：

```sh
gh issue list --state open --limit 200 --json number,title,blockedBy \
  --jq '.[] | select(.blockedBy.totalCount > 0) | "#\(.number) ← \([.blockedBy.nodes[].number]|join(", "))"'
```

可以开工的 issue：

```sh
gh issue list --state open --limit 200 --json number,title,blockedBy \
  --jq '[.[] | select([.blockedBy.nodes[] | select(.state=="OPEN")] | length == 0) | "#\(.number)"] | length'
```

**注意：** `blockedBy` 是连接对象，形如 `{nodes:[…], totalCount:n}`。
它不是扁平数组。取编号要用 `.blockedBy.nodes[].number`。

### 4.4 阻塞

**阻塞只用 `blocked-by` 一个机制。**

设置阻塞：

```sh
gh issue edit <N> --add-blocked-by <M>
```

解除等于前置 issue 关闭。
`blocked-by` 里只要还有一个 open，就不切分支。
不使用 `status/blocked` 这类标签。两套真相会互相矛盾。

### 4.5 回填节奏

每次合并一个 sub-issue 之后做四件事。

1. 关闭对应的 GitHub issue。
2. 在 issue 评论里写结论和证据。
3. 勾选 issue 正文里的验收子项。
4. 检查路线图文档的对应节是否要改。

不要攒到最后一起回填。
不要写「大部分完成」这类无法判定的结论。

### 4.6 WIP 规则

同一时刻只做一个 sub-issue。
一个 sub-issue 一条分支。
需要并行时，先确认两个 sub-issue 之间没有 `blocked-by` 关系。

## 5. 阶段收口

### 5.1 入口条件

全部满足才收口。

1. 该阶段 milestone 下全部 issue 已关闭。
2. 每个 issue 的验收标准逐条勾选，证据写在 issue 评论里。
3. 该阶段新增或修改的文档已合入集成分支。
4. 集成分支上 `bash scripts/test-all.sh` 全绿。
5. 路线图第 6 节的阶段退出条件逐条满足。
6. 没有 open 的 `blocked-by` 指向下一阶段。

**第 5 条与第 1 条不同。** milestone 到 100% 不等于阶段完成。

### 5.2 步骤

1. 跑第 4.3 节的汇总命令，确认关闭率是 100%。
2. 逐条核对阶段退出条件。
3. 把每条退出条件的证据写进 milestone 描述或对应 issue 评论。
4. 关闭 milestone。
5. 判断本阶段是不是发布边界。
6. 是发布边界时，开集成分支到 `main` 的 PR。
7. 在 PR body 里汇总写 `Closes #N`。
8. 更新 `README.md`、`RELEASE_NOTES.md` 和真机验收清单。
9. 记录本阶段的交付偏差。

关闭 milestone：

```sh
gh api -X PATCH repos/<owner>/<repo>/milestones/<number> -f state=closed
```

**警告：** 第 6 步把集成分支合入 `main`。这是不可逆的对外动作。执行前确认第 1 步到第 5 步全部通过。

### 5.3 出口条件

- milestone 是 closed。
- 集成分支已合入 `main`，或者明确记录了「本阶段不发布」。
- 下一阶段的第一个 issue 满足「已排期」。

### 5.4 不达标的处理

未达标就收口是违规。
未达标项转成新的 problem 或 task issue。
新 issue 挂在**当前**阶段，不带进下一阶段。
当前阶段的 milestone 保持 open，直到新 issue 关闭。

## 6. 变更与退役

### 6.1 加 issue

挂到现有 epic 和阶段。
新工作不属于任何现有阶段时，追加 `P<n+1>`。
不要插队。见第 3.3 节。

### 6.2 改 issue

同时改 issue 正文和路线图的对应节。
改阶段归属时，同时改 milestone 和阶段 label。
只改一处会让两份文档矛盾。

### 6.3 退 issue

```sh
gh issue close <N> --reason "not planned"
```

在路线图第 7 节标注退役。
退役的编号留空，不回收。

### 6.4 路线图自身的变更

第 2、6、7、8 节必须一起改。
不允许只改其中一个。
文档版本号加一。

### 6.5 禁止事项

- 禁止在路线图文档里手写进度数字。
- 禁止一个 issue 挂多个 milestone。
- 禁止两个路线图共用阶段编号。
- 禁止在阶段未达标时收口。
- 禁止回收已退役的编号。

## 7. 检查清单

### 7.1 立项

- [ ] 三条立项判定全中。
- [ ] 入口是一个已存在的 issue，且该 issue 已提升为 epic，未另建。
- [ ] 原 issue 正文已写路线图指针。
- [ ] 结果可判定。
- [ ] 每个阶段有编号、名称、目标、退出条件。
- [ ] 每个 epic 归属且仅归属一个阶段。
- [ ] 每个 sub-issue 一个会话能做完。
- [ ] milestone 和阶段 label 已建，格式合规。
- [ ] 第 7 节索引、第 8 节依赖图和关键路径已写。

### 7.2 排期

- [ ] 阶段顺序符合依赖拓扑。
- [ ] 关键路径上没有并行阶段。
- [ ] 每个 issue 只挂一个 milestone。
- [ ] `blocked-by` 已回填。
- [ ] milestone 没有截止日期。

### 7.3 收口

- [ ] milestone 关闭率 100%。
- [ ] 退出条件逐条满足，证据已记录。
- [ ] `bash scripts/test-all.sh` 全绿。
- [ ] 发布边界已判定。
- [ ] 集成分支已合入 `main`，或者记录了不发布。
- [ ] `README.md`、`RELEASE_NOTES.md` 和验收清单已更新。
