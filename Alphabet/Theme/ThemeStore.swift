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
    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "language") }
    }
    /// Speak each letter aloud when tapped (with a brief cooldown before the next tap).
    var soundOnTap: Bool {
        didSet { UserDefaults.standard.set(soundOnTap, forKey: "soundOnTap") }
    }
    /// Voice letters by name, sound (phonics), or both.
    var speechMode: SpeechMode {
        didSet { UserDefaults.standard.set(speechMode.rawValue, forKey: "speechMode") }
    }

    init() {
        let d = UserDefaults.standard
        id = ThemeID(rawValue: d.string(forKey: "themeID") ?? "") ?? .sunnySky
        speechRate = d.object(forKey: "speechRate") as? Double ?? 0.35
        calmMode = d.bool(forKey: "calmMode")
        language = AppLanguage(rawValue: d.string(forKey: "language") ?? "") ?? .englishUK
        soundOnTap = d.bool(forKey: "soundOnTap")
        speechMode = SpeechMode(rawValue: d.string(forKey: "speechMode") ?? "") ?? .names
    }

    var theme: Theme { id.theme }
}
