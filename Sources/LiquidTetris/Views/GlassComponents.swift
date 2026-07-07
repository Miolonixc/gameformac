import SwiftUI

// MARK: - Liquid Glass Panel

struct GlassPanel<Content: View>: View {
    var content: Content
    var cornerRadius: CGFloat = 24
    @Environment(\.theme) var theme

    init(cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        let c = theme.colors
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(c.panelFill)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [c.panelStrokeTop, c.panelStrokeBottom, c.panelStrokeTop.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: c.panelShadow, radius: 20, x: 0, y: 10)
            .shadow(color: .white.opacity(theme.mode == .dark ? 0.05 : 0.3), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Glass Button

struct GlassButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @Environment(\.theme) var theme

    var body: some View {
        let c = theme.colors
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(c.textPrimary)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)

                    RoundedRectangle(cornerRadius: 18)
                        .fill(color.opacity(isHovered ? 0.2 : 0.1))

                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.5),
                                    color.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovered = hovering }
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in isPressed = pressing }, perform: {})
    }
}

// MARK: - Glass Card

struct GlassCard: View {
    let title: String
    let value: String
    var icon: String = "star.fill"
    @Environment(\.theme) var theme

    var body: some View {
        let c = theme.colors
        GlassPanel(cornerRadius: 16) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(c.textSecondary)
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(c.textSecondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(c.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minWidth: 80)
        }
    }
}

// MARK: - Glass Cell

struct GlassCell: View {
    let color: Color?
    let filled: Bool
    var isGhost: Bool = false
    var isActive: Bool = false
    var isClearing: Bool = false
    var isJustLocked: Bool = false
    var cellSize: CGFloat = GameConstants.cellSize
    @Environment(\.theme) var theme

    var body: some View {
        let c = theme.colors
        RoundedRectangle(cornerRadius: 4)
            .fill(cellFill(colors: c))
            .frame(width: cellSize - 2, height: cellSize - 2)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(cellStroke(colors: c), lineWidth: isActive ? 1.5 : 0.5)
            )
            .shadow(color: (color ?? .clear).opacity(filled ? (isActive ? 0.8 : 0.4) : 0), radius: isActive ? 6 : 3, x: 0, y: 1)
            .brightness(isClearing ? 0.6 : (isJustLocked ? 0.4 : (isActive ? 0.15 : 0)))
            .overlay(
                isJustLocked ? RoundedRectangle(cornerRadius: 4).fill(.white.opacity(0.25)) : nil
            )
            .scaleEffect(isClearing ? 1.05 : (isJustLocked ? 1.08 : 1.0))
            .animation(.easeOut(duration: 0.1), value: isClearing)
            .animation(.easeOut(duration: 0.15), value: isJustLocked)
    }

    private func cellFill(colors c: ThemeColors) -> some ShapeStyle {
        if isClearing, let color = color {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.white, color, color.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else if isGhost {
            return AnyShapeStyle(color?.opacity(0.2) ?? c.cellEmpty)
        } else if isActive, let color = color {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else if filled, let color = color {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(c.cellEmpty)
        }
    }

    private func cellStroke(colors c: ThemeColors) -> some ShapeStyle {
        if isClearing {
            return AnyShapeStyle(Color.white.opacity(0.8))
        } else if filled, let color = color {
            return AnyShapeStyle(color.opacity(isActive ? 0.9 : 0.6))
        } else {
            return AnyShapeStyle(c.cellStroke)
        }
    }
}

// MARK: - Preview Board

struct PreviewPiece: View {
    let type: TetrominoType?
    var cellSize: CGFloat = 20

    var body: some View {
        if let type = type {
            let shape = type.shape
            VStack(spacing: 2) {
                ForEach(0..<shape.count, id: \.self) { r in
                    HStack(spacing: 2) {
                        ForEach(0..<shape[r].count, id: \.self) { c in
                            if shape[r][c] == 1 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: [type.color, type.color.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: cellSize, height: cellSize)
                            } else {
                                Color.clear
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
        } else {
            Color.clear
                .frame(width: cellSize * 4, height: cellSize * 4)
        }
    }
}

// MARK: - Animated Gradient Background

struct LiquidBackground: View {
    @State private var phase: CGFloat = 0
    @Environment(\.theme) var theme

    var body: some View {
        let c = theme.colors
        LinearGradient(
            colors: [c.bgTop, c.bgMiddle, c.bgBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            ZStack {
                Circle()
                    .fill(c.accentCyan.opacity(0.06))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: phase.truncatingRemainder(dividingBy: 200) - 100,
                            y: (phase * 0.7).truncatingRemainder(dividingBy: 200) - 100)
                Circle()
                    .fill(c.accentPurple.opacity(0.05))
                    .frame(width: 350, height: 350)
                    .blur(radius: 70)
                    .offset(x: -(phase * 0.5).truncatingRemainder(dividingBy: 200) + 100,
                            y: -(phase * 0.3).truncatingRemainder(dividingBy: 200) + 100)
            }
        )
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = 200
            }
        }
    }
}

// MARK: - Theme Toggle Button

struct ThemeToggleButton: View {
    @Environment(\.theme) var theme

    var body: some View {
        Button(action: { theme.toggle() }) {
            Image(systemName: theme.mode.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.colors.textSecondary)
                .frame(width: 36, height: 36)
                .background(
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Circle().fill(theme.colors.panelFill)
                        Circle().stroke(theme.colors.panelStrokeTop.opacity(0.3), lineWidth: 1)
                    }
                )
        }
        .buttonStyle(.plain)
    }
}
