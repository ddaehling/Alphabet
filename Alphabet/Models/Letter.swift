//
//  Model.swift
//  Alphabet
//
//  Created by Daniel Dähling on 05.12.20.
//

import SwiftUI
import ComposableArchitecture

struct Letter: Equatable, Identifiable {
    var hasAppeared : Bool
    let letter: String
    let id: UUID
    var topPreferenceData : LetterPreferenceData?
    var bottomPreferenceData : [LetterPreferenceData] = []
    
    func offset(using proxy: GeometryProxy) -> CGSize {
        guard
            let bottomAnchor = bottomPreferenceData.first?.anchor,
            let topAnchor = topPreferenceData?.anchor
        else {
            print("Failed")
            return .zero
        }
//        let difference = proxy.size.width < proxy.size.height ? (proxy.size.width - proxy.size.height) / 2 : 0
        let offset = CGSize(
            width: proxy[bottomAnchor].midX - proxy[topAnchor].midX,
            height: proxy[bottomAnchor].midY - proxy[topAnchor].midY
        )
        print(offset)
        return offset
    }
    
}

struct LetterBox: Equatable, Identifiable {
    let id = UUID()
    let letters: [String]
    
    static let basic : [LetterBox] = [
        LetterBox(letters: ["a", "b", "c", "d", "e", "f"]),
        LetterBox(letters: ["g", "h", "i", "j", "k", "l", "m"]),
        LetterBox(letters: ["n", "o", "p", "q", "r", "s", "t"]),
        LetterBox(letters: ["u", "v", "w", "x", "y", "z", "space"])
    ]
}
