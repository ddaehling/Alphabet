//
//  WordView.swift
//  Alphabet
//
//  Created by Daniel Dähling on 05.12.20.
//

import SwiftUI

struct WordView: View {
    
    let proxy: GeometryProxy
    let topViewPreferenceData: [LetterPreferenceData]
    
    @Binding var removedIndex : Int?
    @Binding var selectedLetters : [Letter]
    
    private var letterHeight : CGFloat {
        let totalWidth = selectedLetters.reduce(into: CGFloat(0)) { total, element in
            let elementAnchor = topViewPreferenceData.filter { $0.id == element.letter }.first!
            let elementWidth = proxy[elementAnchor.anchor].size.width
            return total += elementWidth
        } + CGFloat((selectedLetters.count - 1)) * (spacing * 1)
        let overshoot = max(0, totalWidth + (proxy.size.width / 4) - proxy.size.width)
        let heightFactor = (totalWidth - overshoot) / totalWidth
        
        guard let originalHeightAnchor = topViewPreferenceData.first?.anchor else { return 0 }
        let originalLetterHeight = proxy[originalHeightAnchor].size.height
        return originalLetterHeight * heightFactor
    }
    
    private let spacing = CGFloat(10)
    
    var body: some View {
        HStack(spacing: spacing) {
            if !selectedLetters.isEmpty {
                VStack {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            selectedLetters.removeAll()
                        }
                    }, label: { Image(systemName: "arrow.counterclockwise").renderingMode(.original) })
                    Spacer()
                    Button(action: { }, label: { Image(systemName: "checkmark").renderingMode(.original) })
                    Spacer()
                    Button(action: { }, label: { Image(systemName: "speaker.wave.2.fill").renderingMode(.original) })
                }
//                .frame(height: letterHeight)
                .padding([.trailing, .top, .bottom], 20)
                .transition(.opacity)
                .font(.system(.title))
                
                
            }
            
            ForEach(selectedLetters) { l in
                LetterView(letter: l, originalLetterPreferenceData: topViewPreferenceData.filter { $0.id == l.letter }.first, proxy: proxy)
                    .frame(width: letterHeight * aspectRatio(for: l, with: topViewPreferenceData, using: proxy),height: letterHeight)
                    .onTapGesture {
                        removeLetter(l, isLongPress: false)
                    }
                    .onLongPressGesture {
                        removeLetter(l, isLongPress: true)
                    }
                
            }
        }
        .frame(height: (min(proxy.size.width, proxy.size.height) / 7))
        .frame(maxWidth: proxy.size.width - proxy.size.width / 7)
        .padding(.bottom, 50)
        
    }
    
    func aspectRatio(for letter: Letter, with preferenceData : [LetterPreferenceData], using proxy: GeometryProxy) -> CGFloat {
        let elementAnchor = preferenceData.filter { $0.id == letter.letter }.first!
        return  proxy[elementAnchor.anchor].size.width / proxy[elementAnchor.anchor].size.height
    }
    
    
    func removeLetter(_ letter: Letter, isLongPress: Bool) {
        withAnimation(.easeInOut) {
            guard let index = selectedLetters.firstIndex(where:{ $0.id == letter.id }) else { return }
            selectedLetters.remove(at: index)
            if isLongPress {
                removedIndex = index
            }
        }
    }
}

//
//struct WordView_Previews: PreviewProvider {
//    static var previews: some View {
//        WordView(proxy: <#GeometryProxy#>, topViewPreferenceData: <#[LetterPreferenceData]#>, removedIndex: <#Binding<Int?>#>, selectedLetters: <#Binding<[Letter]>#>)
//    }
//}
