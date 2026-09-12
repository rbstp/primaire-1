import SwiftUI

/// The launch screen. The week the teacher handed out is the big button, so
/// he can start on his own; under it the year's plan for each subject, for the
/// evenings we want to go further or back.
struct SubjectPickerView: View {
    let catalog: WeekCatalog
    let curriculum: CurriculumCatalog
    let today: DayKey

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var swordAngle = MinifigBody.restingSwordAngle
    @State private var twirling: Task<Void, Never>?

    private var current: Week? { catalog.current(on: today) }

    var body: some View {
        ZStack {
            Baseplate().ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    header
                    week
                    subjects
                    elsewhere
                }
                .padding(20)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear(perform: twirl)
        .onDisappear {
            twirling?.cancel()
            twirling = nil
        }
    }

    /// The ninja plays with his katana while he waits: a full turn in the
    /// hand to the other side, a breath, and back.
    private func twirl() {
        guard twirling == nil, !reduceMotion else { return }
        twirling = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(1400))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.8)) {
                    swordAngle = swordAngle == MinifigBody.restingSwordAngle
                        ? MinifigBody.twirledSwordAngle
                        : MinifigBody.restingSwordAngle
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            NinjaMascot(mood: .calm, size: 120, fullBody: true, swordAngle: swordAngle)
            Text("Mission Ninja")
                .font(Typography.screenTitle)
                .foregroundStyle(.ninjaCream)
            Text("Choisis ton entraînement")
                .font(Typography.body)
                .foregroundStyle(Palette.cream.opacity(0.7).color)
        }
        .padding(.top, 12)
    }

    @ViewBuilder private var week: some View {
        if let current {
            NinjaCard(tinted: true) {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Semaine en cours", systemImage: "shield.lefthalf.filled")
                        .font(Typography.caption)
                        .foregroundStyle(.ninjaAzure)
                    Text(current.title)
                        .font(Typography.sectionTitle)
                        .foregroundStyle(.ninjaCream)
                    Text("\(current.grade), \(current.teacher)")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.cream.opacity(0.7).color)
                    NavigationLink("Commencer l'entraînement") {
                        DojoView(week: current, catalog: catalog)
                    }
                    .buttonStyle(BrickButtonStyle(tone: .azure, minHeight: 56))
                }
            }
        } else {
            NinjaCard {
                Text("Aucune semaine n'est installée.")
                    .font(Typography.body)
                    .foregroundStyle(.ninjaCream)
            }
        }
    }

    private var subjects: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tout le cursus de l'année")
                .font(Typography.caption)
                .foregroundStyle(Palette.cream.opacity(0.6).color)
                .padding(.leading, 4)
            ForEach(curriculum.subjects) { plan in
                NavigationLink {
                    UnitPickerView(curriculum: plan, catalog: catalog)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: plan.subject.symbol)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.ninjaBlade)
                            .frame(width: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.title)
                                .font(Typography.counter)
                                .foregroundStyle(.ninjaCream)
                            Text("\(plan.units.count) blocs")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.cream.opacity(0.6).color)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.ninjaBlade)
                    }
                    .padding(.horizontal, 16)
                }
                .buttonStyle(BrickButtonStyle(tone: .night, studs: 6, minHeight: 72, cornerRadius: 12))
            }
        }
    }

    private var elsewhere: some View {
        VStack(spacing: 12) {
            if catalog.weeks.count > 1 {
                NavigationLink("Toutes les semaines") {
                    WeekPickerView(catalog: catalog)
                }
                .buttonStyle(NinjaButtonStyle(prominent: false))
            }
            NavigationLink("Bilan des semaines") {
                WeekSummaryView(catalog: catalog)
            }
            .buttonStyle(NinjaButtonStyle(prominent: false))
        }
    }
}
