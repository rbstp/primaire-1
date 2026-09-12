import SwiftUI

/// The week's home. Everything he can do sits on one screen, one tap away.
struct DojoView: View {
    let week: Week
    let catalog: WeekCatalog

    @Environment(ProgressStore.self) private var store

    @State private var showsParentScreen = false

    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    BeltBadge(
                        belt: store.belt,
                        stars: store.thisWeek.stars,
                        advance: store.beltAdvance,
                        streak: store.streak()
                    ) {
                        showsParentScreen = true
                    }

                    Text(week.title)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.cream.opacity(0.65).color)

                    LazyVGrid(columns: [GridItem(spacing: 14), GridItem(spacing: 14)], spacing: 18) {
                        ForEach(Array(activities.enumerated()), id: \.element) { index, activity in
                            NavigationLink {
                                destination(activity)
                            } label: {
                                label(activity, tone: activity.tone ?? (index.isMultiple(of: 2) ? .blue : .black))
                            }
                            .buttonStyle(DojoTileStyle())
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        // The title is drawn in bricks; the plain one only feeds the back
        // button of the screens pushed from here.
        .navigationTitle("Le dojo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                BrickTitle(text: "Le dojo")
            }
        }
        .sheet(isPresented: $showsParentScreen) {
            ParentView(week: week, catalog: catalog)
        }
    }

    /// Only what this week has material for: a block of the year's plan in
    /// French offers no number game, and one in maths no letters and no words.
    private var activities: [Activity] {
        var list = DrillFactory.modes(for: week).map(Activity.drill)
        if !week.names.isEmpty { list.append(.buildName) }
        if DrillFactory.hasVowelGame(week) { list.append(.vowels) }
        if week.letters.alphabet { list.append(.alphabet) }
        if !week.tracing.isEmpty { list.append(.trace) }
        if !week.tasks.isEmpty { list.append(.log) }
        return list
    }

    @ViewBuilder private func destination(_ activity: Activity) -> some View {
        switch activity {
        case let .drill(mode): DrillView(week: week, mode: mode)
        case .buildName: NameBuildView(week: week)
        case .vowels: DrillView(week: week, mode: .vowels)
        case .alphabet: AlphabetView(week: week)
        case .trace: TraceModeView(week: week)
        case .log: MissionLogView(week: week)
        }
    }

    @ViewBuilder private func label(_ activity: Activity, tone: BrickTone) -> some View {
        switch activity {
        case .vowels:
            DojoTile(title: activity.title, symbol: nil, tone: tone) {
                BrickPictureView(picture: PictureLibrary.dojo.picture)
                    .frame(height: 64)
            }
        case .alphabet:
            DojoTile(title: activity.title, symbol: nil, tone: tone) {
                DragonBuild(done: 1, total: 1, animated: false)
                    .frame(height: 64)
            }
        default:
            DojoTile(title: activity.title, symbol: activity.symbol, tone: tone)
        }
    }
}

/// One tile of the dojo. The tones alternate down the grid, so the first one
/// is always the blue brick whatever the week happens to carry.
private enum Activity: Hashable {
    case drill(DrillFactory.Mode)
    case buildName
    case vowels
    case alphabet
    case trace
    case log

    var title: String {
        switch self {
        case let .drill(mode): "Mode \(mode.title)"
        case .buildName: "Construis le prénom"
        case .vowels: "Les voyelles"
        case .alphabet: "L'alphabet"
        case .trace: "Le tracé"
        case .log: "Mon carnet"
        }
    }

    /// The dragon is laid in dark bricks, so its tile stays dark wherever the
    /// alternation would have put it.
    var tone: BrickTone? { self == .alphabet ? .black : nil }

    var symbol: String? {
        switch self {
        case let .drill(mode):
            switch mode {
            case .letters: "textformat.abc"
            case .numbers: "number"
            case .words: "text.book.closed"
            case .names: "person.text.rectangle"
            case .vowels: nil
            }
        case .buildName: "puzzlepiece.fill"
        case .trace: "hand.draw"
        case .log: "checklist"
        case .vowels, .alphabet: nil
        }
    }
}

/// A brick per activity. The press sinks the whole tile, picture included.
private struct DojoTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.dojoTilePressed, configuration.isPressed)
    }
}

private struct DojoTile<Picture: View>: View {
    let title: String
    let symbol: String?
    var tone: BrickTone = .blue
    @ViewBuilder var picture: Picture

    @Environment(\.dojoTilePressed) private var pressed

    init(title: String, symbol: String?, tone: BrickTone) where Picture == EmptyView {
        self.title = title
        self.symbol = symbol
        self.tone = tone
        picture = EmptyView()
    }

    init(title: String, symbol: String?, tone: BrickTone, @ViewBuilder picture: () -> Picture) {
        self.title = title
        self.symbol = symbol
        self.tone = tone
        self.picture = picture()
    }

    var body: some View {
        Brick(tone: tone, studs: 3, depth: 10, cornerRadius: 12, pressed: pressed) {
            VStack(spacing: 10) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(tone == .blue ? Color.ninjaCream : Color.ninjaAzure)
                        .frame(height: 64)
                } else {
                    picture
                }
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(.ninjaCream)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 134)
        }
    }
}

private extension EnvironmentValues {
    @Entry var dojoTilePressed = false
}
