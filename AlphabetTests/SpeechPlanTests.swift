import XCTest
@testable import Alphabet

final class SpeechPlanTests: XCTestCase {
    private func tiles(_ s: String) -> [Tile] { s.map { Tile(letter: String($0)) } }

    func testSpellsThenSaysWord() {
        let p = SpeechPlan.make(for: tiles("cat"))
        XCTAssertEqual(p, [
            .letter(tileIndex: 0, spoken: "see"),
            .letter(tileIndex: 1, spoken: "ay"),
            .letter(tileIndex: 2, spoken: "tee"),
            .word(spoken: "cat"),
        ])
    }

    func testSkipsSpacesButSplitsWords() {
        let t = tiles("hi") + [Tile(letter: " ")] + tiles("yo")
        let p = SpeechPlan.make(for: t)
        let letters = p.filter { if case .letter = $0 { true } else { false } }
        XCTAssertEqual(letters.count, 4)
        XCTAssertEqual(p.last, .word(spoken: "hi yo"))
    }

    func testEmptyProducesNothing() {
        XCTAssertTrue(SpeechPlan.make(for: []).isEmpty)
    }

    func testBritishLetterNames() {
        XCTAssertEqual(SpeechPlan.letterName["z"], "zed")
        XCTAssertEqual(SpeechPlan.letterName["h"], "aitch")
    }

    func testLetterIndicesPointAtNonSpaceTiles() {
        let t = tiles("a") + [Tile(letter: " ")] + tiles("b")
        let p = SpeechPlan.make(for: t)
        guard case let .letter(i0, _) = p[0], case let .letter(i1, _) = p[1] else {
            return XCTFail("expected two letter steps first")
        }
        XCTAssertEqual(i0, 0)   // "a"
        XCTAssertEqual(i1, 2)   // "b" (index 1 is the skipped space)
    }
}
