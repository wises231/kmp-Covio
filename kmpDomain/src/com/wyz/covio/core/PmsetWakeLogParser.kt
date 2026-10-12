package com.wyz.covio.core

/*
 * The wake-log parsing approach follows BatteryHog.
 * Source: https://github.com/luke-fairbanks/BatteryHog
 * Copyright (c) 2026 Luke Fairbanks
 * Licensed under the MIT License. See THIRD_PARTY_NOTICES.md.
 */

/**
 * `pmset -g log` 的解析。
 *
 * 时间戳格式固定为 `yyyy-MM-dd HH:mm:ss +0800`。时区偏移写在字符串里，
 * 所以不需要时区数据库。Kotlin/Native 没有 `java.time`，时间戳用纯算术转换。
 *
 * 转换的正确性由 `core/test/.../PmsetWakeLogParserParityTest.kt` 独立校验：
 * 那份测试在 jvm 上把本解析器与 `java.time` 逐值对比。
 */
object PmsetWakeLogParser {
    private const val RETENTION_SECONDS = 24L * 60L * 60L
    private const val FUTURE_TOLERANCE_SECONDS = 300L
    private val timestampPattern = Regex("""^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4})\s+(.+)$""")
    private val rawTimestampPattern =
        Regex("""^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) ([+-])(\d{2})(\d{2})$""")
    private val reasonPattern = Regex("""\bdue to\s+(.+?)(?:\s+Using\s|$)""", RegexOption.IGNORE_CASE)
    private val darkWakeToFullWakeToken = Regex("""\bDarkWake\s+to\s+FullWake\b""", RegexOption.IGNORE_CASE)
    private val fullWakeToken = Regex("""(?:^|\s)Wake(?:\s|\[|$)""")
    private val darkWakeToken = Regex("""(?:^|\s)DarkWake(?:\s|\[|$)""")

    fun parse(text: String, nowEpochSeconds: Long): WakeLogSnapshot {
        val cutoff = nowEpochSeconds - RETENTION_SECONDS
        val futureLimit = nowEpochSeconds + FUTURE_TOLERANCE_SECONDS
        val events = mutableListOf<WakeEvent>()

        for (rawLine in text.lineSequence()) {
            val line = rawLine.trim()
            val match = timestampPattern.matchEntire(line) ?: continue
            val atEpochSeconds = parseTimestamp(match.groupValues[1]) ?: continue
            if (atEpochSeconds < cutoff || atEpochSeconds > futureLimit) continue

            val remainder = match.groupValues[2]
            val kind = classify(remainder) ?: continue
            val reason = reasonPattern.find(remainder)?.groupValues?.getOrNull(1)?.trim().orEmpty()
            events += WakeEvent(kind = kind, atEpochSeconds = atEpochSeconds, reason = reason)
        }

        events.sortWith(compareBy<WakeEvent> { it.atEpochSeconds })
        return WakeLogSnapshot(
            events = events,
            darkWakeCount24h = events.count { it.kind == WakeKind.DARK },
        )
    }

    /**
     * 把 `2026-10-08 11:18:14 +0800` 转成 epoch 秒。
     *
     * 格式不符或日期不合法时返回 null。日期按公历校验，
     * 所以 `2026-02-30` 会被拒绝，不会被悄悄挪到 3 月 2 日。
     */
    fun parseTimestamp(value: String): Long? {
        val match = rawTimestampPattern.matchEntire(value.trim()) ?: return null
        val year = match.groupValues[1].toIntOrNull() ?: return null
        val month = match.groupValues[2].toIntOrNull() ?: return null
        val day = match.groupValues[3].toIntOrNull() ?: return null
        val hour = match.groupValues[4].toIntOrNull() ?: return null
        val minute = match.groupValues[5].toIntOrNull() ?: return null
        val second = match.groupValues[6].toIntOrNull() ?: return null
        val offsetHours = match.groupValues[8].toIntOrNull() ?: return null
        val offsetMinutes = match.groupValues[9].toIntOrNull() ?: return null

        if (month !in 1..12) return null
        if (day !in 1..daysInMonth(year, month)) return null
        if (hour !in 0..23) return null
        if (minute !in 0..59) return null
        // 闰秒用 60 表示。pmset 不写闰秒，但接受它比丢掉整行更安全。
        if (second !in 0..60) return null
        if (offsetHours !in 0..23 || offsetMinutes !in 0..59) return null

        val localSeconds = daysFromCivil(year, month, day) * 86_400L +
            hour * 3_600L + minute * 60L + second
        val offsetSeconds = (offsetHours * 3_600L + offsetMinutes * 60L) *
            if (match.groupValues[7] == "-") -1L else 1L
        return localSeconds - offsetSeconds
    }

    private fun isLeapYear(year: Int): Boolean =
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0

    private fun daysInMonth(year: Int, month: Int): Int = when (month) {
        1, 3, 5, 7, 8, 10, 12 -> 31
        4, 6, 9, 11 -> 30
        2 -> if (isLeapYear(year)) 29 else 28
        else -> 0
    }

    /**
     * 公历日期转「1970-01-01 起的天数」。Howard Hinnant 的 days_from_civil 算法。
     * 与 `java.time.LocalDate.toEpochDay()` 结果一致，包含 1970 年之前的日期。
     */
    private fun daysFromCivil(year: Int, month: Int, day: Int): Long {
        val adjustedYear = if (month <= 2) year - 1 else year
        val era = (if (adjustedYear >= 0) adjustedYear else adjustedYear - 399) / 400
        val yearOfEra = adjustedYear - era * 400
        val dayOfYear = (153 * (month + (if (month > 2) -3 else 9)) + 2) / 5 + day - 1
        val dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146_097L + dayOfEra - 719_468L
    }

    private fun classify(remainder: String): WakeKind? {
        val eventText = remainder.substringBefore(" from ", remainder).trim()
        return when {
            darkWakeToFullWakeToken.containsMatchIn(eventText) -> WakeKind.FULL
            fullWakeToken.containsMatchIn(eventText) -> WakeKind.FULL
            darkWakeToken.containsMatchIn(eventText) -> WakeKind.DARK
            else -> null
        }
    }
}
