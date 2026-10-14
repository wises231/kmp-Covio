import AppKit
import SwiftUI

/// Hub 面板的根视图。
///
/// 面板窗口的尺寸是固定的展开尺寸。展开与收起只改内容的高度，
/// 所以视觉上是一条从顶部垂下来的窗帘。
///
/// 卡片分两栏：左边是悬浮导航栏，右边是顶部胶囊加页内容。
/// 两栏之间留 `HubMetrics.columnGap`，卡片内边距是 `HubMetrics.cardPadding`。
///
/// 这个视图不持有控制器，只接收值。这样它可以被预览与测试。
struct HubView: View {
    let geometry: ScreenGeometry
    let isExpanded: Bool
    let reduceMotion: Bool
    let hubState: HubState
    let outputState: HubOutputState
    @Binding var selection: HubTab
    /// 外壳的共享状态。搜索文字与设置分节住在这里。
    @Bindable var chrome: HubChromeModel
    let runtime: AppRuntime?

    /// 切换界面语言。默认什么都不做，预览与测试不必接。
    var onLanguage: (AppLanguage) -> Void = { _ in }
    /// 退出应用。退出不可逆，所以只在这里转达，判断在调用方。
    var onQuit: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // 刘海屏要让开刘海那一条。非刘海屏这里是 0。
            Color.clear
                .frame(height: geometry.panelTopInset)

            card
                .frame(height: isExpanded ? cardHeight : 0)
                .opacity(cardOpacity)
                .clipped()

            Spacer(minLength: 0)
        }
        .frame(
            width: geometry.expandedRect(contentHeight: cardHeight).width,
            height: geometry.expandedRect(contentHeight: cardHeight).height,
            alignment: .top
        )
        .animation(curtainAnimation, value: isExpanded)
    }

    /// 内容高度由页签决定。设置页比占位页高。
    /// 面板窗口的高度由控制器按同一个值设置，两边必须一致。
    private var cardHeight: CGFloat {
        HubMetrics.contentHeight(for: selection)
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
    private var language: AppLanguage { runtime?.language ?? CopyLocale.language }

    /// 引擎在跑。导航栏底部的呼吸灯用它。
    private var isActive: Bool { runtime?.config.enabled ?? false }

    private var card: some View {
        // 导航栏与胶囊都是玻璃。放进同一个容器，两块的边缘才会互相融合。
        GlassEffectContainer(spacing: MacTheme.space2) {
            HStack(alignment: .top, spacing: HubMetrics.columnGap) {
                HubNavRail(
                    selection: $selection,
                    chrome: chrome,
                    language: language,
                    isActive: isActive,
                    reduceMotion: reduceMotion,
                    onLanguage: onLanguage,
                    onQuit: onQuit
                )

                VStack(alignment: .leading, spacing: HubMetrics.pageGap) {
                    capsule
                    pageContent
                        .frame(
                            width: HubMetrics.contentColumnWidth,
                            height: HubMetrics.pageContentHeight(for: selection),
                            alignment: .topLeading
                        )
                        // 搜索结果浮在页内容上方。搜索框在左栏，结果贴在右栏看。
                        .overlay(alignment: .topLeading) { searchResults }
                }
                .frame(width: HubMetrics.contentColumnWidth, alignment: .topLeading)
            }
        }
        .padding(HubMetrics.cardPadding)
        .frame(width: HubMetrics.cardWidth, height: cardHeight, alignment: .top)
        .background(.regularMaterial)
        .clipShape(cardShape)
        .overlay(cardShape.strokeBorder(Color.primary.opacity(0.12), lineWidth: HubMetrics.borderWidth))
        .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
        // 高亮行从环境里取，六个设置页不必各自拿一遍模型。
        .environment(\.highlightedSettingsRow, chrome.highlightedRowID)
    }

    /// 搜索框有字的时候显示结果。
    @ViewBuilder
    private var searchResults: some View {
        if !chrome.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            SettingsSearchResults(chrome: chrome, language: language) { hit in
                selection = .settings
                chrome.reveal(hit)
            }
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: MacTheme.cardRadius, style: .continuous)
    }

    // MARK: - 顶部胶囊

    /// 设置页的胶囊只放六个分节：内容列放不下页标题加六个分节。
    /// 选中的分节本身就是标题，所以设置页不再另放标题。
    @ViewBuilder
    private var capsule: some View {
        if selection == .settings {
            HubToolbarCapsule(title: nil, summary: nil) {
                SettingsSectionSegments(section: $chrome.settingsSection, language: language)
            }
        } else {
            HubToolbarCapsule(
                title: selection.title.text(for: language),
                summary: selection.summary.text(for: language)
            ) {
                capsuleActions
            }
        }
    }

    /// 胶囊右侧的动作。没有动作的页签留空。
    @ViewBuilder
    private var capsuleActions: some View {
        if let runtime {
            switch selection {
            case .screenshots:
                ScreenshotsCapsuleActions(shelf: runtime.shelf, language: language)
            case .clipboard:
                ClipboardCapsuleActions(clipboard: runtime.clipboard, language: language)
            case .files:
                FilesCapsuleActions(workspace: runtime.workspace, language: language)
            default:
                EmptyView()
            }
        }
    }

    // MARK: - 页内容

    @ViewBuilder
    private var pageContent: some View {
        HubTabContent(
            tab: selection,
            chrome: chrome,
            hubState: hubState,
            outputState: outputState,
            language: language,
            runtime: runtime
        )
    }
}

/// 页签内容的分发。
///
/// 设置页、截图页、剪切板页与文件页已经有真实内容。其余两个页签还是占位。
/// 运行时缺失时（预览、测试）一律显示占位。
struct HubTabContent: View {
    let tab: HubTab
    let chrome: HubChromeModel
    let hubState: HubState
    let outputState: HubOutputState
    let language: AppLanguage
    let runtime: AppRuntime?

    var body: some View {
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
/// 三个还没落地的页签显示模块说明，证明页签切换生效。
/// 页标题与说明在顶部胶囊里，所以这里只剩提示语。
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
                Text(Copy.copyHubPlaceholderNotice.text(for: language))
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
