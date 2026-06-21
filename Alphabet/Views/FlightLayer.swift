import SwiftUI

/// Identifies a measured frame in the shared "flight" coordinate space.
enum FrameID: Hashable {
    case grid(String)   // a letter's cell in the top grid
    case slot(UUID)     // a tile's resting slot in the word tray
}

/// Collects frames reported by grid cells and tray slots into one registry.
struct TileFrameKey: PreferenceKey {
    static var defaultValue: [FrameID: CGRect] = [:]
    static func reduce(value: inout [FrameID: CGRect], nextValue: () -> [FrameID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    /// Publish this view's frame (in the named space) under `id`. Uses a zero-size
    /// `Color.clear` background so measuring never perturbs layout.
    func reportFrame(_ id: FrameID, in space: String) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(key: TileFrameKey.self,
                                       value: [id: geo.frame(in: .named(space))])
            }
        )
    }
}

/// Shared shrink-to-fit math for the word tray — used by the tray to size tiles and to
/// derive the maximum letter count (the point at which tiles would shrink below `minTile`).
enum TrayLayout {
    static let maxTile: CGFloat = 66
    static let minTile: CGFloat = 34
    static let spacing: CGFloat = 10
    static let hardCap = 16

    static func tileSize(width: CGFloat, count: Int) -> CGFloat {
        guard count > 0, width > 0 else { return maxTile }
        let raw = (width - spacing * CGFloat(count - 1)) / CGFloat(count)
        return min(maxTile, max(minTile, raw))
    }

    static func maxCount(width: CGFloat) -> Int {
        guard width > 0 else { return 12 }
        return min(hardCap, max(1, Int((width + spacing) / (minTile + spacing))))
    }
}

/// One letter currently flying from its grid cell to its tray slot.
struct Flight: Identifiable, Equatable {
    let id: UUID        // == the destination Tile.id
    let letter: String
}

/// A transient flying copy of a letter. Lerps position + size from the grid cell to the
/// tray slot, with a parabolic arc. Lives in an overlay with `.position`/`.frame` only,
/// so it never affects any ancestor's layout.
struct FlyingTile: View {
    let flight: Flight
    let from: CGRect
    let to: CGRect
    let arcHeight: CGFloat
    let animation: Animation
    let onLanded: () -> Void

    @State private var t: CGFloat = 0

    private func lerp(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * t }

    var body: some View {
        let w = lerp(from.width, to.width)
        let h = lerp(from.height, to.height)
        let x = lerp(from.midX, to.midX)
        let y = lerp(from.midY, to.midY) - arcHeight * 4 * t * (1 - t)   // up-and-over throw
        TileView(letter: flight.letter)
            .frame(width: w, height: h)
            .position(x: x, y: y)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(animation) { t = 1 } completion: { onLanded() }
            }
    }
}

/// Overlay that renders every in-flight letter. A flight only animates once BOTH its grid
/// frame and its (reserved, invisible) tray-slot frame are known.
struct FlightLayer: View {
    let flights: [Flight]
    let frames: [FrameID: CGRect]
    let arcHeight: CGFloat
    let animation: Animation
    let onLanded: (UUID) -> Void

    var body: some View {
        ZStack {
            ForEach(flights) { flight in
                if let from = frames[.grid(flight.letter)], let to = frames[.slot(flight.id)] {
                    FlyingTile(flight: flight, from: from, to: to,
                               arcHeight: arcHeight, animation: animation) {
                        onLanded(flight.id)
                    }
                    .id(flight.id)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
