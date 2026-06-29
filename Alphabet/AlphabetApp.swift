//
//  AlphabetApp.swift
//  Alphabet
//

import SwiftUI
import AVFoundation

@main
struct AlphabetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var model: AppModel
    @State private var themeStore: ThemeStore

    init() {
        let store = ThemeStore()
        let model = AppModel(speech: SpeechEngine(), words: WordList.load())

        // Launch-env seeding for deterministic screenshots / UI tests.
        // Pass via `SIMCTL_CHILD_UITEST_*` to xcrun simctl launch. No effect otherwise.
        let env = ProcessInfo.processInfo.environment
        if let raw = env["UITEST_THEME"], let id = ThemeID(rawValue: raw) { store.id = id }
        if let raw = env["UITEST_LANG"], let lang = AppLanguage(rawValue: raw) {
            store.language = lang
            model.language = lang
            model.words = WordList.load(language: lang)
        }
        if env["UITEST_SOUNDTAP"] == "1" { store.soundOnTap = true; model.soundOnTap = true }
        if env["UITEST_MODE"] == "challenge" { model.setMode(.challenge) }
        if let word = env["UITEST_WORD"] { word.forEach { model.tapLetter(String($0)) } }
        if env["UITEST_PICKER"] == "1" { model.showThemePicker = true }

        _model = State(initialValue: model)
        _themeStore = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model, themeStore: themeStore)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        return true
    }
}
