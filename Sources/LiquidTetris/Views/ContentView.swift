import SwiftUI

struct GamePlayView: View {
    @ObservedObject var viewModel: GameViewModel
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        let c = theme.colors
        ZStack {
            LiquidBackground()

            if viewModel.gameStarted {
                VStack(spacing: 0) {
                    // Top bar: mode + timer
                    if viewModel.selectedMode.showTimer || viewModel.selectedMode.showLineProgress {
                        topBar
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                    }

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
                                label: viewModel.isLocal2P ? "PLAYER 1" : "YOU",
                                gameMode: viewModel.selectedMode
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
                                    label: viewModel.isLocal2P ? "PLAYER 2" : "OPPONENT",
                                    gameMode: viewModel.selectedMode
                                )
                            }
                        }
                    }
                    .padding(24)
                }
            }

            // Level Up Banner
            if viewModel.playerBoard.showLevelUp {
                LevelUpBanner(level: viewModel.playerBoard.levelUpLevel)
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

    // MARK: - Top Bar (Timer / Progress)

    private var topBar: some View {
        let c = theme.colors
        return HStack {
            // Mode badge
            GlassPanel(cornerRadius: 8) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.selectedMode.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(c.accentCyan)
                    Text(viewModel.selectedMode.displayName)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(c.textSecondary)
                    Text("·")
                        .foregroundStyle(c.textMuted)
                    Text(viewModel.selectedDifficulty.displayName)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(c.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }

            Spacer()

            // Timer (Sprint/Ultra)
            if viewModel.selectedMode.showTimer {
                GlassPanel(cornerRadius: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                            .foregroundStyle(viewModel.playerBoard.timeRemaining < 10 ? c.accentRed : c.accentCyan)
                        Text(formatTime(viewModel.playerBoard.timeRemaining))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(viewModel.playerBoard.timeRemaining < 10 ? c.accentRed : c.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }

            // Line Progress (Sprint)
            if viewModel.selectedMode.showLineProgress, let target = viewModel.selectedMode.targetLines {
                GlassPanel(cornerRadius: 8) {
                    HStack(spacing: 8) {
                        Text("\(viewModel.playerBoard.linesCleared)/\(target)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(c.textPrimary)
                        ProgressView(value: Double(viewModel.playerBoard.linesCleared), total: Double(target))
                            .frame(width: 80)
                            .tint(c.accentGreen)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }

            Spacer()
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
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

// MARK: - Level Up Banner

struct LevelUpBanner: View {
    let level: Int
    @EnvironmentObject var theme: ThemeManager
    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = -20

    var body: some View {
        let c = theme.colors
        VStack {
            GlassPanel(cornerRadius: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(c.accentYellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LEVEL UP")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(c.accentYellow)
                        Text("Level \(level)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(c.textPrimary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .opacity(opacity)
            .offset(y: yOffset)
            .animation(.easeOut(duration: 0.3), value: opacity)
            .animation(.easeOut(duration: 0.3), value: yOffset)
            Spacer()
        }
        .padding(.top, 60)
        .onAppear {
            withAnimation { opacity = 1; yOffset = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { opacity = 0; yOffset = -20 }
            }
        }
    }
}

// MARK: - Pause Overlay

struct PauseOverlay: View {
    let onResume: () -> Void
    let onQuit: () -> Void
    @EnvironmentObject var theme: ThemeManager

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
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        let c = theme.colors
        ZStack {
            c.overlayBackground
                .ignoresSafeArea()

            GlassPanel(cornerRadius: 32) {
                VStack(spacing: 24) {
                    Image(systemName: message.contains("WIN") || message.contains("COMPLETE") ? "trophy.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(message.contains("WIN") || message.contains("COMPLETE") ? c.accentYellow : c.accentRed)

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
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        let c = theme.colors
        GlassPanel(cornerRadius: 16) {
            VStack(spacing: 10) {
                statRow(label: "Pieces", value: "\(stats.piecesPlaced)", color: c.accentCyan)
                statRow(label: "Lines Cleared", value: "\(stats.linesClearedTotal)", color: c.accentGreen)
                statRow(label: "Lines Sent", value: "\(stats.linesSent)", color: c.accentOrange)
                statRow(label: "Longest Combo", value: "\(stats.longestCombo)x", color: c.accentPurple)
                statRow(label: "Tetris", value: "\(stats.tetrisCount)", color: c.accentYellow)
                if stats.tSpinCount > 0 {
                    statRow(label: "T-Spins", value: "\(stats.tSpinCount)", color: c.accentPurple)
                }
                if stats.backToBackCount > 0 {
                    statRow(label: "Back-to-Back", value: "\(stats.backToBackCount)", color: c.accentOrange)
                }
                if stats.perfectClearCount > 0 {
                    statRow(label: "Perfect Clears", value: "\(stats.perfectClearCount)", color: c.accentYellow)
                }
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
    @EnvironmentObject var theme: ThemeManager

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
