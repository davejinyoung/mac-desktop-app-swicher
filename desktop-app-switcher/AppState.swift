import SwiftUI
import ScreenCaptureKit
import OrderedCollections
import AppKit
import CoreGraphics

struct AppInfo: Identifiable, Equatable {
    let id: String
    let window: SCWindow
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
    
    func fetchRunningApps() async {
        let allRunnableApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        let appsByPID = Dictionary(uniqueKeysWithValues: allRunnableApps.map { ($0.processIdentifier, $0) })
        
        let option: CGWindowListOption = SettingsStore.shared.appsFromAllDeskops ? .excludeDesktopElements : .optionOnScreenOnly
        guard let windowList = CGWindowListCopyWindowInfo(option, kCGNullWindowID) as? [[String: Any]] else {
            return
        }
        
        var orderedWindows = OrderedDictionary<CGWindowID, pid_t>()
        for window in windowList {
            if let pid = window[kCGWindowOwnerPID as String] as? pid_t,
               let windowId = window[kCGWindowNumber as String] as? CGWindowID {
                orderedWindows[windowId] = pid
            }
        }
        
        let content = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let allUnorderedWindows = content?.windows else { return }
        
        // Create apps immediately with placeholder icons
        let sortedApps = matchAppsWithWindows(
            appsByPID: appsByPID,
            orderedWindows: orderedWindows,
            allUnorderedWindows: allUnorderedWindows
        )
        
        await MainActor.run {
            self.runningApps = sortedApps
            if self.selectedAppId == nil {
                self.selectedAppId = self.runningApps.first?.id
            }
        }
        
        // Get window previews asynchronously in non-main thread
        if (SettingsStore.shared.previewWindows) {
            getWindowThumbnails(sortedApps: sortedApps)
        }
    }
    
    // Matches app windows from CGWindowListCopyWindowInfo to windows from SCShareableContent
    func matchAppsWithWindows(
        appsByPID: [pid_t : NSRunningApplication],
        orderedWindows: OrderedDictionary<CGWindowID, pid_t>,
        allUnorderedWindows: [SCWindow]
    ) -> [AppInfo] {
        var apps: [pid_t] = []
        let sortedApps = orderedWindows.keys.compactMap { winID -> AppInfo? in
            let pid = orderedWindows[winID]!
            guard let app = appsByPID[pid],
                  let window = allUnorderedWindows.first(where: { $0.windowID == winID }),
                  window.isOnScreen,
                  window.frame.width > 50,
                  window.frame.height > 50,
                  window.windowLayer == 0,
                  let name = app.localizedName,
                  let id = app.bundleIdentifier else {
                return nil
            }
            // Choose the first window instance of the app and ignore the rest
            if apps.contains(pid) { return nil }
            apps.append(pid)
            var preview = app.icon
            if (SettingsStore.shared.previewWindows) {
                preview = self.runningApps.first(where: {$0.window.windowID == winID})?.icon ?? preview
            }
            return AppInfo(id: id, window: window, name: name, icon: preview!)
        }
        return sortedApps
    }
    
    func getWindowThumbnails(sortedApps: [AppInfo]) {
        for (index, app) in sortedApps.enumerated() {
            Task {
                if let windowThumbnail = try? await captureWindow(app.window) {
                    await MainActor.run {
                        if self.runningApps[index].window.windowID == app.window.windowID {
                            let title = app.window.title?.isEmpty == false ? app.window.title! : app.name
                            let appInfo = AppInfo(
                                id: app.id,
                                window: app.window,
                                name: title,
                                icon: windowThumbnail
                            )
                            self.runningApps[index] = appInfo
                        }
                    }
                }
            }
        }
    }
    
    func captureWindow(_ window: SCWindow) async throws -> NSImage? {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        config.scalesToFit = true
        
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
        
        return NSImage(cgImage: image, size: NSSize(width: window.frame.width, height: window.frame.height))
    }

    func cycleSelection(reverse: Bool = false) {
        if !panel.isVisible {
            Task {
                await fetchRunningApps()
                await performCycle(reverse: reverse)
            }
        } else {
            Task {
                await performCycle(reverse: reverse)
            }
        }
    }

    @MainActor
    private func performCycle(reverse: Bool) {
        print("running apps are: " + runningApps.map(\.name).joined(separator: ", "))
        guard !runningApps.isEmpty else {
            return
        }
        
        if let curIndex = runningApps.firstIndex(where: { $0.id == selectedAppId }) {
            let indexOffset = reverse ? -1 : 1
            var nextIndex = (curIndex + indexOffset) % runningApps.count
            nextIndex = (nextIndex % runningApps.count + runningApps.count) % runningApps.count
            self.selectedAppId = runningApps[nextIndex].id
        } else {
            self.selectedAppId = runningApps.first?.id
        }
        
        if SettingsStore.shared.switchWindowsWhileCycling {
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
