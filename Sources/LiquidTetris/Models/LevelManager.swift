import Foundation
import SwiftUI

// MARK: - Level Manager

class LevelManager: ObservableObject, Codable {
    @Published var currentLevel: Int = 1
    @Published var linesInLevel: Int = 0
    @Published var linesForNextLevel: Int = 10
    @Published var totalLines: Int = 0

    @Published var showLevelUp: Bool = false
    @Published var levelUpLevel: Int = 0

    private var linesPerLevel: Int = 10

    init() {}

    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case currentLevel, linesInLevel, linesForNextLevel, totalLines, linesPerLevel
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.containerKeyedBy(CodingKeys.self)
        currentLevel = try container.decode(Int.self, forKey: .currentLevel)
        linesInLevel = try container.decode(Int.self, forKey: .linesInLevel)
        linesForNextLevel = try container.decode(Int.self, forKey: .linesForNextLevel)
        totalLines = try container.decode(Int.self, forKey: .totalLines)
        linesPerLevel = try container.decode(Int.self, forKey: .linesPerLevel)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentLevel, forKey: .currentLevel)
        try container.encode(linesInLevel, forKey: .linesInLevel)
        try container.encode(linesForNextLevel, forKey: .linesForNextLevel)
        try container.encode(totalLines, forKey: .totalLines)
        try container.encode(linesPerLevel, forKey: .linesPerLevel)
    }

    // MARK: - Setup

    func setup(difficulty: DifficultyPreset) {
        linesPerLevel = difficulty.linesPerLevel
        currentLevel = 1
        linesInLevel = 0
        linesForNextLevel = difficulty.linesPerLevel
        totalLines = 0
        showLevelUp = false
    }

    // MARK: - Line Clear

    /// Returns true if level increased
    @discardableResult
    func addLines(_ count: Int) -> Bool {
        totalLines += count
        linesInLevel += count

        if linesInLevel >= linesForNextLevel {
            currentLevel += 1
            linesInLevel -= linesForNextLevel
            linesForNextLevel = linesPerLevel
            showLevelUpNotification()
            return true
        }
        return false
    }

    // MARK: - Level Up Notification

    private func showLevelUpNotification() {
        levelUpLevel = currentLevel
        showLevelUp = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showLevelUp = false
        }
    }

    // MARK: - Visual Intensity

    /// 0.0 at level 1, approaches 1.0 at high levels — used for background effects
    var intensity: Double {
        min(1.0, Double(currentLevel) / 30.0)
    }

    /// True every 5 levels — triggers milestone visual effects
    var isMilestone: Bool {
        currentLevel > 1 && currentLevel % 5 == 0
    }

    // MARK: - Drop Interval

    func dropInterval(for difficulty: DifficultyPreset) -> TimeInterval {
        return difficulty.dropInterval(level: currentLevel)
    }

    // MARK: - Reset

    func reset() {
        currentLevel = 1
        linesInLevel = 0
        linesForNextLevel = linesPerLevel
        totalLines = 0
        showLevelUp = false
    }
}
