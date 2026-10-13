# issue-first 规范

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.1` |
| 状态 | 待评审 |
| 日期 | `2026-10-13` |
| 适用范围 | issue 的生命周期、分支命名、commit 格式、PR 规则和例外 |

本文定义 issue 从建立到关闭的完整规则。
本文不定义工作类型的划分。工作类型见 [work-types.md](work-types.md)。
本文不定义路线图的立项、排期和收口。这些流程见 [roadmap-first.md](roadmap-first.md)。

## 1. issue 生命周期

### 1.1 状态

| 状态 | GitHub 上的表现 | 谁触发进入 |
| --- | --- | --- |
| 想法 | 还不存在 | 人 |
| 已登记 | issue 是 open，type 和 label 已填 | 人 |
| 已排期 | milestone 已填，`blocked-by` 全部关闭 | 人 |
| 进行中 | 短分支已切，issue 有 assignee | agent |
| 待集成 | 存在指向集成分支的 PR | agent |
| 已集成 | PR 已合入集成分支 | 人 |
| 已关闭 | issue 是 closed | agent |
| 已放弃 | issue 是 closed，评论写明原因 | 人 |

### 1.2 状态的进出条件

| 状态 | 入口条件 | 出口条件 |
| --- | --- | --- |
| 已登记 | issue 表单提交成功，type 已设，必需 label 已打 | milestone 已填，且 `blocked-by` 里的 issue 全部 closed |
| 已排期 | 上一态的出口条件满足 | 短分支已从集成分支切出 |
| 进行中 | 分支名合规，issue 有 assignee | 分支上有合规 commit，PR 已开 |
| 待集成 | PR 指向集成分支，body 有 `Refs #N`，CI 三个 job 全绿 | PR 已合并 |
| 已集成 | PR 已合并，去掉 assignee | 关闭条件逐条满足，证据记入 issue 评论 |
| 已关闭 | 关闭条件逐条满足 | 终态 |

### 1.3 状态不使用标签

工作流不用 `status/*` 这类 label 表示中间状态。

理由是两套真相会互相矛盾。
分支、assignee、PR 和 issue 的开闭状态本来就在 GitHub 界面上可见。
再加一组标签，标签就会和真实状态不一致。
维护标签的人一旦漏打，读到的是错的。

因此：进行中看 assignee 和分支，待集成看 PR，已集成看 PR 的合并状态，已关闭看 issue 状态。

阻塞关系用 `blocked-by` 表达。见第 1.4 节。

### 1.4 与 GitHub 原生机制的配合

**sub-issue。** epic 用 `gh issue create --parent <N>` 建。
GitHub 不会在子 issue 全关时自动关父 issue。
Goal 的关闭条件里必须写明「全部 sub-issue 已关闭」。关闭动作由 agent 手工执行。

**blocked-by。** 用 `gh issue edit <N> --add-blocked-by <M>` 设置。
这是「已登记 → 已排期」的闸门。
`blocked-by` 里只要还有一个 open，就不切分支。

**milestone。** milestone 是路线图阶段在 GitHub 上的投影。
一个阶段对应且只对应一个 milestone。
milestone 的标题格式是 `P<n> · <阶段名称>`，例如 `P2 · 工作区模型`。
milestone 不设截止日期。
milestone 的关闭率是进度的读法。它只表示 issue 关闭率，不表示阶段完成。
阶段的完成判据是路线图第 6 节的退出条件。

一个 issue 只挂一个 milestone。epic 和它的 sub-issue 挂同一个 milestone。

格式见 [../roadmap/AUTHORING.md](../roadmap/AUTHORING.md) 第 2 节。
排期和进度汇总见 [roadmap-first.md](roadmap-first.md) 第 3 节和第 4 节。

## 2. 分支

### 2.1 集成分支

集成分支是 `feature/swiftui-macos`。
集成分支承接全部短分支。
集成分支在阶段收口时一次合入 `main`。
收口的入口条件和步骤见 [roadmap-first.md](roadmap-first.md) 第 5 节。

### 2.2 短分支

每个 issue 从集成分支切一条短分支。
分支名格式是 `<前缀>/<本地编号>-<描述>`。

| 前缀 | 用于 |
| --- | --- |
| `feature` | task、goal |
| `fix` | problem |
| `design` | design |
| `plan` | plan |
| `spike` | 一次性技术验证 |
| `docs` | 纯文档改动 |
| `chore` | 构建、CI、依赖 |

本地编号的格式是 `E[0-9]{2}` 或 `E[0-9]{2}-S[0-9]{2}`。
描述用小写字母、数字和短横线。

示例：

```sh
git switch -c feature/E03-S02-workbench-store feature/swiftui-macos
git switch -c fix/E04-S04-contract-test feature/swiftui-macos
git switch -c design/E00-S03-adr-config-storage feature/swiftui-macos
```

### 2.3 长命分支豁免

`main` 和 `feature/swiftui-macos` 豁免分支名规则。
在这两条分支上提交时，commit 尾行必须引用 issue。

集成分支改名时，同步修改 `scripts/hooks/guard.py` 的 `LONG_LIVED_DEFAULT`。
也可以用环境变量 `COVIO_LONG_LIVED_BRANCHES` 追加。

### 2.4 禁止事项

- 禁止从短分支直接向 `main` 开 PR。
- 禁止在集成分支上直接做 issue 范围内的实现工作。
- 禁止一条分支覆盖多个 issue。

## 3. commit

### 3.1 格式

```text
<祈使句标题，英文，首字母大写，不超过 72 字符，结尾不加句号>

<正文。为什么改、改了什么、边界在哪。一段一件事。可以留空。>

Refs: E03-S02
Co-Authored-By: Claude Code <noreply@anthropic.com>
```

### 3.2 标题行

标题行用英文祈使句。
标题行首字母大写。
标题行不超过 72 字符。
标题行结尾不加句号。
标题行不加 `feat:` 这类前缀。本仓库不用 Conventional Commits。

本仓库已有的 20 个提交都用这个风格。
示例：`Add the design contract, docs and CI`、`Keep deleted workspace entries from coming back`。

### 3.3 尾行

尾行是必须项。尾行格式如下：

```text
Refs: E03-S02
Refs: #27
Refs: E03-S02, E03-S03
Closes: #27
```

规则：

1. 本地编号和 GitHub 编号都可以用。
2. 多个编号用逗号加空格分隔。
3. 尾行的编号必须与分支名的编号一致。在 `E03-S02` 的分支上不能引用 `E05-S01`。
4. 豁免的改动写 `Refs: none`，并另起一行写 `Waiver:`。

### 3.4 署名

agent 创建的提交加尾行 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
人创建的提交不加。

### 3.5 提取规则

hook 从命令里提取 commit message，按下面的顺序判断。

| 命令形态 | 提取来源 | 检查方式 |
| --- | --- | --- |
| `git commit -m "..."` | `-m` 参数 | 正常检查 |
| `git commit -F <file>` | 文件内容 | 正常检查 |
| `git commit --amend --no-edit` | 现有 message | 只检查分支名 |
| `git commit` | 编辑器 | 拦下。要求改用 `-m` |
| `git commit -F -` | 标准输入 | 拦下。要求改用 `-m` 或 `-F <file>` |

message 由运行时计算时（含 `$(`、反引号或 heredoc），hook 在原始命令里搜尾行。
搜不到就拦下，并提示把尾行写成字面量。

## 4. PR

### 4.1 目标分支

| 场景 | 目标分支 | body 里写 |
| --- | --- | --- |
| 短分支 → 集成分支 | `feature/swiftui-macos` | `Refs #27` |
| 集成分支 → 主干 | `main` | `Closes #27`，汇总全部 |

### 4.2 关闭规则

**`Closes #N` 只在提交进入默认分支时自动关闭 issue。**
本仓库的默认分支是 `main`。集成分支是 `feature/swiftui-macos`。
短分支 → 集成分支的 PR 写 `Closes #N` 不会关闭 issue。
因此日常 PR 写 `Refs #N`。

关闭动作固定在「合入集成分支之后」。
agent 执行：

```sh
gh issue close 27 --comment "已合入 feature/swiftui-macos，commit <sha>。CI 全绿。"
```

集成分支 → `main` 的 PR body 里汇总写 `Closes #27`、`Closes #28`，作为兜底。

### 4.3 PR 必填项

PR 使用 `.github/PULL_REQUEST_TEMPLATE.md`。
必填项是关联 issue、本地编号、工作类型、改动摘要、验证记录、文档同步和回滚方案。
验证记录逐条写跑过的命令和结果。没跑的要写原因。

## 5. 例外

### 5.1 豁免清单

以下改动可以不建 issue。清单是穷举的。清单外的一律要建 issue。

1. 纯错别字、标点或空白修正。
2. 文档里的失效链接修正。
3. `.github/workflows/` 的缩进和拼写修正。
4. 无行为变化的依赖补丁版本调整。
5. 一次错误提交的 `git revert`。
6. `AGENTS.md`、`docs/workflow/` 和 `scripts/hooks/` 的紧急修复。
7. 集成分支 → `main` 的合并提交。

### 5.2 Waiver 尾行

豁免的是「建 issue」，不是「写尾行」。
豁免的改动照样要写尾行，格式如下：

```text
Fix a typo in the README build section

Refs: none
Waiver: 错别字修正，无行为变化
```

`Refs: none` 必须配一行非空的 `Waiver:`。缺了 hook 会拦下。

豁免记录可以审计：

```sh
git log --grep='^Waiver:' --format='%h %s%n  %b'
```

### 5.3 Break-glass

`COVIO_WORKFLOW_SKIP=1` 可以让 hook 直接放行。

**本开关只用于 hook 自身故障。**
不要用于赶时间。
`AGENTS.md` 的正文不写这个开关，只在本文记录。
这个不对称是刻意的：正文里出现逃生舱，agent 就会去用它。

hook 拦下时，stderr 的最后一句会明确要求不要用这个开关绕过。

### 5.4 审计

定期跑一次：

```sh
git log --grep='^Waiver:' --oneline
```

Waiver 密集出现说明规则设计有问题。
此时应该改规则，不要继续豁免。

## 6. 工具

| 工具 | 用途 |
| --- | --- |
| `scripts/hooks/guard.py` | commit 和 PR 的合规守卫。被 Claude Code hook 调用。 |
| `scripts/hooks/test-guard.sh` | 守卫的表驱动自测。 |
| `scripts/hooks/session-context.sh` | 会话开始时打印当前分支和对应 issue。 |
| `scripts/create-roadmap-issues.sh` | 按 `docs/roadmap/issues/*.md` 创建 GitHub issue。 |
| `scripts/sync-issue-types.sh` | 创建自定义 issue type。账号级操作。 |
| `docs/roadmap/issues/.created.json` | 本地编号到 GitHub 编号的映射。 |

路线图进度的查询命令见 [roadmap-first.md](roadmap-first.md) 第 4 节。

守卫的手工验证：

```sh
python3 -I scripts/hooks/guard.py --command 'git commit -m "Add x"' --cwd "$PWD"
```

守卫自测：

```sh
bash scripts/hooks/test-guard.sh
```

退出码 0 表示放行。
退出码 2 表示拦下，stderr 里是原因和修复指引。
