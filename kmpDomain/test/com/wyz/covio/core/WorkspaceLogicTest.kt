package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * 工作区的纯逻辑测试。
 *
 * 覆盖方案第 10.1 节要的两块：淘汰顺序与过期边界。
 * 不碰磁盘，那两个平台的测试跑的是同一份代码。
 */
class WorkspaceLogicTest {
    private fun entryId(seed: String): String = WorkspaceStore.digestOf(seed.encodeToByteArray())

    private fun entry(
        seed: String,
        bytes: Long = 0L,
        createdAt: Long = 0L,
        expiresAt: Long = 0L,
        pinned: Boolean = false,
        availability: WorkspaceAvailability = WorkspaceAvailability.LOCAL,
    ): WorkspaceEntry = WorkspaceEntry(
        entryId = entryId(seed),
        byteSize = bytes,
        createdAtEpochSeconds = createdAt,
        expiresAtEpochSeconds = expiresAt,
        pinned = pinned,
        availability = availability,
    )

    @Test
    fun `classification prefers the content type over the extension`() {
        assertEquals(WorkspaceKind.PDF, WorkspaceLogic.classify("photo.png", "application/pdf"))
        assertEquals(WorkspaceKind.IMAGE, WorkspaceLogic.classify("no-extension", "image/heic"))
        assertEquals(WorkspaceKind.TEXT, WorkspaceLogic.classify("", "text/plain"))
    }

    @Test
    fun `classification falls back to the extension`() {
        assertEquals(WorkspaceKind.IMAGE, WorkspaceLogic.classify("shot.PNG", ""))
        assertEquals(WorkspaceKind.AUDIO, WorkspaceLogic.classify("voice.m4a", ""))
        assertEquals(WorkspaceKind.PDF, WorkspaceLogic.classify("合同.pdf", ""))
        assertEquals(WorkspaceKind.TEXT, WorkspaceLogic.classify("notes.md", ""))
        assertEquals(WorkspaceKind.FILE, WorkspaceLogic.classify("archive.zip", ""))
        assertEquals(WorkspaceKind.FILE, WorkspaceLogic.classify("README", ""))
    }

    /// 保留期为 0 表示不过期，与剪切板的 `maxAgeDays` 同一套约定。
    @Test
    fun `expiry counts days from the creation time and zero means never`() {
        val sevenDays = 7L * 24 * 60 * 60
        assertEquals(1000L + sevenDays, WorkspaceLogic.expiryEpochSeconds(1000L, WorkspacePolicy(retentionDays = 7)))
        assertEquals(0L, WorkspaceLogic.expiryEpochSeconds(1000L, WorkspacePolicy(retentionDays = 0)))
        assertEquals(sevenDays, WorkspaceLogic.expiryEpochSeconds(-5L, WorkspacePolicy(retentionDays = 7)))
    }

    @Test
    fun `a digest must be sixty four hex characters`() {
        assertTrue(WorkspaceLogic.isValidEntryId(entryId("x")))
        assertTrue(WorkspaceLogic.isValidEntryId("  ${entryId("x").uppercase()}  "))
        assertTrue(!WorkspaceLogic.isValidEntryId(""))
        assertTrue(!WorkspaceLogic.isValidEntryId("abc"))
        assertTrue(!WorkspaceLogic.isValidEntryId(entryId("x").dropLast(1) + "z"))
        assertTrue(!WorkspaceLogic.isValidEntryId("../../etc/passwd"))
    }

    /// 摘要不合法的条目在 `dedupe` 就出局，`isUsable` 与它同一个判断。
    @Test
    fun `malformed entries are dropped`() {
        val bad = WorkspaceEntry(entryId = "not-a-digest", byteSize = 10L)

        assertEquals(emptyList(), WorkspaceLogic.dedupe(listOf(bad)))
        assertEquals(emptyList(), WorkspaceLogic.plan(listOf(bad), WorkspacePolicy(), 0L).kept)
        assertTrue(!bad.isUsable)
    }

    /// 同一个摘要留最早的一条，条目记录首次放入方。
    @Test
    fun `duplicate digests merge into the earliest entry`() {
        val merged = WorkspaceLogic.dedupe(
            listOf(
                entry("same", createdAt = 30L, pinned = true),
                entry("same", createdAt = 10L),
            ),
        )

        assertEquals(1, merged.size)
        assertEquals(10L, merged.single().createdAtEpochSeconds)
        assertTrue(merged.single().pinned, "任意一条置顶就算置顶")
    }

    @Test
    fun `admission rejects bad digests oversized entries and a full workspace`() {
        val policy = WorkspacePolicy(maxTotalBytes = 1000L, maxEntryBytes = 100L)

        assertEquals(WorkspaceAdmission.ACCEPTED, WorkspaceLogic.admit(entry("a", bytes = 100L), emptyList(), policy))
        assertEquals(
            WorkspaceAdmission.INVALID,
            WorkspaceLogic.admit(WorkspaceEntry(entryId = "nope", byteSize = 1L), emptyList(), policy),
        )
        assertEquals(WorkspaceAdmission.TOO_LARGE, WorkspaceLogic.admit(entry("b", bytes = 101L), emptyList(), policy))
        assertEquals(
            WorkspaceAdmission.QUOTA_EXCEEDED,
            WorkspaceLogic.admit(entry("c", bytes = 100L), listOf(entry("a", bytes = 950L)), policy),
        )
        assertEquals(
            WorkspaceAdmission.DUPLICATE,
            WorkspaceLogic.admit(entry("a", bytes = 10L), listOf(entry("a", bytes = 10L)), policy),
        )
    }

    /// 空间不足时先拒绝新条目，不删已有条目。
    @Test
    fun `a full workspace does not evict anything on admission`() {
        val existing = listOf(entry("a", bytes = 1000L))

        val verdict = WorkspaceLogic.admit(
            entry("b", bytes = 10L),
            existing,
            WorkspacePolicy(maxTotalBytes = 1000L, maxEntryBytes = 1000L),
        )

        assertEquals(WorkspaceAdmission.QUOTA_EXCEEDED, verdict)
        assertEquals(1, existing.size)
    }

    /// 淘汰顺序：先过期的，再未置顶且最旧的。保留的顺序从新到旧。
    @Test
    fun `plan evicts the oldest unpinned entries first`() {
        val newest = entry("newest", bytes = 200L, createdAt = 30L)
        val middle = entry("middle", bytes = 200L, createdAt = 20L)
        val oldest = entry("oldest", bytes = 200L, createdAt = 10L)

        val plan = WorkspaceLogic.plan(
            listOf(oldest, newest, middle),
            WorkspacePolicy(maxTotalBytes = 500L, maxEntryBytes = 500L),
            nowEpochSeconds = 100L,
        )

        assertEquals(listOf(newest.entryId, middle.entryId), plan.kept.map(WorkspaceEntry::entryId))
        assertEquals(listOf(oldest.entryId), plan.evicted.map(WorkspaceEntry::entryId))
        assertEquals(400L, plan.totalBytes)
        assertTrue(plan.changed)
    }

    /// 过期判定含边界：到期那一刻就算过期。置顶的不过期。
    @Test
    fun `an entry expires at the boundary and pinned ones do not`() {
        val expiresAt = 1000L
        val entries = listOf(
            entry("due", bytes = 1L, expiresAt = expiresAt),
            entry("pin", bytes = 1L, expiresAt = expiresAt, pinned = true),
            entry("soon", bytes = 1L, expiresAt = expiresAt + 1L),
        )
        val policy = WorkspacePolicy(maxTotalBytes = 100L, maxEntryBytes = 100L)

        val atBoundary = WorkspaceLogic.plan(entries, policy, nowEpochSeconds = expiresAt)
        assertEquals(listOf(entryId("due")), atBoundary.expired.map(WorkspaceEntry::entryId))
        assertEquals(
            listOf(entryId("pin"), entryId("soon")),
            atBoundary.kept.map(WorkspaceEntry::entryId),
        )

        val justBefore = WorkspaceLogic.plan(entries, policy, nowEpochSeconds = expiresAt - 1L)
        assertEquals(emptyList(), justBefore.expired)
        assertTrue(!justBefore.changed)
    }

    /// 置顶既不淘汰也不过期，但它占的字节照算。
    @Test
    fun `plan never evicts a pinned entry`() {
        val fresh = entry("fresh", bytes = 100L, createdAt = 30L)
        val stale = entry("stale", bytes = 100L, createdAt = 25L)
        val pinned = entry("pinned", bytes = 100L, createdAt = 20L, pinned = true)

        val plan = WorkspaceLogic.plan(
            listOf(fresh, stale, pinned),
            WorkspacePolicy(maxTotalBytes = 100L, maxEntryBytes = 100L),
            nowEpochSeconds = 100L,
        )

        assertEquals(listOf(fresh.entryId, pinned.entryId), plan.kept.map(WorkspaceEntry::entryId))
        assertEquals(listOf(stale.entryId), plan.evicted.map(WorkspaceEntry::entryId))
        assertEquals(200L, plan.totalBytes, "置顶条目的字节仍然计入总量")
    }

    /// 单条目超过上限的，多半是策略调小之后留下的旧条目。
    @Test
    fun `plan evicts a single entry that is over the per entry limit`() {
        val big = entry("big", bytes = 200L, createdAt = 5L)
        val small = entry("small", bytes = 50L, createdAt = 4L)

        val plan = WorkspaceLogic.plan(
            listOf(big, small),
            WorkspacePolicy(maxTotalBytes = 1000L, maxEntryBytes = 100L),
            nowEpochSeconds = 100L,
        )

        assertEquals(listOf(small.entryId), plan.kept.map(WorkspaceEntry::entryId))
        assertEquals(listOf(big.entryId), plan.evicted.map(WorkspaceEntry::entryId))
    }

    /// 界面顺序：置顶的在前，其余从新到旧。
    @Test
    fun `display order puts pinned entries first`() {
        val oldest = entry("oldest", createdAt = 10L)
        val newest = entry("newest", createdAt = 30L)
        val pinned = entry("pinned", createdAt = 20L, pinned = true)

        val order = WorkspaceLogic.displayOrder(listOf(oldest, newest, pinned))

        assertEquals(listOf(pinned.entryId, newest.entryId, oldest.entryId), order.map(WorkspaceEntry::entryId))
    }

    /// 只同步了索引的条目不占本机空间，不该把本机内容挤掉。
    @Test
    fun `plan counts only local bytes against the quota`() {
        val remote = entry("remote", bytes = 5_000L, createdAt = 2L, availability = WorkspaceAvailability.REMOTE)
        val evicted = entry("evicted", bytes = 5_000L, createdAt = 3L, availability = WorkspaceAvailability.EVICTED)
        val local = entry("local", bytes = 80L, createdAt = 1L)

        val plan = WorkspaceLogic.plan(
            listOf(remote, evicted, local),
            WorkspacePolicy(maxTotalBytes = 100L, maxEntryBytes = 100L),
            nowEpochSeconds = 100L,
        )

        assertEquals(3, plan.kept.size)
        assertEquals(80L, plan.totalBytes)
    }

    /// 文字名取第一行，去掉路径分隔符与控制字符。
    @Test
    fun `suggested text name takes the first line and drops forbidden characters`() {
        assertEquals("hello.txt", WorkspaceLogic.suggestedTextName("hello"))
        assertEquals("first.txt", WorkspaceLogic.suggestedTextName("\n\n  first  \nsecond"))
        assertEquals("a b.txt", WorkspaceLogic.suggestedTextName("a   b"))
    }

    /// 名字不能带路径分隔符，否则拼路径时会被当成目录。
    @Test
    fun `suggested text name drops separators and control characters`() {
        assertEquals("etc passwd.txt", WorkspaceLogic.suggestedTextName("/etc/passwd"))
        assertEquals("C Users w.txt", WorkspaceLogic.suggestedTextName("C:\\Users\\w"))
        assertEquals("ab.txt", WorkspaceLogic.suggestedTextName("a\u0000b"))
        assertEquals("hello.txt", WorkspaceLogic.suggestedTextName("hello."))
    }

    /// 名字有长度上限，正文取不出名字时用固定的那一个。
    @Test
    fun `suggested text name is capped and has a fallback`() {
        assertEquals("clipboard.txt", WorkspaceLogic.suggestedTextName("   \n\t "))
        assertEquals("clipboard.txt", WorkspaceLogic.suggestedTextName(""))
        assertEquals("clipboard.txt", WorkspaceLogic.suggestedTextName("///"))
        assertEquals(44, WorkspaceLogic.suggestedTextName("x".repeat(200)).length)
    }
}
