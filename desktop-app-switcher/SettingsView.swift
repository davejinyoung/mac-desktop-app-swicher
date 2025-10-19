// Create a new SwiftUI settings view to show in the settings window.
import SwiftUI

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title)
                .padding(.bottom, 16)
            
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .padding(.bottom, 8)
            
            Spacer()
        }
        .padding(32)
        .frame(width: 340, height: 180)
    }
}

#Preview {
    SettingsView()
}
