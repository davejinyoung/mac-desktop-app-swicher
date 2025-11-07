import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsStore.shared
    @State private var showPopover: Bool = false
    @State private var isEditing = false
    @State private var testing: CGFloat = 0
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Switch Apps Shortcut:")
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
                Text("Panel size:")
                Slider(
                    value: $appState.screenWidth,
                    in: 500...1000,
                    onEditingChanged: { editing in
                        isEditing = editing
                    }
                )
                .onChange(of: isEditing) {
                    isEditing ? appState.showPanel() : appState.panel.orderOut(nil)
                }
            }
        }
        .padding(32)
        .frame(width: 300, height: 180)
    }
}

#Preview {
    SettingsView()
}
