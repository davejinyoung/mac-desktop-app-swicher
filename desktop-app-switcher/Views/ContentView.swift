import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAppId: String?

    var body: some View {
        if appState.runningApps.isEmpty {
            EmptyWindowsView()
        }
        else if SettingsStore.shared.previewWindows {
            AppWindowPanelView()
        } else {
            AppIconPanelView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
