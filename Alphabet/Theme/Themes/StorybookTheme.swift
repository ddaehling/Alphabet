import SwiftUI

// MARK: - Theme tokens

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
        tileChip: TileChipStyle(tint: .letterColor, shape: .circle, shadowOpacity: 0.28, highlightOpacity: 0.55),
        motion: MotionProfile(springResponse: 0.46, springDamping: 0.62, flyArcHeight: 95, idleWobble: false),
        celebration: .doodleStars,
        typography: ThemeTypography(titleWeight: .bold, labelWeight: .semibold)
    )
}

// MARK: - Background

/// Warm picture-book page: cream paper gradient, a soft warm corner vignette, and
/// faint hand-drawn doodle accents (a little sun, a couple of outlined stars, dotted
/// "paths" and a squiggle) kept low-opacity and desaturated so they stay recessive
/// behind the glossy letter grid.
struct StorybookBackground: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)   // scale doodles to short edge

            ZStack {
                // Cream paper.
                LinearGradient(colors: [Color(hex: "FBF3E2"), Color(hex: "F3E4C8")],
                               startPoint: .top, endPoint: .bottom)

                // Warm vignette: clear in the middle, gently darker tan at the corners.
                RadialGradient(
                    stops: [
                        .init(color: .clear, location: 0.62),
                        .init(color: Color(hex: "D9B47F").opacity(0.28), location: 1.0)
                    ],
                    center: UnitPoint(x: 0.5, y: 0.42),
                    startRadius: s * 0.30,
                    endRadius: s * 1.02
                )

                // Doodles, all behind content.
                DoodleLayer()
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}

/// Static, low-opacity doodle accents drawn with a single Canvas pass (cheap, no
/// per-frame work). Positions are normalised to the page so it looks balanced on
/// any iPad size or orientation.
private struct DoodleLayer: View {
    // Muted tan ink for outlines, warm sand for fills — all desaturated.
    private let inkSoft = Color(hex: "D8B98A")
    private let sunFill = Color(hex: "F2D69A")
    private let starFill = Color(hex: "EAD0A0")
    private let starInk = Color(hex: "D6B274")

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width
            let h = sz.height
            let s = min(w, h)

            // --- Sun, top-left: filled disc + short outlined rays. ---
            let sunC = CGPoint(x: w * 0.11, y: h * 0.16)
            let sunR = s * 0.045
            let sunRect = CGRect(x: sunC.x - sunR, y: sunC.y - sunR, width: sunR * 2, height: sunR * 2)
            ctx.opacity = 0.40
            ctx.fill(Path(ellipseIn: sunRect), with: .color(sunFill))
            ctx.stroke(Path(ellipseIn: sunRect), with: .color(starInk), lineWidth: s * 0.0035)

            var rays = Path()
            let rayInner = sunR * 1.35
            let rayOuter = sunR * 1.75
            for k in 0..<8 {
                let a = Double(k) / 8.0 * 2 * .pi
                let dx = CGFloat(cos(a)), dy = CGFloat(sin(a))
                rays.move(to: CGPoint(x: sunC.x + dx * rayInner, y: sunC.y + dy * rayInner))
                rays.addLine(to: CGPoint(x: sunC.x + dx * rayOuter, y: sunC.y + dy * rayOuter))
            }
            ctx.stroke(rays, with: .color(starInk),
                       style: StrokeStyle(lineWidth: s * 0.004, lineCap: .round))

            // --- Two outlined 5-point stars, top-right. ---
            ctx.opacity = 0.46
            let star1 = Self.starPath(center: CGPoint(x: w * 0.89, y: h * 0.15), radius: s * 0.032)
            ctx.fill(star1, with: .color(starFill))
            ctx.stroke(star1, with: .color(starInk),
                       style: StrokeStyle(lineWidth: s * 0.0035, lineJoin: .round))

            let star2 = Self.starPath(center: CGPoint(x: w * 0.945, y: h * 0.255), radius: s * 0.020)
            ctx.fill(star2, with: .color(starFill))
            ctx.stroke(star2, with: .color(starInk),
                       style: StrokeStyle(lineWidth: s * 0.0032, lineJoin: .round))

            // --- A few faint dots near the title (sprinkle). ---
            ctx.opacity = 0.50
            let dots: [(Double, Double, Double)] = [(0.49, 0.10, 0.004), (0.55, 0.13, 0.003), (0.435, 0.135, 0.003)]
            for (fx, fy, rr) in dots {
                let r = s * CGFloat(rr)
                let dot = CGRect(x: w * fx - r, y: h * fy - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: dot), with: .color(inkSoft))
            }

            // --- Dotted "paths" — dashed strokes, mid-page left & right. ---
            let dash = StrokeStyle(lineWidth: s * 0.003, lineCap: .round, dash: [s * 0.002, s * 0.014])

            var pathL = Path()
            pathL.move(to: CGPoint(x: w * 0.07, y: h * 0.61))
            pathL.addQuadCurve(to: CGPoint(x: w * 0.20, y: h * 0.605),
                               control: CGPoint(x: w * 0.135, y: h * 0.56))
            pathL.addQuadCurve(to: CGPoint(x: w * 0.34, y: h * 0.59),
                               control: CGPoint(x: w * 0.27, y: h * 0.645))
            ctx.opacity = 0.50
            ctx.stroke(pathL, with: .color(inkSoft), style: dash)

            var pathR = Path()
            pathR.move(to: CGPoint(x: w * 0.80, y: h * 0.60))
            pathR.addQuadCurve(to: CGPoint(x: w * 0.95, y: h * 0.605),
                               control: CGPoint(x: w * 0.875, y: h * 0.64))
            ctx.opacity = 0.45
            ctx.stroke(pathR, with: .color(inkSoft), style: dash)

            // --- A tiny squiggle, lower-left. ---
            var squiggle = Path()
            squiggle.move(to: CGPoint(x: w * 0.145, y: h * 0.785))
            squiggle.addQuadCurve(to: CGPoint(x: w * 0.188, y: h * 0.78),
                                  control: CGPoint(x: w * 0.166, y: h * 0.745))
            ctx.opacity = 0.42
            ctx.stroke(squiggle, with: .color(inkSoft),
                       style: StrokeStyle(lineWidth: s * 0.003, lineCap: .round))

            // --- A little double-hump squiggle, lower-right. ---
            var hump = Path()
            hump.move(to: CGPoint(x: w * 0.835, y: h * 0.785))
            hump.addQuadCurve(to: CGPoint(x: w * 0.862, y: h * 0.785),
                              control: CGPoint(x: w * 0.8485, y: h * 0.772))
            hump.addQuadCurve(to: CGPoint(x: w * 0.889, y: h * 0.785),
                              control: CGPoint(x: w * 0.8755, y: h * 0.798))
            ctx.opacity = 0.44
            ctx.stroke(hump, with: .color(inkSoft),
                       style: StrokeStyle(lineWidth: s * 0.003, lineCap: .round))
        }
        .blur(radius: 0.4)   // a whisper of softness so the ink reads "hand-drawn"
    }

    /// A filled/outlinable 5-point star centred at `center`.
    static func starPath(center: CGPoint, radius: CGFloat) -> Path {
        var p = Path()
        let inner = radius * 0.42
        for k in 0..<5 {
            let outerAngle = -Double.pi / 2 + Double(k) * 2 * .pi / 5
            let innerAngle = outerAngle + .pi / 5
            let op = CGPoint(x: center.x + radius * CGFloat(cos(outerAngle)),
                             y: center.y + radius * CGFloat(sin(outerAngle)))
            let ip = CGPoint(x: center.x + inner * CGFloat(cos(innerAngle)),
                             y: center.y + inner * CGFloat(sin(innerAngle)))
            if k == 0 { p.move(to: op) } else { p.addLine(to: op) }
            p.addLine(to: ip)
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Celebration

/// Doodle stars that pop in and twinkle (scale + gentle rotation) on a spring, plus a
/// few warm confetti bits that drift up and fade. Under `reduceMotion` the stars and
/// confetti simply fade in statically — no looping motion, no confetti rain.
struct DoodleStarsCelebration: View {
    let reduceMotion: Bool

    @State private var appeared = false

    // Hand-placed star burst (normalised offsets from centre, in points).
    private let stars: [StarSpec] = [
        StarSpec(dx:   -8, dy: -150, size: 40, hue: "F2C14E", filled: true,  delay: 0.00),
        StarSpec(dx:  150, dy:  -88, size: 30, hue: "E8A23D", filled: false, delay: 0.06),
        StarSpec(dx:  210, dy:   36, size: 24, hue: "F2D69A", filled: true,  delay: 0.12),
        StarSpec(dx:  122, dy:  140, size: 34, hue: "EFC15A", filled: true,  delay: 0.09),
        StarSpec(dx: -130, dy:  -70, size: 28, hue: "EAD0A0", filled: false, delay: 0.05),
        StarSpec(dx: -200, dy:   30, size: 22, hue: "E8A23D", filled: true,  delay: 0.14),
        StarSpec(dx: -120, dy:  150, size: 32, hue: "F2C14E", filled: false, delay: 0.10),
        StarSpec(dx:   10, dy:  120, size: 26, hue: "D6B274", filled: true,  delay: 0.16),
    ]

    private let confettiColors = ["F2C14E", "EC6B4E", "9E66BE", "6FA99B", "EFC15A", "E8A23D"]

    var body: some View {
        ZStack {
            // --- Twinkling doodle stars. ---
            ForEach(Array(stars.enumerated()), id: \.offset) { _, spec in
                StarShape()
                    .fill(Color(hex: spec.hue))
                    .overlay(
                        StarShape().stroke(Color(hex: "D6B274").opacity(spec.filled ? 0.0 : 0.9),
                                           style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
                    )
                    .frame(width: spec.size, height: spec.size)
                    .scaleEffect(reduceMotion ? 1.0 : (appeared ? 1.0 : 0.05))
                    .rotationEffect(.degrees(reduceMotion ? 0 : (appeared ? 8 : -22)))
                    .opacity(reduceMotion ? 0.92 : (appeared ? 1 : 0))
                    .offset(x: spec.dx, y: spec.dy)
                    .animation(reduceMotion ? nil
                               : .spring(response: 0.5, dampingFraction: 0.55)
                                   .delay(spec.delay),
                               value: appeared)
            }

            // --- A few confetti that pop in and fade (no continuous rain). ---
            if reduceMotion {
                ForEach(0..<6, id: \.self) { i in
                    confettiBit(i)
                        .opacity(0.7)
                        .offset(x: CGFloat((i * 71) % 300) - 150,
                                y: CGFloat((i * 53) % 200) - 60)
                }
            } else {
                ForEach(0..<10, id: \.self) { i in
                    confettiBit(i)
                        .scaleEffect(appeared ? 1 : 0.1)
                        .rotationEffect(.degrees(appeared ? Double((i * 47) % 90 - 45) : 0))
                        .opacity(appeared ? 0 : 1)
                        .offset(x: CGFloat((i * 71) % 320) - 160,
                                y: appeared ? CGFloat((i * 37) % 160) - 200
                                            : CGFloat((i * 37) % 160) - 60)
                        .animation(.easeOut(duration: 0.9).delay(Double(i) * 0.02),
                                   value: appeared)
                }
            }
        }
        .onAppear { appeared = true }
        .allowsHitTesting(false)
    }

    private func confettiBit(_ i: Int) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Color(hex: confettiColors[i % confettiColors.count]))
            .frame(width: 9, height: 13)
    }

    private struct StarSpec {
        let dx: CGFloat
        let dy: CGFloat
        let size: CGFloat
        let hue: String
        let filled: Bool
        let delay: Double
    }
}

/// A reusable 5-point star, sized to fit its frame.
private struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.42
        var p = Path()
        for k in 0..<5 {
            let outerAngle = -Double.pi / 2 + Double(k) * 2 * .pi / 5
            let innerAngle = outerAngle + .pi / 5
            let op = CGPoint(x: center.x + outer * CGFloat(cos(outerAngle)),
                             y: center.y + outer * CGFloat(sin(outerAngle)))
            let ip = CGPoint(x: center.x + inner * CGFloat(cos(innerAngle)),
                             y: center.y + inner * CGFloat(sin(innerAngle)))
            if k == 0 { p.move(to: op) } else { p.addLine(to: op) }
            p.addLine(to: ip)
        }
        p.closeSubpath()
        return p
    }
}
