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
    /// How letters are voiced: by name, by sound (phonics), or both.
    var speechMode: SpeechMode = .names
    /// Fetch real human recordings for whole words online (cached on device), preferring
    /// them over the built-in voice for the final "say the word" step.
    var useOnlinePronunciation: Bool = true

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
            speech.speakLetter(letter, language: language, mode: speechMode, rate: rate) { [weak self] in
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
            tiles: tiles, language: language, mode: speechMode,
            includeWord: real, blend: speechMode.usesSounds,
            useOnline: useOnlinePronunciation, rate: rate,
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
        prefetchChallengeWord()
    }

    func setLanguage(_ lang: AppLanguage) {
        guard lang != language else { return }
        language = lang
        words = WordList.load(language: lang)
        if mode == .challenge { challenge = ChallengeState(prompts: words.prompts) }
        clear()
        prefetchChallengeWord()
    }

    // MARK: Challenge

    func checkChallenge() {
        guard var c = challenge, let target = c.current else { return }
        if currentWord.lowercased() == target.word.lowercased() {
            c.status = .correct
            challenge = c
            isSpeaking = true
            speech.speak(
                tiles: tiles, language: language, mode: speechMode,
                includeWord: true, blend: speechMode.usesSounds,
                useOnline: useOnlinePronunciation, rate: rate,
                onHighlight: { [weak self] in self?.highlightedTileID = $0 },
                onFinish: { [weak self] in self?.isSpeaking = false; self?.highlightedTileID = nil }
            )
        } else {
            // Graduated scaffolding: reveal one more leading letter (never the whole word)
            // and sound it out, so the child gets unstuck instead of just being buzzed.
            c.status = .wrong
            let maxHint = max(0, target.word.count - 1)
            if c.hintLevel < maxHint { c.hintLevel += 1 }
            challenge = c
            let revealIdx = c.hintLevel - 1
            let chars = Array(target.word)
            if chars.indices.contains(revealIdx) {
                speech.speakLetter(String(chars[revealIdx]), language: language,
                                   mode: speechMode, rate: rate) { }
            }
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
        prefetchChallengeWord()
    }

    func restartChallenge() {
        guard var c = challenge else { return }
        c.restart()
        challenge = c
        clear()
        prefetchChallengeWord()
    }

    func speakChallengeHint() {
        guard let w = challenge?.current?.word else { return }
        speech.speak(
            tiles: w.map { Tile(letter: String($0)) }, language: language, mode: speechMode,
            includeWord: true, blend: speechMode.usesSounds,
            useOnline: useOnlinePronunciation, rate: rate,
            onHighlight: { _ in }, onFinish: { }
        )
    }

    /// Warm the recording cache for the current Challenge word so it's ready by the time
    /// the child solves it (no-op offline or when online audio is off).
    func prefetchChallengeWord() {
        guard useOnlinePronunciation, let word = challenge?.current?.word else { return }
        let lang = language
        Task { await PronunciationStore.shared.prefetch(word: word, language: lang) }
    }
}
