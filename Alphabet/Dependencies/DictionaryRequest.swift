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
        appId : String = "<my_app_id>",
        appKey : String = "<my_app_key>",
        language : String = "eng-gb",
        fields : String = "pronunciation",
        strictMatch : String = "false") {
        self.appId = appId
        self.appKey = appKey
        self.language = language
        self.fields = fields
        self.strictMatch = strictMatch
    }
}

public struct DictionaryRequest {
    public var spellingRequest : (String, URLVariables) -> Effect<APIResponse, Never>
    
    public init(spellingRequest: @escaping (String, URLVariables) -> Effect<APIResponse, Never>,
                components: URLVariables = URLVariables()
    ) { self.spellingRequest = spellingRequest }
}

public struct APIError: Decodable, Error {
    public let statusCode: Int
}
