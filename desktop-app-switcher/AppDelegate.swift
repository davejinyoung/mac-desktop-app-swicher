import AppKit
import HotKey
import SwiftUI

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
            let newSize = CGSize(width: appState.screenWidth, height: appState.screenHeight	)
            panel.setContentSize(newSize)

            let newOriginX = (screenRect.width - newSize.width) / 2 + screenRect.origin.x
            let newOriginY = (screenRect.height - newSize.height) / 2 + screenRect.origin.y

            panel.setFrame(CGRect(origin: CGPoint(x: newOriginX, y: newOriginY), size: newSize), display: true)
        }
        panel.makeKeyAndOrderFront(nil)
    }
}
