import Foundation

/// How letters are voiced when spelling a word or tapping a tile.
///
/// - `names`  — the letter's *name* ("see", "ay", "tee"). What older spellers expect.
/// - `sounds` — the letter's *phoneme* (/k/, /a/, /t/). This is the phonics skill that
///   actually drives early decoding, so it's the recommended mode for new readers.
/// - `both`   — name first, then the sound, on each letter ("see … /k/").
///
/// In `sounds`/`both` the Speak button also runs a short **blending** pass — the sounds
/// are repeated pulling closer together before the whole word is said — which is the
/// single most pivotal early-reading step.
enum SpeechMode: String, CaseIterable, Identifiable, Codable {
    case names
    case sounds
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .names: "Names"
        case .sounds: "Sounds"
        case .both: "Both"
        }
    }

    /// Whether this mode voices letter phonemes (and therefore enables blending).
    var usesSounds: Bool { self != .names }
}
