import SwiftUI

/// Resolves a celebration style to its view. Each theme file provides its own
/// celebration; all take `reduceMotion` for the calm fallback.
struct CelebrationOverlay: View {
    let style: CelebrationStyle
    let reduceMotion: Bool

    var body: some View {
        switch style {
        case .confetti: ConfettiCelebration(reduceMotion: reduceMotion)
        case .glowPulse: GlowPulseCelebration(reduceMotion: reduceMotion)
        case .sparkle: SparkleCelebration(reduceMotion: reduceMotion)
        case .doodleStars: DoodleStarsCelebration(reduceMotion: reduceMotion)
        }
    }
}
