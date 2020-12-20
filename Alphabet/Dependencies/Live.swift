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
        pronunciationRequest: { word, variables, cache in
            print(word)
            let word_id = word.lowercased()
            let apiKey = "2493d6db-83a3-46ca-a6d1-7b1b7924822b"
            guard let url = URL(string: "https://www.dictionaryapi.com/api/v3/references/learners/json/\(word_id)?key=\(apiKey)") else { fatalError("Invalid URL") }
            var request = URLRequest(url: url)

            let publisher = URLSession.shared.dataTaskPublisher(for: request)
            return publisher
                .tryMap { data, response in
                    guard let jsonData = try? JSONSerialization.jsonObject(with: data),
                          let json = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted) else {
                        return APIResponse.empty
                    }
                    let decoder = JSONDecoder()
                    
                    guard let httpUrlResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpUrlResponse.statusCode) else {
                        let apiError = try decoder.decode(APIError.self, from: data)
                        throw apiError
                    }
                    
                    do {
                        let responseElements = try decoder.decode([APIResponseElement].self, from: data)
                        let response = APIResponse(elements: responseElements)
                        return response
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
                .tryCatch { error -> AnyPublisher<APIResponse, Error> in
                    guard let apiError = error as? APIError else {
                        throw error
                    }
                    // TODO: Handle
                    return Just(APIResponse.empty)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                .replaceError(with: APIResponse.empty)
                .flatMap { response -> AnyPublisher<Data, Never> in
                    guard let firstElement = response.elements.first,
                          let audio = firstElement.hwi?.prs?[0].sound?.audio,
                          let subDirectory = audio.first,
                          let audioURL = URL(string: "https://media.merriam-webster.com/audio/prons/en/us/mp3/\(String(subDirectory))/\(audio).mp3") else {
                        print("Failed initializing url")
                        fatalError()
                    }
                    return URLSession.shared.dataTaskPublisher(for: audioURL)
                        .map { $0.data }
                        .replaceError(with: Data())
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
