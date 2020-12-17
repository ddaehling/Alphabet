//
//  DictionaryRequest.swift
//  Alphabet
//
//  Created by Daniel Dähling on 10.12.20.
//

import Foundation
import Combine
import ComposableArchitecture

public struct URLVariables: Equatable {
    public let appId : String
    public let appKey : String
    public let language : String
    public let fields : String
    public let strictMatch : String
    
    public init(
        appId : String = "<9fc38dd6>",
        appKey : String = "<5d8333e006c48bf3118e2c710dbe72bf>",
        language : String = "eng-gb",
        fields : String = "pronunciations",
        strictMatch : String = "false") {
        self.appId = appId
        self.appKey = appKey
        self.language = language
        self.fields = fields
        self.strictMatch = strictMatch
    }
}

public struct DictionaryRequest {
    public var spellingRequest : (String, URLVariables) -> Effect<Response, Never>
    
    public init(spellingRequest: @escaping (String, URLVariables) -> Effect<Response, Never>,
                components: URLVariables = URLVariables()
    ) { self.spellingRequest = spellingRequest }
}

public struct APIError: Codable, Error {
    public let error: String
}
