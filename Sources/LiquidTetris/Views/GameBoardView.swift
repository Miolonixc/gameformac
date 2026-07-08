import SwiftUI

struct GameBoardView: View {
    @ObservedObject var board: GameBoard
    let isPlayer: Bool
    var label: String = ""
    var gameMode: GameMode = .marathon
    @EnvironmentObject var theme: ThemeManager
    @State private var dropShake: CGFloat = 0
    @State private var ringScales: [CGFloat] = [0, 0, 0]
    @State private var ringOpacities: [Double] = [0, 0, 0]

    // Line clear sweep animation
    @State private var sweepProgress: CGFloat = 0
    @State private var sweepActive: Bool = false

    // T-spin ring animation
    @State private var tSpinRingScale: CGFloat = 0
    @State private var tSpinRingOpacity: Double = 0

    // Tetris flash
    @State private var tetrisFlashOpacity: Double = 0

    // Perfect clear
    @State private var perfectClearScale: CGFloat = 0.5
    @State private var perfectClearOpacity: Double = 0

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
        .overlay(tSpinOverlay, alignment: .center)
        .overlay(tetrisFlashOverlay)
        .overlay(perfectClearOverlay, alignment: .center)
        .overlay(particleOverlay)
        .onChange(of: board.hardDropFlash) { _, flash in
            guard flash else { return }
            triggerDropEffects()
        }
        .onChange(of: board.lineClearCount) { _, count in
            guard count > 0 else { return }
            triggerLineClearSweep(count: count)
        }
        .onChange(of: board.showTSpinOverlay) { _, show in
            guard show else { return }
            triggerTSpinEffect()
        }
        .onChange(of: board.showTetrisFlash) { _, show in
            guard show else { return }
            triggerTetrisFlash()
        }
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
        .overlay(lineClearSweepOverlay)
        .offset(y: dropShake)
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

    // MARK: - Line Clear Sweep Overlay

    private var lineClearSweepOverlay: some View {
        GeometryReader { geo in
            if sweepActive {
                let boardWidth = geo.size.width
                let sweepX = sweepProgress * boardWidth

                // Vertical sweep line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.6),
                                .white.opacity(0.9),
                                .white.opacity(0.6),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: boardWidth * 0.15)
                    .position(x: sweepX, y: geo.size.height / 2)
                    .blendMode(.screen)

                // Horizontal flash bars on cleared rows
                ForEach(Array(board.lineClearRows), id: \.self) { row in
                    let rowY = CGFloat(row) * cellSize + cellSize / 2 + 4
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(height: cellSize)
                        .position(x: geo.size.width / 2, y: rowY)
                        .opacity(sweepProgress > 0 ? 1 : 0)
                        .animation(.easeOut(duration: 0.2), value: sweepProgress)
                }
            }
        }
        .allowsHitTesting(false)
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

    // MARK: - T-Spin Overlay

    private var tSpinOverlay: some View {
        let c = theme.colors
        return Group {
            if board.showTSpinOverlay {
                ZStack {
                    // Spinning ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [c.accentPurple, c.accentCyan, c.accentPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120 + tSpinRingScale * 60, height: 120 + tSpinRingScale * 60)
                        .opacity(tSpinRingOpacity)
                        .rotationEffect(.degrees(tSpinRingScale * 360))

                    // T-Spin text
                    VStack(spacing: 4) {
                        Text(board.tSpinIsMini ? "T-SPIN MINI" : "T-SPIN")
                            .font(.system(size: board.tSpinIsMini ? 16 : 22, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [c.accentPurple, c.accentCyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        if board.tSpinLinesCleared > 0 {
                            Text(board.tSpinLinesCleared == 1 ? "SINGLE" :
                                    board.tSpinLinesCleared == 2 ? "DOUBLE" : "TRIPLE")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(c.accentYellow)
                        }
                    }
                    .scaleEffect(tSpinRingScale > 0.5 ? 1.0 : 0.5)
                    .opacity(tSpinRingOpacity)
                }
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Tetris Flash Overlay

    private var tetrisFlashOverlay: some View {
        Group {
            if tetrisFlashOpacity > 0 {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(tetrisFlashOpacity * 0.4))
                    .blendMode(.screen)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Perfect Clear Overlay

    private var perfectClearOverlay: some View {
        let c = theme.colors
        return Group {
            if perfectClearOpacity > 0 {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(c.accentYellow)
                    Text("PERFECT CLEAR")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [c.accentYellow, c.accentCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("+3000")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(c.accentGreen)
                }
                .scaleEffect(perfectClearScale)
                .opacity(perfectClearOpacity)
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Particle Overlay

    private var particleOverlay: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(board.particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.x + 16,
                            y: particle.y + 16
                        )
                        .opacity(particle.opacity)
                        .blur(radius: particle.size > 4 ? 1 : 0)
                }
            }
            .allowsHitTesting(false)
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
                    .foregroundStyle(board.levelManager.isMilestone ? c.accentYellow : c.textPrimary)
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

    private func triggerLineClearSweep(count: Int) {
        sweepActive = true
        sweepProgress = 0

        // Sweep across the board
        withAnimation(.easeInOut(duration: 0.35)) {
            sweepProgress = 1.0
        }

        // Tetris flash for 4 lines
        if count >= 4 {
            withAnimation(.easeIn(duration: 0.05)) { tetrisFlashOpacity = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.25)) { tetrisFlashOpacity = 0 }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            sweepActive = false
            sweepProgress = 0
        }
    }

    private func triggerTSpinEffect() {
        // Ring animation
        withAnimation(.easeOut(duration: 0.3)) {
            tSpinRingScale = 1.0
            tSpinRingOpacity = 1.0
        }

        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                tSpinRingOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            tSpinRingScale = 0
            tSpinRingOpacity = 0
        }
    }

    private func triggerTetrisFlash() {
        withAnimation(.easeIn(duration: 0.05)) { tetrisFlashOpacity = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.3)) { tetrisFlashOpacity = 0 }
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
    @EnvironmentObject var theme: ThemeManager

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
