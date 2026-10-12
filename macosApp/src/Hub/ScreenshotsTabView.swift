import SwiftUI
import kmpDomain

/// 截图页签。
///
/// 结构与全宽工具栏面板共用同一套几何：把 `ShelfLayout` 的 `screenWidth`
/// 换成这里的容器宽度，绳子的形状与卡片的位置就跟着算出来。
///
/// 面板里那块区域是可交互的（Hub 本身不接受鼠标穿透），
/// 所以这里的卡片能点、能拖、能右键，与工具栏上的卡片行为一致。
///
/// 三个模块级动作在顶部胶囊里，见 `ScreenshotsCapsuleActions`。
struct ScreenshotsTabView: View {
    let shelf: ShelfRuntime
    /// 界面语言。晾衣线上的卡片按它取文案。
    let language: AppLanguage

    private var layout: ShelfLayout { ShelfLayout.shared }

    var body: some View {
        clothesline
            .padding(.horizontal, MacTheme.space4)
            .padding(.vertical, MacTheme.space3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// 横向晾衣线。上下各留一点空隙，卡片边缘的阴影才不会被切掉。
    private var clothesline: some View {
        ClotheslineView(
            items: shelf.items,
            containerWidth: Self.areaWidth,
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
            language: language,
            flyingPath: shelf.flyingPath,
            onCopy: { shelf.copyItem($0) },
            onPreview: { shelf.openItem($0) },
            onMarkup: { shelf.markupItem($0) },
            onRemove: { shelf.removeItem($0) },
            onDragBegin: { item, view, event in
                shelf.beginDrag(item: item, from: view, event: event)
            },
            onPointerInside: { _ in }
        )
        .frame(width: Self.areaWidth, height: Self.areaHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: MacTheme.mediumRadius, style: .continuous)
                .fill(MacTheme.surface)
        )
        .clipShape(RoundedRectangle(cornerRadius: MacTheme.mediumRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MacTheme.mediumRadius, style: .continuous)
                .strokeBorder(MacTheme.divider, lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }

    /// 晾衣线区域的宽度。等于右栏内容宽度减去左右内边距。
    ///
    /// 卡片按这个宽度居中排布，所以 Hub 里也能看到绳子的下垂。
    ///
    /// 标 `nonisolated` 是因为 `HubMetrics`（非隔离）要用它算内容高度。
    nonisolated static var areaWidth: CGFloat {
        HubMetrics.contentColumnWidth - MacTheme.space4 * 2
    }

    /// 晾衣线区域的高度。与独立面板一样高。
    nonisolated static var areaHeight: CGFloat { CGFloat(ShelfLayout.shared.PANEL_HEIGHT) }
}

/// 截图页的胶囊动作：打开目录、清空、显示或隐藏工具条。
///
/// 这三个动作各对应 Compose 版托盘菜单里的一项。原先在页内容底部，
/// 搬到胶囊后晾衣线区域占满整页。
struct ScreenshotsCapsuleActions: View {
    let shelf: ShelfRuntime
    let language: AppLanguage

    var body: some View {
        HStack(spacing: MacTheme.space2) {
            MacButton(title: ContractCopy.copyTopShelfActionOpenFolder.text(for: language)) {
                shelf.openScreenshotDirectory()
            }
            MacButton(
                title: ContractCopy.copyTopShelfActionClearAll.text(for: language),
                isEnabled: !shelf.items.isEmpty
            ) {
                shelf.clearItems()
            }
            MacButton(
                title: shelf.isVisible
                    ? ContractCopy.copyTopShelfActionHideToolbar.text(for: language)
                    : ContractCopy.copyTopShelfActionShowToolbar.text(for: language)
            ) {
                shelf.toggle()
            }
            MacStatusLine(text: "\(shelf.items.count) / \(ShelfStoreClient.maxItems)")
        }
    }
}
