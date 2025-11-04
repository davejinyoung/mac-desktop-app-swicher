import Foundation
import Combine

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    private enum Keys {
        static let shortcutModifierRaw = "shortcutModifierRaw"
        static let shortcutKey = "shortcutKey"
    }
    
    @Published var shortcutModifierRaw: Int {
        didSet {
            UserDefaults.standard.set(shortcutModifierRaw, forKey: Keys.shortcutModifierRaw)
        }
    }

    @Published var shortcutKey: Int {
        didSet {
            UserDefaults.standard.set(shortcutKey, forKey: Keys.shortcutKey)
        }
    }
    
    private init() {
        self.shortcutModifierRaw = UserDefaults.standard.object(forKey: Keys.shortcutModifierRaw) as? Int ?? 524576 // Option modifier
        self.shortcutKey = UserDefaults.standard.object(forKey: Keys.shortcutKey) as? Int ?? 48 // Tab key
    }
}
