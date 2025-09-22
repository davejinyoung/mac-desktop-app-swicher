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
                        .frame(width: 120, height: 120)
                        .background(
                            selectedAppId == app.id ? Color.black.opacity(0.5) : Color.clear
                        )
                        .cornerRadius(8)
                        .padding(4)
                    
                    Text(app.name)
                        .lineLimit(1)
                        .foregroundColor(selectedAppId == app.id ? Color.white : Color.clear)
                        .padding(.bottom, -15)
                }
                .onHover { hover in
                    if hover && appState.canHover {
                        appState.selectedAppId = app.id
                    }
                }
            }
        }
        .padding(20)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(20)
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
