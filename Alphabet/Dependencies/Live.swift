//
//  Live.swift
//  Alphabet
//
//  Created by Daniel Dähling on 12.12.20.
//

import Foundation
import Combine
import ComposableArchitecture

extension DictionaryRequest {
    public static let live = Self(
        pronunciationRequest: { word, variables, cache, mainQueue in
            if let cachedRequest = cache.value(for: word) {
                return Just(Result.success(cachedRequest))
                    .eraseToEffect()
            }
            
            let word_id = word.lowercased()
            let apiKey = "2493d6db-83a3-46ca-a6d1-7b1b7924822b"
            guard let url = URL(string: "https://www.dictionaryapi.com/api/v3/references/learners/json/\(word_id)?key=\(apiKey)") else { fatalError("Invalid URL") }
            var request = URLRequest(url: url)

            let publisher = URLSession.shared.dataTaskPublisher(for: request)
            return publisher
                .tryMap { data, response -> APIResult in
                    guard let jsonData = try? JSONSerialization.jsonObject(with: data),
                          let json = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted) else {
                        throw APIError.corruptedJSONData
                    }
                    
                    if let httpUrlResponse = response as? HTTPURLResponse,
                       !(200...299).contains(httpUrlResponse.statusCode) {
                        throw APIError.httpURLResponseStatusCode(httpUrlResponse.statusCode)
                    }
                    
                    let decoder = JSONDecoder()
                    do {
                        if let noEntryFound = try? decoder.decode(NoEntryFound.self, from: data) {
                            throw APIError.noEntryFound
                        }
                        let responseElements = try decoder.decode([APIResponseElement].self, from: data)
                        let response = APIResponse(elements: responseElements)
                        return .success(response)
                    } catch let error as DecodingError {
                        switch error {
                        case let .typeMismatch(_, context):
                            fatalError("Failed to decode response due to type mismatch - \(context.debugDescription)")
                        case let .valueNotFound(value, context):
                            fatalError("Failed to decode response due to missing value \(value) - \(context.debugDescription)")
                        case let .keyNotFound(key, context):
                            fatalError("Failed to decode response due to missing key \(key) - \(context.debugDescription)")
                        case .dataCorrupted(_):
                            fatalError("Data is corrupt.")
                        @unknown default:
                            fatalError("An unknown error occurred.")
                        }
                    } 
                }
                .catch { error -> AnyPublisher<APIResult, Never> in
                    guard let apiError = error as? APIError else {
                        return Just(.failure(.unknown("An unknown error occurred.")))
                            .eraseToAnyPublisher()
                    }
                        return Just(.failure(apiError))
                            .eraseToAnyPublisher()
                    
                }
                .flatMap { response -> AnyPublisher<AudioRequestResult, Never> in
                    guard case let .success(response) = response,
                          let firstElement = response.elements.first,
                          let audio = firstElement.hwi?.prs?[0].sound?.audio,
                          let subDirectory = audio.first,
                          let audioURL = URL(string: "https://media.merriam-webster.com/audio/prons/en/us/mp3/\(String(subDirectory))/\(audio).mp3") else {
                        print("Failed initializing url")
                        fatalError()
                    }
                    let mp3RequestPublisher = URLSession.shared.dataTaskPublisher(for: audioURL).share()
                    return mp3RequestPublisher
                        .catch { _ in
                            mp3RequestPublisher
                                .delay(for: 1, scheduler: mainQueue)
                                .eraseToAnyPublisher()
                        }
                        .retry(3)
                        .map { .success($0.data) }
                        .replaceError(with: .failure(.unknown("An unknown error occurred.")))
                        .eraseToAnyPublisher()
                        
                }
                
                .eraseToEffect()
        }
    )
}


//            guard let url = URL(string: "https://od-api.oxforddictionaries.com/api/v2/entries/\(variables.language)/\(word_id)?fields=\(variables.fields)&strictMatch=\(variables.strictMatch)") else { fatalError("Invalid URL") }

//            request.addValue("application/json", forHTTPHeaderField: "Accept")
//            request.addValue(variables.appId, forHTTPHeaderField: "app_id")
//            request.addValue(variables.appKey, forHTTPHeaderField: "app_key")


