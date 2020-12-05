//
//  Helpers.swift
//  Alphabet
//
//  Created by Daniel Dähling on 02.09.20.
//

import SwiftUI

public extension View {
    func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") -> some View {
        let string = items.map{String(describing: $0)}.joined(separator: separator)
        print(string, terminator: terminator)
        return self
    }

    func contentFrame(for screenSize: GeometryProxy, with sizeFactor: CGFloat) -> some View {
        frame(width: screenSize.size.width * sizeFactor, height: screenSize.size.height * sizeFactor)
    }

    func debugFrame(with color: Color) -> some View {
        overlay(Color.clear.border(color))
    }
}

