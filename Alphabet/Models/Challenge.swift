import Foundation

/// A target word in Challenge mode, paired with an SF Symbol that pictures it.
struct WordPrompt: Equatable, Codable {
    let word: String        // lowercase letters, no spaces
    let symbol: String      // SF Symbol name
}

enum ChallengeStatus: Equatable {
    case building
    case correct
    case wrong
}

struct ChallengeState: Equatable {
    var prompts: [WordPrompt]
    var index: Int = 0
    var status: ChallengeStatus = .building
    /// How many leading letters are revealed as graduated hints on the current word.
    /// Grows by one with each wrong attempt; resets on a new word.
    var hintLevel: Int = 0

    var current: WordPrompt? {
        prompts.indices.contains(index) ? prompts[index] : nil
    }
    var isFinished: Bool { index >= prompts.count }

    mutating func advance() {
        index += 1
        status = .building
        hintLevel = 0
    }
    mutating func restart() {
        index = 0
        status = .building
        hintLevel = 0
    }
}
