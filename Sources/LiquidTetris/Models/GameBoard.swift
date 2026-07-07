import Foundation
import SwiftUI

// MARK: - Cell

struct Cell: Codable {
    var filled: Bool
    var color: TetrominoType?

    static let empty = Cell(filled: false, color: nil)
}

// MARK: - GameBoard

class GameBoard: ObservableObject, Codable {
    @Published var grid: [[Cell]]
    @Published var currentPiece: Tetromino?
    @Published var nextPiece: Tetromino?
    @Published var score: Int = 0
    @Published var level: Int = 1
    @Published var linesCleared: Int = 0
    @Published var isGameOver: Bool = false
    @Published var heldPiece: TetrominoType?
    @Published var canHold: Bool = true

    let rows = GameConstants.rows
    let cols = GameConstants.cols

    private var pieceBag: [TetrominoType] = []

    init() {
        grid = Array(repeating: Array(repeating: Cell.empty, count: GameConstants.cols), count: GameConstants.rows)
        spawnPiece()
    }

    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case grid, score, level, linesCleared, isGameOver, heldPiece, canHold
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        grid = try container.decode([[Cell]].self, forKey: .grid)
        score = try container.decode(Int.self, forKey: .score)
        level = try container.decode(Int.self, forKey: .level)
        linesCleared = try container.decode(Int.self, forKey: .linesCleared)
        isGameOver = try container.decode(Bool.self, forKey: .isGameOver)
        heldPiece = try container.decodeIfPresent(TetrominoType.self, forKey: .heldPiece)
        canHold = try container.decode(Bool.self, forKey: .canHold)
        currentPiece = nil
        nextPiece = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(grid, forKey: .grid)
        try container.encode(score, forKey: .score)
        try container.encode(level, forKey: .level)
        try container.encode(linesCleared, forKey: .linesCleared)
        try container.encode(isGameOver, forKey: .isGameOver)
        try container.encode(heldPiece, forKey: .heldPiece)
        try container.encode(canHold, forKey: .canHold)
    }

    // MARK: - Piece Bag (7-bag randomizer)

    private func nextFromBag() -> TetrominoType {
        if pieceBag.isEmpty {
            pieceBag = TetrominoType.allCases.shuffled()
        }
        return pieceBag.removeFirst()
    }

    // MARK: - Spawn

    func spawnPiece() {
        if nextPiece == nil {
            nextPiece = Tetromino.random()
        }
        currentPiece = nextPiece
        nextPiece = Tetromino(type: nextFromBag(), row: 0, col: 3, rotation: 0)
        canHold = true

        if let piece = currentPiece, !isValidPosition(piece: piece) {
            isGameOver = true
        }
    }

    // MARK: - Collision Detection

    func isValidPosition(piece: Tetromino) -> Bool {
        let shape = piece.cells
        for r in 0..<shape.count {
            for c in 0..<shape[r].count {
                if shape[r][c] == 1 {
                    let newR = piece.row + r
                    let newC = piece.col + c

                    if newR < 0 || newR >= rows || newC < 0 || newC >= cols {
                        return false
                    }
                    if grid[newR][newC].filled {
                        return false
                    }
                }
            }
        }
        return true
    }

    // MARK: - Movement

    @discardableResult
    func moveLeft() -> Bool {
        guard var piece = currentPiece else { return false }
        piece.col -= 1
        if isValidPosition(piece: piece) {
            currentPiece = piece
            return true
        }
        return false
    }

    @discardableResult
    func moveRight() -> Bool {
        guard var piece = currentPiece else { return false }
        piece.col += 1
        if isValidPosition(piece: piece) {
            currentPiece = piece
            return true
        }
        return false
    }

    @discardableResult
    func moveDown() -> Bool {
        guard var piece = currentPiece else { return false }
        piece.row += 1
        if isValidPosition(piece: piece) {
            currentPiece = piece
            return true
        } else {
            lockPiece()
            return false
        }
    }

    @discardableResult
    func rotate() -> Bool {
        guard var piece = currentPiece else { return false }
        let oldRotation = piece.rotation
        piece.rotation = (piece.rotation + 1) % 4

        let kicks = [(0, 0), (0, -1), (0, 1), (0, -2), (0, 2), (-1, 0), (-2, 0)]
        for kick in kicks {
            var kicked = piece
            kicked.row += kick.0
            kicked.col += kick.1
            if isValidPosition(piece: kicked) {
                currentPiece = kicked
                return true
            }
        }
        piece.rotation = oldRotation
        return false
    }

    func hardDrop() {
        while moveDown() {}
    }

    func holdPiece() {
        guard canHold, let piece = currentPiece else { return }
        let type = piece.type
        if let held = heldPiece {
            currentPiece = Tetromino(type: held, row: 0, col: 3, rotation: 0)
        } else {
            currentPiece = nil
            spawnPiece()
        }
        heldPiece = type
        canHold = false
    }

    // MARK: - Lock & Clear

    func lockPiece() {
        guard let piece = currentPiece else { return }
        let shape = piece.cells
        for r in 0..<shape.count {
            for c in 0..<shape[r].count {
                if shape[r][c] == 1 {
                    let newR = piece.row + r
                    let newC = piece.col + c
                    if newR >= 0 && newR < rows && newC >= 0 && newC < cols {
                        grid[newR][newC] = Cell(filled: true, color: piece.type)
                    }
                }
            }
        }
        let cleared = clearLines()
        updateScore(lines: cleared)
        spawnPiece()
    }

    func clearLines() -> Int {
        var clearedRows: [Int] = []
        for r in 0..<rows {
            if grid[r].allSatisfy({ $0.filled }) {
                clearedRows.append(r)
            }
        }
        for row in clearedRows {
            grid.remove(at: row)
            grid.insert(Array(repeating: Cell.empty, count: cols), at: 0)
        }
        linesCleared += clearedRows.count
        return clearedRows.count
    }

    func updateScore(lines: Int) {
        let points: [Int: Int] = [1: 100, 2: 300, 3: 500, 4: 800]
        score += (points[lines] ?? 0) * level
        level = (linesCleared / 10) + 1
    }

    // MARK: - Garbage Lines

    func addGarbageLines(_ count: Int) {
        guard count > 0 else { return }
        let gap = Int.random(in: 0..<cols)
        for _ in 0..<count {
            grid.removeFirst()
            var garbageRow = Array(repeating: Cell(filled: true, color: .Z), count: cols)
            garbageRow[gap] = Cell.empty
            grid.append(garbageRow)
        }
    }

    // MARK: - Ghost Piece

    func ghostPosition() -> (row: Int, col: Int)? {
        guard var piece = currentPiece else { return nil }
        while isValidPosition(piece: piece) {
            piece.row += 1
        }
        return (piece.row - 1, piece.col)
    }
}
