import Foundation

/// One spoken step in a spell-then-say sequence.
enum SpeechStep: Equatable {
    case letter(tileIndex: Int, spoken: String)   // the letter's NAME, e.g. "see"
    case word(spoken: String)                      // the whole assembled word
}

/// Pure, testable sequencing of how a built word is spoken:
/// each non-space letter is named in order, then the whole word is said once.
enum SpeechPlan {
    /// British-English letter names (teacher context is German-school EFL).
    static let letterName: [Character: String] = [
        "a": "ay", "b": "bee", "c": "see", "d": "dee", "e": "ee", "f": "eff", "g": "gee",
        "h": "aitch", "i": "eye", "j": "jay", "k": "kay", "l": "el", "m": "em", "n": "en",
        "o": "oh", "p": "pee", "q": "cue", "r": "ar", "s": "ess", "t": "tee", "u": "you",
        "v": "vee", "w": "double you", "x": "ex", "y": "why", "z": "zed",
    ]

    static func make(for tiles: [Tile]) -> [SpeechStep] {
        var steps: [SpeechStep] = []
        for (i, t) in tiles.enumerated() where !t.isSpace {
            let ch = Character(t.letter.lowercased())
            steps.append(.letter(tileIndex: i, spoken: letterName[ch] ?? t.letter))
        }
        let word = tiles.map { $0.isSpace ? " " : $0.letter }.joined()
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
        if !word.isEmpty { steps.append(.word(spoken: word)) }
        return steps
    }
}
