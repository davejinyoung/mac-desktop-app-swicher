import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject var settings = SettingsStore.shared
    @State private var showPopover: Bool = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Switch Apps Shortcut:")
                Button("\(iconForModifierFlags(CGEventFlags(rawValue: UInt64(settings.shortcutModifierRaw))))\(iconForKeyCode(settings.shortcutKey))") {
                    showPopover = true
                    appState.isChoosingShortcut = true
                }
               .popover(isPresented: $showPopover, attachmentAnchor: .rect(.bounds), arrowEdge: .trailing) {
                   VStack {
                       Text("Choose any modifier + key")
                           .font(.callout)
                   }
                   .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                   .padding()
               }
               .onChange(of: showPopover) { oldValue, newValue in
                   appState.isChoosingShortcut = newValue
               }
            }
        }
        .padding(32)
        .frame(width: 340, height: 180)
    }
}

#Preview {
    SettingsView()
}
