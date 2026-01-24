import SwiftUI

struct ShortcutSettingRow: View {
    let label: String
    let buttonLabel: String
    let modifyingProperty: String
    let popoverMessage: String
    @EnvironmentObject var appState: AppState
    let onButtonTap: () -> Void

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Button(buttonLabel) {
                onButtonTap()
            }
            .popover(
                isPresented: Binding(
                    get: { appState.settings.isModifying && appState.settings.modifyingProperty == modifyingProperty },
                    set: { newValue in
                        if !newValue {
                            DispatchQueue.main.async {
                                appState.settings.isModifying = false
                                appState.settings.modifyingProperty = nil
                            }
                        }
                    }
                ),
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .trailing
            ) {
                VStack {
                    Text(popoverMessage)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .padding(1)
                }
                .frame(maxWidth: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(12)
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings = SettingsStore.shared
    @State private var isEditing = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ShortcutSettingRow(
                label: "Switch Apps Shortcut:",
                buttonLabel: "\(iconForModifierFlags(CGEventFlags(rawValue: UInt64(settings.shortcutModifierRaw))))\(iconForKeyCode(settings.shortcutKey))",
                modifyingProperty: "cycle",
                popoverMessage: "Choose any modifier + key",
                onButtonTap: {
                    appState.settings.isModifying = true
                    appState.settings.modifyingProperty = "cycle"
                }
            )
            .environmentObject(appState)
            
            ShortcutSettingRow(
                label: "Quit App Key:",
                buttonLabel: "\(iconForKeyCode(settings.quitAppKey))",
                modifyingProperty: "quit",
                popoverMessage: "Choose any key to quit the currently selected app",
                onButtonTap: {
                    appState.settings.isModifying = true
                    appState.settings.modifyingProperty = "quit"
                }
            )
            .environmentObject(appState)
            
            ShortcutSettingRow(
                label: "Close Window Key:",
                buttonLabel: "\(iconForKeyCode(settings.closeWindowKey))",
                modifyingProperty: "close",
                popoverMessage: "Choose any key to close the frontmost window of the currently selected app",
                onButtonTap: {
                    appState.settings.isModifying = true
                    appState.settings.modifyingProperty = "close"
                }
            )
            .environmentObject(appState)
            
            ShortcutSettingRow(
                label: "New App Window Key:",
                buttonLabel: "\(iconForKeyCode(settings.newAppWindowKey))",
                modifyingProperty: "new",
                popoverMessage: "Choose any key to open a new window of the currently selected app",
                onButtonTap: {
                    appState.settings.isModifying = true
                    appState.settings.modifyingProperty = "new"
                }
            )
            .environmentObject(appState)
            
            HStack {
                Text("Show Apps from All Desktops")
                Spacer()
                Toggle(isOn: $settings.appsFromAllDeskops) {}
                .toggleStyle(.switch)
            }
            
            HStack {
                Text("Allow Continuous App Cycling")
                Spacer()
                Toggle(isOn: $settings.continuousCycling) {}
                .toggleStyle(.switch)
            }
            
            HStack {
                Text("Switch Windows when Cycling Apps")
                Spacer()
                Toggle(isOn: $settings.switchWindowsWhileCycling) {}
                .toggleStyle(.switch)
            }
            
            HStack {
                Text("Preview Windows on Panel")
                Spacer()
                Toggle(isOn: $settings.previewWindows) {}
                .toggleStyle(.switch)
            }
            
            HStack {
                Text("Show All Windows of Each App")
                Spacer()
                Toggle(isOn: $settings.showAllWindows) {}
                .toggleStyle(.switch)
            }
            
            HStack {
                Text("Activate All Windows of Each App")
                Spacer()
                Toggle(isOn: $settings.activateAllWindows) {}
                .toggleStyle(.switch)
            }
            
            HStack {
                Text("Panel Size:")
                Spacer()
                Slider(
                    value: $appState.appIconSize,
                    in: 40...200,
                    onEditingChanged: { editing in
                        isEditing = editing
                    }
                )
                .onChange(of: isEditing) {
                    Task {
                        await appState.fetchRunningApps()
                        isEditing && !SettingsStore.shared.previewWindows ? appState.showPanel() : appState.panel.orderOut(nil)
                        SettingsStore.shared.appIconSize = appState.appIconSize
                    }
                }
            }
        }
        .padding(32)
        .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    SettingsView()
}
