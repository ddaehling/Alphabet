//
//  DictionaryRequest.swift
//  Alphabet
//
//  Created by Daniel Dähling on 10.12.20.
//

import Foundation
import Combine
import ComposableArchitecture

struct URLVariables: Equatable {
    let appId : String
    let appKey : String
    let language : String
    let fields : String
    let strictMatch : String
    
   init(
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

enum APIError: Error {
    
}

typealias Result = Result<Data, APIError>

struct DictionaryRequest {
    var pronunciationRequest : (String, URLVariables, Cache<String, Data>) -> Effect<Data, Never>
    
    init(pronunciationRequest: @escaping (String, URLVariables, Cache<String, Data>) -> Effect<Data, Never>,
                components: URLVariables = URLVariables()
    ) { self.pronunciationRequest = pronunciationRequest }
}

struct APIError: Codable, Error {
    let error: String
}
