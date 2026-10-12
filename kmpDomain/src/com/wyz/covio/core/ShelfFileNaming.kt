package com.wyz.covio.core

/**
 * 晾衣线的文件重名规则。
 *
 * 「照片.png」被占用时依次试「照片 2.png」「照片 3.png」。
 * 以点开头且没有其他点的名字当作没有扩展名，所以 `.DS_Store` 的候选是 `.DS_Store 2`。
 *
 * 存在性检查由调用方注入。这里不碰文件系统，规则本身两个平台共用。
 */
object ShelfFileNaming {
    /**
     * 第 [index] 个候选名。index 从 2 起。
     *
     * 扩展名按最后一个点切。点在最前面时不算扩展名。
     */
    fun numberedName(name: String, index: Int): String {
        val dot = name.lastIndexOf('.')
        val hasExtension = dot > 0
        val base = if (hasExtension) name.substring(0, dot) else name
        val suffix = if (hasExtension) name.substring(dot) else ""
        return "$base $index$suffix"
    }

    /**
     * 第一个未被占用的名字。
     *
     * [name] 本身没被占用时原样返回，所以调用方不需要先查一次。
     */
    fun uniqueName(name: String, exists: (String) -> Boolean): String {
        if (!exists(name)) return name
        var index = 2
        while (true) {
            val candidate = numberedName(name, index)
            if (!exists(candidate)) return candidate
            index += 1
        }
    }
}
