import SwiftUI

struct GamePlayView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.theme) var theme

    var body: some View {
        let c = theme.colors
        ZStack {
            LiquidBackground()

            if viewModel.gameStarted {
                HStack(spacing: 40) {
                    VStack(spacing: 16) {
                        GameBoardView(
                            board: viewModel.playerBoard,
                            isPlayer: true,
                            label: "YOU"
                        )

                        if !viewModel.isMultiplayer {
                            controlsHint
                        }
                    }

                    if viewModel.isMultiplayer {
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

                        OpponentBoardView(board: viewModel.opponentBoard)
                    }
                }
                .padding(40)
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

// MARK: - Result Overlay

struct ResultOverlay: View {
    let message: String
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

                    GlassButton(title: "Back to Menu", icon: "arrow.left", color: c.accentCyan) {
                        onDismiss()
                    }
                }
                .padding(48)
            }
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
                        .focusable()
                        .onKeyPress(.leftArrow)  { viewModel.handleLeft(); return .handled }
                        .onKeyPress(.rightArrow) { viewModel.handleRight(); return .handled }
                        .onKeyPress(.downArrow)  { viewModel.handleDown(); return .handled }
                        .onKeyPress(.upArrow)    { viewModel.handleRotate(); return .handled }
                        .onKeyPress(.space)      { viewModel.handleDrop(); return .handled }
                        .onKeyPress("c")         { viewModel.handleHold(); return .handled }
                        .onKeyPress("C")         { viewModel.handleHold(); return .handled }
                        .focusSection()
                }

                if viewModel.showResult {
                    ResultOverlay(message: viewModel.resultMessage) {
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
