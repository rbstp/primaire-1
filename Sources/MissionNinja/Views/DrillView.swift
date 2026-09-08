import SwiftUI

/// The letters and numbers modes, which are the same screen with different
/// material. He switches between them here rather than going back to the dojo.
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
            DrillDoneView(stars: runner?.stars ?? 0, again: start, leave: { dismiss() })
        } else {
            ProgressView().tint(.ninjaBlade)
        }
    }

    private func layout(runner: DrillRunner, drill: Drill, spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            PromptView(prompt: drill.prompt, seed: drill.id, replay: runner.speakPrompt)
                .padding(.top, spacing)

            ChoiceGrid(
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
            case .spokenLetter, .spokenNumber:
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
        case .bricks: "Combien de briques vois-tu?"
        }
    }
}

private struct ChoiceGrid: View {
    let choices: [DrillChoice]
    let state: (DrillChoice) -> BigChoiceButton.State
    let isEnabled: Bool
    let pick: (DrillChoice) -> Void

    /// Two and three choices sit on one row, four go two by two. Anything else
    /// leaves a hole where a tile should be.
    private var perRow: Int { choices.count == 4 ? 2 : max(choices.count, 1) }

    private var glyphSize: CGFloat { perRow >= 3 ? 58 : 74 }

    private var rows: [[DrillChoice]] {
        stride(from: 0, to: choices.count, by: perRow).map { start in
            Array(choices[start..<min(start + perRow, choices.count)])
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 14) {
                    ForEach(rows[row], id: \.self) { choice in
                        BigChoiceButton(
                            label: choice.label,
                            glyphSize: glyphSize,
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

private struct DrillDoneView: View {
    let stars: Int
    let again: () -> Void
    let leave: () -> Void

    /// The reward at the end of a run: one of the three little scenes, drawn
    /// when the screen appears so the ending is not always the same.
    @State private var celebration = Celebration.draw()

    var body: some View {
        VStack(spacing: 26) {
            CelebrationView(kind: celebration)
                .frame(maxHeight: 200)
            Text("Entraînement terminé!")
                .font(Typography.screenTitle)
                .foregroundStyle(.ninjaCream)
            Label("\(stars) étoiles gagnées", systemImage: "star.fill")
                .font(Typography.counter)
                .foregroundStyle(.ninjaGold)

            VStack(spacing: 12) {
                Button("Encore une fois", action: again)
                    .buttonStyle(NinjaButtonStyle(prominent: true))
                Button("Retour au dojo", action: leave)
                    .buttonStyle(NinjaButtonStyle(prominent: false))
            }
            .padding(.horizontal, 32)
        }
        .padding(24)
    }
}
