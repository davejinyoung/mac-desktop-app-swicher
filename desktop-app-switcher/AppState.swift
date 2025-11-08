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
    @Published var appIconSize: CGFloat = SettingsStore.shared.appIconSize
    @Published var screenWidth: CGFloat = 0
    @Published var screenHeight: CGFloat = 0
    @Published var canHover: Bool = false
    @Published var isChoosingShortcut: Bool = false
    @Published var panel: NSPanel!

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
    
    func cycleSelection(reverse: Bool = false) {
        print("running apps are: " + runningApps.map(\.self).map(\.name).joined(separator: ", "))
        guard !runningApps.isEmpty else {
            return
        }
        
        if let selectedAppId = selectedAppId,
           let curIndex = runningApps.firstIndex(where: { $0.id == selectedAppId })
        {
            let indexOffset: Int = reverse ? -1 : 1
            var nextIndex = (curIndex + indexOffset) % runningApps.count
            nextIndex = (nextIndex % runningApps.count + runningApps.count) % runningApps.count
            self.selectedAppId = runningApps[nextIndex].id
        }
        else {
            self.selectedAppId = runningApps.first?.id
        }
    }
    
    func showPanel() {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let newSize = CGSize(width: screenWidth, height: screenHeight)
            panel.setContentSize(newSize)

            let newOriginX = (screenRect.width - newSize.width) / 2 + screenRect.origin.x
            let newOriginY = (screenRect.height - newSize.height) / 2 + screenRect.origin.y

            panel.setFrame(CGRect(origin: CGPoint(x: newOriginX, y: newOriginY), size: newSize), display: true)
        }
        panel.makeKeyAndOrderFront(nil)
    }
}
