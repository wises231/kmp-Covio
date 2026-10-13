---
id: E09-S05
title: "文档、发布说明与验收清单"
labels: [documentation, phase-5-quality, area/docs]
type: Task
parent: E09
milestone: "P5 · 质量与交付"
blocked-by: [E08-S04]
---

## 背景

`README.md` 描述 0.5.0 的功能与验收清单。
`RELEASE_NOTES.md` 目前仍描述 0.4.2，文件开头已写明待重写。
`docs/covio-macos-swiftui-migration-plan.md` 的 13.2 节记录了发布说明的待办。

工作台是一个大版本。三份文档都要更新。

## 目标

让文档描述工作台的实际行为。

## 实施要点

1. `README.md` 增加工作台一节：触发方式、工作区、组件、配置路径。
2. `README.md` 的路径一节增加 `workbench.json`。
3. `README.md` 的真机验收清单增加工作台条目。
4. 重写 `RELEASE_NOTES.md` 为工作台版本。
5. 更新 `docs/covio-macos-swiftui-migration-plan.md` 的交付偏差一节。
6. 更新 `docs/covio-product-master.md` 的 4.2、4.3、4.4 与 6.3 节。
7. 说明升级与降级行为，尤其是 `workbench.json` 在降级后的处理。

## 验收标准

1. `README.md` 描述工作台的触发方式与配置路径。
2. 真机验收清单包含工作台条目，可逐条执行。
3. `RELEASE_NOTES.md` 描述当前版本，不再描述 0.4.2。
4. 产品总稿的四节与实现一致。
5. 文档写明升级与降级行为。
6. 文档不写设备序列号、令牌或隐私日志。

## 依赖

`E08-S04`。
