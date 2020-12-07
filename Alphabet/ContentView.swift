//
//  ContentView.swift
//  Alphabet
//
//  Created by Daniel Dähling on 28.08.20.
//

import SwiftUI
import Combine
import ComposableArchitecture

struct AppState {
    let proxy : GeometryProxy
    let letters = [
        LetterBox(letters: ["a", "b", "c", "d", "e", "f"]),
        LetterBox(letters: ["g", "h", "i", "j", "k", "l", "m"]),
        LetterBox(letters: ["n", "o", "p", "q", "r", "s", "t"]),
        LetterBox(letters: ["u", "v", "w", "x", "y", "z", "space"])
    ]
    var letterAnchors : [LetterPreferenceData] = []
    var selectedLetters : [Letter] = []
    var removedIndex : Int?

    var wordViewState : WordViewState {
        get { .init(
            proxy: self.proxy,
            topViewLetterAnchors: self.letterAnchors,
            removedIndex: self.removedIndex,
            selectedLetters: self.selectedLetters
        )
        }
        set { (self.removedIndex, self.selectedLetters, self.removedIndex, self.selectedLetters) = (newValue.removedIndex, newValue.selectedLetters, newValue.removedIndex, newValue.selectedLetters ) }
    }

    struct WordViewState {
        var proxy : GeometryProxy
        var topViewLetterAnchors : [LetterPreferenceData]
        var removedIndex : Int?
        var selectedLetters : [Letter]
    }
}

extension AppState.WordViewState: Equatable {
    static func ==(lhs: AppState.WordViewState, rhs: AppState.WordViewState) -> Bool {
        return (lhs.removedIndex, lhs.selectedLetters) == (rhs.removedIndex, rhs.selectedLetters)
    }
}

extension AppState: Equatable {
    static func ==(lhs: AppState, rhs: AppState) -> Bool {
        return (lhs.letterAnchors, lhs.removedIndex, lhs.selectedLetters, lhs.wordViewState) == (rhs.letterAnchors, rhs.removedIndex, rhs.selectedLetters, rhs.wordViewState)
    }
}

enum AppAction {
    case letterTapped(String)
    case subViewAction(WordViewAction)
    case letterAnchorsUpdated([LetterPreferenceData])
}

public struct AppEnvironment {
    public var orientationDidChange : AnyPublisher<NSNotification.Name, Never> = Empty<NSNotification.Name, Never>().eraseToAnyPublisher()
    public var requestDictionaryCheck : (String) -> AnyPublisher<URLResponse, Error> = { _ in Empty<URLResponse, Error>().eraseToAnyPublisher() }
    public var requestPronunciation : (String) -> AnyPublisher<URLResponse, Error> = { _ in Empty<URLResponse, Error>().eraseToAnyPublisher() }
    public var uuid : () -> UUID
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    case let .letterTapped(l):
        let letter = Letter(hasAppeared: false, letter: l, id: environment.uuid())
        if let index = state.removedIndex {
            state.selectedLetters.insert(letter, at: index)
            state.removedIndex = nil
        } else {
            state.selectedLetters.append(letter)
        }
        return .none
    case .subViewAction(_):
        return .none
    case let .letterAnchorsUpdated(anchors):
        state.letterAnchors = anchors
        return .none
    }
}


struct ContentView: View {
    
    @ObservedObject var viewStore : ViewStore<AppState, AppAction>
    
    init(_ store: Store<AppState, AppAction>) {
        viewStore = ViewStore(store)
    }
    
    let letters = [
        LetterBox(letters: ["a", "b", "c", "d", "e", "f"]),
        LetterBox(letters: ["g", "h", "i", "j", "k", "l", "m"]),
        LetterBox(letters: ["n", "o", "p", "q", "r", "s", "t"]),
        LetterBox(letters: ["u", "v", "w", "x", "y", "z", "space"])
    ]
    
    @State private var letterAnchors : [LetterPreferenceData] = []
    @State private var selectedLetters : [Letter] = []
    @State private var removedIndex : Int? = nil
    
    private let orientationDidChange = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
    
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
                .padding(.top, 50)
                
                Spacer()
                WordView(proxy: proxy, topViewPreferenceData: letterAnchors, removedIndex: $removedIndex, selectedLetters: $selectedLetters)
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
