import SwiftUI

// MARK: - Soft Pastel Calm (Montessori / sensory-friendly)
//
// A quiet warm off-white canvas. Three very soft, large, blurred pastel orbs
// survive only as a near-imperceptible whisper (~0.05) shoved into the corners
// and desaturated toward warm grey, so the central grid band stays perfectly
// flat and the chip-less rainbow bubble letters never lose contrast against the
// canvas. The bottom gradient stop is deepened slightly to ground the lowest
// rows. All ambient blur is static (applied once to shapes), never animated, to
// keep the GPU cool on iPad.

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
        letterShadow: LetterShadow(color: .black.opacity(0.16), radiusFactor: 0.05, dyFactor: 0.045),
        letterHalo: LetterHalo(color: Color(hex: "5A5249").opacity(0.22), radiusFactor: 0.05),
        motion: MotionProfile(springResponse: 0.5, springDamping: 0.85, flyArcHeight: 60, idleWobble: false),
        celebration: .glowPulse,
        typography: ThemeTypography(titleWeight: .semibold, labelWeight: .medium)
    )
}

// MARK: - Background

struct PastelCalmBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            // Scale orb radii to the smaller dimension so the composition reads
            // the same on portrait and landscape iPad.
            let unit = min(size.width, size.height)

            ZStack {
                // Quiet warm cream vertical wash. The bottom stop is deepened
                // slightly (#F3ECE0 → #ECE2D2) so the lowest grid rows gain a
                // touch of contrast behind the now chip-less letters.
                LinearGradient(
                    colors: [Color(hex: "FBF7F0"), Color(hex: "ECE2D2")],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Three soft, static-blurred pastel orbs pushed hard into the
                // corners and dropped to a near-imperceptible whisper. They are
                // desaturated toward warm grey so they read as faint ambient
                // tint, never as color competing with the rainbow letters, and
                // are kept well clear of the central grid band.
                orb(color: Color(hex: "C7BFD2"), opacity: 0.05, // de-chroma'd lavender, top-left corner
                    diameter: unit * 0.62,
                    center: CGPoint(x: size.width * 0.08, y: size.height * 0.16))

                orb(color: Color(hex: "D8CBC0"), opacity: 0.05, // de-chroma'd peach, top-right corner
                    diameter: unit * 0.50,
                    center: CGPoint(x: size.width * 0.94, y: size.height * 0.12))

                orb(color: Color(hex: "BFC8C0"), opacity: 0.05, // de-chroma'd sage, bottom-right corner
                    diameter: unit * 0.58,
                    center: CGPoint(x: size.width * 0.92, y: size.height * 0.90))
            }
        }
        .ignoresSafeArea()
    }

    /// A single soft orb: a radial gradient that fades fully to transparent at
    /// its edge, with a one-time `.blur` to melt it into the background. The
    /// blur is applied to a static shape (not inside any animation loop).
    private func orb(color: Color, opacity: Double, diameter: CGFloat, center: CGPoint) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(opacity), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter / 2
                )
            )
            .frame(width: diameter, height: diameter)
            .blur(radius: diameter * 0.16)
            .position(center)
            .blendMode(.normal)
            .allowsHitTesting(false)
    }
}

// MARK: - Celebration

/// A calm, slow expanding soft halo ring with a few gentle slow sparkles.
/// This theme is already calm, so the reduceMotion variant is a static soft
/// glow with no motion and no falling confetti.
struct GlowPulseCelebration: View {
    let reduceMotion: Bool

    @State private var animate = false

    // Palette pulled from the theme's lavender accent so the celebration sits
    // gently inside the world rather than introducing a new strong color.
    private let haloColor = Color(hex: "C5B1E2")
    private let sparkleColor = Color(hex: "F0C5A8")

    var body: some View {
        ZStack {
            if reduceMotion {
                staticGlow
            } else {
                expandingHalo
                sparkles
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            // A single, gentle, autoreversing breath — calm and finite-feeling,
            // not a frantic loop. Slow enough to be soothing.
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    // MARK: Reduce-motion variant — a still, soft glow.
    private var staticGlow: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [haloColor.opacity(0.45), haloColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 18)

            Circle()
                .stroke(haloColor.opacity(0.55), lineWidth: 6)
                .frame(width: 180, height: 180)
                .blur(radius: 0.5)
        }
    }

    // MARK: Animated variant — slow soft halo ring + diffuse glow.
    private var expandingHalo: some View {
        ZStack {
            // Diffuse breathing glow behind the ring.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [haloColor.opacity(0.38), haloColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)
                .blur(radius: 22)
                .scaleEffect(animate ? 1.08 : 0.82)
                .opacity(animate ? 0.9 : 0.55)

            // Slow expanding soft ring.
            Circle()
                .stroke(haloColor.opacity(0.6), lineWidth: 7)
                .frame(width: 150, height: 150)
                .scaleEffect(animate ? 1.9 : 0.7)
                .opacity(animate ? 0.0 : 0.7)
                .blur(radius: 0.5)

            // A second, inner ring offset in phase for a gentle layered feel.
            Circle()
                .stroke(haloColor.opacity(0.45), lineWidth: 4)
                .frame(width: 150, height: 150)
                .scaleEffect(animate ? 1.35 : 0.5)
                .opacity(animate ? 0.0 : 0.6)
                .blur(radius: 0.5)
        }
    }

    // MARK: A few gentle slow sparkles, drawn cheaply in a Canvas.
    private var sparkles: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                // Six soft sparkles slowly twinkling around the halo. Positions
                // are fixed; only opacity/scale breathe — no per-frame blur.
                for spark in Self.sparkSpecs {
                    let phase = (sin(t * spark.speed + spark.offset) + 1) / 2 // 0...1
                    let alpha = 0.25 + 0.55 * phase
                    let scale = 0.6 + 0.5 * phase
                    let pos = CGPoint(
                        x: center.x + cos(spark.angle) * spark.radius,
                        y: center.y + sin(spark.angle) * spark.radius
                    )
                    drawSparkle(in: &context, at: pos, size: spark.size * scale, alpha: alpha)
                }
            }
            .frame(width: 360, height: 360)
        }
    }

    /// Draw a soft four-point sparkle (two crossed tapered diamonds) plus a
    /// faint core dot. Pure path fills — inexpensive per frame.
    private func drawSparkle(in context: inout GraphicsContext, at point: CGPoint, size: CGFloat, alpha: Double) {
        let color = sparkleColor.opacity(alpha)

        var star = Path()
        let s = size
        // Vertical spike
        star.move(to: CGPoint(x: point.x, y: point.y - s))
        star.addLine(to: CGPoint(x: point.x + s * 0.22, y: point.y))
        star.addLine(to: CGPoint(x: point.x, y: point.y + s))
        star.addLine(to: CGPoint(x: point.x - s * 0.22, y: point.y))
        star.closeSubpath()
        // Horizontal spike
        star.move(to: CGPoint(x: point.x - s, y: point.y))
        star.addLine(to: CGPoint(x: point.x, y: point.y - s * 0.22))
        star.addLine(to: CGPoint(x: point.x + s, y: point.y))
        star.addLine(to: CGPoint(x: point.x, y: point.y + s * 0.22))
        star.closeSubpath()

        context.fill(star, with: .color(color))

        let core = Path(ellipseIn: CGRect(x: point.x - s * 0.18, y: point.y - s * 0.18,
                                          width: s * 0.36, height: s * 0.36))
        context.fill(core, with: .color(Color.white.opacity(alpha * 0.7)))
    }

    private struct SparkSpec {
        let angle: Double
        let radius: CGFloat
        let size: CGFloat
        let speed: Double
        let offset: Double
    }

    private static let sparkSpecs: [SparkSpec] = [
        SparkSpec(angle: -1.3, radius: 96, size: 11, speed: 1.1, offset: 0.0),
        SparkSpec(angle:  0.4, radius: 118, size: 8,  speed: 0.8, offset: 1.6),
        SparkSpec(angle:  1.9, radius: 88,  size: 12, speed: 1.0, offset: 3.0),
        SparkSpec(angle:  2.9, radius: 110, size: 7,  speed: 0.9, offset: 0.8),
        SparkSpec(angle: -2.4, radius: 100, size: 9,  speed: 1.2, offset: 2.2),
        SparkSpec(angle:  0.05, radius: 70, size: 6,  speed: 0.7, offset: 4.1),
    ]
}
