import Foundation

/// Loads the Challenge word list from `words.json`, with a safe built-in fallback
/// so the app is never empty even if the resource is missing or malformed.
struct WordList: Equatable {
    let prompts: [WordPrompt]

    static func load(language: AppLanguage = .englishUK, from bundle: Bundle = .main) -> WordList {
        if let url = bundle.url(forResource: language.wordsFile, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let p = try? JSONDecoder().decode([WordPrompt].self, from: data),
           !p.isEmpty {
            return WordList(prompts: p)
        }
        return WordList(prompts: fallback)
    }

    static let fallback: [WordPrompt] = [
        .init(word: "cat", symbol: "cat"),
        .init(word: "dog", symbol: "dog"),
        .init(word: "sun", symbol: "sun.max"),
        .init(word: "star", symbol: "star.fill"),
    ]
}
