import AppKit

/// 菜单栏状态项。§4.3 把菜单栏图标列为 macOS 的次级入口。
///
/// 图标与无障碍名称来自设计合同 `states.menuBarAndNotchHub.statusItemStates`
/// 的 DEFAULT 项：SF Symbol `menubar.rectangle`，文案键 `copy/status-item/default`。
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let shell: NotchShellController
    /// 运行时。菜单里的命令直接调它，与设置页走同一批方法。
    private let runtime: AppRuntime?
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    init(shell: NotchShellController, runtime: AppRuntime? = nil) {
        self.shell = shell
        self.runtime = runtime
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureButton()
        configureMenu()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        let image = NSImage(
            systemSymbolName: Self.defaultSymbolName,
            accessibilityDescription: ContractCopy.copyStatusItemDefault.text
        )
        image?.isTemplate = true
        button.image = image
        button.imagePosition = .imageOnly
        button.toolTip = ContractCopy.copyStatusItemDefault.text
        // 合同 `component/tray-icon` 的 accessibilityRules 要求交互目标不小于 24 点。
        button.setAccessibilityLabel(ContractCopy.copyStatusItemDefault.text)
    }

    private func configureMenu() {
        menu.delegate = self
        menu.autoenablesItems = false

        let showItem = NSMenuItem(
            title: ContractCopy.copyTopShelfShow.text,
            action: #selector(showShelf),
            keyEquivalent: ""
        )
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: ContractCopy.copyTrayActionSettings.text,
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: ContractCopy.copyTrayActionQuit.text,
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func tearDown() {
        statusItem.menu = nil
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    /// 合同的 `component/tray-icon` 变体里 DEFAULT 对应的 SF Symbol。
    private static let defaultSymbolName = "menubar.rectangle"

    // MARK: - 菜单动作

    /// 显示挂帘。挂帘本体属于 P3，这里先打开 Hub 的截图页。
    @objc private func showShelf() {
        shell.selection = .screenshots
        shell.show()
    }

    @objc private func openSettings() {
        shell.selection = .settings
        shell.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
