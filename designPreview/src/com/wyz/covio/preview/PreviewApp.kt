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
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * 打样宿主。首页列出全部打样，点一条进去看。
 *
 * 这一层只管外壳与路由。每一份打样的内容在 [previews] 里。
 *
 * 地址栏加锚点可以直接进某一份打样，见 [DeepLink]。
 */
@Composable
fun PreviewApp() {
    var openIssue by remember { mutableStateOf(DeepLink.issue) }
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
        Text("Covio 打样", color = Harness.textPrimary, fontSize = 26.sp, fontWeight = FontWeight.SemiBold)
        Text(
            "设计闸门的预览产物。评审人拿每一份打样对照提出它的 issue 的「表现预期」。",
            color = Harness.textSecondary,
            fontSize = 13.sp,
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
        Text("还没有打样", color = Harness.textPrimary, fontSize = 15.sp, fontWeight = FontWeight.Medium)
        Text(
            "宿主已经跑通。加第一份打样：在 PreviewRegistry.kt 的 previews 里加一条。",
            color = Harness.textSecondary,
            fontSize = 13.sp,
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
            Text(preview.title, color = Harness.textPrimary, fontSize = 17.sp, fontWeight = FontWeight.Medium)
            IssueBadge(preview.issue)
        }
        Text(preview.covers, color = Harness.textSecondary, fontSize = 13.sp)
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
            Text(
                "← 全部打样",
                color = Harness.accent,
                fontSize = 13.sp,
                modifier = Modifier.clip(RoundedCornerShape(6.dp)).clickable(onClick = onBack).padding(4.dp),
            )
            Text(preview.title, color = Harness.textPrimary, fontSize = 15.sp, fontWeight = FontWeight.Medium)
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
        Text("#$issue", color = Harness.textSecondary, fontSize = 11.sp)
    }
}
