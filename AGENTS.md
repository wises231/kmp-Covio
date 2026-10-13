# Covio 工作约定

本文件是 agent 的强制契约。Codex 直接读本文件。Claude Code 通过 `CLAUDE.md` 导入。
本文件不超过 120 行。细节放在 `docs/workflow/`。

## 1. 项目基线

Covio 是 macOS 菜单栏应用。界面是 SwiftUI 宿主，放在 `macosApp/`。
共享领域逻辑是 KMP 模块，放在 `kmpDomain/`。
构建系统是 Amper 0.12.1，不是 Gradle。跑全部测试用 `bash scripts/test-all.sh`。
集成分支是 `feature/swiftui-macos`。主干是 `main`。

## 2. 会话开始

先做三件事，再动代码。

1. 看当前分支。`git branch --show-current`。
2. 找当前 issue。分支名里的编号就是 issue 本地编号。
3. 读 issue 定义。`docs/roadmap/issues/<本地编号>-*.md`。

本地编号到 GitHub 编号的映射在 `docs/roadmap/issues/.created.json`。
没有对应 issue 时，先建 issue。

## 3. issue 先行

没有 issue 就不改代码。先建 issue，再建分支。一个 issue 一条分支。
改动超出 issue 范围时，新建一个 issue，不要顺手做。
建 issue 用 `.github/ISSUE_TEMPLATE/` 下的表单。表单会自动设置 Issue Type 和 label。
在本仓库建 issue 定义文件时，用 `docs/workflow/work-types.md` 第 2 节的模板。

## 4. 路线图与里程碑

大的产品目标先立路线图。路线图放在 `docs/roadmap/<slug>.md`。
一个路线图分成有序的阶段。阶段编号 `P0`、`P1`……只在路线图内唯一。
一个阶段对应一个 GitHub milestone，标题格式是 `P<n> · <阶段名称>`。
一个阶段配一个 `phase-<n>-<slug>` label，颜色 `C5DEF5`。
计划（plan）的阶段用 `M0`、`M1`……与路线图的 `P` 分开。
epic 是带 sub-issue 的 Goal issue，挂到所属阶段的 milestone。sub-issue 跟随它的 epic。
工具与流程类 Goal issue 例外，不建路线图，不挂 milestone。
一个 issue 只挂一个 milestone。一个 epic 只属于一个阶段。
sub-issue 的粒度是一个会话能做完，一条分支一个 PR。
阶段收口前，milestone 必须 100% 关闭，且阶段退出条件逐条满足。
阶段收口时集成分支一次合入 `main`。
流程见 `docs/workflow/roadmap-first.md`。格式见 `docs/roadmap/AUTHORING.md`。

## 5. 工作类型与产物

八种工作类型是 goal、aim、design、plan、task、problem、optimization、commit。
每种类型到产物和 Issue Type 的映射见 `docs/workflow/work-types.md` 第 1 节。`aim` 和 `commit` 不建 issue。

## 6. 分支

从集成分支切短分支，例如
`git switch -c feature/E03-S02-workbench-store feature/swiftui-macos`。
分支名格式是 `<前缀>/<本地编号>-<小写描述>`。
前缀取 `feature`、`fix`、`design`、`plan`、`spike`、`docs`、`chore`。
本地编号形如 `E03` 或 `E03-S02`。
`main` 和 `feature/swiftui-macos` 豁免分支名规则，但提交仍要写 issue 尾行。
禁止从短分支直接向 `main` 开 PR。

## 7. commit

```text
Add the workbench store

Refs: E03-S02
Co-Authored-By: Claude Code <noreply@anthropic.com>
```

1. 标题行用英文祈使句，首字母大写，不超过 72 字符，不加句号，不加 `feat:` 这类前缀。
2. 尾行必须有 `Refs:` 或 `Closes:`。本地编号和 GitHub 编号都可以。
3. 尾行的编号必须与分支名的编号一致。
4. agent 创建的提交加 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

不要用 `git commit` 不带 `-m`。守卫会拦下。
不要用 `COVIO_WORKFLOW_SKIP` 绕过守卫。

## 8. PR

短分支的 PR 目标是 `feature/swiftui-macos`，body 用 `.github/PULL_REQUEST_TEMPLATE.md`，写 `Refs #27`。
`Closes #N` 只在提交进入默认分支 `main` 时自动关闭 issue。
合入集成分支之后手工关闭：`gh issue close 27 --comment "已合入 feature/swiftui-macos。"`
集成分支合入 `main` 时，PR body 里汇总写 `Closes #27`，作为兜底。

## 9. 文档

改动涉及行为时，同步改文档。

| 知识 | 位置 |
| --- | --- |
| 产品行为 | `docs/covio-product-master.md` |
| 设计合同 | `docs/covio-design-contract.json` |
| 架构决策 | `docs/adr/` |
| 目标架构 | `docs/design/` |
| 研究结论 | `docs/research/` |
| 路线图和 issue | `docs/roadmap/` |
| 工作流规则 | `docs/workflow/` |

文档用中文。命令、路径、API 名称和版本号保留原文。不写本机绝对路径。

## 10. 例外

七类改动可以不建 issue：错别字修正、失效链接修正、CI 配置的缩进修正、依赖补丁版本调整、
错误提交的 `git revert`、`AGENTS.md` 与 `docs/workflow/` 与 `scripts/hooks/` 的紧急修复、
集成分支合入 `main` 的合并提交。清单是穷举的。完整定义见 `docs/workflow/issue-first.md` 第 5.1 节。

豁免的是「建 issue」，不是「写尾行」。豁免改动写 `Refs: none` 加一行 `Waiver: <理由>`。

## 11. 验证与禁止

提交前跑 `bash scripts/test-all.sh`。改了 UI 的还要在真机验收。

禁止事项：

1. 跳过守卫，或直接向 `main` 推送。
2. 在一条分支上做多个 issue。
3. 改设计合同后不重跑 `scripts/generate-contract-constants.py`。
4. 把本机绝对路径写进仓库文件。

规则全文见 `docs/workflow/README.md`。
