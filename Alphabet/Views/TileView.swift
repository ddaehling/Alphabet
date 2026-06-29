import SwiftUI

/// One standalone glossy 3D bubble letter — no chip. Legibility comes from the art's
/// own same-hue dark outline plus a per-theme contact shadow and an optional rim halo
/// (dark rim for pale letters on light themes; white rim for all letters on dark themes).
struct TileView: View {
    let letter: String
    var isHighlighted: Bool = false
    @Environment(\.theme) private var theme

    private static let assetOverrides: [String: String] = [
        " ": "space", "ä": "aumlaut", "ö": "oumlaut", "ü": "uumlaut", "ß": "eszett",
    ]
    private var assetName: String { Self.assetOverrides[letter] ?? letter }
    private var isSpace: Bool { letter == " " }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Image(assetName)
                .resizable()
                .scaledToFit()
                .padding(s * (isSpace ? 0.30 : 0.10))
                .opacity(isSpace ? 0.5 : 1)
                .frame(width: geo.size.width, height: geo.size.height)
                // Halo first (rim only, transparent center), then the grounding contact shadow.
                .shadow(color: isSpace ? .clear : haloColor,
                        radius: s * (theme.letterHalo?.radiusFactor ?? 0))
                .shadow(color: isSpace ? .clear : theme.letterShadow.color,
                        radius: s * theme.letterShadow.radiusFactor,
                        x: 0, y: s * theme.letterShadow.dyFactor)
                // Challenge-selection focus glow — deliberately distinct from the always-on halo.
                .shadow(color: isHighlighted ? .white.opacity(0.9) : .clear, radius: s * 0.10)
                .scaleEffect(isHighlighted ? 1.10 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isHighlighted)
        }
        .accessibilityElement()
        .accessibilityLabel(isSpace ? "Space" : "Letter \(letter.uppercased())")
    }

    /// Resolve the rim color: white halo applies to all letters; a dark halo applies only
    /// to letters whose art is pale enough to risk vanishing on a light background.
    private var haloColor: Color {
        guard let halo = theme.letterHalo else { return .clear }
        if halo.appliesToAll { return halo.color }
        return LetterPalette.isPaleArt(letter) ? halo.color : .clear
    }
}
