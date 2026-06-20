import XCTest
@testable import Alphabet

final class WordListTests: XCTestCase {
    func testFallbackNeverEmpty() {
        XCTAssertFalse(WordList.fallback.isEmpty)
    }

    func testDecodesPromptArray() throws {
        let json = #"[{"word":"sun","symbol":"sun.max"}]"#.data(using: .utf8)!
        let p = try JSONDecoder().decode([WordPrompt].self, from: json)
        XCTAssertEqual(p.first, WordPrompt(word: "sun", symbol: "sun.max"))
    }

    func testBundledWordsLoadAndAreValid() {
        // The shipped words.json should load (or fall back) and never be empty.
        let list = WordList.load()
        XCTAssertFalse(list.prompts.isEmpty)
        for p in list.prompts {
            XCTAssertFalse(p.word.isEmpty)
            XCTAssertFalse(p.symbol.isEmpty)
            XCTAssertEqual(p.word, p.word.lowercased())
        }
    }
}
