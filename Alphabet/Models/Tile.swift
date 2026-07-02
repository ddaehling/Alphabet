import Foundation

/// One letter in the word the child is building. A fresh `id` per tap lets the
/// same letter appear multiple times and animate independently.
struct Tile: Identifiable, Equatable {
    let id: UUID
    let letter: String          // "a"..."z" or " " for the space tile

    init(letter: String, id: UUID = UUID()) {
        self.letter = letter
        self.id = id
    }

    var isSpace: Bool { letter == " " }
}
