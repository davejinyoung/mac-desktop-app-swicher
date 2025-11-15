import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsStore.shared
    @State private var showPopover: Bool = false
    @State private var isEditing = false
    @EnvironmentObject var appState: AppState
    @State private var showingPopover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Switch Apps Shortcut:")
                Spacer()
                Button("\(iconForModifierFlags(CGEventFlags(rawValue: UInt64(settings.shortcutModifierRaw))))\(iconForKeyCode(settings.shortcutKey))") {
                    appState.isChoosingShortcut = true
                }
                .popover(isPresented: $appState.isChoosingShortcut, attachmentAnchor: .rect(.bounds), arrowEdge: .trailing) {
                   VStack {
                       Text("Choose any modifier + key")
                           .font(.callout)
                   }
                   .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                   .padding()
               }
            }
            HStack {
                Text("Quit App Key:")
                Spacer()
                Button("\(iconForKeyCode(settings.quitAppKey))"){}
            }
            HStack {
                Text("New App Window Key:")
                Spacer()
                Button("\(iconForKeyCode(settings.newAppWindowKey))"){}
            }
            HStack {
                Text("Panel size:")
                Spacer()
                Slider(
                    value: $appState.appIconSize,
                    in: 40...200,
                    onEditingChanged: { editing in
                        isEditing = editing
                    }
                )
                .onChange(of: isEditing) {
                    isEditing ? appState.showPanel() : appState.panel.orderOut(nil)
                    SettingsStore.shared.appIconSize = appState.appIconSize
                }
            }
        }
        .padding(32)
        .frame(minWidth: 320, maxWidth: .infinity, minHeight: 220, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    SettingsView()
}
