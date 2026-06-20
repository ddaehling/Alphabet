import SwiftUI

struct RootView: View {
    @Bindable var model: AppModel
    @Bindable var themeStore: ThemeStore
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var shake: CGFloat = 0

    private var calm: Bool { themeStore.calmMode || systemReduceMotion }
    private var spring: Animation {
        calm ? .easeInOut(duration: 0.2)
             : .spring(response: themeStore.theme.motion.springResponse,
                       dampingFraction: themeStore.theme.motion.springDamping)
    }

    var body: some View {
        ZStack {
            ThemeBackground(id: themeStore.id)

            VStack(spacing: 16) {
                ModeSwitcher(model: model)

                if model.mode == .challenge, let p = model.challenge?.current {
                    ChallengeCardView(prompt: p, filledCount: model.tiles.count) {
                        model.speakChallengeHint()
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                LetterGridView { letter in
                    withAnimation(spring) { model.tapLetter(letter) }
                }
                .frame(maxHeight: .infinity)

                WordTrayView(model: model, reduceMotion: calm)
                    .modifier(ShakeEffect(animatableData: shake))
            }
            .padding(24)

            if model.mode == .challenge, model.challenge?.isFinished == true {
                finishedCard.transition(.scale.combined(with: .opacity))
            }

            if model.mode == .challenge, model.challenge?.status == .correct {
                CelebrationOverlay(style: themeStore.theme.celebration, reduceMotion: calm)
            }

            VStack {
                HStack { Spacer(); gearButton }
                Spacer()
            }
            .padding(20)
        }
        .environment(\.theme, themeStore.theme)
        .animation(.easeInOut(duration: 0.4), value: themeStore.id)
        .sheet(isPresented: $model.showThemePicker) {
            ThemePickerSheet(store: themeStore)
        }
        .onChange(of: model.challenge?.status) { _, status in
            switch status {
            case .correct:
                Task {
                    try? await Task.sleep(for: .seconds(2.2))
                    withAnimation(spring) { model.advanceChallenge() }
                }
            case .wrong:
                withAnimation(.linear(duration: 0.45)) { shake += 1 }
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    model.clearWrongStatus()
                }
            default:
                break
            }
        }
    }

    private var gearButton: some View {
        Button { model.showThemePicker = true } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(themeStore.theme.uiTextOnBackground.opacity(0.6))
                .padding(12)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Themes and settings")
    }

    private var finishedCard: some View {
        VStack(spacing: 16) {
            Text("You did them all!")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Image(systemName: "star.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color(hex: "F4B400"))
            Button("Play again") {
                withAnimation(spring) { model.restartChallenge() }
            }
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(themeStore.theme.traySurface))
        .foregroundStyle(themeStore.theme.uiTextOnSurface)
        .shadow(radius: 20)
    }
}

/// Gentle horizontal jiggle for a wrong Challenge attempt.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0))
    }
}
