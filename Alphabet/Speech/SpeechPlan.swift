import Foundation

/// One spoken step in a spell-then-say sequence.
enum SpeechStep: Equatable {
    case letter(tileIndex: Int, spoken: String)   // the letter's NAME, e.g. "see"
    case word(spoken: String)                      // the whole assembled word
}

/// Pure, testable sequencing of how a built word is spoken: each non-space letter is
/// named in order, then (optionally) the whole word is said once.
enum SpeechPlan {
    /// British-English letter names.
    static let letterName: [Character: String] = [
        "a": "ay", "b": "bee", "c": "see", "d": "dee", "e": "ee", "f": "eff", "g": "gee",
        "h": "aitch", "i": "eye", "j": "jay", "k": "kay", "l": "el", "m": "em", "n": "en",
        "o": "oh", "p": "pee", "q": "cue", "r": "ar", "s": "ess", "t": "tee", "u": "you",
        "v": "vee", "w": "double you", "x": "ex", "y": "why", "z": "zed",
    ]

    /// German letter names, spelled so the de-DE voice pronounces them correctly.
    static let germanLetterName: [Character: String] = [
        "a": "ah", "b": "beh", "c": "tseh", "d": "deh", "e": "eh", "f": "eff", "g": "geh",
        "h": "hah", "i": "ie", "j": "jott", "k": "kah", "l": "ell", "m": "emm", "n": "enn",
        "o": "oh", "p": "peh", "q": "kuh", "r": "err", "s": "ess", "t": "teh", "u": "uh",
        "v": "fau", "w": "weh", "x": "iks", "y": "üpsilon", "z": "zett",
        "ä": "äh", "ö": "öh", "ü": "üh", "ß": "eszett",
    ]

    static func names(_ language: AppLanguage) -> [Character: String] {
        language == .german ? germanLetterName : letterName
    }

    static func make(for tiles: [Tile],
                     language: AppLanguage = .englishUK,
                     includeWord: Bool = true) -> [SpeechStep] {
        var steps: [SpeechStep] = []
        let names = names(language)
        for (i, t) in tiles.enumerated() where !t.isSpace {
            let ch = Character(t.letter.lowercased())
            steps.append(.letter(tileIndex: i, spoken: names[ch] ?? t.letter))
        }
        if includeWord {
            let word = tiles.map { $0.isSpace ? " " : $0.letter }.joined()
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespaces)
            if !word.isEmpty { steps.append(.word(spoken: word)) }
        }
        return steps
    }
}
