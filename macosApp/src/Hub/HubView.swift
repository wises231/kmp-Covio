import AppKit
import SwiftUI
import kmpDomain

/// Hub 面板的根视图。
///
/// 面板窗口的尺寸是固定的展开尺寸。展开与收起只改内容的高度，
/// 所以视觉上是一条从顶部垂下来的窗帘。
///
/// 面板是两块独立的玻璃板：上面是胶囊形的顶栏 46 点，下面是圆角矩形的内容板。
/// 两块板之间留一条 11 点的缝，缝里露出桌面。顶栏板与菜单栏之间再留一条同宽的缝。
/// 板与板之间没有投影 —— 层次由 Liquid Glass 的镜面亮边给。
///
/// 内容板自带 24 点内边距，里面是「页标题行 + 主体」。
/// 首页没有页标题行，直接从组件网格开始。
///
/// 这个视图不持有控制器，只接收值。这样它可以被预览与测试。
struct HubView: View {
    let geometry: ScreenGeometry
    let isExpanded: Bool
    let reduceMotion: Bool
    let hubState: HubState
    let outputState: HubOutputState
    @Bindable var workbench: WorkbenchModel
    /// 外壳的共享状态。搜索文字与设置分节住在这里。
    @Bindable var chrome: HubChromeModel
    let runtime: AppRuntime?

    var body: some View {
        VStack(spacing: 0) {
            // 刘海屏要让开刘海那一条。非刘海屏这里是 0。
            Color.clear
                .frame(height: geometry.panelTopInset)

            // 顶栏板与菜单栏之间的缝。排在卡片外面：进了卡片的话，挂帘收起时会
            // 先露出一条空缝，再露出顶栏板。
            Color.clear
                .frame(height: HubMetrics.plateTopInset)

            plates
                .frame(height: isExpanded ? plateStackHeight : 0)
                .opacity(cardOpacity)
                .clipped()

            Spacer(minLength: 0)
        }
        .frame(
            width: geometry.expandedRect(contentHeight: panelHeight).width,
            height: geometry.expandedRect(contentHeight: panelHeight).height,
            alignment: .top
        )
        .animation(curtainAnimation, value: isExpanded)
    }

    /// 两块玻璃板加起来的高度。卡片的 frame 用它。
    private var plateStackHeight: CGFloat {
        HubMetrics.plateStackHeight(for: HubPage.current(workbench), editing: workbench.isEditing)
    }

    /// 面板窗口的高度：两块板加上与菜单栏之间的缝。
    ///
    /// 面板窗口的高度由控制器按同一个值设置，两边必须一致。
    private var panelHeight: CGFloat {
        HubMetrics.contentHeight(for: HubPage.current(workbench), editing: workbench.isEditing)
    }

    /// 减弱动态效果时只改透明度，不做位移。
    private var cardOpacity: Double {
        guard reduceMotion else { return 1 }
        return isExpanded ? 1 : 0
    }

    private var curtainAnimation: Animation {
        if reduceMotion {
            return .linear(duration: HubMotion.reducedMotion)
        }
        return isExpanded
            ? .spring(response: HubMotion.expand, dampingFraction: 0.82)
            : .easeOut(duration: HubMotion.collapse)
    }

    /// 当前界面语言。运行时缺失时（预览、测试）跟随系统。
    private var language: AppLanguage { runtime?.language ?? workbench.language }

    // MARK: - 玻璃板

    /// 面板的两块玻璃板：上面是胶囊形的顶栏，下面是圆角矩形的内容。
    ///
    /// 控制中心没有统一背板，是一组独立的玻璃板直接浮在桌面上，板与板之间露出
    /// 桌面。所以这里不画背景、不描边、不加投影 —— 三样都由 Liquid Glass 自己画。
    ///
    /// `spacing` 取 0 而不是 `plateGap`：容器里间距小于 `spacing` 的两块玻璃会
    /// **合并成一块**，那就毁掉了「两块板」这个形态本身。取 0 表示只有贴在一起
    /// 才合并。
    private var plates: some View {
        GlassEffectContainer(spacing: 0) {
            VStack(spacing: HubMetrics.plateGap) {
                topBarPlate
                contentPlate
            }
        }
        // 高亮行从环境里取，六个设置页不必各自拿一遍模型。
        .environment(\.highlightedSettingsRow, chrome.highlightedRowID)
    }

    private var topBarPlate: some View {
        WorkbenchTabBar(
            panes: workbench.panes,
            destination: workbench.destination,
            isEditing: workbench.isEditing,
            searchText: $chrome.searchText,
            language: language,
            pageAction: workbench.pageAction,
            onHome: { workbench.destination = .home },
            onSelect: { workbench.select(paneID: $0) },
            onReorder: { workbench.movePane(from: $0, to: $1) },
            onPageAction: { workbench.performPageAction() }
        )
        .glassSurface(cornerRadius: HubMetrics.tabBarPlateRadius)
    }

    private var contentPlate: some View {
        contentColumn
            .frame(height: contentPlateHeight)
            .glassSurface(cornerRadius: HubMetrics.contentPlateRadius)
    }

    /// 内容板的高度：两块板的总高减去顶栏板与中间的缝。
    ///
    /// 撑不出高度的话板会缩成内容那么大，与顶栏板宽度对不齐。
    private var contentPlateHeight: CGFloat {
        plateStackHeight - HubMetrics.tabBarHeight - HubMetrics.plateGap
    }

    // MARK: - 内容列

    private var contentColumn: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: HubMetrics.pageGap) {
                if workbench.isEditing {
                    EditBanner(
                        paneCount: workbench.visiblePaneCount,
                        widgetCount: workbench.homeWidgets.count,
                        language: language
                    ) { workbench.isEditing = false }
                }

                if isSearching {
                    SettingsSearchResults(chrome: chrome, language: language) { hit in
                        workbench.destination = .pane(id: PaneKind.settings.defaultId)
                        chrome.reveal(hit)
                    }
                } else {
                    pageContent
                }
            }
            .padding(HubMetrics.panelPadding)
            .frame(width: HubMetrics.panelWidth, alignment: .topLeading)
        }
        .scrollIndicators(.never)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    /// 搜索框有字的时候整列换成结果，与打样一致。
    private var isSearching: Bool {
        !chrome.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - 页内容

    @ViewBuilder
    private var pageContent: some View {
        switch workbench.destination {
        case .home:
            homeContent
        case .pane(let id):
            HubTabContent(
                tab: workbench.tab(for: workbench.destination),
                paneID: id,
                workbench: workbench,
                chrome: chrome,
                hubState: hubState,
                outputState: outputState,
                language: language,
                runtime: runtime
            )
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        if workbench.homeWidgets.isEmpty {
            EmptyHomeView(isEditing: workbench.isEditing, language: language)
        } else {
            BentoGrid(
                widgets: workbench.homeWidgets,
                isEditing: workbench.isEditing,
                language: language,
                runtime: runtime,
                onMove: { workbench.moveWidget(from: $0, to: $1) },
                onResize: { id, size in workbench.resizeWidget(id: id, to: size) },
                onDelete: { workbench.removeWidget(id: $0) }
            )
        }
    }
}

/// 首页为空时的提示。
struct EmptyHomeView: View {
    let isEditing: Bool
    let language: AppLanguage

    var body: some View {
        VStack(spacing: MacTheme.space2) {
            Text(ContractCopy.copyHubHomeEmptyTitle.text(for: language))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(MacTheme.textPrimary)
            Text(hint)
                .font(.system(size: 11))
                .foregroundStyle(MacTheme.textSecondary)
        }
        .frame(width: HubMetrics.contentColumnWidth, height: HubMetrics.emptyHomeHeight)
        .background(
            Color.primary.opacity(0.06),
            in: RoundedRectangle(cornerRadius: HubMetrics.bentoCardRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HubMetrics.bentoCardRadius, style: .continuous)
                .strokeBorder(MacTheme.divider, lineWidth: 1)
        )
    }

    private var hint: String {
        let copy = isEditing
            ? ContractCopy.copyHubHomeEmptyHintEditing
            : ContractCopy.copyHubHomeEmptyHint
        return copy.text(for: language)
    }
}

/// 页签内容的分发。
///
/// 设置页、截图页、剪切板页与文件页已经有真实内容。其余页签还是占位。
/// 运行时缺失时（预览、测试）一律显示占位。
struct HubTabContent: View {
    let tab: HubTab
    let paneID: String
    let workbench: WorkbenchModel
    let chrome: HubChromeModel
    let hubState: HubState
    let outputState: HubOutputState
    let language: AppLanguage
    let runtime: AppRuntime?

    var body: some View {
        VStack(alignment: .leading, spacing: HubMetrics.pageGap) {
            if let heading = workbench.heading(for: .pane(id: paneID)) {
                PaneHeading(title: heading.title, summary: heading.summary) {
                    headingActions
                }
            }

            body(width: HubMetrics.contentColumnWidth)
                .frame(
                    width: HubMetrics.contentColumnWidth,
                    height: HubMetrics.bodyHeight(for: .pane(tab)),
                    alignment: .topLeading
                )
        }
    }

    /// 页标题行右端的动作。原来在顶部胶囊里，胶囊没了就搬到这里。
    @ViewBuilder
    private var headingActions: some View {
        if let runtime {
            switch tab {
            case .screenshots:
                ScreenshotsHeadingActions(shelf: runtime.shelf, language: language)
            case .clipboard:
                ClipboardHeadingActions(clipboard: runtime.clipboard, language: language)
            case .files:
                FilesHeadingActions(workspace: runtime.workspace, language: language)
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func body(width: CGFloat) -> some View {
        if let runtime, tab == .settings {
            SettingsTabView(runtime: runtime, section: chrome.settingsSection, chrome: chrome)
        } else if let runtime, tab == .screenshots {
            ScreenshotsTabView(
                shelf: runtime.shelf,
                language: language,
                onSaveToWorkspace: { item in _ = runtime.workspace.save(filesAt: [item.path]) }
            )
        } else if let runtime, tab == .clipboard {
            ClipboardTabView(clipboard: runtime.clipboard, runtime: runtime)
        } else if let runtime, tab == .files {
            FilesTabView(workspace: runtime.workspace, language: language)
        } else {
            HubPlaceholderView(
                tab: tab,
                hubState: hubState,
                outputState: outputState,
                language: language
            )
        }
    }
}

/// 页签内容的占位。
///
/// 还没落地的页签显示模块说明，证明页签切换生效。
/// `#if DEBUG` 的那段是插桩 HUD，对应风险清单 R2：
/// 手工验证面板行为时常显 `hubState`、内容态与前台应用。
struct HubPlaceholderView: View {
    let tab: HubTab
    let hubState: HubState
    let outputState: HubOutputState
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: MacTheme.space3) {
            MacCard {
                Text(ContractCopy.copyHubPlaceholderNotice.text(for: language))
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.textSecondary)
            }

            Spacer(minLength: 0)

            #if DEBUG
            Divider()
            Text(hud)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
            #endif
        }
        .padding(.horizontal, MacTheme.space4)
        .padding(.vertical, MacTheme.space3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    #if DEBUG
    private var hud: String {
        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "-"
        return """
        tab=\(tab.rawValue) hub=\(hubState.rawValue) output=\(outputState.rawValue)
        frontmost=\(frontmost)
        """
    }
    #endif
}
