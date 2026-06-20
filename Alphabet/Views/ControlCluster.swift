import SwiftUI

/// Clear / Speak, plus Check in Challenge mode.
struct ControlCluster: View {
    @Bindable var model: AppModel
    @Environment(\.theme) private var theme

    private var canActOnWord: Bool { !model.tiles.isEmpty && !model.isSpeaking }

    var body: some View {
        HStack(spacing: 10) {
            GlossButton(systemImage: "arrow.counterclockwise", title: "Clear",
                        paint: theme.secondaryButton, enabled: canActOnWord) {
                withAnimation { model.clear() }
            }
            GlossButton(systemImage: "speaker.wave.2.fill", title: "Speak",
                        paint: theme.primaryButton, enabled: canActOnWord) {
                model.speakCurrentWord()
            }
            if model.mode == .challenge {
                GlossButton(systemImage: "checkmark", title: "Check",
                            paint: theme.primaryButton, enabled: canActOnWord) {
                    withAnimation { model.checkChallenge() }
                }
            }
        }
    }
}
