import SwiftUI

/// Live theme thumbnails + speech rate + calm mode. Opened from the gear.
struct ThemePickerSheet: View {
    @Bindable var store: ThemeStore
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(ThemeID.allCases) { id in
                        Button { withAnimation { store.id = id } } label: { thumbnail(id) }
                            .buttonStyle(.plain)
                    }
                }
                .padding()

                VStack(alignment: .leading, spacing: 18) {
                    Text("Language")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Picker("Language", selection: $store.language) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text("\(lang.flag)  \(lang.displayName)").tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("Letter voice")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Picker("Letter voice", selection: $store.speechMode) {
                        ForEach(SpeechMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("**Names** says \u{201C}see\u{2013}ay\u{2013}tee\u{201D}. **Sounds** says the phonics \u{2044}k\u{2044} \u{2044}a\u{2044} \u{2044}t\u{2044} and gently blends them into the word \u{2014} best for new readers. **Both** says the name, then the sound.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Divider()

                    HStack(spacing: 12) {
                        Image(systemName: "tortoise.fill").foregroundStyle(.secondary)
                        Slider(value: $store.speechRate, in: 0.2...0.5)
                        Image(systemName: "hare.fill").foregroundStyle(.secondary)
                    }
                    Toggle("Say each letter", isOn: $store.soundOnTap)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("Speaks each letter aloud as it's tapped, with a short pause so the child can hear it before the next one.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Toggle("Calm mode", isOn: $store.calmMode)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("Calm mode keeps motion gentle and surfaces solid — good for younger or easily-overwhelmed readers.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func thumbnail(_ id: ThemeID) -> some View {
        VStack(spacing: 8) {
            ZStack {
                ThemeBackground(id: id)
                HStack(spacing: 6) {
                    ForEach(["c", "a", "t"], id: \.self) { l in
                        TileView(letter: l).frame(width: 34, height: 34)
                    }
                }
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(store.id == id ? Color.accentColor : Color.black.opacity(0.08),
                        lineWidth: store.id == id ? 4 : 1))
            .environment(\.theme, id.theme)

            Text(id.displayName)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
}
