import SwiftUI

/// The word being built — tiles only (controls live in a separate bar below). Tiles
/// shrink-to-fit the fixed-width tray so the content can never overflow and push the
/// layout wider (which previously made the whole screen "zoom"). Tap to remove,
/// long-press to remove-and-keep the slot. Each slot publishes its frame so a flying
/// letter knows where to land; a flying tile stays invisible in its reserved slot until
/// it arrives.
struct WordTrayView: View {
    @Bindable var model: AppModel
    let reduceMotion: Bool
    let space: String
    @Environment(\.theme) private var theme

    private let inset: CGFloat = 18
    private let trayHeight: CGFloat = 104

    private var spring: Animation {
        reduceMotion ? .easeInOut(duration: 0.2)
                     : .spring(response: theme.motion.springResponse,
                               dampingFraction: theme.motion.springDamping)
    }

    var body: some View {
        GeometryReader { geo in
            let avail = max(0, geo.size.width - inset * 2)
            let size = TrayLayout.tileSize(width: avail, count: model.tiles.count)
            HStack(spacing: TrayLayout.spacing) {
                ForEach(model.tiles) { tile in
                    TileView(letter: tile.letter, isHighlighted: model.highlightedTileID == tile.id)
                        .frame(width: size, height: size)
                        .reportFrame(.slot(tile.id), in: space)
                        .opacity(model.flyingIDs.contains(tile.id) ? 0 : 1)
                        .onTapGesture { withAnimation(spring) { model.removeTile(tile.id, longPress: false) } }
                        .onLongPressGesture { withAnimation(spring) { model.removeTile(tile.id, longPress: true) } }
                        .transition(.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(spring, value: model.tiles.map(\.id))
            .onAppear { model.maxTiles = TrayLayout.maxCount(width: avail) }
            .onChange(of: avail) { _, w in model.maxTiles = TrayLayout.maxCount(width: w) }
        }
        .frame(height: trayHeight)
        .frame(maxWidth: .infinity)
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
}
