import Foundation
import SwiftUI

// MARK: - Tetromino Shapes

enum TetrominoType: Int, CaseIterable, Codable {
    case I = 0, O, T, S, Z, J, L

    var color: Color {
        switch self {
        case .I: return Color(red: 0.0, green: 0.9, blue: 1.0)
        case .O: return Color(red: 1.0, green: 0.95, blue: 0.0)
        case .T: return Color(red: 0.7, green: 0.0, blue: 1.0)
        case .S: return Color(red: 0.0, green: 1.0, blue: 0.4)
        case .Z: return Color(red: 1.0, green: 0.2, blue: 0.2)
        case .J: return Color(red: 0.0, green: 0.3, blue: 1.0)
        case .L: return Color(red: 1.0, green: 0.6, blue: 0.0)
        }
    }

    var shape: [[Int]] {
        switch self {
        case .I: return [[0,0,0,0],
                         [1,1,1,1],
                         [0,0,0,0],
                         [0,0,0,0]]
        case .O: return [[1,1],
                         [1,1]]
        case .T: return [[0,1,0],
                         [1,1,1],
                         [0,0,0]]
        case .S: return [[0,1,1],
                         [1,1,0],
                         [0,0,0]]
        case .Z: return [[1,1,0],
                         [0,1,1],
                         [0,0,0]]
        case .J: return [[1,0,0],
                         [1,1,1],
                         [0,0,0]]
        case .L: return [[0,0,1],
                         [1,1,1],
                         [0,0,0]]
        }
    }
}

// MARK: - Tetromino

struct Tetromino: Codable {
    let type: TetrominoType
    var row: Int
    var col: Int
    var rotation: Int

    var cells: [[Int]] {
        var shape = type.shape
        for _ in 0..<rotation {
            shape = rotateMatrix(shape)
        }
        return shape
    }

    private func rotateMatrix(_ matrix: [[Int]]) -> [[Int]] {
        let n = matrix.count
        var result = Array(repeating: Array(repeating: 0, count: n), count: n)
        for r in 0..<n {
            for c in 0..<n {
                result[c][n - 1 - r] = matrix[r][c]
            }
        }
        return result
    }

    static func random() -> Tetromino {
        let type = TetrominoType.allCases.randomElement()!
        return Tetromino(type: type, row: 0, col: 3, rotation: 0)
    }
}

// MARK: - Game Constants

enum GameConstants {
    static let rows = 20
    static let cols = 10
    static let cellSize: CGFloat = 28
    static let dropInterval: TimeInterval = 0.8
    static let levelSpeedup: TimeInterval = 0.05
    static let lockDelay: TimeInterval = 0.5
    static let maxLockResets: Int = 15
    static let dasDelay: TimeInterval = 0.15
    static let dasRepeat: TimeInterval = 0.05
}
