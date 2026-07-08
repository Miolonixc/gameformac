import Foundation

// MARK: - Difficulty Preset

enum DifficultyPreset: String, CaseIterable, Codable {
    case easy
    case normal
    case hard

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }

    var icon: String {
        switch self {
        case .easy: return "leaf.fill"
        case .normal: return "flame.fill"
        case .hard: return "bolt.fill"
        }
    }

    var description: String {
        switch self {
        case .easy: return "Relaxed pace, fewer garbage lines"
        case .normal: return "Classic Tetris experience"
        case .hard: return "Fast, aggressive, competitive"
        }
    }

    var baseSpeed: TimeInterval {
        switch self {
        case .easy: return 1.0
        case .normal: return 0.8
        case .hard: return 0.6
        }
    }

    var speedMultiplier: Double {
        switch self {
        case .easy: return 0.03
        case .normal: return 0.05
        case .hard: return 0.08
        }
    }

    var minSpeed: TimeInterval {
        return 0.08
    }

    var garbageMultiplier: Double {
        switch self {
        case .easy: return 0.5
        case .normal: return 1.0
        case .hard: return 1.5
        }
    }

    var lockDelay: TimeInterval {
        switch self {
        case .easy: return 0.7
        case .normal: return 0.5
        case .hard: return 0.3
        }
    }

    var maxLockResets: Int {
        switch self {
        case .easy: return 20
        case .normal: return 15
        case .hard: return 10
        }
    }

    var dasDelay: TimeInterval {
        switch self {
        case .easy: return 0.18
        case .normal: return 0.15
        case .hard: return 0.12
        }
    }

    var dasRepeat: TimeInterval {
        switch self {
        case .easy: return 0.07
        case .normal: return 0.05
        case .hard: return 0.03
        }
    }

    var linesPerLevel: Int {
        switch self {
        case .easy: return 15
        case .normal: return 10
        case .hard: return 8
        }
    }

    func dropInterval(level: Int) -> TimeInterval {
        let interval = baseSpeed - Double(level - 1) * speedMultiplier
        return max(minSpeed, interval)
    }
}
