package com.wyz.covio.core

import java.time.LocalDate
import java.time.LocalTime
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/**
 * `PmsetWakeLogParser.parseTimestamp` 与 `java.time` 的一致性测试。
 *
 * 这个文件只跑在 jvm 上，作用是当参照物：手写的时间戳转换必须在整个值域上
 * 与 `java.time` 逐值相等。macosArm64 上跑的是同一份被测代码，
 * 所以这里通过就等于两个平台都通过。
 *
 * 见 `docs/adr/adr-0001-macos-ui-swiftui.md` 实测 18。
 */
class PmsetWakeLogParserParityTest {
    private val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss Z", Locale.US)

    private fun reference(value: String): Long =
        OffsetDateTime.parse(value, formatter).toEpochSecond()

    private fun timestamp(date: LocalDate, time: LocalTime, offset: ZoneOffset): String =
        "%04d-%02d-%02d %02d:%02d:%02d %s".format(
            date.year,
            date.monthValue,
            date.dayOfMonth,
            time.hour,
            time.minute,
            time.second,
            offsetText(offset),
        )

    private fun offsetText(offset: ZoneOffset): String {
        val total = offset.totalSeconds
        val sign = if (total < 0) "-" else "+"
        val absolute = kotlin.math.abs(total)
        return "%s%02d%02d".format(sign, absolute / 3_600, (absolute % 3_600) / 60)
    }

    /// 逐日扫过 1970 年前后各若干年，覆盖闰年与月末。
    @Test
    fun `day by day across leap years matches java time`() {
        val start = LocalDate.of(1968, 1, 1)
        val end = LocalDate.of(2032, 12, 31)
        val expectedDays = ChronoUnit.DAYS.between(start, end) + 1
        val time = LocalTime.of(13, 56, 24)
        val offset = ZoneOffset.ofHours(8)

        var date = start
        var checked = 0L

        while (!date.isAfter(end)) {
            val value = timestamp(date, time, offset)
            assertEquals(reference(value), PmsetWakeLogParser.parseTimestamp(value), "不一致：$value")
            date = date.plusDays(1)
            checked += 1
        }

        assertEquals(expectedDays, checked, "扫描的天数不对，测试本身可能没跑完")
    }

    /// 一天里的每个小时与每分钟边界。
    @Test
    fun `every hour and minute boundary matches java time`() {
        val date = LocalDate.of(2026, 10, 8)
        val offset = ZoneOffset.ofHours(8)
        for (hour in 0..23) {
            for (minute in 0..59) {
                for (second in listOf(0, 1, 30, 59)) {
                    val value = timestamp(date, LocalTime.of(hour, minute, second), offset)
                    assertEquals(reference(value), PmsetWakeLogParser.parseTimestamp(value), "不一致：$value")
                }
            }
        }
    }

    /// 全部整小时偏移，以及半小时与三刻钟偏移。
    @Test
    fun `every offset matches java time`() {
        val date = LocalDate.of(2026, 6, 15)
        val time = LocalTime.of(3, 4, 5)
        val offsets = (-12..14).map { ZoneOffset.ofHours(it) } +
            listOf(
                ZoneOffset.ofHoursMinutes(5, 30),
                ZoneOffset.ofHoursMinutes(-3, -30),
                ZoneOffset.ofHoursMinutes(5, 45),
                ZoneOffset.ofHoursMinutes(12, 45),
                ZoneOffset.ofHoursMinutes(-9, -30),
            )

        for (offset in offsets) {
            val value = timestamp(date, time, offset)
            assertEquals(reference(value), PmsetWakeLogParser.parseTimestamp(value), "不一致：$value")
        }
    }

    /// 闰秒与非法日期：参照物的行为也要对齐。
    @Test
    fun `invalid dates are rejected like java time`() {
        // java.time 的默认解析器不接受 2 月 30 日。
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-02-30 00:00:00 +0000"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-04-31 00:00:00 +0000"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-06-31 00:00:00 +0000"))
        assertNull(PmsetWakeLogParser.parseTimestamp("2026-11-31 00:00:00 +0000"))
        // 1900 不是闰年。
        assertNull(PmsetWakeLogParser.parseTimestamp("1900-02-29 00:00:00 +0000"))
        // 2000 是闰年。
        assertEquals(
            reference("2000-02-29 00:00:00 +0000"),
            PmsetWakeLogParser.parseTimestamp("2000-02-29 00:00:00 +0000"),
        )
    }

    /// 真实日志里出现过的整行，端到端比对。
    @Test
    fun `real log lines match java time`() {
        val lines = listOf(
            "2026-10-08 11:18:14 +0800",
            "2026-10-08 12:20:00 +0800",
            "2026-10-08 13:34:53 +0800",
            "2026-10-07 23:59:59 +0800",
            "2026-10-08 00:00:00 +0800",
            "2026-10-09 00:00:00 +0800",
            "2025-12-31 23:59:59 -0800",
        )
        for (line in lines) {
            assertEquals(reference(line), PmsetWakeLogParser.parseTimestamp(line), "不一致：$line")
        }
    }

    /// 解析整份日志时，事件的时间戳也要与参照物一致。
    @Test
    fun `parsed event timestamps match java time`() {
        val text = """
            2026-10-08 11:18:14 +0800 DarkWake DarkWake from Deep Idle [CDNP] : due to A Using BATT (Charge:80%)
            2026-10-08 12:20:00 +0800 Wake Wake from Deep Idle [CDNVA] : due to B Using AC (Charge:80%)
        """.trimIndent()
        val snapshot = PmsetWakeLogParser.parse(text, 1_791_439_200L)
        assertEquals(
            listOf(reference("2026-10-08 11:18:14 +0800"), reference("2026-10-08 12:20:00 +0800")),
            snapshot.events.map { it.atEpochSeconds },
        )
    }
}
