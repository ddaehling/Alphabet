import SwiftUI

struct RootView: View {
    @Bindable var model: AppModel
    @Bindable var themeStore: ThemeStore
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @State private var shake: CGFloat = 0
    @State private var frames: [FrameID: CGRect] = [:]
    private let flightSpace = "flight"

    private var calm: Bool { themeStore.calmMode || systemReduceMotion }
    private var spring: Animation {
        calm ? .easeInOut(duration: 0.2)
             : .spring(response: themeStore.theme.motion.springResponse,
                       dampingFraction: themeStore.theme.motion.springDamping)
    }

    var body: some View {
        styledStack
            .sheet(isPresented: $model.showThemePicker) {
                ThemePickerSheet(store: themeStore)
            }
            .onChange(of: model.challenge?.status) { _, status in handleChallengeStatus(status) }
            .onAppear {
                model.soundOnTap = themeStore.soundOnTap
                model.speechMode = themeStore.speechMode
                if model.language != themeStore.language { model.setLanguage(themeStore.language) }
            }
            .onChange(of: themeStore.language) { _, lang in withAnimation(spring) { model.setLanguage(lang) } }
            .onChange(of: themeStore.soundOnTap) { _, on in model.soundOnTap = on }
            .onChange(of: themeStore.speechMode) { _, m in model.speechMode = m }
            .onChange(of: model.nonWordNudge) { _, _ in
                withAnimation(.linear(duration: 0.4)) { shake += 1 }   // gentle "not a word yet" wiggle
            }
            .sensoryFeedback(trigger: model.tiles.count) { old, new in tileFeedback(old, new) }
            .sensoryFeedback(trigger: model.challenge?.status) { _, status in statusFeedback(status) }
            .sensoryFeedback(.warning, trigger: model.nonWordNudge)
            .task { await runFlyDemoIfRequested() }
    }

    private var styledStack: some View {
        ZStack {
            ThemeBackground(id: themeStore.id)
            mainColumn.padding(24)
            FlightLayer(flights: model.flights, frames: frames,
                        arcHeight: themeStore.theme.motion.flyArcHeight,
                        animation: spring) { id in model.completeFlight(id) }
            if model.mode == .challenge, model.challenge?.isFinished == true {
                finishedCard.transition(.scale.combined(with: .opacity))
            }
            if model.mode == .challenge, model.challenge?.status == .correct {
                CelebrationOverlay(style: themeStore.theme.celebration, reduceMotion: calm)
            }
            VStack { HStack { Spacer(); gearButton }; Spacer() }.padding(20)
        }
        .coordinateSpace(name: flightSpace)
        .onPreferenceChange(TileFrameKey.self) { frames = $0 }
        .environment(\.theme, themeStore.theme)
        .animation(.easeInOut(duration: 0.4), value: themeStore.id)
    }

    // MARK: Main column

    @ViewBuilder private var mainColumn: some View {
        VStack(spacing: 14) {
            ModeSwitcher(model: model)

            if model.mode == .challenge, let prompt = model.challenge?.current {
                ChallengeCardView(prompt: prompt, filledCount: model.tiles.count,
                                  revealedHints: model.challenge?.hintLevel ?? 0) {
                    model.speakChallengeHint()
                }
                .transition(.scale.combined(with: .opacity))
            }

            LetterGridView(space: flightSpace, rows: model.language.gridRows) { letter in
                if !model.tapLetter(letter, fly: !calm) {
                    withAnimation(.linear(duration: 0.4)) { shake += 1 }
                }
            }
            .frame(maxHeight: .infinity)
            .opacity(model.inputLocked ? 0.6 : 1)
            .animation(.easeOut(duration: 0.15), value: model.inputLocked)

            WordTrayView(model: model, reduceMotion: calm, space: flightSpace)
                .modifier(ShakeEffect(animatableData: shake))

            controlBar
        }
    }

    @ViewBuilder private var controlBar: some View {
        HStack(spacing: 12) {
            ControlCluster(model: model)
            if model.canUndo {
                GlossButton(systemImage: "arrow.uturn.left", title: "Undo",
                            paint: themeStore.theme.secondaryButton) {
                    withAnimation(spring) { model.undoRemove() }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(spring, value: model.canUndo)
    }

    // MARK: Helpers

    private func tileFeedback(_ old: Int, _ new: Int) -> SensoryFeedback? {
        new != old ? .impact(weight: .light) : nil
    }

    private func statusFeedback(_ status: ChallengeStatus?) -> SensoryFeedback? {
        switch status {
        case .correct: .success
        case .wrong: .warning
        default: nil
        }
    }

    private func handleChallengeStatus(_ status: ChallengeStatus?) {
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

    private func runFlyDemoIfRequested() async {
        // Launch-gated demo so the fly animation can be screen-recorded. Inert otherwise.
        guard ProcessInfo.processInfo.environment["UITEST_FLYDEMO"] == "1" else { return }
        for letter in ["c", "a", "t", "d", "o", "g", "s", "u", "n"] {
            try? await Task.sleep(for: .seconds(0.8))
            _ = model.tapLetter(letter, fly: true)
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

/// Gentle horizontal jiggle for a wrong Challenge attempt or a full/locked tray.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0))
    }
}
