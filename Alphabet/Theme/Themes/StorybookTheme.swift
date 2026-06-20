import SwiftUI

enum StorybookTheme {
    static let theme = Theme(
        id: .storybook,
        name: "Storybook",
        uiTextOnBackground: Color(hex: "5A3A1E"),
        uiTextOnSurface: Color(hex: "FFF7EC"),
        traySurface: Color(hex: "E0A35E"),
        usesMaterialSurface: false,
        slotFill: Color(hex: "C98B45"),
        slotStroke: Color(hex: "B97C3C"),
        primaryButton: ButtonPaint(fillTop: Color(hex: "C79BDD"), fillBottom: Color(hex: "9E66BE"),
                                   rim: Color(hex: "7A4F9A"), label: Color(hex: "FFF7EC"), glossOpacity: 0.35),
        secondaryButton: ButtonPaint(fillTop: Color(hex: "9ED0C2"), fillBottom: Color(hex: "6FA99B"),
                                     rim: Color(hex: "5A8A7C"), label: Color(hex: "FFF7EC"), glossOpacity: 0.35),
        switcherTrack: Color(hex: "F1E2C4"),
        switcherThumb: ButtonPaint(fillTop: Color(hex: "EAC081"), fillBottom: Color(hex: "DDA85C"),
                                   rim: Color(hex: "CFA15B"), label: Color(hex: "5A3A1E")),
        tileChip: TileChipStyle(tint: .letterColor, shape: .circle, shadowOpacity: 0.3, highlightOpacity: 0.55),
        motion: MotionProfile(springResponse: 0.46, springDamping: 0.62, flyArcHeight: 95, idleWobble: false),
        celebration: .doodleStars
    )
}

struct StorybookBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "FBF3E2"), Color(hex: "F3E4C8")],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [.clear, Color(hex: "D9B47F").opacity(0.28)],
                           center: .center, startRadius: 260, endRadius: 620)
        }
        .ignoresSafeArea()
    }
}

struct DoodleStarsCelebration: View {
    let reduceMotion: Bool
    @State private var go = false
    var body: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: "EFC15A"))
                    .offset(x: CGFloat((i * 67) % 320) - 160,
                            y: CGFloat((i * 41) % 220) - 110)
                    .scaleEffect(reduceMotion ? 1 : (go ? 1 : 0.1))
                    .opacity(reduceMotion ? 0.9 : (go ? 1 : 0))
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.6), value: go)
        .onAppear { go = true }
        .allowsHitTesting(false)
    }
}
