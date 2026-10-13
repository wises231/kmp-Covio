package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * 线格式。
 *
 * 字段名与写法按 `docs/research/shared-transfer-workspace/solution.md` 第 2 节核对。
 * 契约是两端共用的，改字段名会让新旧版本对不上，所以这里逐字断言。
 */
class WorkspaceWireTest {

    @Test
    fun `a put request uses the contract field names`() {
        val entry = WorkspaceEntry(
            entryId = "a".repeat(64),
            kind = WorkspaceKind.PDF,
            displayName = "合同.pdf",
            byteSize = 2_048L,
            contentType = "application/pdf",
            createdAtEpochSeconds = 1_760_000_000L,
            originDeviceId = "mac-1",
            expiresAtEpochSeconds = 1_762_592_000L,
        )

        val text = WorkspaceWire.encode(
            WorkspaceRequest(
                requestId = "req-0001",
                op = WorkspaceWire.OP_PUT,
                args = WorkspaceWire.args(of = entry),
            ),
        )

        assertTrue(text.contains("\"request_id\":\"req-0001\""), text)
        assertTrue(text.contains("\"op\":\"workspace.put\""), text)
        assertTrue(text.contains("\"entry_id\":\"${"a".repeat(64)}\""), text)
        assertTrue(text.contains("\"kind\":\"pdf\""), text)
        assertTrue(text.contains("\"display_name\":\"合同.pdf\""), text)
        assertTrue(text.contains("\"byte_size\":2048"), text)
        assertTrue(text.contains("\"content_type\":\"application/pdf\""), text)
        // 契约第 2.2 节写的是 UTC 毫秒，本地索引用秒。
        assertTrue(text.contains("\"created_at\":1760000000000"), text)
        assertTrue(text.contains("\"expires_at\":1762592000000"), text)
        assertTrue(text.contains("\"origin_device_id\":\"mac-1\""), text)
    }

    /// 用不到的字段不写到线上去。
    @Test
    fun `a request without arguments carries none`() {
        val text = WorkspaceWire.encode(WorkspaceRequest(requestId = "req-0002", op = WorkspaceWire.OP_STAT))

        assertEquals("""{"request_id":"req-0002","op":"workspace.stat"}""", text)
    }

    /// 删除请求只带条目摘要。契约第 2.5 节的参数只有 `entry_id`。
    @Test
    fun `a delete request carries the entry id`() {
        val text = WorkspaceWire.encode(
            WorkspaceRequest(
                requestId = "req-0004",
                op = WorkspaceWire.OP_DELETE,
                args = WorkspaceArgs(entryId = "c".repeat(64)),
            ),
        )

        assertEquals(
            """{"request_id":"req-0004","op":"workspace.delete","args":{"entry_id":"${"c".repeat(64)}"}}""",
            text,
        )
    }

    @Test
    fun `a request round trips`() {
        val request = WorkspaceRequest(
            requestId = "req-0003",
            op = WorkspaceWire.OP_CHUNK,
            args = WorkspaceArgs(taskId = "b".repeat(64), offset = 4_096L, length = 8_192L),
        )

        val decoded = WorkspaceWire.decodeRequest(WorkspaceWire.encode(request))

        assertEquals(request, decoded)
    }

    @Test
    fun `a response uses the contract field names`() {
        val text = WorkspaceWire.encode(
            WorkspaceWire.ok(WorkspaceResponseData(accepted = true, taskId = "task-0001")),
        )

        assertTrue(text.contains("\"ok\":true"), text)
        assertTrue(text.contains("\"accepted\":true"), text)
        assertTrue(text.contains("\"task_id\":\"task-0001\""), text)
        assertFalse(text.contains("error_code"), text)
    }

    @Test
    fun `a failure carries the wire error code`() {
        val text = WorkspaceWire.encode(WorkspaceWire.failed(WorkspaceErrorCode.QUOTA_EXCEEDED, "空间不足"))

        assertTrue(text.contains("\"ok\":false"), text)
        assertTrue(text.contains("\"error_code\":\"quota_exceeded\""), text)
        assertTrue(text.contains("\"error_message\":\"空间不足\""), text)
    }

    /// 收到零字节也要写出去，不能被当成默认值省掉。
    @Test
    fun `a received count of zero is written`() {
        val text = WorkspaceWire.encode(WorkspaceWire.ok(WorkspaceResponseData(received = 0L)))

        assertTrue(text.contains("\"received\":0"), text)
    }

    @Test
    fun `a response round trips`() {
        val response = WorkspaceWire.failed(WorkspaceErrorCode.CHECKSUM_MISMATCH)

        assertEquals(response, WorkspaceWire.decodeResponse(WorkspaceWire.encode(response)))
    }

    @Test
    fun `broken json decodes to nothing`() {
        assertNull(WorkspaceWire.decodeRequest("{ not json"))
        assertNull(WorkspaceWire.decodeResponse(""))
    }

    // MARK: - 条目与线格式互转

    @Test
    fun `an entry converts to wire fields and back`() {
        val entry = WorkspaceEntry(
            entryId = "c".repeat(64),
            kind = WorkspaceKind.IMAGE,
            displayName = "shot.png",
            byteSize = 512L,
            contentType = "image/png",
            createdAtEpochSeconds = 1_760_000_000L,
            originDeviceId = "mac-2",
            expiresAtEpochSeconds = 1_762_592_000L,
        )

        val parsed = WorkspaceWire.entry(from = WorkspaceWire.args(of = entry))

        assertTrue(parsed is WorkspaceEntryParse.Ok)
        assertEquals(entry, (parsed as WorkspaceEntryParse.Ok).entry)
    }

    /// 毫秒到秒的换算只在这一处。0 表示不过期，换算后还是 0。
    @Test
    fun `wire milliseconds become index seconds`() {
        val args = WorkspaceArgs(
            entryId = "d".repeat(64),
            kind = "text",
            byteSize = 1L,
            createdAtEpochMillis = 1_760_000_999_000L,
            expiresAtEpochMillis = 0L,
        )

        val entry = (WorkspaceWire.entry(from = args) as WorkspaceEntryParse.Ok).entry

        assertEquals(1_760_000_999L, entry.createdAtEpochSeconds)
        assertEquals(0L, entry.expiresAtEpochSeconds)
    }

    /// 发送方说的内容状态不算数，接收方按自己的情况定。
    @Test
    fun `the announced availability is ignored`() {
        val args = WorkspaceArgs(
            entryId = "e".repeat(64),
            kind = "file",
            byteSize = 1L,
            availability = "remote",
        )

        val entry = (WorkspaceWire.entry(from = args) as WorkspaceEntryParse.Ok).entry

        assertEquals(WorkspaceAvailability.LOCAL, entry.availability)
    }

    @Test
    fun `an entry without a digest is refused`() {
        assertTrue(WorkspaceWire.entry(from = WorkspaceArgs(kind = "file")) is WorkspaceEntryParse.BadDigest)
    }

    @Test
    fun `an entry with an unknown kind is refused`() {
        val args = WorkspaceArgs(entryId = "f".repeat(64), kind = "video", byteSize = 1L)

        assertTrue(WorkspaceWire.entry(from = args) is WorkspaceEntryParse.BadKind)
    }

    @Test
    fun `every error code has a wire spelling`() {
        assertEquals("quota_exceeded", WorkspaceErrorCode.QUOTA_EXCEEDED.wire)
        assertEquals("local_network_denied", WorkspaceErrorCode.LOCAL_NETWORK_DENIED.wire)
        assertEquals(WorkspaceErrorCode.CHECKSUM_MISMATCH, WorkspaceErrorCode.fromWire("checksum_mismatch"))
        assertEquals(WorkspaceErrorCode.STORAGE_FULL, WorkspaceErrorCode.fromWire(" STORAGE_FULL "))
        assertNull(WorkspaceErrorCode.fromWire("not_a_code"))
        assertNotNull(WorkspaceErrorCode.entries.firstOrNull { it == WorkspaceErrorCode.ENTRY_EXPIRED })
    }
}
