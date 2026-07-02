import SwiftUI

/// Explore | Challenge segmented control, themed.
struct ModeSwitcher: View {
    @Bindable var model: AppModel
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            ForEach(GameMode.allCases) { mode in
                let selected = model.mode == mode
                Text(mode.title)
                    .font(.system(size: 18, weight: selected ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(selected ? theme.switcherThumb.label : theme.uiTextOnBackground.opacity(0.65))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background {
                        if selected {
                            Capsule().fill(LinearGradient(
                                colors: [theme.switcherThumb.fillTop, theme.switcherThumb.fillBottom],
                                startPoint: .top, endPoint: .bottom))
                        }
                    }
                    .contentShape(Capsule())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { model.setMode(mode) }
                    }
            }
        }
        .padding(5)
        .background(Capsule().fill(theme.switcherTrack))
        .overlay(Capsule().stroke(theme.slotStroke.opacity(0.4), lineWidth: 1))
    }
}
