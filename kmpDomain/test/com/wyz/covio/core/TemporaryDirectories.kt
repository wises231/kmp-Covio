package com.wyz.covio.core

import kotlin.random.Random
import okio.FileSystem
import okio.Path

/**
 * 测试用的临时目录。
 *
 * 用 `kotlin.random` 而不是 `java.util.UUID`，因为同一份测试要跑在 macosArm64 上。
 */
internal fun temporaryDirectory(tag: String): Path {
    val base = FileSystem.SYSTEM_TEMPORARY_DIRECTORY
    var candidate = base.resolve("covio-$tag-${Random.nextLong().toString(16).removePrefix("-")}")
    while (FileSystem.SYSTEM.exists(candidate)) {
        candidate = base.resolve("covio-$tag-${Random.nextLong().toString(16).removePrefix("-")}")
    }
    FileSystem.SYSTEM.createDirectories(candidate)
    return candidate
}

/** 建临时目录并在测试结束时删除。 */
internal inline fun <T> withTemporaryDirectory(tag: String, block: (Path) -> T): T {
    val directory = temporaryDirectory(tag)
    try {
        return block(directory)
    } finally {
        FileSystem.SYSTEM.deleteRecursively(directory, mustExist = false)
    }
}

internal fun Path.writeText(text: String) {
    FileSystem.SYSTEM.write(this) { writeUtf8(text) }
}

internal fun Path.readText(): String = FileSystem.SYSTEM.read(this) { readUtf8() }

internal val Path.exists: Boolean get() = FileSystem.SYSTEM.exists(this)
