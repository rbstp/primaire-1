import SwiftUI

/// "Je chante la chanson de l'alphabet." Sing along, where the app walks the
/// alphabet out loud, or find the letters in order among the shuffled bricks.
/// Every letter found lays a brick of the dragon; once whole, the ninja fights it.
struct AlphabetView: View {
    let week: Week

    private static let columns = 5

    @Environment(Speaker.self) private var speaker
    @Environment(SoundEffects.self) private var effects
    @Environment(ProgressStore.self) private var store

    @State private var run: AlphabetRun?
    @State private var random = SeededRandom.fresh()
    @State private var singing: Task<Void, Never>?
    @State private var singingLetter: Character?
    @State private var starBursts = 0

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
                        grid(run)
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
            StarBurst(trigger: starBursts)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("L'alphabet")
        .navigationBarTitleDisplayMode(.inline)
        // A new order every time the section is opened.
        .onAppear {
            run = AlphabetRun(random: &random)
            store.markPractised()
            sayExpected()
        }
        .onDisappear {
            stopSinging()
            speaker.stop()
        }
    }

    /// Explicit rows rather than a grid, so the row holding the letter he is
    /// looking for can light up after two misses.
    private func grid(_ run: AlphabetRun) -> some View {
        let columns = AlphabetView.columns
        let rows = stride(from: 0, to: run.order.count, by: columns).map { start in
            Array(run.order[start..<min(start + columns, run.order.count)])
        }
        let hinted = run.wantsHint ? run.expected.flatMap { run.order.firstIndex(of: $0) }.map { $0 / columns } : nil
        return VStack(spacing: 10) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(rows[row], id: \.self) { letter in
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
                    ForEach(0..<(columns - rows[row].count), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity, minHeight: 1)
                    }
                }
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Palette.azure.opacity(hinted == row ? 0.22 : 0).color)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Palette.azure.opacity(hinted == row ? 0.9 : 0).color, lineWidth: 2.5)
                        )
                }
                .animation(.easeOut(duration: 0.3), value: hinted == row)
            }
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

    /// A star per letter found, like every other exercise: the whole dragon
    /// used to pay a single one, which made the longest game on the dojo the
    /// one that moved the belt the least. A letter pays once per visit, so
    /// finding the a and reshuffling is not a star every second tap.
    private func touch(_ letter: Character) {
        guard var current = run else { return }
        let outcome = current.touch(letter)
        run = current
        switch outcome {
        case .idle:
            effects.play(.tap)
            speaker.say(Pronunciation.letterName(letter))
        case let .missed(expected):
            effects.play(.wrong)
            store.apply(.answered(key: String(expected), drill: .alphabetOrder, firstTry: false, correct: false))
            speaker.say([Utterance("C'est le"), Pronunciation.letterName(letter)])
        case let .found(found, pays):
            effects.play(.snap)
            store.apply(.answered(key: String(found), drill: .alphabetOrder, firstTry: pays, correct: true))
            if current.isComplete {
                effects.play(.belt)
                starBursts += 1
                speaker.say(Pronunciation.praise(0))
            } else {
                sayExpected()
            }
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
            GlyphMark(letter, size: 28)
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
