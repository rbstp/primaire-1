import SwiftUI

/// Behind a three second press on the belt badge. What he is getting right,
/// where he is stuck, and which voice the app actually found.
struct ParentView: View {
    let week: Week

    @Environment(ProgressStore.self) private var store
    @Environment(Speaker.self) private var speaker
    @Environment(\.dismiss) private var dismiss

    @State private var confirmsReset = false

    private var tracked: [Character] {
        var seen: Set<Character> = []
        return (week.letters.vowels.characters + week.numbers.digits.map { Character(String($0)) })
            .filter { seen.insert($0).inserted }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Progression") {
                    row("Ceinture", store.belt.name.capitalizedFirst)
                    row("Étoiles", "\(store.stars)")
                    row("Jours consécutifs", "\(store.streak())")
                }

                Section("Par caractère") {
                    ForEach(tracked, id: \.self) { character in
                        let record = store.progress.record(for: character)
                        HStack {
                            Text(String(character))
                                .font(Typography.glyph(22))
                                .frame(width: 30, alignment: .leading)
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
                }

                Section("Par exercice") {
                    ForEach(DrillKind.allCases, id: \.self) { kind in
                        let record = store.progress.record(for: kind)
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
