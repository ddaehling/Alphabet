import Foundation

/// A language the child can read/spell in. Each carries its own voice, letter names
/// (via SpeechPlan), real-word check (via WordValidator), grid letters, and word list.
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case englishUK
    case german

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .englishUK: "English"
        case .german: "Deutsch"
        }
    }

    /// Flag-ish emoji for the picker (kid-friendly, no text needed).
    var flag: String {
        switch self {
        case .englishUK: "🇬🇧"
        case .german: "🇩🇪"
        }
    }

    /// AVSpeechSynthesisVoice language code.
    var voiceLanguage: String {
        switch self {
        case .englishUK: "en-GB"
        case .german: "de-DE"
        }
    }

    /// Preferred UITextChecker language id (WordValidator falls back if unavailable).
    var textCheckerLanguage: String {
        switch self {
        case .englishUK: "en_GB"
        case .german: "de_DE"
        }
    }

    var wordsFile: String {
        switch self {
        case .englishUK: "words-en"
        case .german: "words-de"
        }
    }

    /// Grid rows of letters. German adds an Ä Ö Ü ß row.
    var gridRows: [[String]] {
        switch self {
        case .englishUK:
            [["a", "b", "c", "d", "e", "f"],
             ["g", "h", "i", "j", "k", "l", "m"],
             ["n", "o", "p", "q", "r", "s", "t"],
             ["u", "v", "w", "x", "y", "z", " "]]
        case .german:
            [["a", "b", "c", "d", "e", "f"],
             ["g", "h", "i", "j", "k", "l", "m"],
             ["n", "o", "p", "q", "r", "s", "t"],
             ["u", "v", "w", "x", "y", "z"],
             ["ä", "ö", "ü", "ß", " "]]
        }
    }
}
