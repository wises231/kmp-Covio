package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import okio.FileSystem
import okio.Path
import okio.Path.Companion.toPath

/**
 * 复制引擎的接收方行为。
 *
 * 对应方案第 3.2 节与契约第 2.5 节的 `workspace.put`、`transfer.chunk`、
 * `transfer.commit`、`transfer.cancel`。
 *
 * 传输层不在这一层，所以测试直接喂字节：谁送来的都一样。
 */
class WorkspaceTransferTest {
    private fun engineIn(directory: Path): WorkspaceTransferEngine =
        WorkspaceTransferEngine.create(directory.resolve("Workspace").toString())

    private fun storeIn(directory: Path): WorkspaceStore =
        WorkspaceStore.create(directory.resolve("Workspace").toString())

    /** 一段内容的声明。字段与放入方发出去的那一份一样。 */
    private fun argsFor(
        bytes: ByteArray,
        name: String = "note.txt",
        kind: String = "text",
        contentType: String = "text/plain",
        createdAtEpochSeconds: Long = 100L,
        expiresAtEpochSeconds: Long = 0L,
    ): WorkspaceArgs = WorkspaceWire.args(
        of = WorkspaceEntry(
            entryId = WorkspaceStore.digestOf(bytes),
            kind = WorkspaceKind.TEXT,
            displayName = name,
            byteSize = bytes.size.toLong(),
            contentType = contentType,
            createdAtEpochSeconds = createdAtEpochSeconds,
            originDeviceId = "mac-1",
            expiresAtEpochSeconds = expiresAtEpochSeconds,
        ),
    ).copy(kind = kind)

    /** 把策略写进索引。引擎每次都从索引里读策略。 */
    private fun WorkspaceStore.usePolicy(policy: WorkspacePolicy): WorkspaceStore {
        save(WorkspaceState(policy = policy))
        return this
    }

    private fun policy(
        maxTotalBytes: Long = 1_000_000L,
        maxEntryBytes: Long = 1_000_000L,
        lazyFetchThresholdBytes: Long = 1_000_000L,
    ): WorkspacePolicy = WorkspacePolicy(
        maxTotalBytes = maxTotalBytes,
        maxEntryBytes = maxEntryBytes,
        retentionDays = 30,
        lazyFetchThresholdBytes = lazyFetchThresholdBytes,
    )

    // MARK: - 声明

    @Test
    fun `begin returns a task for content under the threshold`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)
            val bytes = "hello".encodeToByteArray()

            val result = engine.begin(argsFor(bytes), nowEpochSeconds = 100L)

            assertTrue(result.accepted)
            assertEquals(WorkspaceStore.digestOf(bytes), result.taskId)
            assertEquals(WorkspaceAvailability.FETCHING, result.entry?.availability)
            assertEquals(0L, result.received)
            assertEquals(listOf(WorkspaceStore.digestOf(bytes)), storeIn(directory).load().entries.map { it.entryId })
        }

    /// 高于门槛的内容只记索引，内容以后按需取。
    @Test
    fun `begin records index only over the threshold`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory).usePolicy(policy(lazyFetchThresholdBytes = 4L))
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()

            val result = engine.begin(argsFor(bytes), nowEpochSeconds = 100L)

            assertTrue(result.accepted)
            assertNull(result.taskId)
            assertEquals(WorkspaceAvailability.REMOTE, result.entry?.availability)
            assertEquals(1, store.load().entries.size)
            assertEquals(0L, store.stagingSize(WorkspaceStore.digestOf(bytes)))
        }

    /// 本机已经有这份内容时不必再传，算成功。
    @Test
    fun `begin merges an entry that already has content`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val bytes = "hello".encodeToByteArray()
            val id = store.importContent(bytes)!!
            store.save(WorkspaceState(entries = listOf(entryFor(id, bytes.size.toLong()))))
            val engine = engineIn(directory)

            val result = engine.begin(argsFor(bytes), nowEpochSeconds = 100L)

            assertTrue(result.accepted)
            assertNull(result.taskId)
            assertEquals(bytes.size.toLong(), result.received)
            assertEquals(1, store.load().entries.size, "同摘要只留一条")
        }

    /// 传了一半的条目再声明一次，把已经收到多少告诉对方。
    @Test
    fun `begin reports how much was already received`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            engine.chunk(taskId = id, offset = 0L, bytes = bytes.copyOfRange(0, 4))

            val again = engine.begin(argsFor(bytes), nowEpochSeconds = 200L)

            assertEquals(id, again.taskId)
            assertEquals(4L, again.received)
        }

    @Test
    fun `begin refuses an expired entry`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)
            val bytes = "hello".encodeToByteArray()

            val result = engine.begin(argsFor(bytes, expiresAtEpochSeconds = 50L), nowEpochSeconds = 100L)

            assertFalse(result.accepted)
            assertEquals(WorkspaceErrorCode.ENTRY_EXPIRED, result.errorCode)
            assertEquals(emptyList(), storeIn(directory).load().entries)
        }

    @Test
    fun `begin refuses content over the entry limit`() =
        withTemporaryDirectory("transfer") { directory ->
            storeIn(directory).usePolicy(policy(maxTotalBytes = 8L, maxEntryBytes = 8L))
            val engine = engineIn(directory)

            val result = engine.begin(argsFor("0123456789".encodeToByteArray()), nowEpochSeconds = 100L)

            assertEquals(WorkspaceErrorCode.QUOTA_EXCEEDED, result.errorCode)
            assertEquals(emptyList(), storeIn(directory).load().entries)
        }

    /// 已有的条目占满工作区时，新条目被拒，已有条目不动。
    @Test
    fun `begin refuses when the workspace is full`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory).usePolicy(policy(maxTotalBytes = 10L, maxEntryBytes = 10L))
            val existing = "01234567".encodeToByteArray()
            val id = store.importContent(existing)!!
            store.save(WorkspaceState(entries = listOf(entryFor(id, 8L)), policy = policy(maxTotalBytes = 10L, maxEntryBytes = 10L)))
            val engine = engineIn(directory)

            val result = engine.begin(argsFor("abcdefgh".encodeToByteArray()), nowEpochSeconds = 100L)

            assertEquals(WorkspaceErrorCode.QUOTA_EXCEEDED, result.errorCode)
            assertEquals(listOf(id), store.load().entries.map { it.entryId })
            assertTrue(store.hasContent(id))
        }

    /**
     * 传输中的条目也占配额。
     *
     * `fetching` 的条目按声明的字节数算占用，所以同时开几个传输也越不过总上限。
     * 声明的字节数本身由 `chunk` 把住，见 `chunk refuses to grow past the declared size`。
     */
    @Test
    fun `begin counts the transfers in flight against the quota`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory).usePolicy(policy(maxTotalBytes = 40L, maxEntryBytes = 40L))
            val engine = engineIn(directory)
            repeat(4) { index ->
                val bytes = ByteArray(10) { index.toByte() }
                val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
                engine.chunk(taskId = id, offset = 0L, bytes = bytes)
            }

            val fifth = engine.begin(argsFor(ByteArray(10) { 9 }), nowEpochSeconds = 100L)

            assertEquals(WorkspaceErrorCode.QUOTA_EXCEEDED, fifth.errorCode)
            assertNull(fifth.taskId)
            assertEquals(40L, store.load().entries.sumOf { it.localBytes }, "四条在传的都要算进去")
            assertEquals(40L, store.load().entries.sumOf { store.stagingSize(it.entryId) })
        }

    /// 零字节条目的空暂存文件建不出来时，连索引都不写。
    @Test
    fun `begin refuses an empty entry when the staging cannot be created`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            // 把 incoming 占成一个普通文件，建暂存文件必然失败。
            FileSystem.SYSTEM.createDirectories(directory.resolve("Workspace"))
            directory.resolve("Workspace/incoming").writeText("not a directory")

            val result = engine.begin(argsFor(ByteArray(0)), nowEpochSeconds = 100L)

            assertEquals(WorkspaceErrorCode.STORAGE_FULL, result.errorCode)
            assertFalse(result.accepted)
            assertEquals(emptyList(), store.load().entries)
        }

    @Test
    fun `begin refuses a kind that is not supported`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)

            val result = engine.begin(
                argsFor("hello".encodeToByteArray(), kind = "video"),
                nowEpochSeconds = 100L,
            )

            assertEquals(WorkspaceErrorCode.UNSUPPORTED_KIND, result.errorCode)
        }

    @Test
    fun `begin refuses a digest that is not a sha256`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)

            val result = engine.begin(
                argsFor("hello".encodeToByteArray()).copy(entryId = "../../etc/passwd"),
                nowEpochSeconds = 100L,
            )

            assertEquals(WorkspaceErrorCode.CHECKSUM_MISMATCH, result.errorCode)
            assertEquals(emptyList(), storeIn(directory).load().entries)
        }

    // MARK: - 分块

    @Test
    fun `chunk appends and reports the received length`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!

            val first = engine.chunk(taskId = id, offset = 0L, bytes = bytes.copyOfRange(0, 4))
            val second = engine.chunk(taskId = id, offset = 4L, bytes = bytes.copyOfRange(4, 10))

            assertNull(first.errorCode)
            assertEquals(4L, first.received)
            assertEquals(10L, second.received)
            assertEquals(10L, engine.resumeOffset(id))
        }

    /// 偏移对不上时不写，把已经收到多少回给对方。
    @Test
    fun `chunk reports the received length when the offset is wrong`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            engine.chunk(taskId = id, offset = 0L, bytes = bytes.copyOfRange(0, 4))

            val result = engine.chunk(taskId = id, offset = 99L, bytes = bytes.copyOfRange(4, 10))

            assertNull(result.errorCode)
            assertEquals(4L, result.received)
            assertEquals(4L, engine.resumeOffset(id), "偏移不对时不该写进去")
        }

    /// 收到的比声明的多时立刻作废，半份内容删掉：提交一定过不了校验。
    @Test
    fun `chunk refuses to grow past the declared size`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory).usePolicy(policy(maxEntryBytes = 10L))
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            engine.chunk(taskId = id, offset = 0L, bytes = bytes.copyOfRange(0, 6))

            val result = engine.chunk(taskId = id, offset = 6L, bytes = "abcdef".encodeToByteArray())

            assertEquals(WorkspaceErrorCode.CHECKSUM_MISMATCH, result.errorCode)
            assertEquals(6L, result.received, "回的是已经收到多少，不是这一块之后的长度")
            assertEquals(0L, store.stagingSize(id), "半份内容要删掉")
            assertEquals(WorkspaceAvailability.REMOTE, store.load().entries.single().availability)
        }

    /// 索引里的声明比当前上限大时（策略调小了），也按上限拒。
    @Test
    fun `chunk refuses to grow past the entry limit`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory).usePolicy(policy(maxEntryBytes = 10L))
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            // 上限调小之后索引里还留着旧声明，声明比上限大。
            val stale = store.load()
            store.save(stale.copy(entries = stale.entries.map { it.copy(byteSize = 100L) }))
            engine.chunk(taskId = id, offset = 0L, bytes = bytes.copyOfRange(0, 6))

            val result = engine.chunk(taskId = id, offset = 6L, bytes = "abcdef".encodeToByteArray())

            assertEquals(WorkspaceErrorCode.QUOTA_EXCEEDED, result.errorCode)
            assertEquals(0L, store.stagingSize(id), "半份内容要删掉")
            assertEquals(WorkspaceAvailability.REMOTE, store.load().entries.single().availability)
        }

    /// 声明是零字节的条目没有分块可收，提交时也要能过校验。
    @Test
    fun `an empty entry round trips through begin and commit`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val bytes = ByteArray(0)
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!

            val result = engine.commit(taskId = id, sha256 = id)

            assertTrue(result.ok, "${result.errorCode}")
            assertEquals(0L, store.stagingSize(id), "提交后暂存文件不留下")
            assertEquals(WorkspaceAvailability.LOCAL, store.load().entries.single().availability)
            assertTrue(store.hasContent(id), "空内容也要落进 objects")
            assertContentEquals(bytes, store.readContent(id))
        }

    /// 零字节条目收不下任何字节。
    @Test
    fun `chunk refuses bytes for an empty entry`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val id = engine.begin(argsFor(ByteArray(0)), nowEpochSeconds = 100L).taskId!!

            val result = engine.chunk(taskId = id, offset = 0L, bytes = "a".encodeToByteArray())

            assertEquals(WorkspaceErrorCode.CHECKSUM_MISMATCH, result.errorCode)
            assertEquals(0L, store.stagingSize(id))
        }

    /// 暂存文件写不进去时回 `storage_full`，条目留着，用户可以再取一次。
    @Test
    fun `chunk reports a full disk`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            // 把 incoming 占成一个普通文件，建暂存文件必然失败。
            directory.resolve("Workspace/incoming").writeText("not a directory")

            val result = engine.chunk(taskId = id, offset = 0L, bytes = bytes)

            assertEquals(WorkspaceErrorCode.STORAGE_FULL, result.errorCode)
            assertEquals(0L, result.received)
            assertEquals(WorkspaceAvailability.FETCHING, store.load().entries.single().availability)
        }

    @Test
    fun `commit reports a full disk`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            engine.chunk(taskId = id, offset = 0L, bytes = bytes)
            // 把内容路径占成一个目录，原子改名必然失败。
            FileSystem.SYSTEM.createDirectories(store.contentPath(id)!!.toPath())

            val result = engine.commit(taskId = id, sha256 = id)

            assertFalse(result.ok)
            assertEquals(WorkspaceErrorCode.STORAGE_FULL, result.errorCode)
            assertEquals(WorkspaceAvailability.REMOTE, store.load().entries.single().availability)
        }

    @Test
    fun `commit refuses a task that is not in the index`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            engine.chunk(taskId = id, offset = 0L, bytes = bytes)
            store.save(WorkspaceState())

            val result = engine.commit(taskId = id, sha256 = id)

            assertFalse(result.ok)
            assertEquals(WorkspaceErrorCode.ENTRY_NOT_FOUND, result.errorCode)
            assertEquals(0L, store.stagingSize(id), "没有条目就不必留半份内容")
        }

    @Test
    fun `chunk refuses a task that is not in the index`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)

            val result = engine.chunk(
                taskId = WorkspaceStore.digestOf("hello".encodeToByteArray()),
                offset = 0L,
                bytes = "hello".encodeToByteArray(),
            )

            assertEquals(WorkspaceErrorCode.ENTRY_NOT_FOUND, result.errorCode)
            assertEquals(0L, result.received)
        }

    // MARK: - 提交

    @Test
    fun `commit verifies the digest and stores the content`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            engine.chunk(taskId = id, offset = 0L, bytes = bytes)

            val result = engine.commit(taskId = id, sha256 = id)

            assertTrue(result.ok)
            assertNull(result.errorCode)
            assertContentEquals(bytes, store.readContent(id))
            assertEquals(WorkspaceAvailability.LOCAL, store.load().entries.single().availability)
            assertEquals(0L, store.stagingSize(id), "提交后暂存文件不留下")
        }

    @Test
    fun `commit refuses content that does not match the digest`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val declared = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(declared), nowEpochSeconds = 100L).taskId!!
            // 送来的字节与声明的不是同一份。
            engine.chunk(taskId = id, offset = 0L, bytes = "abcdefghij".encodeToByteArray())

            val result = engine.commit(taskId = id, sha256 = id)

            assertFalse(result.ok)
            assertEquals(WorkspaceErrorCode.CHECKSUM_MISMATCH, result.errorCode)
            assertFalse(store.hasContent(id))
            assertEquals(0L, store.stagingSize(id))
            assertEquals(WorkspaceAvailability.REMOTE, store.load().entries.single().availability)
        }

    @Test
    fun `commit refuses a digest that does not match the task`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            engine.chunk(taskId = id, offset = 0L, bytes = bytes)

            val result = engine.commit(taskId = id, sha256 = WorkspaceStore.digestOf("other".encodeToByteArray()))

            assertEquals(WorkspaceErrorCode.CHECKSUM_MISMATCH, result.errorCode)
        }

    /// 字节数对不上也算校验失败：声明与内容不是同一份。
    @Test
    fun `commit refuses content that is shorter than declared`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            engine.chunk(taskId = id, offset = 0L, bytes = bytes.copyOfRange(0, 4))

            val result = engine.commit(taskId = id, sha256 = id)

            assertEquals(WorkspaceErrorCode.CHECKSUM_MISMATCH, result.errorCode)
        }

    // MARK: - 取消

    @Test
    fun `cancel drops the staging and leaves the index only`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            engine.chunk(taskId = id, offset = 0L, bytes = bytes.copyOfRange(0, 4))

            assertTrue(engine.cancel(id))

            assertEquals(0L, store.stagingSize(id))
            assertEquals(WorkspaceAvailability.REMOTE, store.load().entries.single().availability)
            assertFalse(store.hasContent(id))
        }

    @Test
    fun `cancel ignores a task that is not in the index`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)

            assertFalse(engine.cancel(WorkspaceStore.digestOf("hello".encodeToByteArray())))
        }

    // MARK: - 删除

    /// 删除广播到达时删掉索引与内容，并留下标记。
    @Test
    fun `delete removes the content and leaves a tombstone`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val bytes = "hello".encodeToByteArray()
            val id = store.importContent(bytes)!!
            store.save(WorkspaceState(entries = listOf(entryFor(id, bytes.size.toLong()))))

            val result = engine.delete(id, NOW_EPOCH_SECONDS)

            assertTrue(result.ok)
            assertNull(result.errorCode)
            assertEquals(emptyList(), store.load().entries)
            assertFalse(store.hasContent(id), "删除要连内容一起删")
            assertEquals(listOf(id), store.loadTombstones().map { it.entryId })
        }

    /// 两端同时删除不报错：条目本来就不在本机也算成功，标记照写。
    @Test
    fun `delete is ok for an entry that is not here`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val id = WorkspaceStore.digestOf("gone".encodeToByteArray())

            val result = engine.delete(id, NOW_EPOCH_SECONDS)

            assertTrue(result.ok)
            assertEquals(listOf(id), store.loadTombstones().map { it.entryId })
        }

    /// 摘要不合法就拒绝：拼不出路径的标识不能进标记文件。
    @Test
    fun `delete refuses a malformed entry id`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)

            val result = engine.delete("../escape", NOW_EPOCH_SECONDS)

            assertFalse(result.ok)
            assertEquals(WorkspaceErrorCode.ENTRY_NOT_FOUND, result.errorCode)
            assertEquals(emptyList(), store.loadTombstones())
        }

    /// 标记写不进去时这次删除算失败，条目留着：对端要重试。
    @Test
    fun `delete reports a failed tombstone write`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val bytes = "hello".encodeToByteArray()
            val id = store.importContent(bytes)!!
            store.save(WorkspaceState(entries = listOf(entryFor(id, bytes.size.toLong()))))
            // 把 `.tmp` 占成目录，原子改名就写不进去。
            FileSystem.SYSTEM.createDirectories(directory.resolve("Workspace/tombstones.json.tmp"))

            val result = engine.delete(id, NOW_EPOCH_SECONDS)

            assertFalse(result.ok)
            assertEquals(WorkspaceErrorCode.STORAGE_FULL, result.errorCode)
            assertEquals(1, store.load().entries.size)
            assertTrue(store.hasContent(id), "标记没写成，内容也要留着")
        }

    /// 本机删过的条目不再收：对端晚一步的复制不该让它复活。
    @Test
    fun `begin refuses an entry deleted here`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)
            val bytes = "hello".encodeToByteArray()
            engine.delete(WorkspaceStore.digestOf(bytes), NOW_EPOCH_SECONDS)

            val result = engine.begin(argsFor(bytes), nowEpochSeconds = NOW_EPOCH_SECONDS)

            assertFalse(result.accepted)
            assertEquals(WorkspaceErrorCode.ENTRY_NOT_FOUND, result.errorCode)
        }

    /// 保留期过了的标记不再拦人：用户重新放入同样的内容是允许的。
    @Test
    fun `begin accepts an entry whose tombstone has expired`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val bytes = "hello".encodeToByteArray()
            val id = WorkspaceStore.digestOf(bytes)
            val expired = NOW_EPOCH_SECONDS - (WorkspaceLogic.TOMBSTONE_RETENTION_DAYS + 1) * SECONDS_PER_DAY
            store.saveTombstonesReporting(listOf(WorkspaceTombstone(id, expired)))

            assertTrue(engine.begin(argsFor(bytes), nowEpochSeconds = NOW_EPOCH_SECONDS).accepted)
        }

    // MARK: - 索引查询

    @Test
    fun `list returns the entries at or after the cursor`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val older = store.importContent("older".encodeToByteArray())!!
            val newer = store.importContent("newer".encodeToByteArray())!!
            store.save(
                WorkspaceState(
                    entries = listOf(
                        entryFor(older, 5L, createdAtEpochSeconds = 100L),
                        entryFor(newer, 5L, createdAtEpochSeconds = 200L),
                    ),
                ),
            )

            val all = engine.list(sinceEpochMillis = 0L, limit = 0)
            val recent = engine.list(sinceEpochMillis = 150_000L, limit = 0)

            assertEquals(listOf(newer, older), all.map { it.entryId })
            assertEquals(listOf(newer), recent.map { it.entryId })
        }

    @Test
    fun `list honours the limit`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            val ids = listOf("a", "b", "c").map { store.importContent(it.encodeToByteArray())!! }
            store.save(
                WorkspaceState(
                    entries = ids.mapIndexed { index, id ->
                        entryFor(id, 1L, createdAtEpochSeconds = 100L + index)
                    },
                ),
            )

            assertEquals(2, engine.list(sinceEpochMillis = 0L, limit = 2).size)
        }

    @Test
    fun `stat reports the usage and the limit`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory).usePolicy(policy(maxTotalBytes = 4_096L))
            val engine = engineIn(directory)
            val id = store.importContent("hello".encodeToByteArray())!!
            store.save(
                WorkspaceState(
                    entries = listOf(entryFor(id, 5L)),
                    policy = policy(maxTotalBytes = 4_096L),
                ),
            )

            val stat = engine.stat()

            assertEquals(5L, stat.totalBytes)
            assertEquals(4_096L, stat.maxTotalBytes)
            assertEquals(1, stat.entryCount)
        }

    /// 只同步索引的条目不占本机空间。
    @Test
    fun `stat does not count the entries that only have an index`() =
        withTemporaryDirectory("transfer") { directory ->
            val store = storeIn(directory)
            val engine = engineIn(directory)
            store.save(
                WorkspaceState(
                    entries = listOf(
                        entryFor(WorkspaceStore.digestOf("x".encodeToByteArray()), 5L)
                            .copy(availability = WorkspaceAvailability.REMOTE),
                    ),
                ),
            )

            assertEquals(0L, engine.stat().totalBytes)
        }

    /// 传输中的条目按声明的字节数算占用，比暂存文件大：配额因此是保守的。
    @Test
    fun `stat counts the transfers in flight`() =
        withTemporaryDirectory("transfer") { directory ->
            val engine = engineIn(directory)
            val bytes = "0123456789".encodeToByteArray()
            val id = engine.begin(argsFor(bytes), nowEpochSeconds = 100L).taskId!!
            engine.chunk(taskId = id, offset = 0L, bytes = bytes.copyOfRange(0, 4))

            assertEquals(10L, engine.stat().totalBytes)
        }

    // MARK: - 工具

    private companion object {
        /** 测试里的「现在」。删除标记按天保留，固定一个值就够了。 */
        const val NOW_EPOCH_SECONDS = 1_700_000_000L
        const val SECONDS_PER_DAY = 24L * 60 * 60
    }

    private fun entryFor(
        entryId: String,
        byteSize: Long,
        createdAtEpochSeconds: Long = 100L,
    ): WorkspaceEntry = WorkspaceEntry(
        entryId = entryId,
        kind = WorkspaceKind.TEXT,
        displayName = "note.txt",
        byteSize = byteSize,
        contentType = "text/plain",
        createdAtEpochSeconds = createdAtEpochSeconds,
        originDeviceId = "mac-1",
    )
}
