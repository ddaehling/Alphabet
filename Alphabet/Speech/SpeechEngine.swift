import AVFoundation

/// Abstraction so `AppModel` can be unit-tested without invoking real audio.
@MainActor
protocol Speaking: AnyObject {
    /// Spells each letter — by name, by sound, or both, per `mode` — optionally blending
    /// the sounds and saying the whole word, in the given language.
    func speak(tiles: [Tile], language: AppLanguage, mode: SpeechMode,
               includeWord: Bool, blend: Bool, rate: Double,
               onHighlight: @escaping (Tile.ID?) -> Void,
               onFinish: @escaping () -> Void)
    /// Voices a single letter (for tap-to-hear / hint reveal), honouring `mode`.
    func speakLetter(_ letter: String, language: AppLanguage, mode: SpeechMode,
                     rate: Double, onFinish: @escaping () -> Void)
    func stop()
}

/// On-device spell-then-say speech. Offline; no API, no key. Reports which tile is being
/// spoken so the UI can highlight it, and fires `onFinish` once the final utterance ends.
@MainActor
final class SpeechEngine: NSObject, Speaking, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    private var stepForUtterance: [ObjectIdentifier: SpeechStep] = [:]
    private var tilesInFlight: [Tile] = []
    private var pending = 0
    private var onHighlight: ((Tile.ID?) -> Void)?
    private var onFinish: (() -> Void)?
    private var voiceCache: [String: AVSpeechSynthesisVoice] = [:]

    /// IPA pronunciation-hint attribute key (lets us voice a letter's SOUND, not its name).
    private static let ipaKey = NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute)

    override init() {
        super.init()
        synth.delegate = self
    }

    private func voice(_ language: AppLanguage) -> AVSpeechSynthesisVoice? {
        if let v = voiceCache[language.voiceLanguage] { return v }
        let v = AVSpeechSynthesisVoice(language: language.voiceLanguage)
        if let v { voiceCache[language.voiceLanguage] = v }
        return v
    }

    /// Builds an utterance for a step. A `.letter` with an IPA hint is delivered as an
    /// attributed string so the synth produces the phoneme; everything else is plain text.
    private func utterance(for step: SpeechStep, voice: AVSpeechSynthesisVoice?, rate: Double) -> AVSpeechUtterance {
        let u: AVSpeechUtterance
        switch step {
        case let .letter(_, text, ipa?, _):
            let attr = NSAttributedString(string: text, attributes: [Self.ipaKey: ipa])
            u = AVSpeechUtterance(attributedString: attr)
        case let .letter(_, text, nil, _):
            u = AVSpeechUtterance(string: text)
        case let .word(text):
            u = AVSpeechUtterance(string: text)
        }
        u.voice = voice
        u.rate = Float(rate)
        if case let .letter(_, _, _, trailing) = step { u.postUtteranceDelay = trailing }
        return u
    }

    private func enqueue(_ steps: [SpeechStep], language: AppLanguage, rate: Double) {
        guard !steps.isEmpty else { onFinish?(); onFinish = nil; return }
        pending = steps.count
        let v = voice(language)
        for step in steps {
            let u = utterance(for: step, voice: v, rate: rate)
            stepForUtterance[ObjectIdentifier(u)] = step
            synth.speak(u)
        }
    }

    func speak(tiles: [Tile], language: AppLanguage, mode: SpeechMode,
               includeWord: Bool, blend: Bool, rate: Double,
               onHighlight: @escaping (Tile.ID?) -> Void,
               onFinish: @escaping () -> Void) {
        stop()
        tilesInFlight = tiles
        self.onHighlight = onHighlight
        self.onFinish = onFinish
        let steps = SpeechPlan.make(for: tiles, language: language, mode: mode,
                                    includeWord: includeWord, blend: blend)
        enqueue(steps, language: language, rate: rate)
    }

    func speakLetter(_ letter: String, language: AppLanguage, mode: SpeechMode,
                     rate: Double, onFinish: @escaping () -> Void) {
        stop()
        tilesInFlight = []
        self.onHighlight = nil
        self.onFinish = onFinish
        let steps = SpeechPlan.makeSingle(letter: letter, language: language, mode: mode)
        enqueue(steps, language: language, rate: rate)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        stepForUtterance.removeAll()
        pending = 0
        onHighlight?(nil)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            if case let .letter(i, _, _, _)? = stepForUtterance[ObjectIdentifier(utterance)],
               tilesInFlight.indices.contains(i) {
                onHighlight?(tilesInFlight[i].id)
            } else {
                onHighlight?(nil)
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            stepForUtterance[ObjectIdentifier(utterance)] = nil
            pending -= 1
            if pending <= 0 {
                let finish = onFinish
                onHighlight?(nil)
                onFinish = nil
                finish?()
            }
        }
    }
}
