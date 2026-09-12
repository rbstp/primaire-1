import Foundation
import Testing

@testable import MissionNinja

@Suite struct PronunciationTests {
    @Test func namesEveryLetterOfTheAlphabet() {
        for letter in LetterPlan.frenchAlphabet {
            let spoken = Pronunciation.letterName(letter)
            #expect(!spoken.text.isEmpty)
            #expect(spoken.ipa != nil)
        }
    }

    /// Two letters that sound the same would make a listening drill unfair.
    @Test func noTwoLettersAreNamedAlike() {
        let names = LetterPlan.frenchAlphabet.map { Pronunciation.letterName($0).text }
        #expect(Set(names).count == names.count)
    }

    @Test func namesTheUppercaseTheSameWay() {
        #expect(Pronunciation.letterName("A") == Pronunciation.letterName("a"))
        #expect(Pronunciation.letterName("Y") == Pronunciation.letterName("y"))
    }

    /// In first grade é and è are letters of their own, named in full.
    @Test func namesTheAccentsTheWayTheClassDoes() {
        #expect(Pronunciation.letterName("é").text == "e accent aigu")
        #expect(Pronunciation.letterName("è").text == "e accent grave")
        #expect(Pronunciation.correction(.letter("é")).last?.text == "e accent aigu")
    }

    @Test func namesYTheWayTheClassDoes() {
        #expect(Pronunciation.letterName("y").text == "i grec")
    }

    @Test func knowsTheVowels() {
        #expect(Array("aeiouy").allSatisfy(Pronunciation.isVowel))
        #expect(!Pronunciation.isVowel("b"))
        #expect(Pronunciation.isVowel("A"))
    }

    @Test func spellsOutEveryNumberToTwenty() {
        let expected = [
            "zéro", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf",
            "dix", "onze", "douze", "treize", "quatorze", "quinze", "seize", "dix-sept", "dix-huit", "dix-neuf", "vingt",
        ]
        #expect((0...20).map { Pronunciation.numberWord($0).text } == expected)
    }

    /// The number grid runs to 100, and it is read in standard French, the
    /// way the class writes it.
    @Test func spellsOutTheWholeNumberGrid() {
        #expect(Pronunciation.numberWord(21).text == "vingt-et-un")
        #expect(Pronunciation.numberWord(30).text == "trente")
        #expect(Pronunciation.numberWord(47).text == "quarante-sept")
        #expect(Pronunciation.numberWord(51).text == "cinquante-et-un")
        #expect(Pronunciation.numberWord(67).text == "soixante-sept")
        #expect(Pronunciation.numberWord(70).text == "soixante-dix")
        #expect(Pronunciation.numberWord(71).text == "soixante-et-onze")
        #expect(Pronunciation.numberWord(72).text == "soixante-douze")
        #expect(Pronunciation.numberWord(80).text == "quatre-vingts")
        #expect(Pronunciation.numberWord(81).text == "quatre-vingt-un")
        #expect(Pronunciation.numberWord(85).text == "quatre-vingt-cinq")
        #expect(Pronunciation.numberWord(96).text == "quatre-vingt-seize")
        #expect(Pronunciation.numberWord(100).text == "cent")
    }

    /// Two numbers said alike would make the listening drill unfair.
    @Test func noTwoNumbersAreSaidAlike() {
        let spoken = (0...100).map { Pronunciation.numberWord($0).text }
        #expect(spoken.allSatisfy { !$0.isEmpty && $0.first?.isNumber != true })
        #expect(Set(spoken).count == spoken.count)
    }

    /// The word, twice, like everything else the voice asks for.
    @Test func saysAWordTwice() {
        let script = Pronunciation.script(for: .spokenWord("maman"))
        #expect(script.map(\.text) == ["maman", "maman"])
        #expect(Pronunciation.correction(.word("maman")).last?.text == "maman")
    }

    /// "ne … pas" is written that way for the eye; read out loud the ellipsis
    /// is noise.
    @Test func doesNotReadTheEllipsisOfANegation() {
        #expect(Pronunciation.word("ne … pas").text == "ne pas")
    }

    @Test func namesTheAccentsTheCurriculumAdds() {
        #expect(Pronunciation.letterName("ê").text == "e accent circonflexe")
        #expect(Pronunciation.letterName("ç").text == "c cédille")
    }

    /// A name, twice, with nothing around it, like a letter or a number.
    @Test func saysANameTwice() {
        let script = Pronunciation.script(for: .spokenName("Zoé"))
        #expect(script.map(\.text) == ["Zoé", "Zoé"])
    }

    /// The card says "Mme", the voice must not.
    @Test func readsMadameInFull() {
        #expect(Pronunciation.name("Mme Sylvie").text == "Madame Sylvie")
        #expect(Pronunciation.name("Mme Sylvie").ipa == nil)
        #expect(Pronunciation.correction(.name("Mme Catherine")).last?.text == "Madame Catherine")
    }

    @Test func spellsTheNamesTheFrenchVoiceMangles() {
        #expect(Pronunciation.name("Hayden").ipa != nil)
        #expect(Pronunciation.name("Zoé").ipa == nil)
    }

    /// "La lettre a", twice, with no instruction around it: an instruction
    /// repeated ten times a session wears out fast.
    @Test func namesTheLetterTwiceAndNothingElse() {
        let script = Pronunciation.script(for: .spokenLetter("a"))
        #expect(script.map(\.text) == ["La lettre a", "La lettre a"])
    }

    @Test func saysANumberTwiceByItsWord() {
        let script = Pronunciation.script(for: .spokenNumber(7))
        #expect(script.map(\.text) == ["sept", "sept"])
    }

    /// The name, not the sound: y is asked as "i grec", the way the class says it.
    @Test func usesTheLetterNameNotItsSound() {
        #expect(Pronunciation.script(for: .spokenLetter("y")).first?.text == "La lettre i grec")
        #expect(Pronunciation.script(for: .spokenLetter("h")).first?.text == "La lettre hache")
    }

    /// The object is named twice and nothing else is said: the picture is the
    /// question, and writing the word would give away its first letter.
    @Test func saysTheObjectTwice() {
        let script = Pronunciation.script(for: .object("abeille"))
        #expect(script.map(\.text) == ["abeille", "abeille"])
    }

    @Test func asksTheCountingQuestionInFrench() {
        let script = Pronunciation.script(for: .bricks(4))
        #expect(script.count == 1)
        #expect(script[0].text.contains("briques"))
    }

    @Test func correctsWithTheLetterName() {
        #expect(Pronunciation.correction(.letter("y")).last?.text == "i grec")
        #expect(Pronunciation.correction(.number(3)).last?.text == "trois")
    }

    @Test func cyclesThroughPraiseWithoutCrashing() {
        let spoken = (0..<20).map { Pronunciation.praise($0).text }
        #expect(spoken.allSatisfy { !$0.isEmpty })
        #expect(Set(spoken).count > 1)
        #expect(Pronunciation.praise(-3).text.isEmpty == false)
    }

    @Test func fallsBackToTheCharacterItself() {
        #expect(Pronunciation.letterName("ß").text == "ß")
        #expect(Pronunciation.numberWord(101).text == "101")
        #expect(Pronunciation.name("Dalya").text == "Dalya")
    }
}
