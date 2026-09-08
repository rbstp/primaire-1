import SwiftUI

/// "Je reconnais les voyelles, leur nom et leur bruit." Touch a vowel and it
/// says its name, then a word he knows that starts with it, a different one
/// each time. No score, no pressure: this is the part he explores.
struct LetterWallView: View {
    let week: Week

    @Environment(Speaker.self) private var speaker
    @Environment(SoundEffects.self) private var effects

    @State private var spoken: Character?
    @State private var word = ""
    @State private var random = SeededRandom.fresh()

    private var vowels: [Character] { week.letters.vowels.characters }

    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Touche une voyelle pour entendre son nom et un mot qui commence par elle.")
                        .font(Typography.body)
                        .foregroundStyle(Palette.cream.opacity(0.75).color)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    LazyVGrid(columns: [GridItem(spacing: 14), GridItem(spacing: 14), GridItem(spacing: 14)], spacing: 14) {
                        ForEach(vowels, id: \.self) { vowel in
                            Button { say(vowel) } label: {
                                VowelCard(letter: vowel, isSpeaking: spoken == vowel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)

                    if let spoken {
                        NinjaCard {
                            VStack(spacing: 8) {
                                Text("La lettre \(spoken)")
                                    .font(Typography.sectionTitle)
                                    .foregroundStyle(.ninjaCream)
                                Text("comme dans « \(word) »")
                                    .font(Typography.body)
                                    .foregroundStyle(.ninjaAzure)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Les voyelles")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { speaker.stop() }
    }

    /// Never the same word twice in a row on the same letter.
    private func say(_ vowel: Character) {
        let choices = Pronunciation.exampleWords(for: vowel).filter { $0 != word || spoken != vowel }
        word = random.shuffled(choices).first ?? String(vowel)
        spoken = vowel
        effects.play(.tap)
        speaker.say(Pronunciation.introduction(of: vowel, word: word))
    }
}

private struct BrickFrame: ViewModifier {
    let tone: BrickTone
    let pressed: Bool

    func body(content: Content) -> some View {
        Brick(tone: tone, studs: 3, depth: 9, cornerRadius: 12, pressed: pressed) { content }
    }
}

private struct VowelCard: View {
    let letter: Character
    let isSpeaking: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(String(letter))
                .font(Typography.glyph(52))
            Text(String(letter).uppercased())
                .font(Typography.glyph(26))
                .foregroundStyle(Palette.cream.opacity(0.55).color)
        }
        .foregroundStyle(.ninjaCream)
        .frame(maxWidth: .infinity, minHeight: 104)
        .modifier(BrickFrame(tone: isSpeaking ? .blue : .black, pressed: isSpeaking))
        .animation(.easeOut(duration: 0.15), value: isSpeaking)
        .accessibilityLabel("Lettre \(letter)")
    }
}
