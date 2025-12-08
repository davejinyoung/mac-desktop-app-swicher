import SwiftUI

class MenuController {
    private var settingsController: SettingsController
    private var statusItem: NSStatusItem?
    
    init(appState: AppState) {
        self.settingsController = .init(appState: appState)
        createMenu()
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
        
        let settingsMenuItem = NSMenuItem(title: "Settings", action: #selector(self.settingsController.openSettings), keyEquivalent: ",")
        settingsMenuItem.target = self.settingsController
        statusMenu.addItem(settingsMenuItem)
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(withTitle: "Quit \(displayName!)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = statusMenu
        self.statusItem = statusItem
    }
}
