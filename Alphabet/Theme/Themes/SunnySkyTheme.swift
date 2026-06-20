import SwiftUI

enum SunnySkyTheme {
    static let theme = Theme(
        id: .sunnySky,
        name: "Sunny Sky",
        uiTextOnBackground: Color(hex: "5A4632"),
        uiTextOnSurface: Color(hex: "5A4632"),
        traySurface: Color(hex: "FBF7EC"),
        usesMaterialSurface: false,
        slotFill: Color(hex: "F2E8D2"),
        slotStroke: Color(hex: "E5C9A0"),
        primaryButton: ButtonPaint(fillTop: Color(hex: "FFB860"), fillBottom: Color(hex: "FF9E3D"),
                                   rim: Color(hex: "E07A1E"), label: .white, glossOpacity: 0.45),
        secondaryButton: ButtonPaint(fillTop: Color(hex: "7AD2F0"), fillBottom: Color(hex: "5CC0E8"),
                                     rim: Color(hex: "2E9BC8"), label: .white, glossOpacity: 0.45),
        switcherTrack: Color.white.opacity(0.55),
        switcherThumb: ButtonPaint(fillTop: Color(hex: "FFB860"), fillBottom: Color(hex: "FF9E3D"),
                                   rim: Color(hex: "E07A1E"), label: .white),
        tileChip: TileChipStyle(tint: .letterColor, shape: .circle, shadowOpacity: 0.10, highlightOpacity: 0.75),
        motion: MotionProfile(springResponse: 0.42, springDamping: 0.6, flyArcHeight: 100, idleWobble: true),
        celebration: .confetti
    )
}

struct SunnySkyBackground: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(hex: "FFE2C2"), Color(hex: "FFF1DC"),
                                    Color(hex: "BCE4F5"), Color(hex: "9FD6F2")],
                           startPoint: .top, endPoint: .bottom)
            Ellipse()
                .fill(Color(hex: "86C44A"))
                .frame(height: 220)
                .scaleEffect(x: 1.6)
                .offset(y: 150)
        }
        .ignoresSafeArea()
    }
}

struct ConfettiCelebration: View {
    let reduceMotion: Bool
    @State private var go = false
    private let colors = LetterPalette.hues.map { Color(hex: $0) }
    var body: some View {
        ZStack {
            ForEach(0..<24, id: \.self) { i in
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: 16, height: 16)
                    .offset(x: CGFloat((i * 53) % 320) - 160,
                            y: reduceMotion ? 0 : (go ? 360 : -120))
                    .opacity(reduceMotion ? 0.9 : (go ? 0 : 1))
            }
        }
        .animation(reduceMotion ? nil : .easeIn(duration: 1.1), value: go)
        .onAppear { go = true }
        .allowsHitTesting(false)
    }
}
