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
                VStack {
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
                                }
                            }
                        )
                        
                        .overlay(alignment: .bottom) {
                            Text(app.name)
                                .frame(width: appState.appIconSize * 0.8)
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
