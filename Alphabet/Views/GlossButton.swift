import SwiftUI

/// A chunky, glossy, kid-sized capsule button: icon over a label, themed paint.
struct GlossButton: View {
    let systemImage: String
    let title: String
    let paint: ButtonPaint
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(paint.label)
            .frame(minWidth: 74, minHeight: 64)
            .padding(.horizontal, 14)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [paint.fillTop, paint.fillBottom],
                                   startPoint: .top, endPoint: .bottom))
            )
            .overlay(Capsule().stroke(paint.rim, lineWidth: 2))
            .overlay(alignment: .top) {
                Capsule()
                    .fill(.white.opacity(paint.glossOpacity))
                    .frame(height: 16)
                    .padding(.horizontal, 12)
                    .padding(.top, 5)
            }
            .shadow(color: paint.rim.opacity(0.45), radius: 6, y: 4)
        }
        .buttonStyle(PressScaleStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(title)
    }
}

/// Juicy press feedback shared by tappable controls.
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
