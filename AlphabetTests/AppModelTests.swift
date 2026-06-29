import XCTest
@testable import Alphabet

@MainActor
final class AppModelTests: XCTestCase {
    /// A no-op speech double so model tests never touch real audio.
    final class NoopSpeech: Speaking {
        func speak(tiles: [Tile], language: AppLanguage, includeWord: Bool, rate: Double,
                   onHighlight: @escaping (Tile.ID?) -> Void,
                   onFinish: @escaping () -> Void) { onFinish() }
        func speakLetter(_ letter: String, language: AppLanguage, rate: Double,
                         onFinish: @escaping () -> Void) { onFinish() }
        func stop() {}
    }

    private func model() -> AppModel {
        AppModel(speech: NoopSpeech(),
                 words: WordList(prompts: [.init(word: "cat", symbol: "cat"),
                                           .init(word: "dog", symbol: "dog")]))
    }

    func testTapAppendsTile() {
        let m = model()
        ["c", "a", "t"].forEach { m.tapLetter($0) }
        XCTAssertEqual(m.currentWord, "cat")
        XCTAssertEqual(m.tiles.count, 3)
    }

    func testRemoveAndReinsertAtSlot() {
        let m = model()
        ["c", "a", "t"].forEach { m.tapLetter($0) }
        m.removeTile(m.tiles[1].id, longPress: true)     // remove 'a', remember slot 1
        XCTAssertEqual(m.currentWord, "ct")
        m.tapLetter("o")                                  // re-inserts at slot 1
        XCTAssertEqual(m.currentWord, "cot")
    }

    func testClear() {
        let m = model()
        ["c", "a", "t"].forEach { m.tapLetter($0) }
        m.clear()
        XCTAssertTrue(m.tiles.isEmpty)
    }

    func testChallengeCorrectAdvances() {
        let m = model()
        m.setMode(.challenge)
        XCTAssertEqual(m.challenge?.current?.word, "cat")
        ["c", "a", "t"].forEach { m.tapLetter($0) }
        m.checkChallenge()
        XCTAssertEqual(m.challenge?.status, .correct)
        m.advanceChallenge()
        XCTAssertEqual(m.challenge?.current?.word, "dog")
        XCTAssertTrue(m.tiles.isEmpty)
    }

    func testChallengeWrongStays() {
        let m = model()
        m.setMode(.challenge)
        ["c", "o", "w"].forEach { m.tapLetter($0) }
        m.checkChallenge()
        XCTAssertEqual(m.challenge?.status, .wrong)
        XCTAssertEqual(m.tiles.count, 3)
    }

    func testChallengeExhaustion() {
        let m = model()
        m.setMode(.challenge)
        ["c", "a", "t"].forEach { m.tapLetter($0) }; m.checkChallenge(); m.advanceChallenge()
        ["d", "o", "g"].forEach { m.tapLetter($0) }; m.checkChallenge(); m.advanceChallenge()
        XCTAssertTrue(m.challenge?.isFinished ?? false)
        m.restartChallenge()
        XCTAssertEqual(m.challenge?.current?.word, "cat")
    }

    func testMaxTilesCapRejectsBeyondLimit() {
        let m = model()
        m.maxTiles = 3
        XCTAssertTrue(m.tapLetter("a"))
        XCTAssertTrue(m.tapLetter("b"))
        XCTAssertTrue(m.tapLetter("c"))
        XCTAssertFalse(m.tapLetter("d"))      // rejected at the cap
        XCTAssertEqual(m.tiles.count, 3)
    }

    func testFlyQueuesFlightAndCompletes() {
        let m = model()
        _ = m.tapLetter("a", fly: true)
        let id = m.tiles[0].id
        XCTAssertTrue(m.flyingIDs.contains(id))   // hidden in its slot until it lands
        m.completeFlight(id)
        XCTAssertFalse(m.flyingIDs.contains(id))
    }

    func testClearRemovesFlights() {
        let m = model()
        _ = m.tapLetter("a", fly: true)
        _ = m.tapLetter("b", fly: true)
        XCTAssertEqual(m.flights.count, 2)
        m.clear()
        XCTAssertTrue(m.flights.isEmpty)
    }

    func testUndoRestoresRemovedTile() {
        let m = model()
        ["c", "a", "t"].forEach { m.tapLetter($0) }
        let id = m.tiles[1].id
        m.removeTile(id, longPress: false)
        XCTAssertEqual(m.currentWord, "ct")
        XCTAssertTrue(m.canUndo)
        m.undoRemove()
        XCTAssertEqual(m.currentWord, "cat")
        XCTAssertFalse(m.canUndo)
    }

    func testSetLanguageReloadsWordsAndResetsChallenge() {
        let m = model()
        m.setMode(.challenge)
        m.setLanguage(.german)
        XCTAssertEqual(m.language, .german)
        XCTAssertFalse(m.words.prompts.isEmpty)
        XCTAssertTrue(m.tiles.isEmpty)
    }
}
