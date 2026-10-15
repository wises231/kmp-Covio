import SwiftUI
import kmpDomain

/// 首页的 bento 网格。合同 `component/bento-grid`，`nativeSize` 是 912 × 420。
///
/// 四列，行高 96 点，间距 12 点。卡片的位置由 `BentoPacker` 算，视图只负责画。
///
/// 编辑模式里卡片可拖动、可缩放、可删除。拖动松手后按落点找那一格上的卡片，
/// 两块换顺序——与打样 `HomeGrid` 的判定一致。
struct BentoGrid: View {
    let widgets: [WidgetInstance]
    let isEditing: Bool
    let language: AppLanguage
    let runtime: AppRuntime?
    /// 把第 `from` 块挪到第 `to` 位。
    let onMove: (Int, Int) -> Void
    /// 改一块卡片的档位。
    let onResize: (String, WidgetSize) -> Void
    let onDelete: (String) -> Void

    /// 正在拖动的卡片 id 与累计位移。
    @State private var draggingID: String?
    @State private var dragOffset: CGSize = .zero
    /// 正在缩放的卡片 id、累计位移与起始档位。
    @State private var resizingID: String?
    @State private var resizeOffset: CGSize = .zero
    @State private var resizeBase: WidgetSize = .small

    private var spots: [BentoSpot] { BentoPacker.pack(widgets, columns: HubMetrics.bentoColumns) }
    private var rows: Int { BentoPacker.rows(spots) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(spots, id: \.id) { spot in
                card(for: spot)
            }
        }
        .frame(
            width: HubMetrics.contentColumnWidth,
            height: HubMetrics.bentoGridHeight(rows: rows),
            alignment: .topLeading
        )
    }

    // MARK: - 一块卡片

    private func card(for spot: BentoSpot) -> some View {
        let isDragging = draggingID == spot.id
        return BentoWidgetCard(
            spot: spot,
            title: WidgetCatalog.descriptor(for: spot.kind, language: language).title,
            detail: WidgetDetail.text(
                for: spot.kind,
                runtime: runtime,
                language: language
            ),
            tint: WidgetCatalog.descriptor(for: spot.kind, language: language).tint,
            isEditing: isEditing,
            isDragging: isDragging,
            language: language,
            onDelete: { onDelete(spot.id) },
            onResize: { translation in resize(spot, translation: translation) }
        )
        .offset(
            x: CGFloat(spot.column) * HubMetrics.bentoColumnStep + (isDragging ? dragOffset.width : 0),
            y: CGFloat(spot.row) * HubMetrics.bentoRowStep + (isDragging ? dragOffset.height : 0)
        )
        .zIndex(isDragging ? 1 : 0)
        .gesture(isEditing ? dragGesture(for: spot) : nil)
    }

    // MARK: - 拖动换位

    private func dragGesture(for spot: BentoSpot) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                if draggingID != spot.id {
                    draggingID = spot.id
                    dragOffset = .zero
                }
                dragOffset = value.translation
            }
            .onEnded { _ in
                guard draggingID == spot.id else { return }
                move(spot)
                draggingID = nil
                dragOffset = .zero
            }
    }

    /// 松手的位置换算成格子，再找那一格上是谁。
    private func move(_ spot: BentoSpot) {
        let droppedX = CGFloat(spot.column) * HubMetrics.bentoColumnStep + dragOffset.width
        let droppedY = CGFloat(spot.row) * HubMetrics.bentoRowStep + dragOffset.height
        let centerColumn = Int(
            (droppedX + HubMetrics.bentoCardWidth(columns: spot.size.gridColumns) / 2)
                / HubMetrics.bentoColumnStep
        )
        let centerRow = Int(
            (droppedY + HubMetrics.bentoCardHeight(rows: spot.size.gridRows) / 2)
                / HubMetrics.bentoRowStep
        )

        let target = spots.first { other in
            other.id != spot.id
                && centerColumn >= other.column
                && centerColumn < other.column + other.size.gridColumns
                && centerRow >= other.row
                && centerRow < other.row + other.size.gridRows
        }
        guard let target else { return }
        onMove(spot.order, target.order)
    }

    // MARK: - 缩放改档

    private func resize(_ spot: BentoSpot, translation: CGSize) {
        if resizingID != spot.id {
            resizingID = spot.id
            resizeOffset = .zero
            resizeBase = spot.size
        }
        resizeOffset = translation

        let baseWidth = HubMetrics.bentoCardWidth(columns: resizeBase.gridColumns)
        let baseHeight = HubMetrics.bentoCardHeight(rows: resizeBase.gridRows)
        let columns = Int(((baseWidth + resizeOffset.width) / HubMetrics.bentoColumnStep).rounded())
        let rows = Int(((baseHeight + resizeOffset.height) / HubMetrics.bentoRowStep).rounded())
        let size = BentoPacker.size(
            columns: columns.clamped(to: 1...HubMetrics.bentoColumns),
            rows: rows.clamped(to: 1...HubMetrics.bentoMaxRows)
        )
        guard size.key != spot.size.key else { return }
        onResize(spot.id, size)
    }
}

extension Comparable {
    /// 夹到区间里。缩放时算出来的列数与行数可能越界。
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
