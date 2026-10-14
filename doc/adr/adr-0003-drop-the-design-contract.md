# ADR-0003：删掉设计合同，界面取值以 Swift 为准

- Status：accepted
- Kind：architecture
- Date：2026-10-14
- Supersedes：ADR-0001 的设计合同部分，见实测 23，以及实测 31 与 37 里的合同校验作业
- Implements：none

字段取值见[流程文件](../process/workflow.md)的 S4。

## 背景

ADR-0001 把 macOS 宿主换成 SwiftUI。设计合同是这一层之上的一层账本。

合同层有五件东西：

| 件 | 位置 |
| --- | --- |
| 取值账本 | `docs/covio-design-contract.json`，238 KB |
| Schema | `docs/covio-design-contract.schema.json` |
| 生成脚本 | `scripts/generate-contract-constants.py`，产出 `Copy.swift` 与 `Tokens.swift` |
| 校验脚本 | `scripts/validate-contract.py` |
| 读取与测试 | `kmpDomain` 的 `DesignContract.kt`、4 份测试、2 个 CI 作业 |

账本存三组数据：颜色与尺寸、动效时长、界面文案。

合同只有一个消费者。macOS 宿主读生成的 Swift 常量。Compose 宿主在 0.5.0 停用。
没有第二个平台读合同。

生成物与账本是同一份数据的两个副本。改一处就要同步另一处。

引用分布如下：

| 组 | 条目 | 引用处 | 文件数 |
| --- | --- | --- | --- |
| 颜色与尺寸 | 69 | 39 | 2 |
| 动效 | 10 | 23 | 1 |
| 文案 | 280 | 281 | 26 |

## 决策

1. 删掉合同层。删 JSON、Schema、生成脚本、校验脚本、`DesignContract.kt`、4 份测试和 2 个 CI 作业。
2. 界面取值的权威是 `macosApp/src/Design/` 下的 Swift 代码。
3. `Copy.swift` 存全部界面文案，中英各一份。别处不得构造 `LocalizedCopy`。
4. `Tokens.swift` 存颜色、圆角、间距与动效时长。
5. `MacTheme.swift` 把取值转成 SwiftUI 的颜色与尺寸。
6. 类型名去掉 `Contract` 前缀：`Copy`、`TokenColors`、`TokenColor`、`TokenDimensions`、`Motion`、`MotionToken`。
7. Compose 打样画的是目标画面。打样与 macOS 实现不一致时，改 macOS 实现。
8. Figma 侧的页面、画板与组件清单留在 `docs/covio-product-design.md`，作为视觉基准的表格。

## 后果

### 正面

- 界面取值只有一个来源。改一处就生效。
- 没有生成步骤。改完不用重跑脚本。
- 删掉 238 KB 的 JSON、一份 Schema、两个脚本、4 份测试与 2 个 CI 作业。
- 文案不再需要 `key` 字段。`key` 只被测试用过。

### 负面

- 失去「改了合同忘了重跑脚本」这道检查。这道检查只为两个副本而存在。
- 失去机器可读的 Figma 节点映射。映射改由 `docs/covio-product-design.md` 的表格承担。
- `kmpDomain` 不再认识界面取值。跨平台宿主将来要另立一份取值。

### 风险

- Figma 侧与 Swift 侧的偏差不再自动拦。缓解办法是打样的截图与设计闸门的 R8。
- 将来加 Windows 或 Android 宿主时，取值要重新分家。届时另写一条 ADR。

## 备选方案

### 备选 1：保留合同，继续生成 Swift 常量

维持现状。合同是账本，Swift 是生成物。

未采纳的原因：账本只有一个消费者。第二个副本没有收益，只有同步成本。

### 备选 2：保留 JSON，只当只读账本，不再生成

去掉生成脚本，Swift 手写。JSON 留作查阅。

未采纳的原因：两个副本还在，检查却没了。比现状更差。

### 备选 3：取值搬进 Swift，保留校验脚本

让校验脚本解析 Swift 源码，继续核对取值。

未采纳的原因：为 Swift 源码写解析器，比它守的东西更复杂。

## 未决事项

| 项目 | 状态 | 确认方法 |
| --- | --- | --- |
| Figma 侧的表格会不会与 Swift 漂移 | 待观察 | 改完 Figma 后核对 `docs/covio-product-design.md` 的验收清单 |
| 将来加第二个平台宿主时取值怎么分 | 未定 | 届时另写一条 ADR |

## 参考

- [ADR-0001](adr-0001-macos-ui-swiftui.md)
- `macosApp/src/Design/`：`Copy.swift`、`Tokens.swift`、`MacTheme.swift`、`LocalizedCopy.swift`
- [产品设计](../covio-product-design.md)
- [打样模块](../design/design-preview.md)
- [研发工作流](../process/workflow.md)的设计闸门
