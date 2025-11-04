import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsStore.shared
    @State private var showPopover: Bool = false
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
        }
        .padding(32)
        .frame(width: 340, height: 180)
    }
}

#Preview {
    SettingsView()
}
