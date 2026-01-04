import AppKit
import SwiftUI

struct EmptyWindowsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAppId: String?

    var body: some View {
        HStack {
            Text("No Available Windows")
        }
        .padding(25)
        .glassEffect(.clear, in: .rect(cornerRadius: 15))
        .frame(width: appState.screenWidth, height: appState.screenHeight, alignment: .center)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
