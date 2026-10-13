---
id: E00-S06
type: Design
title: "工作台架构骨架文档"
labels: [documentation, phase-0-research, area/pane, area/swift]
parent: E00
milestone: "P0 · 调研与决策"
blocked-by: []
---

## 背景

路线图 `docs/roadmap/curtain-workbench.md` 第 5 节给出了四层目标架构，但只有类型名和一句话职责。
它没有把需求映射到组件，没有说明每层的边界和依赖方向，也没有说明现有代码怎么迁移。
结果是 `E01` 到 `E07` 共 34 个实现类 issue 缺少共同参照。读者要拼七份 issue 才能看出整体形状。

## 待决策

1. 这份骨架放在哪个目录。
2. 写到多细：只写结构，还是写到函数签名与字段。
3. 它与路线图第 5 节、产品设计总稿、ADR 的职责边界怎么划。

## 候选方案

### 方案 A：新增 `docs/design/` 目录

新建 `docs/design/workbench-architecture.md`。
`docs/` 下目前没有架构骨架类目录，架构内容散在 `docs/adr/`（决策）、路线图第 5 节（要点）、迁移计划第 5 节（迁移视角）。

代价：新增一个文档类别，要在 `AGENTS.md` 第 8 节和 `docs/workflow/work-types.md` 登记。
适用条件：骨架是长期参照物，会被多个 issue 反复引用。

### 方案 B：写进 `docs/covio-product-master.md`

产品总稿是产品行为权威，已有 1369 行、十个编号章。
把架构骨架追加成新章。

代价：产品总稿同时承载产品行为与工程结构。两份内容互相牵制，评审时无法分开。
适用条件：骨架很短，或者骨架本身就是产品行为的一部分。

### 方案 C：扩写路线图第 5 节

不新增文件，把路线图第 5 节从要点扩写成完整骨架。

代价：`docs/roadmap/README.md` 明文规定「本目录不保存架构决策」。骨架放进路线图会让该目录职责失真。
适用条件：骨架只服务于本路线图，不被其他文档引用。

## 判定依据

1. 评审可分离。产品行为的评审人和工程结构的评审人可以分开看。
2. 职责边界清楚。一份文档只回答一类问题。
3. 引用稳定。多个 issue 引用时，路径不随路线图改版而变。

## 决策

选方案 A。

理由：方案 B 让产品总稿承担两类职责，违反判定依据 2。方案 C 违反 `docs/roadmap/README.md` 已写明的目录职责。方案 A 唯一同时满足三条判定依据。

详细程度定为**结构级**：写职责、边界、依赖方向和关键类型名，不写函数签名、字段清单和状态迁移表。签名与字段在 ADR 和实现类 issue 里定，定完回填骨架。

## 证据

1. `docs/roadmap/curtain-workbench.md` 第 5 节现状：四层、类型名齐全，接口签名与数据字段均无。
2. `docs/covio-product-master.md` 第 7.1 节「平台架构」是产品视角的层表，不是代码骨架。
3. `docs/roadmap/README.md` 第 13-14 行规定本目录不保存研究资料与架构决策。
4. `docs/` 下无 `design/`、`architecture/`、`specs/` 目录。

以上四条均为事实，来自文件内容核对。

## 影响

1. 新增目录 `docs/design/`，需在 `AGENTS.md` 第 8 节和 `docs/workflow/work-types.md` 的 design 产物路径登记。
2. 路线图计数变化：sub-issue 从 48 增至 49，`E00` 子项从 5 增至 6。
3. `E00-research-and-decisions.md` 的子项表与范围段需同步。
4. 不约束其他 issue。骨架是参照物，不产生依赖边。

## 依赖

无。骨架不依赖 `E00-S03` 和 `E00-S04` 的结论。
`E00-S03` 定第 8 节的存储细节，`E00-S04` 定第 4 节的协议边界，两份 ADR 完成后回填骨架对应小节。
