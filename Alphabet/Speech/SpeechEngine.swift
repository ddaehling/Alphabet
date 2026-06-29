import AVFoundation

/// Abstraction so `AppModel` can be unit-tested without invoking real audio.
@MainActor
protocol Speaking: AnyObject {
    /// Spells each letter, optionally followed by the whole word, in the given language.
    func speak(tiles: [Tile], language: AppLanguage, includeWord: Bool, rate: Double,
               onHighlight: @escaping (Tile.ID?) -> Void,
               onFinish: @escaping () -> Void)
    /// Speaks a single letter's name (for the tap-to-hear mode); calls `onFinish` when done.
    func speakLetter(_ letter: String, language: AppLanguage, rate: Double,
                     onFinish: @escaping () -> Void)
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

    func speak(tiles: [Tile], language: AppLanguage, includeWord: Bool, rate: Double,
               onHighlight: @escaping (Tile.ID?) -> Void,
               onFinish: @escaping () -> Void) {
        stop()
        tilesInFlight = tiles
        self.onHighlight = onHighlight
        self.onFinish = onFinish
        let steps = SpeechPlan.make(for: tiles, language: language, includeWord: includeWord)
        guard !steps.isEmpty else { onFinish(); return }
        pending = steps.count
        let v = voice(language)
        for step in steps {
            let spoken: String
            switch step {
            case let .letter(_, s): spoken = s
            case let .word(s): spoken = s
            }
            let u = AVSpeechUtterance(string: spoken)
            u.voice = v
            u.rate = Float(rate)
            if case .letter = step { u.postUtteranceDelay = 0.18 }
            stepForUtterance[ObjectIdentifier(u)] = step
            synth.speak(u)
        }
    }

    func speakLetter(_ letter: String, language: AppLanguage, rate: Double,
                     onFinish: @escaping () -> Void) {
        stop()
        let name = SpeechPlan.names(language)[Character(letter.lowercased())] ?? letter
        let u = AVSpeechUtterance(string: name)
        u.voice = voice(language)
        u.rate = Float(rate)
        self.onHighlight = nil
        self.onFinish = onFinish
        pending = 1
        stepForUtterance[ObjectIdentifier(u)] = .letter(tileIndex: -1, spoken: name)
        synth.speak(u)
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
            if case let .letter(i, _)? = stepForUtterance[ObjectIdentifier(utterance)],
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
