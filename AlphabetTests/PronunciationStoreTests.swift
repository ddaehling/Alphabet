import XCTest
@testable import Alphabet

/// Covers the pure, offline pieces of the online-pronunciation store: cache-key
/// normalization and parsing a dictionaryapi.dev response. The network path itself is
/// not unit-tested (it hits a live service).
final class PronunciationStoreTests: XCTestCase {

    func testNormalizeKeepsOnlyLowercaseLetters() {
        XCTAssertEqual(PronunciationStore.normalize("Cat"), "cat")
        XCTAssertEqual(PronunciationStore.normalize("hi yo!"), "hiyo")
        XCTAssertEqual(PronunciationStore.normalize("  DOG  "), "dog")
    }

    private func json(_ s: String) -> Data { Data(s.utf8) }

    func testParsePrefersBritishAudioForEnglish() {
        let data = json("""
        [{"word":"cat","phonetics":[
          {"text":"/kæt/","audio":"https://api.example.com/cat-us.mp3"},
          {"text":"/kat/","audio":"https://api.example.com/cat-uk.mp3"}
        ]}]
        """)
        let url = PronunciationStore.audioURL(fromDictionaryJSON: data, preferUK: true)
        XCTAssertEqual(url?.absoluteString, "https://api.example.com/cat-uk.mp3")
    }

    func testParseFallsBackToFirstAudioWhenNoUK() {
        let data = json("""
        [{"word":"cat","phonetics":[
          {"text":"/kæt/","audio":"https://api.example.com/cat-us.mp3"}
        ]}]
        """)
        let url = PronunciationStore.audioURL(fromDictionaryJSON: data, preferUK: true)
        XCTAssertEqual(url?.absoluteString, "https://api.example.com/cat-us.mp3")
    }

    func testParseSkipsEmptyAudioStrings() {
        let data = json("""
        [{"word":"cat","phonetics":[
          {"text":"/kæt/","audio":""},
          {"text":"/kat/","audio":"https://api.example.com/cat.mp3"}
        ]}]
        """)
        let url = PronunciationStore.audioURL(fromDictionaryJSON: data, preferUK: false)
        XCTAssertEqual(url?.absoluteString, "https://api.example.com/cat.mp3")
    }

    func testParseFixesProtocolRelativeURL() {
        let data = json("""
        [{"phonetics":[{"audio":"//ssl.example.com/cat.mp3"}]}]
        """)
        let url = PronunciationStore.audioURL(fromDictionaryJSON: data, preferUK: false)
        XCTAssertEqual(url?.absoluteString, "https://ssl.example.com/cat.mp3")
    }

    func testParseReturnsNilOnErrorObjectOrNoAudio() {
        // dictionaryapi.dev returns an object (not an array) with "title" on 404.
        XCTAssertNil(PronunciationStore.audioURL(
            fromDictionaryJSON: json(#"{"title":"No Definitions Found"}"#), preferUK: true))
        XCTAssertNil(PronunciationStore.audioURL(
            fromDictionaryJSON: json(#"[{"word":"x","phonetics":[]}]"#), preferUK: true))
    }

    func testCachedFileURLNilWhenNotDownloaded() {
        // A word we've never fetched has no cached file.
        let store = PronunciationStore()
        XCTAssertNil(store.cachedFileURL(word: "zzzznever", language: .englishUK))
        XCTAssertNil(store.cachedFileURL(word: "", language: .englishUK))
    }
}
