import SwiftUI
import AppKit

struct AppInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: NSImage
}

class AppState: ObservableObject {
    @Published var runningApps: [AppInfo] = []

    func fetchRunningApps() {
        let workspace = NSWorkspace.shared
        let apps = workspace.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> AppInfo? in
                guard let name = app.localizedName,
                      let icon = app.icon,
                      let id = app.bundleIdentifier else {
                    return nil
                }
                return AppInfo(id: id, name: name, icon: icon)
            }
        self.runningApps = apps
    }
}
