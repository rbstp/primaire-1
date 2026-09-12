import SwiftUI

struct RootView: View {
    let catalog: WeekCatalog
    let curriculum: CurriculumCatalog

    @Environment(\.scenePhase) private var scenePhase

    @State private var store = ProgressStore()
    @State private var speaker = Speaker()
    @State private var effects = SoundEffects()

    var body: some View {
        NavigationStack {
            content
        }
        .tint(.ninjaBlade)
        .environment(store)
        .environment(speaker)
        .environment(effects)
        .onAppear { store.resume() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.resume()
                return
            }
            store.pause()
            store.flush()
            speaker.stop()
        }
    }

    @ViewBuilder private var content: some View {
        #if DEBUG
        if let requested = DebugScreen.requested, let week = debugWeek {
            debugScreen(requested, week)
        } else {
            journey
        }
        #else
        journey
        #endif
    }

    private var journey: some View {
        SubjectPickerView(catalog: catalog, curriculum: curriculum, today: store.today())
    }

    #if DEBUG
    /// The block named by `-unit`, or the current week. `-screen words` on a
    /// week that carries none falls back to the first block that does, so it
    /// opens on a real run rather than an empty screen.
    private var debugWeek: Week? {
        if let id = DebugScreen.requestedUnit {
            return curriculum.subjects.compactMap { $0.lesson(id) }.first
        }
        let week = catalog.current(on: store.today())
        guard DebugScreen.requested == .words, week?.hasWords != true else { return week }
        return curriculum.subjects
            .flatMap { plan in plan.units.compactMap { plan.lesson($0.id) } }
            .first(where: \.hasWords) ?? week
    }

    @ViewBuilder private func debugScreen(_ screen: DebugScreen, _ week: Week) -> some View {
        switch screen {
        case .dojo: DojoView(week: week, catalog: catalog)
        case .letters: DrillView(week: week, mode: .letters)
        case .numbers: DrillView(week: week, mode: .numbers)
        case .names: DrillView(week: week, mode: .names)
        case .build: NameBuildView(week: week)
        case .summary: WeekSummaryView(catalog: catalog)
        case .parent: ParentView(week: week, catalog: catalog)
        case .vowels: DrillView(week: week, mode: .vowels)
        case .alphabet: AlphabetView(week: week)
        case .trace: TraceModeView(week: week)
        case .log: MissionLogView(week: week)
        case .glyphs: GlyphProofView()
        case .pictures: PictureProofView()
        case .scenes: SceneProofView()
        case .subjects: journey
        case .weeks: WeekPickerView(catalog: catalog)
        case .francais: units(.francais)
        case .maths: units(.mathematiques)
        case .words: DrillView(week: week, mode: .words)
        }
    }

    @ViewBuilder private func units(_ subject: Subject) -> some View {
        if let plan = curriculum.curriculum(for: subject) {
            UnitPickerView(curriculum: plan, catalog: catalog)
        }
    }
    #endif
}
