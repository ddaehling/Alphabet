import Foundation

/// One spoken step in a spell-then-say sequence.
///
/// A `.letter` step carries the plain `text` the synth would read by default *and* an
/// optional `ipa` phoneme. When `ipa` is non-nil the synth is told to pronounce that
/// IPA instead — i.e. the letter's SOUND (/k/) rather than its NAME ("see"). `trailing`
/// is the pause that follows the utterance; the blending pass shrinks it toward zero so
/// the sounds audibly pull together.
enum SpeechStep: Equatable {
    case letter(tileIndex: Int, text: String, ipa: String?, trailing: Double)
    case word(text: String)
}

/// Pure, testable sequencing of how a built word is spoken.
enum SpeechPlan {
    // MARK: Letter NAMES

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

    // MARK: Letter SOUNDS (phonemes, as IPA)
    //
    // The synth is given these as an IPA pronunciation hint so it produces the letter's
    // phoneme rather than its name. Values are the single most common ("first") sound a
    // beginning reader is taught. They are intentionally easy to tweak by ear — if a
    // voice mispronounces one, adjust the IPA string here.

    /// English (en-GB) primary phonemes.
    static let letterSound: [Character: String] = [
        "a": "æ", "b": "b", "c": "k", "d": "d", "e": "ɛ", "f": "f", "g": "ɡ",
        "h": "h", "i": "ɪ", "j": "dʒ", "k": "k", "l": "l", "m": "m", "n": "n",
        "o": "ɒ", "p": "p", "q": "kw", "r": "ɹ", "s": "s", "t": "t", "u": "ʌ",
        "v": "v", "w": "w", "x": "ks", "y": "j", "z": "z",
    ]

    /// German (de-DE) primary phonemes.
    static let germanLetterSound: [Character: String] = [
        "a": "a", "b": "b", "c": "k", "d": "d", "e": "ɛ", "f": "f", "g": "ɡ",
        "h": "h", "i": "ɪ", "j": "j", "k": "k", "l": "l", "m": "m", "n": "n",
        "o": "ɔ", "p": "p", "q": "kv", "r": "ʁ", "s": "z", "t": "t", "u": "ʊ",
        "v": "f", "w": "v", "x": "ks", "y": "ʏ", "z": "ts",
        "ä": "ɛ", "ö": "œ", "ü": "ʏ", "ß": "s",
    ]

    static func names(_ language: AppLanguage) -> [Character: String] {
        language == .german ? germanLetterName : letterName
    }

    static func sounds(_ language: AppLanguage) -> [Character: String] {
        language == .german ? germanLetterSound : letterSound
    }

    // MARK: Plan building

    private static let nameTrailing = 0.16
    private static let soundTrailing = 0.24
    private static let bothNameTrailing = 0.05   // quick gap before the sound in `.both`

    /// All non-space tiles with their original indices (so highlighting still lines up
    /// after spaces are skipped).
    private static func letterTiles(_ tiles: [Tile]) -> [(index: Int, ch: Character)] {
        tiles.enumerated().compactMap { i, t in
            t.isSpace ? nil : (i, Character(t.letter.lowercased()))
        }
    }

    private static func wordText(_ tiles: [Tile]) -> String {
        tiles.map { $0.isSpace ? " " : $0.letter }.joined()
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Builds the spoken sequence.
    ///
    /// - mode: names / sounds / both.
    /// - includeWord: append the whole word at the end (gated on it being a real word).
    /// - blend: when voicing sounds, add a compressed re-run of the phonemes (gaps
    ///   shrinking to zero) right before the word, so they audibly slide together.
    static func make(for tiles: [Tile],
                     language: AppLanguage = .englishUK,
                     mode: SpeechMode = .names,
                     includeWord: Bool = true,
                     blend: Bool = false) -> [SpeechStep] {
        let names = names(language)
        let sounds = sounds(language)
        let letters = letterTiles(tiles)
        var steps: [SpeechStep] = []

        for (index, ch) in letters {
            let name = names[ch] ?? String(ch)
            let ipa = sounds[ch]
            switch mode {
            case .names:
                steps.append(.letter(tileIndex: index, text: name, ipa: nil, trailing: nameTrailing))
            case .sounds:
                steps.append(.letter(tileIndex: index, text: name, ipa: ipa, trailing: soundTrailing))
            case .both:
                steps.append(.letter(tileIndex: index, text: name, ipa: nil, trailing: bothNameTrailing))
                steps.append(.letter(tileIndex: index, text: name, ipa: ipa, trailing: soundTrailing))
            }
        }

        // Blending pass: phonemes only, gaps shrinking to zero, then the word.
        if blend, includeWord, mode.usesSounds, letters.count >= 2 {
            let n = letters.count
            for (k, (index, ch)) in letters.enumerated() {
                let frac = Double(k) / Double(n - 1)            // 0 → 1
                let trailing = 0.14 * (1 - frac)                // 0.14 → 0
                steps.append(.letter(tileIndex: index, text: names[ch] ?? String(ch),
                                     ipa: sounds[ch], trailing: trailing))
            }
        }

        if includeWord {
            let word = wordText(tiles)
            if !word.isEmpty { steps.append(.word(text: word)) }
        }
        return steps
    }

    /// A single-letter plan for tap-to-hear, honouring the current mode (name, sound, or
    /// both). `tileIndex` is -1 since no tray tile is highlighted.
    static func makeSingle(letter: String, language: AppLanguage, mode: SpeechMode) -> [SpeechStep] {
        let ch = Character(letter.lowercased())
        let name = names(language)[ch] ?? letter
        let ipa = sounds(language)[ch]
        switch mode {
        case .names:
            return [.letter(tileIndex: -1, text: name, ipa: nil, trailing: 0)]
        case .sounds:
            return [.letter(tileIndex: -1, text: name, ipa: ipa, trailing: 0)]
        case .both:
            return [.letter(tileIndex: -1, text: name, ipa: nil, trailing: bothNameTrailing),
                    .letter(tileIndex: -1, text: name, ipa: ipa, trailing: 0)]
        }
    }
}
