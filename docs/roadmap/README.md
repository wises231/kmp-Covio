# 路线图归档

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `2.0` |
| 状态 | 待评审 |
| 日期 | `2026-10-13` |
| 适用范围 | `docs/roadmap/` 下的路线图与 issue 定义 |

本目录保存产品路线图和对应的 issue 定义。
本目录不保存研究资料。研究资料放在 `docs/research/`。
本目录不保存架构决策。架构决策放在 `docs/adr/`。

路线图的立项、拆解、排期、进度汇总、阶段收口和变更流程见
[../workflow/roadmap-first.md](../workflow/roadmap-first.md)。
路线图文档、阶段表和 issue 定义文件的格式与模板见 [AUTHORING.md](AUTHORING.md)。

## 主题索引

| 主题 | 状态 | 平台范围 | 阶段 | 说明 |
| --- | --- | --- | --- | --- |
| [挂帘式工作台](curtain-workbench.md) | 待评审 | macOS | P0–P6 | 把 Hub 改造成可编辑的挂帘工作台。11 个 epic。 |

## 目录结构

```text
docs/roadmap/
  README.md                 本索引
  AUTHORING.md              格式与模板
  curtain-workbench.md      挂帘式工作台总路线图
  issues/                   issue 定义，一个文件一个 issue
    E00-research-and-decisions.md
    E00-S01-trackpad-gesture-research.md
    ...
    .created.json           脚本写入的编号映射，由脚本生成
```

## 分支与提交

每个 issue 从集成分支切一条短分支。
集成分支是 `feature/swiftui-macos`。

```sh
git switch -c feature/E03-S02-workbench-store feature/swiftui-macos
```

每次提交在正文最后引用 issue：

```text
Add the workbench store

Refs: E03-S02
```

完整规则见 [issue-first.md](../workflow/issue-first.md)。

## 创建 issue

预览将执行的操作，不写入 GitHub：

```sh
bash scripts/create-roadmap-issues.sh --dry-run
```

创建全部 issue：

```sh
bash scripts/create-roadmap-issues.sh
```

**警告：** 仓库 `wyz541/kmp-Covio` 是公开仓库。
执行脚本会把全部 issue 发布到 GitHub。
执行前先运行 `--dry-run` 并确认输出。

脚本按以下顺序执行：

1. 创建缺失的标签。
2. 创建缺失的里程碑。
3. 创建全部 epic。
4. 创建全部 sub-issue，并设置父 issue。
5. 回填 `blocked-by` 关系。
6. 把本地编号到 GitHub 编号的映射写入 `issues/.created.json`。

脚本可以重复运行。`issues/.created.json` 里已有的编号会跳过。

## 进度

本索引不记录进度。
进度从 GitHub 上 sub-issue 的实际状态推导。
查询命令见 [../workflow/roadmap-first.md](../workflow/roadmap-first.md) 第 4 节。
