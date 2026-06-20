import SwiftUI

/// Holds the chosen theme and a couple of preferences, persisted across launches.
@MainActor
@Observable
final class ThemeStore {
    var id: ThemeID {
        didSet { UserDefaults.standard.set(id.rawValue, forKey: "themeID") }
    }
    var speechRate: Double {
        didSet { UserDefaults.standard.set(speechRate, forKey: "speechRate") }
    }
    var calmMode: Bool {
        didSet { UserDefaults.standard.set(calmMode, forKey: "calmMode") }
    }

    init() {
        let d = UserDefaults.standard
        id = ThemeID(rawValue: d.string(forKey: "themeID") ?? "") ?? .sunnySky
        speechRate = d.object(forKey: "speechRate") as? Double ?? 0.35
        calmMode = d.bool(forKey: "calmMode")
    }

    var theme: Theme { id.theme }
}
