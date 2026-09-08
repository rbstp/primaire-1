import SwiftUI

/// The launch screen. The current week is one big button so he can start on
/// his own; the other weeks sit below for when we want to go back over them.
struct WeekPickerView: View {
    let catalog: WeekCatalog
    let today: DayKey
    let choose: (Week) -> Void

    private var current: Week? { catalog.current(on: today) }
    private var others: [Week] { catalog.weeks.filter { $0.id != current?.id } }

    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    header
                    if let current {
                        currentCard(current)
                    } else {
                        NinjaCard {
                            Text("Aucune semaine n'est installée.")
                                .font(Typography.body)
                                .foregroundStyle(.ninjaCream)
                        }
                    }
                    if !others.isEmpty { archive }
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            NinjaMascot(mood: .calm, size: 120, fullBody: true)
            Text("Mission Ninja")
                .font(Typography.screenTitle)
                .foregroundStyle(.ninjaCream)
            Text("Choisis ta semaine d'entraînement")
                .font(Typography.body)
                .foregroundStyle(Palette.cream.opacity(0.7).color)
        }
        .padding(.top, 12)
    }

    private func currentCard(_ week: Week) -> some View {
        NinjaCard(tinted: true) {
            VStack(alignment: .leading, spacing: 14) {
                Label("Semaine en cours", systemImage: "shield.lefthalf.filled")
                    .font(Typography.caption)
                    .foregroundStyle(.ninjaAzure)
                Text(week.title)
                    .font(Typography.sectionTitle)
                    .foregroundStyle(.ninjaCream)
                Text("\(week.grade), \(week.teacher)")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.cream.opacity(0.7).color)
                Button("Commencer l'entraînement") { choose(week) }
                    .buttonStyle(BrickButtonStyle(tone: .azure, minHeight: 56))
            }
        }
    }

    private var archive: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Les semaines passées")
                .font(Typography.caption)
                .foregroundStyle(Palette.cream.opacity(0.6).color)
                .padding(.leading, 4)
            ForEach(others) { week in
                Button { choose(week) } label: {
                    HStack {
                        Text(week.title)
                            .font(Typography.body)
                            .foregroundStyle(.ninjaCream)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.ninjaBlade)
                    }
                    .padding(.horizontal, 16)
                }
                .buttonStyle(BrickButtonStyle(tone: .night, studs: 6, minHeight: 54, cornerRadius: 10))
            }
        }
    }
}
