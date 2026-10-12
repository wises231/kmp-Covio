package com.wyz.covio.domain

internal actual object EngineDefaults {
    actual fun wakeScanExecutor(runnable: () -> Unit) {
        Thread(runnable).apply {
            name = "Covio-wake-log"
            isDaemon = true
        }.start()
    }

    actual fun blockingDelay(millis: Long) {
        Thread.sleep(millis)
    }

    actual fun scheduleAfter(delayMillis: Long, block: () -> Unit) {
        Thread {
            Thread.sleep(delayMillis)
            block()
        }.apply {
            name = "Covio-sleep-restore"
            isDaemon = true
        }.start()
    }

    actual fun nowMillis(): Long = System.currentTimeMillis()
}
