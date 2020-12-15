//
//  AlphabetApp.swift
//  Alphabet
//
//  Created by Daniel Dähling on 28.08.20.
//

import SwiftUI
import ComposableArchitecture
import Combine

@main
struct AlphabetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(Store(
                initialState: AppState(orientation: UIDevice.current.orientation),
                reducer: appReducer,
                environment: AppEnvironment(
                    requestDictionaryCheck: DictionaryRequest.live.spellingRequest,
                    uuid: UUID.init,
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
                    orientationDidChange: NotificationCenter.default
                        .publisher(for: UIDevice.orientationDidChangeNotification)
                        .eraseToEffect()
                )
            )
            )
        }
    }
}
