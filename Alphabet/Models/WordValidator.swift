import UIKit

/// Offline real-word check via the system spell-checker — so the app only pronounces
/// words that actually exist (no network / dictionary API needed). Tries lower-case and
/// capitalized forms (German nouns are capitalized), in the selected language.
enum WordValidator {
    static func isRealWord(_ word: String, language: AppLanguage) -> Bool {
        let raw = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard raw.count >= 1 else { return false }

        let available = UITextChecker.availableLanguages
        let preferred = language.textCheckerLanguage
        let lang = available.contains(preferred)
            ? preferred
            : (language == .german ? "de" : "en")

        let checker = UITextChecker()
        for candidate in [raw.lowercased(), raw.prefix(1).uppercased() + raw.dropFirst().lowercased()] {
            let range = NSRange(location: 0, length: candidate.utf16.count)
            let misspelled = checker.rangeOfMisspelledWord(
                in: candidate, range: range, startingAt: 0, wrap: false, language: lang)
            if misspelled.location == NSNotFound { return true }
        }
        return false
    }
}
