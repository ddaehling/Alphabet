//
//  WordView.swift
//  Alphabet
//
//  Created by Daniel Dähling on 05.12.20.
//

import SwiftUI
import ComposableArchitecture
import Combine


enum WordViewAction {
    case letterPressed(Letter, Bool)
    case clearButtonTapped
    case letterAction(id: UUID, action: LetterAction)
    case pronunciationButtonTapped
    case pronunciationResponseReceived(APIResponse)
}

struct WordViewEnvironment {
    var mainqueue : AnySchedulerOf<DispatchQueue>
    var requestDictionaryCheck : (String, URLVariables) -> Effect<APIResponse, Never>
}

let wordViewReducer = Reducer<AppState.WordViewState, WordViewAction, WordViewEnvironment>.combine(
    letterReducer.forEach(
        state: \.selectedLetters,
        action: /WordViewAction.letterAction(id:action:),
        environment: { LetterEnvironment(mainQueue: $0.mainqueue) }
    ),
    Reducer { state, action, environment in
        
        struct RequestID: Hashable {}
        
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
            return environment.requestDictionaryCheck(state.selectedLetters.map{$0.letter}.joined(), state.urlVariables)
                .map{ WordViewAction.pronunciationResponseReceived($0) }
                .cancellable(id: RequestID(), cancelInFlight: true)
                .eraseToEffect()
        case let .pronunciationResponseReceived(response):
            print("Got response!")
            return .none
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
