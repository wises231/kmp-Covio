package com.wyz.covio.domain

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.alloc
import kotlinx.cinterop.nativeHeap
import kotlinx.cinterop.ptr
import platform.posix.PTHREAD_MUTEX_RECURSIVE
import platform.posix.pthread_mutex_t
import platform.posix.pthread_mutexattr_destroy
import platform.posix.pthread_mutexattr_init
import platform.posix.pthread_mutexattr_settype
import platform.posix.pthread_mutex_destroy
import platform.posix.pthread_mutex_init
import platform.posix.pthread_mutex_lock
import platform.posix.pthread_mutex_unlock

/**
 * 递归的 pthread 互斥量。`Engine` 会嵌套取锁，所以必须是递归类型。
 *
 * `PTHREAD_MUTEX_RECURSIVE` 让同一线程可以重复取锁，计数归零才真正释放。
 * 这与 JVM 的 `synchronized` 语义一致。
 */
@OptIn(ExperimentalForeignApi::class)
internal actual class EngineLock {
    private val mutex = nativeHeap.alloc<pthread_mutex_t>()

    init {
        val attributes = nativeHeap.alloc<platform.posix.pthread_mutexattr_t>()
        pthread_mutexattr_init(attributes.ptr)
        pthread_mutexattr_settype(attributes.ptr, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(mutex.ptr, attributes.ptr)
        pthread_mutexattr_destroy(attributes.ptr)
        nativeHeap.free(attributes.rawPtr)
    }

    actual fun <T> withLock(block: () -> T): T {
        pthread_mutex_lock(mutex.ptr)
        try {
            return block()
        } finally {
            pthread_mutex_unlock(mutex.ptr)
        }
    }

    /** 锁与引擎同生命周期，这里不主动释放。保留方法供将来显式销毁。 */
    fun dispose() {
        pthread_mutex_destroy(mutex.ptr)
        nativeHeap.free(mutex.rawPtr)
    }
}
