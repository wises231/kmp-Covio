import AppKit
import SwiftUI
import kmpDomain

/// 一张截图卡片。
///
/// 对应 Compose 版 `app/src/com/wyz/covio/app/ui/ShelfWindow.kt` 的 `ShelfCard`。
///
/// 尺寸与位置由 `ShelfLayout` 决定，卡片自己只管画和响应操作。
/// 状态机是 `ShelfVisualState`，动效参数是 `shelfMotionPlan`。
struct ScreenshotCardView: View {
    let item: ShelfItem
    let index: Int32
    let reduceMotion: Bool
    let language: AppLanguage
    /// 这张卡片是不是正从屏幕外飞进来。
    let flying: Bool

    let onCopy: () -> Void
    let onPreview: () -> Void
    let onMarkup: () -> Void
    /// 卡片落到底了，可以真的移除。不是用户点「移除」的那一刻。
    let onRemove: () -> Void
    /// 用户开始拖这张卡片。参数是发起拖拽的视图与触发它的鼠标事件。
    let onDragBegin: (NSView, NSEvent) -> Void

    @State private var visualState: ShelfVisualState
    @State private var pointerOver = false
    @State private var breezeTarget: CGFloat = 0
    @State private var image: NSImage?

    init(
        item: ShelfItem,
        index: Int32,
        reduceMotion: Bool,
        language: AppLanguage,
        flying: Bool,
        onCopy: @escaping () -> Void,
        onPreview: @escaping () -> Void,
        onMarkup: @escaping () -> Void,
        onRemove: @escaping () -> Void,
        onDragBegin: @escaping (NSView, NSEvent) -> Void
    ) {
        self.item = item
        self.index = index
        self.reduceMotion = reduceMotion
        self.language = language
        self.flying = flying
        self.onCopy = onCopy
        self.onPreview = onPreview
        self.onMarkup = onMarkup
        self.onRemove = onRemove
        self.onDragBegin = onDragBegin
        _visualState = State(initialValue: flying ? .flying : .default)
    }

    private var layout: ShelfLayout { ShelfLayout.shared }

    private var plan: ShelfMotionPlan {
        shelfMotionPlan(state: visualState, reduceMotion: reduceMotion)
    }

    /// 卡片自身的倾斜加当前状态的角度增量加微风。
    private var rotation: Double {
        Double(layout.tiltDegrees(index: index))
            + Double(plan.rotationAdjustmentDegrees)
            + Double(breezeTarget)
    }

    var body: some View {
        cardBody
            .frame(width: CGFloat(layout.CARD_WIDTH), height: CGFloat(layout.CARD_HEIGHT))
            .rotationEffect(.degrees(rotation))
            .scaleEffect(plan.scale)
            .opacity(Double(plan.opacity))
            .offset(y: CGFloat(plan.verticalOffset))
            .animation(
                .interpolatingSpring(
                    stiffness: Double(ShelfMotionSpec.scaleSpringStiffness),
                    damping: Double(ShelfMotionSpec.scaleSpringDamping)
                ),
                value: plan.scale
            )
            .animation(
                .interpolatingSpring(
                    stiffness: Double(ShelfMotionSpec.rotationSpringStiffness),
                    damping: Double(ShelfMotionSpec.rotationSpringDamping)
                ),
                value: plan.rotationAdjustmentDegrees
            )
            .animation(
                .linear(duration: plan.fallAnimationEnabled ? ShelfMotionSpec.fallingSeconds : fadeSeconds),
                value: plan.opacity
            )
            .animation(
                plan.fallAnimationEnabled
                    ? .easeOut(duration: ShelfMotionSpec.fallingSeconds)
                    : .linear(duration: fadeSeconds),
                value: plan.verticalOffset
            )
            .animation(.easeOut(duration: ShelfMotionSpec.breezeSwingSeconds), value: breezeTarget)
            .task(id: item.path) { await loadImage() }
            .task(id: breezeKey) { await runBreeze() }
            .task(id: stateKey) { await runStateDwell() }
            .accessibilityElement()
            .accessibilityLabel(cardDescription)
    }

    /// 卡片的辅助功能描述。
    ///
    /// 四个动作连起来读，最后跟文件路径。与 Compose 版的 `contentDescription` 同序。
    private var cardDescription: String {
        [
            ContractCopy.copyTopShelfActionCopy.text(for: language),
            ContractCopy.copyTopShelfActionPreview.text(for: language),
            ContractCopy.copyTopShelfActionMarkup.text(for: language),
            ContractCopy.copyTopShelfActionRemoveFromShelf.text(for: language),
        ].joined(separator: ", ") + ": " + item.path
    }

    /// 退出与进入动画的时长。减弱动态效果时用短的那一档。
    private var fadeSeconds: TimeInterval {
        reduceMotion ? ShelfMotionSpec.reducedMotionSeconds : ShelfMotionSpec.stateChangeSeconds
    }

    /// 微风任务的重启键。摆动开关一变就重启。
    private var breezeKey: String {
        "\(item.path)#\(plan.breezeEnabled)"
    }

    /// 停留任务的重启键。状态一变就重启。
    private var stateKey: String {
        "\(visualState.rawValue)#\(reduceMotion)"
    }

    private var cardBody: some View {
        ZStack(alignment: .topLeading) {
            photo
            // 交互层盖住整张卡片。点击、双击、长按、右键、拖拽都由它接管。
            // 它必须放在菜单按钮下面，否则按钮收不到点击。
            CardInteractionView(
                onPress: { pressed in
                    if pressed {
                        visualState = .pressed
                    } else if visualState == .pressed {
                        visualState = pointerOver ? .hover : .default
                    }
                },
                onHover: { inside in
                    pointerOver = inside
                    if inside, visualState == .default {
                        visualState = .hover
                    } else if !inside, visualState == .hover {
                        visualState = .default
                    }
                },
                onClick: {
                    visualState = .copied
                    onCopy()
                },
                onDoubleClick: onPreview,
                onLongPress: onMarkup,
                onDragBegin: onDragBegin,
                menuProvider: { menuProvider() }
            )
            menuButton
            if visualState == .copied {
                toast
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Double(layout.CARD_RADIUS), style: .continuous)
                .fill(MacTheme.surface)
        )
        .clipShape(RoundedRectangle(cornerRadius: Double(layout.CARD_RADIUS), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Double(layout.CARD_RADIUS), style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.24), radius: visualState == .hover ? 11 : 8, y: 4)
    }

    /// 右键菜单。原生菜单，与访达和其他应用里的右键菜单一致。
    private func menuProvider() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(menuItem(ContractCopy.copyTopShelfActionCopy.text(for: language)) { [self] in
            visualState = .copied
            onCopy()
        })
        menu.addItem(menuItem(ContractCopy.copyTopShelfActionPreview.text(for: language)) { [self] in onPreview() })
        menu.addItem(menuItem(ContractCopy.copyTopShelfActionMarkup.text(for: language)) { [self] in onMarkup() })
        menu.addItem(.separator())
        // 只切状态。真的移除在卡片落到底之后，这样用户看得见卡片掉下去。
        menu.addItem(menuItem(ContractCopy.copyTopShelfActionRemoveFromShelf.text(for: language)) { [self] in
            visualState = .falling
        })
        return menu
    }

    private func menuItem(_ title: String, action: @escaping () -> Void) -> NSMenuItem {
        MenuActionItem(title: title, handler: action)
    }

    private var photo: some View {
        Group {
            if let image {
                let fitted = layout.fitImageSize(
                    imageWidth: Int32(image.size.width),
                    imageHeight: Int32(image.size.height),
                    maxWidth: layout.PHOTO_MAX_WIDTH,
                    maxHeight: layout.PHOTO_MAX_HEIGHT
                )
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: CGFloat(fitted.width), height: CGFloat(fitted.height))
                    .clipShape(
                        RoundedRectangle(cornerRadius: Double(MacTheme.mediumRadius), style: .continuous)
                    )
            } else {
                // 读不出图片时留一块灰底。卡片仍然占位、仍然可点。
                RoundedRectangle(cornerRadius: Double(MacTheme.mediumRadius), style: .continuous)
                    .fill(Color(red: 0.898, green: 0.898, blue: 0.918))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(CGFloat(layout.CARD_PADDING))
    }

    private var menuButton: some View {
        Menu {
            Button(ContractCopy.copyTopShelfActionCopy.text(for: language)) {
                visualState = .copied
                onCopy()
            }
            Button(ContractCopy.copyTopShelfActionPreview.text(for: language), action: onPreview)
            Button(ContractCopy.copyTopShelfActionMarkup.text(for: language), action: onMarkup)
            Divider()
            Button(ContractCopy.copyTopShelfActionRemoveFromShelf.text(for: language)) { visualState = .falling }
        } label: {
            Text("⋯")
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.black.opacity(0.70)))
                .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 26, height: 26)
        .offset(x: CGFloat(layout.CARD_WIDTH) - 32, y: 6)
        .accessibilityLabel("\(ContractCopy.copyTopShelfActionPreview.text(for: language)): \(item.path)")
    }

    private var toast: some View {
        Text(ContractCopy.copyTopShelfActionCopy.text(for: language))
            .font(.system(size: 12))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: Double(MacTheme.mediumRadius), style: .continuous)
                    .fill(MacTheme.elevated.opacity(0.96))
            )
            .shadow(color: .black.opacity(0.30), radius: 8, y: 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .offset(y: -8)
            .allowsHitTesting(false)
    }

    /// 读图片。后台读字节，回主线程建 `NSImage`。
    private func loadImage() async {
        let path = item.path
        let data = await Task.detached(priority: .userInitiated) {
            try? Data(contentsOf: URL(fileURLWithPath: path))
        }.value
        guard !Task.isCancelled, let data else { return }
        image = NSImage(data: data)
    }

    /// 常态下的微风。隔一段随机时间摆一下，摆完回到零。
    ///
    /// 不摆动时直接返回。任务被取消时也退出，不会留下还在跑的循环。
    private func runBreeze() async {
        guard plan.breezeEnabled else {
            breezeTarget = 0
            return
        }
        while !Task.isCancelled {
            let wait = Double.random(
                in: ShelfMotionSpec.breezeMinSeconds...ShelfMotionSpec.breezeMaxSeconds
            )
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            guard !Task.isCancelled else { return }
            let degrees = CGFloat.random(
                in: ShelfMotionSpec.breezeMinDegrees...ShelfMotionSpec.breezeMaxDegrees
            )
            breezeTarget = Bool.random() ? degrees : -degrees
            try? await Task.sleep(
                nanoseconds: UInt64(ShelfMotionSpec.breezeHoldSeconds * 1_000_000_000)
            )
            guard !Task.isCancelled else { return }
            breezeTarget = 0
        }
    }

    /// 复制提示与下落这两个状态会自己结束。
    ///
    /// 复制提示到时回到悬停或常态。下落到时才真的移除，这样用户看得见卡片掉下去。
    private func runStateDwell() async {
        switch visualState {
        case .copied:
            try? await Task.sleep(
                nanoseconds: UInt64(ShelfMotionSpec.copyToastSeconds * 1_000_000_000)
            )
            guard !Task.isCancelled, visualState == .copied else { return }
            visualState = pointerOver ? .hover : .default
        case .falling:
            let dwell = plan.fallAnimationEnabled
                ? ShelfMotionSpec.fallingSeconds
                : ShelfMotionSpec.reducedMotionSeconds
            try? await Task.sleep(nanoseconds: UInt64(dwell * 1_000_000_000))
            guard !Task.isCancelled else { return }
            onRemove()
        default:
            return
        }
    }
}

/// 右键菜单里的一项。`NSMenuItem` 的 target/action 需要 Objective-C 对象，
/// 所以用一个小类把 Swift 闭包包起来。
final class MenuActionItem: NSMenuItem {
    private let handler: () -> Void

    init(title: String, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(invoke), keyEquivalent: "")
        target = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("MenuActionItem 不支持从归档创建")
    }

    @objc private func invoke() {
        handler()
    }
}
