import Foundation

/// Where the bricks to count land on a grid of slots. Rows of five let him
/// read six as "five and one" without counting, so the slots are drawn at
/// random, with the drill as the seed so the pile holds still while he looks.
enum CountingLayout {
    static let columns = 4
    static let rows = 3

    static func slots(count: Int, seed: Int) -> [Int] {
        var random = SeededRandom(seed: UInt64(bitPattern: Int64(seed)) &+ 0x9E37)
        let all = Array(0..<(columns * rows))
        return Array(random.shuffled(all).prefix(max(0, min(count, all.count))))
    }
}
