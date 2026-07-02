import XCTest
@testable import Alphabet

final class SpeechPlanTests: XCTestCase {
    private func tiles(_ s: String) -> [Tile] { s.map { Tile(letter: String($0)) } }

    /// Spoken text of each step (letter name or word), ignoring ipa/trailing.
    private func texts(_ steps: [SpeechStep]) -> [String] {
        steps.map {
            switch $0 {
            case let .letter(_, text, _, _): text
            case let .word(text): text
            }
        }
    }
    private func letterSteps(_ steps: [SpeechStep]) -> [SpeechStep] {
        steps.filter { if case .letter = $0 { true } else { false } }
    }
    private func ipas(_ steps: [SpeechStep]) -> [String?] {
        letterSteps(steps).map { if case let .letter(_, _, ipa, _) = $0 { ipa } else { nil } }
    }

    // MARK: Names

    func testNamesModeSpellsThenSaysWord() {
        let p = SpeechPlan.make(for: tiles("cat"), mode: .names)
        XCTAssertEqual(texts(p), ["see", "ay", "tee", "cat"])
        XCTAssertEqual(ipas(p), [nil, nil, nil])      // names carry no phoneme hint
        XCTAssertEqual(p.last, .word(text: "cat"))
    }

    // MARK: Sounds / Both

    func testSoundsModeAttachesIPA() {
        let p = SpeechPlan.make(for: tiles("cat"), mode: .sounds, includeWord: false)
        XCTAssertEqual(ipas(p), ["k", "æ", "t"])
    }

    func testBothModeSaysNameThenSoundPerLetter() {
        let p = SpeechPlan.make(for: tiles("at"), mode: .both, includeWord: false)
        XCTAssertEqual(letterSteps(p).count, 4)        // a-name, a-sound, t-name, t-sound
        XCTAssertEqual(ipas(p), [nil, "æ", nil, "t"])
    }

    // MARK: Blending

    func testBlendAppendsCompressedSoundsBeforeWord() {
        let plain = SpeechPlan.make(for: tiles("cat"), mode: .sounds, includeWord: true, blend: false)
        let blended = SpeechPlan.make(for: tiles("cat"), mode: .sounds, includeWord: true, blend: true)
        XCTAssertEqual(blended.count, plain.count + 3)         // +3 phonemes for the blend run
        XCTAssertEqual(blended.last, .word(text: "cat"))
        guard case let .letter(_, _, _, trailing) = blended[blended.count - 2] else {
            return XCTFail("expected a sound step right before the word")
        }
        XCTAssertEqual(trailing, 0, accuracy: 0.0001)          // last blend sound slides into the word
    }

    func testNoBlendForNamesOrWithoutWord() {
        let names = SpeechPlan.make(for: tiles("cat"), mode: .names, includeWord: true, blend: true)
        XCTAssertEqual(texts(names), ["see", "ay", "tee", "cat"])     // names never blend
        let noWord = SpeechPlan.make(for: tiles("cat"), mode: .sounds, includeWord: false, blend: true)
        XCTAssertEqual(letterSteps(noWord).count, 3)                  // no word ⇒ no blend run
    }

    // MARK: Spaces / indices / empties

    func testSkipsSpacesButSplitsWords() {
        let t = tiles("hi") + [Tile(letter: " ")] + tiles("yo")
        let p = SpeechPlan.make(for: t)
        XCTAssertEqual(letterSteps(p).count, 4)
        XCTAssertEqual(p.last, .word(text: "hi yo"))
    }

    func testLetterIndicesPointAtNonSpaceTiles() {
        let t = tiles("a") + [Tile(letter: " ")] + tiles("b")
        let p = SpeechPlan.make(for: t)
        guard case let .letter(i0, _, _, _) = p[0], case let .letter(i1, _, _, _) = p[1] else {
            return XCTFail("expected two letter steps first")
        }
        XCTAssertEqual(i0, 0)   // "a"
        XCTAssertEqual(i1, 2)   // "b" (index 1 is the skipped space)
    }

    func testEmptyProducesNothing() {
        XCTAssertTrue(SpeechPlan.make(for: []).isEmpty)
    }

    func testExcludeWholeWordWhenNotIncluded() {
        let p = SpeechPlan.make(for: tiles("cat"), includeWord: false)
        XCTAssertFalse(p.contains { if case .word = $0 { true } else { false } })
        XCTAssertEqual(letterSteps(p).count, 3)
    }

    // MARK: Language maps

    func testBritishLetterNames() {
        XCTAssertEqual(SpeechPlan.letterName["z"], "zed")
        XCTAssertEqual(SpeechPlan.letterName["h"], "aitch")
    }

    func testGermanNamesAndSounds() {
        XCTAssertEqual(SpeechPlan.germanLetterName["z"], "zett")
        XCTAssertEqual(SpeechPlan.germanLetterName["ä"], "äh")
        XCTAssertEqual(SpeechPlan.germanLetterSound["w"], "v")    // German w = /v/
        XCTAssertEqual(SpeechPlan.germanLetterSound["z"], "ts")
        let p = SpeechPlan.make(for: [Tile(letter: "a")], language: .german, includeWord: false)
        XCTAssertEqual(texts(p), ["ah"])
    }

    // MARK: Single-letter (tap-to-hear)

    func testMakeSingleHonoursMode() {
        XCTAssertEqual(texts(SpeechPlan.makeSingle(letter: "c", language: .englishUK, mode: .names)), ["see"])
        let sound = SpeechPlan.makeSingle(letter: "c", language: .englishUK, mode: .sounds)
        XCTAssertEqual(ipas(sound), ["k"])
        XCTAssertEqual(SpeechPlan.makeSingle(letter: "c", language: .englishUK, mode: .both).count, 2)
    }
}
