package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * 重名规则的断言。
 *
 * `ShelfFileOperations.swift` 的既有用例
 * `ShelfRuntimeTests.testCopyingDoesNotOverwriteAnExistingFile` 是集成侧的另一半。
 */
class ShelfFileNamingTest {
    private fun occupied(vararg names: String): (String) -> Boolean {
        val taken = names.toSet()
        return { it in taken }
    }

    @Test
    fun `a free name is returned unchanged`() {
        assertEquals("a.png", ShelfFileNaming.uniqueName("a.png", occupied()))
    }

    @Test
    fun `an occupied name gets the second candidate`() {
        assertEquals("a 2.png", ShelfFileNaming.uniqueName("a.png", occupied("a.png")))
    }

    @Test
    fun `numbering continues while candidates are occupied`() {
        assertEquals(
            "a 4.png",
            ShelfFileNaming.uniqueName("a.png", occupied("a.png", "a 2.png", "a 3.png")),
        )
    }

    @Test
    fun `the suffix keeps the last dot`() {
        assertEquals("archive.tar 2.gz", ShelfFileNaming.uniqueName("archive.tar.gz", occupied("archive.tar.gz")))
    }

    @Test
    fun `a leading dot is not an extension`() {
        // `.DS_Store` 整串是名字，所以候选是 `.DS_Store 2`，不是 `. 2DS_Store`。
        assertEquals(".DS_Store 2", ShelfFileNaming.uniqueName(".DS_Store", occupied(".DS_Store")))
    }

    @Test
    fun `a name without a dot gets the number appended`() {
        assertEquals("noext 2", ShelfFileNaming.uniqueName("noext", occupied("noext")))
    }

    @Test
    fun `the numbered name keeps the extension attached`() {
        assertEquals("photo 2.png", ShelfFileNaming.numberedName("photo.png", 2))
    }
}
