import SwiftUI

struct LobbyView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showMenu = true
    @State private var showModeSelection = false
    @State private var showDifficultySelection = false
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack {
            LiquidBackground()

            if showMenu {
                menuView
            } else if showModeSelection {
                modeSelectionView
            } else if showDifficultySelection {
                difficultySelectionView
            } else {
                connectingView
            }
        }
    }

    // MARK: - Menu

    var menuView: some View {
        let c = theme.colors
        return VStack(spacing: 40) {
            // Header with theme toggle
            HStack {
                Spacer()
                ThemeToggleButton()
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            // Title
            VStack(spacing: 12) {
                Text("LIQUID")
                    .font(.system(size: 64, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [c.accentCyan, c.textPrimary, c.accentPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("TETRIS")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [c.accentPurple, c.accentCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .tracking(20)
            }

            // Buttons
            VStack(spacing: 16) {
                GlassButton(title: "Single Player", icon: "person.fill", color: c.accentCyan) {
                    showMenu = false
                    showModeSelection = true
                }

                GlassButton(title: "2 Players (Local)", icon: "person.2.fill", color: c.accentGreen) {
                    showMenu = false
                    showModeSelection = true
                }

                GlassButton(title: "Find Opponent", icon: "network", color: c.accentPurple) {
                    showMenu = false
                    viewModel.autoConnect()
                }

                GlassButton(title: "Host Game", icon: "antenna.radiowaves.left.and.right", color: c.accentOrange) {
                    showMenu = false
                    viewModel.hostMultiplayer()
                }

                GlassButton(title: "Join Game", icon: "link", color: c.accentOrange) {
                    showMenu = false
                    viewModel.joinMultiplayer()
                }
            }

            // Controls info
            GlassHeader(cornerRadius: 16) {
                VStack(spacing: 12) {
                    HStack(spacing: 32) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("P1")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(c.accentCyan)
                            Text("\u{2190}\u{2192} Move  \u{2191} Rotate  \u{2193} Drop")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(c.textSecondary)
                            Text("Space Hard  C Hold")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(c.textSecondary)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("P2")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(c.accentGreen)
                            Text("A/D Move  W Rotate  S Drop")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(c.textSecondary)
                            Text("Space Hard  E Hold")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(c.textSecondary)
                        }
                    }
                }
                .padding(16)
            }
            .frame(maxWidth: 400)

            Spacer()
        }
    }

    // MARK: - Mode Selection

    var modeSelectionView: some View {
        let c = theme.colors
        return VStack(spacing: 30) {
            // Top bar
            GlassHeader(cornerRadius: 0) {
                HStack {
                    Button("Back") {
                        showModeSelection = false
                        showMenu = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(c.textSecondary)

                    Spacer()
                    ThemeToggleButton()
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }

            Spacer()

            VStack(spacing: 8) {
                Text("SELECT MODE")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(c.textPrimary)
            }

            // Mode cards
            VStack(spacing: 16) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    Button(action: {
                        viewModel.selectedMode = mode
                        showModeSelection = false
                        showDifficultySelection = true
                    }) {
                        GlassPanel(cornerRadius: 16) {
                            HStack(spacing: 16) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 28))
                                    .foregroundStyle(mode == .marathon ? c.accentCyan : mode == .sprint ? c.accentGreen : c.accentOrange)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.displayName)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundStyle(c.textPrimary)
                                    Text(mode.description)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(c.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(c.textMuted)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: 400)
                }
            }

            Spacer()
        }
    }

    // MARK: - Difficulty Selection

    var difficultySelectionView: some View {
        let c = theme.colors
        return VStack(spacing: 30) {
            // Top bar
            GlassHeader(cornerRadius: 0) {
                HStack {
                    Button("Back") {
                        showDifficultySelection = false
                        showModeSelection = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(c.textSecondary)

                    Spacer()

                    Text(viewModel.selectedMode.displayName)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(c.textSecondary)

                    Spacer()

                    ThemeToggleButton()
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }

            Spacer()

            VStack(spacing: 8) {
                Text("SELECT DIFFICULTY")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(c.textPrimary)
            }

            // Difficulty cards
            VStack(spacing: 16) {
                ForEach(DifficultyPreset.allCases, id: \.self) { diff in
                    Button(action: {
                        viewModel.selectedDifficulty = diff
                        showDifficultySelection = false

                        // Start game based on mode
                        switch viewModel.selectedMode {
                        case .marathon, .sprint, .ultra:
                            viewModel.startSinglePlayer(mode: viewModel.selectedMode, difficulty: diff)
                        }
                    }) {
                        GlassPanel(cornerRadius: 16) {
                            HStack(spacing: 16) {
                                Image(systemName: diff.icon)
                                    .font(.system(size: 28))
                                    .foregroundStyle(diff == .easy ? c.accentGreen : diff == .normal ? c.accentCyan : c.accentRed)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(diff.displayName)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundStyle(c.textPrimary)
                                    Text(diff.description)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(c.textSecondary)
                                }

                                Spacer()

                                // Stats preview
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Speed: \(String(format: "%.1f", diff.baseSpeed))s")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(c.textMuted)
                                    Text("Lines/level: \(diff.linesPerLevel)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(c.textMuted)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: 400)
                }
            }

            Spacer()
        }
    }

    // MARK: - Connecting

    var connectingView: some View {
        let c = theme.colors
        return VStack(spacing: 30) {
            // Top bar
            GlassHeader(cornerRadius: 0) {
                HStack {
                    Button("Back") {
                        viewModel.stopAll()
                        showMenu = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(c.textSecondary)

                    Spacer()
                    ThemeToggleButton()
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }

            Spacer()

            // Animated pulse
            ZStack {
                Circle()
                    .fill(c.accentCyan.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(1.5)
                    .animation(.easeInOut(duration: 1.5).repeatForever(), value: UUID())
                Circle()
                    .fill(c.accentPurple.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .animation(.easeInOut(duration: 1.5).repeatForever(), value: UUID())
                Image(systemName: viewModel.network.connectionState == .hosting ? "antenna.radiowaves.left.and.right" : "magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundStyle(c.accentCyan)
            }

            VStack(spacing: 12) {
                Text(statusText)
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .foregroundStyle(c.textPrimary)

                if viewModel.network.discoveredPeers.isEmpty {
                    Text("Looking for opponents...")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(c.textSecondary)
                } else {
                    Text("Found \(viewModel.network.discoveredPeers.count) player(s)")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(c.accentGreen)
                }
            }

            // Peer list
            if !viewModel.network.discoveredPeers.isEmpty {
                GlassPanel(cornerRadius: 16) {
                    VStack(spacing: 8) {
                        ForEach(viewModel.network.discoveredPeers, id: \.self) { peer in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(c.accentCyan)
                                Text(peer.displayName)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(c.textPrimary)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(c.accentGreen)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(8)
                }
                .frame(maxWidth: 300)
            }

            // Start button
            if viewModel.network.connectionState == .hosting {
                GlassButton(title: "Start Game", icon: "play.fill", color: c.accentGreen) {
                    viewModel.startMultiplayerGame()
                }
                .padding(.top, 20)
            }

            Spacer()
        }
    }

    private var statusText: String {
        switch viewModel.network.connectionState {
        case .idle: return "Ready"
        case .searching: return "Searching..."
        case .hosting: return "Hosting Game"
        case .connecting: return "Connecting..."
        case .connected: return "Connected!"
        case .gameStarted: return "Game Starting..."
        case .disconnected: return "Disconnected"
        }
    }
}
