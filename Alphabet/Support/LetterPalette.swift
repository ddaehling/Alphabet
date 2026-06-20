import SwiftUI

/// A curated rainbow, keyed by alphabetical index, used to tint each letter's
/// contrast chip so any glossy letter reads clearly on any background.
enum LetterPalette {
    static let hues: [String] = [
        "F4B400", "EC3E8E", "F37A1A", "27B85F", "27A6E0", "7B4FD6", "EE4F3C",
        "1FB68A", "3A66E0", "8A4FE0", "D63AA0", "F08020", "4FAE2A",
    ]

    static func color(for ch: Character) -> Color {
        guard let s = ch.lowercased().unicodeScalars.first,
              s.value >= 97, s.value <= 122 else {
            return Color(hex: "9AA0A6")
        }
        return Color(hex: hues[Int(s.value - 97) % hues.count])
    }

    static func color(forLetter letter: String) -> Color {
        color(for: letter.first ?? " ")
    }

    /// Letters whose 3D art is light/warm enough to risk vanishing on the light themes,
    /// so they get a soft dark rim halo there. Measured from the rendered letter PNGs'
    /// mean opaque luminance (see scripts/measure_luminance); refined after generation.
    static let paleArt: Set<Character> = ["a", "d", "f", "i", "k", "n", "p", "s", "u", "x"]

    static func isPaleArt(_ letter: String) -> Bool {
        guard let c = letter.lowercased().first else { return false }
        return paleArt.contains(c)
    }
}
