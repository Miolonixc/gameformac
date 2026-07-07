import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var playerBoard = GameBoard()
    @Published var opponentBoard = GameBoard()
    @Published var isMultiplayer = false
    @Published var isHost = false
    @Published var gameStarted = false
    @Published var showResult = false
    @Published var resultMessage = ""

    let network = NetworkManager.shared
    private var dropTimer: Timer?
    private var sendTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNetworkCallbacks()
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

    func startSinglePlayer() {
        isMultiplayer = false
        playerBoard = GameBoard()
        opponentBoard = GameBoard()
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
        playerBoard = GameBoard()

        startDropTimer()

        if isMultiplayer {
            startSendTimer()
        }
    }

    private func startDropTimer() {
        dropTimer?.invalidate()
        let interval = max(0.1, GameConstants.dropInterval - Double(playerBoard.level - 1) * GameConstants.levelSpeedup)
        dropTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func startSendTimer() {
        sendTimer?.invalidate()
        sendTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.sendState()
        }
    }

    func tick() {
        guard !playerBoard.isGameOver else { return }
        playerBoard.moveDown()

        if playerBoard.isGameOver {
            gameOver(won: false)
            if isMultiplayer {
                network.sendGameOver()
            }
        }
    }

    // MARK: - Input

    func handleLeft()    { playerBoard.moveLeft() }
    func handleRight()   { playerBoard.moveRight() }
    func handleDown()    { playerBoard.moveDown() }
    func handleRotate()  { playerBoard.rotate() }
    func handleDrop()    { playerBoard.hardDrop() }
    func handleHold()    { playerBoard.holdPiece() }

    // MARK: - Send State

    func sendState() {
        let state = GameStatePayload(
            grid: playerBoard.grid,
            score: playerBoard.score,
            level: playerBoard.level,
            linesCleared: playerBoard.linesCleared,
            isGameOver: playerBoard.isGameOver,
            currentPieceType: playerBoard.currentPiece?.type,
            nextPieceType: playerBoard.nextPiece?.type
        )
        network.sendGameState(state)
    }

    // MARK: - Receive State

    private func updateOpponentBoard(from state: GameStatePayload) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.opponentBoard.grid = state.grid
            self.opponentBoard.score = state.score
            self.opponentBoard.level = state.level
            self.opponentBoard.linesCleared = state.linesCleared
            self.opponentBoard.isGameOver = state.isGameOver
        }
    }

    // MARK: - Game Over

    func gameOver(won: Bool) {
        dropTimer?.invalidate()
        sendTimer?.invalidate()
        gameStarted = false
        showResult = true
        resultMessage = won ? "YOU WIN!" : "GAME OVER"
    }

    // MARK: - Cleanup

    func stopAll() {
        dropTimer?.invalidate()
        sendTimer?.invalidate()
        network.stopAll()
        gameStarted = false
    }
}
