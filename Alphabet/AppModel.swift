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
    var maxTiles: Int = 12
    var flyingIDs: Set<UUID> { Set(flights.map(\.id)) }

    // Settings mirrored from the store.
    var language: AppLanguage = .englishUK
    var soundOnTap: Bool = false

    /// True while a tapped letter is being sounded out (tap-to-hear mode) — blocks the
    /// next tap until the letter finishes, so each one is heard clearly.
    var inputLocked = false
    /// Bumped when Speak is pressed on a word that isn't real, so the view can give a
    /// gentle "not yet" cue.
    var nonWordNudge = 0
    /// Last removed tile, for one-step Undo of an accidental deletion.
    private(set) var lastRemoved: (tile: Tile, index: Int)?
    var canUndo: Bool { lastRemoved != nil }

    let speech: any Speaking
    var words: WordList

    init(speech: any Speaking, words: WordList) {
        self.speech = speech
        self.words = words
    }

    /// Letters only (spaces ignored) — used for Challenge answer matching + word check.
    var currentWord: String {
        tiles.map(\.letter).filter { $0 != " " }.joined()
    }

    var rate: Double {
        UserDefaults.standard.object(forKey: "speechRate") as? Double ?? 0.35
    }

    // MARK: Building the word

    /// Adds a letter to the word. Returns false (and does nothing) if the tray is full or
    /// input is locked during a tap-to-hear cooldown. When `fly` is true the tile is
    /// spawned invisible and a `Flight` is queued so the grid letter animates into its slot.
    @discardableResult
    func tapLetter(_ letter: String, fly: Bool = false) -> Bool {
        guard !inputLocked, tiles.count < maxTiles else { return false }
        lastRemoved = nil
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
        if soundOnTap {
            inputLocked = true
            speech.speakLetter(letter, language: language, rate: rate) { [weak self] in
                self?.inputLocked = false
            }
            // Safety: always release the lock even if the finish callback never fires.
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(1.5))
                self?.inputLocked = false
            }
        }
        return true
    }

    func completeFlight(_ id: UUID) {
        flights.removeAll { $0.id == id }
    }

    func removeTile(_ id: Tile.ID, longPress: Bool) {
        guard let i = tiles.firstIndex(where: { $0.id == id }) else { return }
        lastRemoved = (tiles[i], i)
        tiles.remove(at: i)
        flights.removeAll { $0.id == id }
        removedSlotIndex = longPress ? i : nil
    }

    /// Undo the last accidental removal.
    func undoRemove() {
        guard let last = lastRemoved, last.index <= tiles.count else { return }
        tiles.insert(last.tile, at: last.index)
        lastRemoved = nil
        removedSlotIndex = nil
    }

    func clear() {
        speech.stop()
        tiles.removeAll()
        flights.removeAll()
        removedSlotIndex = nil
        lastRemoved = nil
        isSpeaking = false
        highlightedTileID = nil
    }

    // MARK: Speaking

    /// Spells the letters; says the whole word only if it's a real word in the current
    /// language, otherwise emits a gentle "not yet" nudge after spelling.
    func speakCurrentWord() {
        guard !tiles.isEmpty, !isSpeaking else { return }
        isSpeaking = true
        let real = WordValidator.isRealWord(currentWord, language: language)
        speech.speak(
            tiles: tiles, language: language, includeWord: real, rate: rate,
            onHighlight: { [weak self] in self?.highlightedTileID = $0 },
            onFinish: { [weak self] in
                self?.isSpeaking = false
                self?.highlightedTileID = nil
                if !real { self?.nonWordNudge += 1 }
            }
        )
    }

    // MARK: Modes

    func setMode(_ m: GameMode) {
        mode = m
        clear()
        challenge = (m == .challenge) ? ChallengeState(prompts: words.prompts) : nil
    }

    func setLanguage(_ lang: AppLanguage) {
        guard lang != language else { return }
        language = lang
        words = WordList.load(language: lang)
        if mode == .challenge { challenge = ChallengeState(prompts: words.prompts) }
        clear()
    }

    // MARK: Challenge

    func checkChallenge() {
        guard var c = challenge, let target = c.current else { return }
        if currentWord.lowercased() == target.word.lowercased() {
            c.status = .correct
            challenge = c
            isSpeaking = true
            speech.speak(
                tiles: tiles, language: language, includeWord: true, rate: rate,
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
        lastRemoved = nil
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
            tiles: w.map { Tile(letter: String($0)) }, language: language, includeWord: true, rate: rate,
            onHighlight: { _ in }, onFinish: { }
        )
    }
}
