# 路线图归档

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 待评审 |
| 日期 | `2026-10-13` |
| 适用范围 | `docs/roadmap/` 下的路线图与 issue 定义 |

本目录保存产品路线图和对应的 issue 定义。
本目录不保存研究资料。研究资料放在 `docs/research/`。
本目录不保存架构决策。架构决策放在 `docs/adr/`。

## 主题索引

| 主题 | 状态 | 平台范围 | 说明 |
| --- | --- | --- | --- |
| [挂帘式工作台](curtain-workbench.md) | 待评审 | macOS | 把 Hub 改造成可编辑的挂帘工作台。10 个 epic，48 个 sub-issue。 |

## 目录结构

```text
docs/roadmap/
  README.md                 本索引
  curtain-workbench.md      挂帘式工作台总路线图
  issues/                   issue 定义，一个文件一个 issue
    E00-research-and-decisions.md
    E00-S01-trackpad-gesture-research.md
    ...
    .created.json           脚本写入的编号映射，由脚本生成
```

## issue 文件格式

每个文件用 YAML front-matter 描述元数据，正文就是 issue 正文。

```yaml
---
id: E01-S02
title: "触控板四指下滑触发"
labels: [enhancement, phase-1-curtain-core, area/trigger]
parent: E01
milestone: "P1 · 挂帘内核"
blocked-by: [E00-S01, E01-S01]
---
```

字段说明：

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `id` | 是 | issue 的本地编号。`E00` 是 epic，`E00-S01` 是 sub-issue。 |
| `title` | 是 | issue 标题。 |
| `labels` | 是 | 标签列表。脚本会自动创建缺失的标签。 |
| `parent` | 是 | 父 issue 的本地编号。epic 写 `null`。 |
| `milestone` | 否 | 里程碑名。脚本会自动创建缺失的里程碑。 |
| `blocked-by` | 否 | 阻塞本 issue 的本地编号列表。 |

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

## 更新规则

执行阶段后更新总路线图的阶段表。
关闭或新增 issue 后更新本索引。
issue 内容变化后同步对应的 `.md` 文件。
