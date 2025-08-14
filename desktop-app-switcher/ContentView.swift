import SwiftUI
import AppKit
import HotKey

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAppID: String?
    var hotKey = HotKey(key: .tab, modifiers: [.option, .command])
    
    var body: some View {
        HStack(){
            ForEach(appState.runningApps) { app in
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
        .onChange(of: appState.runningApps) {
            selectedAppID = appState.runningApps.first?.id
        }
    }
}

#Preview {
    ContentView()
}
