# 推荐架构、接口与实施计划

> 本文件承载共享工作区的推荐架构、接口契约、流程、安全、可靠性、失败模式、验收和实施计划。
> 传输契约沿用 [上一主题的方案](../cross-device-content-access/solution.md) 第 2 节。

## 1. 推荐架构

### 1.1 路径选择

采用本地优先副本。
每台已配对设备保存工作区索引与内容副本。
放入方主动推送，接收方保存副本。
选择原因与备选路径见 [conclusion.md](conclusion.md) 第 3 节。

### 1.2 组件

| 组件 | 职责 | 位置 |
| --- | --- | --- |
| 放入入口 | 把外部内容交给 Covio | 每台设备本机 |
| 条目索引 | 记录条目元数据与状态 | 每台设备本机 |
| 内容仓库 | 保存内容字节并执行淘汰 | 每台设备本机 |
| 复制引擎 | 同步索引与内容 | 局域网 |
| 配额管理器 | 统计占用并选择淘汰对象 | 每台设备本机 |
| 清理器 | 删除过期条目与残留 | 每台设备本机 |
| 按需取回器 | 取回只保留索引的条目 | 接收方本机 |

### 1.3 存储布局

工作区使用 Covio 自己管理的目录。
工作区不引用用户的原文件路径。
原因见 [investigation.md](investigation.md) 第 7 节。

```text
<应用数据根>/Covio/Workspace/
  index.json             条目索引，原子写入
  objects/<sha256>       内容字节，按摘要命名
  incoming/<随机名>.part 放入时的半成品，摘要算完就改名
  incoming/<sha256>      摘要算完，等待移入 objects
  incoming/<sha256>.part 传输中的暂存，收到多少就有多大
  tombstones.json        删除标记，保留 30 天
```

`incoming` 有三种形态，实现见 `WorkspaceStore` 的暂存区原语。
`tombstones.json` 属于复制阶段，当前只写本机的删除标记，广播还没接上（第 10.3 节）。

macOS 上 `<应用数据根>` 是 `~/Library/Application Support`。
路径与现有晾衣线的 `Covio/Screenshots/shelf.json` 同级。
Windows 上 `<应用数据根>` 是 `%LOCALAPPDATA%`。
Android 上 `<应用数据根>` 是应用私有的 `files` 目录。
iOS 上 `<应用数据根>` 是应用容器的 `Library/Application Support`。
iOS 的目录选择依据见 [evidence.md](evidence.md) 的 `E-19`。
工作区不放在缓存目录或临时目录（`E-09`、`E-15`、`E-19`）。
`AppDirectories` 的 actual 已实现 macOS、Windows 与 Linux 三个根目录。
iOS 与 Android 的目标还没进构建，补齐要等目标加入（第 10.1 节）。
iOS 的 `Workspace` 目录设置备份排除标记，不进 iCloud 备份。
备份排除标记只是提示，过期仍由 Covio 自己执行（`E-19`）。

`objects` 使用内容寻址。
相同内容只存一份。
同名不同内容自动区分。

### 1.4 与现有实现的关系

现有 `ShelfItem` 记录的是用户文件的原始路径。
现有 `ShelfStore` 只保存引用，不复制内容，上限 12 条。
工作区需要独立存储与独立索引。
两者共用文件命名规则与界面组件。

| 现有部件 | 复用方式 |
| --- | --- |
| `ShelfFileNaming` | 直接复用重名规则 |
| `ShelfStore` | 保留，作为 `Files` 页签的本地视图 |
| `ShelfLayout` | 保留，作为卡片布局 |
| `ClipPolicy` 与 `ClipboardStore.prune` | 作为配额、去重与过期的规则蓝本 |
| 新增 `WorkspaceStore` | 索引与内容的持久化 |
| 新增 `WorkspacePolicy` | 配额、淘汰与过期的纯逻辑 |

剪切板的保留策略已经实现同类规则。
规则包括同一标识只留最新、置顶不过期、条数上限与总字节上限。
工作区策略沿用同一形状，扩展到摘要标识与设备来源。

## 2. 接口契约

### 2.1 传输

复用上一主题的会话通道与传输层。
工作区操作使用同一条控制通道。
内容字节使用数据通道。
iOS 的后台续传另外使用一个 HTTP 端点（`E-18`）。

### 2.2 条目模型

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `entry_id` | string | 内容摘要，`sha256` 十六进制 |
| `kind` | string | `file`、`image`、`audio`、`pdf`、`text` |
| `display_name` | string | 展示名，不含路径 |
| `byte_size` | integer | 字节数 |
| `content_type` | string | MIME 类型 |
| `created_at` | integer | 放入时间，UTC 毫秒 |
| `origin_device_id` | string | 放入方设备标识 |
| `expires_at` | integer | 过期时间，UTC 毫秒 |
| `availability` | string | `local`、`remote`、`fetching`、`evicted` |

`pinned` 是本机属性，不参与复制。
`expires_at` 由放入方确定，接收方照抄。

### 2.3 请求

```json
{"request_id":"req-0001","op":"workspace.put","args":{"entry_id":"<hex>","kind":"pdf","display_name":"<名称>","byte_size":2048,"content_type":"application/pdf","created_at":1760000000000,"expires_at":1762592000000}}
```

### 2.4 响应

```json
{"ok":true,"data":{"accepted":true,"task_id":"task-0001"},"error_code":null,"error_message":null}
```

### 2.5 操作

| 操作 | 参数 | 返回 | 说明 |
| --- | --- | --- | --- |
| `workspace.list` | `since`、`limit` | 条目列表 | 拉取索引增量 |
| `workspace.put` | 条目模型字段 | `accepted`、`task_id` | 声明新条目 |
| `workspace.fetch` | `entry_id` | 内容流 | 取回只保留索引的条目 |
| `workspace.delete` | `entry_id` | `ok` | 广播删除 |
| `workspace.stat` | 无 | 占用、上限、条目数 | 查询对端工作区状态 |
| `transfer.chunk` | `task_id`、`offset`、`length` | `received` | 传输分块 |
| `transfer.commit` | `task_id`、`sha256` | `ok` | 提交并校验 |
| `transfer.cancel` | `task_id` | `ok` | 取消任务 |

### 2.6 错误码

| 错误码 | 触发条件 | 可重试 | 人工处理 |
| --- | --- | --- | --- |
| `quota_exceeded` | 超出空间上限 | 是 | 提示清理或置顶 |
| `entry_expired` | 条目已过期 | 否 | 提示重新放入 |
| `entry_not_found` | 对端没有该条目 | 否 | 刷新索引 |
| `content_unavailable` | 对端只有索引且内容已淘汰 | 是 | 提示从其他设备取回 |
| `unsupported_kind` | 类型不在支持列表 | 否 | 提示转换格式 |
| `share_denied` | 分享入口未授权 | 否 | 引导到系统设置 |
| `storage_full` | 接收方空间不足 | 是 | 提示清理空间 |
| `checksum_mismatch` | 校验失败 | 是 | 删除不完整内容后重传 |
| `peer_offline` | 对端不可达 | 是 | 排队等待 |
| `local_network_denied` | 本地网络权限被拒 | 否 | 引导到系统设置 |

## 3. 关键流程

### 3.1 放入

1. 用户在任意入口把内容交给 Covio。
2. Covio 计算内容摘要。
3. 摘要已存在时合并到已有条目，不新建。
4. 摘要不存在时写入 `incoming`。
5. 校验通过后改名移入 `objects`。
6. 索引新增条目并落盘。
7. 向所有已配对设备发送 `workspace.put`。

内容先落盘再声明。
声明失败时条目只在本机可见。

iOS 上分享扩展只执行第 1 步与第 4 步的前半段。
扩展把内容写入 App Group 共享容器（`E-17`）。
扩展随后结束，不执行摘要计算之外的额外动作。
主应用在下次启动时读取共享容器，继续第 2 步之后的流程。
扩展不做传输，也不声明后台模式（`E-17`）。

### 3.2 复制

1. 接收方收到 `workspace.put`。
2. 接收方检查配额与类型。
3. 低于阈值的内容立即请求传输。
4. 高于阈值的内容只记录索引，状态为 `remote`。
5. 传输完成后校验并落盘。
6. 接收方状态改为 `local`。
7. 接收方回执。

阈值默认 50 MB。
阈值可在设置中修改。

### 3.3 取出

1. 用户在接收方打开 `remote` 条目。
2. 接收方发送 `workspace.fetch`。
3. 放入方从 `objects` 读取内容流。
4. 接收方校验后落盘并改为 `local`。
5. 放入方离线时提示可从其他设备取回。

### 3.4 删除

1. 用户在任意设备删除条目。
2. 本机删除索引与内容。
3. 本机写入删除标记。
4. 本机向所有已配对设备发送 `workspace.delete`。
5. 接收方删除副本并写入删除标记。
6. 删除标记保留 30 天。

删除是全局操作。
置顶不阻止他人删除。
需要长期保留的内容由用户另存到工作区之外。

### 3.5 过期与淘汰

1. 清理器按固定间隔检查 `expires_at`。
2. 过期条目先删除内容，再删除索引。
3. 占用超过上限时，配额管理器按顺序淘汰。
4. 淘汰顺序是过期的、未置顶的、最旧的、只被本次取回的。
5. 置顶条目只在用户手动删除时移除。
6. 淘汰后向对端发送 `workspace.delete`。

### 3.6 冲突

1. 同摘要内容重复放入时合并为一条。
2. 条目记录首次放入方。
3. 同名不同内容生成两条独立条目。
4. 同一条目在两台设备同时删除时不产生错误。
5. 索引以摘要在先、时间在后的顺序合并。

### 3.7 iOS 的传输分层

1. 分享扩展把内容写入共享容器后结束。
2. 主应用读取共享容器并生成条目。
3. 主应用在前台时优先执行传输。
4. 需要后台续传时改用 HTTP 端点。
5. 后台会话只支持 HTTP 与 HTTPS，因此新增该端点（`E-18`）。
6. 用户手动结束应用时传输取消。
7. 下次启动时把取消的任务重新入队。
8. 回到前台后校验摘要并收敛状态。

扩展不进后台，传输不进扩展（`E-17`）。

## 4. 资源策略

1. 单条目上限默认 2 GB。
2. 工作区总上限默认 5 GB。
3. 默认保留期 30 天。
4. 并发传输默认 3 个。
5. 默认按需阈值 50 MB。
6. 移动端只在有电且非低电量模式下传输。
7. iOS 的后台传输时机由系统决定（`E-18`）。
8. 索引变更才发送 `workspace.list`。

参数可在设置中修改。
策略函数是纯函数：输入条目列表、策略与当前时间，输出保留列表。
纯函数形式与 `ClipboardStore.prune` 相同，便于单元测试。

第 4 项还没有对应的策略字段，等传输层落地时再定（第 10.3 节）。

## 5. 安全设计

1. 内容只在已配对设备之间传输。
2. 传输使用 TLS 1.3 与双向认证。
3. 静态内容依赖系统提供的存储保护。
4. 工作区目录权限设为 `0700`。
5. iOS 上为工作区文件显式设置文件保护等级。
6. 工作区只保存展示名，不保存原始路径。
7. 日志不记录内容、文件名和路径。
8. 过期是隐私控制，不只是清理。
9. 撤销设备后不再复制新条目。
10. 撤销设备不删除对端已有副本。
11. 撤销时提示用户在旧设备上清除工作区。
12. 删除标记保留 30 天，防止内容复活。
13. 条目摘要在传输前校验。
14. iOS 分享扩展只写共享容器，不读主应用容器（`E-17`）。

## 6. 合规设计

1. 分享入口由用户动作触发。
2. 不在后台自动收集用户内容。
3. 每个授权在需要时申请并说明用途。
4. 匿名事件只记录类型与大小，不记录内容。
5. 不建立账号体系。
6. 不建立云端内容存储。
7. 工作区数据不写入系统相册或公共目录。
8. 相册导出只覆盖图片与视频（`E-20`）。
9. 移动端不申请与放入功能无关的后台权限。

## 7. 可靠性设计

1. 索引原子写入，避免半份文件。
2. 索引损坏时重建：扫描 `objects` 目录。
3. 内容先写 `incoming`，校验后改名。
4. 未完成传输在重启后重新入队。
5. 落盘失败只在内存更新，不中断应用。
6. 空间不足时先拒绝新条目，不删除已有条目。
7. 删除标记防止已删除条目被重新复制。
8. 索引版本号支持后续迁移。

## 8. 失败模式

| 失败 | 表现 | 处理 |
| --- | --- | --- |
| 分享入口不可用 | 系统分享面板没有 Covio | 说明需要开启扩展，或改用应用内选择 |
| 移动端在后台放入 | 放入动作失败 | 提示回到前台完成 |
| 对端离线 | 条目只在本机可见 | 排队，对端上线后补发 |
| 对端空间不足 | 复制失败 | 保留索引，提示对端清理 |
| 内容已淘汰 | 打开时取不到内容 | 提示从其他设备取回 |
| 索引损坏 | 条目丢失 | 扫描内容目录重建 |
| 两端同时删除 | 出现重复删除请求 | 视为成功，不报错 |
| 时钟不一致 | 过期时间偏差 | 以放入方时间为准 |
| 摘要冲突 | 极低概率的哈希碰撞 | 长度不同时按字节比较，仍冲突则提示 |
| iOS 扩展被系统终止 | 放入动作中断 | 扩展只做落盘，动作短；失败时重新放入 |
| 用户手动结束 iOS 应用 | 后台传输被取消 | 下次启动时任务重新入队（`E-18`） |
| 应用组共享容器缺失 | 扩展无法写文件 | 提示重新启用扩展与共享容器 |
| iOS 后台会话协议不支持 | 后台续传失败 | 改用 HTTP 端点（`E-18`） |

## 9. 验收标准

1. 四个平台各有至少一个可用的放入入口。
2. 放入一个 PDF 后，另一台设备在 10 秒内看到条目。
3. 两台设备的条目列表一致。
4. 手机在后台时条目排队，回到前台后可取出。
5. 放入 2 GB 文件并在中途断网，恢复后从断点继续。
6. 校验失败时删除不完整内容并重传。
7. 相同内容重复放入只生成一条。
8. 同名不同内容生成两条。
9. 删除在一台设备发起后，另一台设备的副本消失。
10. 过期条目在两个平台都按时间删除。
11. 达到空间上限时淘汰最旧的未置顶条目。
12. 置顶条目不被淘汰。
13. 撤销设备后不再收到新条目。
14. 权限被拒时给出原因与下一步。
15. iOS 分享扩展放入后，主应用生成条目（`E-16`、`E-17`）。
16. 用户手动结束 iOS 应用后，重新启动能恢复排队任务（`E-18`）。

## 10. 实施计划

### 10.1 阶段 1：本地工作区

状态：已在 `feature/swiftui-macos` 分支落地。落地位置与偏差见本节。

1. 新增 `WorkspaceStore`，实现索引与内容的持久化。
2. 新增 `WorkspacePolicy`，实现配额、淘汰与过期的纯逻辑。
3. 补齐 `AppDirectories` 在 Windows、iOS 与 Android 上的 actual。
4. 新增单元测试，覆盖淘汰顺序与过期边界。
5. 把 `Files` 页签接到工作区索引。

落地位置：

| 第几项 | 文件 | 说明 |
| --- | --- | --- |
| 1 | `kmpDomain/src/com/wyz/covio/core/WorkspaceStore.kt` | 索引落盘用「写 `.tmp` 再 `atomicMove`」。内容按摘要存放在 `objects/`。放入时流式读，不进整份内存。 |
| 2 | 同上，`WorkspaceLogic` 与 `WorkspacePolicy` | 过期、淘汰、去重、排序都是纯函数。`Models.kt` 放数据结构。 |
| 3 | `kmpDomain/src@jvm/com/wyz/covio/core/AppDirectories.jvm.kt` | 见下面的偏差。 |
| 4 | `kmpDomain/test/com/wyz/covio/core/WorkspaceStoreTest.kt`、`WorkspaceLogicTest.kt`、`test@jvm/.../PlatformDataRootTest.kt` | 覆盖摘要校验、去重、淘汰顺序、过期边界、路径穿越、写失败。 |
| 5 | `macosApp/src/Hub/FilesTabView.swift`、`macosApp/src/Workspace/*.swift` | 列表、放入、置顶、删除、清理过期。 |

偏差：第 3 项只完成了 macOS、Windows 与 Linux。

- `kmpDomain/module.yaml` 只声明 `platforms: [jvm, macosArm64]`。
- iOS 与 Android 目标当前不存在，写 actual 会编译失败。
- 补齐 iOS 与 Android 的 actual 要等这两个目标加入构建。

未做：设备间复制（`workspace.put`、分块传输、断点续传）属于阶段 3。

### 10.2 阶段 2：放入入口

状态：第 1 项与第 5 项已在 `feature/swiftui-macos` 分支落地。其余三项未开始。

1. 实现 macOS 拖放与应用内选择。
2. 实现 Windows 拖放与应用内选择。
3. 实现 iOS 分享扩展与 App Group 共享容器（`E-17`）。
4. 实现 Android 分享意图接收。
5. 实现剪切板条目与截图条目保存到工作区。

落地位置：

| 第几项 | 文件 | 说明 |
| --- | --- | --- |
| 1 | `macosApp/src/Hub/FilesTabView.swift` | 页内容接收文件拖放。胶囊里的「放入文件」开系统选择面板。 |
| 5 | `kmpDomain/src/com/wyz/covio/core/WorkspaceStore.kt` | `putText` 直接写正文。它与 `putFile` 共用 `settle`。 |
| 5 | 同上，`WorkspaceLogic.suggestedTextName` | 按正文第一行取文件名。四个平台共用一条规则。 |
| 5 | `kmpDomain/src/com/wyz/covio/core/ClipboardStore.kt` | `ClipboardLogic.importPaths` 给出条目背后的落盘文件。 |
| 5 | `macosApp/src/Workspace/WorkspaceRuntime.swift` | `save(text:)`、`save(filesAt:)`、`save(clipItem:)`。 |
| 5 | `macosApp/src/Hub/ClipboardTabView.swift` | 每条记录加「存入工作区」。图片与文件存文件，其余存正文。 |
| 5 | `macosApp/src/Shelf/ScreenshotCardView.swift` | 右键菜单与溢出菜单加「存入工作区」。没有工作区时这一项不出现。 |

偏差：来源页没有就地提示。

- 剪切板页高固定 344 点，放不下第二条提示。
- `ClipboardRuntime` 只有失败通道，没有成功通道。
- 因此存入结果只在文件页显示。

未做：这两项的界面动作只有单元测试与编译覆盖，尚未手工验证。

### 10.3 阶段 3：复制

状态：第 1 至 3 项与第 5 项的本机部分已在 `feature/swiftui-macos` 分支落地。第 4 项与第 6 项未开始。

1. 实现 `workspace.put` 与 `workspace.list`。
2. 实现分块传输与校验。
3. 实现断点续传。
4. 实现按需取回。
5. 实现删除广播与删除标记。
6. 实现 HTTP 后台传输端点，供 iOS 的后台会话使用。

落地位置：

| 第几项 | 文件 | 说明 |
| --- | --- | --- |
| 1 | `kmpDomain/src/com/wyz/covio/core/WorkspaceWire.kt` | 第 2 节的线格式：操作名、请求与响应信封、错误码。 |
| 1 | `kmpDomain/src/com/wyz/covio/core/WorkspaceTransfer.kt` | `begin`、`chunk`、`commit`、`cancel`、`list`、`stat`。 |
| 1 | `kmpDomain/src/com/wyz/covio/core/WorkspaceStore.kt` | 暂存区原语。路径是 `incoming/<摘要>.part`。 |
| 2 | 同上 | 每块核对偏移。提交时核对摘要与字节数。 |
| 3 | 同上 | `begin` 返回已经收到的字节数。偏移不符时 `chunk` 回已收长度。 |
| 5 | `kmpDomain/src/com/wyz/covio/core/WorkspaceTransfer.kt` | `delete` 处理收到的 `workspace.delete`：删索引与内容，留标记。 |
| 5 | `kmpDomain/src/com/wyz/covio/core/WorkspaceStore.kt` | `markDeleted`、`loadTombstones`、`sweep` 清过期标记。存放位置是 `tombstones.json`。 |
| 5 | `macosApp/src/Workspace/WorkspaceRuntime.swift` | 界面上的删除走同一条路径，本机删除也留标记。 |

偏差：

- 任务标识就是条目摘要，不是独立的 `task-NNNN`。内容寻址让一次传输只对应一份内容。
- 时间在线格式上是毫秒，在索引里是秒。换算只在 `WorkspaceWire` 的两处。
- 摘要不合法回 `checksum_mismatch`，因为摘要本身就是校验和。
- 类别不在支持列表里回 `unsupported_kind`。
- 超过工作区上限回 `quota_exceeded`。`storage_full` 留给写盘失败。
- 收到的字节超过条目声明的字节数时立刻回 `checksum_mismatch`，不等到提交。
- 零字节条目在 `begin` 时先建空暂存文件，提交时才有东西可校验、可改名。
- 索引写盘失败时 `WorkspacePutResult.persisted` 为假，界面报错而不报成功。
- 删除标记写在索引与内容之前。标记写不进去时这次删除算失败，条目留着等重试（方案第 3.4 节要求先删本机再广播，但标记是拦住对端复活的那一道，顺序反了会丢内容）。
- 本机删过的摘要回 `entry_not_found`，不再接收对端晚一步的 `workspace.put`。
- 摘要不合法的删除请求回 `entry_not_found`，不写标记：拼不出路径的标识不能进标记文件。
- 标记单独存一个文件，不并进 `index.json`。索引每次放入都要写，标记很少变。
- 本机重新放入一份删过的内容时，标记不清。第 3.4 节写「删除是全局操作」，所以删过的那一端在保留期内仍然不收这一条。用户要让它回到那一端，只能等保留期过去。

未做：

- 传输层。第 2.1 节要求复用跨设备主题的会话通道。那个通道还没实现。
- 进程中途退出时，`fetching` 状态的条目要等下一次 `begin` 或 `cancel` 才收敛。
- 删除广播本身。`delete` 已经能处理收到的请求，还没有代码把本机的删除发出去。
- `sweep` 淘汰与过期的条目不写标记（第 3.5 节第 6 项要求广播）。淘汰是本机的空间策略，标记要等广播接上再写。
- 按需取回、HTTP 后台端点。
- 界面。macOS 上还没有对端，所以没有可接的入口。

### 10.4 阶段 4：加固

1. 实现配额设置界面。
2. 实现空间不足与权限不足的提示。
3. 实现索引重建。
4. 完成无障碍与双语验收。

### 10.5 发布级审计（2026-10-13）

审计范围是阶段 1 至 3 的已落地部分。
三条视角：安全与隐私、发布就绪、文档一致性。
下面的结论都在本机复现过。修复已在 `feature/swiftui-macos` 分支落地，提交是 `97cefd5`。

已修的缺陷：

1. **暂存字节可以越过总上限。** 修复前的复现：单条目上限 100 字节，总上限 100 字节，40 条各声明 1 字节的条目，各收到 100 字节。磁盘上留下 4000 字节。原因：`chunk` 只按单条目上限比对，不比条目声明的字节数。声明因此形同虚设。修法：`chunk` 按声明的字节数拒收。
2. **零字节条目永远提交不了。** 原因：`begin` 不建暂存文件，`commit` 找不到文件就回 `checksum_mismatch`。修法：`begin` 先建空暂存文件；建不出来就回 `storage_full`，连索引都不写。
3. **索引写盘失败时报成功。** 原因：`save` 把写盘结果吞掉，界面只看条目有没有进内存。修法：新增 `saveReporting`；`WorkspacePutResult.persisted` 把结果交给界面。没落盘时报错，条目不进列表。

新增的测试：

| 测试 | 覆盖 |
| --- | --- |
| `chunk refuses to grow past the declared size` | 超过声明立刻回 `checksum_mismatch` |
| `chunk refuses to grow past the entry limit` | 声明大于上限时回 `quota_exceeded` |
| `chunk refuses bytes for an empty entry` | 零字节条目收不下字节 |
| `an empty entry round trips through begin and commit` | 零字节条目能提交 |
| `begin refuses an empty entry when the staging cannot be created` | 建不出暂存文件时不写索引 |
| `chunk reports a full disk` | `storage_full`，条目留在 `fetching` |
| `commit reports a full disk` | `storage_full`，条目退回 `remote` |
| `commit refuses a task that is not in the index` | `entry_not_found`，半份内容删掉 |
| `begin counts the transfers in flight against the quota` | 在传的条目占配额 |
| `stat counts the transfers in flight` | 在传的条目按声明计入占用 |
| `save reporting tells whether the index reached the disk` | 写盘结果的两种取值 |
| `put file reports a failed index write` | `persisted` 为假，条目不进内存 |
| `put file reports a persisted entry` | `persisted` 为真 |
| `testIntakeReportsAFailedIndexWrite` | 放入时索引写不进去，报错不报成功 |
| `testSaveTextReportsAFailedIndexWrite` | 存文字时索引写不进去，返回假 |
| `testSaveTextReportsASuccessfulWrite` | 存文字成功时的说明 |

未修：

- 工作区目录没有设 `0700`（第 5 节第 4 项）。权限现在由 umask 决定，阶段 4 加固时补。
- 目前没有任何日志。第 5 节第 7 项因此成立，但没有可核对的内容。
- 并发传输数没有策略字段（第 4 节第 4 项），等传输层落地时再定。
- 阶段 3 的传输引擎没有生产调用方，只被测试覆盖。上面三条缺陷因此都还没在真机上出现过。

发布阻塞项都不在本次改动范围内。真机验收项见 `docs/adr/adr-0001-macos-ui-swiftui.md` 的未决事项。

## 11. 回滚条件

1. 复制造成明显卡顿时，改为只复制索引，内容一律按需取回。
2. 移动端存储压力过大时，把移动端改为只保存索引。
3. 删除传播造成数据丢失投诉时，改为本机删除并保留对端副本。
4. 过期清理不稳定时，改为只提示不自动删除。
5. 任何阶段出现内容泄露风险时，立即关闭自动复制。

## 12. 产品化条件

1. 四个平台的放入入口与授权说明完整。
2. 两台桌面设备的端到端验证通过。
3. 至少一个移动端组合的验证通过。
4. 配额、过期与删除规则写入用户文档。
5. 隐私说明与实际行为一致。
6. iOS 副本的备份策略已确定。
