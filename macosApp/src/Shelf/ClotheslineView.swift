import AppKit
import SwiftUI
import kmpDomain

/// 晾衣线：一根绳子，挂着若干张截图卡片。
///
/// 对应 Compose 版 `app/src/com/wyz/covio/app/ui/ShelfWindow.kt` 的 `ShelfContent`。
///
/// 面板宽等于鼠标所在屏幕的宽度，高是 `ShelfLayout.PANEL_HEIGHT`。
/// 绳子的形状、卡片的位置、夹子的位置都由 `ShelfLayout` 算，这里只负责画。
struct ClotheslineView: View {
    let items: [ShelfItem]
    /// 面板宽度。等于屏幕宽度，也就是绳子的长度。
    let containerWidth: CGFloat
    let reduceMotion: Bool
    let language: AppLanguage
    /// 正在飞进来的那张卡片的路径。没有就是空。
    let flyingPath: String?

    let onCopy: (ShelfItem) -> Void
    let onPreview: (ShelfItem) -> Void
    let onMarkup: (ShelfItem) -> Void
    let onRemove: (ShelfItem) -> Void
    /// 把这张截图存入工作区。没有工作区时传空，菜单里就不出现这一项。
    let onSaveToWorkspace: ((ShelfItem) -> Void)?
    let onDragBegin: (ShelfItem, NSView, NSEvent) -> Void
    /// 鼠标进入或离开面板。控制器据此决定什么时候收起。
    let onPointerInside: (Bool) -> Void

    private var layout: ShelfLayout { ShelfLayout.shared }

    /// 超出容量的卡片不显示。容量由屏幕宽度决定。
    private var visibleItems: [ShelfItem] {
        let capacity = Int(layout.capacity(screenWidth: Float(containerWidth)))
        return Array(items.suffix(capacity))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RopeView(containerWidth: containerWidth)
                .allowsHitTesting(false)

            if visibleItems.isEmpty {
                emptyToast
            }

            ForEach(Array(visibleItems.enumerated()), id: \.element.path) { index, item in
                card(item: item, index: index)
                clothespin(index: index)
            }
        }
        .frame(width: containerWidth, height: CGFloat(layout.PANEL_HEIGHT), alignment: .topLeading)
        .contentShape(Rectangle())
        .onHover(perform: onPointerInside)
    }

    private func card(item: ShelfItem, index: Int) -> some View {
        let count = Int32(visibleItems.count)
        let slot = layout.slotX(index: Int32(index), count: count, screenWidth: Float(containerWidth))
        let ropeY = layout.ropeY(x: slot, screenWidth: Float(containerWidth))
        let cardX = CGFloat(slot) - CGFloat(layout.CARD_WIDTH) / 2
        let cardY = CGFloat(ropeY) + CGFloat(layout.CARD_TOP_OFFSET)

        return ScreenshotCardView(
            item: item,
            index: Int32(index),
            reduceMotion: reduceMotion,
            language: language,
            flying: flyingPath == item.path,
            onCopy: { onCopy(item) },
            onPreview: { onPreview(item) },
            onMarkup: { onMarkup(item) },
            onRemove: { onRemove(item) },
            onDragBegin: { view, event in onDragBegin(item, view, event) },
            onSaveToWorkspace: onSaveToWorkspace.map { save in { save(item) } }
        )
        .offset(x: cardX, y: cardY)
    }

    private func clothespin(index: Int) -> some View {
        let count = Int32(visibleItems.count)
        let slot = layout.slotX(index: Int32(index), count: count, screenWidth: Float(containerWidth))
        let ropeY = layout.ropeY(x: slot, screenWidth: Float(containerWidth))
        let pinX = CGFloat(slot) - CGFloat(layout.CLOTHESPIN_WIDTH) / 2
        let pinY = CGFloat(ropeY) - CGFloat(layout.CLOTHESPIN_ABOVE_ROPE)

        return ClothespinView()
            .offset(x: pinX, y: pinY)
    }

    private var emptyToast: some View {
        Text(Copy.copyTopShelfNone.text(for: language))
            .font(.system(size: 12))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: Double(MacTheme.mediumRadius), style: .continuous)
                    .fill(MacTheme.elevated.opacity(0.96))
            )
            .shadow(color: .black.opacity(0.30), radius: 8, y: 3)
            .frame(width: containerWidth, alignment: .top)
            .offset(y: 70)
            .allowsHitTesting(false)
    }
}

/// 绳子。
///
/// 三遍描边叠出立体感，与 Compose 版一致：
/// 一遍黑色阴影下移 1.4 点，一遍深灰渐变，一遍白色高光上移 1.1 点。
///
/// 绳子在两端回到基准高度，在中间垂到最低。形状由 `ShelfLayout.ropeY` 给。
struct RopeView: View {
    let containerWidth: CGFloat

    /// 采样段数。段数越多越平滑，64 段在 6K 宽屏上也看不出折线。
    private static let steps = 64
    /// 阴影与高光相对绳子的偏移量。
    private static let shadowOffset: CGFloat = 1.4
    private static let highlightOffset: CGFloat = -1.1

    var body: some View {
        Canvas { context, size in
            let width = max(containerWidth, 1)

            context.stroke(
                path(offset: Self.shadowOffset),
                with: .color(.black.opacity(0.18)),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            context.stroke(
                path(offset: 0),
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color(red: 0.169, green: 0.169, blue: 0.180).opacity(0.60), location: 0.08),
                        .init(color: Color(red: 0.169, green: 0.169, blue: 0.180).opacity(0.90), location: 0.50),
                        .init(color: Color(red: 0.169, green: 0.169, blue: 0.180).opacity(0.60), location: 0.92),
                        .init(color: .clear, location: 1),
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: width, y: 0)
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            context.stroke(
                path(offset: Self.highlightOffset),
                with: .color(.white.opacity(0.42)),
                style: StrokeStyle(lineWidth: 0.75, lineCap: .round)
            )
            _ = size
        }
        .allowsHitTesting(false)
    }

    /// 绳子的路径，整体上下平移 `offset` 点。
    private func path(offset: CGFloat) -> Path {
        let width = max(containerWidth, 1)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: CGFloat(ShelfLayout.shared.ropeY(x: 0, screenWidth: Float(width))) + offset))
        for index in 1...Self.steps {
            let x = width * CGFloat(index) / CGFloat(Self.steps)
            let y = CGFloat(ShelfLayout.shared.ropeY(x: Float(x), screenWidth: Float(width)))
            path.addLine(to: CGPoint(x: x, y: y + offset))
        }
        return path
    }
}
