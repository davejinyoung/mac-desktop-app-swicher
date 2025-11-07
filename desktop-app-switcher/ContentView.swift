import AppKit
import SwiftUI

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = blendingMode
        view.material = material
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}


struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAppId: String?

    var body: some View {
        HStack {
            ForEach(appState.runningApps) { app in
                ZStack(alignment: .bottom) {
                    Image(nsImage: app.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: appState.appIconSize, height: appState.appIconSize)
                        .clipShape(RoundedRectangle(cornerRadius: appState.appIconSize * 0.2, style: .continuous))
                        .background(
                            Group {
                                if selectedAppId == app.id {
                                    RoundedRectangle(cornerRadius: appState.appIconSize * 0.2, style: .continuous)
                                        .fill(Color.gray.opacity(0.7))
                                        .padding(3)
                                }
                            }
                        )
                        .padding(.vertical, 5)
                    
                    Text(app.name)
                        .frame(width: appState.appIconSize)
                        .lineLimit(1)
                        .foregroundColor(selectedAppId == app.id ? Color.white : Color.clear)
                        .padding(.bottom, -12)
                }
                .onHover { hover in
                    if hover && appState.canHover {
                        appState.selectedAppId = app.id
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.clear, in: .rect(cornerRadius: 50))
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
