import AppKit
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {

    private var panel: NSPanel!
    private let appState = AppState()

    private var flagsMonitor: Any?
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !checkAccessibilityPermissions() {
            requestAccessibilityPermissions()
            return
        }
        
        setupPanel()
        setupKeyListeners()
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        return accessEnabled
    }
    
    private func requestAccessibilityPermissions() {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "Accessibility Access Required"
            alert.informativeText = "This app requires accessibility access to monitor global keyboard shortcuts. Please grant access in System Preferences > Security & Privacy > Accessibility, then restart the app."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Quit")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open System Preferences
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            NSApplication.shared.terminate(self)
        }
    }
    
    private func setupPanel() {
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.collectionBehavior = .canJoinAllSpaces
        if let screen = NSScreen.main {
            appState.screenWidth = screen.visibleFrame.width
            appState.screenHeight = screen.visibleFrame.height
        }

        let contentView = ContentView().environmentObject(appState)
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = hostingController
    }
    
    func setupKeyListeners() {
        // Hides the panel when Option is released
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            print("Flags changed: \(event.modifierFlags)")
            if !event.modifierFlags.contains(.option) && self.panel.isVisible {
                print("Hiding panel")
                self.panel.orderOut(nil)
            }
        }

        // Shows the panel when Option+Tab is pressed
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            print("Key pressed: \(event.keyCode), modifiers: \(event.modifierFlags)")
            if event.keyCode == 48 && event.modifierFlags.contains(.option) {
                print("Option+Tab detected")
                if !self.panel.isVisible {
                    self.appState.fetchRunningApps()
                    self.showPanel()
                }
            }
        }
        
        if flagsMonitor == nil || keyMonitor == nil {
            print("Failed to set up event monitors - check accessibility permissions")
        } else {
            print("Event monitors set up successfully")
        }
    }

    func showPanel() {
        print("Showing panel")
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let newSize = CGSize(width: appState.screenWidth, height: appState.screenHeight)
            panel.setContentSize(newSize)

            let newOriginX = (screenRect.width - newSize.width) / 2 + screenRect.origin.x
            let newOriginY = (screenRect.height - newSize.height) / 2 + screenRect.origin.y

            panel.setFrame(CGRect(origin: CGPoint(x: newOriginX, y: newOriginY), size: newSize), display: true)
        }
        panel.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if let flagsMonitor = flagsMonitor {
            NSEvent.removeMonitor(flagsMonitor)
        }
        if let keyMonitor = keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
    }
}
