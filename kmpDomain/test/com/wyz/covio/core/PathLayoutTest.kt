package com.wyz.covio.core

import kotlin.test.Test
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

/**
 * 目录布局的钉子。
 *
 * 这几个路径是 0.4.2 的既有布局。改了会让老用户找不到自己的设置。
 * 用例同时跑 jvm 与 macosArm64，所以缝在两个真实目标上都验过。
 *
 * 断言写成「以某段字面量结尾」，不拿实现自己的插值互相比。
 * 这样 actual 里换掉字面量时用例会红。
 */
class PathLayoutTest {
    @Test
    fun `the user data root keeps the apple layout`() {
        assertTrue(
            AppDirectories.userApplicationSupport.endsWith("/Library/Application Support"),
            "实际值：${AppDirectories.userApplicationSupport}",
        )
    }

    @Test
    fun `the config directory uses the application id`() {
        assertTrue(
            defaultConfigPath().endsWith("/Library/Application Support/$APP_ID/config.json"),
            "实际值：${defaultConfigPath()}",
        )
    }

    @Test
    fun `the shelf directory uses the application name`() {
        assertTrue(
            defaultShelfPath().endsWith("/Library/Application Support/$APP_NAME/Screenshots/shelf.json"),
            "实际值：${defaultShelfPath()}",
        )
    }

    @Test
    fun `the clipboard directory uses the application name`() {
        assertTrue(
            ClipboardStore.defaultDirectory().endsWith("/Library/Application Support/$APP_NAME/Clipboard"),
            "实际值：${ClipboardStore.defaultDirectory()}",
        )
    }

    @Test
    fun `the workspace directory uses the application name`() {
        assertTrue(
            WorkspaceStore.defaultDirectory().endsWith("/Library/Application Support/$APP_NAME/Workspace"),
            "实际值：${WorkspaceStore.defaultDirectory()}",
        )
    }

    @Test
    fun `the shelf and the config do not share a directory`() {
        // 晾衣线用 APP_NAME，配置用 APP_ID。混用会让老用户的设置或截图丢失。
        assertNotEquals(
            defaultShelfPath().substringBeforeLast("/Screenshots/"),
            defaultConfigPath().substringBeforeLast("/config.json"),
        )
    }
}
