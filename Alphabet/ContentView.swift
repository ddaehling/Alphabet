//
//  ContentView.swift
//  Alphabet
//
//  Created by Daniel Dähling on 28.08.20.
//

import SwiftUI
import Combine
import ComposableArchitecture
import AVFoundation

struct AppState: Equatable {
    let letters = LetterBox.basic
    var letterAnchors : [LetterPreferenceData] = []
    var selectedLetters : IdentifiedArrayOf<Letter> = []
    var removedIndex : Int?
    var orientation : UIDeviceOrientation
    var alert : AlertState<WordViewAction>?

    var wordViewState : WordViewState {
        get { .init(
            topViewLetterAnchors: self.letterAnchors,
            removedIndex: self.removedIndex,
            selectedLetters: self.selectedLetters,
            alert: self.alert
        )
        }
        set { (self.removedIndex, self.selectedLetters, self.alert) = (newValue.removedIndex, newValue.selectedLetters, newValue.alert) }
    }

    struct WordViewState: Equatable {
        let spacing : CGFloat = 10
        
        var topViewLetterAnchors : [LetterPreferenceData]
        var removedIndex : Int?
        var selectedLetters : IdentifiedArrayOf<Letter>
        var alert : AlertState<WordViewAction>?
        var player : AVAudioPlayer? = nil
        var urlVariables = URLVariables()
        
        var currentWord : String {
            selectedLetters.map{$0.letter}.joined()
        }
        
        func letterHeight(using proxy: GeometryProxy) -> CGFloat {
            let totalWidth = selectedLetters.reduce(into: CGFloat(0)) { total, element in
                let elementAnchor = topViewLetterAnchors.filter { $0.id == element.letter }.first!
                let elementWidth = proxy[elementAnchor.anchor].size.width
                return total += elementWidth
            } + CGFloat((selectedLetters.count - 1)) * (spacing * 1)
            let overshoot = max(0, totalWidth + (proxy.size.width / 4) - proxy.size.width)
            let heightFactor = (totalWidth - overshoot) / totalWidth
            
            guard let originalHeightAnchor = topViewLetterAnchors.first?.anchor else { return 0 }
            let originalLetterHeight = proxy[originalHeightAnchor].size.height
            return originalLetterHeight * heightFactor
        }
        
        func aspectRatio(for letter: Letter, using proxy: GeometryProxy) -> CGFloat {
            let elementAnchor = topViewLetterAnchors.filter { $0.id == letter.letter }.first!
            return  proxy[elementAnchor.anchor].size.width / proxy[elementAnchor.anchor].size.height
        }
        
        mutating func removeLetter(_ letter: Letter, isLongPress: Bool) {
            withAnimation(.easeInOut) {
                guard let index = selectedLetters.firstIndex(where:{ $0.id == letter.id }) else { return }
                selectedLetters.remove(at: index)
                if isLongPress {
                    removedIndex = index
                }
            }
        }
    }
}

enum AppAction {
    case letterAnchorsUpdated([LetterPreferenceData])
    case letterTapped(String)
    case onAppear
    case onDisappear
    case orientationDidChange
    case wordViewAction(WordViewAction)
    
}

struct AppEnvironment {
    typealias Notification = NotificationCenter.Publisher.Output
    typealias Failure = NotificationCenter.Publisher.Failure
    
    var requestDictionaryEntry: (String, URLVariables, Cache<String, Data>, AnySchedulerOf<DispatchQueue>) -> Effect<AudioRequestResult, Never>
    var uuid: () -> UUID
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var orientationDidChange: Effect<Notification, Failure>
    var audioPlayer: (Data) throws -> AVAudioPlayer
    var fileManager: FileManager
    var cache : Cache<String, Data>
    
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    wordViewReducer.pullback(
        state: \.wordViewState,
        action: /AppAction.wordViewAction,
        environment: { WordViewEnvironment(
            mainqueue: $0.mainQueue,
            requestDictionaryCheck: $0.requestDictionaryEntry,
            audioPlayer: $0.audioPlayer,
            fileManager: $0.fileManager,
            cache: $0.cache
        )
        }
    ),
    Reducer { state, action, environment in
        
        struct OrientationDidChange: Hashable {}
        
        switch action {
        case let .letterTapped(l):
            guard !state.letterAnchors.isEmpty else { fatalError("Letter anchors not yet set.") }
            let letter = Letter(hasAppeared: false, letter: l, id: environment.uuid(), topPreferenceData: state.letterAnchors.filter { $0.id == l }.first! )
            if let index = state.removedIndex {
                state.selectedLetters.insert(letter, at: index)
                state.removedIndex = nil
            } else {
                state.selectedLetters.append(letter)
            }
            return .none
        case .wordViewAction(_):
            return .none
        case let .letterAnchorsUpdated(anchors):
            state.letterAnchors = anchors
            return .none
        case .onAppear:
            return environment.orientationDidChange
                .receive(on: environment.mainQueue)
                .map { _ in AppAction.orientationDidChange }
                .eraseToEffect()
                .cancellable(id: OrientationDidChange())
        case .onDisappear:
            return .none
        case .orientationDidChange:
            state.orientation = UIDevice.current.orientation
            return .none
        }
    }
)


struct ContentView: View {
    
    @ObservedObject var viewStore : ViewStore<AppState, AppAction>
    private let store: Store<AppState, AppAction>
    
    init(_ store: Store<AppState, AppAction>) {
        viewStore = ViewStore(store)
        self.store = store
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                VStack {
                    ForEach(viewStore.letters) { box in
                        HStack(alignment: .bottom, spacing: 20) {
                            ForEach(box.letters, id: \.self) { letter in
                                Button(action: {
                                    withAnimation(.easeInOut) {
                                        viewStore.send(.letterTapped(letter))
                                    }
                                }, label: {
                                    Image(letter)
                                        .resizable()
                                        .renderingMode(.original)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: sizeForLetter(letter, with: proxy))
                                        .anchorPreference(
                                            key: LetterBounds.self,
                                            value: .bounds,
                                            transform: { [LetterPreferenceData(id: letter, anchor: $0)] }
                                        )
                                })
                            }
                        }
                    }
                }
                .padding([.top, .leading, .trailing], 50)
                
                Spacer()
                
                WordView(store.scope(state: { $0.wordViewState }, action: AppAction.wordViewAction), proxy: proxy)
                    .frame(height: (min(proxy.size.width, proxy.size.height) / 7))
                    .frame(maxWidth: proxy.size.width - proxy.size.width / 7)
                    .padding([.bottom, .leading, .trailing], 50)
            }
            .backgroundPreferenceValue(LetterBounds.self, { value in
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            DispatchQueue.main.async {
                                viewStore.send(.letterAnchorsUpdated(value))
                            }
                        }
                }
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
        .onAppear { viewStore.send(.onAppear) }
        .onDisappear { viewStore.send(.onDisappear) }
    }
    
    func sizeForLetter(_ letter: String, with proxy: GeometryProxy) -> CGFloat {
        return letter == "space" ? min(proxy.size.width, proxy.size.height) / 21 : min(proxy.size.width, proxy.size.height) / 7
    }
    
}

struct LetterPreferenceData: Equatable {
    let id : String
    let anchor : Anchor<CGRect>
}

extension LetterPreferenceData {
    static func ==(lhs: LetterPreferenceData, rhs: LetterPreferenceData) -> Bool {
        return lhs.id == rhs.id
    }
}



struct LetterBounds: PreferenceKey {
    static var defaultValue: [LetterPreferenceData] = []
    
    typealias Value = [LetterPreferenceData]
    
    static func reduce(value: inout [LetterPreferenceData], nextValue: () -> [LetterPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}

struct LetterHeightKey: PreferenceKey {
    static var defaultValue: [CGFloat] = []
    
    typealias Value = [CGFloat]
    
    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value.append(contentsOf: nextValue())
    }
}

struct LetterHeightEnvironmentKey: EnvironmentKey {    
    static var defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var letterHeight: CGFloat {
        get { self[LetterHeightEnvironmentKey.self]}
        set { self[LetterHeightEnvironmentKey.self] = newValue}
    }
}
