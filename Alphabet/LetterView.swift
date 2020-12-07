//
//  LetterView.swift
//  Alphabet
//
//  Created by Daniel Dähling on 05.12.20.
//

import SwiftUI

struct LetterView: View {
    
    @State var letter : Letter
    @State var letterPreferenceData : [LetterPreferenceData] = []
    
    let originalLetterPreferenceData : LetterPreferenceData?
    let proxy : GeometryProxy
    
    var offset : CGSize {
        guard
            let letterAnchor = letterPreferenceData.first?.anchor,
            let originalLetterAnchor = originalLetterPreferenceData?.anchor
        else {
            return .zero
        }
        let difference = proxy.size.width < proxy.size.height ? (proxy.size.width - proxy.size.height) / 2 : 0
        return .init(
            width: proxy[originalLetterAnchor].midX - proxy[letterAnchor].midX,
            height: proxy[originalLetterAnchor].midY - proxy[letterAnchor].midY
        )
    }
    
    var body: some View {
        ZStack {
            if letter.letter == "space" {
                Image("i")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(0)
            } else {
                Image(letter.letter)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .offset(letter.hasAppeared ? .zero : offset)
        .anchorPreference(key: LetterBounds.self, value: .bounds, transform: { [LetterPreferenceData(id: "\(letter.id)", anchor: $0)] })
        .onAppear {
            withAnimation(.spring()) {
                letter.hasAppeared = true
            }
        }
        .backgroundPreferenceValue(LetterBounds.self, { value in
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        letterPreferenceData = value
                    }
                    
            }
        })
    }
}

//struct LetterView_Previews: PreviewProvider {
//    static var previews: some View {
//        LetterView()
//    }
//}
