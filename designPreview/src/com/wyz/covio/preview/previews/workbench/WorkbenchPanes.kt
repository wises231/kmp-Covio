package com.wyz.covio.preview.previews.workbench

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * 面板里的三种内容：工作区内容页（S5）、工作区设置页（S7）、错误与恢复（S8）。
 */

/** S5：工作区内容页。 */
@Composable
internal fun PaneContent(pane: Pane) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        PaneHeading(pane)

        contentRows(pane.kind).forEach { row ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(Tokens.cardRadius.dp))
                    .background(Tokens.surface)
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(row.title, color = Tokens.textPrimary, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                    Text(row.detail, color = Tokens.textSecondary, fontSize = 11.sp)
                }
                Text(row.trailing, color = Tokens.actionFill, fontSize = 12.sp)
            }
        }
    }
}

/** 页标题。标题加一句说明，并排一行。合同条目 `component/page-title`。 */
@Composable
private fun PaneHeading(pane: Pane) {
    Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(pane.displayTitle, color = Tokens.textPrimary, fontSize = 18.sp, fontWeight = FontWeight.SemiBold)
        Text(pane.kind.summary, color = Tokens.textSecondary, fontSize = 11.sp)
    }
}

/** 工作区的一句话说明。取自合同 `copy/hub/tab/<键>/summary`。 */
internal val PaneKind.summary: String
    get() = when (this) {
        PaneKind.NOW -> "电源、电池、合盖、设备连接和待处理项。"
        PaneKind.CLIPBOARD -> "最近文本、图片和文件列表。"
        PaneKind.FILES -> "临时文件、剩余空间和过期时间。"
        PaneKind.SCREENSHOTS -> "最近截图和截图工具栏。"
        PaneKind.DEVICES -> "已配对设备、发现结果和传输队列。"
        PaneKind.SETTINGS -> "权限、语言、通知、隐私和保留策略。"
        PaneKind.BOARD -> "自建工作区，只有组件网格。"
    }

/**
 * S7：工作区设置页。F5。
 *
 * 改名、换图标、隐藏、重置、删除。内置工作区没有删除项（ADR-0002 决策 6）。
 */
@Composable
internal fun PaneSettings(
    pane: Pane,
    settings: List<PaneSetting>,
    onRename: (String) -> Unit,
    onIcon: (String) -> Unit,
    onHidden: (Boolean) -> Unit,
    onSettingToggle: (String) -> Unit,
    onReset: () -> Unit,
    onDelete: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        PaneHeading(pane)

        SettingBlock("名称") {
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(30.dp)
                    .clip(RoundedCornerShape(Tokens.controlRadius.dp))
                    .background(Tokens.controlFill)
                    .border(1.dp, Tokens.divider, RoundedCornerShape(Tokens.controlRadius.dp))
                    .padding(horizontal = 10.dp),
                contentAlignment = Alignment.CenterStart,
            ) {
                if (pane.title.isEmpty()) {
                    Text("用内置名字「${pane.kind.defaultTitle}」", color = Tokens.textSecondary, fontSize = 12.sp)
                }
                BasicTextField(
                    value = pane.title,
                    onValueChange = onRename,
                    singleLine = true,
                    textStyle = TextStyle(color = Tokens.textPrimary, fontSize = 12.sp),
                    cursorBrush = SolidColor(Tokens.actionFill),
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }

        SettingBlock("图标") {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                iconChoices.forEach { choice ->
                    val selected = pane.displayIcon == choice
                    Box(
                        Modifier
                            .size(30.dp)
                            .clip(RoundedCornerShape(Tokens.controlRadius.dp))
                            .background(if (selected) Tokens.actionFill else Tokens.controlFill)
                            .border(
                                1.dp,
                                if (selected) Tokens.actionFill else Tokens.divider,
                                RoundedCornerShape(Tokens.controlRadius.dp),
                            )
                            .clickable { onIcon(choice) },
                        contentAlignment = Alignment.Center,
                    ) {
                        Text(
                            choice,
                            color = if (selected) Tokens.textOnAccent else Tokens.textPrimary,
                            fontSize = 13.sp,
                        )
                    }
                }
            }
        }

        SettingBlock("显示") {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                SwitchRow(
                    label = "在 tab bar 显示",
                    summary = "关掉只是隐藏，工作区还在。",
                    on = !pane.hidden,
                    onToggle = { onHidden(!it) },
                )
                settings.forEach { setting ->
                    SwitchRow(
                        label = setting.label,
                        summary = setting.summary,
                        on = setting.on,
                        onToggle = { onSettingToggle(setting.key) },
                    )
                }
            }
        }

        SettingBlock("恢复") {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ActionButton("重置这个工作区", primary = false, onClick = onReset)
                // 内置工作区没有删除项。ADR-0002 决策 6。
                if (!pane.isBuiltin) {
                    ActionButton("删除工作区", primary = true, onClick = onDelete)
                }
            }
            if (pane.isBuiltin) {
                Spacer(Modifier.height(6.dp))
                Text(
                    "内置工作区不能删除，只能隐藏。",
                    color = Tokens.disabledText,
                    fontSize = 11.sp,
                )
            }
        }
    }
}

/** 设置页的一个分组。 */
@Composable
private fun SettingBlock(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(7.dp)) {
        Text(title, color = Tokens.textSecondary, fontSize = 11.sp, fontWeight = FontWeight.Medium)
        content()
    }
}

/** 一行开关。 */
@Composable
private fun SwitchRow(label: String, summary: String, on: Boolean, onToggle: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Tokens.controlRadius.dp))
            .background(Tokens.surface)
            .clickable { onToggle(on) }
            .padding(horizontal = 12.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(label, color = Tokens.textPrimary, fontSize = 12.sp)
            Text(summary, color = Tokens.textSecondary, fontSize = 10.sp)
        }
        Box(
            Modifier
                .width(34.dp)
                .height(20.dp)
                .clip(RoundedCornerShape(Tokens.pillRadius.dp))
                .background(if (on) Tokens.successFill else Tokens.divider),
            contentAlignment = if (on) Alignment.CenterEnd else Alignment.CenterStart,
        ) {
            Box(
                Modifier
                    .padding(horizontal = 2.dp)
                    .size(16.dp)
                    .clip(RoundedCornerShape(Tokens.pillRadius.dp))
                    .background(Color.White),
            )
        }
    }
}

/** 设置页上的一个按钮。 */
@Composable
private fun ActionButton(label: String, primary: Boolean, onClick: () -> Unit) {
    Box(
        Modifier
            .height(28.dp)
            .clip(RoundedCornerShape(Tokens.controlRadius.dp))
            .background(if (primary) Tokens.errorBg else Tokens.controlFill)
            .border(1.dp, if (primary) Tokens.errorText else Tokens.divider, RoundedCornerShape(Tokens.controlRadius.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, color = if (primary) Tokens.errorText else Tokens.textPrimary, fontSize = 12.sp)
    }
}

/**
 * S8：错误与恢复。
 *
 * 文案写出原因和恢复动作。见 F7 的降级与需求文档第 7 节的 `ERROR` 状态。
 */
@Composable
internal fun ErrorScreen(
    onRetry: () -> Unit,
    onOpenSettings: () -> Unit,
    onResetLayout: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(Tokens.cardRadius.dp))
                .background(Tokens.errorBg)
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("!", color = Tokens.errorText, fontSize = 16.sp, fontWeight = FontWeight.Bold)
            Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
                Text("读不到工作台配置", color = Tokens.errorText, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                Text(
                    "原因：workbench.json 的内容不是合法的 JSON，解析在第 3 行中断。",
                    color = Tokens.textPrimary,
                    fontSize = 12.sp,
                )
                Text(
                    "工作台仍然可用。现在显示的是默认布局。",
                    color = Tokens.textSecondary,
                    fontSize = 11.sp,
                )
            }
        }

        Text("恢复动作", color = Tokens.textSecondary, fontSize = 11.sp, fontWeight = FontWeight.Medium)
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            ActionButton("重试", primary = false, onClick = onRetry)
            ActionButton("打开配置目录", primary = false, onClick = onOpenSettings)
            ActionButton("回退默认布局", primary = false, onClick = onResetLayout)
        }

        Text(
            "回退默认布局会丢掉自定义的工作区与组件排布。",
            color = Tokens.textSecondary,
            fontSize = 11.sp,
        )
    }
}

/**
 * S6：编辑模式的状态条。
 *
 * 编辑模式的形态还没定（需求文档第 9 节，影响 #82）。打样先用一条状态条占位，
 * 把「拖动排序、拖动卡片、缩放、删除」这几件事画出来。
 */
@Composable
internal fun EditBanner(tabCount: Int, widgetCount: Int, onDone: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Tokens.controlRadius.dp))
            .background(Tokens.infoBg)
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            "编辑模式：拖动页签排序，拖动卡片移动，拖右下角缩放，点 ✕ 删除。",
            color = Tokens.textPrimary,
            fontSize = 11.sp,
            modifier = Modifier.weight(1f),
        )
        Text("$tabCount 个工作区 · $widgetCount 块组件", color = Tokens.textSecondary, fontSize = 11.sp)
        Spacer(Modifier.width(12.dp))
        ActionButton("完成", primary = false, onClick = onDone)
    }
}
