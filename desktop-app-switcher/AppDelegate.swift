import CoreGraphics
import AppKit
import SwiftUI
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var menuController: MenuController?
    private var eventController: EventController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !checkAccessibilityPermissions() {
            requestAccessibilityPermissions()
            return
        }
        setupPanel()
        setupFlagsMonitor()
        self.menuController = .init(appState: appState)
        self.eventController = .init(appState: appState)
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
           let workItem = eventController!.showPanelWorkItem,
           !workItem.isCancelled {
            eventController!.showPanelWorkItem?.cancel()
            if appState.panel.isVisible {
                appState.canHover = false
            }
            self.appState.panel.orderOut(nil)
            self.appState.switchSelectedAppToForeground()
            self.appState.updateRunningAppsListOrder()
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

    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up event tap
        if let eventTap = eventController!.eventTap {
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

