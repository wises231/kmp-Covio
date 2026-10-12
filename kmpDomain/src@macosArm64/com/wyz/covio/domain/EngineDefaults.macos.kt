package com.wyz.covio.domain

import kotlinx.cinterop.ExperimentalForeignApi
import platform.Foundation.NSDate
import platform.Foundation.timeIntervalSince1970
import platform.darwin.DISPATCH_QUEUE_PRIORITY_DEFAULT
import platform.darwin.DISPATCH_TIME_NOW
import platform.darwin.dispatch_after
import platform.darwin.dispatch_async
import platform.darwin.dispatch_get_global_queue
import platform.darwin.dispatch_get_main_queue
import platform.darwin.dispatch_time
import platform.posix.usleep

@OptIn(ExperimentalForeignApi::class)
internal actual object EngineDefaults {
    actual fun wakeScanExecutor(runnable: () -> Unit) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT.toLong(), 0uL)) {
            runnable()
        }
    }

    actual fun blockingDelay(millis: Long) {
        if (millis <= 0L) return
        usleep((millis * 1_000L).toUInt())
    }

    actual fun scheduleAfter(delayMillis: Long, block: () -> Unit) {
        val nanoseconds = delayMillis.coerceAtLeast(0L) * 1_000_000L
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, nanoseconds),
            dispatch_get_main_queue(),
        ) {
            block()
        }
    }

    actual fun nowMillis(): Long = (NSDate().timeIntervalSince1970 * 1_000.0).toLong()
}
