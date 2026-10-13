import XCTest
import kmpDomain
@testable import Covio

/// 晾衣线几何：合同对照、与孔位不变量。
///
/// 几何只有一份实现，在 `kmpDomain` 的 `ShelfLayout`。SwiftUI 侧通过 framework 调它。
/// 算得对不对由 `ShelfLogicTest.kt` 在 JVM 上验证。这里验证三件只有 Swift 侧才看得见的事：
///
/// 1. framework 导出的接口在 Swift 里调得通，返回的数值与 JVM 侧一致。
/// 2. 合同给的 `nativeSize` 与这份几何对不对得上。
/// 3. 卡片放不放得进面板和屏幕。
final class ShelfGeometryContractTests: XCTestCase {
    private static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private let layout = ShelfLayout.shared

    /// 从最小到 6K 的屏幕宽度。步长 8 能踩到所有 164 的整数倍边界。
    private static let widths = Array(stride(from: 600, through: 6016, by: 8))

    private func components() throws -> [String: [String: Any]] {
        let url = Self.repoRoot.appendingPathComponent("docs/covio-design-contract.json")
        let data = try Data(contentsOf: url)
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(root["components"] as? [String: [String: Any]])
    }

    private func nativeSize(_ key: String) throws -> (width: Double, height: Double) {
        let component = try XCTUnwrap(try components()[key], "合同里没有 \(key)")
        let size = try XCTUnwrap(component["nativeSize"] as? [String: Any])
        return (
            try XCTUnwrap(size["width"] as? Double),
            try XCTUnwrap(size["height"] as? Double)
        )
    }

    private func contractVariants(_ key: String) throws -> Set<String> {
        let component = try XCTUnwrap(try components()[key], "合同里没有 \(key)")
        return Set(try XCTUnwrap(component["variants"] as? [String]))
    }

    // MARK: - 合同一致

    /// 晾衣夹与合同完全一致。两个方向都断言，改任何一边都会失败。
    func testClothespinMatchesTheContract() throws {
        let size = try nativeSize("component/clothespin")
        XCTAssertEqual(Double(layout.CLOTHESPIN_WIDTH), size.width, accuracy: 0.001)
        XCTAssertEqual(Double(layout.CLOTHESPIN_HEIGHT), size.height, accuracy: 0.001)
    }

    /// 夹子跨在绳子上。
    ///
    /// 夹子中心落在绳子上，所以夹子上半截露在绳上方。
    /// 露出的高度必须小于夹子总高，否则夹子会整根浮在绳子上面。
    func testClothespinStraddlesTheRope() {
        XCTAssertGreaterThan(layout.CLOTHESPIN_ABOVE_ROPE, 0)
        XCTAssertLessThan(layout.CLOTHESPIN_ABOVE_ROPE, layout.CLOTHESPIN_HEIGHT)
    }

    /// 夹子的实际位置满足上面那条关系。
    func testClothespinBoundsStraddleTheRope() {
        for width in Self.widths {
            let count = Int(layout.capacity(screenWidth: Float(width)))
            for index in 0..<count {
                let bounds = layout.clothespinBounds(
                    index: Int32(index), count: Int32(count), screenWidth: Float(width)
                )
                let rope = layout.ropeY(
                    x: layout.slotX(index: Int32(index), count: Int32(count), screenWidth: Float(width)),
                    screenWidth: Float(width)
                )
                XCTAssertLessThan(bounds.top, rope, "屏幕宽 \(width) 第 \(index) 个夹子在绳子下方")
                XCTAssertGreaterThan(bounds.bottom, rope, "屏幕宽 \(width) 第 \(index) 个夹子在绳子上方")
                XCTAssertEqual(bounds.width, layout.CLOTHESPIN_WIDTH, accuracy: 0.001)
                XCTAssertEqual(bounds.height, layout.CLOTHESPIN_HEIGHT, accuracy: 0.001)
            }
        }
    }

    // MARK: - 合同冲突

    /// **已知差异一：** 合同说截图卡片是 150 × 200，运行期用的是 144 × 112。
    ///
    /// 这条用例不改行为，只把冲突钉住。合同值或运行期值任何一边变了它都会失败，
    /// 那时必须重新做一次明确的决定，不能让两边继续不一致。
    ///
    /// 为什么运行期不用 200 高：
    /// - 面板高 210 点，来自 README 的 "The toolbar height is 210 points"。
    /// - 绳子最低点在 20 + 最大下垂 58 = 78 点，卡片顶边再下移 4 点。
    /// - 200 高的卡片底边会落到 282 点，超出面板 72 点。
    ///
    /// 结论：合同的 `nativeSize` 记的是 Figma 里组件的画框尺寸，不是运行期尺寸。
    /// M5 与 Figma 文件核对后，把这条写进 `metadata.knownDifferences`。
    func testScreenshotCardContractSizeDiffersFromRuntime() throws {
        let size = try nativeSize("component/screenshot-card")
        XCTAssertEqual(size.width, 150, accuracy: 0.001, "合同值变了，重新评估这条已知差异")
        XCTAssertEqual(size.height, 200, accuracy: 0.001, "合同值变了，重新评估这条已知差异")

        XCTAssertEqual(Double(layout.CARD_WIDTH), 144, accuracy: 0.001)
        XCTAssertEqual(Double(layout.CARD_HEIGHT), 112, accuracy: 0.001)
    }

    /// **已知差异二：** 卡片状态比合同少两个。
    ///
    /// 合同 `component/screenshot-card` 的 `variants` 有 `SELECTED` 与 `DISABLED`。
    /// 晾衣线上的卡片既不能选中也不能禁用，所以运行期没有这两个状态。
    /// 合同 `component/clothespin` 的 `DISABLED` 同理。
    ///
    /// 反过来，`FLYING` 与 `FALLING` 是运行期的过渡态，合同没有。
    /// 两边各自多出的部分必须正好是这两组，多一个都要在这里说明原因。
    func testCardStatesMatchTheContractExceptForTheDocumentedGaps() throws {
        var contractStates = try contractVariants("component/screenshot-card")
        contractStates.formUnion(try contractVariants("component/clothespin"))
        let runtimeStates = Set(ShelfVisualState.allCases.map(\.rawValue))

        XCTAssertEqual(
            contractStates.subtracting(runtimeStates),
            ["SELECTED", "DISABLED"],
            "合同里有运行期没有的状态，只有这两个是有意的"
        )
        XCTAssertEqual(
            runtimeStates.subtracting(contractStates),
            ["FLYING", "FALLING"],
            "运行期多出的状态只能是飞行与下落两个过渡态"
        )
    }

    // MARK: - 竖直方向装得下

    /// 卡片必须整张落在面板里。
    ///
    /// 绳子下垂到最低点时卡片底边也必须在面板内。这条是产品要求：
    /// 卡片被裁掉一截就点不到、也拖不动。
    func testCardFitsInsideThePanelVertically() {
        for width in Self.widths {
            let count = Int(layout.capacity(screenWidth: Float(width)))
            for index in 0..<count {
                let bounds = layout.cardBounds(
                    index: Int32(index), count: Int32(count), screenWidth: Float(width)
                )
                XCTAssertLessThanOrEqual(
                    bounds.bottom, layout.PANEL_HEIGHT,
                    "屏幕宽 \(width) 第 \(index) 张卡片底边 \(bounds.bottom) 超出面板 \(layout.PANEL_HEIGHT)"
                )
                XCTAssertGreaterThanOrEqual(bounds.top, 0)
            }
        }
    }

    /// 卡片挂在绳子下方。夹子夹住卡片上沿，所以卡片顶边紧贴绳子。
    func testCardsHangBelowTheRope() {
        for width in Self.widths {
            let count = Int(layout.capacity(screenWidth: Float(width)))
            for index in 0..<count {
                let bounds = layout.cardBounds(
                    index: Int32(index), count: Int32(count), screenWidth: Float(width)
                )
                let rope = layout.ropeY(
                    x: layout.slotX(index: Int32(index), count: Int32(count), screenWidth: Float(width)),
                    screenWidth: Float(width)
                )
                XCTAssertGreaterThan(bounds.top, rope, "屏幕宽 \(width) 第 \(index) 张卡片没有挂在绳子下方")
                XCTAssertEqual(
                    bounds.top - rope, layout.CARD_TOP_OFFSET, accuracy: 0.001,
                    "卡片顶边到绳子的距离应当正好是 CARD_TOP_OFFSET"
                )
            }
        }
    }

    /// 绳子在屏幕中间垂得最低，在两端回到基准高度。
    func testRopeSagsInTheMiddleOnly() {
        for width in Self.widths {
            let half = Float(width) / 2
            XCTAssertEqual(layout.ropeY(x: 0, screenWidth: Float(width)), layout.ROPE_BASE_Y, accuracy: 0.001)
            XCTAssertEqual(
                layout.ropeY(x: Float(width), screenWidth: Float(width)),
                layout.ROPE_BASE_Y, accuracy: 0.001
            )
            XCTAssertEqual(
                layout.ropeY(x: half, screenWidth: Float(width)),
                layout.ROPE_BASE_Y + layout.sag(screenWidth: Float(width)), accuracy: 0.001
            )
        }
    }

    /// 下垂量有上限，且屏幕越宽下垂越多直到上限。
    func testSagIsBounded() {
        XCTAssertEqual(layout.sag(screenWidth: 0), 0, accuracy: 0.001)
        XCTAssertEqual(layout.sag(screenWidth: -100), 0, accuracy: 0.001)
        XCTAssertEqual(layout.sag(screenWidth: .nan), 0, accuracy: 0.001)
        XCTAssertEqual(layout.sag(screenWidth: .infinity), 0, accuracy: 0.001)
        for width in Self.widths {
            let sag = layout.sag(screenWidth: Float(width))
            XCTAssertGreaterThanOrEqual(sag, 0)
            XCTAssertLessThanOrEqual(sag, layout.MAX_SAG)
        }
        XCTAssertEqual(
            layout.sag(screenWidth: 100_000), layout.MAX_SAG, accuracy: 0.001,
            "屏幕足够宽时下垂量应当到上限"
        )
    }

    // MARK: - 水平方向

    /// 卡片之间不能重叠，否则后面的卡片点不到。
    func testCardsNeverOverlap() {
        for width in Self.widths {
            let count = Int(layout.capacity(screenWidth: Float(width)))
            let bounds = (0..<count).map {
                layout.cardBounds(index: Int32($0), count: Int32(count), screenWidth: Float(width))
            }
            for index in 1..<count {
                XCTAssertGreaterThanOrEqual(
                    bounds[index].left, bounds[index - 1].right,
                    "屏幕宽 \(width) 第 \(index) 张压住了前一张"
                )
            }
        }
    }

    /// **已知缺陷：** 屏幕不够宽时最外侧的卡片会伸出屏幕。
    ///
    /// `capacity` 按 `screenWidth / SPACING + 1` 算张数。这个式子算的是
    /// 「中心间距塞得下几张」，没有给两端的卡片各留半个卡宽。
    /// 于是 `(n-1) * SPACING + CARD_WIDTH > screenWidth` 时两端各溢出一截，
    /// 溢出量最多半个卡宽，也就是 72 点。
    ///
    /// 实测值：
    /// - 1512 宽（14 吋 MacBook Pro 默认）：10 张，两端各溢出 54 点。
    /// - 1728 宽（16 吋 MacBook Pro 默认）：11 张，两端各溢出 28 点。
    /// - 2048 宽及以上：不溢出。
    ///
    /// 这条用例不断言「不溢出」，因为现在会溢出。它断言溢出量不超过半个卡宽。
    /// 这样修好之后用例仍然通过，但下面两个实测值会失败，逼着改这里。
    /// 修法是一行：`capacity` 的分母改成 `screenWidth - CARD_WIDTH`。
    /// 那会同时改到 Compose 宿主的出货行为，所以留给人决定，不在迁移里顺手改。
    func testOuterCardsOverhangIsRecorded() {
        var worstOverhang: CGFloat = 0
        for width in Self.widths {
            let count = Int(layout.capacity(screenWidth: Float(width)))
            let first = layout.cardBounds(index: 0, count: Int32(count), screenWidth: Float(width))
            let last = layout.cardBounds(
                index: Int32(count - 1), count: Int32(count), screenWidth: Float(width)
            )
            worstOverhang = max(worstOverhang, CGFloat(-first.left), CGFloat(last.right) - CGFloat(width))
        }
        XCTAssertLessThanOrEqual(
            worstOverhang, CGFloat(layout.CARD_WIDTH) / 2,
            "溢出量超过了半个卡宽，说明 capacity 的算法变了"
        )
        XCTAssertEqual(worstOverhang, 72, accuracy: 0.5, "最坏溢出量变了，更新上面的实测值")

        // 两个真实机型的实测值，写死在这里，改动时会被挡住。
        let fourteenInch = Int(layout.capacity(screenWidth: 1512))
        XCTAssertEqual(fourteenInch, 10)
        XCTAssertEqual(
            Double(-layout.cardBounds(index: 0, count: Int32(fourteenInch), screenWidth: 1512).left),
            54, accuracy: 0.5
        )
        let sixteenInch = Int(layout.capacity(screenWidth: 1728))
        XCTAssertEqual(sixteenInch, 11)
        XCTAssertEqual(
            Double(-layout.cardBounds(index: 0, count: Int32(sixteenInch), screenWidth: 1728).left),
            28, accuracy: 0.5
        )
    }

    // MARK: - 张数

    /// 张数夹在 `MIN_CAPACITY` 与 `ShelfStore.MAX_ITEMS` 之间，异常输入退回下限。
    func testCapacityStaysWithinBounds() {
        XCTAssertEqual(layout.MIN_CAPACITY, 3)
        XCTAssertEqual(layout.MAX_CAPACITY, 12)
        XCTAssertEqual(layout.MAX_CAPACITY, ShelfStore.companion.MAX_ITEMS, "布局上限与存储上限必须一致")
        XCTAssertEqual(layout.capacity(screenWidth: 0), layout.MIN_CAPACITY)
        XCTAssertEqual(layout.capacity(screenWidth: -1), layout.MIN_CAPACITY)
        XCTAssertEqual(layout.capacity(screenWidth: .nan), layout.MIN_CAPACITY)
        XCTAssertEqual(layout.capacity(screenWidth: .infinity), layout.MIN_CAPACITY)
        for width in Self.widths {
            let count = layout.capacity(screenWidth: Float(width))
            XCTAssertGreaterThanOrEqual(count, layout.MIN_CAPACITY)
            XCTAssertLessThanOrEqual(count, layout.MAX_CAPACITY)
        }
    }

    // MARK: - 点击命中

    /// 卡片中心点必须命中这张卡片。`cardIndexAt` 是点击与拖拽的入口，算错就点不中。
    func testCardCenterHitsItsOwnCard() {
        for width in Self.widths {
            let count = Int(layout.capacity(screenWidth: Float(width)))
            for index in 0..<count {
                let bounds = layout.cardBounds(
                    index: Int32(index), count: Int32(count), screenWidth: Float(width)
                )
                let hit = layout.cardIndexAt(
                    x: bounds.left + bounds.width / 2,
                    y: bounds.top + bounds.height / 2,
                    count: Int32(count), screenWidth: Float(width)
                )
                XCTAssertEqual(
                    hit?.int32Value, Int32(index),
                    "屏幕宽 \(width) 第 \(index) 张卡片中心没命中自己"
                )
            }
        }
    }

    /// 面板底部的空白处点不到任何卡片。
    func testEmptyAreaHitsNothing() {
        let count = Int32(layout.capacity(screenWidth: 1728))
        XCTAssertNil(
            layout.cardIndexAt(x: 864, y: layout.PANEL_HEIGHT - 1, count: count, screenWidth: 1728),
            "卡片下方的空白不该命中"
        )
        XCTAssertNil(layout.cardIndexAt(x: 864, y: 0, count: 0, screenWidth: 1728), "没有卡片时不该命中")
    }

    // MARK: - 图片缩放

    /// 图片按比例缩放到照片区里，长边贴边，短边留白。
    ///
    /// `maxWidth` 与 `maxHeight` 必须显式传。Kotlin 的默认参数不会导出到 Swift，
    /// 漏传时编译器不会报错，只能收到一对零。零会被当成非法输入，
    /// 于是函数退回照片区大小，看起来「能跑」但缩放比例全错。
    func testImageFitsThePhotoAreaWithoutDistortion() {
        let maxWidth = layout.PHOTO_MAX_WIDTH
        let maxHeight = layout.PHOTO_MAX_HEIGHT

        let wide = layout.fitImageSize(
            imageWidth: 3024, imageHeight: 1964, maxWidth: maxWidth, maxHeight: maxHeight
        )
        XCTAssertEqual(
            Double(wide.width) / Double(wide.height),
            3024.0 / 1964.0,
            accuracy: 0.01,
            "宽高比必须保持"
        )
        XCTAssertEqual(Double(wide.width), Double(maxWidth), accuracy: 0.01, "长边贴边")

        let tall = layout.fitImageSize(
            imageWidth: 1000, imageHeight: 4000, maxWidth: maxWidth, maxHeight: maxHeight
        )
        XCTAssertEqual(Double(tall.height), Double(maxHeight), accuracy: 0.01, "长边贴边")

        for (width, height) in [(3024, 1964), (1000, 4000), (1, 1), (160, 120), (9000, 9000)] {
            let fitted = layout.fitImageSize(
                imageWidth: Int32(width), imageHeight: Int32(height),
                maxWidth: maxWidth, maxHeight: maxHeight
            )
            XCTAssertLessThanOrEqual(fitted.width, maxWidth + 0.01, "\(width)×\(height) 超出照片区")
            XCTAssertLessThanOrEqual(fitted.height, maxHeight + 0.01, "\(width)×\(height) 超出照片区")
        }
    }

    /// 缩放比例恰好等于照片区与图片的较短边之比。
    func testImageScaleIsTheSmallerOfTheTwoRatios() {
        let fitted = layout.fitImageSize(
            imageWidth: 400, imageHeight: 200,
            maxWidth: layout.PHOTO_MAX_WIDTH, maxHeight: layout.PHOTO_MAX_HEIGHT
        )
        // 400 × 200 按宽度缩到 136 时高度只有 68，比 104 矮，所以宽度是限制边。
        XCTAssertEqual(Double(fitted.width), Double(layout.PHOTO_MAX_WIDTH), accuracy: 0.01)
        XCTAssertEqual(Double(fitted.height), 68, accuracy: 0.01)
    }

    /// 图片尺寸非法时退回照片区大小，不返回负数或零。
    func testBadImageSizeFallsBackToThePhotoArea() {
        for (width, height) in [(0, 100), (100, 0), (-1, -1)] {
            let fitted = layout.fitImageSize(
                imageWidth: Int32(width), imageHeight: Int32(height),
                maxWidth: layout.PHOTO_MAX_WIDTH, maxHeight: layout.PHOTO_MAX_HEIGHT
            )
            XCTAssertEqual(fitted.width, layout.PHOTO_MAX_WIDTH, accuracy: 0.001)
            XCTAssertEqual(fitted.height, layout.PHOTO_MAX_HEIGHT, accuracy: 0.001)
        }
    }

    /// **踩坑记录：** 上下限传零会静默退回照片区大小，不报错。
    ///
    /// Kotlin 的默认参数不导出到 Swift。Swift 侧漏传上下限时只能写零，
    /// 而零是非法输入，函数就退回照片区大小。结果是每张图都按 136 × 104 摆，
    /// 宽高比全错，但编译和运行都不报错。
    ///
    /// 这条用例把这个行为写下来：调用点必须显式传 `PHOTO_MAX_WIDTH` 与 `PHOTO_MAX_HEIGHT`。
    func testZeroLimitsSilentlyFallBackInsteadOfFailing() {
        let zeroed = layout.fitImageSize(
            imageWidth: 3024, imageHeight: 1964, maxWidth: 0, maxHeight: 0
        )
        XCTAssertEqual(zeroed.width, layout.PHOTO_MAX_WIDTH, accuracy: 0.001)
        XCTAssertEqual(zeroed.height, layout.PHOTO_MAX_HEIGHT, accuracy: 0.001)
        XCTAssertNotEqual(
            Double(zeroed.width) / Double(zeroed.height),
            3024.0 / 1964.0,
            accuracy: 0.01,
            "退回照片区大小会丢掉宽高比，所以上下限不能漏传"
        )
    }

    // MARK: - 倾斜

    /// 倾斜角在合同声明的区间内，并且按固定花样循环。
    ///
    /// 花样固定是刻意的：卡片不能每次重画都换一个角度，那样会自己抖。
    func testTiltIsBoundedAndDeterministic() {
        XCTAssertEqual(layout.MIN_TILT_DEGREES, -2.5, accuracy: 0.001)
        XCTAssertEqual(layout.MAX_TILT_DEGREES, 2.5, accuracy: 0.001)
        let pattern = (0..<8).map { layout.tiltDegrees(index: Int32($0)) }
        for (index, tilt) in pattern.enumerated() {
            XCTAssertGreaterThanOrEqual(tilt, layout.MIN_TILT_DEGREES, "第 \(index) 个角度太小")
            XCTAssertLessThanOrEqual(tilt, layout.MAX_TILT_DEGREES, "第 \(index) 个角度太大")
        }
        for index in 0..<24 {
            XCTAssertEqual(
                layout.tiltDegrees(index: Int32(index)),
                pattern[index % pattern.count],
                "第 \(index) 个角度没有按花样循环"
            )
        }
        XCTAssertEqual(layout.tiltDegrees(index: -5), pattern[0], "负数下标退回第一个角度")
    }

    // MARK: - 卡片尺寸

    /// 照片区加内边距等于卡片尺寸。图片按比例缩放到照片区里。
    func testCardIsThePhotoAreaPlusPadding() {
        XCTAssertEqual(
            layout.PHOTO_MAX_WIDTH + layout.CARD_PADDING * 2,
            layout.CARD_WIDTH, accuracy: 0.001
        )
        XCTAssertEqual(
            layout.PHOTO_MAX_HEIGHT + layout.CARD_PADDING * 2,
            layout.CARD_HEIGHT, accuracy: 0.001
        )
        XCTAssertEqual(layout.CARD_RADIUS, 16, accuracy: 0.001)
    }
}
