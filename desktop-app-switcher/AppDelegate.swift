import AppKit
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private let appState = AppState()
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var eventTap: CFMachPort?
    private var showPanelWorkItem: DispatchWorkItem?
    private var settingsWindow: NSWindow? = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !checkAccessibilityPermissions() {
            requestAccessibilityPermissions()
            return
        }
        createMenu()
        setupPanel()
        setupEventTap()
        setupFlagsMonitor()
    }
    
    @objc private func openSettings() {
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
    
    private func createMenu() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "arrow.right.arrow.left", accessibilityDescription: "Desktop App Switcher")
            } else {
                button.image = NSImage(named: NSImage.actionTemplateName)
            }
        }
        let statusMenu = NSMenu()
        let displayName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
        
        statusMenu.addItem(withTitle: "Settings", action: #selector(openSettings), keyEquivalent: ",")
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(withTitle: "Quit \(displayName!)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = statusMenu
        self.statusItem = statusItem
    }
    
    private func setupPanel() {
        appState.panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        appState.panel.isOpaque = false
        appState.panel.backgroundColor = .clear
        appState.panel.level = .floating
        appState.panel.collectionBehavior = .canJoinAllSpaces
        if let screen = NSScreen.main {
            appState.screenWidth = screen.visibleFrame.width
            appState.screenHeight = screen.visibleFrame.height
        }

        let contentView = ContentView().environmentObject(appState)
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        appState.panel.contentViewController = hostingController
        appState.fetchRunningApps()
    }
    
    private func setupEventTap() {
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
            return
        }
        
        // Create a run loop source and add it to the current run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private func setupFlagsMonitor() {
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            _ = self.flagMonitorHandler(event: event)
        }
        
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return nil }
            let handled = self.flagMonitorHandler(event: event)
            return handled ? nil : event
        }
        
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            if self.appState.panel.isVisible {
                appState.canHover = true
            }
        }
        
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return event }
            if self.appState.panel.isVisible {
                appState.canHover = true
            }
            return event
        }
    }
    
    private func flagMonitorHandler(event: NSEvent) -> Bool {
        if !event.modifierFlags.contains(NSEvent.ModifierFlags(rawValue: UInt(SettingsStore.shared.shortcutModifierRaw))),
           let workItem = showPanelWorkItem,
           !workItem.isCancelled {
            showPanelWorkItem?.cancel()
            if appState.panel.isVisible {
                appState.canHover = false
            }
            switchSelectedAppToForeground()
            return true
        }
        return false
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
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let shortcutModifierRaw: Int = SettingsStore.shared.shortcutModifierRaw
        let shortcutKey: Int = SettingsStore.shared.shortcutKey
        
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
        
        let isReverse: Bool = flags.contains(.maskShift)
        
        if appState.settings.isModifying {
            let keyCode = Int(keyCode)
            let modifier = Int(flags.rawValue)
            appState.updateSettings(keyCode: keyCode, modifier: modifier)
            appState.settings.isModifying = false
            return nil
        }
        
        // Check for Option+Tab (keyCode 48 = Tab)
        if keyCode == shortcutKey && (flags.contains(CGEventFlags(rawValue: UInt64(shortcutModifierRaw)))) {
            // Trigger panel show on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if !self.appState.panel.isVisible {
                    appState.fetchRunningApps()
                    appState.cycleSelection(reverse: isReverse)
                    self.scheduleShowPanel(reverse: isReverse)
                } else {
                    appState.cycleSelection(reverse: isReverse)
                }
            }
            return nil
        } else if self.appState.panel.isVisible && flags.contains(CGEventFlags(rawValue: UInt64(shortcutModifierRaw))) {
            switch keyCode {
            case Int64(SettingsStore.shared.quitAppKey): // Checks for the quit app key
                terminateSelectedApp()
            case Int64(SettingsStore.shared.newAppWindowKey): // Checks for the new app window key
                openNewAppWindowInstance()
            case 124: // Checks for right arrow key
                appState.cycleSelection()
            case 123: // Checks for left arrow key
                appState.cycleSelection(reverse: true)
            default:
                break
            }
            return nil
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func switchSelectedAppToForeground() {
        self.appState.panel.orderOut(nil)
        let appToActivate = NSWorkspace
             .shared.runningApplications.first(where: { $0
                 .bundleIdentifier == appState.selectedAppId })
        appToActivate?.activate(options: [.activateAllWindows])
    }
    
    private func terminateSelectedApp() {
        if let selectedAppId = appState.selectedAppId {
            appState.runningApps.removeAll { $0.id == selectedAppId }
        }
        let appToTerminate = NSWorkspace
             .shared.runningApplications.first(where: { $0
                 .bundleIdentifier == appState.selectedAppId })
        appToTerminate?.terminate()
        appState.cycleSelection()
    }
    
    private func openNewAppWindowInstance() {
        let appToOpenNewWindown = NSWorkspace
             .shared.runningApplications.first(where: { $0
                 .bundleIdentifier == appState.selectedAppId })
        let url = appToOpenNewWindown!.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url!, configuration: configuration, completionHandler: nil)
    }
    
    private func scheduleShowPanel(reverse: Bool = false) {
        showPanelWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.appState.showPanel()
            self?.appState.fetchRunningApps()
            self?.appState.cycleSelection(reverse: reverse)
        }
        showPanelWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
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
        if let globalMouseMonitor = globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
        }
        if let localMouseMonitor = localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
        }
    }
}

