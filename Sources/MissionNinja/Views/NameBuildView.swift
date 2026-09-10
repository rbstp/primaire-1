import SwiftUI

/// "Je me pratique à reconnaître le prénom des amis." A name he hears, its
/// letters shuffled on bricks, and empty slots to click them into, left to
/// right. The name is never written: after two misses the next brick lights
/// up and the voice names its letter. Five names make a run.
struct NameBuildView: View {
    let week: Week

    static let namesPerRun = 5
    static let nextPause = Duration.milliseconds(1600)

    @Environment(Speaker.self) private var speaker
    @Environment(SoundEffects.self) private var effects
    @Environment(ProgressStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var random = SeededRandom.fresh()
    @State private var queue: [String] = []
    @State private var index = 0
    @State private var build: NameBuild?
    @State private var stars = 0
    @State private var starBursts = 0
    @State private var isFinished = false
    @State private var settle: Task<Void, Never>?

    /// A card reads "Mme Sylvie", but a space and an abbreviation are not
    /// letters to put in order.
    private var candidates: [String] { week.names.filter { !$0.contains(" ") } }

    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            if isFinished {
                RunDoneView(stars: stars, again: start, leave: { dismiss() })
            } else if let build {
                ScrollView {
                    content(build)
                        .padding(.vertical, 16)
                        .frame(maxWidth: 620)
                        .frame(maxWidth: .infinity)
                }
            }
            StarBurst(trigger: starBursts)
        }
        .navigationTitle("Construis le prénom")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: start)
        .onDisappear {
            settle?.cancel()
            speaker.stop()
        }
    }

    private func content(_ build: NameBuild) -> some View {
        VStack(spacing: 18) {
            BrickProgress(done: index, total: queue.count)
                .padding(.horizontal, 20)

            Text("Écoute le prénom, puis place ses lettres dans l'ordre.")
                .font(Typography.sectionTitle)
                .foregroundStyle(.ninjaCream)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(action: sayName) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 44, weight: .bold))
            }
            .buttonStyle(StudButtonStyle(diameter: 116))
            .accessibilityLabel("Réécouter le prénom")

            HStack(spacing: 6) {
                ForEach(build.letters.indices, id: \.self) { slot in
                    Slot(letter: build.letter(inSlot: slot), isNext: slot == build.reached && !build.isComplete)
                }
            }
            .padding(.horizontal, 12)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 10)], spacing: 12) {
                ForEach(build.tiles) { tile in
                    Button { touch(tile) } label: {
                        LetterTile(letter: tile.letter, isPlaced: build.isPlaced(tile), isHinted: build.isHinted(tile))
                    }
                    .buttonStyle(.plain)
                    .disabled(build.isPlaced(tile) || build.isComplete)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func start() {
        settle?.cancel()
        isFinished = false
        stars = 0
        index = 0
        queue = Array(random.shuffled(candidates).prefix(NameBuildView.namesPerRun))
        guard !queue.isEmpty else {
            isFinished = true
            return
        }
        build = NameBuild(name: queue[0], random: &random)
        store.markPractised()
        sayName()
    }

    private func sayName() {
        guard let name = build?.name else { return }
        speaker.say(Pronunciation.script(for: .spokenName(name)))
    }

    private func touch(_ tile: NameBuild.Tile) {
        guard var current = build else { return }
        let right = current.touch(tile)
        build = current
        guard right else {
            effects.play(.wrong)
            if current.wantsHint, let expected = current.expected {
                speaker.say(Pronunciation.script(for: .spokenLetter(expected)))
            }
            return
        }
        effects.play(.snap)
        guard current.isComplete else { return }

        // The star lands whatever the misses: at six, finishing is the win.
        // The parent screen is where a hesitant build shows up.
        stars += 1
        starBursts += 1
        effects.play(.star)
        speaker.say([Pronunciation.praise(index), Pronunciation.name(current.name)])
        store.apply(.builtName(clean: current.wasClean))
        settle = Task {
            try? await Task.sleep(for: NameBuildView.nextPause)
            guard !Task.isCancelled else { return }
            next()
        }
    }

    private func next() {
        index += 1
        guard index < queue.count else {
            isFinished = true
            return
        }
        build = NameBuild(name: queue[index], random: &random)
        sayName()
    }
}

/// One place in the name. Empty until its letter is clicked in; the next one
/// to fill is outlined so he knows where he is, never what goes there.
private struct Slot: View {
    let letter: Character?
    let isNext: Bool

    var body: some View {
        ZStack {
            if let letter {
                Brick(tone: .blue, studs: 1, depth: 4, cornerRadius: 6) {
                    GlyphMark(letter, size: 26)
                        .foregroundStyle(.ninjaCream)
                        .frame(width: 36, height: 42)
                }
                .transition(.scale(scale: 1.3).combined(with: .opacity))
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(
                        isNext ? Palette.azure.color : Palette.blade.opacity(0.4).color,
                        style: StrokeStyle(lineWidth: isNext ? 2.5 : 1.5, dash: [5, 4])
                    )
                    .frame(width: 36, height: 42)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
            }
        }
        .animation(.spring(duration: 0.25, bounce: 0.4), value: letter)
        .accessibilityLabel(letter.map { "Lettre \($0)" } ?? "Case vide")
    }
}

private struct LetterTile: View {
    let letter: Character
    let isPlaced: Bool
    let isHinted: Bool

    var body: some View {
        Brick(tone: isPlaced ? .night : .black, studs: 2, depth: 6, cornerRadius: 8, pressed: isPlaced) {
            GlyphMark(letter, size: 30)
                .foregroundStyle(isPlaced ? Palette.cream.opacity(0.3).color : .ninjaCream)
                .frame(maxWidth: .infinity, minHeight: 54)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Palette.azure.color, lineWidth: 3)
                .padding(.top, 9)
                .padding(.bottom, 6)
                .opacity(isHinted ? 1 : 0)
        }
        .animation(.easeOut(duration: 0.25), value: isHinted)
        .accessibilityLabel("Lettre \(letter)")
    }
}
