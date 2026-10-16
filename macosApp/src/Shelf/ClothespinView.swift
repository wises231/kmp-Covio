import SwiftUI
import kmpDomain

/// 晾衣夹。夹在绳子上，也用作品牌标记。
///
/// 对应 Compose 版 `app/src/com/wyz/covio/app/ui/MacComponents.kt` 的 `Clothespin`。
/// 尺寸是 9 × 26 点。
///
/// **与 Compose 版的差别：** Kotlin 那份在 9dp × 26dp 的画布上用裸像素画
/// （`Offset(2.6f, 0.8f)` 这类），2 倍屏上这些数字只有一半大小，
/// 夹子会被画成半个尺寸并且偏在左上角。这里按 9 × 26 的比例画，
/// 在 2 倍屏上也是填满整块。
struct ClothespinView: View {
    /// 夹子主体颜色。默认跟随主题的主文字色。
    var ink: Color = MacTheme.textPrimary

    var body: some View {
        Canvas { context, _ in
            let body = ink.opacity(0.92)

            // 主体：一根细长的竖条。
            context.fill(
                Path(
                    roundedRect: CGRect(x: 2.6, y: 0.8, width: 3.8, height: 24.4),
                    cornerRadius: 1.8
                ),
                with: .color(body)
            )

            // 高光：主体偏左的一条竖线，让夹子看起来是圆的。
            var highlight = Path()
            highlight.move(to: CGPoint(x: 3.4, y: 3.2))
            highlight.addLine(to: CGPoint(x: 3.4, y: 22.2))
            context.stroke(
                highlight,
                with: .color(.white.opacity(0.75)),
                style: StrokeStyle(lineWidth: 0.8, lineCap: .round)
            )

            // 弹簧：横在中段的那一小块。
            context.fill(
                Path(
                    roundedRect: CGRect(x: 1.2, y: 10.5, width: 6.6, height: 4.2),
                    cornerRadius: 1.4
                ),
                with: .color(body)
            )
        }
        .frame(
            width: CGFloat(ShelfLayout.shared.CLOTHESPIN_WIDTH),
            height: CGFloat(ShelfLayout.shared.CLOTHESPIN_HEIGHT)
        )
        .allowsHitTesting(false)
    }
}
