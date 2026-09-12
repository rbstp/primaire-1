import Foundation

/// The year's plan for every subject, loaded from Resources/Curriculum.
struct CurriculumCatalog: Equatable, Sendable {
    let subjects: [Curriculum]

    init(subjects: [Curriculum]) {
        self.subjects = subjects.sorted { left, right in
            let order = Subject.allCases
            return (order.firstIndex(of: left.subject) ?? 0) < (order.firstIndex(of: right.subject) ?? 0)
        }
    }

    func curriculum(for subject: Subject) -> Curriculum? {
        subjects.first { $0.subject == subject }
    }

    static func decode(from data: [Data]) -> CurriculumCatalog {
        let decoder = JSONDecoder()
        let subjects = data.compactMap { payload -> Curriculum? in
            guard let curriculum = try? decoder.decode(Curriculum.self, from: payload) else { return nil }
            return curriculum.schema <= Curriculum.currentSchema ? curriculum : nil
        }
        return CurriculumCatalog(subjects: subjects)
    }

    static func bundled(in bundle: Bundle = .missionNinja) -> CurriculumCatalog {
        let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: "Curriculum") ?? []
        return decode(from: urls.compactMap { try? Data(contentsOf: $0) })
    }
}
