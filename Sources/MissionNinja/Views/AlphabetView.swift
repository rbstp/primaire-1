import SwiftUI

/// "Je chante la chanson de l'alphabet." Sing along, where the app walks the
/// alphabet out loud, or find the letters in order among the shuffled bricks.
/// Every letter found lays a brick of the dragon; once whole, the ninja fights it.
struct AlphabetView: View {
    let week: Week

    @Environment(Speaker.self) private var speaker
    @Environment(SoundEffects.self) private var effects
    @Environment(ProgressStore.self) private var store

    @State private var run: AlphabetRun?
    @State private var random = SeededRandom.fresh()
    @State private var singing: Task<Void, Never>?
    @State private var singingLetter: Character?

    var body: some View {
        ZStack(alignment: .top) {
            Baseplate().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    if let run {
                        DragonScene(
                            done: run.reached,
                            total: run.letters.count,
                            onRoar: { effects.play(.roar) },
                            onSlash: { effects.play(.stroke) }
                        )
                        .frame(maxHeight: 230)
                        .padding(.horizontal, 24)
                    }

                    HStack(spacing: 14) {
                        Text(instruction)
                            .font(Typography.body)
                            .foregroundStyle(Palette.cream.opacity(0.75).color)
                            .multilineTextAlignment(.leading)
                        if run?.expected != nil, singing == nil {
                            Button(action: sayExpected) {
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.system(size: 22, weight: .bold))
                            }
                            .buttonStyle(StudButtonStyle(diameter: 54))
                            .accessibilityLabel("Réécouter la lettre à trouver")
                        }
                    }
                    .padding(.horizontal, 24)

                    if let run {
                        LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 5), spacing: 10) {
                            ForEach(run.order.indices, id: \.self) { position in
                                let letter = run.order[position]
                                Button { touch(letter) } label: {
                                    AlphabetCell(
                                        letter: letter,
                                        isDone: run.isDone(letter),
                                        isSinging: singingLetter == letter
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(singing != nil)
                            }
                        }
                        .padding(.horizontal, 18)
                    }

                    Button(singing == nil ? "Chante avec moi" : "Arrête la chanson") {
                        singing == nil ? sing() : stopSinging()
                    }
                    .buttonStyle(NinjaButtonStyle(prominent: true))
                    .padding(.horizontal, 30)

                    if run?.reached ?? 0 > 0 {
                        Button("Mélanger et recommencer", action: restart)
                            .buttonStyle(NinjaButtonStyle(prominent: false))
                            .padding(.horizontal, 30)
                    }
                }
                .padding(.vertical, 20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("L'alphabet")
        .navigationBarTitleDisplayMode(.inline)
        // A new order every time the section is opened.
        .onAppear {
            run = AlphabetRun(random: &random)
            sayExpected()
        }
        .onDisappear {
            stopSinging()
            speaker.stop()
        }
    }

    /// The letter is never written here: he cannot read, but he can match one
    /// glyph against the grid, which is the whole exercise.
    private var instruction: String {
        guard let run else { return "" }
        return run.expected == nil ? "Le dragon est fini!" : "Écoute, puis trouve la lettre."
    }

    /// The letter to look for is spoken, never outlined: an outline would hand
    /// him the answer.
    private func sayExpected() {
        guard let expected = run?.expected else { return }
        speaker.say(Pronunciation.script(for: .spokenLetter(expected)))
    }

    private func touch(_ letter: Character) {
        guard var current = run else { return }
        let right = current.touch(letter)
        run = current
        guard right else {
            effects.play(.wrong)
            speaker.say([Utterance("C'est le"), Pronunciation.letterName(letter)])
            return
        }
        effects.play(.snap)
        if current.isComplete {
            effects.play(.belt)
            speaker.say(Pronunciation.praise(0))
            store.apply(.answered(key: String(letter), drill: .alphabetOrder, firstTry: true, correct: true))
        } else {
            sayExpected()
        }
    }

    private func restart() {
        guard var current = run else { return }
        current.restart(random: &random)
        run = current
        sayExpected()
    }

    private func sing() {
        singingLetter = nil
        let letters = run?.letters ?? LetterPlan.frenchAlphabet
        singing = Task {
            for letter in letters {
                guard !Task.isCancelled else { break }
                singingLetter = letter
                speaker.say(Pronunciation.letterName(letter))
                try? await Task.sleep(for: .milliseconds(680))
            }
            singingLetter = nil
            singing = nil
        }
    }

    private func stopSinging() {
        singing?.cancel()
        singing = nil
        singingLetter = nil
        speaker.stop()
    }
}

private struct AlphabetCell: View {
    let letter: Character
    let isDone: Bool
    let isSinging: Bool

    var body: some View {
        Brick(tone: tone, studs: 2, depth: 5, cornerRadius: 7, pressed: isDone) {
            Text(String(letter))
                .font(Typography.glyph(28))
                .foregroundStyle(isDone ? Palette.cream.opacity(0.45).color : .ninjaCream)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .animation(.easeOut(duration: 0.15), value: isSinging)
        .accessibilityLabel("Lettre \(letter)")
    }

    /// A found letter sinks into the plate, greyed: it has gone into the dragon.
    private var tone: BrickTone {
        if isSinging { return .azure }
        if isDone { return .night }
        return .black
    }
}
