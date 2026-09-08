import SwiftUI

/// The paper homework, tracked in the app so the whole lesson plan lives in one
/// place. A day off is greyed out with its reason. Each tick pays one star, and
/// only once per task per day.
struct MissionLogView: View {
    let week: Week

    @Environment(ProgressStore.self) private var store
    @Environment(SoundEffects.self) private var effects

    var body: some View {
        ZStack {
            LinearGradient.ninjaBackdrop.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(week.days) { day in
                        DayCard(week: week, day: day, tick: tick, isTicked: store.isTicked, toggle: toggle)
                    }
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Mon carnet")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { store.flush() }
    }

    private func tick(_ day: SchoolDay, _ task: HomeworkTask) -> TaskTick {
        TaskTick(week: week.id, task: task.id, day: dayKey(for: day))
    }

    /// The log is filed under the week's own dates, not today's, so ticking on
    /// Saturday still lands on the right school day.
    private func dayKey(for day: SchoolDay) -> DayKey {
        let offset = week.days.firstIndex(where: { $0.id == day.id }) ?? 0
        guard let monday = week.monday,
              let key = monday.adding(days: offset, in: .current)
        else { return DayKey(year: 0, month: 1, day: 1) }
        return key
    }

    private func toggle(_ tick: TaskTick) {
        effects.play(store.isTicked(tick) ? .tap : .star)
        store.toggle(tick)
    }
}

private struct DayCard: View {
    let week: Week
    let day: SchoolDay
    let tick: (SchoolDay, HomeworkTask) -> TaskTick
    let isTicked: (TaskTick) -> Bool
    let toggle: (TaskTick) -> Void

    var body: some View {
        NinjaCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(day.name.capitalizedFirst)
                        .font(Typography.sectionTitle)
                        .foregroundStyle(day.atSchool ? .ninjaCream : Palette.cream.opacity(0.45).color)
                    Spacer()
                    if !day.atSchool {
                        Text("Congé")
                            .font(Typography.caption)
                            .foregroundStyle(.ninjaGold)
                    }
                }

                if let note = day.note {
                    Label(note, systemImage: day.atSchool ? "info.circle" : "moon.zzz")
                        .font(Typography.caption)
                        .foregroundStyle(.ninjaAzure)
                }

                if day.atSchool {
                    ForEach(week.tasks) { task in
                        TaskRow(
                            task: task,
                            isDone: isTicked(tick(day, task)),
                            toggle: { toggle(tick(day, task)) }
                        )
                    }
                }
            }
        }
        .opacity(day.atSchool ? 1 : 0.65)
    }
}

private struct TaskRow: View {
    let task: HomeworkTask
    let isDone: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(isDone ? Color.ninjaBamboo : Palette.blade.opacity(0.6).color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(Typography.body)
                        .foregroundStyle(.ninjaCream)
                        .strikethrough(isDone, color: Palette.cream.opacity(0.4).color)
                    if let place = task.place {
                        Text(place)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.cream.opacity(0.55).color)
                    }
                }
                Spacer(minLength: 0)
            }
            .multilineTextAlignment(.leading)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isDone ? [.isButton, .isSelected] : .isButton)
    }
}
