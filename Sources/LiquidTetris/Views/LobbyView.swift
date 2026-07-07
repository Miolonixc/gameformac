import SwiftUI

struct LobbyView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showMenu = true
    @Environment(\.theme) var theme

    var body: some View {
        ZStack {
            LiquidBackground()

            if showMenu {
                menuView
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
                    viewModel.startSinglePlayer()
                }

                GlassButton(title: "Find Opponent", icon: "network", color: c.accentPurple) {
                    showMenu = false
                    viewModel.autoConnect()
                }

                GlassButton(title: "Host Game", icon: "antenna.radiowaves.left.and.right", color: c.accentGreen) {
                    showMenu = false
                    viewModel.hostMultiplayer()
                }

                GlassButton(title: "Join Game", icon: "link", color: c.accentOrange) {
                    showMenu = false
                    viewModel.joinMultiplayer()
                }
            }

            // Info
            GlassPanel(cornerRadius: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "wifi")
                        .foregroundStyle(c.accentCyan)
                    Text("Play with a friend on the same Wi-Fi network. The game finds opponents automatically.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(c.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
            }
            .frame(maxWidth: 400)

            Spacer()
        }
    }

    // MARK: - Connecting

    var connectingView: some View {
        let c = theme.colors
        return VStack(spacing: 30) {
            // Top bar
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

            // Start button (when host)
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
