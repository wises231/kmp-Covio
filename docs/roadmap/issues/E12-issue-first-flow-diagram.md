---
id: E12
type: Task
title: "issue-first 工作流流程图"
labels: [documentation]
parent: null
blocked-by: []
---

## 背景

`docs/workflow/` 的四份文档用文字定义规则。
规则分散在三处：判据在 `roadmap-first.md`，分支和 commit 格式在 `issue-first.md`，产物落在 `work-types.md`。
读者要读完三份文档，才能拼出「一个大功能从 issue 到 main」的完整路径。

## 目标

一张图说清这条路径。
图的每个节点标出载体和产物。

## 实施要点

1. 新建 `docs/workflow/issue-first-flow.html`。内容是两幅 SVG 图和说明文字。
2. 第一幅图画主流程的七个节点：提 issue、判据、提升为 epic、立项产物、sub-issue 循环、阶段收口、合入 main。
3. 第二幅图画分支拓扑：短分支从集成分支切出、逐个合回、worktree 并行、收口合并进 main。
4. 在 `docs/workflow/README.md` 的文件索引里加一行。

## 验收标准

1. `docs/workflow/issue-first-flow.html` 存在。用浏览器打开能看到两幅图。
2. 图里的规则与 `docs/workflow/` 下的正文一致。图不新增规则。
3. `docs/workflow/README.md` 的文件索引含这一行。

## 依赖

无。
