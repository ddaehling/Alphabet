//
//  AlphabetApp.swift
//  Alphabet
//
//  Created by Daniel Dähling on 28.08.20.
//

import SwiftUI
import ComposableArchitecture
import Combine
import AVFoundation

@main
struct AlphabetApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView(Store(
                initialState: AppState(orientation: UIDevice.current.orientation),
                reducer: appReducer,
                environment: AppEnvironment(
                    requestDictionaryEntry: DictionaryRequest.live.pronunciationRequest,
                    uuid: UUID.init,
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
                    orientationDidChange: NotificationCenter.default
                        .publisher(for: UIDevice.orientationDidChangeNotification)
                        .eraseToEffect(),
                    audioPlayer: AVAudioPlayer.init(data:),
                    fileManager: FileManager.default,
                    cache: Cache(entryLifetime: 7 * 24 * 60 * 60, dateProvider: Date.init, maximumEntryCount: 50)
                )
            )
            )
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try! AVAudioSession.sharedInstance().setActive(true)
        return true
    }
}
