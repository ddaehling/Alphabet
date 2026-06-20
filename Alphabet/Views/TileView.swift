import SwiftUI

/// One glossy bubble letter on its theme-tinted contrast chip. The chip is the
/// legibility guarantee: every letter sits on its own saturated disc/square.
struct TileView: View {
    let letter: String
    var isHighlighted: Bool = false
    @Environment(\.theme) private var theme

    private var assetName: String { letter == " " ? "space" : letter }

    private var chipColor: Color {
        switch theme.tileChip.tint {
        case .letterColor: LetterPalette.color(forLetter: letter)
        case .neutralLight: Color.white.opacity(0.92)
        case .neutralDark: Color.black.opacity(0.28)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                chip(size: s)
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .padding(s * (letter == " " ? 0.30 : 0.16))
                    .opacity(letter == " " ? 0.5 : 1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .overlay { if isHighlighted { ring(size: s) } }
            .scaleEffect(isHighlighted ? 1.10 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isHighlighted)
        }
        .accessibilityElement()
        .accessibilityLabel(letter == " " ? "Space" : "Letter \(letter.uppercased())")
    }

    @ViewBuilder private func chip(size s: CGFloat) -> some View {
        shape
            .fill(chipColor)
            .overlay(alignment: .topLeading) {
                Ellipse()
                    .fill(.white.opacity(theme.tileChip.highlightOpacity))
                    .frame(width: s * 0.34, height: s * 0.22)
                    .offset(x: s * 0.16, y: s * 0.12)
                    .blur(radius: 0.5)
            }
            .shadow(color: .black.opacity(theme.tileChip.shadowOpacity), radius: s * 0.07, y: s * 0.05)
    }

    private func ring(size s: CGFloat) -> some View {
        shape.stroke(.white, lineWidth: 5).shadow(color: .white.opacity(0.85), radius: 8)
    }

    private var shape: AnyShape {
        switch theme.tileChip.shape {
        case .circle: AnyShape(Circle())
        case let .roundedSquare(r): AnyShape(RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }
}
