//
//  RootClass.swift
//  Model Generated using http://www.jsoncafe.com/ 
//  Created on December 11, 2020


import Foundation

struct APIResponseElement: Codable {
    let shortdef: [String]?
    let hwi: Hwi?
    let meta: Meta?
    let dros: [Dro]?
    let fl: String?
    let hom: Int?
    let def: [APIResponseDef]?
    let lbs: [String]?
    let gram: String?
    let ins: [In]?
    let vrs: [VR]?
}

// MARK: - APIResponseDef
struct APIResponseDef: Codable {
    let sseq: [[[TentacledSseq]]]?
    let sls: [String]?
}

enum TentacledSseq: Codable {
    case enumeration(SseqEnum)
    case purpleSseq(PurpleSseq)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(SseqEnum.self) {
            self = .enumeration(x)
            return
        }
        if let x = try? container.decode(PurpleSseq.self) {
            self = .purpleSseq(x)
            return
        }
        throw DecodingError.typeMismatch(TentacledSseq.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for TentacledSseq"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enumeration(let x):
            try container.encode(x)
        case .purpleSseq(let x):
            try container.encode(x)
        }
    }
}

// MARK: - PurpleSseq
struct PurpleSseq: Codable {
    let sn: String?
    let dt: [[PurpleDt]]?
    let sls: [String]?
}

enum PurpleDt: Codable {
    case string(String)
    case unionArray([FluffyDt])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([FluffyDt].self) {
            self = .unionArray(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(PurpleDt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for PurpleDt"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        }
    }
}

enum FluffyDt: Codable {
    case dtClass(DtClass)
    case unionArray([TentacledDt])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([TentacledDt].self) {
            self = .unionArray(x)
            return
        }
        if let x = try? container.decode(DtClass.self) {
            self = .dtClass(x)
            return
        }
        throw DecodingError.typeMismatch(FluffyDt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for FluffyDt"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .dtClass(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        }
    }
}

enum TentacledDt: Codable {
    case string(String)
    case unionArray([StickyDt])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([StickyDt].self) {
            self = .unionArray(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(TentacledDt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for TentacledDt"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        }
    }
}

enum StickyDt: Codable {
    case dtClass(DtClass)
    case dtClassArray([DtClass])
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([DtClass].self) {
            self = .dtClassArray(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        if let x = try? container.decode(DtClass.self) {
            self = .dtClass(x)
            return
        }
        throw DecodingError.typeMismatch(StickyDt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for StickyDt"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .dtClass(let x):
            try container.encode(x)
        case .dtClassArray(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        }
    }
}

// MARK: - DtClass
struct DtClass: Codable {
    let t: String?
}

enum SseqEnum: String, Codable {
    case sense = "sense"
}

// MARK: - Dro
struct Dro: Codable {
    let drp: String?
    let def: [DroDef]?
    let vrs: [VR]?
}

// MARK: - DroDef
struct DroDef: Codable {
    let sls: [String]?
    let sseq: [[[StickySseq]]]?
}

enum StickySseq: Codable {
    case enumeration(SseqEnum)
    case fluffySseq(FluffySseq)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(SseqEnum.self) {
            self = .enumeration(x)
            return
        }
        if let x = try? container.decode(FluffySseq.self) {
            self = .fluffySseq(x)
            return
        }
        throw DecodingError.typeMismatch(StickySseq.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for StickySseq"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .enumeration(let x):
            try container.encode(x)
        case .fluffySseq(let x):
            try container.encode(x)
        }
    }
}

// MARK: - FluffySseq
struct FluffySseq: Codable {
    let sn: String?
    let dt: [[IndigoDt]]?
    let sls: [String]?
}

enum IndigoDt: Codable {
    case string(String)
    case unionArray([IndecentDt])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([IndecentDt].self) {
            self = .unionArray(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(IndigoDt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for IndigoDt"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let x):
            try container.encode(x)
        case .unionArray(let x):
            try container.encode(x)
        }
    }
}

enum IndecentDt: Codable {
    case dtClass(DtClass)
    case unionArrayArray([[HilariousDt]])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([[HilariousDt]].self) {
            self = .unionArrayArray(x)
            return
        }
        if let x = try? container.decode(DtClass.self) {
            self = .dtClass(x)
            return
        }
        throw DecodingError.typeMismatch(IndecentDt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for IndecentDt"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .dtClass(let x):
            try container.encode(x)
        case .unionArrayArray(let x):
            try container.encode(x)
        }
    }
}

enum HilariousDt: Codable {
    case dtClassArray([DtClass])
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode([DtClass].self) {
            self = .dtClassArray(x)
            return
        }
        if let x = try? container.decode(String.self) {
            self = .string(x)
            return
        }
        throw DecodingError.typeMismatch(HilariousDt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for HilariousDt"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .dtClassArray(let x):
            try container.encode(x)
        case .string(let x):
            try container.encode(x)
        }
    }
}

// MARK: - VR
struct VR: Codable {
    let va, vl: String?
}

// MARK: - Hwi
struct Hwi: Codable {
    let prs: [PR]?
    let hw: String?
    let altprs: [Altpr]?
}

// MARK: - Altpr
struct Altpr: Codable {
    let ipa, pun: String?
}

// MARK: - PR
struct PR: Codable {
    let ipa, pun: String?
    let sound: Sound?
}

// MARK: - Sound
struct Sound: Codable {
    let audio: String?
}

// MARK: - In
struct In: Codable {
    let ifc, il, inIf: String?

    enum CodingKeys: String, CodingKey {
        case ifc, il
        case inIf = "if"
    }
}

// MARK: - Meta
struct Meta: Codable {
    let target: Target?
    let stems: [String]?
    let offensive: Bool?
    let id: String?
    let src: Src?
    let section: Section?
    let uuid: String?
    let appShortdef: AppShortdef?
    let highlight: String?

    enum CodingKeys: String, CodingKey {
        case target, stems, offensive, id, src, section, uuid
        case appShortdef = "app-shortdef"
        case highlight
    }
}

// MARK: - AppShortdef
struct AppShortdef: Codable {
    let def: [String]?
    let hw, fl: String?
}

enum Section: String, Codable {
    case alpha = "alpha"
}

enum Src: String, Codable {
    case learners = "learners"
}

// MARK: - Target
struct Target: Codable {
    let tuuid, tsrc: String?
}

struct APIResponse: Codable {
    let elements : [APIResponseElement]
    
//    public init(from decoder: Decoder) throws {
//        <#code#>
//    }
//    
//    public func encode(to encoder: Encoder) throws {
//        <#code#>
//    }
}

extension APIResponse {
    static let empty : Self = .init(elements: [])
}

//// MARK: - ApiResponse
//
//public struct APIResponse: Codable {
//    public let statusCode: Int
//    public let text: String
//    public let response: Response
//
//    enum CodingKeys: String, CodingKey {
//        case statusCode = "status_code"
//        case text
//        case response
//    }
//}
//
//public struct Response: Codable {
//    public let id: String
//    public let metadata: Metadata
//    public let results: [Result]
//    public let word: String
//}
//
//// MARK: - Metadata
//public struct Metadata: Codable {
//    public let operation, provider, schema: String
//}
//
//// MARK: - Result
//public struct Result: Codable {
//    public let id, language: String
//    public let lexicalEntries: [LexicalEntry]
//    public let type, word: String
//}
//
//// MARK: - LexicalEntry
//public struct LexicalEntry: Codable {
//    public let entries: [Entry]
//    public let language: String
//    public let lexicalCategory: LexicalCategory
//    public let text: String
//}
//
//// MARK: - Entry
//public struct Entry: Codable {
//    public let homographNumber: String?
//    public let pronunciations: [Pronunciation]
//}
//
//// MARK: - Pronunciation
//public struct Pronunciation: Codable {
//    public let audioFile: String
//    public let dialects: [String]
//    public let phoneticNotation, phoneticSpelling: String
//}
//
//// MARK: - LexicalCategory
//public struct LexicalCategory: Codable {
//    public let id, text: String
//}
//
//public extension Response {
//    static let mock = Self(
//        id: "mock",
//        metadata: Metadata(operation: "retrieve",
//                           provider: "Oxford University Press",
//                           schema: "RetrieveEntry"),
//        results: [
//            Result(id: "mock",
//                   language: "en-gb",
//                   lexicalEntries: [
//                    LexicalEntry(entries: [
//                        Entry(homographNumber: nil,
//                              pronunciations: [
//                                Pronunciation(
//                                    audioFile: "https://audio.oxforddictionaries.com/en/mp3/mock_gb_1.mp3",
//                                    dialects: ["British English"],
//                                    phoneticNotation: "IPA",
//                                    phoneticSpelling: "mɒk")
//                              ])
//                    ],
//                    language: "en-gb",
//                    lexicalCategory: LexicalCategory(id: "verb", text: "Verb"),
//                    text: "mock"),
//                    LexicalEntry(entries: [
//                        Entry(homographNumber: nil,
//                              pronunciations: [
//                                Pronunciation(audioFile: "https://audio.oxforddictionaries.com/en/mp3/mock_gb_1.mp3",
//                                              dialects: ["British English"],
//                                              phoneticNotation: "IPA",
//                                              phoneticSpelling: "mɒk")
//                              ])
//                    ],
//                    language: "en-gb",
//                    lexicalCategory: LexicalCategory(id: "adjective", text: "Adjective"),
//                    text: "mock"),
//                    LexicalEntry(entries: [
//                        Entry(homographNumber: nil,
//                              pronunciations: [
//                                Pronunciation(audioFile: "https://audio.oxforddictionaries.com/en/mp3/mock_gb_1.mp3",
//                                              dialects: ["British English"],
//                                              phoneticNotation: "IPA",
//                                              phoneticSpelling: "mɒk")
//                              ])
//                    ],
//                    language: "en-gb",
//                    lexicalCategory: LexicalCategory(id: "noun", text: "noun"),
//                    text: "mock")
//                   ],
//                   type: "headword",
//                   word: "mock")
//        ],
//        word: "mock")
//
//    static let empty = Self(
//        id: "",
//        metadata: Metadata(operation: "", provider: "", schema: ""),
//        results: [
//            Result(id: "",
//                   language: "",
//                   lexicalEntries: [
//                    LexicalEntry(entries: [
//                        Entry(homographNumber: nil,
//                              pronunciations: [
//                                Pronunciation(audioFile: "",
//                                              dialects: [""],
//                                              phoneticNotation: "",
//                                              phoneticSpelling: "")
//                              ])
//                    ],
//                    language: "",
//                    lexicalCategory: LexicalCategory(id: "",
//                                                     text: ""),
//                    text: "")
//                   ],
//                   type: "",
//                   word: "")
//        ],
//        word: "")
//}
