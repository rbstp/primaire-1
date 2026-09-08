import Foundation

/// Text handed to the synthesiser, with an optional phonetic spelling for the
/// cases where a bare character comes out wrong. The text alone is always
/// correct French, so a voice that ignores the phonetic hint still says the
/// right thing.
struct Utterance: Equatable, Sendable {
    let text: String
    var ipa: String?

    init(_ text: String, ipa: String? = nil) {
        self.text = text
        self.ipa = ipa
    }
}

/// A letter is named the way the class names it ("i grec"), and its sound is
/// taught through a word he knows rather than in isolation: "y fait i" meant
/// nothing to him, "comme dans Yannick" does.
enum Pronunciation {
    static func letterName(_ character: Character) -> Utterance {
        let letter = Character(String(character).lowercased())
        return names[letter] ?? Utterance(String(character))
    }

    /// Words that start with the vowel, for the vowel wall.
    static func exampleWords(for character: Character) -> [String] {
        examples[Character(String(character).lowercased())] ?? []
    }

    /// "La lettre e, comme dans" then "étoile" as its own utterance: in one
    /// phrase the synthesiser liaises "dans étoile" into "dan-zétoile", and he
    /// hears a word that does not start with e.
    static func introduction(of character: Character, word: String) -> [Utterance] {
        [Utterance("La lettre \(letterName(character).text), comme dans"), Utterance(word)]
    }

    static func numberWord(_ value: Int) -> Utterance {
        Utterance(words[value] ?? String(value))
    }

    static func isVowel(_ character: Character) -> Bool {
        "aeiouy".contains(Character(String(character).lowercased()))
    }

    /// Said twice, with no instruction around it: one would be repeated ten
    /// times a session, and the screen already says what to do. A letter is
    /// named as "la lettre a": bare, a one syllable name went by too fast. One
    /// phrase, not two utterances, or the pause between them makes the name
    /// run into the next "la lettre".
    static func script(for prompt: DrillPrompt) -> [Utterance] {
        switch prompt {
        case let .spokenLetter(character):
            let phrase = Utterance("La lettre \(letterName(character).text)")
            return [phrase, phrase]
        case let .spokenNumber(value):
            let word = numberWord(value)
            return [word, word]
        case .bricks:
            return [Utterance("Combien de briques vois-tu?")]
        }
    }

    static func praise(_ index: Int) -> Utterance {
        Utterance(cheers[abs(index) % cheers.count])
    }

    static func correction(_ choice: DrillChoice) -> [Utterance] {
        switch choice {
        case let .letter(character):
            return [Utterance("C'était"), letterName(character)]
        case let .number(value):
            return [Utterance("C'était"), numberWord(value)]
        }
    }

    private static let cheers = [
        "Bravo!",
        "Excellent!",
        "Bien joué, ninja!",
        "C'est exact!",
        "Tu progresses vite!",
        "Parfait!",
    ]

    private static let words: [Int: String] = [
        0: "zéro", 1: "un", 2: "deux", 3: "trois", 4: "quatre",
        5: "cinq", 6: "six", 7: "sept", 8: "huit", 9: "neuf",
        10: "dix",
    ]

    private static let names: [Character: Utterance] = [
        "a": Utterance("a", ipa: "a"),
        "b": Utterance("bé", ipa: "be"),
        "c": Utterance("cé", ipa: "se"),
        "d": Utterance("dé", ipa: "de"),
        "e": Utterance("e", ipa: "ə"),
        "f": Utterance("effe", ipa: "ɛf"),
        "g": Utterance("gé", ipa: "ʒe"),
        "h": Utterance("hache", ipa: "aʃ"),
        "i": Utterance("i", ipa: "i"),
        "j": Utterance("ji", ipa: "ʒi"),
        "k": Utterance("ka", ipa: "ka"),
        "l": Utterance("elle", ipa: "ɛl"),
        "m": Utterance("emme", ipa: "ɛm"),
        "n": Utterance("enne", ipa: "ɛn"),
        "o": Utterance("o", ipa: "o"),
        "p": Utterance("pé", ipa: "pe"),
        "q": Utterance("qu", ipa: "ky"),
        "r": Utterance("erre", ipa: "ɛʁ"),
        "s": Utterance("esse", ipa: "ɛs"),
        "t": Utterance("té", ipa: "te"),
        "u": Utterance("u", ipa: "y"),
        "v": Utterance("vé", ipa: "ve"),
        "w": Utterance("double vé", ipa: "dubləve"),
        "x": Utterance("ixe", ipa: "iks"),
        "y": Utterance("i grec", ipa: "iɡʁɛk"),
        "z": Utterance("zède", ipa: "zɛd"),
    ]

    /// Four words each, every one starting with the letter, accent or not:
    /// the point is to see the letter open a word he knows. No igloo: the
    /// voice reads it "iglou".
    private static let examples: [Character: [String]] = [
        "a": ["avion", "ananas", "abeille", "arbre"],
        "e": ["éléphant", "école", "étoile", "escargot"],
        "i": ["insecte", "image", "iguane", "île"],
        "o": ["orange", "olive", "otarie", "oiseau"],
        "u": ["usine", "univers", "uniforme", "ustensile"],
        "y": ["Yannick", "yoyo", "yogourt", "yéti"],
    ]
}
