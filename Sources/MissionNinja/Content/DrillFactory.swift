import Foundation

/// Builds a session out of a week's material. Distractors always come from the
/// same week, so a session never asks about something the class has not seen.
enum DrillFactory {
    static let drillsPerSession = 10
    static let nameChoices = 5
    /// How often a number drill stays inside the week's focus range.
    static let focusShare = 0.9
    /// Past this many bricks the pile stops being countable at a glance.
    static let countingLimit = 20

    enum Mode: String, Sendable {
        case letters
        case numbers
        case names
        case words
        case vowels

        var title: String {
            switch self {
            case .letters: "Lettres"
            case .numbers: "Chiffres"
            case .names: "Prénoms"
            case .words: "Mots"
            case .vowels: "Voyelles"
            }
        }
    }

    /// The modes a week has material for, in the order the picker shows them.
    static func modes(for week: Week) -> [Mode] {
        var modes: [Mode] = []
        if week.hasLetters { modes.append(.letters) }
        if week.hasNumbers { modes.append(.numbers) }
        if week.hasWords { modes.append(.words) }
        if week.names.count > 1 { modes.append(.names) }
        return modes
    }

    static func session(
        mode: Mode,
        week: Week,
        progress: WeekProgress,
        random: inout SeededRandom
    ) -> [Drill] {
        switch mode {
        case .letters: letterSession(week: week, progress: progress, random: &random)
        case .numbers: numberSession(week: week, progress: progress, random: &random)
        case .names: nameSession(week: week, progress: progress, random: &random)
        case .words: wordSession(week: week, progress: progress, random: &random)
        case .vowels: vowelSession(week: week, progress: progress, random: &random)
        }
    }

    // MARK: Letters

    private static func letterSession(week: Week, progress: WeekProgress, random: inout SeededRandom) -> [Drill] {
        let pool = week.letters.vowels.characters
        guard !pool.isEmpty else { return [] }
        let width = choiceWidth(for: .hearLetter, progress: progress, poolSize: pool.count)
        var drills: [Drill] = []
        var previous: Character?
        for index in 0..<drillsPerSession {
            let target = pick(from: pool, avoiding: previous, key: String.init, progress: progress, random: &random)
            previous = target
            let choices = choices(target: target, pool: pool, width: width, random: &random)
                .map(DrillChoice.letter)
            drills.append(drill(id: index, kind: .hearLetter, prompt: .spokenLetter(target), choices: choices, answer: .letter(target)))
        }
        return drills
    }

    // MARK: Vowels

    /// Two letters to choose between and one object to show. The dojo hides
    /// its tile without them, so the game can never open on a run that is
    /// already over.
    static func hasVowelGame(_ week: Week) -> Bool {
        let pool = week.letters.vowelsAndAccents
        return pool.count > 1 && pool.contains { !PictureLibrary.words(startingWith: $0).isEmpty }
    }

    /// An object he can name, and the letter its name starts with. The letter
    /// is drawn first, weighted like everywhere else, then a picture for it,
    /// so a letter with three objects is not asked three times as often.
    private static func vowelSession(week: Week, progress: WeekProgress, random: inout SeededRandom) -> [Drill] {
        guard hasVowelGame(week) else { return [] }
        let pool = week.letters.vowelsAndAccents
        let answerable = pool.filter { !PictureLibrary.words(startingWith: $0).isEmpty }
        let width = choiceWidth(for: .pictureLetter, progress: progress, poolSize: pool.count)
        var drills: [Drill] = []
        var previous: Character?
        var shown: Set<String> = []
        for index in 0..<drillsPerSession {
            let target = pick(from: answerable, avoiding: previous, key: String.init, progress: progress, random: &random)
            previous = target
            let pictures = random.shuffled(PictureLibrary.words(startingWith: target))
            guard let word = pictures.first(where: { !shown.contains($0.word) }) ?? pictures.first else { continue }
            shown.insert(word.word)
            let choices = choices(target: target, pool: pool, width: width, random: &random)
                .map(DrillChoice.letter)
            drills.append(drill(id: index, kind: .pictureLetter, prompt: .object(word.word), choices: choices, answer: .letter(target)))
        }
        return drills
    }

    // MARK: Numbers

    private static func numberSession(week: Week, progress: WeekProgress, random: inout SeededRandom) -> [Drill] {
        let pool = week.numbers.digits
        guard !pool.isEmpty else { return [] }
        let width = choiceWidth(for: .hearNumber, progress: progress, poolSize: pool.count)
        // Counting is its own skill, so it widens on its own history rather
        // than on how well he recognises a spoken number.
        let countingWidth = choiceWidth(for: .countObjects, progress: progress, poolSize: pool.count)
        var drills: [Drill] = []
        var previous: Int?
        for index in 0..<drillsPerSession {
            let slice = focused(week.numbers, within: pool, random: &random)
            let counting = week.numbers.counting && index.isMultiple(of: 2)
            if counting, let drill = countingDrill(id: index, pool: slice, width: countingWidth, avoiding: previous, progress: progress, random: &random) {
                previous = countedValue(of: drill)
                drills.append(drill)
                continue
            }
            let target = pick(from: slice, avoiding: previous, key: String.init, progress: progress, random: &random)
            previous = target
            let choices = choices(target: target, pool: slice, width: width, random: &random)
                .map(DrillChoice.number)
            drills.append(drill(id: index, kind: .hearNumber, prompt: .spokenNumber(target), choices: choices, answer: .number(target)))
        }
        return drills
    }

    /// Each drill is drawn from the focus or from the rest of the week, never
    /// from both at once: a 4 among 12, 14 and 17 is dismissed without reading
    /// anything, and so is a 14 among 2, 4 and 7.
    private static func focused(_ plan: NumberPlan, within pool: [Int], random: inout SeededRandom) -> [Int] {
        let focus = plan.focused
        let rest = pool.filter { !focus.contains($0) }
        guard focus.count > 1, rest.count > 1 else { return pool }
        return random.nextUnit() < focusShare ? focus : rest
    }

    /// Counting starts at one, because no brick on screen is not a puzzle.
    /// Distractors sit next to the answer so he has to count rather than
    /// eyeball the pile.
    private static func countingDrill(
        id: Int,
        pool: [Int],
        width: Int,
        avoiding previous: Int?,
        progress: WeekProgress,
        random: inout SeededRandom
    ) -> Drill? {
        let countable = pool.filter { (1...countingLimit).contains($0) }
        guard !countable.isEmpty else { return nil }
        let target = pick(from: countable, avoiding: previous, key: String.init, progress: progress, random: &random)
        let neighbours = countable
            .filter { $0 != target }
            .sorted { abs($0 - target) < abs($1 - target) }
        var picked = Array(neighbours.prefix(max(width - 1, 1)))
        picked.append(target)
        let choices = random.shuffled(picked).map(DrillChoice.number)
        return drill(id: id, kind: .countObjects, prompt: .bricks(target), choices: choices, answer: .number(target))
    }

    private static func countedValue(of drill: Drill) -> Int? {
        guard case let .bricks(count) = drill.prompt else { return nil }
        return count
    }

    // MARK: Names

    /// Always five names: the bus card exercise is about telling a friend's
    /// name from the others, and with fewer the first letter gives it away.
    private static func nameSession(week: Week, progress: WeekProgress, random: inout SeededRandom) -> [Drill] {
        let pool = week.names
        guard pool.count > 1 else { return [] }
        let width = min(nameChoices, pool.count)
        var drills: [Drill] = []
        var previous: String?
        for index in 0..<drillsPerSession {
            let target = pick(from: pool, avoiding: previous, key: { $0 }, progress: progress, random: &random)
            previous = target
            let choices = choices(target: target, pool: pool, width: width, random: &random)
                .map(DrillChoice.name)
            drills.append(drill(id: index, kind: .hearName, prompt: .spokenName(target), choices: choices, answer: .name(target)))
        }
        return drills
    }

    // MARK: Words

    /// The teacher's own "Oreille ouvre-toi": the word is said, its label sits
    /// on the table among others from the same unit, and he points at it.
    /// Never read out loud by him, so it asks nothing he cannot do yet.
    private static func wordSession(week: Week, progress: WeekProgress, random: inout SeededRandom) -> [Drill] {
        let pool = week.words.all
        guard week.hasWords else { return [] }
        let width = min(choiceWidth(for: .hearWord, progress: progress, poolSize: pool.count), pool.count)
        var drills: [Drill] = []
        var previous: String?
        for index in 0..<drillsPerSession {
            let target = pick(from: pool, avoiding: previous, key: { $0 }, progress: progress, random: &random)
            previous = target
            let choices = choices(target: target, pool: pool, width: width, random: &random)
                .map(DrillChoice.word)
            drills.append(drill(id: index, kind: .hearWord, prompt: .spokenWord(target), choices: choices, answer: .word(target)))
        }
        return drills
    }

    // MARK: Shared

    private static func drill(
        id: Int,
        kind: DrillKind,
        prompt: DrillPrompt,
        choices: [DrillChoice],
        answer: DrillChoice
    ) -> Drill {
        Drill(
            id: id,
            kind: kind,
            prompt: prompt,
            choices: choices,
            answerIndex: choices.firstIndex(of: answer) ?? 0
        )
    }

    /// Three choices while he is learning, four once he answers most of them
    /// right on the first try.
    static func choiceWidth(for kind: DrillKind, progress: WeekProgress, poolSize: Int) -> Int {
        let record = progress.record(for: kind)
        let mastered = record.asked >= 20 && Double(record.solvedFirstTry) / Double(record.asked) >= 0.8
        return min(mastered ? 4 : 3, max(poolSize, 2))
    }

    /// Weighted towards what he gets wrong, with a floor so everything keeps
    /// coming back. The stats key is passed in rather than derived from a
    /// description, which silently stopped weighting anything longer than one
    /// character.
    private static func pick<T: Hashable>(
        from pool: [T],
        avoiding previous: T?,
        key: (T) -> String,
        progress: WeekProgress,
        random: inout SeededRandom
    ) -> T {
        let candidates = pool.count > 1 ? pool.filter { $0 != previous } : pool
        let weights = candidates.map { 0.25 + progress.record(for: key($0)).weakness }
        let total = weights.reduce(0, +)
        guard total > 0 else { return candidates[0] }
        var cut = random.nextDouble(in: 0...total)
        for (candidate, weight) in zip(candidates, weights) {
            cut -= weight
            if cut <= 0 { return candidate }
        }
        return candidates[candidates.count - 1]
    }

    private static func choices<T: Hashable>(
        target: T,
        pool: [T],
        width: Int,
        random: inout SeededRandom
    ) -> [T] {
        var decoys = random.shuffled(pool.filter { $0 != target })
        decoys = Array(decoys.prefix(max(width - 1, 0)))
        return random.shuffled(decoys + [target])
    }

}
