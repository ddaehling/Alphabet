import SwiftUI
import UIKit

/// Challenge prompt: a themed SF-Symbol picture, the word as blanks/filled
/// letters, and a hint button to hear the target word.
struct ChallengeCardView: View {
    let prompt: WordPrompt
    let filledCount: Int
    let onHint: () -> Void
    @Environment(\.theme) private var theme

    private var symbolName: String {
        UIImage(systemName: prompt.symbol) != nil ? prompt.symbol : "questionmark.circle"
    }

    var body: some View {
        HStack(spacing: 22) {
            Image(systemName: symbolName)
                .font(.system(size: 70))
                .foregroundStyle(LetterPalette.color(forLetter: prompt.word))
                .frame(width: 96, height: 96)

            HStack(spacing: 10) {
                ForEach(Array(prompt.word.enumerated()), id: \.offset) { idx, ch in
                    Text(idx < filledCount ? String(ch).uppercased() : "")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.uiTextOnSurface)
                        .frame(width: 44, height: 54)
                        .background(RoundedRectangle(cornerRadius: 10).fill(theme.slotFill))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.slotStroke, lineWidth: 2))
                }
            }

            Button(action: onHint) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(theme.uiTextOnSurface)
                    .padding(12)
                    .background(theme.slotFill, in: Circle())
            }
            .accessibilityLabel("Hear the word")
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(theme.traySurface))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(theme.slotStroke.opacity(0.6), lineWidth: 2))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
    }
}
