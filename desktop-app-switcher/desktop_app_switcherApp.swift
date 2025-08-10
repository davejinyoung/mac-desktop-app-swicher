//
//  desktop_app_switcherApp.swift
//  desktop-app-switcher
//
//  Created by Dave Jung on 2025-08-08.
//

import SwiftUI

@main
struct desktop_app_switcherApp: App {
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
