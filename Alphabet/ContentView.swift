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
    var mainViewState : MainViewState
    var subViewState : SubViewState
}

struct MainViewState {
    let letters = [
        LetterBox(letters: ["a", "b", "c", "d", "e", "f"]),
        LetterBox(letters: ["g", "h", "i", "j", "k", "l", "m"]),
        LetterBox(letters: ["n", "o", "p", "q", "r", "s", "t"]),
        LetterBox(letters: ["u", "v", "w", "x", "y", "z", "space"])
    ]
    var letterAnchors : [LetterPreferenceData] = []
    var selectedLetters : [Letter] = []
    var removedIndex : Int?
}

public struct MainViewEnvironment {
    public var orientationDidChange : AnyPublisher<NSNotification.Name, Never>
    public var checkDictionary : (String) -> AnyPublisher<URLResponse, Error>.Failure
    public var uuid : () -> UUID
}

struct SubViewState {
    
}

struct ContentView: View {
    
    let letters = [
        LetterBox(letters: ["a", "b", "c", "d", "e", "f"]),
        LetterBox(letters: ["g", "h", "i", "j", "k", "l", "m"]),
        LetterBox(letters: ["n", "o", "p", "q", "r", "s", "t"]),
        LetterBox(letters: ["u", "v", "w", "x", "y", "z", "space"])
    ]
    
    @State private var deviceOrientation : UIDeviceOrientation?
    @State private var letterAnchors : [LetterPreferenceData] = []
    @State private var selectedLetters : [Letter] = []
    @State private var removedIndex : Int? = nil
    
    private let orientationDidChange = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
//        .makeConnectable()
//        .autoconnect()
    
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                VStack {
                    ForEach(letters) { box in
                        HStack(alignment: .bottom, spacing: 20) {
                            ForEach(box.letters, id: \.self) { letter in
                                Button(action: {
                                    withAnimation(.easeInOut) {
                                        let letter = Letter(hasAppeared: false, letter: letter, id: UUID())
                                        if let index = removedIndex  {
                                            selectedLetters.insert(letter, at: index)
                                            removedIndex = nil
                                        } else {
                                            selectedLetters.append(letter)
                                        }
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
                    .padding([.leading, .trailing], 50)
                
            }
            .backgroundPreferenceValue(LetterBounds.self, { value in
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            DispatchQueue.main.async {
                                letterAnchors = value
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

struct LetterPreferenceData {
    let id : String
    let anchor : Anchor<CGRect>
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
