import SwiftUI

/// Behind a three second press on the belt badge. What he is getting right
/// this week, where he is stuck, and which voice the app actually found.
struct ParentView: View {
    let week: Week
    let catalog: WeekCatalog

    @Environment(ProgressStore.self) private var store
    @Environment(Speaker.self) private var speaker
    @Environment(\.dismiss) private var dismiss

    @State private var confirmsReset = false

    /// Strings, not characters: a week reaching 10 has no single character
    /// form for it, and forcing one traps.
    private var tracked: [String] {
        var seen: Set<String> = []
        return (week.letters.vowelsAndAccents.map(String.init) + week.numbers.digits.map(String.init))
            .filter { seen.insert($0).inserted }
    }

    var body: some View {
        NavigationStack {
            List {
                let thisWeek = store.thisWeek

                Section("Cette semaine") {
                    row("Ceinture", thisWeek.belt.name.capitalizedFirst)
                    row("Étoiles", "\(thisWeek.stars)")
                    row("Temps dans l'app", TimeLabel.spent(store.secondsThisWeek()))
                    if store.lostAPreviousDocument {
                        Text("Une progression enregistrée n'a pas pu être relue et a été mise de côté. Le compte d'étoiles est donc reparti de zéro.")
                            .font(Typography.caption)
                            .foregroundStyle(.ninjaGold)
                    }
                }

                Section("Depuis le début") {
                    row("Étoiles", "\(store.stars)")
                    row("Jours consécutifs", "\(store.streak())")
                    NavigationLink("Bilan des semaines") {
                        WeekSummaryView(catalog: catalog)
                    }
                    .font(Typography.body)
                }

                Section("Par caractère, à l'écoute, cette semaine") {
                    ForEach(tracked, id: \.self) { key in
                        listening(key, thisWeek.record(for: key), glyph: true)
                    }
                }

                if !week.names.isEmpty {
                    Section("Par prénom, cette semaine") {
                        ForEach(week.names, id: \.self) { name in
                            listening(name, thisWeek.record(for: name), glyph: false)
                        }
                    }
                }

                Section("Tracés, cette semaine") {
                    ForEach(tracked, id: \.self) { key in
                        let times = thisWeek.timesTraced(key)
                        if times > 0 {
                            row(key, "\(thisWeek.timesTracedCleanly(key)) propres sur \(times)")
                        }
                    }
                }

                Section("Par exercice, cette semaine") {
                    ForEach(DrillKind.allCases, id: \.self) { kind in
                        let record = thisWeek.record(for: kind)
                        row(kind.title, record.asked == 0 ? "jamais" : "\(record.solvedFirstTry) sur \(record.asked) du premier coup")
                    }
                }

                Section("Voix") {
                    row("Voix utilisée", speaker.voiceDescription)
                    if !speaker.usesCanadianFrench {
                        Text("Pour une voix québécoise, allez dans Réglages, Accessibilité, Contenu énoncé, Voix, Français (Canada).")
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Réinitialiser la progression", role: .destructive) {
                        confirmsReset = true
                    }
                }
            }
            .navigationTitle("Pour les parents")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .confirmationDialog(
                "Effacer toutes les étoiles et les statistiques?",
                isPresented: $confirmsReset,
                titleVisibility: .visible
            ) {
                Button("Effacer", role: .destructive) {
                    store.reset()
                    dismiss()
                }
                Button("Annuler", role: .cancel) {}
            }
        }
    }

    private func listening(_ label: String, _ record: CharacterRecord, glyph: Bool) -> some View {
        HStack {
            Group {
                if glyph {
                    GlyphMark(label, size: 22)
                } else {
                    Text(label).font(Typography.body)
                }
            }
            .frame(minWidth: 30, alignment: .leading)
            if record.attempts == 0 {
                Text("jamais demandé")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(record.successes) sur \(record.attempts)")
                    .font(Typography.caption)
                Spacer()
                Text("\(Int(record.successRate * 100)) %")
                    .font(Typography.caption)
                    .foregroundStyle(record.successRate >= 0.8 ? Color.ninjaBamboo : .ninjaGold)
            }
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(Typography.body)
    }
}
