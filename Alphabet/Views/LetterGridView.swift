import SwiftUI

/// The a–z + space grid. Tapping a letter calls `onTap`. Each cell publishes its frame
/// (the flight source). Cell size is clamped to a max so the grid can never visually
/// balloon, even if a sibling ever reported an oversized width.
struct LetterGridView: View {
    let space: String
    let onTap: (String) -> Void

    private let rows: [[String]] = [
        ["a", "b", "c", "d", "e", "f"],
        ["g", "h", "i", "j", "k", "l", "m"],
        ["n", "o", "p", "q", "r", "s", "t"],
        ["u", "v", "w", "x", "y", "z", " "],
    ]

    var body: some View {
        GeometryReader { geo in
            let cols = 7
            let spacing: CGFloat = 14
            let cell = min(96, max(40, min((geo.size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols),
                                           (geo.size.height - spacing * 3) / 4)))
            VStack(spacing: spacing) {
                ForEach(rows.indices, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(rows[r], id: \.self) { letter in
                            Button { onTap(letter) } label: {
                                TileView(letter: letter)
                                    .frame(width: cell, height: cell)
                                    .reportFrame(.grid(letter), in: space)
                            }
                            .buttonStyle(PressScaleStyle())
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
    }
}
