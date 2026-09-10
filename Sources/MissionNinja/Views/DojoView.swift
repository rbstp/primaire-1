import SwiftUI

/// The week's home. Everything he can do sits on one screen, one tap away.
struct DojoView: View {
    let week: Week
    let catalog: WeekCatalog
    let changeWeek: () -> Void

    @Environment(ProgressStore.self) private var store

    @State private var drillMode = DrillFactory.Mode.letters
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
                        tile("Mode Lettres", "textformat.abc", .blue, .letters)
                        tile("Mode Chiffres", "number", .black, .numbers)
                        if !week.names.isEmpty {
                            tile("Mode Prénoms", "person.text.rectangle", .blue, .names)
                            NavigationLink {
                                NameBuildView(week: week)
                            } label: {
                                DojoTile(title: "Construis le prénom", symbol: "puzzlepiece.fill", tone: .black)
                            }
                            .buttonStyle(DojoTileStyle())
                        }
                        if DrillFactory.hasVowelGame(week) {
                            NavigationLink {
                                DrillView(week: week, mode: .constant(.vowels))
                            } label: {
                                DojoTile(title: "Les voyelles", symbol: nil, tone: .blue) {
                                    BrickPictureView(picture: PictureLibrary.dojo.picture)
                                        .frame(height: 64)
                                }
                            }
                            .buttonStyle(DojoTileStyle())
                        }
                        if week.letters.alphabet {
                            NavigationLink {
                                AlphabetView(week: week)
                            } label: {
                                DojoTile(title: "L'alphabet", symbol: nil, tone: .black) {
                                    DragonBuild(done: 1, total: 1, animated: false)
                                        .frame(height: 64)
                                }
                            }
                            .buttonStyle(DojoTileStyle())
                        }
                        if !week.tracing.isEmpty {
                            NavigationLink {
                                TraceModeView(week: week)
                            } label: {
                                DojoTile(title: "Le tracé", symbol: "hand.draw", tone: .blue)
                            }
                            .buttonStyle(DojoTileStyle())
                        }
                        NavigationLink {
                            MissionLogView(week: week)
                        } label: {
                            DojoTile(title: "Mon carnet", symbol: "checklist", tone: .black)
                        }
                        .buttonStyle(DojoTileStyle())
                    }

                    Button("Changer de semaine", action: changeWeek)
                        .buttonStyle(NinjaButtonStyle(prominent: false))
                        .padding(.top, 6)
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

    private func tile(_ title: String, _ symbol: String, _ tone: BrickTone, _ mode: DrillFactory.Mode) -> some View {
        NavigationLink {
            DrillView(week: week, mode: $drillMode)
        } label: {
            DojoTile(title: title, symbol: symbol, tone: tone)
        }
        .buttonStyle(DojoTileStyle())
        .simultaneousGesture(TapGesture().onEnded { drillMode = mode })
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
