import Foundation
import Combine

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    private enum Keys {
        static let shortcutModifierRaw = "shortcutModifierRaw"
        static let shortcutModifierReverseRaw = "shortcutModifierReverseRaw"
        static let shortcutKey = "shortcutKey"
    }
    
    @Published var shortcutModifierRaw: Int {
        didSet {
            UserDefaults.standard.set(shortcutModifierRaw, forKey: Keys.shortcutModifierRaw)
        }
    }
    
    @Published var shortcutModifierReverseRaw: Int {
        didSet {
            UserDefaults.standard.set(shortcutModifierReverseRaw, forKey: Keys.shortcutModifierReverseRaw)
        }
    }

    @Published var shortcutKey: Int {
        didSet {
            UserDefaults.standard.set(shortcutKey, forKey: Keys.shortcutKey)
        }
    }
    
    private init() {
        self.shortcutModifierRaw = UserDefaults.standard.object(forKey: Keys.shortcutModifierRaw) as? Int ?? 524576 // Option modifier
        self.shortcutModifierReverseRaw = UserDefaults.standard.object(forKey: Keys.shortcutModifierReverseRaw) as? Int ?? 655650 // Option+Shift modifier
        self.shortcutKey = UserDefaults.standard.object(forKey: Keys.shortcutKey) as? Int ?? 48 // Tab key
    }
}
