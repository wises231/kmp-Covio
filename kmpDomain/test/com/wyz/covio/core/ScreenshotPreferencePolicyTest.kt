package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * 系统截图偏好解析的断言。取值参照 `ScreenshotPreferenceStore` 的既有实现。
 */
class ScreenshotPreferencePolicyTest {
    @Test
    fun `a plain string key is returned trimmed`() {
        assertEquals("/Users/me/Desktop", ScreenshotPreferencePolicy.parseString(0, "/Users/me/Desktop\n"))
    }

    @Test
    fun `paired quotes are removed`() {
        assertEquals(
            "/Users/me/My Shots",
            ScreenshotPreferencePolicy.parseString(0, "\"/Users/me/My Shots\"\n"),
        )
    }

    @Test
    fun `a nonzero exit code is null`() {
        assertEquals(
            null,
            ScreenshotPreferencePolicy.parseString(
                1,
                "The domain/default pair of (com.apple.screencapture, location) does not exist",
            ),
        )
    }

    /** 键存在但是空串，与「键不存在」都返回 null。 */
    @Test
    fun `an empty output is null`() {
        assertEquals(null, ScreenshotPreferencePolicy.parseString(0, "\n"))
        assertEquals(null, ScreenshotPreferencePolicy.parseString(0, "\"\""))
    }

    @Test
    fun `a single quote character is left alone`() {
        assertEquals("\"", ScreenshotPreferencePolicy.parseString(0, "\""))
    }

    @Test
    fun `recognised boolean spellings are parsed`() {
        for (text in listOf("1", "true", "YES", " yes\n")) {
            assertEquals(true, ScreenshotPreferencePolicy.parseBoolean(0, text), text)
        }
        for (text in listOf("0", "false", "No", " no\n")) {
            assertEquals(false, ScreenshotPreferencePolicy.parseBoolean(0, text), text)
        }
    }

    /** 取值不认识时不猜。调用方靠 null 区分「键不存在」与「值是 false」。 */
    @Test
    fun `an unrecognised boolean is null`() {
        assertEquals(null, ScreenshotPreferencePolicy.parseBoolean(0, "maybe"))
        assertEquals(null, ScreenshotPreferencePolicy.parseBoolean(0, ""))
        assertEquals(null, ScreenshotPreferencePolicy.parseBoolean(1, "1"))
    }

    /** 快照里的布尔值存成 "1" 或 "0"，写回要换成 `-bool` 认的字面量。 */
    @Test
    fun `boolean snapshots are written as bool literals`() {
        assertEquals("true", ScreenshotPreferencePolicy.writeArgument("1", isString = false))
        assertEquals("false", ScreenshotPreferencePolicy.writeArgument("0", isString = false))
    }

    /** 字符串键原样写回，不做布尔换算。 */
    @Test
    fun `string snapshots are written unchanged`() {
        assertEquals("1", ScreenshotPreferencePolicy.writeArgument("1", isString = true))
        assertEquals("/Users/me/Desktop", ScreenshotPreferencePolicy.writeArgument("/Users/me/Desktop", isString = true))
    }

    /** 键本来就不存在时 `defaults delete` 报错，这算还原成功。 */
    @Test
    fun `deleting a missing key counts as success`() {
        assertTrue(ScreenshotPreferencePolicy.deleteIsSuccess(0, ""))
        assertTrue(
            ScreenshotPreferencePolicy.deleteIsSuccess(
                1,
                "The domain/default pair of (com.apple.screencapture, location) does not exist",
            ),
        )
        assertTrue(ScreenshotPreferencePolicy.deleteIsSuccess(1, "Domain (com.apple.screencapture) DOES NOT EXIST"))
    }

    @Test
    fun `another delete failure is not success`() {
        assertFalse(ScreenshotPreferencePolicy.deleteIsSuccess(1, "Operation not permitted"))
    }
}
