import Foundation
import SwiftUI

// MARK: - Cell

struct Cell: Codable {
    var filled: Bool
    var color: TetrominoType?

    static let empty = Cell(filled: false, color: nil)
}

// MARK: - Game Stats

struct GameStats: Codable {
    var piecesPlaced: Int = 0
    var linesClearedTotal: Int = 0
    var linesSent: Int = 0
    var longestCombo: Int = 0
    var currentCombo: Int = 0
    var tetrisCount: Int = 0
    var startTime: TimeInterval = Date().timeIntervalSince1970

    var uptime: TimeInterval {
        Date().timeIntervalSince1970 - startTime
    }
}

// MARK: - GameBoard

class GameBoard: ObservableObject, Codable {
    @Published var grid: [[Cell]]
    @Published var currentPiece: Tetromino?
    @Published var pieceQueue: [TetrominoType] = []
    @Published var score: Int = 0
    @Published var level: Int = 1
    @Published var linesCleared: Int = 0
    @Published var isGameOver: Bool = false
    @Published var heldPiece: TetrominoType?
    @Published var canHold: Bool = true
    @Published var isPaused: Bool = false
    @Published var stats = GameStats()
    @Published var lockDelay: TimeInterval = 0
    @Published var isLocking: Bool = false

    // Animation states
    @Published var hardDropFlash: Bool = false
    @Published var lineClearRows: Set<Int> = []
    @Published var lineClearFlash: Bool = false
    @Published var dropImpactCol: Int = -1
    @Published var dropImpactColor: Color = .clear
    @Published var justLockedCells: [(row: Int, col: Int)] = []
    @Published var clearingCol: Int = -1

    let rows = GameConstants.rows
    let cols = GameConstants.cols

    private var pieceBag: [TetrominoType] = []

    init() {
        grid = Array(repeating: Array(repeating: Cell.empty, count: GameConstants.cols), count: GameConstants.rows)
        fillQueue()
        spawnPiece()
    }

    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case grid, score, level, linesCleared, isGameOver, heldPiece, canHold, stats
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
        stats = (try? container.decode(GameStats.self, forKey: .stats)) ?? GameStats()
        currentPiece = nil
        pieceQueue = []
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
        try container.encode(stats, forKey: .stats)
    }

    // MARK: - Piece Bag (7-bag randomizer)

    private func nextFromBag() -> TetrominoType {
        if pieceBag.isEmpty {
            pieceBag = TetrominoType.allCases.shuffled()
        }
        return pieceBag.removeFirst()
    }

    // MARK: - Queue

    private func fillQueue() {
        while pieceQueue.count < 5 {
            pieceQueue.append(nextFromBag())
        }
    }

    // MARK: - Spawn

    func spawnPiece() {
        fillQueue()

        let type = pieceQueue.removeFirst()
        currentPiece = Tetromino(type: type, row: 0, col: 3, rotation: 0)
        fillQueue()
        canHold = true
        isLocking = false
        lockDelay = 0

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

    // MARK: - Check if piece is on ground

    func isOnGround() -> Bool {
        guard let piece = currentPiece else { return false }
        var test = piece
        test.row += 1
        return !isValidPosition(piece: test)
    }

    // MARK: - Movement

    @discardableResult
    func moveLeft() -> Bool {
        guard var piece = currentPiece else { return false }
        piece.col -= 1
        if isValidPosition(piece: piece) {
            currentPiece = piece
            resetLockDelayIfNeeded()
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
            resetLockDelayIfNeeded()
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
            isLocking = false
            lockDelay = 0
            return true
        } else {
            if !isLocking {
                isLocking = true
                lockDelay = 0
            }
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
                resetLockDelayIfNeeded()
                return true
            }
        }
        piece.rotation = oldRotation
        return false
    }

    func hardDrop() {
        guard let piece = currentPiece else { return }

        // Calculate impact column (center of piece)
        let shape = piece.cells
        var minC = cols, maxC = 0
        for r in 0..<shape.count {
            for c in 0..<shape[r].count {
                if shape[r][c] == 1 {
                    minC = min(minC, piece.col + c)
                    maxC = max(maxC, piece.col + c)
                }
            }
        }
        let impactCol = (minC + maxC) / 2

        var dropCount = 0
        while moveDown() {
            dropCount += 1
        }
        stats.piecesPlaced += 1

        // Impact ring animation
        dropImpactCol = impactCol
        dropImpactColor = piece.type.color
        hardDropFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.hardDropFlash = false
            self?.dropImpactCol = -1
        }

        lockPiece()
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
        isLocking = false
        lockDelay = 0
    }

    // MARK: - Lock Delay

    func tickLockDelay(_ dt: TimeInterval) {
        guard isLocking, let piece = currentPiece else { return }
        lockDelay += dt
        if lockDelay >= GameConstants.lockDelay {
            stats.piecesPlaced += 1
            lockPiece()
        }
    }

    private func resetLockDelayIfNeeded() {
        if isLocking && stats.piecesPlaced < GameConstants.maxLockResets {
            lockDelay = 0
        }
    }

    // MARK: - Lock & Clear

    func lockPiece() {
        guard let piece = currentPiece else { return }
        let shape = piece.cells
        var lockedCells: [(row: Int, col: Int)] = []
        for r in 0..<shape.count {
            for c in 0..<shape[r].count {
                if shape[r][c] == 1 {
                    let newR = piece.row + r
                    let newC = piece.col + c
                    if newR >= 0 && newR < rows && newC >= 0 && newC < cols {
                        grid[newR][newC] = Cell(filled: true, color: piece.type)
                        lockedCells.append((row: newR, col: newC))
                    }
                }
            }
        }

        // Lock flash animation
        justLockedCells = lockedCells
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.justLockedCells = []
        }

        let cleared = clearLines()
        updateScore(lines: cleared)

        if cleared >= 2 {
            stats.currentCombo += 1
            stats.longestCombo = max(stats.longestCombo, stats.currentCombo)
            stats.linesSent += cleared - 1
        } else {
            stats.currentCombo = 0
        }

        if cleared == 4 {
            stats.tetrisCount += 1
        }

        stats.linesClearedTotal += cleared
        spawnPiece()
    }

    func clearLines() -> Int {
        var clearedRows: [Int] = []
        for r in 0..<rows {
            if grid[r].allSatisfy({ $0.filled }) {
                clearedRows.append(r)
            }
        }

        guard !clearedRows.isEmpty else { return 0 }

        // Start cascade clear animation
        lineClearRows = Set(clearedRows)
        clearingCol = 0
        lineClearFlash = true

        // Cascade: clear column by column from left to right
        let totalCols = cols
        var col = 0
        func clearNextCol() {
            if col < totalCols {
                clearingCol = col
                col += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    clearNextCol()
                }
            } else {
                // Actually remove the rows after cascade finishes
                for row in clearedRows.sorted().reversed() {
                    grid.remove(at: row)
                    grid.insert(Array(repeating: Cell.empty, count: self.cols), at: 0)
                }
                linesCleared += clearedRows.count
                clearingCol = -1
                lineClearFlash = false
                lineClearRows = []
            }
        }
        clearNextCol()

        return clearedRows.count
    }

    func updateScore(lines: Int) {
        let points: [Int: Int] = [1: 100, 2: 300, 3: 500, 4: 800]
        let comboBonus = stats.currentCombo * 50
        score += ((points[lines] ?? 0) + comboBonus) * level
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

    // MARK: - Pause

    func togglePause() {
        isPaused.toggle()
    }
}
