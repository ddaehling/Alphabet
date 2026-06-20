import SwiftUI

enum PastelCalmTheme {
    static let theme = Theme(
        id: .pastelCalm,
        name: "Soft Pastel",
        uiTextOnBackground: Color(hex: "5A5249"),
        uiTextOnSurface: Color(hex: "6B6256"),
        traySurface: Color(hex: "FFFFFF"),
        usesMaterialSurface: false,
        slotFill: Color(hex: "F1E9DC"),
        slotStroke: Color(hex: "D9CDB6"),
        primaryButton: ButtonPaint(fillTop: Color(hex: "D6C6EC"), fillBottom: Color(hex: "C5B1E2"),
                                   rim: Color(hex: "B9A6D6"), label: .white, glossOpacity: 0.25),
        secondaryButton: ButtonPaint(fillTop: Color(hex: "FFFDF8"), fillBottom: Color(hex: "F6F1E8"),
                                     rim: Color(hex: "E7DECF"), label: Color(hex: "6B6256"), glossOpacity: 0.2),
        switcherTrack: Color(hex: "EFE7D9"),
        switcherThumb: ButtonPaint(fillTop: .white, fillBottom: .white,
                                   rim: Color(hex: "E7DECF"), label: Color(hex: "5A5249")),
        tileChip: TileChipStyle(tint: .letterColor, shape: .circle, shadowOpacity: 0.14, highlightOpacity: 0.9),
        motion: MotionProfile(springResponse: 0.5, springDamping: 0.85, flyArcHeight: 60, idleWobble: false),
        celebration: .glowPulse,
        typography: ThemeTypography(titleWeight: .semibold, labelWeight: .medium)
    )
}

struct PastelCalmBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(hex: "FBF7F0"), Color(hex: "F3ECE0")],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct GlowPulseCelebration: View {
    let reduceMotion: Bool
    @State private var grow = false
    var body: some View {
        Circle()
            .stroke(Color(hex: "C5B1E2"), lineWidth: 10)
            .frame(width: 160, height: 160)
            .scaleEffect(reduceMotion ? 1.4 : (grow ? 2.6 : 0.4))
            .opacity(reduceMotion ? 0.5 : (grow ? 0 : 0.8))
            .animation(reduceMotion ? nil : .easeOut(duration: 1.0), value: grow)
            .onAppear { grow = true }
            .allowsHitTesting(false)
    }
}
