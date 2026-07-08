import Foundation

// MARK: - Game Mode

enum GameMode: String, CaseIterable, Codable {
    case marathon
    case sprint
    case ultra

    var displayName: String {
        switch self {
        case .marathon: return "Marathon"
        case .sprint: return "Sprint"
        case .ultra: return "Ultra"
        }
    }

    var icon: String {
        switch self {
        case .marathon: return "infinity"
        case .sprint: return "bolt.circle.fill"
        case .ultra: return "timer"
        }
    }

    var description: String {
        switch self {
        case .marathon: return "Endless play. Survive as long as you can."
        case .sprint: return "Clear 40 lines as fast as possible."
        case .ultra: return "2 minutes. Highest score wins."
        }
    }

    var targetLines: Int? {
        switch self {
        case .sprint: return 40
        case .marathon, .ultra: return nil
        }
    }

    var timeLimit: TimeInterval? {
        switch self {
        case .ultra: return 120
        case .marathon, .sprint: return nil
        }
    }

    var showTimer: Bool {
        switch self {
        case .sprint, .ultra: return true
        case .marathon: return false
        }
    }

    var showLineProgress: Bool {
        switch self {
        case .sprint: return true
        case .marathon, .ultra: return false
        }
    }
}
