//
//  ContentView.swift
//  desktop-app-switcher
//
//  Created by Dave Jung on 2025-08-08.
//

import SwiftUI

struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let iconSystemName: String
}

let sampleApps = [
    AppInfo(name: "Finder", iconSystemName: "folder.fill"),
    AppInfo(name: "Safari", iconSystemName: "safari.fill")
]

struct ContentView: View {
    @State private var selectedAppID: UUID? = sampleApps.first?.id
    
    var body: some View {
        HStack(spacing: 20){
            ForEach(sampleApps) { app in
                VStack(alignment: .center) {
                    Image(systemName: app.iconSystemName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 64, height: 64)
                        .padding(12)
                        .background(selectedAppID == app.id ? Color.black.opacity(0.25) : Color.clear)
                        .cornerRadius(8)
                    Text(selectedAppID == app.id ? app.name : "")
                }
                .onTapGesture {
                    selectedAppID = app.id
                }
            }
        }
        .padding(25)
        .background(.regularMaterial)
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}
