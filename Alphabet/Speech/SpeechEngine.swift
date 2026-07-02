import AVFoundation

/// Abstraction so `AppModel` can be unit-tested without invoking real audio.
@MainActor
protocol Speaking: AnyObject {
    /// Spells each letter — by name, by sound, or both, per `mode` — optionally blending
    /// the sounds, then says the whole word. When `useOnline` is set, the whole-word step
    /// prefers a real cached recording (see `PronunciationStore`), falling back to speech.
    func speak(tiles: [Tile], language: AppLanguage, mode: SpeechMode,
               includeWord: Bool, blend: Bool, useOnline: Bool, rate: Double,
               onHighlight: @escaping (Tile.ID?) -> Void,
               onFinish: @escaping () -> Void)
    /// Voices a single letter (for tap-to-hear / hint reveal), honouring `mode`.
    func speakLetter(_ letter: String, language: AppLanguage, mode: SpeechMode,
                     rate: Double, onFinish: @escaping () -> Void)
    func stop()
}

/// On-device spell-then-say speech (offline; no API, no key), with an optional real-word
/// recording for the final "say the word" step. Reports which tile is being spoken so the
/// UI can highlight it, and fires `onFinish` once the last sound ends.
@MainActor
final class SpeechEngine: NSObject, Speaking, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    private let synth = AVSpeechSynthesizer()
    private let store = PronunciationStore.shared
    private var stepForUtterance: [ObjectIdentifier: SpeechStep] = [:]
    private var tilesInFlight: [Tile] = []
    private var pending = 0
    private var onHighlight: ((Tile.ID?) -> Void)?
    private var onFinish: (() -> Void)?
    private var voiceCache: [String: AVSpeechSynthesisVoice] = [:]
    private var player: AVAudioPlayer?
    /// The whole-word step, deferred until after spelling so it can be a recording or speech.
    private var pendingWord: (text: String, language: AppLanguage, rate: Double, online: Bool)?

    /// IPA pronunciation-hint attribute key (lets us voice a letter's SOUND, not its name).
    private static let ipaKey = NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute)

    override init() {
        super.init()
        synth.delegate = self
    }

    private func voice(_ language: AppLanguage) -> AVSpeechSynthesisVoice? {
        let code = language.voiceLanguage
        if let v = voiceCache[code] { return v }
        let v = VoiceCatalog.bestVoice(for: language)
        if let v { voiceCache[code] = v }
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

    func speak(tiles: [Tile], language: AppLanguage, mode: SpeechMode,
               includeWord: Bool, blend: Bool, useOnline: Bool, rate: Double,
               onHighlight: @escaping (Tile.ID?) -> Void,
               onFinish: @escaping () -> Void) {
        stop()
        tilesInFlight = tiles
        self.onHighlight = onHighlight
        self.onFinish = onFinish
        var steps = SpeechPlan.make(for: tiles, language: language, mode: mode,
                                    includeWord: includeWord, blend: blend)
        // Peel the trailing whole-word step off; it's handled specially after spelling.
        if includeWord, case let .word(text)? = steps.last {
            steps.removeLast()
            pendingWord = (text, language, rate, useOnline)
            if useOnline { Task { await store.prefetch(word: text, language: language) } }  // head start
        } else {
            pendingWord = nil
        }
        startSpelling(steps, language: language, rate: rate)
    }

    func speakLetter(_ letter: String, language: AppLanguage, mode: SpeechMode,
                     rate: Double, onFinish: @escaping () -> Void) {
        stop()
        tilesInFlight = []
        self.onHighlight = nil
        self.onFinish = onFinish
        pendingWord = nil
        let steps = SpeechPlan.makeSingle(letter: letter, language: language, mode: mode)
        startSpelling(steps, language: language, rate: rate)
    }

    private func startSpelling(_ steps: [SpeechStep], language: AppLanguage, rate: Double) {
        guard !steps.isEmpty else { runWordPhaseOrFinish(); return }
        pending = steps.count
        let v = voice(language)
        for step in steps {
            let u = utterance(for: step, voice: v, rate: rate)
            stepForUtterance[ObjectIdentifier(u)] = step
            synth.speak(u)
        }
    }

    /// After spelling: play the whole word as a cached recording if we have one, else say
    /// it with the built-in voice (and kick off a download so next time it's the recording).
    private func runWordPhaseOrFinish() {
        guard let w = pendingWord else { finishAll(); return }
        pendingWord = nil
        onHighlight?(nil)
        if w.online, let file = store.cachedFileURL(word: w.text, language: w.language),
           playWordFile(file) {
            return   // AVAudioPlayerDelegate finishes the sequence
        }
        if w.online { Task { await store.prefetch(word: w.text, language: w.language) } }
        speakWordViaSynth(w.text, language: w.language, rate: w.rate)
    }

    private func playWordFile(_ url: URL) -> Bool {
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return false }
        player = p
        p.delegate = self
        return p.play()
    }

    private func speakWordViaSynth(_ text: String, language: AppLanguage, rate: Double) {
        let step = SpeechStep.word(text: text)
        let u = utterance(for: step, voice: voice(language), rate: rate)
        stepForUtterance[ObjectIdentifier(u)] = step
        pending = 1
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        player?.stop()
        player = nil
        stepForUtterance.removeAll()
        pending = 0
        pendingWord = nil
        onHighlight?(nil)
    }

    private func finishAll() {
        let finish = onFinish
        onHighlight?(nil)
        onFinish = nil
        finish?()
    }

    // MARK: AVSpeechSynthesizerDelegate

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
            if pending <= 0 { runWordPhaseOrFinish() }
        }
    }

    // MARK: AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.player = nil
            finishAll()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.player = nil
            finishAll()
        }
    }
}
