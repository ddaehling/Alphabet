import Foundation

/// The four switchable worlds. Each case resolves to its concrete `Theme` tokens,
/// defined in its own file under `Theme/Themes/` (so they can be built in parallel).
enum ThemeID: String, CaseIterable, Identifiable, Codable {
    case sunnySky
    case pastelCalm
    case jellyLab
    case storybook

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sunnySky: "Sunny Sky"
        case .pastelCalm: "Soft Pastel"
        case .jellyLab: "Jelly Lab"
        case .storybook: "Storybook"
        }
    }

    var theme: Theme {
        switch self {
        case .sunnySky: SunnySkyTheme.theme
        case .pastelCalm: PastelCalmTheme.theme
        case .jellyLab: JellyLabTheme.theme
        case .storybook: StorybookTheme.theme
        }
    }
}
