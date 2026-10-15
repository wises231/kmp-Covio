import Foundation
import kmpDomain

/// 网格上的一个格子。
struct BentoCell: Hashable {
    let column: Int
    let row: Int
}

/// 网格上落好位置的一块组件。
///
/// 位置由装箱算出来，不落盘。用户存的是组件的顺序，顺序一变位置就重排。
struct BentoSpot: Equatable {
    let id: String
    let kind: String
    let size: WidgetSize
    let column: Int
    let row: Int
    /// 在配置里的序号。拖动换位时用它，不用位置。
    let order: Int
}

/// 组件卡片的装箱。
///
/// 纯函数，不碰视图，也不碰模型。规则照抄打样 `packWidgets`：
/// 按顺序先放先占，一行从左往右找第一个放得下的位置，找不到就换下一行。
///
/// 打样自己标注这条是临时的，真正的排布规则还没定。所以这里也只求稳：
/// 同样的输入永远给同样的输出，卡片不重叠，顺序不丢。
enum BentoPacker {
    /// 把组件按顺序摆进网格。
    ///
    /// 宽度超过列数的组件按列数收窄，不然找不到位置会一直往下加行。
    static func pack(_ widgets: [WidgetInstance], columns: Int) -> [BentoSpot] {
        guard columns > 0 else { return [] }

        var occupied: Set<BentoCell> = []
        var spots: [BentoSpot] = []

        for (order, widget) in widgets.enumerated() {
            let width = min(widget.size.gridColumns, columns)
            let height = widget.size.gridRows
            var row = 0

            while true {
                let column = (0...(columns - width)).first { candidate in
                    (0..<height).allSatisfy { offsetY in
                        (0..<width).allSatisfy { offsetX in
                            !occupied.contains(BentoCell(column: candidate + offsetX, row: row + offsetY))
                        }
                    }
                }

                guard let column else {
                    row += 1
                    continue
                }

                for offsetY in 0..<height {
                    for offsetX in 0..<width {
                        occupied.insert(BentoCell(column: column + offsetX, row: row + offsetY))
                    }
                }
                spots.append(
                    BentoSpot(
                        id: widget.id,
                        kind: widget.kind,
                        size: widget.size,
                        column: column,
                        row: row,
                        order: order
                    )
                )
                break
            }
        }

        return spots
    }

    /// 网格一共几行。
    static func rows(_ spots: [BentoSpot]) -> Int {
        spots.map { $0.row + $0.size.gridRows }.max() ?? 0
    }

    /// 列数与行数换成档位。与打样 `sizeOf` 一致。
    static func size(columns: Int, rows: Int) -> WidgetSize {
        if columns >= 2, rows >= 2 { return .large }
        if columns >= 2 { return .wide }
        if rows >= 2 { return .tall }
        return .small
    }
}

extension WidgetSize {
    /// 占几列。小 1，宽 2，高 1，大 2。
    var gridColumns: Int {
        switch key {
        case "wide", "large": 2
        default: 1
        }
    }

    /// 占几行。小 1，宽 1，高 2，大 2。
    var gridRows: Int {
        switch key {
        case "tall", "large": 2
        default: 1
        }
    }

    /// 按序列化键找档位。认不出的键回退到模型给的兜底档。
    static func from(key: String) -> WidgetSize {
        WidgetSize.entries.first { $0.key == key } ?? WidgetSize.companion.FALLBACK
    }
}
