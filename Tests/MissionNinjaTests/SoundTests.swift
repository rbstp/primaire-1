import Testing

@testable import MissionNinja

@Suite struct SfxTests {
    @Test func everySoundRendersSomething() {
        for sfx in Sfx.allCases {
            let samples = ToneSynth.render(sfx.recipe)
            #expect(!samples.isEmpty, "\(sfx) est muet")
        }
    }

    /// Clipping would come out as a crackle on a small speaker.
    @Test func nothingClips() {
        for sfx in Sfx.allCases {
            let peak = ToneSynth.render(sfx.recipe).map(abs).max() ?? 0
            #expect(peak <= 1, "\(sfx) sature à \(peak)")
            #expect(peak > 0.01, "\(sfx) est inaudible")
        }
    }

    /// These play between drills, so none of them may drag.
    @Test func everySoundIsShort() {
        for sfx in Sfx.allCases {
            let recipe = sfx.recipe
            let seconds = Double(ToneSynth.render(recipe).count) / recipe.sampleRate
            #expect(seconds < 0.8, "\(sfx) dure \(seconds) s")
        }
    }

    /// A miss must read as "try again", never as a buzzer, so it stays quieter
    /// than the reward.
    @Test func aMissIsSofterThanASuccess() {
        let miss = ToneSynth.render(Sfx.wrong.recipe).map(abs).max() ?? 0
        let hit = ToneSynth.render(Sfx.right.recipe).map(abs).max() ?? 0
        #expect(miss < hit)
    }
}
