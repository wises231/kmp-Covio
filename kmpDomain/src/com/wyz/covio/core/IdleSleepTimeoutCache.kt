package com.wyz.covio.core

import com.wyz.covio.domain.EngineLock

/**
 * 系统空闲睡眠超时的读缓存。
 *
 * `pmset -g` 要几十毫秒，引擎每次 tick 都会问，所以缓存默认 60 秒。
 * 改过系统设置后由调用方调 [invalidate] 明确失效。
 *
 * 时钟与读取函数都是注入的，所以这个类不碰平台。
 * 读不到时也把「读不到」缓存下来，否则每次 tick 都会重跑一次 `pmset`。
 */
class IdleSleepTimeoutCache(
    private val clock: () -> Long,
    private val timeoutReader: () -> Long?,
    private val ttlMillis: Long = DEFAULT_TTL_MILLIS,
) {
    private val lock = EngineLock()
    private var valid = false
    private var cachedAtMillis = 0L
    private var cachedTimeoutSeconds: Long? = null

    /**
     * 取超时值。缓存有效时直接返回，否则读一次再存。
     *
     * 返回 null 有两种来源：缓存里存的「读不到」，以及这次读不到。
     * 两种情况对调用方的含义相同。
     */
    fun get(): Long? {
        val now = clock()
        var hit = false
        var cached: Long? = null
        lock.withLock {
            if (valid && now - cachedAtMillis >= 0 && now - cachedAtMillis < ttlMillis) {
                hit = true
                cached = cachedTimeoutSeconds
            }
        }
        if (hit) return cached

        val timeout = timeoutReader()
        lock.withLock {
            cachedTimeoutSeconds = timeout
            cachedAtMillis = now
            valid = true
        }
        return timeout
    }

    /** 让下一次 [get] 重新读。系统设置变化后调。 */
    fun invalidate() {
        lock.withLock {
            valid = false
            cachedAtMillis = 0L
            cachedTimeoutSeconds = null
        }
    }

    companion object {
        const val DEFAULT_TTL_MILLIS = 60_000L
    }
}
