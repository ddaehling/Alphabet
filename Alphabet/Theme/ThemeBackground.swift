import SwiftUI

/// Resolves a theme id to its full-screen background view. Each theme file
/// provides its own `<Name>Background`.
struct ThemeBackground: View {
    let id: ThemeID

    var body: some View {
        switch id {
        case .sunnySky: SunnySkyBackground()
        case .pastelCalm: PastelCalmBackground()
        case .jellyLab: JellyLabBackground()
        case .storybook: StorybookBackground()
        }
    }
}
