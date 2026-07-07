import SwiftUI

struct GamePlayView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.theme) var theme

    var body: some View {
        let c = theme.colors
        ZStack {
            LiquidBackground()

            if viewModel.gameStarted {
                HStack(spacing: viewModel.isLocal2P ? 24 : 40) {
                    // Player 1 Board
                    VStack(spacing: 12) {
                        if viewModel.isLocal2P {
                            GlassPanel(cornerRadius: 10) {
                                Text("P1  \u{2190}\u{2192}\u{2191}\u{2193} Move  \u{2191} Rotate  Space Drop  C Hold")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundStyle(c.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                            }
                        }

                        GameBoardView(
                            board: viewModel.playerBoard,
                            isPlayer: true,
                            label: viewModel.isLocal2P ? "PLAYER 1" : "YOU"
                        )

                        if !viewModel.isMultiplayer && !viewModel.isLocal2P {
                            controlsHint
                        }
                    }

                    // VS Divider
                    if viewModel.isMultiplayer || viewModel.isLocal2P {
                        VStack(spacing: 20) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(c.accentYellow)
                            Text("VS")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(c.textSecondary)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(c.accentYellow)
                        }

                        // Player 2 Board
                        VStack(spacing: 12) {
                            if viewModel.isLocal2P {
                                GlassPanel(cornerRadius: 10) {
                                    Text("P2  WASD Move  W Rotate  Space Drop  E Hold")
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundStyle(c.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                }
                            }

                            GameBoardView(
                                board: viewModel.player2Board,
                                isPlayer: false,
                                label: viewModel.isLocal2P ? "PLAYER 2" : "OPPONENT"
                            )
                        }
                    }
                }
                .padding(24)
            }

            // Pause Overlay
            if viewModel.isPaused {
                PauseOverlay(
                    onResume: { viewModel.togglePause() },
                    onQuit: {
                        viewModel.stopAll()
                        viewModel.showResult = false
                        viewModel.gameStarted = false
                    }
                )
            }
        }
    }

    var controlsHint: some View {
        GlassPanel(cornerRadius: 12) {
            HStack(spacing: 20) {
                controlItem(keys: "\u{2190} \u{2192}", label: "Move")
                controlItem(keys: "\u{2191}", label: "Rotate")
                controlItem(keys: "\u{2193}", label: "Soft Drop")
                controlItem(keys: "Space", label: "Hard Drop")
                controlItem(keys: "C", label: "Hold")
                controlItem(keys: "ESC", label: "Pause")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    func controlItem(keys: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(keys)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.colors.accentCyan)
            Text(label)
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(theme.colors.textSecondary)
        }
    }
}

// MARK: - Pause Overlay

struct PauseOverlay: View {
    let onResume: () -> Void
    let onQuit: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        let c = theme.colors
        ZStack {
            c.overlayBackground
                .ignoresSafeArea()

            GlassPanel(cornerRadius: 32) {
                VStack(spacing: 24) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(c.accentCyan)

                    Text("PAUSED")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(c.textPrimary)

                    VStack(spacing: 12) {
                        GlassButton(title: "Resume", icon: "play.fill", color: c.accentGreen) {
                            onResume()
                        }

                        GlassButton(title: "Quit", icon: "arrow.left", color: c.accentRed) {
                            onQuit()
                        }
                    }
                }
                .padding(48)
            }
        }
    }
}

// MARK: - Result Overlay

struct ResultOverlay: View {
    let message: String
    let stats: GameStats?
    let onDismiss: () -> Void
    @Environment(\.theme) var theme

    var body: some View {
        let c = theme.colors
        ZStack {
            c.overlayBackground
                .ignoresSafeArea()

            GlassPanel(cornerRadius: 32) {
                VStack(spacing: 24) {
                    Image(systemName: message.contains("WIN") ? "trophy.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(message.contains("WIN") ? c.accentYellow : c.accentRed)

                    Text(message)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(c.textPrimary)

                    if let stats = stats {
                        GameStatsView(stats: stats)
                    }

                    GlassButton(title: "Back to Menu", icon: "arrow.left", color: c.accentCyan) {
                        onDismiss()
                    }
                }
                .padding(48)
            }
        }
    }
}

// MARK: - Game Stats View

struct GameStatsView: View {
    let stats: GameStats
    @Environment(\.theme) var theme

    var body: some View {
        let c = theme.colors
        GlassPanel(cornerRadius: 16) {
            VStack(spacing: 12) {
                statRow(label: "Pieces", value: "\(stats.piecesPlaced)", color: c.accentCyan)
                statRow(label: "Lines Cleared", value: "\(stats.linesClearedTotal)", color: c.accentGreen)
                statRow(label: "Lines Sent", value: "\(stats.linesSent)", color: c.accentOrange)
                statRow(label: "Longest Combo", value: "\(stats.longestCombo)x", color: c.accentPurple)
                statRow(label: "Tetris", value: "\(stats.tetrisCount)", color: c.accentYellow)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(theme.colors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.theme) var theme

    var body: some View {
        ZStack {
            if viewModel.gameStarted || viewModel.showResult {
                if viewModel.gameStarted {
                    GamePlayView(viewModel: viewModel)
                }

                if viewModel.showResult {
                    ResultOverlay(
                        message: viewModel.resultMessage,
                        stats: viewModel.playerBoard.stats
                    ) {
                        viewModel.stopAll()
                        viewModel.showResult = false
                        viewModel.gameStarted = false
                    }
                }
            } else {
                LobbyView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 900, minHeight: 700)
    }
}
