//
//  WordView.swift
//  Alphabet
//
//  Created by Daniel Dähling on 05.12.20.
//

import SwiftUI
import ComposableArchitecture
import Combine
import AVFoundation

enum WordViewAction {
    case letterPressed(Letter, Bool)
    case clearButtonTapped
    case letterAction(id: UUID, action: LetterAction)
    case pronunciationButtonTapped
    case pronunciationResponseReceived(Data)
    case playerItemStatusChanged(AVPlayerItem.Status)
}

struct WordViewEnvironment {
    var mainqueue : AnySchedulerOf<DispatchQueue>
    var requestDictionaryCheck : (String, URLVariables, Cache<String, Data>) -> Effect<Data, Never>
    var audioPlayer: (Data) throws -> AVAudioPlayer
    var fileManager: FileManager
    var cache : Cache<String, Data>
}

let wordViewReducer = Reducer<AppState.WordViewState, WordViewAction, WordViewEnvironment>.combine(
    letterReducer.forEach(
        state: \.selectedLetters,
        action: /WordViewAction.letterAction(id:action:),
        environment: { LetterEnvironment(mainQueue: $0.mainqueue) }
    ),
    Reducer { state, action, environment in
        
        struct RequestID: Hashable {}
        struct ItemStatusID: Hashable {}
        var player : AVPlayer? = nil
        
        switch action {
        case let .letterPressed(letter, isLongPressed):
                state.removeLetter(letter, isLongPress: isLongPressed)
            return .none
        case .clearButtonTapped:
            state.selectedLetters.removeAll()
            return .none
        case .letterAction:
            return .none
        case .pronunciationButtonTapped:
            return environment.requestDictionaryCheck(state.selectedLetters.map{$0.letter}.joined(), state.urlVariables, environment.cache)
                .map{ WordViewAction.pronunciationResponseReceived($0) }
                .cancellable(id: RequestID(), cancelInFlight: true)
                .receive(on: environment.mainqueue)
                .eraseToEffect()
        case let .pronunciationResponseReceived(mp3Data):
            environment.cache.insertValue(mp3Data, for: state.selectedLetters.map{$0.letter}.joined())
            
            do {
                state.player = try environment.audioPlayer(mp3Data)
                state.player!.prepareToPlay()
                print("Player initialized with data.")
            } catch let error {
                print(error.localizedDescription)
                return .none
            }
            
            state.player!.play()
            return .none
//            guard let firstElement = response.elements.first,
//                  let audio = firstElement.hwi.prs?[0].sound.audio,
//                  let subDirectory = audio.first,
//                  let audioURL = URL(string: "https://media.merriam-webster.com/audio/prons/en/us/mp3/\(String(subDirectory))/\(audio).mp3") else {
//                print("Failed initializing url")
//                return .none
//            }
//            let asset = AVAsset(url: audioURL)
//            state.currentPlayerItem = AVPlayerItem(asset: asset)
//            state.player = environment.audioPlayer(AVPlayerItem(asset: asset))
//            switch state.player!.status {
//            case .unknown:
//                print("Unknown player status")
//            case .readyToPlay:
//                print("Ready to play player status")
//            case .failed:
//                print("Failed player status")
//            @unknown default:
//                fatalError()
//            }
//            return state.player!.currentItem!.publisher(for: \.status)
//                .receive(on: environment.mainqueue)
//                .map { WordViewAction.playerItemStatusChanged($0) }
//                .eraseToEffect()
//                .cancellable(id: ItemStatusID())
//
            
//
//            let x = state.player!.currentItem?.publisher(for: \.status).eraseToAnyPublisher()
//
//
//            return .none
        case let .playerItemStatusChanged(status):
            switch status {
            case .unknown:
                print("Status unknown")
                return .none
            case .readyToPlay:
                print("Ready to play")

                return .none
            case .failed:
                print("Failed")
                return .none
            @unknown default:
                return .none
            }
        }
    }
)

struct WordView: View {
    
    @ObservedObject var viewStore : ViewStore<AppState.WordViewState, WordViewAction>
    let store : Store<AppState.WordViewState, WordViewAction>
    let proxy: GeometryProxy
    
    init(_ store: Store<AppState.WordViewState, WordViewAction>, proxy: GeometryProxy) {
        viewStore = ViewStore(store)
        self.store = store
        self.proxy = proxy
    }
    
    var body: some View {
        HStack(spacing: viewStore.spacing) {
            if !viewStore.selectedLetters.isEmpty {
                VStack(alignment: .center, spacing: 10) {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            viewStore.send(.clearButtonTapped)
                        }
                    }, label: {
                        Image(systemName: "arrow.counterclockwise")
                            .renderingMode(.original)
                    })
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "checkmark")
                            .renderingMode(.original)
                    })
                    Button(action: {
                        viewStore.send(.pronunciationButtonTapped)
                    }, label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .renderingMode(.original)
                    })
                }
//                .padding([.top, .bottom], 25)
//                .padding([.leading, .trailing], 10)
//                .background(Image("button").resizable()
//                                .background(Image("buttonbackground")
//                                                .resizable()
//                                                .offset(x: 10, y: 10)
//                                )
//                )
                .padding([.top, .bottom], 20)
                .padding([.trailing], 40)
                .transition(.opacity)
                .font(.system(.title))
            }
            ForEachStore(self.store.scope(state: { $0.selectedLetters }, action: WordViewAction.letterAction(id:action:)), content: { childStore in
                WithViewStore(childStore) { letter in
                    LetterView(store: childStore, proxy: proxy)
                        .frame(
                            width: viewStore.state.letterHeight(using: proxy) * viewStore.state.aspectRatio(for: letter.state, using: proxy),
                            height: viewStore.state.letterHeight(using: proxy))
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                viewStore.send(.letterPressed(letter.state, false))
                            }
                            
                        }
                        .onLongPressGesture {
                            withAnimation(.easeInOut) {
                                viewStore.send(.letterPressed(letter.state, true))
                            }
                            
                        }
                        .transition(AnyTransition.identity)
                }
                            
                
            })
        }
    }
}

//
//struct WordView_Previews: PreviewProvider {
//    static var previews: some View {
//        WordView(proxy: <#GeometryProxy#>, topViewPreferenceData: <#[LetterPreferenceData]#>, removedIndex: <#Binding<Int?>#>, selectedLetters: <#Binding<[Letter]>#>)
//    }
//}
