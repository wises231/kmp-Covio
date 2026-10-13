---
id: E08-S04
title: "重跑校验与生成脚本"
labels: [documentation, phase-5-quality, area/contract]
parent: E08
milestone: "P5 · 质量与交付"
blocked-by: [E08-S01, E08-S02, E08-S03]
---

## 背景

改动合同后必须运行两个脚本：

```sh
python3 scripts/validate-contract.py
python3 scripts/generate-contract-constants.py
```

第一个检查跨节规则。第二个重写 `ContractCopy.swift` 与 `ContractTokens.swift`。
这两个文件是生成的，手改会被下次生成覆盖。

## 目标

让生成文件与合同一致，并让全部合同测试通过。

## 实施要点

1. 运行校验脚本，修掉全部报错。
2. 运行生成脚本，提交生成结果。
3. 运行 `bash scripts/test-all.sh`。
4. 核对 `metadata.counts` 与实际数量。
5. 核对产品总稿里的静态设计状态描述是否需要更新。
   `README.md` 记录了 8 页、8 节、35 板等计数。

## 验收标准

1. `python3 scripts/validate-contract.py` 退出码为 0。
2. 生成脚本运行后工作区无差异，说明已提交。
3. `bash scripts/test-all.sh` 通过。
4. `DesignContractTests`、`ContractConstantsTests`、`CopySingleSourceTests` 全部通过。
5. `README.md` 的计数与合同一致。

## 依赖

`E08-S01`、`E08-S02`、`E08-S03`。
