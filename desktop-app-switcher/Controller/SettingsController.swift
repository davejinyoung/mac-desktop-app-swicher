import SwiftUI

class SettingsController {
    private var settingsWindow: NSWindow? = nil
    private var appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    @objc func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let hostingController = NSHostingController(rootView: SettingsView().environmentObject(appState))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
            styleMask: [.titled, .closable, .utilityWindow, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = window.frame.size
            let x = screenFrame.origin.x + (screenFrame.size.width  - windowSize.width)  / 2
            let y = screenFrame.origin.y + (screenFrame.size.height - windowSize.height) / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        window.contentViewController = hostingController
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            self?.settingsWindow = nil
        }
        settingsWindow = window
    }
}
