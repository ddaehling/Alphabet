//
//  Preferences.swift
//  Alphabet
//
//  Created by Daniel Dähling on 11.09.20.
//
//
import SwiftUI
struct AverageHeightPropagator: ViewModifier {
    
    @State var averageHeight : CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .onPreferenceChange(LetterHeightKey.self, perform: { value in
                DispatchQueue.main.async {
                    let allHeights = value.reduce(0, +)
                    averageHeight = allHeights / CGFloat(value.count)
                    print(averageHeight)
                }
                
            })
            .environment(\.letterHeight, averageHeight)
    }
}

struct HeightReader: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .overlay(GeometryReader { proxy in
                Color.clear
                    .preference(key: LetterHeightKey.self, value: [proxy.size.height])
            })
    }
    
}

extension View {
    
    func equalizeHeight() -> some View {
        self.modifier(AverageHeightPropagator())
    }
    
    func getHeight() -> some View {
        self.modifier(HeightReader())
    }
}

//import SwiftUI
//
//struct PropagatedWidthEnvironmentKey: EnvironmentKey {
//    static var defaultValue: [Int: CGFloat] { [:] }
//}
//
//struct PropagatedHeightEnvironmentKey: EnvironmentKey {
//    static var defaultValue: [Int: CGFloat] { [:] }
//}
//
//struct PropagatedWidthPreferenceKey: PreferenceKey {
//    static var defaultValue: [Int: CGFloat] = [:]
//
//    static func reduce(value: inout [Int : CGFloat], nextValue: () -> [Int : CGFloat]) {
//        guard let next = nextValue().first else { return }
//        let key = next.key
//        if next.value > value[key] ?? 0 { value[key] = next.value }
//    }
//}
//
//struct PropagatedHeightPreferenceKey: PreferenceKey {
//    static var defaultValue: [Int: CGFloat] = [:]
//
//    static func reduce(value: inout [Int : CGFloat], nextValue: () -> [Int : CGFloat]) {
//        guard let next = nextValue().first else { return }
//        let key = next.key
//        if next.value > value[key] ?? 0 { value[key] = next.value }
//    }
//}
//
//extension EnvironmentValues {
//    var propagatedWidth: [Int: CGFloat] {
//        get { self[PropagatedWidthEnvironmentKey.self] }
//        set { self[PropagatedWidthEnvironmentKey.self] = newValue }
//    }
//
//    var propagatedHeight: [Int: CGFloat] {
//        get { self[PropagatedHeightEnvironmentKey.self] }
//        set { self[PropagatedHeightEnvironmentKey.self] = newValue }
//    }
//}
//
//struct PropagatedWidthProvider: ViewModifier {
//    @Environment(\.propagatedWidth) var propagatedWidth
//    private let index: Int
//    private let alignment: Alignment
//
//    init(_ index: Int = 0,  alignment: Alignment = .trailing) {
//        self.index = index
//        self.alignment = alignment
//    }
//
//    func body(content: Content) -> some View {
//        content
//            .frame(width: propagatedWidth[index], alignment: alignment)
//            .overlay(
//                GeometryReader { geometry in
//                    Color.clear
//                        .preference(key: PropagatedWidthPreferenceKey.self, value: geometry.size.width > 0 ? [self.index: geometry.size.width] : [:])
//                }
//            )
//    }
//}
//
//struct PropagatedHeightProvider: ViewModifier {
//    @Environment(\.propagatedHeight) var propagatedHeight
//    private let index: Int
//    private let alignment: Alignment
//
//    init(_ index: Int = 0,  alignment: Alignment = .center) {
//        self.index = index
//        self.alignment = alignment
//    }
//
//    func body(content: Content) -> some View {
//        content
//            .frame(height: propagatedHeight[index], alignment: alignment)
//            .overlay(
//                GeometryReader { geometry in
//                    Color.clear
//                        .preference(key: PropagatedHeightPreferenceKey.self, value: geometry.size.height > 0 ? [self.index: geometry.size.height] : [:])
//                }
//            )
//    }
//}
//
//struct SizePropagator: ViewModifier {
//    @State var propagatedWidth: [Int: CGFloat] = [:]
//    @State var propagatedHeight: [Int: CGFloat] = [:]
//
//    func body(content: Content) -> some View {
//        content
//            .environment(\.propagatedWidth, propagatedWidth)
//            .environment(\.propagatedHeight, propagatedHeight)
//            .onPreferenceChange(PropagatedWidthPreferenceKey.self) { width in
//                DispatchQueue.main.async {
//                    self.propagatedWidth = width
//                }
//            }
//            .onPreferenceChange(PropagatedHeightPreferenceKey.self) { (height) in
//                DispatchQueue.main.async {
//                    self.propagatedHeight = height
//                }
//            }
//    }
//}
//
//extension View {
//    func equalizeWidth(_ index: Int = 0, alignment: Alignment = .trailing) -> some View {
//        self.modifier(PropagatedWidthProvider(index, alignment: alignment))
//    }
//
//    func equalizeHeight(_ index: Int = 0, alignment: Alignment = .center) -> some View {
//        self.modifier(PropagatedHeightProvider(index, alignment: alignment))
//    }
//
//    func sizeEqualizer() -> some View {
//        self.modifier(SizePropagator())
//    }
//}
