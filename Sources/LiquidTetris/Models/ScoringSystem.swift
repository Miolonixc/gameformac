import Foundation

// MARK: - Scoring System

struct ScoringSystem {
    // Base points per lines cleared
    static let linePoints = [0: 0, 1: 100, 2: 300, 3: 500, 4: 800]

    // T-spin bonuses
    static let tSpinMini = 100
    static let tSpinSingle = 400
    static let tSpinDouble = 700
    static let tSpinTriple = 1000

    // Perfect Clear (board is empty after lock)
    static let perfectClear = 3000

    // Back-to-back multiplier
    static let backToBackMultiplier = 1.5

    // Soft drop points per cell
    static let softDropPoint = 1

    // Hard drop points per cell
    static let hardDropPoint = 2

    static func comboMultiplier(combo: Int) -> Double {
        guard combo > 0 else { return 1.0 }
        return 1.0 + Double(combo) * 0.5
    }

    static func calculate(
        linesCleared: Int,
        isTSpin: Bool,
        isMiniTSpin: Bool,
        isPerfectClear: Bool,
        isBackToBack: Bool,
        combo: Int,
        level: Int,
        difficulty: DifficultyPreset
    ) -> Int {
        var basePoints = 0

        // T-spin scoring
        if isTSpin || isMiniTSpin {
            if isMiniTSpin {
                basePoints = tSpinMini
            } else {
                switch linesCleared {
                case 0: basePoints = tSpinMini
                case 1: basePoints = tSpinSingle
                case 2: basePoints = tSpinDouble
                default: basePoints = tSpinTriple
                }
            }
        } else {
            basePoints = linePoints[min(linesCleared, 4)] ?? 0
        }

        // Perfect Clear bonus
        if isPerfectClear {
            basePoints += perfectClear
        }

        // Back-to-back multiplier
        if isBackToBack && (linesCleared == 4 || isTSpin) {
            basePoints = Int(Double(basePoints) * backToBackMultiplier)
        }

        // Combo multiplier
        let comboMult = comboMultiplier(combo: combo)
        basePoints = Int(Double(basePoints) * comboMult)

        // Level multiplier
        basePoints *= level

        // Garbage sent (for multiplayer)
        return basePoints
    }

    static func garbageToSend(
        linesCleared: Int,
        isTSpin: Bool,
        isMiniTSpin: Bool,
        isPerfectClear: Bool,
        difficulty: DifficultyPreset
    ) -> Int {
        var garbage = 0

        if isTSpin || isMiniTSpin {
            switch linesCleared {
            case 1: garbage = 2
            case 2: garbage = 4
            case 3: garbage = 6
            default: garbage = 0
            }
        } else {
            switch linesCleared {
            case 2: garbage = 1
            case 3: garbage = 2
            case 4: garbage = 4
            default: garbage = 0
            }
        }

        if isPerfectClear {
            garbage += 10
        }

        // Apply difficulty multiplier
        garbage = Int(Double(garbage) * difficulty.garbageMultiplier)

        return max(0, garbage)
    }
}
