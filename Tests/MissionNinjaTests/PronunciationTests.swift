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
        #expect(Pronunciation.letterSound("U") == Pronunciation.letterSound("u"))
    }

    /// The one vowel whose name and sound differ, and the lesson plan asks for
    /// both.
    @Test func separatesTheNameOfYFromItsSound() {
        #expect(Pronunciation.letterName("y").text == "i grec")
        #expect(Pronunciation.letterSound("y").text == "i")
        #expect(Pronunciation.letterName("y") != Pronunciation.letterSound("y"))
    }

    @Test func aVowelNameAndSoundOtherwiseMatch() {
        for vowel in Array("aiou") {
            #expect(Pronunciation.letterName(vowel) == Pronunciation.letterSound(vowel))
        }
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

    /// The prompt is the sound itself, said twice, with nothing spoken around
    /// it: an instruction repeated ten times a session wears out fast.
    @Test func saysALetterSoundTwiceAndNothingElse() {
        let script = Pronunciation.script(for: .spokenLetter("a"))
        #expect(script == [Pronunciation.letterSound("a"), Pronunciation.letterSound("a")])
    }

    @Test func saysANumberTwiceByItsWord() {
        let script = Pronunciation.script(for: .spokenNumber(7))
        #expect(script.map(\.text) == ["sept", "sept"])
    }

    @Test func usesTheVowelSoundNotItsName() {
        #expect(Pronunciation.script(for: .spokenLetter("y")).first == Pronunciation.letterSound("y"))
        #expect(Pronunciation.script(for: .spokenLetter("e")).first?.text == "eu")
    }

    @Test func asksTheCountingQuestionInFrench() {
        let script = Pronunciation.script(for: .shurikens(4))
        #expect(script.count == 1)
        #expect(script[0].text.contains("shurikens"))
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
