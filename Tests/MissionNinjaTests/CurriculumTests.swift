import Foundation
import Testing

@testable import MissionNinja

@Suite struct CurriculumTests {
    private let catalog = CurriculumCatalog.bundled()

    private func plan(_ subject: Subject) throws -> Curriculum {
        try #require(catalog.curriculum(for: subject))
    }

    @Test func shipsBothSubjectsInOrder() {
        #expect(catalog.subjects.map(\.subject) == [.francais, .mathematiques])
    }

    @Test func coversTheWholeSchoolYear() throws {
        #expect(try plan(.francais).units.count == 36)
        #expect(try plan(.mathematiques).units.count == 11)
    }

    @Test func everyUnitHasItsOwnIdentifier() throws {
        for subject in Subject.allCases {
            let ids = try plan(subject).units.map(\.id)
            #expect(Set(ids).count == ids.count)
        }
    }

    /// A unit with nothing to drill would open a dojo with no tile on it.
    @Test func everyUnitIsPlayable() throws {
        for subject in Subject.allCases {
            let curriculum = try plan(subject)
            for unit in curriculum.units {
                let lesson = try #require(curriculum.lesson(unit.id))
                #expect(lesson.hasLetters || lesson.hasNumbers || lesson.hasWords, "\(unit.id)")
            }
        }
    }

    /// Under three words the drill is a coin toss, so a unit carries none or
    /// enough. Two of the 36 blocks fall short and show no word tile.
    @Test func aUnitPutsEnoughWordsOnTheTableOrNone() throws {
        let short = try plan(.francais).units.filter {
            !$0.words.isEmpty && $0.words.all.count < WordPlan.playable
        }
        #expect(short.map(\.id) == ["fr-02", "fr-25"])
    }

    /// Two tiles a child cannot tell apart make the drill unanswerable, by ear
    /// or by eye.
    @Test func noUnitRepeatsAWordOrItsSpokenForm() throws {
        for unit in try plan(.francais).units {
            let words = unit.sight + unit.decode
            #expect(Set(words).count == words.count, "\(unit.id)")
            let spoken = words.map { Pronunciation.word($0).text }
            #expect(Set(spoken).count == spoken.count, "\(unit.id)")
        }
    }

    /// The letters pile up over the year: by December the class has met them
    /// all, and a decoy he has never seen is not a decoy.
    @Test func lettersAreCumulative() throws {
        let curriculum = try plan(.francais)
        let first = try #require(curriculum.lesson("fr-01"))
        let third = try #require(curriculum.lesson("fr-03"))
        #expect(first.letters.vowels.characters == ["a", "e", "i", "o", "u", "y"])
        #expect(third.letters.vowels.characters == ["a", "e", "i", "o", "u", "y", "f", "j", "é", "l", "r", "s"])
        for letter in first.letters.vowels.characters {
            #expect(third.letters.vowels.characters.contains(letter))
        }
    }

    /// A digraph names no letter of its own, so it stays out of the listening
    /// game and lives in the unit's title.
    @Test func keepsDigraphsOutOfTheLetters() throws {
        let curriculum = try plan(.francais)
        let third = try #require(curriculum.lesson("fr-03"))
        let fourth = try #require(curriculum.lesson("fr-04"))
        #expect(fourth.title.contains("ou, eu"))
        #expect(fourth.letters.vowels.characters == third.letters.vowels.characters)
    }

    /// Every letter the game can name, and every glyph it can ask him to draw.
    @Test func namesAndDrawsEveryLetterItTeaches() throws {
        let curriculum = try plan(.francais)
        let last = try #require(curriculum.lesson("fr-36"))
        for letter in last.letters.vowels.characters {
            #expect(!Pronunciation.letterName(letter).text.isEmpty)
        }
        for glyph in last.tracing.characters {
            #expect(GlyphLibrary.spec(for: glyph) != nil, "\(glyph)")
        }
    }

    @Test func aFrenchUnitHoldsNoNumbers() throws {
        let lesson = try #require(try plan(.francais).lesson("fr-12"))
        #expect(!lesson.hasNumbers)
        #expect(lesson.numbers.digits.isEmpty)
        #expect(lesson.letters.alphabet)
        #expect(lesson.words.all.contains("lapin"))
    }

    @Test func aMathsUnitHoldsNoLettersAndNoWords() throws {
        let lesson = try #require(try plan(.mathematiques).lesson("ma-40"))
        #expect(!lesson.hasLetters)
        #expect(!lesson.hasWords)
        #expect(!lesson.letters.alphabet)
        #expect(lesson.numbers.digits == Array(0...49))
        #expect(lesson.numbers.focused == Array(40...49))
    }

    /// The digits are the first block's business, and counting stops where the
    /// bricks stop being countable.
    @Test func startsMathsOnTheDigits() throws {
        let curriculum = try plan(.mathematiques)
        let first = try #require(curriculum.lesson("ma-00"))
        #expect(first.numbers.digits == Array(0...9))
        #expect(first.numbers.counting)
        #expect(first.tracing.characters == Array("0123456789"))
        #expect(try #require(curriculum.lesson("ma-90")).numbers.counting == false)
    }

    /// A unit spells out only what it has. Swift's synthesised decoder ignores
    /// default values and would demand every key, which silently dropped the
    /// whole file.
    @Test func decodesAUnitThatSpellsOutOnlyWhatItHas() throws {
        let payload = Data(#"{"schema":1,"subject":"francais","title":"x","units":[{"id":"u","title":"t"}]}"#.utf8)
        let curriculum = try #require(CurriculumCatalog.decode(from: [payload]).subjects.first)
        let unit = try #require(curriculum.units.first)
        #expect(unit.focus == nil)
        #expect(unit.sounds.isEmpty)
        #expect(unit.words.isEmpty)
        #expect(unit.numbers == nil)
        #expect(unit.tracing.isEmpty)
    }

    @Test func skipsAFileFromAFutureSchema() {
        let payload = Data(#"{"schema":99,"subject":"francais","title":"x","units":[]}"#.utf8)
        #expect(CurriculumCatalog.decode(from: [payload]).subjects.isEmpty)
    }

    @Test func hasNoLessonForAnUnknownUnit() throws {
        #expect(try plan(.francais).lesson("fr-99") == nil)
    }
}
