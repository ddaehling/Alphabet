//
//  Model.swift
//  Alphabet
//
//  Created by Daniel Dähling on 05.12.20.
//

import Foundation

struct Letter: Equatable, Identifiable {
    var hasAppeared : Bool
    let letter: String
    let id: UUID
}

struct LetterBox: Equatable, Identifiable {
    let id = UUID()
    let letters: [String]
}
