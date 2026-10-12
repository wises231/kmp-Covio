package com.wyz.covio.core

import com.wyz.covio.domain.EngineLock
import kotlinx.serialization.json.Json
import kotlin.random.Random
import okio.Buffer
import okio.ByteString.Companion.toByteString
import okio.FileSystem
import okio.HashingSink
import okio.HashingSource
import okio.IOException
import okio.Path
import okio.Path.Companion.toPath

/** 一次读写内容的字节数。放入大文件时用它分块，不整份进内存。 */
private const val CHUNK_BYTES = 64L * 1024

/**
 * 工作区的持久化。
 *
 * 与 [ShelfStore]、[ClipboardStore] 同一套做法：一个 `@Serializable` 状态对象，
 * 先用 okio 写 `.tmp` 再原子改名。没有用 SQLDelight，理由见 [ClipboardStore] 的类注释。
 *
 * 目录布局与 `docs/research/shared-transfer-workspace/solution.md` 第 1.3 节一致：
 *
 * ```text
 * <应用数据根>/Covio/Workspace/
 *   index.json          条目索引，原子写入
 *   objects/<sha256>    内容字节，按摘要命名
 *   incoming/<sha256>   未完成的写入，校验后改名移入 objects
 * ```
 *
 * 删除标记（`tombstones.json`）属于复制阶段，这里不写。
 *
 * **内容寻址。** 文件名就是内容的 SHA-256。相同内容只存一份，同名不同内容自动分开。
 * 摘要以外的字符会被拒绝：摘要是十六进制，出现别的字符就不该拼进路径。
 */
class WorkspaceStore(
    val directory: String = defaultWorkspaceDirectory(),
    private val fileSystem: FileSystem = FileSystem.SYSTEM,
    private val json: Json = defaultJson(),
) {
    private val lock = EngineLock()

    val indexPath: String get() = "$directory/index.json"

    val objectsDirectory: String get() = "$directory/objects"

    val incomingDirectory: String get() = "$directory/incoming"

    /**
     * 读取索引。
     *
     * 文件不存在、读不动、JSON 坏了都返回空状态。与 [ClipboardStore.load] 一样不抛异常：
     * 异常跨到 Swift 没有接收方。
     */
    fun load(): WorkspaceState = lock.withLock {
        val state = runCatching {
            val target = indexPath.toPath()
            if (!fileSystem.exists(target)) return@runCatching null
            json.decodeFromString<WorkspaceState>(fileSystem.read(target) { readUtf8() })
        }.getOrNull()
        (state ?: WorkspaceState()).normalized()
    }

    /**
     * 写入索引，返回规范化之后的状态。
     *
     * **写盘失败不抛异常。** 理由与 [ShelfStore.save] 相同：异常跨到 Swift 没有接收方，
     * 会直接终止进程。磁盘满、目录被删都会走到这里，而调用方是每次条目变化都会跑的落盘。
     */
    fun save(state: WorkspaceState): WorkspaceState = lock.withLock {
        val normalized = state.normalized()
        runCatching {
            val target = indexPath.toPath()
            target.parent?.let { fileSystem.createDirectories(it) }
            val temporary = target.parent!!.resolve(target.name + ".tmp")
            fileSystem.write(temporary) {
                writeUtf8(json.encodeToString(WorkspaceState.serializer(), normalized))
            }
            fileSystem.atomicMove(temporary, target)
        }
        normalized
    }

    /** 清空索引与两个内容目录。 */
    fun clear(): Boolean = lock.withLock {
        runCatching {
            val target = indexPath.toPath()
            fileSystem.delete(target, mustExist = false)
            fileSystem.delete(target.parent!!.resolve(target.name + ".tmp"), mustExist = false)
            fileSystem.deleteRecursively(objectsDirectory.toPath(), mustExist = false)
            fileSystem.deleteRecursively(incomingDirectory.toPath(), mustExist = false)
        }.isSuccess
    }

    /** 一条条目内容的落盘路径。摘要不合法时返回 null。 */
    fun contentPath(entryId: String): String? {
        val id = normalizeEntryId(entryId)
        return if (WorkspaceLogic.isValidEntryId(id)) "$objectsDirectory/$id" else null
    }

    fun hasContent(entryId: String): Boolean {
        val path = contentPath(entryId)?.toPath() ?: return false
        return runCatching { fileSystem.exists(path) }.getOrDefault(false)
    }

    fun readContent(entryId: String): ByteArray? {
        val path = contentPath(entryId)?.toPath() ?: return null
        return runCatching { fileSystem.read(path) { readByteArray() } }.getOrNull()
    }

    /**
     * 放入一段内容。
     *
     * 流程与方案第 3.1 节一致：先写 `incoming`，摘要不对就丢弃，对了再改名移入 `objects`。
     * 摘要由调用方给出，这里复核。摘要不符时什么都不写。
     */
    fun putContent(entryId: String, bytes: ByteArray): Boolean = lock.withLock {
        val id = normalizeEntryId(entryId)
        if (!WorkspaceLogic.isValidEntryId(id)) return@withLock false
        if (digestOf(bytes) != id) return@withLock false
        runCatching {
            val incoming = "$incomingDirectory/$id".toPath()
            incoming.parent?.let { fileSystem.createDirectories(incoming.parent!!) }
            fileSystem.write(incoming) { write(bytes) }
            val target = "$objectsDirectory/$id".toPath()
            target.parent?.let { fileSystem.createDirectories(it) }
            fileSystem.atomicMove(incoming, target)
        }.isSuccess
    }

    /**
     * 放入一段内容并返回摘要。
     *
     * 摘要算不出来或写入失败时返回 null。这是「放入」的入口：
     * 调用方给字节，落盘位置由摘要决定。
     */
    fun importContent(bytes: ByteArray): String? {
        val id = digestOf(bytes)
        return if (putContent(id, bytes)) id else null
    }

    /**
     * 把一个外部文件放进工作区。
     *
     * 边读边写边算摘要，不把文件读进内存：单条目上限是 2 GB。
     * 流程与方案第 3.1 节一致：
     *
     * 1. 写 `incoming/<随机名>.part`，同时算摘要。
     * 2. 超过单条目上限时中止并删掉半份文件。
     * 3. 改名成 `incoming/<摘要>`，再原子移入 `objects/<摘要>`。
     * 4. 摘要已存在时只把条目并回索引，不新建。
     *
     * 只读源文件，不动源文件。
     */
    fun putFile(
        state: WorkspaceState,
        sourcePath: String,
        displayName: String,
        contentType: String,
        originDeviceId: String,
        nowEpochSeconds: Long,
    ): WorkspacePutResult = lock.withLock {
        val policy = state.policy.normalized()
        val source = sourcePath.trim().toPath()
        val name = normalizeDisplayName(displayName)

        // 先看一眼文件有多大，超过上限就不必读一遍。
        val declaredSize = runCatching { fileSystem.metadata(source).size }.getOrNull()
        if (declaredSize != null && declaredSize > policy.maxEntryBytes) {
            return@withLock WorkspacePutResult(state, null, WorkspaceAdmission.TOO_LARGE)
        }

        val staged = runCatching { stage(source, policy.maxEntryBytes) }.getOrNull()
            ?: return@withLock WorkspacePutResult(state, null, WorkspaceAdmission.FAILED)
        val done = when (staged) {
            is Staged.Done -> staged
            Staged.TooLarge -> return@withLock WorkspacePutResult(state, null, WorkspaceAdmission.TOO_LARGE)
        }

        val entry = WorkspaceEntry(
            entryId = done.entryId,
            kind = WorkspaceLogic.classify(name, contentType),
            displayName = name,
            byteSize = done.byteSize,
            contentType = contentType.trim(),
            createdAtEpochSeconds = nowEpochSeconds.coerceAtLeast(0L),
            originDeviceId = originDeviceId.trim(),
            expiresAtEpochSeconds = WorkspaceLogic.expiryEpochSeconds(nowEpochSeconds, policy),
        )

        when (val verdict = WorkspaceLogic.admit(entry, state.entries, policy)) {
            WorkspaceAdmission.ACCEPTED -> {
                val next = save(state.copy(entries = state.entries + entry))
                WorkspacePutResult(next, next.entries.firstOrNull { it.entryId == entry.entryId } ?: entry, verdict)
            }

            WorkspaceAdmission.DUPLICATE -> {
                // 内容相同，`objects` 里就是同一个文件，不必删。
                val existing = WorkspaceLogic.dedupe(state.entries).firstOrNull { it.entryId == entry.entryId }
                WorkspacePutResult(state, existing, verdict)
            }

            else -> {
                deleteContent(entry.entryId)
                WorkspacePutResult(state, null, verdict)
            }
        }
    }

    /** 改一条条目的置顶标记。置顶是本机属性，不参与复制。 */
    fun setPinned(state: WorkspaceState, entryId: String, pinned: Boolean): WorkspaceState = lock.withLock {
        val id = normalizeEntryId(entryId)
        if (!WorkspaceLogic.isValidEntryId(id)) return@withLock state
        val entries = state.entries.map { if (it.entryId == id) it.copy(pinned = pinned) else it }
        save(state.copy(entries = entries))
    }

    /** 删掉一条条目及其内容。删除是全局操作，广播由复制层负责。 */
    fun remove(state: WorkspaceState, entryId: String): WorkspaceState = lock.withLock {
        val id = normalizeEntryId(entryId)
        if (!WorkspaceLogic.isValidEntryId(id)) return@withLock state
        val entries = state.entries.filterNot { it.entryId == id }
        if (entries.size != state.entries.size) deleteContent(id)
        save(state.copy(entries = entries))
    }

    /**
     * 把源文件读进 `incoming`，返回摘要与字节数。
     *
     * 摘要用 [HashingSink] 边写边算。超过上限时中止，半份文件删掉。
     * 读不动或写不进时抛异常，由 [putFile] 收成 `FAILED`。
     */
    private fun stage(source: Path, maxEntryBytes: Long): Staged {
        val partial = "$incomingDirectory/${stagingName()}.part".toPath()
        partial.parent?.let { fileSystem.createDirectories(it) }
        val input = fileSystem.source(source)
        val output = fileSystem.sink(partial)
        var byteSize = 0L
        var entryId: String? = null
        var tooLarge = false
        try {
            val hashing = HashingSink.sha256(output)
            val buffer = Buffer()
            while (true) {
                val read = input.read(buffer, CHUNK_BYTES)
                if (read == -1L) break
                byteSize += read
                if (byteSize > maxEntryBytes) {
                    tooLarge = true
                    break
                }
                hashing.write(buffer, read)
            }
            if (!tooLarge) entryId = hashing.hash.hex()
        } finally {
            output.close()
            input.close()
        }

        if (tooLarge || entryId == null) {
            fileSystem.delete(partial, mustExist = false)
            if (tooLarge) return Staged.TooLarge
            throw IOException("staging produced no digest")
        }

        // 先改名成摘要，再原子移入 objects：`incoming` 里不留半成品。
        val named = "$incomingDirectory/$entryId".toPath()
        fileSystem.atomicMove(partial, named)
        val target = "$objectsDirectory/$entryId".toPath()
        target.parent?.let { fileSystem.createDirectories(it) }
        fileSystem.atomicMove(named, target)
        return Staged.Done(entryId, byteSize)
    }

    /** 未完成内容的临时文件名。摘要还不知道，所以用随机名。 */
    private fun stagingName(): String =
        "${Random.nextLong().toString(16).removePrefix("-")}-${Random.nextInt().toString(16).removePrefix("-")}"

    /**
     * 重新读一遍内容，核对摘要。文件不存在或摘要不符都返回 false。
     */
    fun verifyContent(entryId: String): Boolean {
        val id = normalizeEntryId(entryId)
        val path = contentPath(id)?.toPath() ?: return false
        if (!runCatching { fileSystem.exists(path) }.getOrDefault(false)) return false
        return digestOfFile(path) == id
    }

    fun deleteContent(entryId: String): Boolean = lock.withLock {
        val path = contentPath(entryId)?.toPath() ?: return@withLock false
        runCatching { fileSystem.delete(path, mustExist = false) }.isSuccess
    }

    /**
     * 按策略执行一次过期与淘汰。
     *
     * 被淘汰与过期的条目连同内容一起删除，剩下的索引落盘。
     * 空间不足时淘汰的是旧条目，不是拒绝新条目——拒绝发生在放入那一刻。
     */
    fun sweep(policy: WorkspacePolicy, nowEpochSeconds: Long): WorkspacePlan = lock.withLock {
        val state = load()
        val plan = WorkspaceLogic.plan(state.entries, policy, nowEpochSeconds)
        plan.removed.forEach { deleteContent(it.entryId) }
        save(state.copy(policy = policy.normalized(), entries = plan.kept))
        plan
    }

    /** 索引里所有条目的内容字节合计。用于界面显示占用。 */
    fun localBytes(state: WorkspaceState): Long = state.entries.sumOf { it.localBytes }

    private fun digestOf(bytes: ByteArray): String = bytes.toByteString().sha256().hex()

    /**
     * 流式算一遍文件摘要。
     *
     * 用 `read` 加 `clear` 的循环，不用 `use`：这里的 `Source` 不是 `AutoCloseable`，
     * `.use` 在 macosArm64 上解析不到。同模块的 [ShelfStore] 与 [ClipboardStore]
     * 也一律用 `try` / `finally`。
     * 大文件不一次读进内存：单条目上限是 2 GB。
     */
    private fun digestOfFile(path: Path): String? = runCatching {
        val source = fileSystem.source(path)
        try {
            val hashing = HashingSource.sha256(source)
            val buffer = Buffer()
            while (hashing.read(buffer, 8192L) != -1L) {
                buffer.clear()
            }
            hashing.hash.hex()
        } finally {
            source.close()
        }
    }.getOrNull()

    companion object {
        /**
         * 按目录构造。理由同 [ShelfStore.create]：默认参数不导出到 Swift，
         * 从 Swift 拼一个 `Json` 会让两版写出的文件不同。
         */
        fun create(directory: String): WorkspaceStore =
            WorkspaceStore(directory = directory, fileSystem = FileSystem.SYSTEM, json = defaultJson())

        internal fun defaultJson(): Json = Json {
            prettyPrint = true
            ignoreUnknownKeys = true
            encodeDefaults = true
        }

        /** 一段内容的摘要。与放入、校验用的是同一套算法。 */
        fun digestOf(bytes: ByteArray): String = bytes.toByteString().sha256().hex()

        /**
         * 工作区目录。用 `APP_NAME` 而不是 `APP_ID`，与晾衣线和剪切板一致。
         */
        fun defaultDirectory(): String =
            "${AppDirectories.userApplicationSupport}/${APP_NAME}/Workspace"
    }
}

internal fun defaultWorkspaceDirectory(): String = WorkspaceStore.defaultDirectory()

private fun WorkspaceState.normalized(): WorkspaceState = copy(
    schemaVersion = 1,
    entries = WorkspaceLogic.dedupe(entries),
    policy = policy.normalized(),
)

/**
 * 工作区的纯逻辑。没有 IO，两个平台跑同一份。
 *
 * 与 [ClipboardLogic] 同一形状：输入条目列表、策略与当前时间，输出保留与淘汰的结果。
 * 淘汰顺序是「过期的、超单条上限的、未置顶且最旧的」，置顶条目只在用户手动删除时移除。
 */
object WorkspaceLogic {
    /** 摘要的合法写法：SHA-256 的十六进制。 */
    private val ENTRY_ID_PATTERN = Regex("^[0-9a-f]{64}$")

    private const val SECONDS_PER_DAY = 24L * 60 * 60

    private val IMAGE_EXTENSIONS = setOf("png", "jpg", "jpeg", "gif", "heic", "heif", "webp", "tiff", "tif", "bmp")
    private val AUDIO_EXTENSIONS = setOf("mp3", "m4a", "aac", "wav", "flac", "ogg", "opus", "aiff")
    private val TEXT_EXTENSIONS =
        setOf("txt", "md", "csv", "json", "log", "xml", "yaml", "yml", "html", "css", "kt", "swift", "py", "sh")

    /** 摘要是不是合法的十六进制 SHA-256。 */
    fun isValidEntryId(value: String): Boolean = ENTRY_ID_PATTERN.matches(normalizeEntryId(value))

    /**
     * 按展示名与内容类型判断条目类别。
     *
     * 先看内容类型，再看扩展名。都判不出来算普通文件。
     * 这里只做形态判断，不读内容。
     */
    fun classify(displayName: String, contentType: String): WorkspaceKind {
        val type = contentType.trim().lowercase()
        when {
            type.startsWith("image/") -> return WorkspaceKind.IMAGE
            type.startsWith("audio/") -> return WorkspaceKind.AUDIO
            type == "application/pdf" -> return WorkspaceKind.PDF
            type.startsWith("text/") -> return WorkspaceKind.TEXT
        }
        val extension = displayName.trim().substringAfterLast('.', "").lowercase()
        return when (extension) {
            in IMAGE_EXTENSIONS -> WorkspaceKind.IMAGE
            in AUDIO_EXTENSIONS -> WorkspaceKind.AUDIO
            "pdf" -> WorkspaceKind.PDF
            in TEXT_EXTENSIONS -> WorkspaceKind.TEXT
            else -> WorkspaceKind.FILE
        }
    }

    /**
     * 放入时的过期时间。返回 0 表示不过期。
     *
     * 保留期为 0 时不过期，与 [ClipPolicy.maxAgeDays] 同一套约定。
     */
    fun expiryEpochSeconds(createdAtEpochSeconds: Long, policy: WorkspacePolicy): Long {
        val days = policy.normalized().retentionDays
        if (days <= 0) return 0L
        return createdAtEpochSeconds.coerceAtLeast(0L) + days.toLong() * SECONDS_PER_DAY
    }

    /**
     * 判断一条条目能不能放入。
     *
     * 摘要重复时返回 [WorkspaceAdmission.DUPLICATE]，由调用方合并到已有条目。
     * 空间不足时返回 [WorkspaceAdmission.QUOTA_EXCEEDED]：先拒绝新条目，不删已有条目。
     */
    fun admit(
        candidate: WorkspaceEntry,
        entries: List<WorkspaceEntry>,
        policy: WorkspacePolicy,
    ): WorkspaceAdmission {
        val rules = policy.normalized()
        val entry = candidate.normalized()
        if (!isValidEntryId(entry.entryId)) return WorkspaceAdmission.INVALID
        if (entry.byteSize > rules.maxEntryBytes) return WorkspaceAdmission.TOO_LARGE
        val existing = dedupe(entries)
        if (existing.any { it.entryId == entry.entryId }) return WorkspaceAdmission.DUPLICATE
        val used = existing.sumOf { it.localBytes }
        if (used + entry.localBytes > rules.maxTotalBytes) return WorkspaceAdmission.QUOTA_EXCEEDED
        return WorkspaceAdmission.ACCEPTED
    }

    /**
     * 同一个摘要只留一条。
     *
     * 保留最早的一条——条目记录首次放入方。置顶标记与本地内容标记取「或」：
     * 任何一条置顶都算置顶，任何一条有本地内容都算有。
     */
    fun dedupe(entries: List<WorkspaceEntry>): List<WorkspaceEntry> {
        val merged = LinkedHashMap<String, WorkspaceEntry>()
        for (entry in entries) {
            val candidate = entry.normalized()
            if (!candidate.isUsable) continue
            val previous = merged[candidate.entryId]
            merged[candidate.entryId] = if (previous == null) {
                candidate
            } else {
                val older = if (previous.createdAtEpochSeconds <= candidate.createdAtEpochSeconds) previous else candidate
                val newer = if (older === previous) candidate else previous
                older.copy(
                    displayName = older.displayName.ifBlank { newer.displayName },
                    pinned = previous.pinned || candidate.pinned,
                    availability = if (previous.availability == WorkspaceAvailability.LOCAL ||
                        candidate.availability == WorkspaceAvailability.LOCAL
                    ) {
                        WorkspaceAvailability.LOCAL
                    } else {
                        older.availability
                    },
                )
            }
        }
        return merged.values.toList()
    }

    /**
     * 界面上的排列顺序：置顶的在前，其余从新到旧。
     *
     * 放在这里而不是各端界面里：四个平台要显示同一个顺序。
     */
    fun displayOrder(entries: List<WorkspaceEntry>): List<WorkspaceEntry> =
        dedupe(entries).sortedWith(
            compareByDescending<WorkspaceEntry> { it.pinned }.thenByDescending { it.createdAtEpochSeconds },
        )

    /**
     * 按策略整理条目，返回保留、过期与淘汰三份。
     *
     * 顺序从新到旧。[WorkspacePlan.removed] 就是需要删掉内容的那一份。
     * 置顶条目不过期，也不被淘汰，但它们占的字节仍然计入总量。
     */
    fun plan(
        entries: List<WorkspaceEntry>,
        policy: WorkspacePolicy,
        nowEpochSeconds: Long,
    ): WorkspacePlan {
        val rules = policy.normalized()
        val expired = ArrayList<WorkspaceEntry>()
        val live = ArrayList<WorkspaceEntry>()
        for (entry in dedupe(entries)) {
            val expiresAt = entry.expiresAtEpochSeconds
            if (!entry.pinned && expiresAt > 0L && expiresAt <= nowEpochSeconds) {
                expired.add(entry)
            } else {
                live.add(entry)
            }
        }

        val kept = ArrayList<WorkspaceEntry>(live.size)
        val evicted = ArrayList<WorkspaceEntry>()
        var totalBytes = 0L
        for (entry in live.sortedByDescending { it.createdAtEpochSeconds }) {
            if (entry.pinned) {
                kept.add(entry)
                totalBytes += entry.localBytes
                continue
            }
            // 单条目超过上限的，多半是策略调小之后留下的旧条目。
            if (entry.localBytes > rules.maxEntryBytes) {
                evicted.add(entry)
                continue
            }
            val nextTotal = totalBytes + entry.localBytes
            if (nextTotal > rules.maxTotalBytes) {
                evicted.add(entry)
                continue
            }
            totalBytes = nextTotal
            kept.add(entry)
        }
        return WorkspacePlan(kept = kept, expired = expired, evicted = evicted, totalBytes = totalBytes)
    }
}

/** 一次放入的判断结果。 */
enum class WorkspaceAdmission {
    ACCEPTED,

    /** 摘要已经在索引里，合并到已有条目。 */
    DUPLICATE,

    /** 摘要不合法。摘要由 Covio 自己算，正常流程走不到这里。 */
    INVALID,

    /** 超过单条目上限。 */
    TOO_LARGE,

    /** 超出工作区总上限。先拒绝新条目，不删已有条目。 */
    QUOTA_EXCEEDED,

    /** 源文件读不动，或者内容写不进磁盘。 */
    FAILED,
}

/**
 * 一次放入的结果。
 *
 * [state] 是放入之后要用的索引状态，写入失败时就是传进来的那一份。
 * [entry] 是被接受或者被合并的那条；被拒绝时为 null。
 */
data class WorkspacePutResult(
    val state: WorkspaceState,
    val entry: WorkspaceEntry?,
    val admission: WorkspaceAdmission,
) {
    val accepted: Boolean get() = admission == WorkspaceAdmission.ACCEPTED

    companion object {
        /** 空结果。Swift 侧调主构造函数要写全三个参数。 */
        fun rejected(state: WorkspaceState, admission: WorkspaceAdmission): WorkspacePutResult =
            WorkspacePutResult(state, null, admission)
    }
}

/** `stage` 的两种结局。半份文件不返回，直接删掉。 */
private sealed interface Staged {
    class Done(val entryId: String, val byteSize: Long) : Staged

    data object TooLarge : Staged
}

/**
 * 一次整理的结果。
 *
 * [kept] 是要写回索引的那一份，顺序从新到旧。
 * [expired] 与 [evicted] 的内容都要删掉，索引里也不留。
 * [totalBytes] 是 [kept] 占用本机的字节合计，可能超过上限——置顶条目不计入淘汰。
 */
data class WorkspacePlan(
    val kept: List<WorkspaceEntry>,
    val expired: List<WorkspaceEntry>,
    val evicted: List<WorkspaceEntry>,
    val totalBytes: Long,
) {
    /** 要删掉的那些。过期的排在前面。 */
    val removed: List<WorkspaceEntry> get() = expired + evicted

    val changed: Boolean get() = expired.isNotEmpty() || evicted.isNotEmpty()

    companion object {
        /** 空结果。Swift 侧调主构造函数要写全四个参数。 */
        fun empty(): WorkspacePlan = WorkspacePlan(emptyList(), emptyList(), emptyList(), 0L)
    }
}
