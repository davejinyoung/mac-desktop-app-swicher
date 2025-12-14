import SwiftUI

class EventController {
    private var appState: AppState
    public var eventTap: CFMachPort?
    public var showPanelWorkItem: DispatchWorkItem?
    
    init(appState: AppState) {
        self.appState = appState
        self.setupEventTap()
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
                let controller = Unmanaged<EventController>.fromOpaque(refcon!).takeUnretainedValue()
                return controller.handleKeyEvent(proxy: proxy, type: type, event: event)
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
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let shortcutModifier: Int = SettingsStore.shared.shortcutModifierRaw
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
        
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let isReverse: Bool = flags.contains(.maskShift)
        
        if appState.settings.isModifying {
            appState.updateSettings(keyCode: keyCode, modifier: Int(flags.rawValue))
            return nil
        }
        
        // Check for Option+Tab (keyCode 48 = Tab)
        if !missionControlActive() {
            if keyCode == shortcutKey && flags.contains(CGEventFlags(rawValue: UInt64(shortcutModifier))) {
                // Trigger panel show on main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if !appState.panel.isVisible {
                        appState.cycleSelection(reverse: isReverse)
                        scheduleShowPanel(reverse: isReverse)
                    } else { // Panel is already displayed
                        // Logic to check if apps should auto cycle or not
                        let keyHold = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
                        guard !(keyHold &&
                                (((appState.isLastApp() && !isReverse) || (appState.isFirstApp() && isReverse))
                                 && !SettingsStore.shared.continuousCycling)
                        ) else { return }
                        appState.cycleSelection(reverse: isReverse)
                    }
                }
                return nil
            } else if appState.panel.isVisible && flags.contains(CGEventFlags(rawValue: UInt64(shortcutModifier))) {
                performAlternativeCommands(keyCode: keyCode)
                return nil
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func performAlternativeCommands(keyCode: Int) {
        switch keyCode {
        case SettingsStore.shared.quitAppKey:
            terminateSelectedApp()
        case SettingsStore.shared.newAppWindowKey:
            openNewAppWindowInstance()
        case 124: // Checks for right arrow key
            appState.cycleSelection()
        case 123: // Checks for left arrow key
            appState.cycleSelection(reverse: true)
        default:
            break
        }
    }
    
    private func scheduleShowPanel(reverse: Bool = false) {
        showPanelWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.appState.showPanel()
        }
        showPanelWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
    
    private func missionControlActive() -> Bool {
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
        for window in windowList {
            if (window["kCGWindowOwnerName"] as? String) == "Dock",
                let windowOwnerPID = window["kCGWindowOwnerPID"] as? pid_t,
                let app = NSRunningApplication(processIdentifier: windowOwnerPID),
                app.bundleIdentifier == "com.apple.dock",
                window["kCGWindowName"] == nil
            {
                return true
            }
        }
        return false
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
}
