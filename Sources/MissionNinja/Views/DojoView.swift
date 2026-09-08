import SwiftUI

/// The week's home. Everything he can do sits on one screen, one tap away.
struct DojoView: View {
    let week: Week
    let changeWeek: () -> Void

    @Environment(ProgressStore.self) private var store

    @State private var drillMode = DrillFactory.Mode.letters
    @State private var showsParentScreen = false

    var body: some View {
        ZStack {
            LinearGradient.ninjaBackdrop.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    BeltBadge(
                        belt: store.belt,
                        stars: store.stars,
                        advance: store.beltAdvance,
                        streak: store.streak()
                    ) {
                        showsParentScreen = true
                    }

                    Text(week.title)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.cream.opacity(0.65).color)

                    LazyVGrid(columns: [GridItem(spacing: 14), GridItem(spacing: 14)], spacing: 14) {
                        tile("Mode Lettres", "textformat.abc", .letters)
                        tile("Mode Chiffres", "number", .numbers)
                        NavigationLink {
                            LetterWallView(week: week)
                        } label: {
                            DojoTile(title: "Les voyelles", symbol: "waveform")
                        }
                        if week.letters.alphabet {
                            NavigationLink {
                                AlphabetView(week: week)
                            } label: {
                                DojoTile(title: "L'alphabet", symbol: "music.note.list")
                            }
                        }
                        if !week.tracing.isEmpty {
                            NavigationLink {
                                TraceModeView(week: week)
                            } label: {
                                DojoTile(title: "Le tracé", symbol: "hand.draw")
                            }
                        }
                        NavigationLink {
                            MissionLogView(week: week)
                        } label: {
                            DojoTile(title: "Mon carnet", symbol: "checklist")
                        }
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
        .navigationTitle("Le dojo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsParentScreen) {
            ParentView(week: week)
        }
    }

    private func tile(_ title: String, _ symbol: String, _ mode: DrillFactory.Mode) -> some View {
        NavigationLink {
            DrillView(week: week, mode: $drillMode)
        } label: {
            DojoTile(title: title, symbol: symbol)
        }
        .simultaneousGesture(TapGesture().onEnded { drillMode = mode })
    }
}

private struct DojoTile: View {
    let title: String
    let symbol: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.ninjaAzure)
            Text(title)
                .font(Typography.body)
                .foregroundStyle(.ninjaCream)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 128)
        .background(Palette.slate.color, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Palette.blade.opacity(0.35).color, lineWidth: 2)
        )
    }
}
