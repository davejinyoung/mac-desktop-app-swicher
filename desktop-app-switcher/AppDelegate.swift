import AppKit
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {

    private var panel: NSPanel!
    private let appState = AppState()

    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var eventTap: CFMachPort?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !checkAccessibilityPermissions() {
            requestAccessibilityPermissions()
            return
        }
        
        setupPanel()
        setupEventTap()
        setupFlagsMonitor()
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
    
    private func setupEventTap() {
        print("Setting up CGEventTap...")
        
        // Create the event tap
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Get the AppDelegate instance
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon!).takeUnretainedValue()
                return appDelegate.handleKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        guard let eventTap = eventTap else {
            print("Failed to create event tap!")
            return
        }
        
        // Create a run loop source and add it to the current run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("CGEventTap created successfully")
    }
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle tap disabled events
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        // Only handle key down events
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Check for Option+Tab (keyCode 48 = Tab)
        if keyCode == 48 && flags.contains(.maskAlternate) {
            print("Option+Tab detected via CGEventTap - consuming event")
            
            // Trigger panel show on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if !self.panel.isVisible {
                    self.appState.fetchRunningApps()
                    self.showPanel()
                }
                appState.cycleSelection()
            }
            
            return nil
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func switchSelectedAppToForeground() {
        self.panel.orderOut(nil)
        let appToActivate = NSWorkspace
             .shared.runningApplications.first(where: { $0
                 .bundleIdentifier == self.appState.selectedAppId })
        appToActivate?.activate()
    }
    
    private func setupFlagsMonitor() {
        // Hides the panel when Option is released
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            if !event.modifierFlags.contains(.option) && self.panel.isVisible {
                switchSelectedAppToForeground()
            }
        }
        
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return nil }
            if !event.modifierFlags.contains(.option) && self.panel.isVisible {
                switchSelectedAppToForeground()
            }
            return nil
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
        // Clean up event tap
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        
        // Clean up flags monitor
        if let globalFlagsMonitor = globalFlagsMonitor {
            NSEvent.removeMonitor(globalFlagsMonitor)
        }
        if let localFlagsMonitor = localFlagsMonitor {
            NSEvent.removeMonitor(localFlagsMonitor)
        }
    }
}
