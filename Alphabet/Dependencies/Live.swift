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
        spellingRequest: { word, variables in
            let word_id = word.lowercased()
            guard let url = URL(string: "https://od-api.oxforddictionaries.com/api/v2/entries/\(variables.language)/\(word_id)?fields=\(variables.fields)&strictMatch=\(variables.strictMatch)") else { fatalError("Invalid URL")}
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue(variables.appId, forHTTPHeaderField: "app_id")
            request.addValue(variables.appKey, forHTTPHeaderField: "app_key")
            let publisher = URLSession.shared.dataTaskPublisher(for: request)
            return publisher
                .tryMap { data, response in
                    if (!JSONSerialization.isValidJSONObject(data)) {
                        print((response as! HTTPURLResponse).statusCode)
                        print("Is not a valid json object")
                        return Response.empty
                    }
                    guard let jsonData = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? Data else { return Response.empty }
//                          let jsonString = String(data: jsonData, encoding: .utf8)
                    
                    print(jsonData)
//                    print(jsonString)
                    
                    let decoder = JSONDecoder()
                    guard let httpUrlResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpUrlResponse.statusCode) else {
                        let apiError = try decoder.decode(APIError.self, from: data)
                        throw apiError
                    }
                    
                    let response = try decoder.decode(APIResponse.self, from: data)
                    return response.response
                }
                .tryCatch { error -> AnyPublisher<Response, Error> in
                    guard let apiError = error as? APIError else {
                        throw error
                    }
                    print(apiError.error)
                    
                    // TODO: Handle
                    return Just(Response.empty)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                .replaceError(with: Response.mock)
                .eraseToEffect()
        }
    )
}
