import SwiftUI

enum JellyLabTheme {
    static let theme = Theme(
        id: .jellyLab,
        name: "Jelly Lab",
        uiTextOnBackground: .white,
        uiTextOnSurface: .white,
        traySurface: Color(hex: "2A1A5C"),
        usesMaterialSurface: true,
        slotFill: Color(hex: "160A3A"),
        slotStroke: Color(hex: "B9A6FF"),
        primaryButton: ButtonPaint(fillTop: Color(hex: "C76BF7"), fillBottom: Color(hex: "7A28D6"),
                                   rim: Color(hex: "5A1FB0"), label: .white, glossOpacity: 0.6),
        secondaryButton: ButtonPaint(fillTop: Color(hex: "4A3A92"), fillBottom: Color(hex: "2A1E5C"),
                                     rim: Color(hex: "6A5AB0"), label: .white, glossOpacity: 0.4),
        switcherTrack: Color(hex: "241152"),
        switcherThumb: ButtonPaint(fillTop: Color(hex: "C06BF5"), fillBottom: Color(hex: "7A28D6"),
                                   rim: Color(hex: "5A1FB0"), label: .white),
        tileChip: TileChipStyle(tint: .letterColor, shape: .roundedSquare(cornerRadius: 22),
                                shadowOpacity: 0.0, highlightOpacity: 0.7),
        motion: MotionProfile(springResponse: 0.4, springDamping: 0.55, flyArcHeight: 110, idleWobble: true),
        celebration: .sparkle
    )
}

struct JellyLabBackground: View {
    var body: some View {
        RadialGradient(colors: [Color(hex: "7B3FD4"), Color(hex: "3A1C7E"), Color(hex: "1B0E45")],
                       center: .init(x: 0.5, y: 0.34), startRadius: 10, endRadius: 900)
            .ignoresSafeArea()
    }
}

struct SparkleCelebration: View {
    let reduceMotion: Bool
    @State private var go = false
    private let colors = LetterPalette.hues.map { Color(hex: $0) }
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 22))
                    .foregroundStyle(colors[i % colors.count])
                    .offset(x: CGFloat((i * 61) % 300) - 150,
                            y: reduceMotion ? 0 : (go ? -260 : 40))
                    .opacity(reduceMotion ? 0.9 : (go ? 0 : 1))
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 1.0), value: go)
        .onAppear { go = true }
        .allowsHitTesting(false)
    }
}
