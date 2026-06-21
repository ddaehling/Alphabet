import SwiftUI

@MainActor
@Observable
final class AppModel {
    var mode: GameMode = .explore
    var tiles: [Tile] = []
    var removedSlotIndex: Int?
    var isSpeaking = false
    var highlightedTileID: Tile.ID?
    var challenge: ChallengeState?
    var showThemePicker = false

    /// Letters currently flying from the grid into the tray (rendered invisible in their
    /// reserved slot until they land).
    var flights: [Flight] = []
    /// Max letters the tray can hold before tiles would shrink below the legible minimum.
    /// Updated by the tray from its measured width.
    var maxTiles: Int = 12
    var flyingIDs: Set<UUID> { Set(flights.map(\.id)) }

    let speech: any Speaking
    let words: WordList

    init(speech: any Speaking, words: WordList) {
        self.speech = speech
        self.words = words
    }

    /// Letters only (spaces ignored) — used for Challenge answer matching.
    var currentWord: String {
        tiles.map(\.letter).filter { $0 != " " }.joined()
    }

    var rate: Double {
        UserDefaults.standard.object(forKey: "speechRate") as? Double ?? 0.35
    }

    // MARK: Building the word

    /// Adds a letter to the word. Returns false (and does nothing) if the tray is full.
    /// When `fly` is true the tile is spawned invisible and a `Flight` is queued so the
    /// grid letter can animate into its slot; a safety timer un-hides it regardless.
    @discardableResult
    func tapLetter(_ letter: String, fly: Bool = false) -> Bool {
        guard tiles.count < maxTiles else { return false }
        let tile = Tile(letter: letter)
        if let i = removedSlotIndex, i <= tiles.count {
            tiles.insert(tile, at: i)
            removedSlotIndex = nil
        } else {
            tiles.append(tile)
        }
        if fly {
            flights.append(Flight(id: tile.id, letter: letter))
            let id = tile.id
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(1.6))
                self?.completeFlight(id)
            }
        }
        return true
    }

    func completeFlight(_ id: UUID) {
        flights.removeAll { $0.id == id }
    }

    func removeTile(_ id: Tile.ID, longPress: Bool) {
        guard let i = tiles.firstIndex(where: { $0.id == id }) else { return }
        tiles.remove(at: i)
        flights.removeAll { $0.id == id }
        removedSlotIndex = longPress ? i : nil
    }

    func clear() {
        speech.stop()
        tiles.removeAll()
        flights.removeAll()
        removedSlotIndex = nil
        isSpeaking = false
        highlightedTileID = nil
    }

    // MARK: Speaking

    func speakCurrentWord() {
        guard !tiles.isEmpty, !isSpeaking else { return }
        isSpeaking = true
        speech.speak(
            tiles: tiles, rate: rate,
            onHighlight: { [weak self] in self?.highlightedTileID = $0 },
            onFinish: { [weak self] in self?.isSpeaking = false; self?.highlightedTileID = nil }
        )
    }

    // MARK: Modes

    func setMode(_ m: GameMode) {
        mode = m
        clear()
        challenge = (m == .challenge) ? ChallengeState(prompts: words.prompts) : nil
    }

    // MARK: Challenge

    func checkChallenge() {
        guard var c = challenge, let target = c.current else { return }
        if currentWord.lowercased() == target.word.lowercased() {
            c.status = .correct
            challenge = c
            isSpeaking = true
            speech.speak(
                tiles: tiles, rate: rate,
                onHighlight: { [weak self] in self?.highlightedTileID = $0 },
                onFinish: { [weak self] in self?.isSpeaking = false; self?.highlightedTileID = nil }
            )
        } else {
            c.status = .wrong
            challenge = c
        }
    }

    /// Returns the wrong attempt to the building state (after the jiggle plays).
    func clearWrongStatus() {
        guard var c = challenge, c.status == .wrong else { return }
        c.status = .building
        challenge = c
    }

    func advanceChallenge() {
        guard var c = challenge else { return }
        c.advance()
        challenge = c
        tiles.removeAll()
        flights.removeAll()
        removedSlotIndex = nil
    }

    func restartChallenge() {
        guard var c = challenge else { return }
        c.restart()
        challenge = c
        clear()
    }

    func speakChallengeHint() {
        guard let w = challenge?.current?.word else { return }
        speech.speak(
            tiles: w.map { Tile(letter: String($0)) }, rate: rate,
            onHighlight: { _ in }, onFinish: { }
        )
    }
}
