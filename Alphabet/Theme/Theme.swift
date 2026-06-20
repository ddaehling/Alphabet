import SwiftUI

/// Paint for a glossy themed button: a vertical fill, a bottom bevel rim, and a label color.
struct ButtonPaint: Equatable {
    var fillTop: Color
    var fillBottom: Color
    var rim: Color
    var label: Color
    var glossOpacity: Double = 0.4
}

enum ChipShape: Equatable {
    case circle
    case roundedSquare(cornerRadius: CGFloat)
}

/// The contrast chip seated behind every glossy letter — the legibility guarantee.
struct TileChipStyle: Equatable {
    enum Tint: Equatable {
        case letterColor    // tint to the per-letter rainbow color
        case neutralLight   // soft white/cream chip
        case neutralDark    // dark chip (e.g. jelly lab)
    }
    var tint: Tint
    var shape: ChipShape = .circle
    var shadowOpacity: Double = 0.12
    var highlightOpacity: Double = 0.7
}

/// How letters move in a theme.
struct MotionProfile: Equatable {
    var springResponse: Double = 0.45
    var springDamping: Double = 0.6
    var flyArcHeight: CGFloat = 90
    var idleWobble: Bool = false
}

enum CelebrationStyle: String, Equatable {
    case confetti, glowPulse, sparkle, doodleStars
}

struct ThemeTypography: Equatable {
    var titleWeight: Font.Weight = .bold
    var labelWeight: Font.Weight = .semibold
}

/// All visual tokens for one "world." Layout lives in shared views; only these
/// tokens (and a theme-specific background + celebration view) differ per theme.
struct Theme: Identifiable, Equatable {
    let id: ThemeID
    var name: String

    var uiTextOnBackground: Color
    var uiTextOnSurface: Color

    var traySurface: Color
    var usesMaterialSurface: Bool = false   // ignored under Reduce Transparency
    var slotFill: Color
    var slotStroke: Color

    var primaryButton: ButtonPaint          // Speak / Check
    var secondaryButton: ButtonPaint        // Clear
    var switcherTrack: Color
    var switcherThumb: ButtonPaint

    var tileChip: TileChipStyle
    var motion: MotionProfile
    var celebration: CelebrationStyle
    var typography: ThemeTypography = ThemeTypography()
}
