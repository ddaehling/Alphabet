import Foundation

/// Fetches real human WORD-pronunciation recordings from a free online dictionary and
/// caches the audio on disk, so each word is downloaded once and then plays offline
/// forever. Words only — letters, phonemes and non-words use the on-device voice.
///
/// Source: the free, key-less Dictionary API (dictionaryapi.dev), which serves
/// Wiktionary-sourced mp3 recordings. English coverage is strongest (ideal for EFL); a
/// British recording is preferred when present. Anything without a recording simply
/// falls back to the built-in voice. The network source is isolated to
/// `remoteAudioURL(...)` so it can be swapped for another provider (e.g. a keyed neural
/// TTS covering German + phonemes) without touching the rest of the app.
actor PronunciationStore {
    static let shared = PronunciationStore()

    private let session: URLSession
    private let dir: URL
    private var inFlight: Set<String> = []

    init() {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 6
        cfg.timeoutIntervalForResource = 12
        cfg.waitsForConnectivity = false
        session = URLSession(configuration: cfg)
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        dir = base.appendingPathComponent("Pronunciation", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    // MARK: Keys / paths (pure, safe to call from any isolation)

    nonisolated static func normalize(_ word: String) -> String {
        word.lowercased().filter { $0.isLetter }
    }

    nonisolated private func fileURL(_ word: String, _ language: AppLanguage) -> URL {
        dir.appendingPathComponent("\(language.rawValue)-\(Self.normalize(word)).mp3")
    }

    /// Fast, synchronous cache-hit check — returns the local file if already downloaded.
    nonisolated func cachedFileURL(word: String, language: AppLanguage) -> URL? {
        guard !Self.normalize(word).isEmpty else { return nil }
        let f = fileURL(word, language)
        return FileManager.default.fileExists(atPath: f.path) ? f : nil
    }

    // MARK: Prefetch (download once, then it's a cache hit forever)

    func prefetch(word: String, language: AppLanguage) async {
        let norm = Self.normalize(word)
        let key = "\(language.rawValue)-\(norm)"
        guard !norm.isEmpty,
              cachedFileURL(word: word, language: language) == nil,
              !inFlight.contains(key) else { return }
        inFlight.insert(key)
        defer { inFlight.remove(key) }

        guard let remote = await remoteAudioURL(word: word, language: language),
              let (data, resp) = try? await session.data(from: remote),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              data.count > 512 else { return }
        try? data.write(to: fileURL(word, language), options: .atomic)
    }

    // MARK: Network source (swappable)

    private func remoteAudioURL(word: String, language: AppLanguage) async -> URL? {
        let lang = language == .german ? "de" : "en"
        let norm = Self.normalize(word)
        guard !norm.isEmpty,
              let encoded = norm.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/\(lang)/\(encoded)"),
              let (data, resp) = try? await session.data(from: url),
              (resp as? HTTPURLResponse)?.statusCode == 200
        else { return nil }
        return Self.audioURL(fromDictionaryJSON: data, preferUK: language != .german)
    }

    /// Pure, unit-testable parser: pull the best audio URL out of a dictionaryapi.dev
    /// response, preferring a British ("-uk") recording for English.
    static func audioURL(fromDictionaryJSON data: Data, preferUK: Bool) -> URL? {
        struct Entry: Decodable { let phonetics: [Phon]? }
        struct Phon: Decodable { let audio: String? }
        guard let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return nil }
        let audios = entries
            .flatMap { $0.phonetics ?? [] }
            .compactMap { $0.audio }
            .filter { !$0.isEmpty }
        guard let first = audios.first else { return nil }
        let chosen = (preferUK ? audios.first { $0.contains("-uk.") } : nil) ?? first
        // The API occasionally returns protocol-relative ("//ssl…") URLs.
        let fixed = chosen.hasPrefix("//") ? "https:\(chosen)" : chosen
        return URL(string: fixed)
    }
}
