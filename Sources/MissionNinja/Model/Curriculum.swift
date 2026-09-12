import Foundation

/// The two subjects the year is taught in. The dojo trains one unit at a
/// time, so a French unit never offers a number game and the other way round.
enum Subject: String, Codable, CaseIterable, Sendable, Identifiable {
    case francais
    case mathematiques

    var id: String { rawValue }

    var title: String {
        switch self {
        case .francais: "Français"
        case .mathematiques: "Mathématiques"
        }
    }

    var symbol: String {
        switch self {
        case .francais: "textformat.abc"
        case .mathematiques: "number"
        }
    }
}

/// The words a unit puts on the table. Mots éclair are memorised whole, mots
/// à décoder are sounded out, and the game treats them alike: both are heard
/// and pointed at.
struct WordPlan: Codable, Equatable, Sendable {
    var sight: [String] = []
    var decode: [String] = []

    init(sight: [String] = [], decode: [String] = []) {
        self.sight = sight
        self.decode = decode
    }

    /// Written out because Swift's synthesised decoder ignores the default
    /// values above and demands every key.
    init(from decoder: any Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        sight = try box.decodeIfPresent([String].self, forKey: .sight) ?? []
        decode = try box.decodeIfPresent([String].self, forKey: .decode) ?? []
    }

    /// Under three the drill is a coin toss, so the tile stays hidden.
    static let playable = 3

    var isEmpty: Bool { sight.isEmpty && decode.isEmpty }

    var all: [String] {
        var seen: Set<String> = []
        return (sight + decode).filter { seen.insert($0).inserted }
    }
}

/// One block of the year's plan, as the teacher hands it out: the sounds it
/// teaches, the words it puts on the table, and for maths the slice of the
/// number grid it reads.
struct CurriculumUnit: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    /// What the unit is about, under its title: "ou, eu", "les chiffres".
    var focus: String?
    /// The graphemes taught, single letters and digraphs alike.
    var sounds: [String] = []
    var sight: [String] = []
    var decode: [String] = []
    var numbers: NumberPlan?
    var tracing: GlyphList = GlyphList([])

    /// Written out for the same reason as WordPlan: a unit only spells out
    /// what it has, and the synthesised decoder would demand every key.
    init(from decoder: any Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        id = try box.decode(String.self, forKey: .id)
        title = try box.decode(String.self, forKey: .title)
        focus = try box.decodeIfPresent(String.self, forKey: .focus)
        sounds = try box.decodeIfPresent([String].self, forKey: .sounds) ?? []
        sight = try box.decodeIfPresent([String].self, forKey: .sight) ?? []
        decode = try box.decodeIfPresent([String].self, forKey: .decode) ?? []
        numbers = try box.decodeIfPresent(NumberPlan.self, forKey: .numbers)
        tracing = try box.decodeIfPresent(GlyphList.self, forKey: .tracing) ?? GlyphList([])
    }

    var words: WordPlan { WordPlan(sight: sight, decode: decode) }

    /// The sounds written with one letter. A digraph names no letter of its
    /// own, so it stays out of the listening game and lives in the title.
    var letters: [Character] { sounds.compactMap { $0.count == 1 ? $0.first : nil } }
}

/// A subject's whole year, in order.
struct Curriculum: Codable, Equatable, Sendable, Identifiable {
    let schema: Int
    let subject: Subject
    let title: String
    let units: [CurriculumUnit]

    static let currentSchema = 1

    var id: String { subject.rawValue }

    func unit(id: String) -> CurriculumUnit? {
        units.first { $0.id == id }
    }

    /// What one unit trains, in the shape the dojo already knows. Letters are
    /// cumulative: by then the class has met them all, and a decoy he has
    /// never seen is not a decoy.
    func lesson(_ id: String) -> Week? {
        guard let end = units.firstIndex(where: { $0.id == id }) else { return nil }
        let unit = units[end]
        var seen: Set<Character> = []
        let taught = units[...end].flatMap(\.letters).filter { seen.insert($0).inserted }
        let tracing = unit.tracing.isEmpty
            ? GlyphList(taught.filter { GlyphLibrary.spec(for: $0) != nil })
            : unit.tracing
        return Week(
            schema: Week.currentSchema,
            id: unit.id,
            title: [unit.title, unit.focus].compactMap { $0 }.joined(separator: " : "),
            grade: "1re année",
            teacher: "Mme Catherine",
            days: [],
            letters: LetterPlan(vowels: GlyphList(taught), alphabet: subject == .francais),
            numbers: unit.numbers ?? .none,
            tracing: tracing,
            words: unit.words,
            names: [],
            tasks: []
        )
    }
}
