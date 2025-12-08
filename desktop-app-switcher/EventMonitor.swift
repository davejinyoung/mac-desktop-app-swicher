//import SwiftUI
//
//class EventMonitor {
//    private var eventTap: CFMachPort?
//    private var showPanelWorkItem: DispatchWorkItem?
//    private var globalFlagsMonitor: Any?
//    private var localFlagsMonitor: Any?
//    private var globalMouseMonitor: Any?
//    private var localMouseMonitor: Any?
//    private let appState = AppState()
//    
//    init() {
//        setupEventTap()
//        setupFlagsMonitor()
//    }
//    
//    private func setupFlagsMonitor() {
//        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
//            guard let self = self else { return }
//            _ = self.flagMonitorHandler(event: event)
//        }
//        
//        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
//            guard let self = self else { return nil }
//            let handled = self.flagMonitorHandler(event: event)
//            return handled ? nil : event
//        }
//        
//        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
//            guard let self = self else { return }
//            if self.appState.panel.isVisible {
//                appState.canHover = true
//            }
//        }
//        
//        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
//            guard let self = self else { return event }
//            if self.appState.panel.isVisible {
//                appState.canHover = true
//            }
//            return event
//        }
//    }
//    
//    private func flagMonitorHandler(event: NSEvent) -> Bool {
//        if !event.modifierFlags.contains(NSEvent.ModifierFlags(rawValue: UInt(SettingsStore.shared.shortcutModifierRaw))),
//           let workItem = showPanelWorkItem,
//           !workItem.isCancelled {
//            showPanelWorkItem?.cancel()
//            if appState.panel.isVisible {
//                appState.canHover = false
//            }
//            switchSelectedAppToForeground()
//            return true
//        }
//        return false
//    }
//    
//    private func setupEventTap() {
//        // Create the event tap
//        let eventMask = (1 << CGEventType.keyDown.rawValue)
//        
//        eventTap = CGEvent.tapCreate(
//            tap: .cghidEventTap,
//            place: .headInsertEventTap,
//            options: .defaultTap,
//            eventsOfInterest: CGEventMask(eventMask),
//            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
//                let eventMonitor = Unmanaged<EventMonitor>.fromOpaque(refcon!).takeUnretainedValue()
//                return eventMonitor.handleKeyEvent(proxy: proxy, type: type, event: event)
//            },
//            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
//        )
//        
//        guard let eventTap = eventTap else {
//            return
//        }
//        
//        // Create a run loop source and add it to the current run loop
//        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
//        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
//        
//        // Enable the event tap
//        CGEvent.tapEnable(tap: eventTap, enable: true)
//    }
//    
//    private func scheduleShowPanel(reverse: Bool = false) {
//        showPanelWorkItem?.cancel()
//        let workItem = DispatchWorkItem { [weak self] in
//            self?.appState.showPanel()
//        }
//        showPanelWorkItem = workItem
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
//    }
//    
//    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
//        let shortcutModifierRaw: Int = SettingsStore.shared.shortcutModifierRaw
//        let shortcutKey: Int = SettingsStore.shared.shortcutKey
//        
//        // Handle tap disabled events
//        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
//            if let eventTap = eventTap {
//                CGEvent.tapEnable(tap: eventTap, enable: true)
//            }
//            return Unmanaged.passRetained(event)
//        }
//        
//        // Only handle key down events
//        guard type == .keyDown else {
//            return Unmanaged.passRetained(event)
//        }
//        
//        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
//        let flags = event.flags
//        
//        let isReverse: Bool = flags.contains(.maskShift)
//        
//        if appState.settings.isModifying {
//            let keyCode = Int(keyCode)
//            let modifier = Int(flags.rawValue)
//            appState.updateSettings(keyCode: keyCode, modifier: modifier)
//            appState.settings.isModifying = false
//            return nil
//        }
//        
//        // Check for Option+Tab (keyCode 48 = Tab)
//        if !missionControlActive() {
//            if keyCode == shortcutKey && (flags.contains(CGEventFlags(rawValue: UInt64(shortcutModifierRaw)))) {
//                // Trigger panel show on main thread
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//                    if !self.appState.panel.isVisible {
//                        appState.cycleSelection(reverse: isReverse)
//                        self.scheduleShowPanel(reverse: isReverse)
//                    } else {
//                        appState.cycleSelection(reverse: isReverse)
//                    }
//                }
//                return nil
//            } else if self.appState.panel.isVisible && flags.contains(CGEventFlags(rawValue: UInt64(shortcutModifierRaw))) {
//                switch keyCode {
//                case Int64(SettingsStore.shared.quitAppKey): // Checks for the quit app key
//                    terminateSelectedApp()
//                case Int64(SettingsStore.shared.newAppWindowKey): // Checks for the new app window key
//                    openNewAppWindowInstance()
//                case 124: // Checks for right arrow key
//                    appState.cycleSelection()
//                case 123: // Checks for left arrow key
//                    appState.cycleSelection(reverse: true)
//                default:
//                    break
//                }
//                return nil
//            }
//        }
//        
//        return Unmanaged.passRetained(event)
//    }
//}
