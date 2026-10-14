import SwiftUI

/// 合盖页。
///
/// 顺序：合盖即睡、合盖不睡、充电时不睡、电池规则。
/// 三条规则要改 `pmset`，所以没装 helper 时不可用。
struct LidPage: View {
    let runtime: AppRuntime

    /// 合盖策略要改 `pmset`，所以没装 helper 时这几项不可用。
    private var controlsEnabled: Bool { runtime.helperStatus == .installed }

    var body: some View {
        VStack(alignment: .leading, spacing: MacTheme.space6) {
            MacCard {
                MacSettingRow(title: Copy.copyLidInstantSleep.text(for: runtime.language)) {
                    MacSwitch(
                        label: Copy.copyLidInstantSleep.text(for: runtime.language),
                        isOn: Binding(
                            get: { runtime.config.lidSleepImmediateOnClose },
                            set: { runtime.setImmediateLidSleep($0) }
                        )
                    )
                }
                .settingsRowAnchor(SettingsRowID.lidInstant)
                MacSettingRow(title: Copy.copyLidPreventSleep.text(for: runtime.language)) {
                    MacSwitch(
                        label: Copy.copyLidPreventSleep.text(for: runtime.language),
                        isOn: Binding(
                            get: { !runtime.appState.lidSleepAvailable },
                            set: { _ in runtime.toggleLidSleep() }
                        ),
                        isEnabled: controlsEnabled
                    )
                }
                .settingsRowAnchor(SettingsRowID.lidPrevent)
                MacSettingRow(title: Copy.copyLidPowerRules.text(for: runtime.language)) {
                    MacSwitch(
                        label: Copy.copyLidPowerRules.text(for: runtime.language),
                        isOn: Binding(
                            get: { runtime.config.disableLidSleepInCharging },
                            set: { runtime.setDisableLidWhileCharging($0) }
                        ),
                        isEnabled: controlsEnabled
                    )
                }
                .settingsRowAnchor(SettingsRowID.lidPower)
                MacSettingRow(title: Copy.copyLidBatteryRules.text(for: runtime.language)) {
                    MacSwitch(
                        label: Copy.copyLidBatteryRules.text(for: runtime.language),
                        isOn: Binding(
                            get: { runtime.config.disableLidSleepOnBattery },
                            set: { runtime.setDisableLidOnBattery($0) }
                        ),
                        isEnabled: controlsEnabled
                    )
                }
                .settingsRowAnchor(SettingsRowID.lidBattery)
            }

            if !controlsEnabled {
                MacAlert(
                    message: Copy.copyDialogHelperUnavailableBody.text(for: runtime.language),
                    kind: .warning
                )
            }

            MacAlert(message: Copy.copyLidWarning.text(for: runtime.language), kind: .warning)
        }
    }
}
