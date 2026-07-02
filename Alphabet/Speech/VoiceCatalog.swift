import AVFoundation

/// Picks the most natural installed voice for a language.
///
/// iOS ships a low-quality **compact** voice for each language by default and only the
/// far more natural **enhanced / premium** neural voices sound human — but those are an
/// opt-in download (Settings → Accessibility → Spoken Content → Voices). We therefore
/// choose the best quality actually present and fall back gracefully.
enum VoiceCatalog {
    private static func rank(_ q: AVSpeechSynthesisVoiceQuality) -> Int {
        switch q {
        case .premium: 3
        case .enhanced: 2
        default: 1          // .default == compact
        }
    }

    /// All installed voices for the language, exact matches ("en-GB") preferred over
    /// same-language-different-region ("en-US") ones.
    private static func candidates(for language: AppLanguage) -> [AVSpeechSynthesisVoice] {
        let code = language.voiceLanguage
        let all = AVSpeechSynthesisVoice.speechVoices()
        let exact = all.filter { $0.language == code }
        if !exact.isEmpty { return exact }
        let prefix = String(code.prefix(2))     // "en", "de"
        return all.filter { $0.language.hasPrefix(prefix) }
    }

    /// The best-quality installed voice, or the system default as a last resort.
    static func bestVoice(for language: AppLanguage) -> AVSpeechSynthesisVoice? {
        candidates(for: language).max { rank($0.quality) < rank($1.quality) }
            ?? AVSpeechSynthesisVoice(language: language.voiceLanguage)
    }

    /// True when a natural (enhanced or premium) voice is installed for the language.
    /// When false, the app can suggest downloading one for a big quality jump.
    static func hasNaturalVoice(for language: AppLanguage) -> Bool {
        candidates(for: language).contains { $0.quality != .default }
    }
}
