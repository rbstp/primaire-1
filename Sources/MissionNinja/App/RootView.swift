import SwiftUI

struct RootView: View {
    let catalog: WeekCatalog

    @Environment(\.scenePhase) private var scenePhase

    @State private var store = ProgressStore()
    @State private var speaker = Speaker()
    @State private var effects = SoundEffects()
    @State private var week: Week?

    var body: some View {
        NavigationStack {
            content
        }
        .tint(.ninjaBlade)
        .environment(store)
        .environment(speaker)
        .environment(effects)
        .onChange(of: scenePhase) { _, phase in
            guard phase != .active else { return }
            store.flush()
            speaker.stop()
        }
    }

    @ViewBuilder private var content: some View {
        #if DEBUG
        if let requested = DebugScreen.requested, let week = catalog.current(on: store.today()) {
            debugScreen(requested, week)
        } else {
            journey
        }
        #else
        journey
        #endif
    }

    @ViewBuilder private var journey: some View {
        if let week {
            DojoView(week: week) { self.week = nil }
        } else {
            WeekPickerView(catalog: catalog, today: store.today()) { week = $0 }
        }
    }

    #if DEBUG
    @ViewBuilder private func debugScreen(_ screen: DebugScreen, _ week: Week) -> some View {
        switch screen {
        case .dojo: DojoView(week: week) {}
        case .letters: DrillView(week: week, mode: .constant(.letters))
        case .numbers: DrillView(week: week, mode: .constant(.numbers))
        case .vowels: LetterWallView(week: week)
        case .alphabet: AlphabetView(week: week)
        case .trace: TraceModeView(week: week)
        case .log: MissionLogView(week: week)
        case .glyphs: GlyphProofView()
        }
    }
    #endif
}
