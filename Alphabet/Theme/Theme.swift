import SwiftUI

/// Paint for a glossy themed button: a vertical fill, a bottom bevel rim, and a label color.
struct ButtonPaint: Equatable {
    var fillTop: Color
    var fillBottom: Color
    var rim: Color
    var label: Color
    var glossOpacity: Double = 0.4
}

/// Contact drop shadow that grounds a chip-less standalone letter. Radius/offset are
/// fractions of the tile size (tokens are static; tile size is per-cell).
struct LetterShadow: Equatable {
    var color: Color
    var radiusFactor: CGFloat
    var dyFactor: CGFloat
}

/// Optional soft rim — a `.shadow` with no offset and a fully transparent center — that
/// fires only where physics demands it: a dark rim for pale letters on light themes, a
/// white rim for all letters on dark themes. Never a filled disc (that would be a chip
/// by another name).
struct LetterHalo: Equatable {
    var color: Color
    var radiusFactor: CGFloat
    /// true → rim fires for every letter (dark themes); false → only for pale letters (light themes).
    var appliesToAll: Bool = false
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

    var letterShadow: LetterShadow
    var letterHalo: LetterHalo? = nil
    var motion: MotionProfile
    var celebration: CelebrationStyle
    var typography: ThemeTypography = ThemeTypography()
}
