package com.wyz.covio.preview.previews.workbench

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
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
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wyz.covio.preview.DeepLink
import com.wyz.covio.preview.LocalPreviewFontStatus
import kotlin.math.roundToInt

/**
 * 玻璃板组合的打样。外壳照控制中心（Control Center）的做法。
 *
 * 控制中心**没有统一背板**：一组独立的玻璃板直接浮在桌面上，板与板之间露出壁纸。
 * 依据是对 Apple 官方 Tahoe 宣传图的逐像素扫描 —— 模块间隙里像素平滑单调变化，
 * 没有玻璃边界。见提出这份打样的 issue。
 *
 * 与 [WorkbenchPreview] 的差别只在外壳。页签、组件网格、内容页复用同一批 composable，
 * 两份打样可以直接对比。
 *
 * | 锚点 | 画面 |
 * | --- | --- |
 * | 空 | 挂帘收起 |
 * | `home` | 两块玻璃板 · 首页网格 |
 * | `pane` | 两块玻璃板 · 工作区内容页 |
 */

// ---- 取值 ----
//
// 控制中心的比例来自官方宣传图测量。Apple 不公布绝对点值，HIG 里没有控制中心专页，
// 所以只有比例是可靠的，绝对点值由比例乘本项目的单位高度推出。

/**
 * 板与板之间的间隙。
 *
 * 控制中心的比例：间距 ÷ 模块边长 = 0.23。本项目的单位高度取顶栏的 46 点，
 * 46 × 0.23 ≈ 10.6，取 11。
 */
private val plateGap = 11.dp

/** 顶栏板的圆角。小模块用胶囊：圆角 = 高度 ÷ 2 = 46 ÷ 2 = 23。 */
private val barPlateRadius = 23.dp

/**
 * 内容板的圆角。
 *
 * 控制中心宽模块的比例是「圆角 ÷ 高度 = 0.38」。那条比例只对高度相近的模块成立：
 * 内容板高 400 点以上，照 0.38 算会到 150 点以上，不成形。
 * 所以这里取一个设计值，由评审在预览里定。
 */
private val contentPlateRadius = 28.dp

/**
 * 玻璃板的填充。
 *
 * 桌面透过板要看得见颜色与结构，这是控制中心最明显的一条。
 * 白色不透明度取 60%：再高板就成白卡片，壁纸的颜色被冲掉。
 * 真机的材质还会按背后亮度自适应（暗背景上板变暗），浏览器里做不到，
 * 这里取一个中性值，两种背景上都能读。
 */
private val plateFill = Color(0x99FFFFFF)

/** 板的上边缘高光。控制中心的层次靠它，不靠投影。 */
private val plateEdgeTop = Color(0xCCFFFFFF)

/** 板的下边缘。高光弱下去。 */
private val plateEdgeBottom = Color(0x24FFFFFF)

/**
 * 一块玻璃板。
 *
 * **没有投影。** 控制中心的模块与桌面之间没有可见投影，层次靠镜面亮边与明度差。
 * 这与现在真机上那块 `radius: 18` 的投影相反。
 *
 * **已知边界：** 真机是 Liquid Glass，有折射与真实模糊。浏览器里两样都没有，
 * 这里只有半透明填充加一圈渐变描边。材质的观感归真机验收。
 */
@Composable
private fun GlassPlate(shape: Shape, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Box(
        modifier
            .clip(shape)
            .background(plateFill)
            .border(1.dp, Brush.verticalGradient(listOf(plateEdgeTop, plateEdgeBottom)), shape),
    ) {
        content()
    }
}

/** 页签右端那个按钮的文案。与 [WorkbenchPreview] 一致。 */
private fun pageActionFor(editing: Boolean, homeSelected: Boolean): String = when {
    editing -> "完成"
    homeSelected -> "编辑"
    else -> "设置"
}

@Composable
internal fun GlassWorkbenchPreview() {
    val anchor = DeepLink.anchor
    var open by remember { mutableStateOf(anchor != "closed") }
    var homeSelected by remember { mutableStateOf(anchor != "pane") }
    var selectedId by remember { mutableStateOf("clipboard") }
    var query by remember { mutableStateOf("") }
    var editing by remember { mutableStateOf(false) }
    var reducedMotion by remember { mutableStateOf(false) }
    var panes by remember { mutableStateOf(defaultPanes()) }
    var widgets by remember { mutableStateOf(defaultWidgets()) }

    val progress = rememberCurtainProgress(open, reducedMotion)
    val density = LocalDensity.current.density
    val slide = if (reducedMotion) 0f else (1f - progress) * -14f
    val currentPane = panes.firstOrNull { it.id == selectedId } ?: panes.first()

    BoxWithConstraints(Modifier.fillMaxSize()) {
        val maxPanelHeight = maxHeight - 120.dp

        Wallpaper(Modifier.fillMaxSize())

        // 点挂帘外部收起。
        Box(
            Modifier
                .fillMaxSize()
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                ) { open = false },
        )

        Column(
            Modifier.align(Alignment.TopCenter),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            MenuBar(
                capsuleVisible = true,
                onHotspotEnter = { open = true },
                onCapsuleClick = { open = !open },
            )

            if (progress > 0.01f) {
                Column(
                    Modifier
                        .width(Tokens.panelWidth.dp)
                        .offset { IntOffset(0, (slide * density).roundToInt()) }
                        .alpha(progress),
                    verticalArrangement = Arrangement.spacedBy(plateGap),
                ) {
                    // 板 A：顶栏。胶囊形。
                    GlassPlate(RoundedCornerShape(barPlateRadius)) {
                        TabBar(
                            panes = panes,
                            homeSelected = homeSelected,
                            selectedId = selectedId,
                            query = query,
                            editing = editing,
                            pageAction = pageActionFor(editing, homeSelected),
                            onQueryChange = { query = it },
                            onHome = {
                                homeSelected = true
                                editing = false
                            },
                            onSelect = { id ->
                                selectedId = id
                                homeSelected = false
                                editing = false
                            },
                            onPageAction = { if (homeSelected) editing = !editing },
                            onReorder = { from, to ->
                                panes = panes.toMutableList().also { list ->
                                    val moved = list.removeAt(from)
                                    list.add(to.coerceIn(0, list.size), moved)
                                }
                            },
                        )
                    }

                    // 板 B：内容。圆角矩形。板内不叠玻璃，组件卡片是填充色。
                    GlassPlate(RoundedCornerShape(contentPlateRadius)) {
                        Column(
                            Modifier
                                .heightIn(max = maxPanelHeight)
                                .verticalScroll(rememberScrollState())
                                .padding(contentPadding),
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            if (homeSelected) {
                                if (widgets.isEmpty()) {
                                    EmptyHome(editing)
                                } else {
                                    HomeGrid(
                                        widgets = widgets,
                                        editing = editing,
                                        onMove = { from, to ->
                                            widgets = widgets.toMutableList().also { list ->
                                                val moved = list.removeAt(from)
                                                list.add(to.coerceIn(0, list.size), moved)
                                            }
                                        },
                                        onResize = { id, size ->
                                            widgets = widgets.map { if (it.id == id) it.copy(size = size) else it }
                                        },
                                        onDelete = { id -> widgets = widgets.filterNot { it.id == id } },
                                    )
                                }
                            } else {
                                PaneContent(currentPane)
                            }
                        }
                    }
                }
            }
        }

        GlassHarness(
            modifier = Modifier.align(Alignment.BottomCenter),
            screen = glassScreenName(open, homeSelected, editing),
            reducedMotion = reducedMotion,
            onToggleOpen = { open = !open },
            onReducedMotion = { reducedMotion = it },
        )
    }
}

private fun glassScreenName(open: Boolean, homeSelected: Boolean, editing: Boolean): String = when {
    !open -> "挂帘收起"
    editing -> "首页 · 编辑模式"
    homeSelected -> "首页 · 两块板"
    else -> "工作区内容页 · 两块板"
}

/**
 * 打样操作台。
 *
 * 只放这一份打样需要的：开合、减弱动态效果，以及字体状态。
 * 字体那一行是判断截图时机的依据 —— 写「字体已加载」才拍。
 */
@Composable
private fun GlassHarness(
    modifier: Modifier,
    screen: String,
    reducedMotion: Boolean,
    onToggleOpen: () -> Unit,
    onReducedMotion: (Boolean) -> Unit,
) {
    Column(
        modifier
            .padding(16.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Color(0xE61C1C1E))
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("玻璃板组合", color = Color(0xFFF5F5F7), fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
            Text(screen, color = Color(0xFF8E8E93), fontSize = 11.sp)
            Text(LocalPreviewFontStatus.current, color = Color(0xFF8E8E93), fontSize = 11.sp)
        }
        Text(
            "顶栏与内容区是两块独立的玻璃板，中间露出桌面。板与板之间没有投影。",
            color = Color(0xFF8E8E93),
            fontSize = 10.sp,
        )
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            GlassHarnessButton("展开/收起", onToggleOpen)
            GlassHarnessButton(
                if (reducedMotion) "减弱动态效果：开" else "减弱动态效果：关",
            ) { onReducedMotion(!reducedMotion) }
        }
    }
}

@Composable
private fun GlassHarnessButton(label: String, onClick: () -> Unit) {
    Box(
        Modifier
            .height(24.dp)
            .clip(RoundedCornerShape(6.dp))
            .border(1.dp, Color(0x33FFFFFF), RoundedCornerShape(6.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, color = Color(0xFFF5F5F7), fontSize = 10.sp)
    }
}
