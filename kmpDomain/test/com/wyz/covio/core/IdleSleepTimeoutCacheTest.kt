package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * `IdleSleepTimeoutCache` 的断言。
 *
 * `pmset -g` 要几十毫秒，`Engine.tick()` 每次调用都会问，所以缓存 60 秒。
 * 缓存错了会让「阻止闲置睡眠」用一个已经改掉的系统超时值。
 *
 * 四条断言都同时看结果和读取次数：只看结果分不出「命中缓存」和「又读了一次」。
 * 同一批断言在 `macosApp/test/SleepControllerTests.swift` 里对着导出的类再跑一遍。
 */
class IdleSleepTimeoutCacheTest {
    private val ttl = 60_000L

    @Test
    fun `cache reuses the timeout inside the ttl`() {
        var now = 10_000L
        var reads = 0
        val cache = IdleSleepTimeoutCache(
            clock = { now },
            timeoutReader = {
                reads += 1
                120L
            },
            ttlMillis = ttl,
        )

        assertEquals(120L, cache.get())
        now += 59_999
        assertEquals(120L, cache.get())
        assertEquals(1, reads)
    }

    @Test
    fun `cache reads again after the ttl`() {
        var now = 10_000L
        var reads = 0
        val cache = IdleSleepTimeoutCache(
            clock = { now },
            timeoutReader = {
                reads += 1
                if (reads == 1) 120L else 300L
            },
            ttlMillis = ttl,
        )

        assertEquals(120L, cache.get())
        now += 60_000
        assertEquals(300L, cache.get())
        assertEquals(2, reads)
    }

    @Test
    fun `invalidate forces the next read`() {
        var reads = 0
        val cache = IdleSleepTimeoutCache(
            clock = { 0L },
            timeoutReader = {
                reads += 1
                reads * 60L
            },
        )

        assertEquals(60L, cache.get())
        assertEquals(60L, cache.get())
        cache.invalidate()
        assertEquals(120L, cache.get())
        assertEquals(2, reads)
    }

    /**
     * `pmset` 读不到时是 null，不是异常。
     * null 也要缓存，否则每次 tick 都会再起一个进程去撞同一个失败。
     */
    @Test
    fun `unavailable timeout is cached as unavailable`() {
        var reads = 0
        val cache = IdleSleepTimeoutCache(
            clock = { 0L },
            timeoutReader = {
                reads += 1
                null
            },
        )

        assertEquals(null, cache.get())
        assertEquals(null, cache.get())
        assertEquals(1, reads)
    }
}
