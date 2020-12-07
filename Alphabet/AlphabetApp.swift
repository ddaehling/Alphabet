//
//  AlphabetApp.swift
//  Alphabet
//
//  Created by Daniel Dähling on 28.08.20.
//

import SwiftUI
import ComposableArchitecture

@main
struct AlphabetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(Store(
                initialState: AppState(),
                reducer: appReducer,
                environment: AppEnvironment(
                    uuid: UUID.init)
            )
            )
        }
    }
}
