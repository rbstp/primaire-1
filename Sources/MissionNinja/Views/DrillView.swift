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
            LinearGradient.ninjaBackdrop.ignoresSafeArea()
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
                ProgressBar(value: runner.advance)
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
            PromptView(prompt: drill.prompt, replay: runner.speakPrompt)
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
                        .foregroundStyle(.ninjaCream)
                        .frame(width: 116, height: 116)
                        .background(LinearGradient.ninjaBlade, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Réécouter")
            case let .shurikens(count):
                ShurikenCluster(count: count)
                    .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 24)
    }

    private var question: String {
        switch prompt {
        case .spokenLetter: "Écoute, puis touche la bonne lettre."
        case .spokenNumber: "Écoute, puis touche le bon chiffre."
        case .shurikens: "Combien de shurikens vois-tu?"
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

private struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { frame in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.slate.color)
                Capsule()
                    .fill(LinearGradient.ninjaBlade)
                    .frame(width: max(8, frame.size.width * value))
            }
        }
        .frame(height: 12)
        .animation(.easeOut(duration: 0.25), value: value)
        .accessibilityLabel("Avancement")
        .accessibilityValue("\(Int(value * 100)) pour cent")
    }
}

private struct DrillDoneView: View {
    let stars: Int
    let again: () -> Void
    let leave: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            NinjaMascot(mood: .happy, size: 140)
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
