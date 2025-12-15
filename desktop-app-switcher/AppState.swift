import SwiftUI
import AppKit
import CoreGraphics

struct AppInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: NSImage
}

struct SettingsOptions: Equatable {
    var isModifying: Bool
    var modifyingProperty: String?
}

class AppState: ObservableObject {
    @Published var runningApps: [AppInfo] = []
    @Published var selectedAppId: String?
    @Published var appIconSize: CGFloat = SettingsStore.shared.appIconSize
    @Published var screenWidth: CGFloat = 0
    @Published var screenHeight: CGFloat = 0
    @Published var canHover: Bool = false
    @Published var settings: SettingsOptions = SettingsOptions(isModifying: false, modifyingProperty: nil)
    @Published var panel: NSPanel!

    func fetchRunningApps() {
        let firstApp = NSWorkspace.shared.frontmostApplication
        let allRunnableApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        
        let appsByPID = Dictionary(uniqueKeysWithValues: allRunnableApps.map { ($0.processIdentifier, $0) })
        
        let option: CGWindowListOption = SettingsStore.shared.appsFromAllDeskops ? .excludeDesktopElements : .optionOnScreenOnly
        guard let windowList = CGWindowListCopyWindowInfo(option, kCGNullWindowID) as? [[String: Any]] else {
            return
        }
        
        var orderedPIDs: [pid_t] = []
        orderedPIDs.append(firstApp!.processIdentifier)
        for window in windowList {
            if let pid = window[kCGWindowOwnerPID as String] as? pid_t {
                if !orderedPIDs.contains(pid) && pid != firstApp!.processIdentifier {
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
    
    func cycleSelection(reverse: Bool = false, ) {
        if !panel.isVisible {
            fetchRunningApps()
        }
        print("running apps are: " + runningApps.map(\.self).map(\.name).joined(separator: ", "))
        guard !runningApps.isEmpty else {
            return
        }
        
        if let curIndex = runningApps.firstIndex(where: { $0.id == selectedAppId })
        {
            let indexOffset = reverse ? -1 : 1
            var nextIndex = (curIndex + indexOffset) % runningApps.count
            nextIndex = (nextIndex % runningApps.count + runningApps.count) % runningApps.count
            self.selectedAppId = runningApps[nextIndex].id
        }
        else {
            self.selectedAppId = runningApps.first?.id
        }
        if SettingsStore.shared.previewWindows {
            switchSelectedAppToForeground()
        }
    }
    
    func switchSelectedAppToForeground() {
        let appToActivate = NSWorkspace
             .shared.runningApplications.first(where: { $0
                 .bundleIdentifier == selectedAppId })
        appToActivate?.activate(options: [.activateAllWindows])
    }
    
    func isLastApp() -> Bool {
        return runningApps.last?.id == selectedAppId
    }
    
    func isFirstApp() -> Bool {
        return runningApps.first?.id == selectedAppId
    }
    
    func updateRunningAppsListOrder() {
        let curIndex = runningApps.firstIndex(where: { $0.id == selectedAppId }) ?? 0
        let selectedApp = runningApps.remove(at: curIndex)
        self.selectedAppId = selectedApp.id
        runningApps.insert(selectedApp, at: 0)
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
    
    func updateSettings(keyCode: Int, modifier: Int) {
        switch self.settings.modifyingProperty {
        case "cycle":
            SettingsStore.shared.shortcutKey = keyCode
            SettingsStore.shared.shortcutModifierRaw = modifier
        case "quit":
            SettingsStore.shared.quitAppKey = keyCode
        case "new":
            SettingsStore.shared.newAppWindowKey = keyCode
        default:
            break
        }
        settings.isModifying = false
    }
}
