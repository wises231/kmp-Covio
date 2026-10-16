package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class SmokeTest {
    /**
     * 版本号要能解析，而且是稳定版。
     *
     * 这里不写死具体数字：数字每次发版都变，写死了就得跟着改两处。
     * 真正要守住的是「它是唯一的版本来源，而且格式合法」，
     * Xcode 工程的 `MARKETING_VERSION` 与它一致，由 Swift 侧的
     * `ConfigCompatibilityTests.testBundleVersionMatchesTheKotlinConstant` 守。
     */
    @Test
    fun versionIsPresentAndParsable() {
        assertTrue(APP_VERSION.isNotBlank())
        val parsed = SemanticVersion.parse(APP_VERSION)
        assertEquals(APP_VERSION, parsed?.toString())
        assertTrue(isStableVersion(APP_VERSION), "发布版本不能带预发布后缀：$APP_VERSION")
    }
}
