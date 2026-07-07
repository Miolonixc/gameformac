import SwiftUI

struct GameBoardView: View {
    @ObservedObject var board: GameBoard
    let isPlayer: Bool
    var label: String = ""
    @Environment(\.theme) var theme
    @State private var dropShake: CGFloat = 0

    var body: some View {
        let c = theme.colors
        GlassPanel(cornerRadius: 20) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(c.textSecondary)
                            .textCase(.uppercase)
                    }
                    Spacer()
                    Text("\(board.score)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(c.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

                // Board grid
                VStack(spacing: 0) {
                    ForEach(0..<board.rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<board.cols, id: \.self) { col in
                                let cell = board.grid[row][col]
                                let ghostPos = isPlayer ? board.ghostPosition() : nil
                                let isGhost = isPlayer && ghostPos != nil && !cell.filled &&
                                    isGhostCell(row: row, col: col, ghostRow: ghostPos!.row, ghostCol: ghostPos!.col)
                                let isCurrentPiece = isPlayer && isCurrentPieceCell(row: row, col: col)
                                let isLineClearing = board.lineClearRows.contains(row)

                                GlassCell(
                                    color: ghostPos != nil && isGhost
                                        ? board.currentPiece?.type.color
                                        : cell.color?.color,
                                    filled: cell.filled,
                                    isGhost: isGhost && !cell.filled,
                                    isActive: isCurrentPiece,
                                    isClearing: isLineClearing
                                )
                            }
                        }
                    }
                }
                .padding(4)
                .offset(y: dropShake)
                .onChange(of: board.hardDropFlash) { _, flash in
                    if flash {
                        withAnimation(.easeOut(duration: 0.04)) {
                            dropShake = 4
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                            withAnimation(.easeInOut(duration: 0.08)) {
                                dropShake = -2
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            withAnimation(.easeOut(duration: 0.1)) {
                                dropShake = 0
                            }
                        }
                    }
                }

                // Bottom stats
                HStack {
                    VStack(spacing: 4) {
                        Text("QUEUE")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(c.textSecondary)
                            .textCase(.uppercase)
                        VStack(spacing: 6) {
                            ForEach(0..<min(3, board.pieceQueue.count), id: \.self) { i in
                                PreviewPiece(type: board.pieceQueue[i], cellSize: 12)
                            }
                        }
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text("LEVEL")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(c.textSecondary)
                            .textCase(.uppercase)
                        Text("\(board.level)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(c.textPrimary)
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text("LINES")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(c.textSecondary)
                            .textCase(.uppercase)
                        Text("\(board.linesCleared)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(c.textPrimary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .padding(.top, 6)
            }
        }
        .frame(
            width: CGFloat(GameConstants.cols) * GameConstants.cellSize + 32,
            height: CGFloat(GameConstants.rows) * GameConstants.cellSize + 120
        )
        .overlay(
            Group {
                if board.isGameOver {
                    ZStack {
                        c.overlayBackground
                        VStack(spacing: 12) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(c.accentRed)
                            Text("GAME OVER")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(c.textPrimary)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
        )
        .overlay(alignment: .topTrailing) {
            if board.stats.currentCombo >= 2 {
                GlassPanel(cornerRadius: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(c.accentOrange)
                        Text("\(board.stats.currentCombo)x")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundStyle(c.accentOrange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .padding(8)
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: board.stats.currentCombo)
            }
        }
    }

    private func isGhostCell(row: Int, col: Int, ghostRow: Int, ghostCol: Int) -> Bool {
        guard let piece = board.currentPiece else { return false }
        let shape = piece.cells
        for r in 0..<shape.count {
            for c in 0..<shape[r].count {
                if shape[r][c] == 1 {
                    if ghostRow + r == row && ghostCol + c == col {
                        return true
                    }
                }
            }
        }
        return false
    }

    private func isCurrentPieceCell(row: Int, col: Int) -> Bool {
        guard let piece = board.currentPiece else { return false }
        let shape = piece.cells
        for r in 0..<shape.count {
            for c in 0..<shape[r].count {
                if shape[r][c] == 1 {
                    if piece.row + r == row && piece.col + c == col {
                        return true
                    }
                }
            }
        }
        return false
    }
}

// MARK: - Opponent Board View

struct OpponentBoardView: View {
    @ObservedObject var board: GameBoard
    @Environment(\.theme) var theme

    var body: some View {
        let c = theme.colors
        GlassPanel(cornerRadius: 20) {
            VStack(spacing: 0) {
                HStack {
                    Text("OPPONENT")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(c.textSecondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text("\(board.score)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(c.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

                VStack(spacing: 0) {
                    ForEach(0..<board.rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<board.cols, id: \.self) { col in
                                let cell = board.grid[row][col]
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(cell.filled ? (cell.color?.color.opacity(0.7) ?? Color.gray) : c.cellEmpty)
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
                .padding(8)

                HStack {
                    VStack(spacing: 4) {
                        Text("LEVEL")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(c.textSecondary)
                        Text("\(board.level)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(c.textPrimary)
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Text("LINES")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundStyle(c.textSecondary)
                        Text("\(board.linesCleared)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(c.textPrimary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .frame(
            width: CGFloat(GameConstants.cols) * 12 + 60,
            height: CGFloat(GameConstants.rows) * 12 + 120
        )
    }
}
