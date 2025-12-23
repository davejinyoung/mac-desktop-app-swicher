import AppKit
import SwiftUI

struct AppWindowPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAppId: String?

    var body: some View {
        ZStack {
            HStack {
                ForEach(appState.runningApps) { app in
                    VStack {
                        Image(nsImage: app.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(
                                Group {
                                    if selectedAppId == app.id {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.gray.opacity(0.7))
                                    }
                                }
                            )
                            
                            .overlay(alignment: .bottom) {
                                Text(app.name)
                                    .font(.system(size: 13, weight: .light, design: .default))
                                    .lineLimit(1)
                                    .foregroundColor(selectedAppId == app.id ? Color.white : Color.clear)
                                    .offset(y: 18)
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
            .glassEffect(.clear, in: .rect(cornerRadius: 15))
            .frame(width: appState.screenWidth - 80, height: appState.screenHeight)
            .onChange(of: appState.selectedAppId) {
                selectedAppId = appState.selectedAppId
            }
        }
        .frame(width: appState.screenWidth, height: appState.screenHeight, alignment: .center)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
