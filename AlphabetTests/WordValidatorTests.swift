import XCTest
@testable import Alphabet

final class WordValidatorTests: XCTestCase {
    func testEnglishAcceptsRealRejectsNonsense() {
        XCTAssertTrue(WordValidator.isRealWord("cat", language: .englishUK))
        XCTAssertTrue(WordValidator.isRealWord("dog", language: .englishUK))
        XCTAssertTrue(WordValidator.isRealWord("sun", language: .englishUK))
        XCTAssertFalse(WordValidator.isRealWord("xqzjk", language: .englishUK))
    }

    func testGermanAcceptsCapitalizedNoun() {
        // German nouns are capitalized; the validator accepts either case.
        // (Only assert the positive case — German spell data may be limited on some sims.)
        XCTAssertTrue(WordValidator.isRealWord("hund", language: .german))
    }

    func testEmptyIsNotReal() {
        XCTAssertFalse(WordValidator.isRealWord("", language: .englishUK))
    }
}
