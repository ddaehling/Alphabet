//
//  LetterView.swift
//  Alphabet
//
//  Created by Daniel Dähling on 05.12.20.
//

import SwiftUI

struct LetterView: View {
    
    @Environment(\.letterHeight) var letterHeight
    
    @State var letter : Letter
    @State var letterPreferenceData : [LetterPreferenceData] = []
    
    let originalLetterPreferenceData : LetterPreferenceData?
    let proxy : GeometryProxy
    
    var offset : CGSize {
        guard
            let letterAnchor = letterPreferenceData.first?.anchor,
            let originalLetterPreferenceData = originalLetterPreferenceData
        else {
            return .zero
        }
        let difference = proxy.size.width < proxy.size.height ? (proxy.size.width - proxy.size.height) / 2 : 0
        return .init(
            width: proxy[originalLetterPreferenceData.anchor].midX - proxy[letterAnchor].midX,
            height: proxy[originalLetterPreferenceData.anchor].midY - proxy[letterAnchor].midY
        )
    }
    
    var height : CGFloat {
        guard let anchor = originalLetterPreferenceData?.anchor else { return 0 }
        return letter.hasAppeared ? letterHeight : proxy[anchor].height
    }

    var body: some View {
        ZStack {
            if letter.letter == "space" {
                Color.clear
                    .frame(width: min(proxy.size.width, proxy.size.height) / 14)
            } else {
                ZStack {
                    Image(letter.letter)
                        .resizable()
                        .getHeight()
                        .aspectRatio(contentMode: .fit)
                        .offset(letter.hasAppeared ? .zero : offset)
                        .anchorPreference(key: LetterBounds.self, value: .bounds, transform: { [LetterPreferenceData(id: "\(letter.id)", anchor: $0)] })
                        .onAppear {
                            withAnimation(.easeInOut) {
                                letter.hasAppeared = true
                            }
                        }
                }
            }
        }
        .frame(height: height)
        .backgroundPreferenceValue(LetterBounds.self, { value in
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        letterPreferenceData = value
                    }
                    
            }
        })
        .debugFrame(with: .black)
        
    }
}

//struct LetterView_Previews: PreviewProvider {
//    static var previews: some View {
//        LetterView()
//    }
//}
