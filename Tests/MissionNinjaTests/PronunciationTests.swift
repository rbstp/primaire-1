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
        #expect(Pronunciation.exampleWords(for: "Y") == Pronunciation.exampleWords(for: "y"))
    }

    @Test func namesYTheWayTheClassDoes() {
        #expect(Pronunciation.letterName("y").text == "i grec")
    }

    /// Four different words per vowel, each one starting with the letter,
    /// accent or not, so the wall never says "y fait i" to a child for whom
    /// that means nothing.
    @Test func givesFourExampleWordsStartingWithTheVowel() {
        for vowel in Array("aeiouy") {
            let words = Pronunciation.exampleWords(for: vowel)
            #expect(words.count == 4, "\(vowel) a \(words.count) mots")
            #expect(Set(words).count == words.count, "\(vowel) répète un mot")
            for word in words {
                let first = word.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_CA")).first
                #expect(first == vowel, "\(word) ne commence pas par \(vowel)")
            }
        }
    }

    /// The word stands alone, so no liaison can glue a consonant onto it.
    @Test func introducesALetterWithAWordKeptApart() {
        let script = Pronunciation.introduction(of: "e", word: "étoile")
        #expect(script.map(\.text) == ["La lettre e, comme dans", "étoile"])
    }

    @Test func knowsTheVowels() {
        #expect(Array("aeiouy").allSatisfy(Pronunciation.isVowel))
        #expect(!Pronunciation.isVowel("b"))
        #expect(Pronunciation.isVowel("A"))
    }

    @Test func spellsOutEveryDigit() {
        let expected = ["zéro", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf"]
        #expect((0...9).map { Pronunciation.numberWord($0).text } == expected)
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
        #expect(Pronunciation.letterName("é").text == "é")
        #expect(Pronunciation.numberWord(42).text == "42")
    }
}
