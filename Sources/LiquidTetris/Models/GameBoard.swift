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
    var tSpinCount: Int = 0
    var perfectClearCount: Int = 0
    var backToBackCount: Int = 0
    var startTime: TimeInterval = Date().timeIntervalSince1970

    var uptime: TimeInterval {
        Date().timeIntervalSince1970 - startTime
    }
}

// MARK: - Line Clear Particle

struct LineParticle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var color: Color
    var size: CGFloat
    var opacity: Double
    var lifetime: TimeInterval
    var age: TimeInterval = 0
}

// MARK: - GameBoard

class GameBoard: ObservableObject, Codable {
    @Published var grid: [[Cell]]
    @Published var currentPiece: Tetromino?
    @Published var pieceQueue: [TetrominoType] = []
    @Published var score: Int = 0
    @Published var linesCleared: Int = 0
    @Published var isGameOver: Bool = false
    @Published var heldPiece: TetrominoType?
    @Published var canHold: Bool = true
    @Published var isPaused: Bool = false
    @Published var stats = GameStats()
    @Published var lockDelay: TimeInterval = 0
    @Published var isLocking: Bool = false

    // Level system
    var levelManager = LevelManager()
    var difficulty: DifficultyPreset = .normal
    var gameMode: GameMode = .marathon
    var setupDone: Bool = false

    // Sprint/Ultra timer
    @Published var elapsedTime: TimeInterval = 0
    @Published var timeRemaining: TimeInterval = 0

    // T-spin tracking
    private var lastWasRotation: Bool = false
    private var lastRotationMoved: Bool = false

    // Back-to-back tracking
    private var lastClearWasTetrisOrTSpin: Bool = false

    // Animation states
    @Published var hardDropFlash: Bool = false
    @Published var lineClearRows: Set<Int> = []
    @Published var lineClearFlash: Bool = false
    @Published var dropImpactCol: Int = -1
    @Published var dropImpactColor: Color = .clear
    @Published var justLockedCells: [(row: Int, col: Int)] = []
    @Published var clearingCol: Int = -1

    // Line clear effects
    @Published var lineClearCount: Int = 0
    @Published var showTetrisFlash: Bool = false
    @Published var lineClearCenterCol: Int = -1

    // T-spin effects
    @Published var showTSpinOverlay: Bool = false
    @Published var tSpinIsMini: Bool = false
    @Published var tSpinLinesCleared: Int = 0

    // Particle effects
    @Published var particles: [LineParticle] = []
    private var particleIdCounter: Int = 0

    // Level-up animation
    @Published var showLevelUp: Bool = false
    @Published var levelUpLevel: Int = 0

    let rows = GameConstants.rows
    let cols = GameConstants.cols

    private var pieceBag: [TetrominoType] = []

    init() {
        grid = Array(repeating: Array(repeating: Cell.empty, count: GameConstants.cols), count: GameConstants.rows)
        fillQueue()
        spawnPiece()
    }

    func setupGame(mode: GameMode, difficulty: DifficultyPreset) {
        self.gameMode = mode
        self.difficulty = difficulty
        levelManager.setup(difficulty: difficulty)
        lastClearWasTetrisOrTSpin = false
        elapsedTime = 0
        if let limit = mode.timeLimit {
            timeRemaining = limit
        }
        setupDone = true
    }

    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case grid, score, linesCleared, isGameOver, heldPiece, canHold, stats, levelManager
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        grid = try container.decode([[Cell]].self, forKey: .grid)
        score = try container.decode(Int.self, forKey: .score)
        linesCleared = try container.decode(Int.self, forKey: .linesCleared)
        isGameOver = try container.decode(Bool.self, forKey: .isGameOver)
        heldPiece = try container.decodeIfPresent(TetrominoType.self, forKey: .heldPiece)
        canHold = try container.decode(Bool.self, forKey: .canHold)
        stats = (try? container.decode(GameStats.self, forKey: .stats)) ?? GameStats()
        levelManager = (try? container.decode(LevelManager.self, forKey: .levelManager)) ?? LevelManager()
        currentPiece = nil
        pieceQueue = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(grid, forKey: .grid)
        try container.encode(score, forKey: .score)
        try container.encode(linesCleared, forKey: .linesCleared)
        try container.encode(isGameOver, forKey: .isGameOver)
        try container.encode(heldPiece, forKey: .heldPiece)
        try container.encode(canHold, forKey: .canHold)
        try container.encode(stats, forKey: .stats)
        try container.encode(levelManager, forKey: .levelManager)
    }

    // MARK: - Level (computed from LevelManager)

    var level: Int {
        levelManager.currentLevel
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
            lastWasRotation = false
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
            lastWasRotation = false
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
            lastWasRotation = false
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
                lastWasRotation = true
                lastRotationMoved = (kick != (0, 0))
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

        // Track drop distance for scoring
        var dropCount = 0
        while moveDown() {
            dropCount += 1
        }
        stats.piecesPlaced += 1
        score += dropCount * ScoringSystem.hardDropPoint

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
        guard isLocking, let _ = currentPiece else { return }
        lockDelay += dt
        if lockDelay >= difficulty.lockDelay {
            stats.piecesPlaced += 1
            lockPiece()
        }
    }

    private func resetLockDelayIfNeeded() {
        if isLocking && stats.piecesPlaced < difficulty.maxLockResets {
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

        // Detect T-spin
        let (isTSpin, isMiniTSpin) = detectTSpin()

        let cleared = clearLinesSync()

        // Check perfect clear (board is empty)
        let isPerfectClear = grid.allSatisfy { row in
            row.allSatisfy { !$0.filled }
        }

        // Back-to-back check
        let isTetris = cleared == 4
        let isBackToBack = lastClearWasTetrisOrTSpin && (isTetris || isTSpin)
        if isTetris || isTSpin {
            lastClearWasTetrisOrTSpin = true
        } else {
            lastClearWasTetrisOrTSpin = false
        }

        // Calculate score
        let points = ScoringSystem.calculate(
            linesCleared: cleared,
            isTSpin: isTSpin,
            isMiniTSpin: isMiniTSpin,
            isPerfectClear: isPerfectClear,
            isBackToBack: isBackToBack,
            combo: stats.currentCombo,
            level: levelManager.currentLevel,
            difficulty: difficulty
        )
        score += points

        // Combo tracking
        if cleared > 0 || isTSpin {
            stats.currentCombo += 1
            stats.longestCombo = max(stats.longestCombo, stats.currentCombo)
        } else {
            stats.currentCombo = 0
        }

        // Garbage sent (for multiplayer)
        let garbage = ScoringSystem.garbageToSend(
            linesCleared: cleared,
            isTSpin: isTSpin,
            isMiniTSpin: isMiniTSpin,
            isPerfectClear: isPerfectClear,
            difficulty: difficulty
        )
        stats.linesSent += garbage

        // Stats
        stats.linesClearedTotal += cleared
        if isTetris { stats.tetrisCount += 1 }
        if isTSpin { stats.tSpinCount += 1 }
        if isPerfectClear { stats.perfectClearCount += 1 }
        if isBackToBack { stats.backToBackCount += 1 }

        // Visual effects
        if cleared > 0 {
            lineClearCount = cleared
            lineClearCenterCol = cols / 2
            spawnLineClearParticles(rows: Array(lineClearRows), cleared: cleared)

            if isTetris {
                showTetrisFlash = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.showTetrisFlash = false
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.lineClearCount = 0
                self?.lineClearCenterCol = -1
            }
        }

        if isTSpin {
            showTSpinOverlay = true
            tSpinIsMini = isMiniTSpin
            tSpinLinesCleared = cleared
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.showTSpinOverlay = false
            }
        }

        if isPerfectClear {
            spawnPerfectClearParticles()
        }

        // Level progression
        let leveledUp = levelManager.addLines(cleared)
        if leveledUp {
            showLevelUp = true
            levelUpLevel = levelManager.currentLevel
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.showLevelUp = false
            }
        }

        // Reset T-spin tracking
        lastWasRotation = false
        lastRotationMoved = false

        spawnPiece()
    }

    /// Synchronous line clear for use inside lockPiece (no animation delay)
    private func clearLinesSync() -> Int {
        var clearedRows: [Int] = []
        for r in 0..<rows {
            if grid[r].allSatisfy({ $0.filled }) {
                clearedRows.append(r)
            }
        }

        guard !clearedRows.isEmpty else { return 0 }

        // Start cascade animation
        lineClearRows = Set(clearedRows)
        clearingCol = 0
        lineClearFlash = true

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

    func clearLines() -> Int {
        return clearLinesSync()
    }

    // MARK: - T-Spin Detection

    /// Detects if the last move was a T-spin or mini T-spin
    private func detectTSpin() -> (isTSpin: Bool, isMini: Bool) {
        guard lastWasRotation, let piece = currentPiece, piece.type == .T else {
            return (false, false)
        }

        // Count occupied corners of the T-piece's bounding box
        let corners = [
            (piece.row, piece.col),
            (piece.row, piece.col + 2),
            (piece.row + 2, piece.col),
            (piece.row + 2, piece.col + 2)
        ]

        var occupiedCorners = 0
        for (r, c) in corners {
            if r < 0 || r >= rows || c < 0 || c >= cols || grid[r][c].filled {
                occupiedCorners += 1
            }
        }

        // T-spin requires 3+ occupied corners
        guard occupiedCorners >= 3 else { return (false, false) }

        // Mini T-spin: rotation didn't move (no kick) or only 2 corners occupied at tip
        if !lastRotationMoved {
            return (false, true)
        }

        return (true, false)
    }

    // MARK: - Garbage Lines

    func addGarbageLines(_ count: Int) {
        guard count > 0 else { return }
        let adjustedCount = Int(Double(count) * difficulty.garbageMultiplier)
        guard adjustedCount > 0 else { return }
        let gap = Int.random(in: 0..<cols)
        for _ in 0..<adjustedCount {
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

    // MARK: - Timer Tick (for Sprint/Ultra)

    func tickElapsed(_ dt: TimeInterval) {
        guard !isPaused, !isGameOver else { return }
        elapsedTime += dt
        if let limit = gameMode.timeLimit {
            timeRemaining = max(0, limit - elapsedTime)
            if timeRemaining <= 0 {
                isGameOver = true
            }
        }
    }

    // MARK: - Particle Effects

    private func spawnLineClearParticles(rows: [Int], cleared: Int) {
        let cellSize = GameConstants.cellSize
        let colors: [Color] = [.cyan, .white, .yellow, .orange, .purple]
        let count = cleared * 12

        for _ in 0..<count {
            let row = rows.randomElement() ?? rows[0]
            let col = Int.random(in: 0..<cols)
            let x = CGFloat(col) * cellSize + cellSize / 2
            let y = CGFloat(row) * cellSize + cellSize / 2
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 2...6)

            let particle = LineParticle(
                id: particleIdCounter,
                x: x, y: y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed - 2,
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 2...5),
                opacity: 1.0,
                lifetime: TimeInterval.random(in: 0.3...0.6)
            )
            particles.append(particle)
            particleIdCounter += 1
        }

        // Auto-cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.particles.removeAll()
        }
    }

    private func spawnPerfectClearParticles() {
        let cellSize = GameConstants.cellSize
        let colors: [Color] = [.yellow, .white, .cyan, .purple]
        let count = 40

        for _ in 0..<count {
            let col = Int.random(in: 0..<cols)
            let row = Int.random(in: 0..<rows)
            let x = CGFloat(col) * cellSize + cellSize / 2
            let y = CGFloat(row) * cellSize + cellSize / 2
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 3...8)

            let particle = LineParticle(
                id: particleIdCounter,
                x: x, y: y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed - 3,
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 3...6),
                opacity: 1.0,
                lifetime: TimeInterval.random(in: 0.4...0.8)
            )
            particles.append(particle)
            particleIdCounter += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            self?.particles.removeAll()
        }
    }
}
