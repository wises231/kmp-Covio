import SwiftUI

/// 顶部挂帘页。
///
/// 顺序：挂帘开关、接管开关、音效、剪切板设置。
/// 剪切板的面板挂在挂帘上，所以剪切板设置属于本节。
///
/// 截图挂帘本体属于 P3。本阶段这几个开关只写配置，行为在 P3 接上。
/// 所以这里明确写出「暂未生效」，避免用户以为坏了。
struct TopShelfPage: View {
    let runtime: AppRuntime

    var body: some View {
        VStack(alignment: .leading, spacing: MacTheme.space6) {
            MacCard {
                MacSettingRow(title: ContractCopy.copyTopShelfEnabled.text(for: runtime.language)) {
                    MacSwitch(
                        label: ContractCopy.copyTopShelfEnabled.text(for: runtime.language),
                        isOn: Binding(
                            get: { runtime.config.shelfEnabled },
                            set: { runtime.setShelfEnabled($0) }
                        )
                    )
                }
                .settingsRowAnchor(SettingsRowID.topShelfEnabled)
                MacSettingRow(title: ContractCopy.copyTopShelfTakeOver.text(for: runtime.language)) {
                    MacSwitch(
                        label: ContractCopy.copyTopShelfTakeOver.text(for: runtime.language),
                        isOn: Binding(
                            get: { runtime.config.screenshotInboxEnabled },
                            set: { runtime.setScreenshotInbox($0) }
                        )
                    )
                }
                .settingsRowAnchor(SettingsRowID.topShelfTakeOver)
                MacSettingRow(title: ContractCopy.copyTopShelfSounds.text(for: runtime.language)) {
                    MacSwitch(
                        label: ContractCopy.copyTopShelfSounds.text(for: runtime.language),
                        isOn: Binding(
                            get: { runtime.config.shelfSoundsEnabled },
                            set: { runtime.setShelfSounds($0) }
                        )
                    )
                }
                .settingsRowAnchor(SettingsRowID.topShelfSounds)
            }

            ClipboardCard(runtime: runtime)

            MacAlert(message: ContractCopy.copyTopShelfPendingNotice.text(for: runtime.language), kind: .info)
        }
    }
}
