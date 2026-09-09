import SwiftUI

/// One card per week, newest first: belt, stars, time in the app and how
/// often the first answer was the right one. For the parent, so it is text.
struct WeekSummaryView: View {
    let catalog: WeekCatalog

    @Environment(ProgressStore.self) private var store

    private var keys: [String] {
        let current = store.weekKey()
        return ([current] + store.progress.weekKeys.filter { $0 != current }).sorted(by: >)
    }

    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(keys, id: \.self) { key in
                        WeekCard(
                            title: title(for: key),
                            week: store.progress.week(key),
                            seconds: key == store.weekKey() ? store.secondsThisWeek() : store.progress.week(key).seconds,
                            isCurrent: key == store.weekKey()
                        )
                    }
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Bilan des semaines")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The lesson plan's own title when there is one, else the Monday.
    private func title(for key: String) -> String {
        if let week = catalog.week(id: key) { return week.title }
        guard let monday = DayKey(isoDay: key)?.date(in: .current) else { return key }
        return "Semaine du \(WeekSummaryView.mondayFormat.string(from: monday))"
    }

    private static let mondayFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_CA")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()
}

private struct WeekCard: View {
    let title: String
    let week: WeekProgress
    let seconds: Int
    let isCurrent: Bool

    var body: some View {
        NinjaCard(tinted: isCurrent) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(Typography.sectionTitle)
                    .foregroundStyle(.ninjaCream)
                HStack(spacing: 10) {
                    ShurikenBadge(size: 28, fill: week.belt.paint.color, edge: .ninjaInk)
                    Text(week.belt.name.capitalizedFirst)
                        .font(Typography.counter)
                        .foregroundStyle(.ninjaCream)
                }
                HStack(spacing: 16) {
                    Label("\(week.stars)", systemImage: "star.fill")
                        .foregroundStyle(.ninjaGold)
                    Label(TimeLabel.spent(seconds), systemImage: "clock.fill")
                        .foregroundStyle(isCurrent ? .ninjaCream : .ninjaAzure)
                }
                .font(Typography.body)
                if week.asked > 0 {
                    Text("\(week.solvedFirstTry) sur \(week.asked) du premier coup")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.cream.opacity(0.7).color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
