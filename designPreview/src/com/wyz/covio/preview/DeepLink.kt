package com.wyz.covio.preview

import kotlin.js.ExperimentalWasmJsInterop

/** 地址栏的锚点。Kotlin/Wasm 里没有 `js("...")`，只能用 `@JsFun`。 */
@OptIn(ExperimentalWasmJsInterop::class)
@JsFun("() => window.location.hash")
private external fun rawHash(): String

/**
 * 地址栏锚点。
 *
 * 形如 `#107-home`。前段是 issue 号，后段是这份打样自己的锚点。
 *
 * 加锚点的用处：
 *
 * 1. 评审人直接落到某一屏，不用一层层点进去。
 * 2. 截图时一个地址一张图，不用改代码重编译。
 *
 * 打样自己的锚点有哪些，看那份打样的文档注释。
 */
object DeepLink {
    private val hash: String by lazy {
        runCatching { rawHash().removePrefix("#") }.getOrDefault("")
    }

    /** 锚点里的 issue 号。没有就返回 null，首页照常列出全部打样。 */
    val issue: Int? by lazy { hash.substringBefore('-').toIntOrNull() }

    /** 锚点里这份打样自己的那一段。没有就是空串。 */
    val anchor: String by lazy { hash.substringAfter('-', "").lowercase() }
}
