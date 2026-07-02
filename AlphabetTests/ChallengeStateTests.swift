import XCTest
@testable import Alphabet

final class ChallengeStateTests: XCTestCase {
    func testAdvanceAndFinish() {
        var s = ChallengeState(prompts: [.init(word: "cat", symbol: "cat"),
                                         .init(word: "dog", symbol: "dog")])
        XCTAssertEqual(s.current?.word, "cat")
        XCTAssertFalse(s.isFinished)
        s.advance()
        XCTAssertEqual(s.current?.word, "dog")
        s.advance()
        XCTAssertTrue(s.isFinished)
        XCTAssertNil(s.current)
        s.restart()
        XCTAssertEqual(s.current?.word, "cat")
    }
}
