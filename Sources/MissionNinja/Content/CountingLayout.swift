import Foundation

/// How a pile to count is laid out. Whole fives stand as stacks with a 5 on
/// top, the way the class groups them; what is left lands at random on a grid
/// of slots, with the drill as the seed so the pile holds still while he
/// looks. Rows of loose bricks would let him read six as "five and one".
enum CountingLayout {
    static let stackSize = 5
    static let columns = 3
    static let rows = 2

    static func stacks(count: Int) -> Int { max(count, 0) / stackSize }
    static func loose(count: Int) -> Int { max(count, 0) % stackSize }

    static func slots(count: Int, seed: Int) -> [Int] {
        var random = SeededRandom(seed: UInt64(bitPattern: Int64(seed)) &+ 0x9E37)
        let all = Array(0..<(columns * rows))
        return Array(random.shuffled(all).prefix(max(0, min(count, all.count))))
    }
}
