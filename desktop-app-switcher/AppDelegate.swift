//
//  AppDelegate.swift
//  desktop-app-switcher
//
//  Created by Dave Jung on 2025-08-09.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var panel: NSPanel!
    
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
        panel.contentViewController = NSHostingController(rootView: ContentView())
        panel.setContentSize(CGSize(width: 700, height: 160))
        
        showPanel()
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
