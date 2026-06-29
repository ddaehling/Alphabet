import SwiftUI
import UIKit

/// Challenge prompt: a themed SF-Symbol picture, the word as blanks/filled letters, and a
/// hint button to hear the target word.
///
/// `revealedHints` (raised by each wrong attempt) shows that many leading answer letters
/// as faint "ghost" hints, and the next slot to fill gently pulses — graduated scaffolding
/// instead of just buzzing on a wrong guess.
struct ChallengeCardView: View {
    let prompt: WordPrompt
    let filledCount: Int
    var revealedHints: Int = 0
    let onHint: () -> Void
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    private var symbolName: String {
        UIImage(systemName: prompt.symbol) != nil ? prompt.symbol : "questionmark.circle"
    }

    private var count: Int { prompt.word.count }

    var body: some View {
        HStack(spacing: 22) {
            Image(systemName: symbolName)
                .font(.system(size: 70))
                .foregroundStyle(LetterPalette.color(forLetter: prompt.word))
                .frame(width: 96, height: 96)

            HStack(spacing: 10) {
                ForEach(Array(prompt.word.enumerated()), id: \.offset) { idx, ch in
                    slot(idx: idx, ch: ch)
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
        .onAppear { pulse = true }
    }

    @ViewBuilder private func slot(idx: Int, ch: Character) -> some View {
        let revealed = max(filledCount, revealedHints)      // letters to show at all
        let isHint = idx >= filledCount && idx < revealedHints
        let isNext = idx == filledCount && idx < count && revealedHints > 0
        let active = isNext && pulse && !reduceMotion

        Text(idx < revealed ? String(ch).uppercased() : "")
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundStyle(isHint ? theme.uiTextOnSurface.opacity(0.4) : theme.uiTextOnSurface)
            .frame(width: 44, height: 54)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.slotFill))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(isNext ? Color.accentColor : theme.slotStroke, lineWidth: isNext ? 3 : 2))
            .scaleEffect(active ? 1.07 : 1)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.65).repeatForever(autoreverses: true),
                       value: active)
    }
}
