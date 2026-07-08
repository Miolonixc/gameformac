import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var playerBoard = GameBoard()
    @Published var player2Board = GameBoard()
    @Published var isMultiplayer = false
    @Published var isLocal2P = false
    @Published var isHost = false
    @Published var gameStarted = false
    @Published var isPaused = false
    @Published var showResult = false
    @Published var resultMessage = ""

    // Mode & difficulty
    @Published var selectedMode: GameMode = .marathon
    @Published var selectedDifficulty: DifficultyPreset = .normal

    let network = NetworkManager.shared
    private var dropTimer1: Timer?
    private var dropTimer2: Timer?
    private var sendTimer: Timer?
    private var physicsTimer: Timer?
    private var keyboardMonitor: Any?

    // DAS Player 1
    private var das1Direction: DasDirection = .none
    private var das1Timer: Timer?

    // DAS Player 2
    private var das2Direction: DasDirection = .none
    private var das2Timer: Timer?

    enum DasDirection {
        case none, left, right
    }

    init() {
        setupNetworkCallbacks()
        setupKeyboardMonitor()
    }

    deinit {
        removeKeyboardMonitor()
    }

    // MARK: - Keyboard Monitor (Global NSEvent)

    private func setupKeyboardMonitor() {
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self, self.gameStarted else { return event }

            if event.type == .keyUp {
                self.handleKeyUp(Int(event.keyCode))
                return event
            }

            self.handleKeyDown(Int(event.keyCode))
            return event
        }
    }

    private func removeKeyboardMonitor() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
    }

    private func handleKeyDown(_ keyCode: Int) {
        guard !isPaused else {
            if keyCode == 53 { togglePause() }
            return
        }

        // ESC = pause
        if keyCode == 53 {
            togglePause()
            return
        }

        if isLocal2P {
            handlePlayer1Key(keyCode)
            handlePlayer2Key(keyCode)
        } else {
            handlePlayer1Key(keyCode)
        }
    }

    private func handleKeyUp(_ keyCode: Int) {
        // Stop DAS on key release
        if isLocal2P {
            if [123, 124].contains(keyCode) && das1Direction != .none { stopDAS(player: 1) }
            if [0, 2].contains(keyCode) && das2Direction != .none { stopDAS(player: 2) }
        } else {
            if [123, 124].contains(keyCode) && das1Direction != .none { stopDAS(player: 1) }
        }
    }

    // MARK: - Player 1 Input (Arrows + Space + C)

    private func handlePlayer1Key(_ keyCode: Int) {
        switch keyCode {
        case 123: playerBoard.moveLeft();  startDAS(player: 1, direction: .left)
        case 124: playerBoard.moveRight(); startDAS(player: 1, direction: .right)
        case 125: playerBoard.moveDown()
        case 126: playerBoard.rotate()
        case 49:  playerBoard.hardDrop()   // Space
        case 8:   playerBoard.holdPiece()  // C
        default: break
        }
    }

    // MARK: - Player 2 Input (WASD + E/Q)

    private func handlePlayer2Key(_ keyCode: Int) {
        switch keyCode {
        case 0:   player2Board.moveLeft();  startDAS(player: 2, direction: .left)   // A
        case 2:   player2Board.moveRight(); startDAS(player: 2, direction: .right)  // D
        case 13:  player2Board.moveDown()                                  // S
        case 16:  player2Board.rotate()                                    // W
        case 49:  player2Board.hardDrop()                                  // Space (shared)
        case 14:  player2Board.holdPiece()                                 // E
        default: break
        }
    }

    // MARK: - Network Setup

    private func setupNetworkCallbacks() {
        network.onGameStateReceived = { [weak self] state in
            self?.updateOpponentBoard(from: state)
        }
        network.onGarbageReceived = { [weak self] lines in
            self?.playerBoard.addGarbageLines(lines)
        }
        network.onGameStartReceived = { [weak self] in
            DispatchQueue.main.async {
                self?.startGame(isMultiplayer: true)
            }
        }
        network.onGameEndReceived = { [weak self] in
            DispatchQueue.main.async {
                self?.gameOver(won: true)
            }
        }
    }

    // MARK: - Single Player

    func startSinglePlayer(mode: GameMode = .marathon, difficulty: DifficultyPreset = .normal) {
        selectedMode = mode
        selectedDifficulty = difficulty
        isMultiplayer = false
        isLocal2P = false
        playerBoard = GameBoard()
        player2Board = GameBoard()
        playerBoard.setupGame(mode: mode, difficulty: difficulty)
        startGame(isMultiplayer: false)
    }

    // MARK: - Local 2 Player

    func startLocal2Player(mode: GameMode = .marathon, difficulty: DifficultyPreset = .normal) {
        selectedMode = mode
        selectedDifficulty = difficulty
        isMultiplayer = false
        isLocal2P = true
        playerBoard = GameBoard()
        player2Board = GameBoard()
        playerBoard.setupGame(mode: mode, difficulty: difficulty)
        player2Board.setupGame(mode: mode, difficulty: difficulty)
        startGame(isMultiplayer: false)
    }

    // MARK: - Multiplayer

    func hostMultiplayer() {
        isHost = true
        network.hostGame()
    }

    func joinMultiplayer() {
        isHost = false
        network.joinGame()
    }

    func autoConnect() {
        isHost = false
        network.autoConnect()
    }

    func startMultiplayerGame() {
        network.sendGameStart()
        startGame(isMultiplayer: true)
    }

    // MARK: - Game Control

    func startGame(isMultiplayer: Bool) {
        self.isMultiplayer = isMultiplayer
        gameStarted = true
        isPaused = false

        if !playerBoard.setupDone {
            playerBoard = GameBoard()
            playerBoard.setupGame(mode: selectedMode, difficulty: selectedDifficulty)
        }

        if isLocal2P {
            if !player2Board.setupDone {
                player2Board = GameBoard()
                player2Board.setupGame(mode: selectedMode, difficulty: selectedDifficulty)
            }
        }

        startPhysicsTimer()
        startDropTimer()

        if isMultiplayer {
            startSendTimer()
        }
    }

    private func startDropTimer() {
        dropTimer1?.invalidate()
        let interval1 = playerBoard.levelManager.dropInterval(for: selectedDifficulty)
        dropTimer1 = Timer.scheduledTimer(withTimeInterval: interval1, repeats: true) { [weak self] _ in
            self?.tickPlayer1()
        }

        if isLocal2P {
            dropTimer2?.invalidate()
            let interval2 = player2Board.levelManager.dropInterval(for: selectedDifficulty)
            dropTimer2 = Timer.scheduledTimer(withTimeInterval: interval2, repeats: true) { [weak self] _ in
                self?.tickPlayer2()
            }
        }
    }

    /// Restarts drop timer with current level speed (called after level-up)
    func refreshDropTimer() {
        startDropTimer()
    }

    private func startPhysicsTimer() {
        physicsTimer?.invalidate()
        physicsTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.physicsTick()
        }
    }

    private func startSendTimer() {
        sendTimer?.invalidate()
        sendTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.sendState()
        }
    }

    func physicsTick() {
        guard !isPaused else { return }
        let dt = 1.0 / 60.0

        if !playerBoard.isGameOver {
            playerBoard.tickLockDelay(dt)
            playerBoard.tickElapsed(dt)

            // Sprint: check line target
            if selectedMode == .sprint, let target = selectedMode.targetLines,
               playerBoard.linesCleared >= target {
                gameOver(won: true, message: "SPRINT COMPLETE!")
                return
            }

            // Ultra: check time up
            if selectedMode == .ultra, playerBoard.timeRemaining <= 0 {
                gameOver(won: true, message: "TIME'S UP!")
                return
            }

            // Check if level changed and refresh drop timer
            let currentInterval = playerBoard.levelManager.dropInterval(for: selectedDifficulty)
            if dropTimer1?.timeInterval != currentInterval {
                startDropTimer()
            }
        }

        if isLocal2P && !player2Board.isGameOver {
            player2Board.tickLockDelay(dt)
            player2Board.tickElapsed(dt)
        }
    }

    func tickPlayer1() {
        guard !isPaused, !playerBoard.isGameOver else { return }
        playerBoard.moveDown()
        if playerBoard.isGameOver {
            if isLocal2P {
                gameOver(won: false, message: "PLAYER 2 WINS!")
            } else {
                gameOver(won: false)
                if isMultiplayer { network.sendGameOver() }
            }
        }
    }

    func tickPlayer2() {
        guard !isPaused, !player2Board.isGameOver else { return }
        player2Board.moveDown()
        if player2Board.isGameOver {
            gameOver(won: false, message: "PLAYER 1 WINS!")
        }
    }

    // MARK: - Pause

    func togglePause() {
        guard gameStarted, !playerBoard.isGameOver else { return }
        isPaused.toggle()
        playerBoard.isPaused = isPaused
        if isLocal2P { player2Board.isPaused = isPaused }
    }

    // MARK: - DAS (Delayed Auto Shift)

    private func startDAS(player: Int, direction: DasDirection) {
        stopDAS(player: player)

        let delay = selectedDifficulty.dasDelay
        let repeatInterval = selectedDifficulty.dasRepeat

        if player == 1 {
            das1Direction = direction
            das1Timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.das1Timer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { [weak self] _ in
                    guard let self = self, !self.isPaused else { return }
                    switch self.das1Direction {
                    case .left: self.playerBoard.moveLeft()
                    case .right: self.playerBoard.moveRight()
                    case .none: break
                    }
                }
            }
        } else {
            das2Direction = direction
            das2Timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.das2Timer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { [weak self] _ in
                    guard let self = self, !self.isPaused else { return }
                    switch self.das2Direction {
                    case .left: self.player2Board.moveLeft()
                    case .right: self.player2Board.moveRight()
                    case .none: break
                    }
                }
            }
        }
    }

    private func stopDAS(player: Int) {
        if player == 1 {
            das1Timer?.invalidate()
            das1Timer = nil
            das1Direction = .none
        } else {
            das2Timer?.invalidate()
            das2Timer = nil
            das2Direction = .none
        }
    }

    // MARK: - Send State

    func sendState() {
        let state = GameStatePayload(
            grid: playerBoard.grid,
            score: playerBoard.score,
            level: playerBoard.level,
            linesCleared: playerBoard.linesCleared,
            isGameOver: playerBoard.isGameOver,
            currentPieceType: playerBoard.currentPiece?.type,
            nextPieceType: nil
        )
        network.sendGameState(state)
    }

    // MARK: - Receive State

    private func updateOpponentBoard(from state: GameStatePayload) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.player2Board.grid = state.grid
            self.player2Board.score = state.score
            self.player2Board.linesCleared = state.linesCleared
            self.player2Board.isGameOver = state.isGameOver
        }
    }

    // MARK: - Game Over

    func gameOver(won: Bool, message: String? = nil) {
        dropTimer1?.invalidate()
        dropTimer2?.invalidate()
        sendTimer?.invalidate()
        physicsTimer?.invalidate()
        stopDAS(player: 1)
        stopDAS(player: 2)
        gameStarted = false
        isPaused = false
        showResult = true

        if let msg = message {
            resultMessage = msg
        } else if won {
            resultMessage = "YOU WIN!"
        } else {
            switch selectedMode {
            case .marathon: resultMessage = "GAME OVER"
            case .sprint: resultMessage = "TIME'S UP!"
            case .ultra: resultMessage = "TIME'S UP!"
            }
        }
    }

    // MARK: - Cleanup

    func stopAll() {
        dropTimer1?.invalidate()
        dropTimer2?.invalidate()
        sendTimer?.invalidate()
        physicsTimer?.invalidate()
        stopDAS(player: 1)
        stopDAS(player: 2)
        network.stopAll()
        gameStarted = false
        isPaused = false
    }
}
