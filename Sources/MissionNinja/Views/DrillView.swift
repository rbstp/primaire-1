import SwiftUI

/// The letters, numbers and names modes, which are the same screen with
/// different material. He switches between them here rather than going back
/// to the dojo.
struct DrillView: View {
    let week: Week
    @Binding var mode: DrillFactory.Mode

    @Environment(ProgressStore.self) private var store
    @Environment(Speaker.self) private var speaker
    @Environment(SoundEffects.self) private var effects
    @Environment(\.dismiss) private var dismiss

    @State private var runner: DrillRunner?

    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            content
            if let runner {
                StarBurst(trigger: runner.starBursts)
            }
        }
        .navigationTitle("Entraînement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: start)
        .onChange(of: mode) { start() }
        .onDisappear { runner?.stop() }
    }

    @ViewBuilder private var content: some View {
        if let runner, let drill = runner.shown {
            VStack(spacing: 14) {
                modePicker
                    .padding(.horizontal, 20)
                BrickProgress(done: runner.settled, total: runner.total)
                    .padding(.horizontal, 20)

                ViewThatFits(in: .vertical) {
                    layout(runner: runner, drill: drill, spacing: 26)
                    ScrollView { layout(runner: runner, drill: drill, spacing: 16) }
                }
            }
            .padding(.top, 10)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        } else if runner?.isFinished == true {
            RunDoneView(stars: runner?.stars ?? 0, again: start, leave: { dismiss() })
        } else {
            ProgressView().tint(.ninjaBlade)
        }
    }

    private func layout(runner: DrillRunner, drill: Drill, spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            PromptView(prompt: drill.prompt, seed: drill.id, replay: runner.speakPrompt)
                .padding(.top, spacing)

            ChoiceGrid(
                kind: drill.kind,
                choices: drill.choices,
                state: runner.state(of:),
                isEnabled: !runner.isWaiting,
                pick: runner.choose
            )
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
    }

    /// In the body rather than the toolbar: beside an inline title it was
    /// cramped, and it is something he taps, so it should be big.
    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            Text("Lettres").tag(DrillFactory.Mode.letters)
            Text("Chiffres").tag(DrillFactory.Mode.numbers)
            if !week.names.isEmpty {
                Text("Prénoms").tag(DrillFactory.Mode.names)
            }
        }
        .pickerStyle(.segmented)
    }

    private func start() {
        runner?.stop()
        let fresh = DrillRunner(mode: mode, week: week, store: store, speaker: speaker, effects: effects)
        runner = fresh
        fresh.begin()
    }
}

private struct PromptView: View {
    let prompt: DrillPrompt
    let seed: Int
    let replay: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text(question)
                .font(Typography.sectionTitle)
                .foregroundStyle(.ninjaCream)
                .multilineTextAlignment(.center)

            switch prompt {
            case .spokenLetter, .spokenNumber, .spokenName:
                Button(action: replay) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 44, weight: .bold))
                }
                .buttonStyle(StudButtonStyle(diameter: 116))
                .accessibilityLabel("Réécouter")
            case let .bricks(count):
                BrickCluster(count: count, seed: seed)
                    .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 24)
    }

    /// School words: a chiffre goes from 0 to 9, anything past that is a nombre.
    private var question: String {
        switch prompt {
        case .spokenLetter: "Écoute, puis touche la bonne lettre."
        case let .spokenNumber(value): value <= 9 ? "Écoute, puis touche le bon chiffre." : "Écoute, puis touche le bon nombre."
        case .spokenName: "Écoute, puis touche le bon prénom."
        case .bricks: "Combien de briques vois-tu?"
        }
    }
}

private struct ChoiceGrid: View {
    let kind: DrillKind
    let choices: [DrillChoice]
    let state: (DrillChoice) -> BigChoiceButton.State
    let isEnabled: Bool
    let pick: (DrillChoice) -> Void

    private var isNames: Bool { kind == .hearName }

    /// Names stack one per row so five can be read left to right. Two and
    /// three glyphs sit on one row, four go two by two. Anything else leaves
    /// a hole where a tile should be.
    private var perRow: Int {
        if isNames { return 1 }
        return choices.count == 4 ? 2 : max(choices.count, 1)
    }

    private var glyphSize: CGFloat {
        if isNames { return 34 }
        return perRow >= 3 ? 58 : 74
    }

    private var rows: [[DrillChoice]] {
        stride(from: 0, to: choices.count, by: perRow).map { start in
            Array(choices[start..<min(start + perRow, choices.count)])
        }
    }

    var body: some View {
        VStack(spacing: isNames ? 10 : 14) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 14) {
                    ForEach(rows[row], id: \.self) { choice in
                        BigChoiceButton(
                            label: choice.label,
                            glyphSize: glyphSize,
                            minHeight: isNames ? 62 : 104,
                            state: state(choice),
                            isEnabled: isEnabled
                        ) {
                            pick(choice)
                        }
                    }
                }
            }
        }
    }
}

/// One small brick per drill, clicked into a row as they are settled.
struct BrickProgress: View {
    let done: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                if index < done {
                    Brick(tone: .blue, studs: 1, depth: 3, cornerRadius: 3) {
                        Color.clear.frame(height: 8)
                    }
                    .transition(.scale(scale: 1.5).combined(with: .opacity))
                } else {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(Palette.blade.opacity(0.4).color, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .frame(height: 8)
                        .padding(.top, 3.6)
                        .padding(.bottom, 3)
                }
            }
        }
        .animation(.spring(duration: 0.3, bounce: 0.4), value: done)
        .accessibilityElement()
        .accessibilityLabel("Avancement")
        .accessibilityValue("\(done) sur \(total)")
    }
}
