package com.wyz.covio.domain

/**
 * P2 探针。确定 `Engine` 迁移到 common 所需的平台原语。
 *
 * `Engine` 需要三样东西，它们在 JVM 上分别来自 `Thread` 与 `System`：
 * 一个后台执行器、一个阻塞延时、一个当前时间。本文件确定它们在
 * macosArm64 上的替代品。验证后删除。
 */
internal expect object EngineDefaults {
    /** 在引擎线程之外跑一次唤醒日志扫描。 */
    fun wakeScanExecutor(runnable: () -> Unit)
    /** 阻塞当前线程指定毫秒。 */
    fun blockingDelay(millis: Long)
    /** 延迟后在引擎线程上执行。 */
    fun scheduleAfter(delayMillis: Long, block: () -> Unit)
    /** 当前时间，毫秒。 */
    fun nowMillis(): Long
}
