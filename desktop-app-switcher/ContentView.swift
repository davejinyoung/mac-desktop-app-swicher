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
                            Group {
                                if selectedAppId == app.id {
                                    RoundedRectangle(cornerRadius: 32)
                                        .fill(Color.gray.opacity(0.7))
                                        .frame(width: 114, height: 114)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                        .cornerRadius(30)
                        .padding(.vertical, 5)
                    
                    Text(app.name)
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
        .glassEffect(in: .rect(cornerRadius: 50))
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
