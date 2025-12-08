//import SwiftUI
//
//class EventController {
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
