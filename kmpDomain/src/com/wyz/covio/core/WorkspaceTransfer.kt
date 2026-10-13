package com.wyz.covio.core

/**
 * 复制引擎：接收方那一半。
 *
 * 与 `docs/research/shared-transfer-workspace/solution.md` 第 3.2 节一致。
 * 收到 `workspace.put` 之后：
 *
 * 1. 看类别与摘要认不认得。
 * 2. 看条目过没过期。
 * 3. 看配额够不够。
 * 4. 低于门槛的内容立即接收，返回任务标识。
 * 5. 高于门槛的内容只记索引，状态是 `remote`。
 *
 * 分块、提交与取消对应契约第 2.5 节的 `transfer.chunk`、`transfer.commit`、`transfer.cancel`。
 *
 * **任务标识就是条目摘要。** 内容寻址让一次传输只对应一份内容，
 * 续传只要看暂存文件多大，不必另存一张任务表。
 *
 * 传输层不在这里。这一层只吃字节，谁送来的都一样。
 */
class WorkspaceTransferEngine(private val store: WorkspaceStore) {

    /**
     * 声明一条要复制过来的条目。
     *
     * 已经存在且本机有内容的条目直接算成功，不必再传。
     * 已经传了一半的条目返回已经收到的字节数，对方从那里续。
     */
    fun begin(args: WorkspaceArgs, nowEpochSeconds: Long): WorkspaceBeginResult {
        val entry = when (val parsed = WorkspaceWire.entry(args)) {
            WorkspaceEntryParse.BadKind -> return WorkspaceBeginResult.rejected(WorkspaceErrorCode.UNSUPPORTED_KIND)
            WorkspaceEntryParse.BadDigest -> return WorkspaceBeginResult.rejected(WorkspaceErrorCode.CHECKSUM_MISMATCH)
            is WorkspaceEntryParse.Ok -> parsed.entry.normalized()
        }

        val state = store.load()
        val policy = state.policy.normalized()
        if (entry.expiresAtEpochSeconds > 0L && entry.expiresAtEpochSeconds <= nowEpochSeconds) {
            return WorkspaceBeginResult.rejected(WorkspaceErrorCode.ENTRY_EXPIRED)
        }
        // 本机删过的条目不再收：删除是全局操作，对端晚一步的复制不该让它复活。
        if (WorkspaceLogic.isTombstoned(entry.entryId, store.loadTombstones(), nowEpochSeconds)) {
            return WorkspaceBeginResult.rejected(WorkspaceErrorCode.ENTRY_NOT_FOUND)
        }

        val existing = state.entries.firstOrNull { it.entryId == entry.entryId }
        if (existing != null && store.hasContent(entry.entryId)) {
            // 内容已经在本地，合并到已有条目。同摘要只留一条。
            return WorkspaceBeginResult(
                accepted = true,
                taskId = null,
                entry = existing,
                errorCode = null,
                received = existing.byteSize,
            )
        }

        if (entry.byteSize > policy.maxEntryBytes) {
            return WorkspaceBeginResult.rejected(WorkspaceErrorCode.QUOTA_EXCEEDED)
        }
        // 这一条要占的空间不含自己：重传时旧的索引条目会被替换掉。
        // `fetching` 的条目按声明的字节数算占用，所以同时开几个传输也越不过总上限。
        val used = state.entries.filterNot { it.entryId == entry.entryId }.sumOf { it.localBytes }
        if (used + entry.byteSize > policy.maxTotalBytes) {
            return WorkspaceBeginResult.rejected(WorkspaceErrorCode.QUOTA_EXCEEDED)
        }

        val replaced = state.entries.filterNot { it.entryId == entry.entryId }
        if (entry.byteSize > policy.lazyFetchThresholdBytes) {
            // 大内容只记索引。用户打开时再发 `workspace.fetch`。
            val indexOnly = entry.copy(availability = WorkspaceAvailability.REMOTE)
            store.save(state.copy(entries = replaced + indexOnly))
            return WorkspaceBeginResult(true, null, indexOnly, null, 0L)
        }

        // 零字节的条目没有分块可收。先把空文件建出来，提交时才有东西可校验、可改名。
        // 建不出来就不声明，否则索引里会留下一条永远提交不了的条目。
        if (entry.byteSize == 0L && store.appendStaging(entry.entryId, ByteArray(0)) == null) {
            return WorkspaceBeginResult.rejected(WorkspaceErrorCode.STORAGE_FULL)
        }

        val fetching = entry.copy(availability = WorkspaceAvailability.FETCHING)
        store.save(state.copy(entries = replaced + fetching))
        return WorkspaceBeginResult(
            accepted = true,
            taskId = entry.entryId,
            entry = fetching,
            errorCode = null,
            received = store.stagingSize(entry.entryId),
        )
    }

    /**
     * 收下一块内容。
     *
     * 偏移对不上时不写，只把已经收到多少回给对方——对方从这里续传。
     * 收到的字节超过条目声明的字节数时任务作废：声明数与内容对不上，提交必然失败。
     * 超过单条目上限时任务也作废，半份内容删掉。
     */
    fun chunk(taskId: String, offset: Long, bytes: ByteArray): WorkspaceChunkResult {
        val id = normalizeEntryId(taskId)
        val state = store.load()
        val entry = state.entries.firstOrNull { it.entryId == id }
        if (entry == null || entry.availability != WorkspaceAvailability.FETCHING) {
            return WorkspaceChunkResult(0L, WorkspaceErrorCode.ENTRY_NOT_FOUND)
        }

        val received = store.stagingSize(id)
        if (offset != received) return WorkspaceChunkResult(received, null)

        if (received + bytes.size > entry.byteSize) {
            cancel(id)
            return WorkspaceChunkResult(received, WorkspaceErrorCode.CHECKSUM_MISMATCH)
        }

        if (received + bytes.size > state.policy.normalized().maxEntryBytes) {
            cancel(id)
            return WorkspaceChunkResult(received, WorkspaceErrorCode.QUOTA_EXCEEDED)
        }

        val next = store.appendStaging(id, bytes)
            ?: return WorkspaceChunkResult(received, WorkspaceErrorCode.STORAGE_FULL)
        return WorkspaceChunkResult(next, null)
    }

    /**
     * 提交一次传输。
     *
     * 摘要与字节数都对得上才落进 `objects`，否则删掉半份内容并回 `checksum_mismatch`。
     * 失败时索引条目留在原处，状态改成 `remote`：用户以后还能再取一次。
     */
    fun commit(taskId: String, sha256: String): WorkspaceCommitResult {
        val id = normalizeEntryId(taskId)
        val state = store.load()
        val entry = state.entries.firstOrNull { it.entryId == id }
        if (entry == null) {
            store.deleteStaging(id)
            return WorkspaceCommitResult(false, WorkspaceErrorCode.ENTRY_NOT_FOUND)
        }

        val digest = store.digestOfStaging(id)
        val declared = normalizeEntryId(sha256)
        val complete = digest == id && declared == id && store.stagingSize(id) == entry.byteSize
        if (!complete) {
            cancel(id)
            return WorkspaceCommitResult(false, WorkspaceErrorCode.CHECKSUM_MISMATCH)
        }

        if (!store.commitStaging(id, id)) {
            cancel(id)
            return WorkspaceCommitResult(false, WorkspaceErrorCode.STORAGE_FULL)
        }

        val entries = state.entries.map {
            if (it.entryId == id) it.copy(availability = WorkspaceAvailability.LOCAL) else it
        }
        store.save(state.copy(entries = entries))
        return WorkspaceCommitResult(true, null)
    }

    /**
     * 取消一次传输。
     *
     * 半份内容删掉，索引条目留着但改成 `remote`：用户以后还能再取。
     */
    fun cancel(taskId: String): Boolean {
        val id = normalizeEntryId(taskId)
        store.deleteStaging(id)
        val state = store.load()
        if (state.entries.none { it.entryId == id }) return false
        val entries = state.entries.map {
            if (it.entryId == id) it.copy(availability = WorkspaceAvailability.REMOTE) else it
        }
        store.save(state.copy(entries = entries))
        return true
    }

    /**
     * 收到一次 `workspace.delete`。
     *
     * 本机删掉索引与内容，并留下删除标记。删除标记拦住对端的重新复制，
     * 所以它写不进去时这次删除算失败：条目还在，对端要重试。
     *
     * 条目本来就不在本机时也算成功——两端同时删除不报错（方案第 8 节）。
     */
    fun delete(entryId: String, nowEpochSeconds: Long): WorkspaceDeleteResult {
        val id = normalizeEntryId(entryId)
        if (!WorkspaceLogic.isValidEntryId(id)) {
            return WorkspaceDeleteResult(false, WorkspaceErrorCode.ENTRY_NOT_FOUND)
        }
        store.remove(store.load(), id, nowEpochSeconds)
        return if (store.loadTombstones().any { it.entryId == id }) {
            WorkspaceDeleteResult(true, null)
        } else {
            WorkspaceDeleteResult(false, WorkspaceErrorCode.STORAGE_FULL)
        }
    }

    /** 已经收到的字节数。对方续传前先问这里。 */
    fun resumeOffset(taskId: String): Long = store.stagingSize(normalizeEntryId(taskId))

    // MARK: - 索引查询

    /**
     * 索引增量。`since` 是毫秒，返回这一秒之后放入的条目。
     *
     * 顺序从新到旧。`limit` 小于等于 0 时不限条数。
     *
     * 秒是索引里的最小刻度，所以边界上的条目可能重复返回。
     * 重复无害——同摘要合并成一条；漏掉一条则会永远对不齐。
     */
    fun list(sinceEpochMillis: Long, limit: Int): List<WorkspaceEntry> {
        val sinceEpochSeconds = sinceEpochMillis.coerceAtLeast(0L) / 1_000L
        val entries = store.load().entries
            .filter { it.createdAtEpochSeconds >= sinceEpochSeconds }
            .sortedByDescending { it.createdAtEpochSeconds }
        return if (limit > 0) entries.take(limit) else entries
    }

    /** 对端工作区的状态。占用、上限、条目数。 */
    fun stat(): WorkspaceStat {
        val state = store.load()
        return WorkspaceStat(
            // 传输中的条目按声明的字节数算：比暂存文件大，配额才是保守的。
            totalBytes = state.entries.sumOf { it.localBytes },
            maxTotalBytes = state.policy.normalized().maxTotalBytes,
            entryCount = state.entries.size,
        )
    }

    companion object {
        /**
         * 按目录构造。
         *
         * 理由同 [WorkspaceStore.create]：默认参数不导出到 Swift，
         * 从 Swift 拼一个 `FileSystem` 会让两版写出的文件不同。
         */
        fun create(directory: String): WorkspaceTransferEngine =
            WorkspaceTransferEngine(WorkspaceStore.create(directory))
    }
}

/**
 * 一次 `workspace.put` 的结果。
 *
 * [taskId] 为空表示不必传内容：要么本机已经有了，要么这条只同步索引。
 * [received] 是已经收到的字节数，对方续传时从它接着写。
 */
data class WorkspaceBeginResult(
    val accepted: Boolean,
    val taskId: String?,
    val entry: WorkspaceEntry?,
    val errorCode: WorkspaceErrorCode?,
    val received: Long,
) {
    companion object {
        /** 被拒绝的结果。 */
        fun rejected(errorCode: WorkspaceErrorCode): WorkspaceBeginResult =
            WorkspaceBeginResult(false, null, null, errorCode, 0L)
    }
}

/** 一次 `transfer.chunk` 的结果。[errorCode] 为空表示这一块收下了。 */
data class WorkspaceChunkResult(val received: Long, val errorCode: WorkspaceErrorCode?)

/** 一次 `transfer.commit` 的结果。 */
data class WorkspaceCommitResult(val ok: Boolean, val errorCode: WorkspaceErrorCode?)

/** 一次 `workspace.delete` 的结果。[ok] 为假时 [errorCode] 说明原因。 */
data class WorkspaceDeleteResult(val ok: Boolean, val errorCode: WorkspaceErrorCode?)

/** `workspace.stat` 的结果。 */
data class WorkspaceStat(val totalBytes: Long, val maxTotalBytes: Long, val entryCount: Int)
