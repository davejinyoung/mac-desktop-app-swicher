import SwiftUI
import AppKit
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var panel: NSPanel!
    private let appState = AppState()
    private var hotKey: HotKey?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.collectionBehavior = .canJoinAllSpaces
        panel.backgroundColor = .clear
        
        let contentView = ContentView().environmentObject(appState)
        panel.contentViewController = NSHostingController(rootView: contentView)
        panel.setContentSize(CGSize(width: 700, height: 160))
        
        hotKey = HotKey(key: .tab, modifiers: [.option])
        hotKey?.keyDownHandler = { [weak self] in
            self?.togglePanel()
        }
    }

    
    @objc func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            appState.fetchRunningApps()
            showPanel()
        }
    }
    
    func showPanel() {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let panelRect = panel.frame
            
            let newOriginX = (screenRect.width - panelRect.width) / 2 + screenRect.origin.x
            let newOriginY = (screenRect.height - panelRect.height) / 2 + screenRect.origin.y
            
            panel.setFrameOrigin(CGPoint(x: newOriginX, y: newOriginY))
        }
        panel.makeKeyAndOrderFront(nil)
    }
}
