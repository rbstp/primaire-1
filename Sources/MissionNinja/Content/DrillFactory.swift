import Foundation

/// Builds a session out of a week's material. Distractors always come from the
/// same week, so a session never asks about something the class has not seen.
enum DrillFactory {
    static let drillsPerSession = 10

    enum Mode: String, Sendable {
        case letters
        case numbers
    }

    static func session(
        mode: Mode,
        week: Week,
        progress: Progress,
        random: inout SeededRandom
    ) -> [Drill] {
        switch mode {
        case .letters: letterSession(week: week, progress: progress, random: &random)
        case .numbers: numberSession(week: week, progress: progress, random: &random)
        }
    }

    // MARK: Letters

    private static func letterSession(week: Week, progress: Progress, random: inout SeededRandom) -> [Drill] {
        let pool = week.letters.vowels.characters
        guard !pool.isEmpty else { return [] }
        let width = choiceWidth(for: .hearLetter, progress: progress, poolSize: pool.count)
        var drills: [Drill] = []
        var previous: Character?
        for index in 0..<drillsPerSession {
            let target = pick(from: pool, avoiding: previous, progress: progress, random: &random)
            previous = target
            let choices = choices(target: target, pool: pool, width: width, random: &random)
                .map(DrillChoice.letter)
            drills.append(drill(id: index, kind: .hearLetter, prompt: .spokenLetter(target), choices: choices, answer: .letter(target)))
        }
        return drills
    }

    // MARK: Numbers

    private static func numberSession(week: Week, progress: Progress, random: inout SeededRandom) -> [Drill] {
        let pool = week.numbers.digits
        guard !pool.isEmpty else { return [] }
        let width = choiceWidth(for: .hearNumber, progress: progress, poolSize: pool.count)
        var drills: [Drill] = []
        var previous: Int?
        for index in 0..<drillsPerSession {
            let counting = week.numbers.counting && index.isMultiple(of: 2)
            if counting, let drill = countingDrill(id: index, pool: pool, width: width, avoiding: previous, progress: progress, random: &random) {
                previous = countedValue(of: drill)
                drills.append(drill)
                continue
            }
            let target = pick(from: pool, avoiding: previous, progress: progress, random: &random)
            previous = target
            let choices = choices(target: target, pool: pool, width: width, random: &random)
                .map(DrillChoice.number)
            drills.append(drill(id: index, kind: .hearNumber, prompt: .spokenNumber(target), choices: choices, answer: .number(target)))
        }
        return drills
    }

    /// Counting starts at one, because no shuriken on screen is not a puzzle.
    /// Distractors sit next to the answer so he has to count rather than
    /// eyeball the pile.
    private static func countingDrill(
        id: Int,
        pool: [Int],
        width: Int,
        avoiding previous: Int?,
        progress: Progress,
        random: inout SeededRandom
    ) -> Drill? {
        let countable = pool.filter { (1...9).contains($0) }
        guard !countable.isEmpty else { return nil }
        let target = pick(from: countable, avoiding: previous, progress: progress, random: &random)
        let neighbours = countable
            .filter { $0 != target }
            .sorted { abs($0 - target) < abs($1 - target) }
        var picked = Array(neighbours.prefix(max(width - 1, 1)))
        picked.append(target)
        let choices = random.shuffled(picked).map(DrillChoice.number)
        return drill(id: id, kind: .countObjects, prompt: .shurikens(target), choices: choices, answer: .number(target))
    }

    private static func countedValue(of drill: Drill) -> Int? {
        guard case let .shurikens(count) = drill.prompt else { return nil }
        return count
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
    static func choiceWidth(for kind: DrillKind, progress: Progress, poolSize: Int) -> Int {
        let record = progress.record(for: kind)
        let mastered = record.asked >= 20 && Double(record.solvedFirstTry) / Double(record.asked) >= 0.8
        return min(mastered ? 4 : 3, max(poolSize, 2))
    }

    /// Weighted towards what he gets wrong, with a floor so everything keeps
    /// coming back.
    private static func pick<T: Hashable>(
        from pool: [T],
        avoiding previous: T?,
        progress: Progress,
        random: inout SeededRandom
    ) -> T where T: CustomStringConvertible {
        let candidates = pool.count > 1 ? pool.filter { $0 != previous } : pool
        let weights = candidates.map { weight(of: $0, progress: progress) }
        let total = weights.reduce(0, +)
        guard total > 0 else { return candidates[0] }
        var cut = random.nextDouble(in: 0...total)
        for (candidate, weight) in zip(candidates, weights) {
            cut -= weight
            if cut <= 0 { return candidate }
        }
        return candidates[candidates.count - 1]
    }

    private static func weight<T: CustomStringConvertible>(of value: T, progress: Progress) -> Double {
        let text = String(describing: value)
        guard let character = text.count == 1 ? text.first : nil else { return 1 }
        return 0.25 + progress.record(for: character).weakness
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
