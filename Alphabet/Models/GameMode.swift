import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case explore
    case challenge
    var id: String { rawValue }

    var title: String {
        switch self {
        case .explore: "Explore"
        case .challenge: "Challenge"
        }
    }
}
