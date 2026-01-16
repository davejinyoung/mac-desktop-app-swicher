import Foundation
import Combine

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    private enum Keys {
        static let shortcutModifierRaw = "shortcutModifierRaw"
        static let shortcutKey = "shortcutKey"
        static let quitAppKey = "quitAppKey"
        static let closeWindowKey = "closeWindowKey"
        static let newAppWindowKey = "newAppWindowKey"
        static let appIconSize = "appIconSizeKey"
        static let appsFromAllDeskops = "appsFromAllDeskops"
        static let continuousCycling = "continuousCycling"
        static let previewWindows = "previewWindows"
        static let showAllWindows = "showAllWindows"
        static let switchWindowsWhileCycling = "switchWindowsWhileCycling"
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
    
    @Published var quitAppKey: Int {
        didSet {
            UserDefaults.standard.set(quitAppKey, forKey: Keys.quitAppKey)
        }
    }
    
    @Published var closeWindowKey: Int {
        didSet {
            UserDefaults.standard.set(closeWindowKey, forKey: Keys.closeWindowKey)
        }
    }
    
    @Published var newAppWindowKey: Int {
        didSet {
            UserDefaults.standard.set(newAppWindowKey, forKey: Keys.newAppWindowKey)
        }
    }
    
    @Published var appsFromAllDeskops: Bool {
        didSet {
            UserDefaults.standard.set(appsFromAllDeskops, forKey: Keys.appsFromAllDeskops)
        }
    }
    
    @Published var continuousCycling: Bool {
        didSet {
            UserDefaults.standard.set(continuousCycling, forKey: Keys.continuousCycling)
        }
    }
    
    @Published var previewWindows: Bool {
        didSet {
            UserDefaults.standard.set(previewWindows, forKey: Keys.previewWindows)
        }
    }
    
    @Published var switchWindowsWhileCycling: Bool {
        didSet {
            UserDefaults.standard.set(switchWindowsWhileCycling, forKey: Keys.switchWindowsWhileCycling)
        }
    }
    
    @Published var showAllWindows: Bool {
        didSet {
            UserDefaults.standard.set(showAllWindows, forKey: Keys.showAllWindows)
        }
    }
    
    @Published var appIconSize: CGFloat {
        didSet {
            UserDefaults.standard.set(appIconSize, forKey: Keys.appIconSize)
        }
    }
    
    private init() {
        self.shortcutModifierRaw = UserDefaults.standard.object(forKey: Keys.shortcutModifierRaw) as? Int ?? 524576 // Option modifier
        self.shortcutKey = UserDefaults.standard.object(forKey: Keys.shortcutKey) as? Int ?? 48 // Tab key
        self.quitAppKey = UserDefaults.standard.object(forKey: Keys.quitAppKey) as? Int ?? 12 // Q key
        self.closeWindowKey = UserDefaults.standard.object(forKey: Keys.closeWindowKey) as? Int ?? 13 // W key
        self.newAppWindowKey = UserDefaults.standard.object(forKey: Keys.newAppWindowKey) as? Int ?? 45 // N key
        self.appsFromAllDeskops = UserDefaults.standard.object(forKey: Keys.appsFromAllDeskops) as? Bool ?? false
        self.continuousCycling = UserDefaults.standard.object(forKey: Keys.continuousCycling) as? Bool ?? false
        self.previewWindows = UserDefaults.standard.object(forKey: Keys.previewWindows) as? Bool ?? false
        self.switchWindowsWhileCycling = UserDefaults.standard.object(forKey: Keys.switchWindowsWhileCycling) as? Bool ?? false
        self.showAllWindows = UserDefaults.standard.object(forKey: Keys.showAllWindows) as? Bool ?? false
        self.appIconSize = UserDefaults.standard.object(forKey: Keys.appIconSize) as? CGFloat ?? 120
    }
}
