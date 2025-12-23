import SwiftUI
import ScreenCaptureKit
import OrderedCollections
import AppKit
import CoreGraphics

struct AppInfo: Identifiable, Equatable {
    let id: String
    let winID: CGWindowID
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
        
        var appsByPID = Dictionary(uniqueKeysWithValues: allRunnableApps.map { ($0.processIdentifier, $0) })
        
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
        guard let windows = content?.windows else { return }
        
        // Create apps immediately with placeholder icons
        let sortedApps = orderedWindows.keys.compactMap { winID -> AppInfo? in
            let pid = orderedWindows[winID]!
            guard let app = appsByPID[pid],
                  let window = windows.first(where: { $0.windowID == winID }),
                  window.frame.width > 50,
                  window.frame.height > 50,
                  let name = app.localizedName,
                  let id = app.bundleIdentifier else {
                return nil
            }
            appsByPID.removeValue(forKey: pid)
            var preview = app.icon
            if (SettingsStore.shared.previewWindows) {
                preview = self.runningApps.first(where: {$0.winID == winID})?.icon ?? preview
            }
            return AppInfo(id: id, winID: window.windowID, name: name, icon: preview!)
        }
        
        await MainActor.run {
            self.runningApps = sortedApps
            if self.selectedAppId == nil {
                self.selectedAppId = self.runningApps.first?.id
            }
        }
        
        // Get window previews asynchronously in background
        if (SettingsStore.shared.previewWindows) {
            getWindowPreviews(sortedApps: sortedApps, windows: windows)
        }
    }
    
    func getWindowPreviews(sortedApps: [AppInfo], windows: [SCWindow]) {
        for (index, appInfo) in sortedApps.enumerated() {
            guard let window = windows.first(where: { $0.windowID == appInfo.winID }) else { continue }
            
            Task {
                if let preview = try? await captureWindow(window) {
                    await MainActor.run {
                        if self.runningApps[index].winID == appInfo.winID {
                            let title = (window.title?.isEmpty == false) ? window.title! : appInfo.name
                            self.runningApps[index] = AppInfo(
                                id: appInfo.id,
                                winID: appInfo.winID,
                                name: title,
                                icon: preview
                            )
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
