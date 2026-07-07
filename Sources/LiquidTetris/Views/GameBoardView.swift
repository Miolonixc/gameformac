import SwiftUI

struct GameBoardView: View {
    @ObservedObject var board: GameBoard
    let isPlayer: Bool
    var label: String = ""
    @Environment(\.theme) var theme
    @State private var dropShake: CGFloat = 0
    @State private var ringScales: [CGFloat] = [0, 0, 0]
    @State private var ringOpacities: [Double] = [0, 0, 0]

    private let cellSize = GameConstants.cellSize

    var body: some View {
        GlassPanel(cornerRadius: 20) {
            VStack(spacing: 0) {
                headerView
                boardGrid
                bottomStats
            }
        }
        .frame(
            width: CGFloat(GameConstants.cols) * cellSize + 32,
            height: CGFloat(GameConstants.rows) * cellSize + 100
        )
        .overlay(gameOverOverlay)
        .overlay(comboOverlay, alignment: .topTrailing)
    }

    // MARK: - Header

    private var headerView: some View {
        let c = theme.colors
        return HStack {
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
    }

    // MARK: - Board Grid

    private var boardGrid: some View {
        return VStack(spacing: 0) {
            ForEach(0..<board.rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<board.cols, id: \.self) { col in
                        cellView(row: row, col: col)
                    }
                }
            }
        }
        .padding(4)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(impactRingsOverlay)
        .offset(y: dropShake)
        .onChange(of: board.hardDropFlash) { _, flash in
            guard flash else { return }
            triggerDropEffects()
        }
    }

    // MARK: - Cell

    @ViewBuilder
    private func cellView(row: Int, col: Int) -> some View {
        let cell = board.grid[row][col]
        let ghostPos = isPlayer ? board.ghostPosition() : nil
        let ghost = isGhost(row: row, col: col, ghostPos: ghostPos)
        let current = isCurrent(row: row, col: col)
        let clearing = board.clearingCol >= 0 && board.lineClearRows.contains(row) && col <= board.clearingCol
        let locked = isJustLocked(row: row, col: col)

        GlassCell(
            color: cellColor(cell: cell, ghostPos: ghostPos, current: current, ghost: ghost),
            filled: cell.filled || current,
            isGhost: ghost && !cell.filled,
            isActive: current,
            isClearing: clearing,
            isJustLocked: locked
        )
    }

    // MARK: - Impact Rings

    private var impactRingsOverlay: some View {
        let boardHeight = CGFloat(GameConstants.rows) * cellSize
        return GeometryReader { geo in
            if board.dropImpactCol >= 0 {
                let x = CGFloat(board.dropImpactCol) * cellSize + cellSize / 2 + 4
                let y = boardHeight / 2 + 4
                let color = board.dropImpactColor
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        let scale = ringScales[safe: i] ?? 0
                        let opacity = ringOpacities[safe: i] ?? 0
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(color.opacity(opacity), lineWidth: 2)
                            .frame(width: 30 + scale * 120, height: 30 + scale * 120)
                            .position(x: x, y: y)
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Bottom Stats

    private var bottomStats: some View {
        let c = theme.colors
        return HStack {
            VStack(spacing: 4) {
                Text("QUEUE")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
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
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(c.textSecondary)
                    .textCase(.uppercase)
                Text("\(board.level)")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(c.textPrimary)
            }
            Spacer()
            VStack(spacing: 4) {
                Text("LINES")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(c.textSecondary)
                    .textCase(.uppercase)
                Text("\(board.linesCleared)")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(c.textPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .padding(.top, 6)
    }

    // MARK: - Overlays

    private var gameOverOverlay: some View {
        let c = theme.colors
        return Group {
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
    }

    private var comboOverlay: some View {
        let c = theme.colors
        return Group {
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

    // MARK: - Effects

    private func triggerDropEffects() {
        withAnimation(.easeOut(duration: 0.04)) { dropShake = 4 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            withAnimation(.easeInOut(duration: 0.08)) { dropShake = -2 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.1)) { dropShake = 0 }
        }
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                withAnimation(.easeOut(duration: 0.35)) {
                    ringScales[i] = 1
                    ringOpacities[i] = 0.5
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeIn(duration: 0.15)) { ringOpacities[i] = 0 }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ringScales = [0, 0, 0]
            ringOpacities = [0, 0, 0]
        }
    }

    // MARK: - Helpers

    private func isGhost(row: Int, col: Int, ghostPos: (row: Int, col: Int)?) -> Bool {
        guard isPlayer, let pos = ghostPos, let piece = board.currentPiece else { return false }
        for r in 0..<piece.cells.count {
            for c in 0..<piece.cells[r].count {
                if piece.cells[r][c] == 1 && pos.row + r == row && pos.col + c == col {
                    return true
                }
            }
        }
        return false
    }

    private func isCurrent(row: Int, col: Int) -> Bool {
        guard isPlayer, let piece = board.currentPiece else { return false }
        for r in 0..<piece.cells.count {
            for c in 0..<piece.cells[r].count {
                if piece.cells[r][c] == 1 && piece.row + r == row && piece.col + c == col {
                    return true
                }
            }
        }
        return false
    }

    private func isJustLocked(row: Int, col: Int) -> Bool {
        guard isPlayer else { return false }
        return board.justLockedCells.contains { $0.row == row && $0.col == col }
    }

    private func cellColor(cell: Cell, ghostPos: (row: Int, col: Int)?, current: Bool, ghost: Bool) -> Color? {
        if current {
            return board.currentPiece?.type.color
        }
        if ghost {
            return board.currentPiece?.type.color
        }
        return cell.color?.color
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
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
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(c.textSecondary)
                        Text("\(board.level)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(c.textPrimary)
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Text("LINES")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(c.textSecondary)
                        Text("\(board.linesCleared)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(c.textPrimary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .frame(
            width: CGFloat(GameConstants.cols) * 12 + 60,
            height: CGFloat(GameConstants.rows) * 12 + 100
        )
    }
}
