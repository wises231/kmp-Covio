package com.wyz.covio.domain

internal actual class EngineLock {
    private val monitor = Any()

    actual fun <T> withLock(block: () -> T): T = synchronized(monitor) { block() }
}
