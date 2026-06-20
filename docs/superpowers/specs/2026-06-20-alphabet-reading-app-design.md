# Alphabet — Design Spec (finish + redesign)

Date: 2026-06-20
Status: Approved for planning
Author: Daniel Dähling (with Claude)

## Product promise

Alphabet helps a young child (≈ ages 4–8) learn to read by tapping glossy bubble
letters that fly into a word, then hearing the word **spelled out letter-by-letter
and said aloud** — fully offline, with no accounts, no network, and no data
collection. It is a delightful, calm-capable iPad-first experience with four
switchable visual "worlds."

## Why this rewrite

The existing app (created 2020) is built on Composable Architecture **0.9.0**, which
will not compile on a current Xcode. Its "speak" feature called the
Merriam-Webster / Oxford dictionary APIs to fetch an MP3 — which never worked
reliably and is the wrong foundation:

- Works only for **real dictionary words** (useless for a child freely
  experimenting with letters).
- Crashes on the unhappy path (~6 `fatalError()` calls in the network code).
- Requires the internet and a valid API key.

**Decision:** replace the entire dictionary/audio stack with the on-device
`AVSpeechSynthesizer`, and rewrite the app in plain modern SwiftUI with no external
dependencies.

## Target & constraints

- **Platform:** iPadOS first (all four orientations), iPhone supported via adaptive
  layout (portrait + landscape).
- **Min iOS:** 17.0 (uses `@Observable`, modern animations). Builds against the
  latest installed SDK (iOS 26.x).
- **Devices:** "most recent available" iPads (per user). Build/verify on the
  `iPad (A16)` / `iPad Pro 11-inch (M4)` simulators.
- **No dependencies.** No Swift Package Manager packages. No TCA.
- **Offline only.** No networking, no persistence beyond a couple of `@AppStorage`
  preferences. Therefore no privacy prompts and no App Privacy disclosures needed.

## Core experience

One screen, two modes, switched by a small segmented control at the top.

### Explore (free-play sandbox) — default mode
- Full grid of letters `a–z` plus a `space` tile (existing artwork).
- Tap a letter → a copy **flies down** along a springy arc into the **word tray** at
  the bottom, appending to the current word.
- Tap a tray letter to remove it; **long-press** a tray letter to remove it *and*
  remember its slot so the next tapped letter re-inserts there.
- Controls: **Clear (↺)** empties the tray; **Speak (🔊)** performs spell-then-say.

### Challenge (guided) mode
- A **picture card** shows a target word as an SF Symbol (themed) plus the word as
  blank slots (e.g. 🐱 `_ _ _`).
- The child builds the word from the grid.
- **Check (✓)** replaces the old gray checkmark:
  - **Correct** → letters bounce, the theme's celebration plays (confetti / glow /
    sparkle / doodle stars), a spoken praise ("You spelled CAT! C–A–T, cat."),
    then auto-advance to the next prompt.
  - **Wrong** → a gentle horizontal jiggle + soft "try again." Never punishing,
    never a harsh red.
- A **🔊 hint** spells the target word on demand.
- Words come from a curated `words.json` (≈16 simple words). When the list is
  exhausted: a friendly "You did them all! 🌟" card; tapping restarts the list.

### Speak: spell-then-say (the centerpiece)
- Each letter is spoken **in sequence at a slow, kid-friendly rate**, and the
  corresponding tray tile **highlights/glows as it is spoken** (sync driven by the
  speech synthesizer's per-utterance delegate callbacks — not guessed timers).
- After the final letter, the **whole word** is spoken once at a natural pace.
- The `space` tile is not spoken; it produces a short pause and separates words.
- Implementation note (must verify): a single letter must be read as its **name**
  ("C" → "see", "A" → "ay"), not as a phoneme or the article "a". If the synthesizer
  mis-reads a lowercase letter, map letters to explicit pronunciations (e.g. via a
  per-letter pronunciation table or `AVSpeechUtterance` tuning). This is a tracked
  verification item.

## Architecture

Plain SwiftUI, single `@Observable` model, dependency-free.

```
App/
  AlphabetApp.swift        @main; builds AppModel; sets AVAudioSession.
  AppModel.swift           @Observable app state + intents.
  RootView.swift           Background + mode switcher + grid + tray + overlays.
Models/
  Tile.swift               struct Tile { let id: UUID; let letter: String }
  GameMode.swift           enum GameMode { case explore, challenge }
  Challenge.swift          WordPrompt, ChallengeState, ChallengeStatus
  WordList.swift           Loads words.json.
Speech/
  SpeechEngine.swift       AVSpeechSynthesizer wrapper; spell-then-say + highlight.
Theme/
  Theme.swift              The Theme token struct + supporting value types.
  ThemeID.swift            enum ThemeID { sunnySky, pastelCalm, jellyLab, storybook }
  ThemeStore.swift         @Observable; current theme; @AppStorage persistence.
  ThemeBackground.swift    @ViewBuilder background switch by ThemeID.
  Themes/
    SunnySkyTheme.swift     tokens + SunnySkyBackground + celebration
    PastelCalmTheme.swift   tokens + PastelCalmBackground + celebration
    JellyLabTheme.swift     tokens + JellyLabBackground + celebration
    StorybookTheme.swift    tokens + StorybookBackground + celebration
Views/
  LetterGridView.swift     The a–z + space grid.
  WordTrayView.swift       The word being built + slots.
  TileView.swift           One bubble letter on its theme contrast chip.
  ControlCluster.swift     Clear / Speak / Check buttons (themed).
  ChallengeCardView.swift  Picture + blanks + hint.
  CelebrationOverlay.swift Dispatches to the theme's celebration.
  FlightLayer.swift        Transient fly-down animation overlay.
  ThemePickerSheet.swift   Gear → theme thumbnails + speech rate + calm toggle.
Resources/
  words.json               Challenge content (editable).
  Assets.xcassets          Existing letter PNGs (kept); new AppIcon.
```

**Deleted:** `Dependencies/APIRequest.swift`, `Dependencies/Live.swift`,
`Models/Response.swift`, `Models/Cache.swift`, `Preferences.swift` (the
anchor-preference plumbing), `Helpers.swift` (debug-only), all TCA usage in
`ContentView.swift`, `WordView.swift`, `LetterView.swift` (replaced by the new
views above). The 3 SPM packages (composable-architecture, case-paths,
combine-schedulers) are removed from the project and `Package.resolved`.

### AppModel (contract)

```swift
@MainActor @Observable final class AppModel {
    var mode: GameMode = .explore
    var tiles: [Tile] = []              // current word
    var removedSlotIndex: Int?          // long-press re-insert target
    var isSpeaking = false
    var highlightedTileID: Tile.ID?     // glowing tile during spell-out
    var challenge: ChallengeState?      // non-nil only in .challenge
    var showThemePicker = false

    let speech: SpeechEngine
    let words: WordList
    // Letters-only, used for Challenge matching (spaces ignored).
    var currentWord: String { tiles.map(\.letter).filter { $0 != " " }.joined() }
    // Speech instead iterates the raw `tiles` sequence: letters are spoken/highlighted
    // in order; a `space` tile is skipped (a short pause) and the final whole-word
    // utterance joins tiles with spaces so "cat dog" is said as two words.

    // Intents
    func tapLetter(_ letter: String, from source: CGRect)   // triggers flight + append
    func removeTile(_ id: Tile.ID, longPress: Bool)
    func clear()
    func speakCurrentWord()             // spell-then-say
    func setMode(_ mode: GameMode)
    func checkChallenge()               // correct → celebrate + advance; wrong → jiggle
    func speakChallengeHint()
}
```

### Theme (contract)

A theme is **tokens only**; layout lives in the shared views. Backgrounds and
celebrations are theme-specific SwiftUI views resolved by `ThemeID`.

```swift
struct Theme: Identifiable, Equatable {
    let id: ThemeID
    let name: String                    // "Sunny Sky", "Soft Pastel", "Jelly Lab", "Storybook"

    // Color roles
    let uiTextOnBackground: Color
    let uiTextOnSurface: Color
    let traySurface: SurfacePaint        // solid color OR material (per Reduce Transparency)
    let slotFill: Color
    let slotStroke: Color
    let primaryButton: ButtonPaint       // Speak / Check
    let secondaryButton: ButtonPaint     // Clear
    let switcher: SwitcherPaint

    // Per-letter contrast chip behind each glossy letter (the legibility guarantee)
    let tileChip: TileChipStyle          // tint strategy + shadow + highlight

    // Motion + feel
    let motion: MotionProfile            // springResponse, damping, flyArcHeight, idleWobble
    let celebration: CelebrationStyle    // .confetti | .glowPulse | .sparkle | .doodleStars
    let typography: ThemeTypography      // SF Rounded weights/colors
}
```

Views read the theme via the SwiftUI `Environment` (`\.theme`), set by `ThemeStore`.
`ThemeBackground(themeID:)` and `CelebrationOverlay(style:)` switch to the concrete
theme view. **Adding or editing a theme never touches layout code** — this is what
lets four themes be built in parallel against a frozen contract.

### Theme switcher

- A small, low-contrast **gear button in a top corner** (out of small fingers' way).
- Opens `ThemePickerSheet`: four **live preview thumbnails** (the real
  `ThemeBackground` + a few sample tiles, scaled down); tap to apply with a smooth
  crossfade.
- Also hosts: **speech rate** slider and a **Calm mode** master toggle (forces the
  reduced-motion / reduced-stimulation variant regardless of system setting).
- Persisted with `@AppStorage("themeID")`, `@AppStorage("speechRate")`,
  `@AppStorage("calmMode")`. Default theme on first launch: **Sunny Sky**.

### Letter fly-down animation

The original used anchor preferences; the rewrite uses a **transient flight overlay**
(more reliable than `matchedGeometryEffect` because each tap spawns a *new* tile, so
there is no single shared identity to match):

1. On tap, the grid button reports its frame (global coordinate space).
2. `AppModel` reserves the destination slot and `FlightLayer` renders a flying copy
   of the letter on its chip.
3. The copy springs along an arc (height from `theme.motion.flyArcHeight`) from
   source to destination; the tray plank gives a tiny bounce on landing.
4. On arrival the real tile is committed to `tiles` and the flying copy is removed.

Under **Reduce Motion / Calm mode** the flight collapses to a quick fade-in at the
destination (no arc).

## Challenge content

- Pictures are **SF Symbols rendered in the theme palette** (no image assets, recolor
  per theme for free). The word list is chosen so each word maps to a clean, concrete
  symbol.
- `words.json` (editable starter set, ~16 words), e.g.:
  `cat`(cat) `dog`(dog) `sun`(sun.max) `star`(star.fill) `fish`(fish) `bird`(bird)
  `car`(car.fill) `bus`(bus) `tree`(tree.fill) `house`(house.fill) `moon`(moon.fill)
  `heart`(heart.fill) `cup`(cup.and.saucer.fill) `key`(key.fill) `hand`(hand.raised.fill)
  `bell`(bell.fill).
- Schema: `[{ "word": "cat", "symbol": "cat" }, ...]`. Invalid/missing symbols fall
  back to `questionmark.circle` (and are logged), so a bad entry never crashes.

## States (every screen handles these)

- **Empty tray:** Speak/Check disabled and gently dimmed; Explore shows a soft "Tap a
  letter to build a word!" hint.
- **Speaking:** buttons locked; tiles non-interactive; current letter highlighted.
- **Challenge correct:** celebration + praise + auto-advance.
- **Challenge wrong:** jiggle + soft "try again," tiles remain for editing.
- **Challenge list exhausted:** "You did them all! 🌟" card; tap to restart.
- **Reduce Motion / Calm:** confetti → glow-pulse; fly-down → fade; idle wobble off.
- **Reduce Transparency:** frosted/material surfaces → solid theme colors.
- **VoiceOver:** every letter button labeled (e.g. "Letter A"); tray announces the
  current word; Speak/Clear/Check/gear labeled; celebration announces "Correct!".
- **Dynamic Type:** all UI text scales; layout reflows; letter art scales with the
  grid, independent of text size.

## App icon

Generate a 1024×1024 icon from the existing bubble-letter art — likely the glossy
"A" centered on a themed (Sunny Sky) gradient with a soft rounded vignette — and wire
it into `AppIcon.appiconset` (single-size modern app icon).

## Xcode project surgery

- Remove the 3 SPM package references and their build phases from
  `Alphabet.xcodeproj/project.pbxproj`; clear `Package.resolved`.
- Add the new Swift files to the `Alphabet` target; remove deleted files from the
  target.
- Set `IPHONEOS_DEPLOYMENT_TARGET = 17.0`; keep `TARGETED_DEVICE_FAMILY = "1,2"`.
- Keep bundle id, display name, and the existing asset catalog.
- `AlphabetApp` keeps the `AppDelegate` only to set the `AVAudioSession` category to
  `.playback` so speech is audible with the ringer off.

## Verification strategy

Building/running is possible locally (Xcode 26.5 installed; selected via
`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`).

1. **Compile:**
   `DEVELOPER_DIR=… xcodebuild -project Alphabet.xcodeproj -scheme Alphabet
   -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPad (A16)' build`
2. **Run + screenshot:** boot the iPad simulator, install, launch; screenshot each of
   the four themes (Explore), the Challenge card, and a celebration; capture the
   spell-then-say highlight sequence.
3. **Behavioral checks via logs:** assert the spell-out emits the correct per-letter
   highlight order, no crashes on edge cases (empty word, all-spaces, rapid taps,
   list exhaustion), and that the letter-name pronunciation is correct.
4. Audio itself can't be "heard" in CI, so pronunciation correctness is verified via
   the synthesizer's spoken-string log + a manual listen by Daniel.

## Parallelization plan (for the build phase)

Implementation will fan out **after** the shared contracts (Theme, AppModel,
SpeechEngine, view interfaces) are frozen by the first track:

- **Track A — Core & contracts (must land first):** Models, AppModel, SpeechEngine,
  ThemeStore + Theme struct + Environment, the generic Views (grid/tray/tile/controls/
  challenge/celebration/flight) coded against the Theme contract, RootView, project
  surgery skeleton.
- **Tracks B–E — Themes (parallel, isolated files):** SunnySky, PastelCalm, JellyLab,
  Storybook — each a self-contained file set (tokens + background + celebration)
  conforming to the frozen contract; no shared mutable files → safe to build in
  parallel (worktrees if needed).
- **Track F — Content & assets (parallel):** `words.json`, the app icon, and final
  Xcode project file wiring.
- **Integration + verification:** assemble, build, run, screenshot all four themes,
  fix, repeat.

## Out of scope (YAGNI)

- No accounts, cloud sync, analytics, ads, or in-app purchases.
- No networking of any kind.
- No recorded human audio (TTS only).
- No localized UI beyond English (UI text is minimal).
- No uppercase/lowercase letter toggle (single existing glyph set). Possible future.
- No handwriting/tracing. Possible future.

## Open questions

None blocking. Word list and default theme are easily adjusted post-build.
