//
//  ContentView.swift
//  desktop-app-switcher
//
//  Created by Dave Jung on 2025-08-08.
//

import SwiftUI
import AppKit

struct AppInfo: Identifiable {
    let id: String
    let name: String
    let icon: NSImage
}

struct ContentView: View {
    @State private var runningApps: [AppInfo] = []
    @State private var selectedAppID: String?
    
    var body: some View {
        HStack(){
            ForEach(runningApps) { app in
                VStack(alignment: .center) {
                    Image(nsImage: app.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 90, height: 90)
                        .padding(8)
                        .background(selectedAppID == app.id ? Color.black.opacity(0.25) : Color.clear)
                        .cornerRadius(8)
                    Text(app.name)
                        .lineLimit(1)
                }
                .onTapGesture {
                    selectedAppID = app.id
                }
            }
        }
        .padding(25)
        .cornerRadius(8)
        .frame(width: 700, height: 160)
        .onAppear(perform: fetchRunningApps)
    }
    
    private func fetchRunningApps() {
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap{ app -> AppInfo? in
                guard let name = app.localizedName,
                      let icon = app.icon,
                      let id = app.bundleIdentifier else {
                    return nil
                }
                return AppInfo(id: id, name: name, icon: icon)
            }
        self.runningApps = runningApps
        self.selectedAppID = runningApps.first?.id
    }
}

#Preview {
    ContentView()
}
