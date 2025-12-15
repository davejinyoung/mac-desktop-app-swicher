import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAppId: String?

    var body: some View {
        let appBackgroundSize = appState.appIconSize + (0.03125 * (200-appState.appIconSize))
        let appBackgroundCornerRadius = 13 + (((appState.appIconSize - 40) / 160) * 37) // max=50, min=13
        let panelCornerRadius = 20 + (((appState.appIconSize - 40) / 160) * 40) // max=60, min=20
        
        HStack {
            ForEach(appState.runningApps) { app in
                VStack {
                    Image(nsImage: app.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: appState.appIconSize, height: appState.appIconSize)
                        .clipShape(RoundedRectangle(cornerRadius: appState.appIconSize * 0.2, style: .continuous))
                        .background(
                            Group {
                                if selectedAppId == app.id {
                                    RoundedRectangle(cornerRadius: appBackgroundCornerRadius, style: .continuous)
                                        .fill(Color.gray.opacity(0.7))
                                        .frame(width: appBackgroundSize, height: appBackgroundSize)
                                        
                                }
                            }
                        )
                        
                        .overlay(alignment: .bottom) {
                            Text(app.name)
                                .frame(width: appState.appIconSize * 0.8)
                                .font(.system(size: 13, weight: .regular, design: .default))
                                .lineLimit(1)
                                .foregroundColor(selectedAppId == app.id ? Color.white : Color.clear)
                                .offset(y: 19)
                        }
                }
                .onHover { hover in // The onHover now wraps the whole item
                    if hover && appState.canHover {
                        appState.selectedAppId = app.id
                    }
                }
            }
        }
        .padding(25)
        .glassEffect(.clear, in: .rect(cornerRadius: panelCornerRadius))
        .frame(width: appState.screenWidth, height: appState.screenHeight)
        .onChange(of: appState.selectedAppId) {
            selectedAppId = appState.selectedAppId
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
