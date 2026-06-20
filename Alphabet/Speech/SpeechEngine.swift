import AVFoundation

/// Abstraction so `AppModel` can be unit-tested without invoking real audio.
@MainActor
protocol Speaking: AnyObject {
    func speak(tiles: [Tile], rate: Double,
               onHighlight: @escaping (Tile.ID?) -> Void,
               onFinish: @escaping () -> Void)
    func speakWordOnly(_ text: String, rate: Double)
    func stop()
}

/// On-device spell-then-say speech. Enqueues one utterance per letter (named) plus
/// a final whole-word utterance, and reports which tile is being spoken so the UI
/// can highlight it in sync. Fully offline; no API, no key.
@MainActor
final class SpeechEngine: NSObject, Speaking, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    private var stepForUtterance: [ObjectIdentifier: SpeechStep] = [:]
    private var tilesInFlight: [Tile] = []
    private var onHighlight: ((Tile.ID?) -> Void)?
    private var onFinish: (() -> Void)?
    private let voice = AVSpeechSynthesisVoice(language: "en-GB")

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(tiles: [Tile],
               rate: Double,
               onHighlight: @escaping (Tile.ID?) -> Void,
               onFinish: @escaping () -> Void) {
        stop()
        tilesInFlight = tiles
        self.onHighlight = onHighlight
        self.onFinish = onFinish
        let steps = SpeechPlan.make(for: tiles)
        guard !steps.isEmpty else { onFinish(); return }
        for step in steps {
            let spoken: String
            switch step {
            case let .letter(_, s): spoken = s
            case let .word(s): spoken = s
            }
            let u = AVSpeechUtterance(string: spoken)
            u.voice = voice
            u.rate = Float(rate)
            if case .letter = step { u.postUtteranceDelay = 0.18 }
            stepForUtterance[ObjectIdentifier(u)] = step
            synth.speak(u)
        }
    }

    func speakWordOnly(_ text: String, rate: Double) {
        stop()
        let u = AVSpeechUtterance(string: text)
        u.voice = voice
        u.rate = Float(rate)
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        stepForUtterance.removeAll()
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
            let isWord: Bool
            if case .word? = stepForUtterance[ObjectIdentifier(utterance)] { isWord = true }
            else { isWord = false }
            if isWord {
                onHighlight?(nil)
                onFinish?()
            }
        }
    }
}
