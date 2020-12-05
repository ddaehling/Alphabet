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
    
    var body: some View {
        HStack {
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
                }.padding([.trailing, .top, .bottom], 20)
                .transition(.opacity)
                .font(.system(.title))
                
            }
            
            ForEach(selectedLetters) { l in
                LetterView(letter: l, originalLetterPreferenceData: topViewPreferenceData.filter { $0.id == l.letter }.first, proxy: proxy)
                    .onTapGesture {
                        removeLetter(l, isLongPress: false)
                    }
                    .onLongPressGesture {
                        removeLetter(l, isLongPress: true)
                    }
                
            }
        }
        .equalizeHeight()
        .frame(height: min(proxy.size.width, proxy.size.height) / 7)
        .padding(.bottom, 50)
        
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
