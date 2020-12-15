//
//  LetterView.swift
//  Alphabet
//
//  Created by Daniel Dähling on 05.12.20.
//

import SwiftUI
import ComposableArchitecture

struct LetterEnvironment {
    var mainQueue : AnySchedulerOf<DispatchQueue>
}

enum LetterAction {
    case letterHasAppeared
    case preferenceDataChanged([LetterPreferenceData])
}

let letterReducer = Reducer<Letter, LetterAction, LetterEnvironment> { state, action, environment in
    switch action {
    case .letterHasAppeared:
        withAnimation(.spring()) {
            state.hasAppeared = true
        }
        return .none
    case let .preferenceDataChanged(data):
        state.bottomPreferenceData = data
        return Effect(value: .letterHasAppeared)
            .receive(on: environment.mainQueue)
            .eraseToEffect()
    }
}

struct LetterView: View {
    
    @ObservedObject var viewStore : ViewStore<Letter, LetterAction>
    let proxy : GeometryProxy
    
    init(store: Store<Letter, LetterAction>, proxy: GeometryProxy) {
        self.viewStore = ViewStore(store)
        self.proxy = proxy
    }
    
    var body: some View {
        Group {
            if viewStore.letter == "space" {
                Image("i")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(0)
            } else {
                Image(viewStore.letter)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }        
        .offset(viewStore.hasAppeared ? .zero : viewStore.state.offset(using: proxy))
        .anchorPreference(
            key: LetterBounds.self,
            value: .bounds,
            transform: { [LetterPreferenceData(id: "\(viewStore.id)", anchor: $0)] }
        )
        .backgroundPreferenceValue(LetterBounds.self, { value in
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        withAnimation(.spring()) {
                            viewStore.send(.preferenceDataChanged(value))
                        }
                    }
            }
        })
        .onChange(of: viewStore.hasAppeared, perform: { print($0) })
    }
}

//struct LetterView_Previews: PreviewProvider {
//    static var previews: some View {
//        LetterView()
//    }
//}
