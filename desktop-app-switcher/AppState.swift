import SwiftUI
import AppKit
import CoreGraphics

struct AppInfo: Identifiable, Equatable {
    let id: CGWindowID
    let app: NSRunningApplication
    let name: String
    let icon: NSImage
}

struct SettingsOptions: Equatable {
    var isModifying: Bool
    var modifyingProperty: String?
}

class AppState: ObservableObject {
    @Published var runningApps: [AppInfo] = []
    @Published var selectedAppId: CGWindowID?
    @Published var appIconSize: CGFloat = SettingsStore.shared.appIconSize
    @Published var screenWidth: CGFloat = 0
    @Published var screenHeight: CGFloat = 0
    @Published var canHover: Bool = false
    @Published var settings: SettingsOptions = SettingsOptions(isModifying: false, modifyingProperty: nil)
    @Published var panel: NSPanel!
    
    // MARK: - Window Management
    func isStandardWindow(_ window: AXUIElement) -> Bool {
        // Check if window is minimized
        var minimizedRef: CFTypeRef?
        let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedRef)
        if minimizedResult == .success, let isMinimized = minimizedRef as? Bool, isMinimized {
            return false
        }
        
        // Check subrole to filter out things like system dialogs, popovers, etc.
        var subroleRef: CFTypeRef?
        let subroleResult = AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subroleRef)
        if subroleResult == .success, let subrole = subroleRef as? String {
            // Filter out non-standard windows
            let nonStandardSubroles = [
                "AXSystemDialog",
                "AXDialog",  // Optional: uncomment if you want to exclude dialogs
                "AXSheet",
                "AXFloatingWindow",
                "AXUnknown"
            ]
            if nonStandardSubroles.contains(subrole) {
                return false
            }
        }
        
        // Check role - should be AXWindow
        var roleRef: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &roleRef)
        if roleResult == .success, let role = roleRef as? String {
            if role != "AXWindow" {
                return false
            }
        }
        
        // Optional: Check if window has a title (most standard windows do)
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        // Some apps have windows without titles, so this is optional
        // if titleRef == nil { return false }
        
        return true
    }
    
    /// Get the AXUIElement for a specific window by PID and window ID
    func getAppWindow(pid: pid_t, wid: CGWindowID) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            print("Failed to get windows for process \(pid)")
            return nil
        }
        
        // First pass: try direct window ID match
        for window in windows {
            if let id = getWindowID(window), id == wid {
                print("Found window by direct ID match")
                return window
            }
        }
        
        // Second pass: if we have the target window info from CGWindowList, match by title and bounds
        let windowList = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        
        guard let targetWindowInfo = windowList.first(where: {
            ($0[kCGWindowNumber as String] as? CGWindowID) == wid &&
            ($0[kCGWindowOwnerPID as String] as? pid_t) == pid
        }) else {
            print("Could not find window info for ID \(wid)")
            return nil
        }
        
        let targetTitle = targetWindowInfo[kCGWindowName as String] as? String
        let targetBounds = targetWindowInfo[kCGWindowBounds as String] as? [String: CGFloat]
        
        // Try to match each AX window with the target
        for window in windows {
            // Method 1: Match by title
            if let targetTitle = targetTitle {
                var titleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
                if let title = titleRef as? String, title == targetTitle {
                    print("Found window by title match: \(title)")
                    return window
                }
            }
            
            // Method 2: Match by position and size
            if let targetBounds = targetBounds,
               let targetX = targetBounds["X"],
               let targetY = targetBounds["Y"],
               let targetW = targetBounds["Width"],
               let targetH = targetBounds["Height"] {
                
                var positionRef: CFTypeRef?
                var sizeRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
                AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
                
                if let posValue = positionRef, let sizeValue = sizeRef {
                    var position = CGPoint.zero
                    var size = CGSize.zero
                    
                    if AXValueGetValue(posValue as! AXValue, .cgPoint, &position) &&
                       AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) {
                        
                        if abs(targetX - position.x) < 2 && abs(targetY - position.y) < 2 &&
                           abs(targetW - size.width) < 2 && abs(targetH - size.height) < 2 {
                            print("Found window by bounds match")
                            return window
                        }
                    }
                }
            }
        }
        
        // Last resort: if there's only one window, return it
        if windows.count == 1 {
            print("Only one window available, returning it")
            return windows[0]
        }
        
        print("Could not match window with ID \(wid)")
        return nil
    }
    
    /// Extract window ID from an AXUIElement by matching with CGWindowList
    func getWindowID(_ window: AXUIElement) -> CGWindowID? {
        // Get the PID for this window
        var pid: pid_t = 0
        guard AXUIElementGetPid(window, &pid) == .success else {
            return nil
        }
        
        // Get window title
        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        let title = titleRef as? String
        
        // Get window position
        var positionRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        
        var position = CGPoint.zero
        var hasPosition = false
        if let posValue = positionRef {
            hasPosition = AXValueGetValue(posValue as! AXValue, .cgPoint, &position)
        }
        
        // Get window size
        var sizeRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        
        var size = CGSize.zero
        var hasSize = false
        if let sizeValue = sizeRef {
            hasSize = AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        }
        
        // Get all windows from CGWindowList
        let windowList = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        
        // Try to find a matching window
        for windowInfo in windowList {
            guard let windowPID = windowInfo[kCGWindowOwnerPID as String] as? pid_t,
                  let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID,
                  windowPID == pid else {
                continue
            }
            
            let windowTitle = windowInfo[kCGWindowName as String] as? String
            
            // Match by title if both have titles
            if let title = title, let windowTitle = windowTitle, title == windowTitle {
                // Double-check with bounds if available
                if hasPosition, let bounds = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                   let x = bounds["X"], let y = bounds["Y"] {
                    // Position should match (with small tolerance for floating point)
                    if abs(x - position.x) < 2 && abs(y - position.y) < 2 {
                        print("1")
                        return windowID
                    }
                } else {
                    // No bounds to check, title match is good enough
                    print("2")
                    return windowID
                }
            }
            
            // If no title match but we have position and size, try bounds matching
            if hasPosition && hasSize,
               let bounds = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
               let x = bounds["X"], let y = bounds["Y"],
               let w = bounds["Width"], let h = bounds["Height"] {
                
                if abs(x - position.x) < 2 && abs(y - position.y) < 2 &&
                   abs(w - size.width) < 2 && abs(h - size.height) < 2 {
                    print("3")
                    return windowID
                }
            }
        }
        
        // If we still haven't found it and there's only one window for this PID, return that
        let pidWindows = windowList.filter { ($0[kCGWindowOwnerPID as String] as? pid_t) == pid }
        if pidWindows.count == 1,
           let windowID = pidWindows[0][kCGWindowNumber as String] as? CGWindowID {
            print("4")
            return windowID
        }
        
        return nil
    }
    
    /// Switch to a specific window across spaces
    func switchToWindow(pid: pid_t, windowID: CGWindowID, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self,
                  let window = self.getAppWindow(pid: pid, wid: windowID) else {
                print("Could not find window with ID \(windowID)")
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            
            // Set the window as the main window
            AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, true as CFTypeRef)
            
            // Raise the window to front
            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
            
            // Activate the application (this will switch spaces if needed)
            DispatchQueue.main.async {
                if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid }) {
                    app.activate()
                }
                completion?()
            }
        }
    }
    
    /// Switch to the currently selected window
    func switchToSelectedWindow(completion: (() -> Void)? = nil) {
        guard let selectedWindowID = selectedAppId,
              let selectedApp = runningApps.first(where: { $0.id == selectedWindowID }) else {
            completion?()
            return
        }
        
        let pid = selectedApp.app.processIdentifier
        switchToWindow(pid: pid, windowID: selectedWindowID, completion: completion)
    }
    
    /// Get all windows for a specific app
    func getWindowsForApp(_ app: NSRunningApplication) -> [CGWindowID] {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var windowsRef: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        
        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            return []
        }
        
        return windows.compactMap { getWindowID($0) }
    }
    
    /// Get window title for a given window element
    func getWindowTitle(_ window: AXUIElement) -> String? {
        var titleRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        
        guard result == .success, let title = titleRef as? String else {
            return nil
        }
        
        return title
    }

    // MARK: - App Fetching
    
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
        if let firstPID = firstApp?.processIdentifier {
            orderedPIDs.append(firstPID)
        }
        
        for window in windowList {
            if let pid = window[kCGWindowOwnerPID as String] as? pid_t {
                if !orderedPIDs.contains(pid) && pid != firstApp?.processIdentifier {
                    orderedPIDs.append(pid)
                }
            }
        }
        
        let sortedApps = windowList.compactMap { window -> AppInfo? in
            guard let pid = window[kCGWindowOwnerPID as String] as? pid_t,
                  let wid = window[kCGWindowNumber as String] as? CGWindowID,
                  let app = appsByPID[pid],
                  let name = app.localizedName,
                  let icon = app.icon,
                  let _ = app.bundleIdentifier else {
                return nil
            }
            
            // Filter by window layer (0 = normal windows)
            let windowLayer = window[kCGWindowLayer as String] as? Int ?? 0
            if windowLayer != 0 {
                return nil  // Skip non-normal window layers
            }
            
            // Check if window has valid bounds (not zero size)
            guard let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = bounds["Width"],
                  let height = bounds["Height"],
                  width > 0 && height > 0 else {
                return nil  // Skip windows with no size
            }
            
            // Check if the window is a standard window using Accessibility API
            let appElement = AXUIElementCreateApplication(pid)
            var windowsRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
               let windows = windowsRef as? [AXUIElement] {
                
                // Find the matching AX window and check if it's standard
                for axWindow in windows {
                    if let axWindowID = getWindowID(axWindow), axWindowID == wid {
                        if !isStandardWindow(axWindow) {
                            return nil  // Skip non-standard windows (minimized, dialogs, etc.)
                        }
                        break
                    }
                }
            }
            
            return AppInfo(id: wid, app: app, name: name, icon: icon)
        }
        
        self.runningApps = sortedApps
        print("number of apps: \(self.runningApps.count)")
        self.selectedAppId = self.runningApps.first?.id
    }
    
    func retrieveRunningApps() {
        let allRunnableApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        
        let windows = allRunnableApps.map { app in
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var value: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
            return value
        }

        for windowValue in windows {
            if let windowList = windowValue as? [AXUIElement] {
                for windowElement in windowList {
                    var titleValue: CFTypeRef?
                    let titleResult = AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &titleValue)
                    if titleResult == .success, let title = titleValue as? String {
                        print("Window title: \(title)")
                    } else {
                        print("No title found for window")
                    }
                }
            } else {
                print("No windows or could not access windows for this app")
            }
        }
    }
    
    // MARK: - Selection & Navigation
    
    func cycleSelection(reverse: Bool = false) {
        if !panel.isVisible {
            fetchRunningApps()
        }
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
    }
    
    func updateRunningAppsListOrder() {
        guard let curIndex = runningApps.firstIndex(where: { $0.id == selectedAppId }) else {
            return
        }
        let selectedApp = runningApps.remove(at: curIndex)
        self.selectedAppId = selectedApp.id
        runningApps.insert(selectedApp, at: 0)
    }
    
    // MARK: - Panel Management
    
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
    
    // MARK: - Settings
    
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
    }
    
    // MARK: - Debugging
    
    /// Debug helper to print window information
    func debugWindowInfo(pid: pid_t, wid: CGWindowID) {
        print("\n=== DEBUG: Window Info ===")
        print("Target PID: \(pid), Window ID: \(wid)")
        
        // Show CGWindow info
        let windowList = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        if let windowInfo = windowList.first(where: {
            ($0[kCGWindowNumber as String] as? CGWindowID) == wid
        }) {
            print("CGWindow Info:")
            print("  Title: \(windowInfo[kCGWindowName as String] as? String ?? "nil")")
            print("  Bounds: \(windowInfo[kCGWindowBounds as String] ?? "nil")")
        }
        
        // Show AX windows
        let appElement = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
           let windows = windowsRef as? [AXUIElement] {
            print("\nAX Windows (\(windows.count) total):")
            for (index, window) in windows.enumerated() {
                var titleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
                let title = titleRef as? String ?? "nil"
                print("  [\(index)] Title: \(title)")
            }
        }
        print("======================\n")
    }
}

// MARK: - Usage Examples

/*
// Example 1: Switch to the selected window when user confirms selection
// (e.g., when they release the Tab key or press Enter)
appState.switchToSelectedWindow()

// Example 2: Get all windows for the currently selected app
if let selectedWindowID = appState.selectedAppId,
   let selectedApp = appState.runningApps.first(where: { $0.id == selectedWindowID }) {
    let windows = appState.getWindowsForApp(selectedApp.app)
    print("App has \(windows.count) windows: \(windows)")
}

// Example 3: Switch to a specific window by ID
let pid: pid_t = 12345  // Process ID of the app
let windowID: CGWindowID = 67890  // Window ID
appState.switchToWindow(pid: pid, windowID: windowID)

// Example 4: Get window details
if let selectedWindowID = appState.selectedAppId,
   let selectedApp = appState.runningApps.first(where: { $0.id == selectedWindowID }),
   let window = appState.getAppWindow(pid: selectedApp.app.processIdentifier, wid: selectedWindowID) {
    if let title = appState.getWindowTitle(window) {
        print("Selected window title: \(title)")
    }
}

// Example 5: Debug window matching issues
if let selectedWindowID = appState.selectedAppId,
   let selectedApp = appState.runningApps.first(where: { $0.id == selectedWindowID }) {
    appState.debugWindowInfo(pid: selectedApp.app.processIdentifier, wid: selectedWindowID)
}
*/
