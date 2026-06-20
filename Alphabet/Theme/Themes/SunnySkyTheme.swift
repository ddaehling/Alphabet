import SwiftUI

// MARK: - Theme tokens

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
        letterShadow: LetterShadow(color: .black.opacity(0.20), radiusFactor: 0.055, dyFactor: 0.045),
        letterHalo: LetterHalo(color: Color(hex: "5A4632").opacity(0.22), radiusFactor: 0.05),
        motion: MotionProfile(springResponse: 0.42, springDamping: 0.6, flyArcHeight: 100, idleWobble: true),
        celebration: .confetti
    )
}

// MARK: - Background

struct SunnySkyBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Smooth vertical sky gradient: warm peach -> cooled cream -> pale sky -> soft blue.
                // Mid cream stop is cooled/deepened and the sky stops pulled up a touch so the
                // central band (where warm yellow/orange/lime letters sit) is never near-white.
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "FFE2C2"), location: 0.0),
                        .init(color: Color(hex: "F4E8CE"), location: 0.22),
                        .init(color: Color(hex: "BCE4F5"), location: 0.56),
                        .init(color: Color(hex: "9FD6F2"), location: 1.0),
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                // Very soft radial sun glow in the upper-right.
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "FFF7E6").opacity(0.85), location: 0.0),
                        .init(color: Color(hex: "FFF7E6").opacity(0.0), location: 1.0),
                    ]),
                    center: UnitPoint(x: 0.86, y: 0.12),
                    startRadius: 0,
                    endRadius: max(w, h) * 0.55
                )
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

                // Soft cream veil behind the central grid rows: a wide horizontal band that
                // flattens the value range exactly in the letter band so chip-less letters
                // keep contrast. Large blur keeps it imperceptible as an edge.
                Capsule()
                    .fill(Color(hex: "FDF6EA"))
                    .frame(width: w * 1.4, height: h * 0.34)
                    .position(x: w * 0.5, y: h * 0.5)
                    .blur(radius: max(w, h) * 0.12)
                    .opacity(0.35)
                    .allowsHitTesting(false)

                // Slowly drifting soft clouds (static under reduceMotion).
                CloudLayer(size: geo.size, reduceMotion: reduceMotion)
                    .allowsHitTesting(false)

                // Two-layer rolling grassy hill anchored to the bottom.
                HillLayer(size: geo.size)
                    .allowsHitTesting(false)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Clouds

private struct CloudLayer: View {
    let size: CGSize
    let reduceMotion: Bool

    // Each cloud: normalized base x/y, scale, drift amplitude (points), phase, opacity.
    private struct Cloud {
        let x: CGFloat
        let y: CGFloat
        let scale: CGFloat
        let drift: CGFloat
        let phase: Double
        let opacity: Double
    }

    // Kept in the top ~22% only, clear of the central grid band. Peak white is capped
    // (see cloudShape) so the brightest puff never approaches pure white near the letters.
    private let clouds: [Cloud] = [
        Cloud(x: 0.20, y: 0.15, scale: 1.00, drift: 26, phase: 0.0, opacity: 0.85),
        Cloud(x: 0.74, y: 0.12, scale: 0.82, drift: 20, phase: 1.7, opacity: 0.82),
        Cloud(x: 0.49, y: 0.10, scale: 0.58, drift: 16, phase: 3.1, opacity: 0.78),
    ]

    var body: some View {
        if reduceMotion {
            ZStack {
                ForEach(0..<clouds.count, id: \.self) { i in
                    cloudShape(clouds[i], offsetX: 0)
                }
            }
        } else {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(0..<clouds.count, id: \.self) { i in
                        let c = clouds[i]
                        // Gentle left<->right drift; ~40s period.
                        let dx = CGFloat(sin(t * 0.16 + c.phase)) * c.drift
                        cloudShape(c, offsetX: dx)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cloudShape(_ c: Cloud, offsetX: CGFloat) -> some View {
        let base: CGFloat = 96 * c.scale         // overall cloud width unit
        let cx = size.width * c.x + offsetX
        let cy = size.height * c.y

        ZStack {
            // Faint cooler underside (drawn slightly lower & behind).
            Group {
                puff(d: base * 0.92, dx: -base * 0.42, dy: base * 0.10)
                puff(d: base * 1.18, dx: 0,           dy: base * 0.12)
                puff(d: base * 0.86, dx: base * 0.46, dy: base * 0.12)
            }
            .foregroundStyle(Color(hex: "DCEDF7"))

            // Bright tops, capped below pure white so peak luminance stays ~0.85.
            Group {
                puff(d: base * 0.90, dx: -base * 0.46, dy: 0)
                puff(d: base * 1.16, dx: -base * 0.02, dy: -base * 0.05)
                puff(d: base * 0.84, dx: base * 0.46,  dy: 0)
                puff(d: base * 0.66, dx: base * 0.20,  dy: -base * 0.18)
            }
            .foregroundStyle(Color.white.opacity(0.85))
        }
        .compositingGroup()
        .blur(radius: 1.5)                       // static soft edge (cheap, not per-frame data)
        .opacity(c.opacity)
        .position(x: cx, y: cy)
    }

    private func puff(d: CGFloat, dx: CGFloat, dy: CGFloat) -> some View {
        Circle()
            .frame(width: d, height: d)
            .offset(x: dx, y: dy)
    }
}

// MARK: - Hills

private struct HillLayer: View {
    let size: CGSize

    var body: some View {
        let w = size.width
        let h = size.height

        // Hill occupies roughly the bottom quarter. Crest baselines as fractions of height.
        let backCrest = h * 0.78
        let frontCrest = h * 0.83

        ZStack {
            // Back crest (top edge darkened ~6% so the bottom letter row keeps contrast).
            hillPath(width: w, height: h, crest: backCrest, amplitude: h * 0.030, phase: 0.0)
                .fill(Color(hex: "68A738"))

            // Front crest (top edge darkened ~6%).
            hillPath(width: w, height: h, crest: frontCrest, amplitude: h * 0.026, phase: 0.6)
                .fill(Color(hex: "7EB846"))

            // Sunlit rim along the front crest's top edge (also dialed back ~6%).
            crestLine(width: w, height: h, crest: frontCrest, amplitude: h * 0.026, phase: 0.6)
                .stroke(Color(hex: "9CCB64"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .opacity(0.9)

            // Decorations: tiny grass tufts + daisy dots resting near the front crest.
            decorations(width: w, frontCrest: frontCrest)
        }
    }

    /// A closed, smooth rounded wave filling down to the bottom of the screen.
    private func hillPath(width w: CGFloat, height h: CGFloat,
                          crest: CGFloat, amplitude amp: CGFloat, phase: CGFloat) -> Path {
        Path { p in
            let segs = 4
            let step = w / CGFloat(segs)
            p.move(to: CGPoint(x: 0, y: crest))
            for i in 0..<segs {
                let x0 = step * CGFloat(i)
                let x1 = step * CGFloat(i + 1)
                let dir: CGFloat = (i % 2 == 0) ? -1 : 1
                let cYBase = crest + amp * sin(phase + CGFloat(i))
                let ctrlY = cYBase + dir * amp
                let cp = CGPoint(x: (x0 + x1) / 2, y: ctrlY)
                let endY = crest + amp * 0.4 * sin(phase + CGFloat(i + 1))
                p.addQuadCurve(to: CGPoint(x: x1, y: endY), control: cp)
            }
            p.addLine(to: CGPoint(x: w, y: h))
            p.addLine(to: CGPoint(x: 0, y: h))
            p.closeSubpath()
        }
    }

    /// Just the top wave line of the front crest (for the sunlit rim).
    private func crestLine(width w: CGFloat, height h: CGFloat,
                           crest: CGFloat, amplitude amp: CGFloat, phase: CGFloat) -> Path {
        Path { p in
            let segs = 4
            let step = w / CGFloat(segs)
            p.move(to: CGPoint(x: 0, y: crest))
            for i in 0..<segs {
                let x0 = step * CGFloat(i)
                let x1 = step * CGFloat(i + 1)
                let dir: CGFloat = (i % 2 == 0) ? -1 : 1
                let cYBase = crest + amp * sin(phase + CGFloat(i))
                let ctrlY = cYBase + dir * amp
                let cp = CGPoint(x: (x0 + x1) / 2, y: ctrlY)
                let endY = crest + amp * 0.4 * sin(phase + CGFloat(i + 1))
                p.addQuadCurve(to: CGPoint(x: x1, y: endY), control: cp)
            }
        }
    }

    @ViewBuilder
    private func decorations(width w: CGFloat, frontCrest: CGFloat) -> some View {
        // Small darker grass tufts.
        ForEach(0..<4, id: \.self) { i in
            let x = w * [0.12, 0.135, 0.86, 0.875][i]
            Triangle()
                .fill(Color(hex: "5C9A2E"))
                .frame(width: 8, height: 16)
                .opacity(0.6)
                .position(x: x, y: frontCrest + 16)
        }

        // Tiny white-yellow daisy dots.
        ForEach(0..<3, id: \.self) { i in
            let x = w * [0.18, 0.62, 0.81][i]
            let yOff: CGFloat = [34, 50, 24][i]
            ZStack {
                Circle().fill(.white).frame(width: 12, height: 12)
                Circle().fill(Color(hex: "F4C400")).frame(width: 5, height: 5)
            }
            .opacity(0.9)
            .position(x: x, y: frontCrest + yOff)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Celebration

struct ConfettiCelebration: View {
    let reduceMotion: Bool

    private let colors: [Color] = LetterPalette.hues.map { Color(hex: $0) }

    var body: some View {
        if reduceMotion {
            ReducedPulse(colors: colors)
        } else {
            ConfettiRain(colors: colors)
        }
    }
}

// Calm static variant: a single gentle scale-up + glow pulse.
private struct ReducedPulse: View {
    let colors: [Color]
    @State private var on = false

    var body: some View {
        ZStack {
            // Soft warm glow.
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "FFF7E6").opacity(0.55), .clear]),
                center: .center, startRadius: 0, endRadius: 280
            )
            .scaleEffect(on ? 1.0 : 0.6)
            .opacity(on ? 0.9 : 0.0)

            // A small ring of rainbow dots that fades in once.
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) / 8.0 * 2 * .pi
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: 18, height: 18)
                    .offset(x: CGFloat(cos(angle)) * 96,
                            y: CGFloat(sin(angle)) * 96)
                    .scaleEffect(on ? 1.0 : 0.2)
                    .opacity(on ? 0.95 : 0.0)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: on)
        .onAppear { on = true }
        .allowsHitTesting(false)
    }
}

// Rainbow confetti: gravity + gentle rotation/flutter, drawn cheaply in a Canvas.
private struct ConfettiRain: View {
    let colors: [Color]

    private struct Particle {
        let x0: CGFloat          // normalized launch x (0...1)
        let delay: Double        // seconds before it starts falling
        let drift: CGFloat       // horizontal sway amplitude (points)
        let swaySpeed: Double
        let fallSpeed: CGFloat   // points per second
        let spin: Double         // rotations per second
        let size: CGFloat
        let colorIndex: Int
        let kind: Int            // 0 = rounded rect, 1 = circle
        let tilt: Double         // base rotation
    }

    private let particles: [Particle]
    private let start = Date()

    init(colors: [Color]) {
        self.colors = colors
        var rng = SystemRandomNumberGenerator()
        var built: [Particle] = []
        built.reserveCapacity(120)
        for i in 0..<120 {
            built.append(
                Particle(
                    x0: CGFloat.random(in: 0...1, using: &rng),
                    delay: Double.random(in: 0...1.4, using: &rng),
                    drift: CGFloat.random(in: 18...46, using: &rng),
                    swaySpeed: Double.random(in: 0.8...1.8, using: &rng),
                    fallSpeed: CGFloat.random(in: 170...300, using: &rng),
                    spin: Double.random(in: -1.6...1.6, using: &rng),
                    size: CGFloat.random(in: 9...16, using: &rng),
                    colorIndex: i % colors.count,
                    kind: Int.random(in: 0...1, using: &rng),
                    tilt: Double.random(in: 0...(2 * .pi), using: &rng)
                )
            )
        }
        self.particles = built
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            Canvas { ctx, size in
                let topMargin: CGFloat = 60
                let totalTravel = size.height + topMargin * 2
                for p in particles {
                    let local = t - p.delay
                    guard local > 0 else { continue }

                    // Vertical position with gravity-like acceleration that eases out.
                    let y = -topMargin + p.fallSpeed * CGFloat(local) + 30 * CGFloat(local * local)
                    if y > size.height + topMargin { continue }   // off-screen below

                    // Horizontal sway.
                    let sway = sin(local * p.swaySpeed + Double(p.colorIndex)) * Double(p.drift)
                    let x = p.x0 * size.width + CGFloat(sway)

                    // Fade out near the bottom.
                    let progress = max(0, min(1, (y + topMargin) / totalTravel))
                    let alpha = progress > 0.82 ? Double((1 - progress) / 0.18) : 1.0

                    let angle = p.tilt + local * p.spin * 2 * .pi
                    // Flutter: squash width to fake a 3D flip.
                    let flutter = CGFloat(abs(cos(local * 2.4 + Double(p.colorIndex)))) * 0.7 + 0.3

                    ctx.drawLayer { layer in
                        layer.translateBy(x: x, y: y)
                        layer.rotate(by: .radians(angle))
                        layer.scaleBy(x: flutter, y: 1)
                        layer.opacity = alpha

                        let rect = CGRect(x: -p.size / 2, y: -p.size / 2,
                                          width: p.size, height: p.size * 0.7)
                        let color = colors[p.colorIndex]
                        if p.kind == 0 {
                            let path = Path(roundedRect: rect, cornerRadius: 2.5)
                            layer.fill(path, with: .color(color))
                        } else {
                            layer.fill(Path(ellipseIn: rect), with: .color(color))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
