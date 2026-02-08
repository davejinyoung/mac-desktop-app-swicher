import AppKit
import SwiftUI

struct AppWindowPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAppId: String?

    var body: some View {
        ZStack {
            HStack {
                ForEach(appState.runningApps) { app in
                    let title = app.window.title
                    let caption = (title != "") ? "\(app.name) | \(title ?? "")" : app.name
                    VStack {
                        Image(nsImage: app.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: appState.appIconSize * 0.2, style: .continuous))
                        
                        Image(nsImage: app.thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipped()
                            .frame(maxHeight: 200)
                            .padding(8)
                            .background(
                                Group {
                                    if SettingsStore.shared.showAllWindows && SettingsStore.shared.activateAllWindows {
                                        if appState.getPidofSelectedApp() == app.pid {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color.gray.opacity(0.7))
                                        }
                                    } else {
                                        if selectedAppId == app.id {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color.gray.opacity(0.7))
                                        }
                                    }
                                }
                            )
                            .overlay(alignment: .bottom) {
                                Text(caption)
                                    .font(.system(size: 13, weight: .regular, design: .default))
                                    .lineLimit(1)
                                    .foregroundColor(selectedAppId == app.id ? Color.white : Color.clear)
                                    .offset(y: 19)
                            }
                    }
                    .onHover { hover in
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
