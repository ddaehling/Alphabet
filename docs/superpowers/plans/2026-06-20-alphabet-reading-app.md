# Alphabet Reading App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the children's reading app by replacing the broken dictionary-API "speak" feature with on-device spell-then-say speech, rewriting it in dependency-free SwiftUI, and adding Explore + Challenge modes across four switchable visual themes.

**Architecture:** One `@Observable` `AppModel` drives a single screen. All visuals come from a frozen `Theme` token contract resolved through the SwiftUI `Environment`, so the four themes are isolated files built in parallel. Speech sequencing is a pure, unit-tested function consumed by an `AVSpeechSynthesizer` wrapper. The Xcode project is converted to a synchronized file group so new source files need no per-file project edits (conflict-free parallel file creation).

**Tech Stack:** Swift 5.9+, SwiftUI, `@Observable` (Observation), `AVFoundation` (`AVSpeechSynthesizer`), SF Symbols, XCTest. No external packages.

## Global Constraints

- Min deployment target: **iOS 17.0**. Build SDK: latest installed (iOS 26.x). `SWIFT_VERSION = 5.0` or later; `TARGETED_DEVICE_FAMILY = "1,2"`.
- **Zero external dependencies.** Remove all SwiftPM packages (composable-architecture, swift-case-paths, combine-schedulers). No TCA anywhere.
- **Offline only.** No networking, no data collection. Persistence limited to `@AppStorage` for `themeID`, `speechRate`, `calmMode`.
- **English (en-GB)** speech and letter names (teacher context is German-school EFL → British English; e.g. `z` = "zed", `h` = "aitch").
- Build/run via Xcode 26.5, selected per-command: prefix every `xcodebuild`/`xcrun` with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- All UI copy: sentence case. All UI text supports Dynamic Type. Every icon-only control has an accessibility label. Min touch target ≈ 64pt.
- Repo: `/Users/daniel/Library/CloudStorage/OneDrive-Personal/Programmieren/Projekte/Alphabet`. Work on branch `alphabet-swiftui-rewrite`.
- Honor `Reduce Motion` (no arcs/confetti → fades/glow) and `Reduce Transparency` (materials → solid colors). `calmMode` forces both.

---

## File Structure

```
Alphabet/
  AlphabetApp.swift          @main, AVAudioSession setup, builds AppModel + ThemeStore
  AppModel.swift             @Observable state + intents
  RootView.swift             background + switcher + grid + tray + overlays + gear
  Support/
    Color+Hex.swift          Color(hex:) helper
    LetterPalette.swift      per-letter rainbow chip colors
  Models/
    Tile.swift               Tile value type
    GameMode.swift           enum
    Challenge.swift          WordPrompt, ChallengeState, ChallengeStatus
    WordList.swift           loads words.json with fallback
  Speech/
    SpeechPlan.swift         pure SpeechStep sequencing (unit-tested)
    SpeechEngine.swift       AVSpeechSynthesizer wrapper + highlight callbacks
  Theme/
    Theme.swift              Theme struct + ButtonPaint/TileChipStyle/MotionProfile/...
    ThemeID.swift            enum + displayName + the registry (Theme.all)
    ThemeStore.swift         @Observable current theme, @AppStorage persistence
    Environment+Theme.swift  EnvironmentKey for \.theme
    ThemeBackground.swift    @ViewBuilder switch over ThemeID -> background view
    CelebrationOverlay.swift @ViewBuilder switch over CelebrationStyle
    Themes/
      SunnySkyTheme.swift     tokens + SunnySkyBackground + SunnySkyCelebration
      PastelCalmTheme.swift   tokens + PastelCalmBackground + PastelCalmCelebration
      JellyLabTheme.swift     tokens + JellyLabBackground + JellyLabCelebration
      StorybookTheme.swift    tokens + StorybookBackground + StorybookCelebration
  Views/
    LetterGridView.swift     a–z + space grid, reports tap source frames
    TileView.swift           one bubble letter on its theme chip
    WordTrayView.swift       the word being built + slots + controls row
    ControlCluster.swift     Clear / Speak / Check buttons (themed)
    ChallengeCardView.swift  SF-Symbol picture + blanks + hint
    FlightLayer.swift        transient fly-down overlay
    ModeSwitcher.swift       Explore | Challenge segmented control (themed)
    ThemePickerSheet.swift   gear sheet: theme thumbnails + rate + calm toggle
  Resources/
    words.json               challenge content
  Assets.xcassets            existing letter PNGs (kept) + new AppIcon
  Info.plist                 (kept; orientations unchanged)
AlphabetTests/
  SpeechPlanTests.swift
  WordListTests.swift
  AppModelTests.swift
  ChallengeStateTests.swift
```

**Deleted:** `Dependencies/APIRequest.swift`, `Dependencies/Live.swift`, `Models/Response.swift`, `Models/Cache.swift`, `Preferences.swift`, `Helpers.swift`, `ContentView.swift`, `WordView.swift`, `LetterView.swift`, `Models/Letter.swift`.

---

# TRACK A — Core & contracts (sequential; must land before B–F)

### Task A1: Xcode project surgery

**Files:**
- Modify: `Alphabet.xcodeproj/project.pbxproj`
- Modify/replace: `Alphabet.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- Delete from disk: the files listed under "Deleted" above.

**Goal:** A project that builds an empty-but-launchable app with no SPM deps, iOS 17 target, a synchronized `Alphabet` source group, and an `AlphabetTests` unit-test target.

- [ ] **Step 1: Remove SwiftPM packages.** In `project.pbxproj` remove the `XCRemoteSwiftPackageReference`, `XCSwiftPackageProductDependency`, `packageReferences`, and `packageProductDependencies` entries for `swift-composable-architecture`, `swift-case-paths`, `combine-schedulers`, and any `ComposableArchitecture` entries in the target's `Frameworks` build phase. Empty `Package.resolved` to `{ "pins": [], "version": 2 }`.

- [ ] **Step 2: Convert the `Alphabet` group to a synchronized root group.** Replace the classic `PBXGroup` for the `Alphabet` folder and its per-file `PBXBuildFile`/`PBXFileReference`/`Sources` build-phase entries with a single `PBXFileSystemSynchronizedRootGroup` (Xcode 16+ format; `objectVersion = 77`). The membership exceptions list keeps `Info.plist`. After this, any `.swift` file on disk under `Alphabet/` is automatically compiled — no further pbxproj edits needed for new files. Keep the existing asset catalog reference.

- [ ] **Step 3: Set build settings.** `IPHONEOS_DEPLOYMENT_TARGET = 17.0` (both configs). Keep `TARGETED_DEVICE_FAMILY = "1,2"` and the existing bundle id / display name.

- [ ] **Step 4: Add the `AlphabetTests` unit-test target.** A new `PBXNativeTarget` of product type `com.apple.product-type.bundle.unit-test`, host application = `Alphabet`, with its own `PBXFileSystemSynchronizedRootGroup` pointing at `AlphabetTests/`. Add to the scheme's test action.

- [ ] **Step 5: Delete obsolete source files** (the "Deleted" list) and replace `AlphabetApp.swift` with a minimal launchable stub:

```swift
import SwiftUI
import AVFoundation

@main
struct AlphabetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { WindowGroup { Text("Alphabet") } }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication,
                     didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        return true
    }
}
```

- [ ] **Step 6: Build + verify it launches.**
Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Alphabet.xcodeproj -scheme Alphabet -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPad (A16)' build`
Expected: `** BUILD SUCCEEDED **`, no `ComposableArchitecture` references.

- [ ] **Step 7: Commit.** `git add -A && git commit -m "chore: remove TCA + dictionary stack; modernize Xcode project to iOS 17 synchronized groups"`

---

### Task A2: Support helpers + Models

**Files:** Create `Alphabet/Support/Color+Hex.swift`, `Alphabet/Support/LetterPalette.swift`, `Alphabet/Models/Tile.swift`, `Alphabet/Models/GameMode.swift`, `Alphabet/Models/Challenge.swift`, `Alphabet/Models/WordList.swift`. Test `AlphabetTests/ChallengeStateTests.swift`, `AlphabetTests/WordListTests.swift`.

**Interfaces produced:**
- `Tile(letter: String, id: UUID = UUID())`, `.isSpace`
- `enum GameMode { case explore, challenge }`
- `WordPrompt(word: String, symbol: String)` (Codable)
- `ChallengeState(prompts:)` with `.current`, `.isFinished`, `mutating func advance()`, `mutating func restart()`
- `WordList.load(from:) -> WordList`, `WordList.fallback`
- `Color(hex: String)`; `LetterPalette.color(for: Character) -> Color`

- [ ] **Step 1: Color+Hex.swift**

```swift
import SwiftUI

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0; Scanner(string: h).scanHexInt64(&v)
        let r, g, b: Double
        switch h.count {
        case 8: r = Double((v >> 24) & 0xFF)/255; g = Double((v >> 16) & 0xFF)/255
                b = Double((v >> 8) & 0xFF)/255
        default: r = Double((v >> 16) & 0xFF)/255; g = Double((v >> 8) & 0xFF)/255
                 b = Double(v & 0xFF)/255
        }
        self = Color(.sRGB, red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 2: LetterPalette.swift** — a curated rainbow keyed by alphabetical index (matches the mockups' hue cycle), used to tint each letter's contrast chip.

```swift
import SwiftUI

enum LetterPalette {
    static let hues: [String] = [
        "F4B400","EC3E8E","F37A1A","27B85F","27A6E0","7B4FD6","EE4F3C",
        "1FB68A","3A66E0","8A4FE0","D63AA0","F08020","4FAE2A"
    ]
    static func color(for ch: Character) -> Color {
        guard let s = ch.lowercased().unicodeScalars.first, s.value >= 97, s.value <= 122
        else { return Color(hex: "9AA0A6") }
        return Color(hex: hues[Int(s.value - 97) % hues.count])
    }
}
```

- [ ] **Step 3: Tile.swift / GameMode.swift**

```swift
import Foundation
struct Tile: Identifiable, Equatable {
    let id: UUID
    let letter: String           // "a"..."z" or " "
    init(letter: String, id: UUID = UUID()) { self.letter = letter; self.id = id }
    var isSpace: Bool { letter == " " }
}
enum GameMode: String, CaseIterable, Identifiable { case explore, challenge; var id: String { rawValue } }
```

- [ ] **Step 4: Challenge.swift**

```swift
import Foundation
struct WordPrompt: Equatable, Codable { let word: String; let symbol: String }
enum ChallengeStatus: Equatable { case building, correct, wrong }
struct ChallengeState: Equatable {
    var prompts: [WordPrompt]
    var index: Int = 0
    var status: ChallengeStatus = .building
    var current: WordPrompt? { prompts.indices.contains(index) ? prompts[index] : nil }
    var isFinished: Bool { index >= prompts.count }
    mutating func advance() { index += 1; status = .building }
    mutating func restart() { index = 0; status = .building }
}
```

- [ ] **Step 5: WordList.swift**

```swift
import Foundation
struct WordList: Equatable {
    let prompts: [WordPrompt]
    static func load(from bundle: Bundle = .main) -> WordList {
        if let url = bundle.url(forResource: "words", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let p = try? JSONDecoder().decode([WordPrompt].self, from: data), !p.isEmpty {
            return WordList(prompts: p)
        }
        return WordList(prompts: fallback)
    }
    static let fallback: [WordPrompt] = [
        .init(word: "cat", symbol: "cat"), .init(word: "dog", symbol: "dog"),
        .init(word: "sun", symbol: "sun.max"), .init(word: "star", symbol: "star.fill")
    ]
}
```

- [ ] **Step 6: Tests** (`ChallengeStateTests`, `WordListTests`) — real assertions:

```swift
import XCTest
@testable import Alphabet

final class ChallengeStateTests: XCTestCase {
    func testAdvanceAndFinish() {
        var s = ChallengeState(prompts: [.init(word:"cat",symbol:"cat"), .init(word:"dog",symbol:"dog")])
        XCTAssertEqual(s.current?.word, "cat"); XCTAssertFalse(s.isFinished)
        s.advance(); XCTAssertEqual(s.current?.word, "dog")
        s.advance(); XCTAssertTrue(s.isFinished); XCTAssertNil(s.current)
        s.restart(); XCTAssertEqual(s.current?.word, "cat")
    }
}
final class WordListTests: XCTestCase {
    func testFallbackNeverEmpty() { XCTAssertFalse(WordList.fallback.isEmpty) }
    func testDecodesPromptArray() throws {
        let json = #"[{"word":"sun","symbol":"sun.max"}]"#.data(using: .utf8)!
        let p = try JSONDecoder().decode([WordPrompt].self, from: json)
        XCTAssertEqual(p.first, WordPrompt(word: "sun", symbol: "sun.max"))
    }
}
```

- [ ] **Step 7: Run tests + commit.**
Run: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Alphabet.xcodeproj -scheme Alphabet -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPad (A16)'`
Expected: PASS. Then `git add -A && git commit -m "feat: add models, word list, color + letter-palette helpers"`

---

### Task A3: Speech (SpeechPlan + SpeechEngine)

**Files:** Create `Alphabet/Speech/SpeechPlan.swift`, `Alphabet/Speech/SpeechEngine.swift`. Test `AlphabetTests/SpeechPlanTests.swift`.

**Interfaces produced:**
- `enum SpeechStep: Equatable { case letter(tileIndex: Int, spoken: String); case word(spoken: String) }`
- `SpeechPlan.make(for tiles: [Tile]) -> [SpeechStep]`
- `SpeechPlan.letterName: [Character: String]`
- `@MainActor final class SpeechEngine` with `func speak(tiles:[Tile], rate:Double, onHighlight:@escaping (Tile.ID?)->Void, onFinish:@escaping ()->Void)`, `func speakWordOnly(_ text:String, rate:Double)`, `func stop()`

- [ ] **Step 1: SpeechPlanTests.swift (failing)**

```swift
import XCTest
@testable import Alphabet

final class SpeechPlanTests: XCTestCase {
    private func tiles(_ s: String) -> [Tile] { s.map { Tile(letter: String($0)) } }

    func testSpellsThenSaysWord() {
        let p = SpeechPlan.make(for: tiles("cat"))
        XCTAssertEqual(p, [
            .letter(tileIndex: 0, spoken: "see"),
            .letter(tileIndex: 1, spoken: "ay"),
            .letter(tileIndex: 2, spoken: "tee"),
            .word(spoken: "cat"),
        ])
    }
    func testSkipsSpacesButSplitsWords() {
        let t = tiles("hi") + [Tile(letter: " ")] + tiles("yo")
        let p = SpeechPlan.make(for: t)
        XCTAssertEqual(p.filter { if case .letter = $0 { true } else { false } }.count, 4)
        XCTAssertEqual(p.last, .word(spoken: "hi yo"))
    }
    func testEmptyProducesNothing() { XCTAssertTrue(SpeechPlan.make(for: []).isEmpty) }
    func testBritishLetterNames() {
        XCTAssertEqual(SpeechPlan.letterName["z"], "zed")
        XCTAssertEqual(SpeechPlan.letterName["h"], "aitch")
    }
}
```

- [ ] **Step 2: Run → FAIL** (`SpeechPlan` undefined).

- [ ] **Step 3: SpeechPlan.swift**

```swift
import Foundation
enum SpeechStep: Equatable {
    case letter(tileIndex: Int, spoken: String)
    case word(spoken: String)
}
enum SpeechPlan {
    static let letterName: [Character: String] = [
        "a":"ay","b":"bee","c":"see","d":"dee","e":"ee","f":"eff","g":"gee",
        "h":"aitch","i":"eye","j":"jay","k":"kay","l":"el","m":"em","n":"en",
        "o":"oh","p":"pee","q":"cue","r":"ar","s":"ess","t":"tee","u":"you",
        "v":"vee","w":"double you","x":"ex","y":"why","z":"zed"
    ]
    static func make(for tiles: [Tile]) -> [SpeechStep] {
        var steps: [SpeechStep] = []
        for (i, t) in tiles.enumerated() where !t.isSpace {
            let ch = Character(t.letter.lowercased())
            steps.append(.letter(tileIndex: i, spoken: letterName[ch] ?? t.letter))
        }
        let word = tiles.map { $0.isSpace ? " " : $0.letter }.joined()
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
        if !word.isEmpty { steps.append(.word(spoken: word)) }
        return steps
    }
}
```

- [ ] **Step 4: Run → PASS.**

- [ ] **Step 5: SpeechEngine.swift** (delegate maps each spoken utterance back to its tile for highlight sync; verified on-simulator, not unit-tested):

```swift
import AVFoundation

@MainActor final class SpeechEngine: NSObject, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    private var stepForUtterance: [ObjectIdentifier: SpeechStep] = [:]
    private var tilesInFlight: [Tile] = []
    private var onHighlight: ((Tile.ID?) -> Void)?
    private var onFinish: (() -> Void)?
    private let voice = AVSpeechSynthesisVoice(language: "en-GB")

    override init() { super.init(); synth.delegate = self }

    func speak(tiles: [Tile], rate: Double,
               onHighlight: @escaping (Tile.ID?) -> Void,
               onFinish: @escaping () -> Void) {
        stop()
        tilesInFlight = tiles; self.onHighlight = onHighlight; self.onFinish = onFinish
        for step in SpeechPlan.make(for: tiles) {
            let spoken: String = { if case let .letter(_, s) = step { return s }
                                   if case let .word(s) = step { return s }; return "" }()
            let u = AVSpeechUtterance(string: spoken)
            u.voice = voice
            u.rate = Float(rate)                       // ~0.35 letters, model can nudge
            u.postUtteranceDelay = { if case .letter = step { return 0.18 } else { return 0 } }()
            stepForUtterance[ObjectIdentifier(u)] = step
            synth.speak(u)
        }
    }
    func speakWordOnly(_ text: String, rate: Double) {
        stop(); let u = AVSpeechUtterance(string: text); u.voice = voice; u.rate = Float(rate); synth.speak(u)
    }
    func stop() { synth.stopSpeaking(at: .immediate); stepForUtterance.removeAll(); onHighlight?(nil) }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart u: AVSpeechUtterance) {
        Task { @MainActor in
            if case let .letter(i, _)? = stepForUtterance[ObjectIdentifier(u)],
               tilesInFlight.indices.contains(i) { onHighlight?(tilesInFlight[i].id) }
            else { onHighlight?(nil) }
        }
    }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        Task { @MainActor in
            if stepForUtterance[ObjectIdentifier(u)].map({ if case .word = $0 { true } else { false } }) == true {
                onHighlight?(nil); onFinish?()
            }
        }
    }
}
```

- [ ] **Step 6: Build (test target) + commit.** Run the test command from A2 Step 7. Expected PASS. `git add -A && git commit -m "feat: add offline spell-then-say speech engine (en-GB)"`

---

### Task A4: Theme contract + store + registry

**Files:** Create `Alphabet/Theme/Theme.swift`, `Theme/ThemeID.swift`, `Theme/ThemeStore.swift`, `Theme/Environment+Theme.swift`, `Theme/ThemeBackground.swift`, `Theme/CelebrationOverlay.swift`.

**Interfaces produced (THE FROZEN CONTRACT — tracks B–E depend on these names/types verbatim):**

- [ ] **Step 1: Theme.swift**

```swift
import SwiftUI

struct ButtonPaint: Equatable {
    let fillTop: Color, fillBottom: Color, rim: Color, label: Color
    var glossOpacity: Double = 0.4
}
enum ChipShape: Equatable { case circle; case roundedSquare(cornerRadius: CGFloat) }
struct TileChipStyle: Equatable {
    enum Tint: Equatable { case letterColor, neutralLight, neutralDark }
    var tint: Tint
    var shape: ChipShape = .circle
    var shadowOpacity: Double = 0.12
    var highlightOpacity: Double = 0.7
}
struct MotionProfile: Equatable {
    var springResponse: Double = 0.45
    var springDamping: Double = 0.6
    var flyArcHeight: CGFloat = 90
    var idleWobble: Bool = false
}
enum CelebrationStyle: String, Equatable { case confetti, glowPulse, sparkle, doodleStars }
struct ThemeTypography: Equatable {
    var titleWeight: Font.Weight = .bold
    var labelWeight: Font.Weight = .semibold
}

struct Theme: Identifiable, Equatable {
    let id: ThemeID
    var name: String
    var uiTextOnBackground: Color
    var uiTextOnSurface: Color
    var traySurface: Color
    var usesMaterialSurface: Bool = false   // ignored under Reduce Transparency
    var slotFill: Color
    var slotStroke: Color
    var primaryButton: ButtonPaint          // Speak / Check
    var secondaryButton: ButtonPaint        // Clear
    var switcherTrack: Color
    var switcherThumb: ButtonPaint
    var tileChip: TileChipStyle
    var motion: MotionProfile
    var celebration: CelebrationStyle
    var typography: ThemeTypography
}
```

- [ ] **Step 2: ThemeID.swift** — registry that maps each id to its concrete `Theme` (each theme file in Track B–E defines a `static let theme: Theme` it slots in here). To avoid a shared-file merge conflict, the registry reads from per-theme static members:

```swift
enum ThemeID: String, CaseIterable, Identifiable, Codable {
    case sunnySky, pastelCalm, jellyLab, storybook
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .sunnySky: "Sunny Sky"; case .pastelCalm: "Soft Pastel"
        case .jellyLab: "Jelly Lab"; case .storybook: "Storybook"
        }
    }
    var theme: Theme {                      // resolves to the concrete theme tokens
        switch self {
        case .sunnySky: SunnySkyTheme.theme
        case .pastelCalm: PastelCalmTheme.theme
        case .jellyLab: JellyLabTheme.theme
        case .storybook: StorybookTheme.theme
        }
    }
}
```

- [ ] **Step 3: ThemeStore.swift**

```swift
import SwiftUI

@MainActor @Observable final class ThemeStore {
    var id: ThemeID { didSet { UserDefaults.standard.set(id.rawValue, forKey: "themeID") } }
    var speechRate: Double { didSet { UserDefaults.standard.set(speechRate, forKey: "speechRate") } }
    var calmMode: Bool { didSet { UserDefaults.standard.set(calmMode, forKey: "calmMode") } }
    init() {
        let d = UserDefaults.standard
        id = ThemeID(rawValue: d.string(forKey: "themeID") ?? "") ?? .sunnySky
        speechRate = d.object(forKey: "speechRate") as? Double ?? 0.35
        calmMode = d.bool(forKey: "calmMode")
    }
    var theme: Theme { id.theme }
}
```

- [ ] **Step 4: Environment+Theme.swift**

```swift
import SwiftUI
private struct ThemeKey: EnvironmentKey { static let defaultValue: Theme = ThemeID.sunnySky.theme }
extension EnvironmentValues { var theme: Theme { get { self[ThemeKey.self] } set { self[ThemeKey.self] = newValue } } }
```

- [ ] **Step 5: ThemeBackground.swift / CelebrationOverlay.swift** — `@ViewBuilder` switches that each Track B–E view plugs into:

```swift
import SwiftUI
struct ThemeBackground: View {
    let id: ThemeID
    var body: some View {
        switch id {
        case .sunnySky: SunnySkyBackground()
        case .pastelCalm: PastelCalmBackground()
        case .jellyLab: JellyLabBackground()
        case .storybook: StorybookBackground()
        }
    }
}
struct CelebrationOverlay: View {
    let style: CelebrationStyle
    let reduceMotion: Bool
    var body: some View {
        switch style {
        case .confetti: ConfettiCelebration(reduceMotion: reduceMotion)
        case .glowPulse: GlowPulseCelebration()
        case .sparkle: SparkleCelebration(reduceMotion: reduceMotion)
        case .doodleStars: DoodleStarsCelebration(reduceMotion: reduceMotion)
        }
    }
}
```

- [ ] **Step 6:** This task will NOT compile until Track B–E provide `SunnySkyTheme`, `SunnySkyBackground`, `ConfettiCelebration`, etc. That is expected — A4 defines the contract; A6 uses a temporary stub. Commit the contract now: `git add -A && git commit -m "feat: add Theme contract, store, environment, background/celebration dispatch"`

---

### Task A5: AppModel

**Files:** Create `Alphabet/AppModel.swift`. Test `AlphabetTests/AppModelTests.swift`.

**Interfaces produced (consumed by views in A6):**

- [ ] **Step 1: AppModelTests.swift (failing)**

```swift
import XCTest
@testable import Alphabet

@MainActor final class AppModelTests: XCTestCase {
    private func model() -> AppModel {
        AppModel(speech: SpeechEngine(),
                 words: WordList(prompts: [.init(word:"cat",symbol:"cat"), .init(word:"dog",symbol:"dog")]))
    }
    func testTapAppendsTile() {
        let m = model(); m.tapLetter("c"); m.tapLetter("a"); m.tapLetter("t")
        XCTAssertEqual(m.currentWord, "cat"); XCTAssertEqual(m.tiles.count, 3)
    }
    func testRemoveAndReinsertAtSlot() {
        let m = model(); ["c","a","t"].forEach(m.tapLetter)
        m.removeTile(m.tiles[1].id, longPress: true)     // remove 'a', remember slot 1
        XCTAssertEqual(m.currentWord, "ct")
        m.tapLetter("o")                                  // re-inserts at slot 1
        XCTAssertEqual(m.currentWord, "cot")
    }
    func testClear() { let m = model(); ["c","a","t"].forEach(m.tapLetter); m.clear(); XCTAssertTrue(m.tiles.isEmpty) }
    func testChallengeCorrectAdvances() {
        let m = model(); m.setMode(.challenge)
        XCTAssertEqual(m.challenge?.current?.word, "cat")
        ["c","a","t"].forEach(m.tapLetter); m.checkChallenge()
        XCTAssertEqual(m.challenge?.status, .correct)
        m.advanceChallenge()
        XCTAssertEqual(m.challenge?.current?.word, "dog"); XCTAssertTrue(m.tiles.isEmpty)
    }
    func testChallengeWrongStays() {
        let m = model(); m.setMode(.challenge); ["c","o","w"].forEach(m.tapLetter); m.checkChallenge()
        XCTAssertEqual(m.challenge?.status, .wrong); XCTAssertEqual(m.tiles.count, 3)
    }
}
```

- [ ] **Step 2: Run → FAIL.**

- [ ] **Step 3: AppModel.swift**

```swift
import SwiftUI

@MainActor @Observable final class AppModel {
    var mode: GameMode = .explore
    var tiles: [Tile] = []
    var removedSlotIndex: Int?
    var isSpeaking = false
    var highlightedTileID: Tile.ID?
    var challenge: ChallengeState?
    var showThemePicker = false

    let speech: SpeechEngine
    let words: WordList

    init(speech: SpeechEngine, words: WordList) { self.speech = speech; self.words = words }

    var currentWord: String { tiles.map(\.letter).filter { $0 != " " }.joined() }

    func tapLetter(_ letter: String) {
        let tile = Tile(letter: letter)
        if let i = removedSlotIndex, i <= tiles.count { tiles.insert(tile, at: i); removedSlotIndex = nil }
        else { tiles.append(tile) }
    }
    func removeTile(_ id: Tile.ID, longPress: Bool) {
        guard let i = tiles.firstIndex(where: { $0.id == id }) else { return }
        tiles.remove(at: i); if longPress { removedSlotIndex = i }
    }
    func clear() { speech.stop(); tiles.removeAll(); removedSlotIndex = nil; isSpeaking = false }

    func speakCurrentWord() {
        guard !tiles.isEmpty, !isSpeaking else { return }
        isSpeaking = true
        speech.speak(tiles: tiles, rate: rate,
                     onHighlight: { [weak self] in self?.highlightedTileID = $0 },
                     onFinish: { [weak self] in self?.isSpeaking = false; self?.highlightedTileID = nil })
    }
    func setMode(_ m: GameMode) {
        mode = m; clear()
        challenge = (m == .challenge) ? ChallengeState(prompts: words.prompts) : nil
    }
    func checkChallenge() {
        guard var c = challenge, let target = c.current else { return }
        if currentWord.lowercased() == target.word.lowercased() {
            c.status = .correct; challenge = c
            speech.speak(tiles: tiles, rate: rate, onHighlight: { [weak self] in self?.highlightedTileID = $0 },
                         onFinish: { [weak self] in self?.highlightedTileID = nil })
        } else { c.status = .wrong; challenge = c }
    }
    func advanceChallenge() {
        guard var c = challenge else { return }
        c.advance(); challenge = c; tiles.removeAll(); removedSlotIndex = nil
    }
    func restartChallenge() { guard var c = challenge else { return }; c.restart(); challenge = c; clear() }
    func speakChallengeHint() {
        guard let w = challenge?.current?.word else { return }
        speech.speak(tiles: w.map { Tile(letter: String($0)) }, rate: rate,
                     onHighlight: { _ in }, onFinish: { })
    }
    var rate: Double { UserDefaults.standard.object(forKey: "speechRate") as? Double ?? 0.35 }
}
```

- [ ] **Step 4: Run → PASS. Commit.** `git add -A && git commit -m "feat: add AppModel (explore + challenge intents)"`

---

### Task A6: Generic views + RootView (against contract; temporary stub theme to compile)

**Files:** Create all files under `Alphabet/Views/`, plus `RootView.swift`, and **four minimal-but-complete theme files** `Theme/Themes/SunnySkyTheme.swift`, `PastelCalmTheme.swift`, `JellyLabTheme.swift`, `StorybookTheme.swift` — each defining its `enum <Name>Theme { static let theme }`, a basic `struct <Name>Background` (a plain themed gradient is fine for now), and its celebration view (`ConfettiCelebration`/`GlowPulseCelebration`/`SparkleCelebration`/`DoodleStarsCelebration`, minimal) — so the app compiles and launches. **Tracks B–E each fully REPLACE one of these four files** (disjoint files → no shared-file conflict, project always compiles). Replace `AlphabetApp.swift` body with `RootView`.

**Interfaces consumed:** `AppModel`, `Theme`, `\.theme`, `ThemeBackground`, `CelebrationOverlay`, `LetterPalette`.

**Acceptance (verified visually, not unit-tested):** App launches on iPad sim; Explore shows the grid; tapping a letter flies it into the tray; Speak highlights letters in order then says the word; Clear empties; switching to Challenge shows the SF-Symbol card; Check celebrates/advances or jiggles.

- [ ] **Step 1:** Implement `TileView` — renders `Image(letter)` (existing PNG) centered on a chip whose fill is `theme.tileChip` (`.letterColor` → `LetterPalette.color(for:)`, else neutral), shape per `ChipShape`, with the white specular highlight ellipse and soft shadow. Highlighted state (`id == model.highlightedTileID`) adds a glow ring + slight scale. Accessibility label `"Letter \(letter.uppercased())"`.

- [ ] **Step 2:** Implement `LetterGridView` — 4 rows from the existing `LetterBox.basic` layout (`a–f / g–m / n–t / u–z + space`), each a themed tappable `TileView`; reports each cell's global frame via a `PreferenceKey` so `FlightLayer` knows the source. Tapping calls `model.tapLetter` and records the source frame.

- [ ] **Step 3:** Implement `FlightLayer` — overlay that, on a new flight request, springs a copy of the letter+chip from source frame to the destination tray slot along an arc of height `theme.motion.flyArcHeight` (0 under reduce motion → fade). Uses `theme.motion` spring. On completion the real tray tile becomes visible.

- [ ] **Step 4:** Implement `WordTrayView` — the themed tray surface (`traySurface`, optional material when `usesMaterialSurface` && !reduceTransparency) holding the tiles row + empty slots; tap removes, long-press removes-and-remembers. Hosts `ControlCluster`.

- [ ] **Step 5:** Implement `ControlCluster` — Clear (secondary paint, `arrow.counterclockwise`), Speak (primary paint, `speaker.wave.2.fill`); in challenge mode also Check (primary, `checkmark`) and a hint (`speaker.wave.2`). Disabled+dimmed when `tiles.isEmpty` or `isSpeaking`. 64pt min. Labeled.

- [ ] **Step 6:** Implement `ModeSwitcher` (themed segmented Explore|Challenge) and `ChallengeCardView` (SF Symbol `Image(systemName: prompt.symbol)` tinted in palette + blanks line + hint button; fallback `questionmark.circle`).

- [ ] **Step 7:** Implement `ThemePickerSheet` — 2×2 grid of live theme thumbnails (`ThemeBackground(id:)` scaled + a few sample tiles), tap sets `themeStore.id`; speech-rate `Slider` (0.2–0.5); calm-mode `Toggle`. Presented from a gear button in `RootView`'s top-trailing corner.

- [ ] **Step 8:** Implement `RootView` — `ZStack { ThemeBackground(id:) ; VStack { ModeSwitcher ; LetterGridView ; Spacer ; (ChallengeCardView if challenge) ; WordTrayView } ; FlightLayer ; CelebrationOverlay when status == .correct ; gear }`. Inject `\.theme` from `themeStore.theme`. Crossfade on theme change. On `challenge.status == .correct`, show celebration then `model.advanceChallenge()` after a beat.

- [ ] **Step 9:** Wire `AlphabetApp` to build `ThemeStore` + `AppModel(speech: SpeechEngine(), words: .load())` and show `RootView`. Build + launch on `iPad (A16)` sim.
Run the build command from A1 Step 6. Expected: BUILD SUCCEEDED + app launches.

- [ ] **Step 10: Commit.** `git add -A && git commit -m "feat: add views + RootView wired to AppModel and Theme contract (stub theme)"`

---

# TRACKS B–E — Themes (PARALLEL; each is an isolated file set)

Each theme task fully REPLACES exactly one file `Alphabet/Theme/Themes/<Name>Theme.swift` (created minimally in A6) containing:
1. `enum <Name>Theme { static let theme: Theme = … }` — all token values below.
2. `struct <Name>Background: View` — reproduces the approved mockup environment.
3. The matching celebration view (named per the `CelebrationOverlay` switch: `ConfettiCelebration`, `GlowPulseCelebration`, `SparkleCelebration`, `DoodleStarsCelebration`).

These files are disjoint — each task owns one file and edits no other — so they are built concurrently with zero merge conflict, and the project compiles at every step. **Acceptance for each: the app builds and a simulator screenshot of that theme's Explore screen matches its mockup's palette and feel; letters legible; celebration plays; Reduce Motion + Reduce Transparency variants verified.**

### Task B: Sunny Sky theme
- Tokens: `uiTextOnBackground`/`OnSurface` `#5A4632`; `traySurface` `#FBF7EC`; `slotFill` `#F2E8D2`, `slotStroke` `#E5C9A0`; `primaryButton` fill `#FFB860→#FF9E3D`, rim `#E07A1E`, label white; `secondaryButton` fill `#7AD2F0→#5CC0E8`, rim `#2E9BC8`, label white; `switcherTrack` white@55%, `switcherThumb` `#FFB860→#FF9E3D` white label; `tileChip` `.letterColor`, `.circle`, shadow 0.10, highlight 0.75; `motion` response 0.42 damping 0.6 arc 100 idleWobble true; `celebration` `.confetti`; SF Rounded.
- `SunnySkyBackground`: vertical gradient `#FFE2C2 → #FFF1DC(0.22) → #BCE4F5(0.62) → #9FD6F2`; soft radial sun glow top-right; 2–3 slow-drifting pale clouds (groups of circles); a two-layer rolling grassy hill (`#6FB23C` back, `#86C44A` front, `#A6D86A` rim) along the bottom. Clouds drift via `TimelineView` (disabled under reduce motion).
- `ConfettiCelebration`: rainbow confetti (LetterPalette hues) falling with rotation via `Canvas`+`TimelineView`, capped ≤120 particles; under reduce motion → a single gentle scale+glow pulse.

### Task C: Soft Pastel theme
- Tokens: `uiTextOnBackground` `#5A5249`, `OnSurface` `#6B6256`; `traySurface` `#FFFFFF` (`usesMaterialSurface` false — keep crisp paper); `slotFill` `#F1E9DC`, `slotStroke` `#D9CDB6`; `primaryButton` lavender `#D6C6EC→#C5B1E2` rim `#B9A6D6` white label; `secondaryButton` `#FFFDF8→#F6F1E8` rim `#E7DECF` label `#6B6256`; `switcherTrack` `#EFE7D9`, thumb white label `#5A5249`; `tileChip` `.letterColor`, `.circle`, shadow 0.14, highlight 0.9; `motion` response 0.5 damping 0.8 arc 60 idleWobble false; `celebration` `.glowPulse`; SF Rounded regular/medium.
- `PastelCalmBackground`: vertical `#FBF7F0 → #F3ECE0` with 3 very soft, blurred pastel orbs (lavender/peach/sage) at low opacity.
- `GlowPulseCelebration`: a calm expanding soft halo + a few slow sparkles; no falling confetti (already calm — same under reduce motion).

### Task D: Jelly Lab theme
- Tokens: `uiTextOnBackground` white, `OnSurface` white; `traySurface` `#2A1A5C` (`usesMaterialSurface` true → ultraThin over the dark bg unless Reduce Transparency); `slotFill` `#160A3A`@0.6, `slotStroke` `#B9A6FF`@0.18; `primaryButton` `#C76BF7→#7A28D6` rim `#5A1FB0` white label, gloss 0.6; `secondaryButton` `#4A3A92→#2A1E5C` rim `#6A5AB0` white label; `switcherTrack` `#241152`@0.7, thumb `#C06BF5→#7A28D6`; `tileChip` `.letterColor`, `.roundedSquare(26)`, shadow 0.0, highlight 0.7; `motion` response 0.4 damping 0.55 arc 110 idleWobble true; `celebration` `.sparkle`; SF Rounded bold.
- `JellyLabBackground`: radial `#7B3FD4 → #3A1C7E → #1B0E45`; a few large blurred color bokeh circles at very low opacity + tiny white sparkle dots. **Feasibility guard:** use solid radial gradients + ≤8 blurred circles (no per-frame blur); under Reduce Transparency the tray becomes solid `#2A1A5C`.
- `SparkleCelebration`: upward burst of small glowing star/dot particles via `Canvas`; capped ≤100; under reduce motion → static sparkle ring + glow.

### Task E: Storybook theme
- Tokens: `uiTextOnBackground` `#5A3A1E`, `OnSurface` `#FFF7EC` (on wood); `traySurface` `#E0A35E` (wood); `slotFill` `#C98B45`@0.4, `slotStroke` `#B97C3C`; `primaryButton` `#C79BDD→#9E66BE` rim `#7A4F9A` label `#FFF7EC`; `secondaryButton` `#9ED0C2→#6FA99B` rim `#5A8A7C` label `#FFF7EC`; `switcherTrack` `#F1E2C4`, thumb `#EAC081→#DDA85C` label `#5A3A1E`; `tileChip` `.letterColor`, `.circle`, shadow 0.3, highlight 0.55; `motion` response 0.46 damping 0.62 arc 95 idleWobble false; `celebration` `.doodleStars`; SF Rounded bold.
- `StorybookBackground`: paper gradient `#FBF3E2 → #F3E4C8` + soft radial vignette; hand-drawn doodle accents (a sun top-left, a few outlined stars top-right, faint dotted paths) in `#D8B98A`.
- `DoodleStarsCelebration`: outlined doodle stars + a few confetti pop in and twinkle; under reduce motion → static doodle stars fade in.

---

# TRACK F — Content & assets (PARALLEL with B–E)

### Task F1: words.json
**Files:** Create `Alphabet/Resources/words.json`.
- [ ] Write the curated list (each word maps to a real, concrete SF Symbol):
```json
[
  {"word":"cat","symbol":"cat"},{"word":"dog","symbol":"dog"},
  {"word":"sun","symbol":"sun.max"},{"word":"star","symbol":"star.fill"},
  {"word":"fish","symbol":"fish"},{"word":"bird","symbol":"bird"},
  {"word":"car","symbol":"car.fill"},{"word":"bus","symbol":"bus"},
  {"word":"tree","symbol":"tree.fill"},{"word":"house","symbol":"house.fill"},
  {"word":"moon","symbol":"moon.fill"},{"word":"heart","symbol":"heart.fill"},
  {"word":"cup","symbol":"cup.and.saucer.fill"},{"word":"key","symbol":"key.fill"},
  {"word":"hand","symbol":"hand.raised.fill"},{"word":"bell","symbol":"bell.fill"}
]
```
- [ ] Verify each symbol exists: `for s in cat dog sun.max star.fill fish bird car.fill bus tree.fill house.fill moon.fill heart.fill cup.and.saucer.fill key.fill hand.raised.fill bell.fill; do echo $s; done` and sanity-check in SF Symbols app / by rendering on-sim. Any missing symbol → swap to a valid one. Commit.

### Task F2: App icon
**Files:** Create `Alphabet/Assets.xcassets/AppIcon.appiconset/icon-1024.png` + update its `Contents.json` to a single 1024 universal icon.
- [ ] Generate a 1024×1024 icon: the glossy bubble "A" (from `a.imageset/a.png`) centered on a Sunny-Sky gradient (`#FFE2C2 → #9FD6F2`) with a soft rounded vignette. Use the existing `a.png` composited onto the gradient (e.g. via `sips`/Core Image script or an AppIcon generator). Commit.

---

# INTEGRATION & VERIFICATION

### Task G1: Assemble + build all themes
- [ ] All four theme files now carry full implementations (Tracks B–E). Build.
Run the A1 Step 6 build command. Expected: BUILD SUCCEEDED with all four real themes.
- [ ] Run full test suite (A2 Step 7 command). Expected: all PASS.
- [ ] Commit: `git add -A && git commit -m "feat: integrate all four themes; remove stub"`

### Task G2: On-simulator visual proof
- [ ] Boot `iPad (A16)`, install, launch (`xcrun simctl boot`/`install`/`launch`).
- [ ] For each theme: switch via the picker, build the word "cat", screenshot Explore (`xcrun simctl io booted screenshot`). Confirm: palette matches mockup, every letter legible on its chip, tray/buttons themed.
- [ ] Switch to Challenge: confirm SF-Symbol card renders, Check on a correct word celebrates, a wrong word jiggles.
- [ ] Toggle iOS Reduce Motion + Reduce Transparency (`xcrun simctl ... accessibility` or Settings) and re-verify: no arcs/confetti, solid surfaces, app fully usable.
- [ ] Attach screenshots to the PR/summary.

### Task G3: Behavioral verification
- [ ] Edge cases (interaction on sim + assert no crash): empty word (Speak/Check disabled), all-spaces word, rapid repeated taps mid-flight, removing tiles during speech, Challenge list exhaustion → "You did them all!" → restart.
- [ ] Confirm spell-then-say order + highlight by observing the highlight sequence and the synthesizer's spoken strings (en-GB letter names: "see, ay, tee, cat"). Manual listen by Daniel for pronunciation sign-off.
- [ ] `superpowers:finishing-a-development-branch` to decide merge/PR.

---

## Self-Review

**Spec coverage:** Speak-then-say → A3/A5/A6. Explore + Challenge → A5/A6/F1. Four switchable themes + switcher → A4/A6 Step 7/B–E. Per-letter contrast chip → A2(LetterPalette)/A6 Step 1/all themes. Offline+no-deps+iOS17 → A1. Fly-down → A6 Step 3. SF-Symbol content → F1/A6 Step 6. App icon → F2. Reduce Motion/Transparency → B–E + G2. Accessibility labels → A6. Project surgery + delete old stack → A1. Verification → G1–G3. All spec sections mapped.

**Placeholder scan:** No TBD/TODO. View tasks (A6, B–E) intentionally specify behavior + exact token values + screenshot acceptance rather than line-level TDD, because SwiftUI views are verified visually, not by unit assertion; all logic with hidden failure modes (SpeechPlan, ChallengeState, WordList, AppModel) has complete TDD with real assertions.

**Type consistency:** `Tile.id`, `highlightedTileID: Tile.ID`, `SpeechStep` cases, `SpeechPlan.make`, `Theme` field names, `ThemeID.theme`, celebration view names (`ConfettiCelebration`/`GlowPulseCelebration`/`SparkleCelebration`/`DoodleStarsCelebration`) all match across A4/A6/B–E. `model.rate` reads the same `speechRate` default (0.35) as `ThemeStore`. Confirmed consistent.
