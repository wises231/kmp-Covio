package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PmsetWakeLogParserTest {
    /**
     * 期望值独立算出，不是用被测代码算的。
     * 生成方式：`datetime.strptime(value, '%Y-%m-%d %H:%M:%S %z').timestamp()`。
     */
    private fun epoch(value: String): Long = when (value) {
        "2026-10-08 14:00:00 +0800" -> 1_791_439_200L
        "2026-10-09 00:00:00 +0800" -> 1_791_475_200L
        else -> error("未登记的期望值：$value")
    }

    @Test
    fun `classifies dark wake and full wake events with reasons`() {
        val snapshot = PmsetWakeLogParser.parse(
            """
            2026-10-08 11:18:14 +0800 DarkWake DarkWake from Deep Idle [CDNP] : due to NUB.SPMISw3IRQ Using BATT (Charge:80%) 2 secs
            2026-10-08 12:20:00 +0800 Wake Wake from Deep Idle [CDNVA] : due to USB-C_plug Using AC (Charge:80%)
            2026-10-08 13:34:53 +0800 Wake DarkWake to FullWake from Deep Idle [CDNVA] : due to UserActivity Assertion Using AC (Charge:80%) 141 secs
            """.trimIndent(),
            epoch("2026-10-08 14:00:00 +0800"),
        )

        assertEquals(3, snapshot.events.size)
        assertEquals(WakeKind.DARK, snapshot.events[0].kind)
        assertEquals("NUB.SPMISw3IRQ", snapshot.events[0].reason)
        assertEquals(WakeKind.FULL, snapshot.events[1].kind)
        assertEquals("USB-C_plug", snapshot.events[1].reason)
        assertEquals(WakeKind.FULL, snapshot.events[2].kind)
        assertEquals("UserActivity Assertion", snapshot.events[2].reason)
        assertEquals(1, snapshot.darkWakeCount24h)
    }

    @Test
    fun `parses real pmset log lines`() {
        val snapshot = PmsetWakeLogParser.parse(
            """2026-10-08 11:01:01 +0800 DarkWake            	DarkWake from Deep Idle [CDNP] : due to NUB.SPMISw3IRQ nub-spmi0.0x02 rtc/Maintenance Using BATT (Charge:80%) 6 secs
2026-10-08 13:34:53 +0800 Wake                	Wake from Deep Idle [CDNVA] : due to smc.sysState.Wake(0x70070000) USB-C_plug SMC.OutboxNotEmpty/Notification Using AC (Charge:80%)""",
            epoch("2026-10-08 14:00:00 +0800"),
        )

        assertEquals(2, snapshot.events.size)
        assertEquals(WakeKind.DARK, snapshot.events[0].kind)
        assertEquals("NUB.SPMISw3IRQ nub-spmi0.0x02 rtc/Maintenance", snapshot.events[0].reason)
        assertEquals(WakeKind.FULL, snapshot.events[1].kind)
        assertEquals(
            "smc.sysState.Wake(0x70070000) USB-C_plug SMC.OutboxNotEmpty/Notification",
            snapshot.events[1].reason,
        )
        assertEquals(1, snapshot.darkWakeCount24h)
    }

    @Test
    fun `keeps events inside twenty four hour boundary`() {
        val now = epoch("2026-10-09 00:00:00 +0800")
        val snapshot = PmsetWakeLogParser.parse(
            """
            2026-10-07 23:59:59 +0800 DarkWake DarkWake from Deep Idle : due to Old
            2026-10-08 00:00:00 +0800 DarkWake DarkWake from Deep Idle : due to Boundary
            """.trimIndent(),
            now,
        )

        assertEquals(1, snapshot.events.size)
        assertEquals("Boundary", snapshot.events.single().reason)
        assertEquals(1, snapshot.darkWakeCount24h)
    }

    @Test
    fun `ignores malformed and unknown lines`() {
        val snapshot = PmsetWakeLogParser.parse(
            """
            not a timestamp
            2026-10-08 13:00:00 +0800 Sleep Sleep from Idle : due to Idle
            2026-10-08 13:01:00 +0800 Wake Wake from Deep Idle : due to User
            """.trimIndent(),
            epoch("2026-10-08 14:00:00 +0800"),
        )

        assertEquals(1, snapshot.events.size)
        assertEquals(WakeKind.FULL, snapshot.events.single().kind)
    }

    @Test
    fun `returns an empty snapshot for garbled input`() {
        val snapshot = PmsetWakeLogParser.parse("�\nnoise\n", epoch("2026-10-08 14:00:00 +0800"))
        assertTrue(snapshot.events.isEmpty())
        assertEquals(0, snapshot.darkWakeCount24h)
    }

    // MARK: - 时间戳转换

    /// 转换结果必须与 java.time 一致。这里钉住几个关键值。
    @Test
    fun `timestamp conversion matches the reference values`() {
        assertEquals(1_791_439_200L, PmsetWakeLogParser.parseTimestamp("2026-10-08 14:00:00 +0800"))
        assertEquals(0L, PmsetWakeLogParser.parseTimestamp("1970-01-01 00:00:00 +0000"))
        assertEquals(1_709_226_000L, PmsetWakeLogParser.parseTimestamp("2024-02-29 12:00:00 -0500"))
        assertEquals(951_868_800L, PmsetWakeLogParser.parseTimestamp("2000-03-01 00:00:00 +0000"))
        assertEquals(1_767_254_400L, PmsetWakeLogParser.parseTimestamp("2026-01-01 00:00:00 -0800"))
    }

    /// 1970 年之前也要对得上，因为 days_from_civil 的负数分支容易被写错。
    @Test
    fun `timestamp conversion handles dates before nineteen seventy`() {
        // 1969-12-31 23:59:59 UTC 是 -1。
        assertEquals(-1L, PmsetWakeLogParser.parseTimestamp("1969-12-31 23:59:59 +0000"))
        // 1900-01-01 00:00:00 UTC 是 -2208988800。
        assertEquals(-2_208_988_800L, PmsetWakeLogParser.parseTimestamp("1900-01-01 00:00:00 +0000"))
    }

    /// 闰年判断。1900 不是闰年，2000 是。
    @Test
    fun `timestamp conversion validates the calendar`() {
        assertNull(PmsetWakeLogParser.parseTimestamp("1900-02-29 00:00:00 +0000"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-02-29 00:00:00 +0000"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-02-30 00:00:00 +0000"))
        assertEquals(
            PmsetWakeLogParser.parseTimestamp("2000-03-01 00:00:00 +0000"),
            PmsetWakeLogParser.parseTimestamp("2000-02-29 00:00:00 +0000")!! + 86_400L,
        )
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-13-01 00:00:00 +0000"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-00-10 00:00:00 +0000"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-10-00 00:00:00 +0000"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-10-08 24:00:00 +0000"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-10-08 00:60:00 +0000"))
    }

    @Test
    fun `timestamp conversion rejects malformed input`() {
        assertNull(PmsetWakeLogParser.parseTimestamp(""))
        assertNull(PmsetWakeLogParser.parseTimestamp("not a timestamp"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-10-08 00:00:00"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-10-08 00:00:00 Z"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-10-08T00:00:00+0000"))
        assertNull(PmsetWakeLogParser.parseTimestamp("20261008 000000 +0000"))
    }

    /// 偏移量分正负，符号不能忽略。
    @Test
    fun `timestamp conversion applies the offset sign`() {
        val utc = PmsetWakeLogParser.parseTimestamp("2026-10-08 12:00:00 +0000")!!
        assertEquals(utc - 8 * 3_600L, PmsetWakeLogParser.parseTimestamp("2026-10-08 12:00:00 +0800"))
        assertEquals(utc + 5 * 3_600L, PmsetWakeLogParser.parseTimestamp("2026-10-08 12:00:00 -0500"))
        // 半小时偏移的地区也要对。+0530 是 5.5 小时，即 11 个半小时。
        assertEquals(utc - 11 * 1_800L, PmsetWakeLogParser.parseTimestamp("2026-10-08 12:00:00 +0530"))
    }
}
