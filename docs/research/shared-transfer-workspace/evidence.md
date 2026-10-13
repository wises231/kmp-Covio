# 证据附录

## 文档状态

| 项目 | 内容 |
| --- | --- |
| 文档版本 | `1.0` |
| 状态 | 初稿，可评审 |
| 日期 | `2026-10-12` |
| 主题 | 跨设备共享暂存工作区 |
| 证据总数 | 22 |
| 案例映射 | `Case 1` 至 `Case 3` |

本文件记录来源、观察、推论、反证和缺口。
每条证据有唯一编号。
编号格式为 `E-01`。

## 1. 问题类别和案例映射

| 问题类别 | 案例 | 主要证据 |
| --- | --- | --- |
| 放入入口 | `Case 1`、`Case 2` | `E-06`、`E-12`、`E-13`、`E-16` |
| 本地存储与配额 | `Case 3` | `E-02`、`E-03`、`E-04`、`E-09`、`E-19` |
| 后台传输 | `Case 2` | `E-10`、`E-11`、`E-17`、`E-18` |
| 安全与隐私 | `Case 3` | `E-01`、`E-07`、`E-20`、`E-21` |
| 与系统投送的差异 | 不在验证范围 | `E-22` |

## 2. 来源等级

| 等级 | 来源 | 用途 |
| --- | --- | --- |
| A | Android developer 官方文档、AOSP、Microsoft Learn、Apple 接口文档 | 权威行为与硬约束 |
| B | 目标仓库源码、本机 SDK 头文件、归档文档 | 实现边界 |
| C | 商店政策页、支持文章 | 产品能力 |
| D | 本机实验 | 当前环境事实 |
| E | 第三方文章与社区讨论 | 背景线索 |

高影响结论只使用 A 与 B。
只有 E 支持的判断标记为推测。
`A-` 表示 Apple 的归档文档，仍属 Apple 官方来源。

## 3. 环境事实

| 项目 | 值 |
| --- | --- |
| 主机 | Apple Silicon Mac |
| 系统 | macOS 27.0.1 |
| 仓库分支 | `feature/swiftui-macos` |
| 仓库版本基线 | `0.5.0`，未发布 |
| 磁盘加密 | FileVault 已开启 |
| 应用数据根 | `~/Library/Application Support` |

### 3.1 复现命令

```bash
# 确认磁盘加密状态
fdesetup status
```

```bash
# 确认应用数据目录与权限
ls -ld "$HOME/Library/Application Support/Covio"
ls -ld "$HOME/Library/Application Support/com.wyz.covio"
```

```bash
# 确认现有晾衣线模型
grep -rn -A8 'class ShelfItem' --include="*.kt" kmpDomain/src
```

```bash
# 确认现有保留策略
grep -rn -A40 'fun prune' --include="*.kt" kmpDomain/src/com/wyz/covio/core/ClipboardStore.kt
```

```bash
# 确认平台目录实现
ls "kmpDomain/src@jvm/com/wyz/covio/core/" \
   "kmpDomain/src@macosArm64/com/wyz/covio/core/"
```

### 3.2 环境结论

本机实验只覆盖 macOS。
Android 与 Windows 的结论来自官方文档。
iOS 的结论来自官方文档。
没有真机交叉验证。

## 4. 证据索引

| 编号 | 主题 | 来源 | 结论 | 置信度 |
| --- | --- | --- | --- | --- |
| E-01 | 本机存储保护 | D | FileVault 开启，数据目录权限 `0755` | 高 |
| E-02 | 现有晾衣线模型 | B | 只存路径，不复制内容，上限 12 条 | 高 |
| E-03 | 现有剪切板保留策略 | B | 已有去重、过期、置顶与双上限 | 高 |
| E-04 | 平台目录实现缺口 | B | 只实现 macOS 路径 | 高 |
| E-05 | 既有设计约定 | B | 临时文件 30 天或 5 GB | 高 |
| E-06 | Android 分享入口 | A | 意图过滤器接收，不需存储权限 | 高 |
| E-07 | Android 公共目录写入 | A | 自有文件免权限，用相对路径 | 高 |
| E-08 | Android 全盘权限政策 | C | 门槛高，需申报 | 高 |
| E-09 | Android 缓存目录清理 | A | 系统可能删除缓存目录 | 高 |
| E-10 | Android 后台传输 | A | 需前台服务类型，有 6 小时配额 | 高 |
| E-11 | Android 冻结与授权有效期 | A | 生命周期事件立即解冻 | 高 |
| E-12 | Windows 分享目标 | A | 需要包身份 | 高 |
| E-13 | Windows 拖放 | A | 未打包应用可用 | 高 |
| E-14 | Windows 完整性级别 | B | 高完整性可向低完整性发消息 | 中高 |
| E-15 | Windows 临时目录 | A | 存储感知会清理临时文件 | 高 |
| E-16 | iOS 接收入口 | A | 分享面板只列扩展，文档类型只处理单 URL | 高 |
| E-17 | 分享扩展的容器与限制 | A | 扩展与主应用靠共享容器交换文件 | 高 |
| E-18 | iOS 后台传输 | A | 系统后台会话，用户强杀即取消 | 高 |
| E-19 | iOS 容器清理与备份 | A | 缓存与临时目录被清理并排除备份 | 高 |
| E-20 | iOS 相册与文件 App 写入 | A | 相册需要用途说明键，音频无独立资产 | 高 |
| E-21 | macOS 拖放与沙盒扩展 | A | 拖入应用自动扩展沙盒授权 | 高 |
| E-22 | 隔空投送对照 | A | 需要接收方同意，没有第三方接口 | 高 |

## 5. 证据详情

### E-01：本机存储保护

来源等级：D
环境：macOS 27.0.1，Apple Silicon
命令或来源：`fdesetup status`、`ls -ld`
关键输出：

```text
FileVault is On.
drwxr-xr-x@ 4 wyz staff 128 Oct 11 20:53 Application Support/Covio
drwxr-xr-x@ 6 wyz staff 192 Oct 12 21:03 Application Support/com.wyz.covio
```

观察：磁盘加密已开启。
观察：数据目录权限为 `0755`。
观察：挂载点是只读的系统宗卷，数据在数据宗卷上。
推论：静态内容依赖磁盘加密。
推论：目录权限允许同机其他账户读取目录内容。
推论：工作区目录应显式设为 `0700`。
限制：只在本机观察，样本为一台设备。
置信度：高
关联：`solution.md` 第 5 节

### E-02：现有晾衣线模型

来源等级：B
环境：分支 `feature/swiftui-macos`，commit 见仓库
命令或来源：`kmpDomain/src/com/wyz/covio/core/Models.kt:123`、`ShelfStore.kt`
关键输出：

```kotlin
data class ShelfItem(
    @SerialName("path") val path: String,
    @SerialName("addedAtEpochSeconds") val addedAtEpochSeconds: Long = 0L,
)
// ShelfStore.MAX_ITEMS = 12
// normalizeItems 用 exists(it.path) 过滤
```

观察：条目只有路径与加入时间。
观察：没有大小、摘要、类型和来源设备字段。
观察：路径不存在时条目被过滤掉。
观察：条数上限为 12。
推论：现有晾衣线是用户文件的展示视图，不是内容仓库。
推论：原文件移动或删除后条目消失。
推论：跨设备副本不能建在 `ShelfItem` 上，需要新的存储模型。
推论：12 是界面轮播上限，不是存储上限。
限制：只读源码，未运行。
置信度：高
关联：`E-03`、`E-04`、`solution.md` 第 1.4 节

### E-03：现有剪切板保留策略

来源等级：B
环境：分支 `feature/swiftui-macos`
命令或来源：`kmpDomain/src/com/wyz/covio/core/ClipboardStore.kt:115`
关键输出：

```kotlin
fun prune(items: List<ClipItem>, policy: ClipPolicy, nowEpochSeconds: Long, exists: (String) -> Boolean = { true }): List<ClipItem>
// 1. 丢掉正文与路径都为空的坏数据
// 2. 同一个标识只留最新的一条
// 3. 丢掉过期的条目。置顶的不过期
// 4. 先保住置顶的，再按新旧留到条数上限与总字节上限
```

观察：已有完整的保留策略实现。
观察：策略是纯函数，输入列表、策略与时间，返回保留列表。
观察：策略处理去重、过期、置顶与双上限。
推论：工作区策略沿用同一形状，只把标识换成内容摘要。
推论：纯函数形式便于单元测试，不需要文件系统。
限制：剪切板的标识规则与内容摘要不同，需要新增字段。
置信度：高
关联：`E-02`、`solution.md` 第 1.4 节与第 4 节

### E-04：平台目录实现缺口

来源等级：B
环境：分支 `feature/swiftui-macos`
命令或来源：`kmpDomain/src/com/wyz/covio/core/AppDirectories.kt`、`kmpDomain/src@jvm/.../AppDirectories.jvm.kt`
关键输出：

```text
common 只声明 expect object AppDirectories { home, userApplicationSupport, support }
actual 只有两个：src@jvm 与 src@macosArm64
src@jvm 的 userApplicationSupport 返回 "${user.home}/Library/Application Support"
defaultShelfPath 返回 "${userApplicationSupport}/Covio/Screenshots/shelf.json"
```

观察：JVM 实现返回的是 macOS 路径。
观察：没有 Windows、iOS 与 Android 的目录实现。
观察：晾衣线目录用应用名，配置目录用应用标识，两者不同。
推论：工作区在三个平台上没有可用的根目录。
推论：实施阶段 1 必须先补齐目录实现。
限制：未验证 JVM 目标在 Windows 上的实际行为。
置信度：高
关联：`E-02`、`solution.md` 第 1.3 节与第 10.1 节

### E-05：既有设计约定

来源等级：B
关键输出：

```text
临时文件：30 天或 5 GB，可修改保留期、空间上限和置顶
传输：分块传输、SHA-256 校验、断点续传、默认 3 个并发
接收文件先写入临时目录，校验成功后移动到目标目录
Files 页签状态：空、正常、即将过期、已置顶、清理
```

观察：已定义保留期、容量上限与置顶。
观察：已定义传输的校验与续传方式。
观察：临时文件与局域网互传被列为两个独立模块。
推论：共享工作区需要把两个模块合并。
推论：方案参数可以直接沿用，不需要重新决定。
限制：没有定义跨设备副本的策略。
置信度：高
关联：`E-02`、`solution.md` 第 4 节与第 12 节

### E-06：Android 分享入口

来源等级：A
环境：2026-10-12，Android developer 文档
命令或来源：`developer.android.com/training/sharing/receive`、`/training/sharing/send`
关键输出：

```text
接收方在 manifest 声明 ACTION_SEND / ACTION_SEND_MULTIPLE + DEFAULT category + MIME 类型
单个文件用 EXTRA_STREAM，多个文件用 EXTRA_STREAM 的列表，文本用 EXTRA_TEXT
"Although you can receive a MIME type of */*, avoid doing so unless your app is fully capable"
"Android 13 (API level 33) deprecates the unparameterized Intent.getParcelableExtra(String)"
"As of Android 10 (API level 29), the Android Sharesheet only uses icons set in the manifest on your application tag"
接收方不需要声明存储权限
```

观察：应用通过意图过滤器出现在系统分享面板。
观察：读取内容的权限由发送方按 URI 临时授予。
观察：接收方不需要存储权限。
推论：Android 的放入入口不需要额外授权。
推论：图标必须声明在 `application` 标签上。
限制：接收页没有直接写接收方的权限要求，结论由 FileProvider 页反推。
置信度：高
关联：`E-07`、`Case 2`、`V06`

### E-07：Android 公共目录写入

来源等级：A
环境：2026-10-12，Android developer 文档
命令或来源：`developer.android.com/training/data-storage/shared/media`、`/about/versions/11/privacy/storage`
关键输出：

```text
"don't use the value of the DATA column. Instead, use the values of the DISPLAY_NAME and RELATIVE_PATH columns"
"you don't need storage-related permissions to access and modify media files that your app owns"
"your app can contribute to well-defined media collections such as MediaStore.Downloads without requesting any storage-related permissions"
"it's better to use the Storage Access Framework" 用于非媒体文件
IS_PENDING 让写入中的文件只对本应用可见
```

观察：写入自有文件不需要存储权限。
观察：写入用相对路径与展示名，不用绝对路径列。
观察：非媒体文件官方建议改用 SAF。
推论：工作区副本可以只写应用私有目录，完全不碰公共目录。
推论：公共目录导出是可选动作，不是默认行为。
限制：文档没有列举 `Downloads` 允许的 MIME 类型。
置信度：高
关联：`E-08`、`solution.md` 第 6 节

### E-08：Android 全盘权限政策

来源等级：C
环境：2026-10-12，Google Play 政策页
命令或来源：`support.google.com/googleplay/android-developer/answer/10467955`
关键输出：

```text
只有无法使用 SAF 或 MediaStore 时才考虑申请 MANAGE_EXTERNAL_STORAGE
允许用途共 7 类，全部需要 Play 审核
不允许"Media Files access"与"用户手动挑选单个文件"的场景
未申报的应会被下架
```

观察：全盘文件访问权限的审核门槛高。
观察：媒体文件访问不在允许用途内。
推论：Covio 不应申请该权限。
推论：工作区使用私有目录与分享意图，不触发商店审批。
限制：政策页没有列出全部拒绝案例。
置信度：高
关联：`E-07`、`solution.md` 第 6 节

### E-09：Android 缓存目录清理

来源等级：A
环境：2026-10-12，Android developer 文档
命令或来源：`developer.android.com/training/data-storage/app-specific`
关键输出：

```text
"When the device is low on internal storage space, Android may delete these cache files to recover space"
"you shouldn't rely on the system to clean up these files for you"
"To determine how much cache space is currently available for your app, call getCacheQuotaBytes()"
getAllocatableBytes() 的返回值可能大于当前可用空间
"On Android 11 (API level 30) and higher, apps cannot create their own app-specific directory on external storage"
```

观察：系统可能删除内部缓存目录内容。
观察：官方要求应用自己管理缓存。
观察：有配额查询接口。
推论：工作区副本不能放在缓存目录。
推论：工作区放在内部 `files` 目录。
推论：Android 的设备间行为需要在 `V07` 中实测。
限制：文档只把"存储紧张时删除"写给内部缓存目录。
置信度：高
关联：`E-10`、`Case 2`、`V07`

### E-10：Android 后台传输

来源等级：A
环境：2026-10-12，Android developer 文档
命令或来源：`/develop/background-work/background-tasks/persistent/how-to/long-running`、`/about/versions/14/changes/fgs-types-required`、`/develop/background-work/services/fgs/timeout`
关键输出：

```text
"WorkManager has built-in support for long running workers ... These Workers can run longer than 10 minutes"
"If your app targets Android 14 (API level 34) or higher you must specify a foreground service type"
dataSync 用途包含"Data upload or download"与"Transfer data between a device and the cloud over a network"
"If you call startForeground() without declaring the appropriate foreground service type permission, the system throws a SecurityException"
"The system permits dataSync and mediaProcessing foreground services to run for a total of 6 hours in a 24-hour period"
超时后系统调用 Service.onTimeout，再次启动抛 ForegroundServiceStartNotAllowedException
"WorkManager uses JobScheduler internally, so WorkManager tasks don't run" 在 Doze 期间
```

观察：长任务需要前台服务与类型声明。
观察：Android 15 起该类型有 6 小时每 24 小时的配额。
观察：Doze 期间 JobScheduler 不运行。
推论：移动端的大文件传输有硬上限。
推论：需要在 `Service.onTimeout` 中保存断点并暂停。
推论：配额耗尽后只能等用户回到前台。
限制：Android 16 起长任务会消耗作业配额，官方给出替代路径。
置信度：高
关联：`E-09`、`E-11`、`solution.md` 第 4 节

### E-11：Android 冻结与授权有效期

来源等级：A
环境：2026-10-12，AOSP 与 Android developer 文档
命令或来源：`source.android.com/docs/core/perf/cached-apps-freezer`、`/guide/topics/providers/content-provider-basics`
关键输出：

```text
"When an app process is frozen, all of its threads are suspended and can't perform CPU work until unfrozen"
"App processes in the cached state are frozen 10 seconds after entering the cached state"
"The system immediately unfreezes a frozen app process during a lifecycle event"
manifest 声明的广播会立即解冻应用；context 注册的广播被排队
"These are permissions for a specific content URI that last until the activity that receives them is finished"
"The permissions you grant are temporary and expire automatically when the receiving app's task stack is finished"
```

观察：缓存进程被冻结后不执行代码。
观察：生命周期事件立即解冻。
观察：URI 授权随接收方任务栈结束而失效。
推论：分享面板启动接收方属于生命周期事件，能唤醒被冻结的应用。
推论：接收方必须在任务栈结束前读完内容并落盘。
推论：落盘后再开始传输，不能一边传输一边持有授权。
限制：官方没有直接描述分享唤醒被冻结应用的延迟。
置信度：高
关联：`E-06`、`solution.md` 第 3.1 节

### E-12：Windows 分享目标需要包身份

来源等级：A
环境：2026-10-12，Microsoft Learn
命令或来源：`learn.microsoft.com/windows/apps/develop/windows-integration/integrate-sharesheet-receive`、`element-uap-sharetarget`
关键输出：

```text
分享目标在清单中声明 uap:Extension Category="windows.shareTarget"
"To register as a Share Target, your app needs package identity"
两种取得身份的方式：MSIX 重新打包，或外部位置稀疏包
稀疏包需要 runFullTrust 能力与 AllowExternalContent
ShareTarget 必须声明 SupportedFileTypes 或至少一个 DataFormat，两者不能都省略
"Always declare only the specific file types and data formats your app can handle"
DataTransferManager.ShowShareUI 只用于 UWP，桌面应用要用 IDataTransferManagerInterop
```

观察：分享目标必须有包身份。
观察：未打包应用没有替代注册路径。
观察：发送侧对桌面应用也有接口限制。
推论：Windows 的分享面板入口是产品决策点。
推论：不做打包时，Windows 只剩拖放与应用内选择。
限制：官方没有列出未打包应用的替代分享入口。
置信度：高
关联：`E-13`、`Case 1`、`V03`

### E-13：Windows 拖放

来源等级：A
环境：2026-10-12，Microsoft Learn
命令或来源：`learn.microsoft.com/windows/win32/shell/dragdrop`、`/windows/win32/shell/clipboard`
关键输出：

```text
"For drag-and-drop operations, your application must initialize COM with OleInitialize, not CoInitialize"
拖放目标用 RegisterDragDrop 注册 IDropTarget
CF_HDROP 是预定义格式，不需要 RegisterClipboardFormat
DROPFILES 的 pFiles 成员指向双空结尾的文件名数组，用 DragQueryFile 提取
虚拟文件用 CFSTR_FILEDESCRIPTOR 与 CFSTR_FILECONTENTS
```

观察：OLE 拖放与经典拖放都能接收文件。
观察：文件路径通过 `CF_HDROP` 传递。
观察：都不需要包身份。
推论：Windows 的放入入口以拖放为默认路径。
推论：分享面板作为可选增强。
限制：未验证在 Windows 11 上的实际行为。
置信度：高
关联：`E-12`、`Case 1`、`V03`

### E-14：Windows 完整性级别

来源等级：B
环境：2026-10-12，Microsoft Learn 归档文档与 `ChangeWindowMessageFilterEx`
命令或来源：`previous-versions/dotnet/articles/bb625963`、`change-window-message-filter-ex`
关键输出：

```text
UIPI 阻止低权限进程向高权限进程发送窗口消息
"Higher-privilege applications are permitted to send window messages to lower-privilege processes"
ChangeWindowMessageFilterEx 的 MSGFLT_ALLOW 允许特定消息穿过过滤器
```

观察：高完整性进程可以向低完整性进程发消息。
观察：反方向被阻止。
推论：非提升应用接收普通进程拖入的文件不受影响。
推论：提升应用接收非提升进程的拖放会失败，本主题不受影响。
限制：官方没有直接描述拖放跨完整性级别的完整场景。
置信度：中高
关联：`E-13`

### E-15：Windows 临时目录

来源等级：A
环境：2026-10-12，Microsoft Learn
命令或来源：`gettemppathw`、`storage-sense`、`store-and-retrieve-app-data`
关键输出：

```text
GetTempPath 按 TMP、TEMP、USERPROFILE、Windows 目录的顺序取第一个存在的
"Apps should call GetTempPath2 instead of GetTempPath"
存储感知可以清理用户临时文件，默认在磁盘空间不足时自动运行
可配置为每天、每周、每月或仅在空间不足时运行
TemporaryFolder："could be removed at any time"、"There is no guarantee that this data will persist"
"Local app data should be used for any information that needs to be preserved between app sessions"
```

观察：临时目录内容会被系统清理。
观察：本地应用数据目录用于需要保留的数据。
观察：存储感知的清理节奏由用户或策略决定。
推论：工作区数据放 `%LOCALAPPDATA%`，不放 `%TEMP%`。
推论：工作区不得依赖系统清理来执行过期。
限制：官方没有给出清理临时文件的天数阈值。
置信度：高
关联：`E-09`、`solution.md` 第 1.3 节

### E-16：iOS 接收入口

来源等级：A，归档文档为 A-
环境：2026-10-12，Apple developer 文档与归档文档
命令或来源：`ExtensibilityPG/Share.html`、`ExtensibilityPG/ExtensionScenarios.html`、`AppExtensionKeys.html`、`defining-file-and-data-types-for-your-app`、`qa1587/_index.html`
关键输出：

```text
"In iOS, users tap the Share button and choose a Share extension from the sharing area of the activity view controller that appears."
扩展点标识符为 com.apple.share-services
激活规则写在 NSExtensionActivationRule 里，可以是字典或谓词字符串
字典键包括 NSExtensionActivationSupportsFileWithMaxCount、…ImageWithMaxCount、…MovieWithMaxCount、…Text、…WebURLWithMaxCount
"If any app extensions in your containing app include the string TRUEPREDICATE, the app will be rejected."
UIActivityViewController 的 applicationActivities 只出现在发起方自己的应用里
非扩展路径见 QA1587：用 CFBundleDocumentTypes 注册类型，系统生成"打开方式"菜单
```

观察：分享面板只列出 App Extension。
观察：激活规则声明支持的类型与数量上限。
观察：普通应用没有进入他人分享面板的公开路径。
观察：文档类型注册只处理单个 URL。
推论：iOS 的放入入口是分享扩展。
推论：文档类型注册只能作为辅助入口。
限制：普通应用能否出现在分享面板属负向证据，未找到 Apple 的肯定表述。
置信度：高
关联：`E-17`、`Case 2`、`V04`

### E-17：分享扩展的容器与限制

来源等级：A，归档文档为 A-
环境：2026-10-12，Apple developer 文档与归档文档
命令或来源：`ExtensibilityPG/ExtensionScenarios.html`、`ExtensibilityPG/ExtensionCreation.html`、`containerurl(forsecurityapplicationgroupidentifier:)`、`configuring-app-groups`
关键输出：

```text
"the running app extension and containing app have no direct access to each other's containers"
"the containing app—and each contained app extension that you allow to participate in data sharing—have read and write access to the shared container"
"To avoid data corruption, you must synchronize data accesses."
"Memory limits for running app extensions are significantly lower than the memory limits imposed on a foreground app"
"An extension that launches too slowly is terminated by the system."，启动目标是 "well under one second"
"If you include the UIBackgroundModes key in your app extension's Info.plist file, the extension will be rejected by the App Store."
"If your app extension initiates a background NSURLSession task, you must also set up a shared container"，用 sharedContainerIdentifier 指定
"In iOS, the group identifier starts with the word group and a dot"
"when all the apps in a given app group are removed from the device, the system … removes the corresponding group directory as well"
"The system creates only the Library/Caches subdirectory automatically."
```

观察：扩展与主应用不能互相读对方容器。
观察：共享容器两端都可读写，并发写入需要加锁。
观察：扩展内存低于前台应用，且随时可被终止。
观察：扩展不能声明后台模式。
观察：组内应用全部卸载后，系统删除共享容器。
推论：扩展只负责把内容搬进共享容器。
推论：大文件按文件路径传递，不整体读入内存。
推论：传输交给主应用，不放扩展。
限制：Apple 未公布扩展的内存上限与执行时间上限。
置信度：高
关联：`E-16`、`E-18`、`solution.md` 第 3.1 节

### E-18：iOS 后台传输

来源等级：A
环境：2026-10-12，Apple developer 文档
命令或来源：`downloading-files-in-the-background`、`urlsessionconfiguration/background(withidentifier:)`、`urlsessionconfiguration/isdiscretionary`、`application(_:handleeventsforbackgroundurlsession:completionhandler:)`
关键输出：

```text
"In iOS, this configuration makes it possible for transfers to continue even when the app itself is suspended or terminated."
"If the user terminates the app from the multitasking screen, the system cancels all of the session's background transfers."
"the system does not automatically relaunch apps that were force quit by the user"
只支持 HTTP 与 HTTPS；重定向总是被跟随；上传必须从文件发起
"the system always starts transfers at its discretion"，后台发起时忽略 isDiscretionary
速率限制器：后台启动新任务先等待，延迟随重启次数增加，回到前台后清零
任务完成后的文件在临时位置，回调返回后失效
```

观察：后台传输由系统进程执行，独立于应用进程。
观察：用户手动结束应用会取消全部后台传输。
观察：后台会话只支持 HTTP 与 HTTPS。
观察：后台发起任务受速率限制。
推论：iOS 的大文件传输走系统后台会话。
推论：现有自定义协议不能在后台会话里使用。
推论：用户强杀后的任务必须重新入队。
限制：Apple 未公布后台传输的字节上限与单次时长上限。
置信度：高
关联：`E-17`、`solution.md` 第 3.7 节、`V05`

### E-19：iOS 容器清理与备份

来源等级：A，归档文档为 A-
环境：2026-10-12，Apple developer 文档与归档文档
命令或来源：`optimizing-your-app-s-data-for-icloud-backup`、`FileSystemProgrammingGuide/FileSystemOverview`
关键输出：

```text
"The system periodically purges these directories"，指 /tmp 与 /Library/Caches，"so iCloud Backup excludes them by default"
"Don't use these directories to exclude nonpurgeable data from iCloud Backup."
"The contents of this directory are backed up by iTunes and iCloud."，指 Documents
"The contents of the Library directory (with the exception of the Caches subdirectory) are backed up by iTunes and iCloud."
"The isExcludedFromBackup resource value exists only to provide guidance … it's not a mechanism to guarantee"
```

观察：`Caches` 与 `tmp` 会被系统定期清理，且默认不进备份。
观察：`Documents` 与 `Library`（除 `Caches` 外）进入备份。
观察：备份排除标记只是给系统的提示。
推论：iOS 副本的目录位置决定备份与清理行为。
推论：副本放 `Library/Application Support`，过期由 Covio 自己执行。
推论：不能依赖备份排除标记来保证内容不进备份。
限制：Apple 未公布应用或共享容器的存储配额数字。
置信度：高
关联：`E-17`、`solution.md` 第 1.3 节、`V05`

### E-20：iOS 相册与文件 App 写入

来源等级：A，支持文章为 C
环境：2026-10-12，Apple developer 文档与支持文章
命令或来源：`phassetcreationrequest`、`addresource(with:fileurl:options:)`、`supportsassetresourcetypes(_:)`、`phassetresourcetype/audio`、`phphotolibrary/requestauthorization(for:handler:)`、`phaccesslevel`、`nsphotolibraryaddusagedescription`、`uifilesharingenabled`、`support.apple.com/en-us/148676`
关键输出：

```text
"NSPhotoLibraryAddUsageDescription … required if your app uses APIs that have write access to the user's photo library."
授权等级为 PHAccessLevel.addOnly 与 PHAccessLevel.readWrite，用 requestAuthorization(for:handler:) 申请
"If you instantiate or use this class outside a photo library change block, Photos throws an exception."
"This method verifies only that the collection of asset resource types is valid (for example, ensuring that you do not attempt to construct a photo asset without image data)"
PHAssetResourceType.audio："Provides the original audio data for its asset."
相册支持格式只列图片与视频：HEIF、JPEG、RAW、PNG、GIF、TIFF、HEVC、MP4、QuickTime、H.264、MPEG-4
UIFileSharingEnabled 默认是 NO，文件放在 Documents 才对用户可见
```

观察：写相册需要用途说明键与运行时授权。
观察：相册写入必须在变更块内执行。
观察：音频是某个资产的资源，不是独立资产类型。
观察：官方支持的相册格式不含音频。
推论：相册导出只覆盖图片与视频。
推论：取出的内容默认落在应用容器，并按需导出到文件 App 可见位置。
限制：音频单独写入相册没有 Apple 的肯定或否定表述。
置信度：高
关联：`E-19`、`solution.md` 第 6 节

### E-21：macOS 拖放与沙盒扩展

来源等级：A，归档文档为 A-
环境：macOS 27.0.1，Apple developer 文档与归档文档
命令或来源：`nsdraggingdestination`、`nspasteboard/pasteboardtype/fileurl`、`readobjects(forclasses:options:)`、`nsfilepromiseprovider`、`EnablingAppSandbox.html`、`accessing-files-from-the-macos-app-sandbox`
关键输出：

```text
"Certain other user interactions, such as dragging items to your app or choosing items from the Open Recent menu, automatically expand your sandbox to include those items."
"The operating system starts security-scoped access on URLs passed from open panels, save panels, or items dragged to your app's icon in the Dock, as if you called startAccessingSecurityScopedResource()."
拖放目标实现 draggingEntered:、draggingUpdated:、prepareForDragOperation:、performDragOperation:、concludeDragOperation:
用 readObjects(forClasses:options:) 读 NSURL 的 fileURL 类型
NSFilePromiseProvider 的类型必须最终符合 kUTTypeData 或 kUTTypeDirectory
```

观察：拖入应用会自动扩展沙盒授权。
观察：沙盒扩展基于文件 URL 类型，不是字符串路径。
观察：两条 Apple 表述的授权范围不完全一致。
推论：macOS 的放入入口用拖放，不需要额外的文件授权。
推论：授权范围需要在 `V01` 中实测。
限制：拖入窗口的授权范围与时长没有 Apple 一级表述。
置信度：高
关联：`E-01`、`Case 1`、`V01`

### E-22：隔空投送对照

来源等级：A
环境：2026-10-12，Apple 支持文章、用户指南与 developer 文档
命令或来源：`support.apple.com/en-us/102538`、`support.apple.com/en-us/119857`、`nssharingservice/name/sendviaairdrop`、`samplecode/sc2273`、`implementing-handoff-in-your-app`、`devicediscoveryui`、`wifiaware`、`multipeerconnectivity`
关键输出：

```text
"tap or click Accept on the AirDrop notification"
"If you're using AirDrop to send items between your Apple devices, sign in to the same Apple Account to automatically accept and save the items."
iOS 26.2 起，非同账号设备之间提示使用 AirDrop code，配对有效期 30 天
"Everyone for 10 Minutes" 超时后按登录状态回落
落点：相册内容进照片应用，部分内容进文件 App，macOS 进"下载"或由用户选择
NSSharingService.Name.sendViaAirDrop 只在 macOS 提供，自 10.8 起
iOS 发送必须经 UIActivityViewController，由用户手动选择"隔空投送"
"To handoff between apps on different platforms, your apps must share the same developer Team ID."
公开 SDK 没有 iOS 的隔空投送编程接口
```

观察：隔空投送需要接收方同意或同账号。
观察：iOS 没有隔空投送的第三方接口。
观察：发送路径由系统分享面板控制。
推论：本主题的差异在共享副本与过期两项，这两项隔空投送不提供。
推论：产品文案不宣称调用隔空投送。
限制：隔空投送是否要求接收设备解锁未找到证据。
置信度：高
关联：`investigation.md` 第 8 节、`conclusion.md` 第 5 节

## 6. 逻辑证据链

```text
研究问题：能否在四个平台把内容推入一个共享工作区
  -> 来源：E-06、E-12、E-13
  -> 观察：Android 提供分享入口，Windows 拖放可用，Windows 分享面板需要包身份
  -> 推论：每个平台至少有一个不需要额外授权的放入入口
  -> 决策：以分享面板加拖放作为默认入口
  -> 验证条件：V01 至 V07
  -> 回填位置：solution.md 第 3.1 节
```

```text
研究问题：工作区内容存在哪里
  -> 来源：E-02、E-03、E-04、E-09、E-15
  -> 观察：现有晾衣线只存路径，缓存目录会被系统清理，平台目录尚未实现
  -> 推论：工作区需要独立的、由应用拥有的存储目录
  -> 决策：本地优先副本，内容寻址，放在应用数据目录
  -> 验证条件：V07、V08
  -> 回填位置：solution.md 第 1.3 节
```

```text
研究问题：移动端能否完成大文件传输
  -> 来源：E-10、E-11
  -> 观察：前台服务有类型要求与 6 小时配额，冻结进程在生命周期事件时解冻
  -> 推论：移动端传输有硬上限，需要断点与超时处理
  -> 决策：移动端只在有电与前台窗口内传输大文件
  -> 验证条件：V05、V09
  -> 回填位置：solution.md 第 4 节
```

```text
研究问题：iOS 能否把内容推入工作区
  -> 来源：E-16、E-17、E-18、E-19
  -> 观察：分享面板只列扩展，扩展与主应用靠共享容器交换文件，主应用有系统后台传输且只支持 HTTP
  -> 推论：iOS 的入口是分享扩展加共享容器，大文件由主应用执行
  -> 决策：扩展只落盘，传输交给主应用；后台传输需要 HTTP 端点或退到前台
  -> 验证条件：V04、V05
  -> 回填位置：solution.md 第 3.1 节与第 3.7 节
```

```text
研究问题：本主题与隔空投送的差别
  -> 来源：E-22
  -> 观察：隔空投送需要接收方同意，iOS 没有第三方接口，内容是定向单次投送
  -> 推论：共享副本与过期是本主题的增量，投送通道不能复用
  -> 决策：自建会话通道，产品文案不宣称隔空投送
  -> 验证条件：不在验证范围
  -> 回填位置：conclusion.md 第 5 节
```

## 7. 反证和限制

### 7.1 Android 参考页无法取证

三个接口参考页只返回导航索引。
受影响的是 `Intent` 常量、`StorageManager` 与 `Manifest.permission`。
相关结论改用训练页原文代替。

### 7.2 未验证的平台行为

Android、Windows 与 iOS 的结论全部来自官方文档。
没有真机交叉验证。
`E-14` 的推论只有归档文档支持。
`E-16`、`E-17`、`E-19`、`E-21` 用到归档文档，等级记 A-。

### 7.3 事件缺失的负向证据

"没有替代注册路径"这类结论是未找到证据，不是官方否认。

### 7.4 检索配额

两路调研共用有限次数的网页检索。
未核实的条目见第 8 节。

### 7.5 Apple 未公布的数值

以下项目在 Apple 文档里没有数值或结论。
这些是未找到证据，不是官方否认。

1. 扩展的内存上限。文档只说“明显低于前台应用”。
2. 扩展的执行时间上限。文档只给启动目标。
3. 后台传输的字节上限与单次时长上限。
4. 应用与共享容器的存储配额。
5. 音频单独写入相册是否支持。
6. 隔空投送是否要求接收设备解锁。
7. 应用组容器是否进入 iCloud 备份。
8. 拖入窗口时沙盒授权的范围与时长。
9. 无扩展的普通应用能否稳定出现在分享面板。

## 8. 已知缺口

1. 没有移动端真机验证。
2. 没有跨平台端到端验证。
3. iOS 副本是否进入 iCloud 备份，待产品确认。
4. macOS 拖入窗口的沙盒授权范围与时长未实测。
5. Android `MediaStore.Downloads` 允许的 MIME 类型未列举。
6. 分享唤醒被冻结应用的延迟未给出数值。
7. Windows 11 任务栏图标的拖放没有官方接口文档。
8. 存储感知清理临时文件的天数阈值没有官方数值。
9. 厂商定制系统对缓存目录与后台策略的差异未核实。
10. 扩展内存上限与后台传输上限没有官方数值。

## 9. 复核方法

1. 在 macOS 27 上运行第 3.1 节的命令。
2. 打开 `E-06` 至 `E-22` 的来源链接，核对引文。
3. 按 [validation/README.md](validation/README.md) 执行测试矩阵。
4. 真机验证时记录系统版本与构建号。

## 参考来源

- [Android 接收分享内容](https://developer.android.com/training/sharing/receive)
- [Android 发送分享内容](https://developer.android.com/training/sharing/send)
- [Android 媒体存储](https://developer.android.com/training/data-storage/shared/media)
- [Android 应用专属存储](https://developer.android.com/training/data-storage/app-specific)
- [Android 长任务](https://developer.android.com/develop/background-work/background-tasks/persistent/how-to/long-running)
- [Android 前台服务类型](https://developer.android.com/about/versions/14/changes/fgs-types-required)
- [Android 前台服务超时](https://developer.android.com/develop/background-work/services/fgs/timeout)
- [AOSP 缓存应用冻结](https://source.android.com/docs/core/perf/cached-apps-freezer)
- [Google Play 全盘访问政策](https://support.google.com/googleplay/android-developer/answer/10467955)
- [Windows 接收分享](https://learn.microsoft.com/en-us/windows/apps/develop/windows-integration/integrate-sharesheet-receive)
- [uap:ShareTarget](https://learn.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/element-uap-sharetarget)
- [Windows 拖放](https://learn.microsoft.com/en-us/windows/win32/shell/dragdrop)
- [ChangeWindowMessageFilterEx](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-changewindowmessagefilterex)
- [GetTempPath2](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppath2w)
- [存储感知](https://learn.microsoft.com/en-us/windows/configuration/storage/storage-sense)
- [iOS 分享扩展](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html)
- [扩展场景与共享容器](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html)
- [应用扩展的 Info.plist 键](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AppExtensionKeys.html)
- [注册文件与数据类型](https://developer.apple.com/documentation/uniformtypeidentifiers/defining-file-and-data-types-for-your-app)
- [共享容器路径](https://developer.apple.com/documentation/foundation/filemanager/containerurl(forsecurityapplicationgroupidentifier:))
- [配置应用组](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [后台下载](https://developer.apple.com/documentation/Foundation/downloading-files-in-the-background)
- [后台会话配置](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/background(withidentifier:))
- [为 iCloud 备份优化数据](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup)
- [文件系统概览](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html)
- [相册资源创建](https://developer.apple.com/documentation/photos/phassetcreationrequest)
- [相册资源类型](https://developer.apple.com/documentation/photos/phassetresourcetype/audio)
- [拖放目标](https://developer.apple.com/documentation/appkit/nsdraggingdestination)
- [文件承诺](https://developer.apple.com/documentation/appkit/nsfilepromiseprovider)
- [启用应用沙盒](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/EnablingAppSandbox.html)
- [隔空投送接收](https://support.apple.com/en-us/102538)
- [隔空投送发送](https://support.apple.com/en-us/119857)
- [NSSharingService.Name.sendViaAirDrop](https://developer.apple.com/documentation/appkit/nssharingservice/name/sendviaairdrop)
- [上一主题：跨设备内容读取能力](../cross-device-content-access/evidence.md)

## 10. 关联文档

- [主题索引](README.md)
- [验证目录](validation/README.md)
