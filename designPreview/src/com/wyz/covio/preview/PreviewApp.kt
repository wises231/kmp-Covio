package com.wyz.covio.preview

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * 打样宿主。首页列出全部打样，点一条进去看。
 *
 * 这一层只管外壳与路由。每一份打样的内容在 [previews] 里。
 *
 * 只用 foundation 画。不引 material3：打样要还原的是 Covio 的设计，
 * 不是 Material 的默认样式。见 `docs/design/design-preview.md`。
 */
@Composable
fun PreviewApp() {
    var openIssue by remember { mutableStateOf<Int?>(null) }
    val open = previews.firstOrNull { it.issue == openIssue }

    Box(Modifier.fillMaxSize().background(Harness.canvas)) {
        if (open == null) {
            Home(onOpen = { openIssue = it.issue })
        } else {
            PreviewPage(preview = open, onBack = { openIssue = null })
        }
    }
}

/**
 * 宿主的色值。
 *
 * 宿主是工具，不是 Covio 的界面，所以这里用中性灰，不读设计合同。
 * 打样的内容才用合同里的取值。
 */
internal object Harness {
    val canvas = Color(0xFFECECEF)
    val surface = Color(0xFFFFFFFF)
    val textPrimary = Color(0xFF1D1D1F)
    val textSecondary = Color(0xFF6E6E73)
    val separator = Color(0xFFD1D1D6)
    val accent = Color(0xFF007AFF)
}

/** 一行字。颜色与字号每次都给，不落主题的默认值。 */
@Composable
internal fun Label(
    text: String,
    color: Color,
    size: TextUnit,
    weight: FontWeight = FontWeight.Normal,
    modifier: Modifier = Modifier,
) {
    BasicText(
        text = text,
        modifier = modifier,
        style = TextStyle(color = color, fontSize = size, fontWeight = weight),
    )
}

/** 首页。列出全部打样。 */
@Composable
private fun Home(onOpen: (Preview) -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 32.dp, vertical = 28.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Label("Covio 打样", Harness.textPrimary, 26.sp, FontWeight.SemiBold)
        Label(
            "设计闸门的预览产物。评审人拿每一份打样对照提出它的 issue 的「表现预期」。",
            Harness.textSecondary,
            13.sp,
        )
        Box(Modifier.fillMaxWidth().height(1.dp).background(Harness.separator))

        if (previews.isEmpty()) {
            EmptyState()
        } else {
            previews.forEach { preview ->
                PreviewCard(preview = preview, onOpen = { onOpen(preview) })
            }
        }
    }
}

/** 一份打样都没有时显示的卡片。 */
@Composable
private fun EmptyState() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(Harness.surface)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Label("还没有打样", Harness.textPrimary, 15.sp, FontWeight.Medium)
        Label(
            "宿主已经跑通。加第一份打样：在 PreviewRegistry.kt 的 previews 里加一条。",
            Harness.textSecondary,
            13.sp,
        )
    }
}

/** 首页上的一张卡片。 */
@Composable
private fun PreviewCard(preview: Preview, onOpen: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(Harness.surface)
            .clickable(onClick = onOpen)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Label(preview.title, Harness.textPrimary, 17.sp, FontWeight.Medium)
            IssueBadge(preview.issue)
        }
        Label(preview.covers, Harness.textSecondary, 13.sp)
    }
}

/** 一条打样。顶部是返回栏，下面铺满打样内容。 */
@Composable
private fun PreviewPage(preview: Preview, onBack: () -> Unit) {
    Column(Modifier.fillMaxSize()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(Harness.surface)
                .padding(horizontal = 20.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Label(
                "← 全部打样",
                Harness.accent,
                13.sp,
                modifier = Modifier.clip(RoundedCornerShape(6.dp)).clickable(onClick = onBack).padding(4.dp),
            )
            Label(preview.title, Harness.textPrimary, 15.sp, FontWeight.Medium)
            IssueBadge(preview.issue)
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(Harness.separator))
        Box(Modifier.fillMaxSize()) {
            preview.content()
        }
    }
}

/** `#106` 这样的小标签。 */
@Composable
private fun IssueBadge(issue: Int) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(Harness.canvas)
            .padding(horizontal = 8.dp, vertical = 2.dp),
    ) {
        Label("#$issue", Harness.textSecondary, 11.sp)
    }
}
