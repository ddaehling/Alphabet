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

enum APIError: Error, Equatable {
    case corruptedJSONData
    case httpURLResponseStatusCode(Int)
    case noEntryFound
    case unknown(String)
}

typealias APIResult = Result<APIResponse, APIError>
typealias AudioRequestResult = Result<Data, APIError>

typealias DictionaryRequest = (String, URLVariables) -> AnyPublisher<APIResult, Never>
typealias _PronunciationRequest = (String, URLVariables, Cache<String, Data>, AnySchedulerOf<DispatchQueue>) -> Effect<AudioRequestResult, Never>
typealias PronunciationRequest = (String, URLVariables, Cache<String, Data>, AnySchedulerOf<DispatchQueue>, DictionaryRequest) -> Effect<AudioRequestResult, Never>

struct APIRequest {
    let dictionaryRequest: DictionaryRequest
    let _pronunciationRequest : _PronunciationRequest
    
    public init(
        dictionaryRequest: @escaping DictionaryRequest,
        pronunciationRequest: @escaping PronunciationRequest
    ) {
        self.init(
            dictionaryRequest: dictionaryRequest,
            _pronunciationRequest: { word, variables, cache, mainQueue in
                pronunciationRequest(word, variables, cache, mainQueue, dictionaryRequest)
            }
        )
    }
    
    private init(
        dictionaryRequest: @escaping DictionaryRequest,
        _pronunciationRequest: @escaping _PronunciationRequest
    ) {
        self.dictionaryRequest = dictionaryRequest
        self._pronunciationRequest = _pronunciationRequest
    }
}

