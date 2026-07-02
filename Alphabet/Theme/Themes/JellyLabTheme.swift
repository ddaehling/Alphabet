import SwiftUI

// MARK: - Theme tokens

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
        letterShadow: LetterShadow(color: Color(hex: "0E0626").opacity(0.55), radiusFactor: 0.06, dyFactor: 0.05),
        letterHalo: LetterHalo(color: .white.opacity(0.16), radiusFactor: 0.085, appliesToAll: true),
        motion: MotionProfile(springResponse: 0.4, springDamping: 0.55, flyArcHeight: 110, idleWobble: true),
        celebration: .sparkle
    )
}

// MARK: - Background

/// Bubblegum Jelly Lab: a rich grape→indigo→deep radial gradient, a soft sheen band
/// near the top, a few LARGE static-blurred color bokeh circles at very low opacity,
/// and a sparse scatter of tiny white sparkle dots. The bokeh and sparkles are dimmed
/// and pushed toward the margins, and the radial/vignette are deepened, so the central
/// grid band stays a calm dark field — chip-less letters keep their contrast there while
/// the candy color still glows around the edges.
struct JellyLabBackground: View {
    /// One large soft bokeh orb. Positions/sizes are expressed as fractions of the
    /// canvas so the composition scales with the iPad screen.
    private struct Bokeh {
        let hex: String
        let ux: CGFloat     // center x as fraction of width
        let uy: CGFloat     // center y as fraction of height
        let ur: CGFloat     // radius as fraction of min(width, height)
        let opacity: Double
    }

    // Few, large, low-opacity, pushed toward the margins. Pink / cyan / lime / purple /
    // soft gold — candy-shop hues. Opacities are dimmed to ~0.4 of the old values so no
    // glowing blob ever sits bright behind a dark-edged letter; the brightest orb is shoved
    // off dead-center into the top-left corner.
    private let bokeh: [Bokeh] = [
        Bokeh(hex: "FF7FC0", ux: 0.08, uy: 0.14, ur: 0.16, opacity: 0.040),
        Bokeh(hex: "6BE0FF", ux: 0.92, uy: 0.13, ur: 0.13, opacity: 0.040),
        Bokeh(hex: "B6F36B", ux: 0.95, uy: 0.58, ur: 0.18, opacity: 0.028),
        Bokeh(hex: "C79AFF", ux: 0.06, uy: 0.64, ur: 0.15, opacity: 0.040),
        Bokeh(hex: "FFE26B", ux: 0.18, uy: 0.06, ur: 0.10, opacity: 0.032),
    ]

    // A handful of small mid-bright accent puffs (still soft) for depth — also dimmed to
    // ~0.4 and kept off the central grid band.
    private let accents: [Bokeh] = [
        Bokeh(hex: "FF8AD4", ux: 0.14, uy: 0.36, ur: 0.05, opacity: 0.064),
        Bokeh(hex: "6BF0C0", ux: 0.86, uy: 0.36, ur: 0.045, opacity: 0.064),
    ]

    // Tiny white sparkle dots (static). Fractions of width/height. Reduced in count and
    // dimmed to ~0.4 so the grid reads on a calm dark field.
    private let dots: [(ux: CGFloat, uy: CGFloat, r: CGFloat, o: Double)] = [
        (0.16, 0.27, 2.0, 0.28),
        (0.85, 0.29, 2.5, 0.28),
        (0.62, 0.12, 1.5, 0.24),
        (0.29, 0.16, 1.8, 0.24),
        (0.91, 0.73, 2.0, 0.24),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let m = min(w, h)

            ZStack {
                // Base radial gradient: grape center → indigo → deep edges. Mid/edge
                // stops are deepened so the central grid band sits on a calm dark field
                // (the center grape stop is unchanged — not brightened).
                RadialGradient(
                    colors: [Color(hex: "7B3FD4"), Color(hex: "32176E"), Color(hex: "150A38")],
                    center: UnitPoint(x: 0.5, y: 0.34),
                    startRadius: 10,
                    endRadius: m * 1.15
                )

                // Subtle lighter sheen band near the top.
                LinearGradient(
                    colors: [
                        Color(hex: "C9B8FF").opacity(0.0),
                        Color(hex: "C9B8FF").opacity(0.14),
                        Color(hex: "B9A6FF").opacity(0.0),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: h * 0.34)
                .frame(maxHeight: .infinity, alignment: .top)
                .blendMode(.screen)

                // LARGE soft blurred bokeh — STATIC blur (rendered once, no per-frame work).
                ForEach(Array(bokeh.enumerated()), id: \.offset) { _, b in
                    Circle()
                        .fill(Color(hex: b.hex))
                        .frame(width: b.ur * m * 2, height: b.ur * m * 2)
                        .blur(radius: b.ur * m * 0.55)
                        .opacity(b.opacity)
                        .position(x: b.ux * w, y: b.uy * h)
                }
                .blendMode(.screen)

                // Smaller soft accent puffs.
                ForEach(Array(accents.enumerated()), id: \.offset) { _, b in
                    Circle()
                        .fill(Color(hex: b.hex))
                        .frame(width: b.ur * m * 2, height: b.ur * m * 2)
                        .blur(radius: b.ur * m * 0.7)
                        .opacity(b.opacity)
                        .position(x: b.ux * w, y: b.uy * h)
                }
                .blendMode(.screen)

                // Tiny white sparkle dots (crisp, static).
                ForEach(Array(dots.enumerated()), id: \.offset) { _, d in
                    Circle()
                        .fill(Color.white)
                        .frame(width: d.r * 2, height: d.r * 2)
                        .opacity(d.o)
                        .position(x: d.ux * w, y: d.uy * h)
                }

                // A vignette to keep edges deep and the central grid band calm and dark
                // so chip-less letters never lose contrast. Deepened slightly and pulled
                // inward; it darkens — it does not brighten the center.
                RadialGradient(
                    colors: [Color.clear, Color(hex: "0E0626").opacity(0.58)],
                    center: .center,
                    startRadius: m * 0.40,
                    endRadius: m * 0.95
                )
                .allowsHitTesting(false)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Celebration

/// SparkleCelebration: an upward burst of small glowing sparkle particles in bright
/// candy hues, drawn with a single Canvas (cheap), capped at ~100 particles.
/// Under reduceMotion it shows a static ring of sparkles plus a soft central glow —
/// no looping motion, no rain.
struct SparkleCelebration: View {
    let reduceMotion: Bool

    @State private var t: CGFloat = 0   // 0 → 1 animation progress

    private let colors: [Color] = LetterPalette.hues.map { Color(hex: $0) }

    // Pre-computed particle field. Deterministic so layout is stable across redraws.
    private struct Particle {
        let angle: CGFloat        // launch direction (radians, mostly upward)
        let speed: CGFloat        // travel distance factor
        let size: CGFloat         // base glyph size
        let color: Color
        let spin: CGFloat         // rotation amount over the burst
        let drift: CGFloat        // horizontal sway factor
        let twinklePhase: CGFloat // offset for opacity twinkle
    }

    private let particles: [Particle]

    init(reduceMotion: Bool) {
        self.reduceMotion = reduceMotion

        var rng = SeededRNG(seed: 0xA17EE)
        let palette = LetterPalette.hues.map { Color(hex: $0) }
        let count = 96   // capped well under ~100
        var built: [Particle] = []
        built.reserveCapacity(count)

        for _ in 0..<count {
            // Bias the launch upward: angles clustered around -90° (straight up)
            // with a wide fan to the sides.
            let spread = CGFloat.random(in: -1.15...1.15, using: &rng) // radians from straight up
            let angle = -CGFloat.pi / 2 + spread
            let speed = CGFloat.random(in: 0.45...1.0, using: &rng)
            let size = CGFloat.random(in: 8...20, using: &rng)
            let color = palette.randomElement(using: &rng) ?? .white
            let spin = CGFloat.random(in: -1.6...1.6, using: &rng)
            let drift = CGFloat.random(in: -0.18...0.18, using: &rng)
            let twinkle = CGFloat.random(in: 0...(2 * .pi), using: &rng)
            built.append(Particle(angle: angle, speed: speed, size: size, color: color,
                                  spin: spin, drift: drift, twinklePhase: twinkle))
        }
        self.particles = built
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                if reduceMotion {
                    staticBurst(in: size)
                } else {
                    // `t` is driven by withAnimation (easeOut) for a clean, non-looping
                    // burst that ends crisply at 1. TimelineView keeps redraws smooth
                    // so the per-particle twinkle reads as alive during the burst.
                    TimelineView(.animation) { _ in
                        animatedCanvas(progress: t, in: size)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.25)) {
                t = 1
            }
        }
    }

    // MARK: Animated path (cheap Canvas particle motion)

    private func animatedCanvas(progress: CGFloat, in size: CGSize) -> some View {
        Canvas { ctx, canvasSize in
            let origin = CGPoint(x: canvasSize.width / 2, y: canvasSize.height * 0.62)
            let reach = min(canvasSize.width, canvasSize.height) * 0.92
            let p = max(0, min(1, progress))
            // Ease-out for distance so particles decelerate as they rise.
            let dist = 1 - pow(1 - p, 2)
            // Fade tail: full until ~65%, then fade to 0.
            let globalFade = p < 0.65 ? 1.0 : Double(1 - (p - 0.65) / 0.35)

            // Soft central bloom that blossoms then fades.
            let bloomR = reach * (0.10 + 0.22 * dist)
            let bloomAlpha = globalFade * 0.30 * Double(1 - dist * 0.4)
            if bloomAlpha > 0.01 {
                let rect = CGRect(x: origin.x - bloomR, y: origin.y - bloomR,
                                  width: bloomR * 2, height: bloomR * 2)
                ctx.fill(Circle().path(in: rect),
                         with: .radialGradient(
                            Gradient(colors: [Color.white.opacity(bloomAlpha),
                                              Color.white.opacity(0)]),
                            center: origin, startRadius: 0, endRadius: bloomR))
            }

            for particle in particles {
                let travel = reach * particle.speed * dist
                let dx = cos(particle.angle) * travel + particle.drift * reach * dist
                // Gravity sag near the end of the burst.
                let gravity = reach * 0.18 * pow(dist, 2)
                let dy = sin(particle.angle) * travel + gravity
                let pos = CGPoint(x: origin.x + dx, y: origin.y + dy)

                let twinkle = 0.65 + 0.35 * Double(sin(particle.twinklePhase + progress * 6))
                let alpha = globalFade * twinkle
                if alpha < 0.02 { continue }

                let scale = 0.6 + 0.4 * dist
                drawSparkle(in: &ctx,
                            at: pos,
                            size: particle.size * scale,
                            rotation: particle.spin * dist,
                            color: particle.color,
                            alpha: alpha)
            }
        }
    }

    // MARK: Static (reduceMotion) path — a calm ring of sparkles + soft glow.

    private func staticBurst(in size: CGSize) -> some View {
        Canvas { ctx, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let reach = min(canvasSize.width, canvasSize.height)

            // Soft central glow.
            let glowR = reach * 0.26
            let rect = CGRect(x: center.x - glowR, y: center.y - glowR,
                              width: glowR * 2, height: glowR * 2)
            ctx.fill(Circle().path(in: rect),
                     with: .radialGradient(
                        Gradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0)]),
                        center: center, startRadius: 0, endRadius: glowR))

            // Two concentric rings of sparkles, no motion.
            let ringSpecs: [(radius: CGFloat, count: Int, size: CGFloat, alpha: Double)] = [
                (reach * 0.18, 10, 18, 0.95),
                (reach * 0.30, 16, 13, 0.80),
            ]
            var idx = 0
            for ring in ringSpecs {
                for i in 0..<ring.count {
                    let a = (CGFloat(i) / CGFloat(ring.count)) * 2 * .pi
                    let pos = CGPoint(x: center.x + cos(a) * ring.radius,
                                      y: center.y + sin(a) * ring.radius)
                    let color = colors[idx % colors.count]
                    idx += 1
                    drawSparkle(in: &ctx, at: pos, size: ring.size,
                                rotation: 0, color: color, alpha: ring.alpha)
                }
            }
        }
    }

    // MARK: Sparkle glyph

    /// Draws a small glowing four-point sparkle: a soft glow disc + a crisp star
    /// rendered as a filled path. Cheap enough to run for ~100 particles per frame.
    private func drawSparkle(in ctx: inout GraphicsContext,
                             at pos: CGPoint,
                             size: CGFloat,
                             rotation: CGFloat,
                             color: Color,
                             alpha: Double) {
        // Glow halo.
        let glowR = size * 0.95
        let glowRect = CGRect(x: pos.x - glowR, y: pos.y - glowR,
                              width: glowR * 2, height: glowR * 2)
        ctx.fill(Circle().path(in: glowRect),
                 with: .radialGradient(
                    Gradient(colors: [color.opacity(alpha * 0.55), color.opacity(0)]),
                    center: pos, startRadius: 0, endRadius: glowR))

        // Four-point star path.
        let star = sparklePath(center: pos, radius: size * 0.55, rotation: rotation)
        ctx.fill(star, with: .color(color.opacity(alpha)))
        // Bright white core for the "glowing" pop.
        let core = sparklePath(center: pos, radius: size * 0.30, rotation: rotation)
        ctx.fill(core, with: .color(Color.white.opacity(min(1, alpha * 0.9))))
    }

    /// A concave four-point star (sparkle) built from 8 alternating long/short spokes.
    private func sparklePath(center: CGPoint, radius: CGFloat, rotation: CGFloat) -> Path {
        var path = Path()
        let points = 4
        let inner = radius * 0.34
        for i in 0..<(points * 2) {
            let isOuter = (i % 2 == 0)
            let r = isOuter ? radius : inner
            let a = rotation + (CGFloat(i) / CGFloat(points * 2)) * 2 * .pi - .pi / 2
            let pt = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Deterministic RNG (for stable, varied particle layout)

/// A tiny SplitMix64-based generator so the celebration's particle field is
/// varied but reproducible, with no Foundation randomness dependency beyond
/// SwiftUI/Swift standard library.
private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
