import SwiftUI

/// The word being built. Tiles drop in from above; tap to remove, long-press to
/// remove-and-keep the slot. Hosts the control cluster.
struct WordTrayView: View {
    @Bindable var model: AppModel
    let reduceMotion: Bool
    @Environment(\.theme) private var theme

    private var spring: Animation {
        reduceMotion ? .easeInOut(duration: 0.2)
                     : .spring(response: theme.motion.springResponse,
                               dampingFraction: theme.motion.springDamping)
    }

    var body: some View {
        HStack(spacing: 16) {
            ControlCluster(model: model)
            tiles
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 108)
        .background(traySurface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(theme.slotStroke.opacity(0.6), lineWidth: 2))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
    }

    @ViewBuilder private var traySurface: some View {
        if theme.usesMaterialSurface {
            theme.traySurface.opacity(0.55).background(.ultraThinMaterial)
        } else {
            theme.traySurface
        }
    }

    private var tiles: some View {
        HStack(spacing: 10) {
            ForEach(model.tiles) { tile in
                TileView(letter: tile.letter, isHighlighted: model.highlightedTileID == tile.id)
                    .frame(width: 64, height: 64)
                    .onTapGesture { withAnimation(spring) { model.removeTile(tile.id, longPress: false) } }
                    .onLongPressGesture { withAnimation(spring) { model.removeTile(tile.id, longPress: true) } }
                    .transition(.asymmetric(
                        insertion: reduceMotion ? .opacity
                            : .move(edge: .top).combined(with: .scale).combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)))
            }
        }
        .animation(spring, value: model.tiles.map(\.id))
    }
}
