# Project 字段

[Project 8「Covio」](https://github.com/users/wyz541/projects/8)是字段的唯一来源。本文件记录实测结果。

```text
gh project field-list 8 --owner wyz541
```

读取需要 `read:project` 权限。设置字段值或加条目需要 `project` 权限。

新 issue 不会自动进 Project。要让它们进来，在 Project 的 `⋯` 菜单里打开 `Workflows`，再开 `Auto-add to project`，筛选条件填 `repo:wyz541/kmp-Covio is:issue`。

## 字段

| 名称 | 类型 | 取值 | 用途 |
| --- | --- | --- | --- |
| `Status` | 单选 | `Todo`、`In progress`、`Done` | 全部 issue |
| `Priority` | 单选 | `P0`、`P1`、`P2` | Feature issue |
| `Size` | 单选 | `XS`、`S`、`M`、`L`、`XL` | 全部 issue，由负责人打分 |
| `Start date` | 日期 | 日期 | Feature issue |
| `Target date` | 日期 | 日期 | Feature issue，roadmap 视图读它 |
| `Iteration` | 迭代 | 未启用 | 需要按周期排期时再配 |

GitHub 自带的字段还有 `Title`、`Assignees`、`Labels`、`Linked pull requests`、`Milestone`、`Repository`、`Reviewers`、`Parent issue`、`Sub-issues progress`、`Created`、`Updated`、`Closed`。

## 注意

- 字段名是 `Sub-issues progress`，复数。
- `Priority` 目前只有三档。要加 `P3` 就在 Project 的字段设置里加。
- 表单里的 Priority 与 Size 由 `feature.yml` 收集，写在 issue 正文。日期只在 Project 里维护。
- 改字段名时同步改本文件与 `.github/ISSUE_TEMPLATE/feature.yml`。名字对不上，每周检查的命令就失效。

## 相关

- [研发工作流](workflow.md)的 S8
- [Agent 契约](../../AGENTS.md)
