//
//  RootClass.swift
//  Model Generated using http://www.jsoncafe.com/ 
//  Created on December 11, 2020


import Foundation

// MARK: - ApiResponse
public struct APIResponse: Codable {
    public let id: String
    public let metadata: Metadata
    public let results: [Result]
    public let word: String
}

// MARK: - Metadata
public struct Metadata: Codable {
    public let operation, provider, schema: String
}

// MARK: - Result
public struct Result: Codable {
    public let id, language: String
    public let lexicalEntries: [LexicalEntry]
    public let type, word: String
}

// MARK: - LexicalEntry
public struct LexicalEntry: Codable {
    public let entries: [Entry]
    public let language: String
    public let lexicalCategory: LexicalCategory
    public let text: String
}

// MARK: - Entry
public struct Entry: Codable {
    public let homographNumber: String?
    public let pronunciations: [Pronunciation]
}

// MARK: - Pronunciation
public struct Pronunciation: Codable {
    public let audioFile: String
    public let dialects: [String]
    public let phoneticNotation, phoneticSpelling: String
}

// MARK: - LexicalCategory
public struct LexicalCategory: Codable {
    public let id, text: String
}

public extension APIResponse {
    static let mock = Self(
        id: "mock",
        metadata: Metadata(operation: "retrieve",
                           provider: "Oxford University Press",
                           schema: "RetrieveEntry"),
        results: [
            Result(id: "mock",
                   language: "en-gb",
                   lexicalEntries: [
                    LexicalEntry(entries: [
                        Entry(homographNumber: nil,
                              pronunciations: [
                                Pronunciation(
                                    audioFile: "https://audio.oxforddictionaries.com/en/mp3/mock_gb_1.mp3",
                                    dialects: ["British English"],
                                    phoneticNotation: "IPA",
                                    phoneticSpelling: "mɒk")
                              ])
                    ],
                    language: "en-gb",
                    lexicalCategory: LexicalCategory(id: "verb", text: "Verb"),
                    text: "mock"),
                    LexicalEntry(entries: [
                        Entry(homographNumber: nil,
                              pronunciations: [
                                Pronunciation(audioFile: "https://audio.oxforddictionaries.com/en/mp3/mock_gb_1.mp3",
                                              dialects: ["British English"],
                                              phoneticNotation: "IPA",
                                              phoneticSpelling: "mɒk")
                              ])
                    ],
                    language: "en-gb",
                    lexicalCategory: LexicalCategory(id: "adjective", text: "Adjective"),
                    text: "mock"),
                    LexicalEntry(entries: [
                        Entry(homographNumber: nil,
                              pronunciations: [
                                Pronunciation(audioFile: "https://audio.oxforddictionaries.com/en/mp3/mock_gb_1.mp3",
                                              dialects: ["British English"],
                                              phoneticNotation: "IPA",
                                              phoneticSpelling: "mɒk")
                              ])
                    ],
                    language: "en-gb",
                    lexicalCategory: LexicalCategory(id: "noun", text: "noun"),
                    text: "mock")
                   ],
                   type: "headword",
                   word: "mock")
        ],
        word: "mock")
    
    static let empty = Self(id: "",
                                   metadata: Metadata(operation: "", provider: "", schema: ""),
                                   results: [
                                    Result(id: "",
                                           language: "",
                                           lexicalEntries: [
                                            LexicalEntry(entries: [
                                                Entry(homographNumber: nil,
                                                      pronunciations: [
                                                        Pronunciation(audioFile: "",
                                                                      dialects: [""],
                                                                      phoneticNotation: "",
                                                                      phoneticSpelling: "")
                                                      ])
                                            ],
                                            language: "",
                                            lexicalCategory: LexicalCategory(id: "",
                                                                             text: ""),
                                            text: "")
                                           ],
                                           type: "",
                                           word: "")
                                   ],
                                   word: "")
}
