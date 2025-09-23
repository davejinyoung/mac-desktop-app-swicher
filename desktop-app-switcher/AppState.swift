import SwiftUI
import AppKit
import CoreGraphics

struct AppInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: NSImage
}

class AppState: ObservableObject {
    @Published var runningApps: [AppInfo] = []
    @Published var selectedAppId: String?
    @Published var screenWidth: CGFloat = 0
    @Published var screenHeight: CGFloat = 0
    @Published var canHover: Bool = false

    func fetchRunningApps() {
        let allRunnableApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        
        let appsByPID = Dictionary(uniqueKeysWithValues: allRunnableApps.map { ($0.processIdentifier, $0) })
        
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return
        }
        
        var orderedPIDs: [pid_t] = []
        for window in windowList {
            if let pid = window[kCGWindowOwnerPID as String] as? pid_t {
                if !orderedPIDs.contains(pid) {
                    orderedPIDs.append(pid)
                }
            }
        }
        let sortedApps = orderedPIDs.compactMap { pid -> AppInfo? in
            guard let app = appsByPID[pid],
                  let name = app.localizedName,
                  let icon = app.icon,
                  let id = app.bundleIdentifier else {
                return nil
            }
            return AppInfo(id: id, name: name, icon: icon)
        }
        
        self.runningApps = sortedApps
        self.selectedAppId = self.runningApps.first?.id
    }
    
    func cycleSelection() {
//        print("running apps are: " + runningApps.map(\.self).map(\.name).joined(separator: ", "))
        guard !runningApps.isEmpty else {
            return
        }
        
        if let selectedAppId = selectedAppId,
           let curIndex = runningApps.firstIndex(where: { $0.id == selectedAppId }) {
            let nextIndex = (curIndex + 1) % runningApps.count
            self.selectedAppId = runningApps[nextIndex].id
        } else {
            self.selectedAppId = runningApps.first?.id
        }
    }
}
