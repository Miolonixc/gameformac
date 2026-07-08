import SwiftUI

// MARK: - Glass Header (lens/refraction effect)

struct GlassHeader<Content: View>: View {
    var content: Content
    var cornerRadius: CGFloat = 20
    @EnvironmentObject var theme: ThemeManager
    @State private var hoverLocation: CGPoint = .zero
    @State private var isHovered = false

    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .background(
                ZStack {
                    // Base: ultra thin material for blur-through
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Semi-transparent glass body
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(theme.mode == .dark ? 0.08 : 0.45),
                                    Color.white.opacity(theme.mode == .dark ? 0.03 : 0.25),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Lens refraction: top-left specular highlight
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(theme.mode == .dark ? 0.15 : 0.6),
                                    Color.white.opacity(0.0),
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )

                    // Lens refraction: bottom-right subtle glow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(theme.mode == .dark ? 0.04 : 0.15),
                                ],
                                startPoint: .center,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Specular highlight spot (lens焦点)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.25 : 0.12),
                                    Color.white.opacity(0.0),
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .position(hoverLocation)
                        .opacity(isHovered ? 1 : 0.5)
                        .animation(.easeInOut(duration: 0.3), value: isHovered)

                    // Border: top highlight + bottom shadow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(theme.mode == .dark ? 0.3 : 0.7),
                                    Color.white.opacity(theme.mode == .dark ? 0.08 : 0.2),
                                    Color.white.opacity(theme.mode == .dark ? 0.15 : 0.4),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(theme.mode == .dark ? 0.3 : 0.08), radius: 20, x: 0, y: 10)
            .shadow(color: .white.opacity(theme.mode == .dark ? 0.05 : 0.4), radius: 1, x: 0, y: 1)
            .onHover { hovering in
                isHovered = hovering
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    hoverLocation = location
                    isHovered = true
                case .ended:
                    isHovered = false
                }
            }
    }
}

// MARK: - Glass Button (lens/refraction effect)

struct GlassButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var hoverLocation: CGPoint = .zero
    @EnvironmentObject var theme: ThemeManager

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
                    // Base blur material
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)

                    // Semi-transparent glass body
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(isHovered ? 0.22 : 0.12),
                                    color.opacity(isHovered ? 0.10 : 0.05),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Lens highlight: top-left specular
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.2 : 0.1),
                                    Color.clear,
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )

                    // Lens highlight: bottom-right subtle
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(isHovered ? 0.08 : 0.03),
                                ],
                                startPoint: .center,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Specular spot (follows cursor)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.3 : 0.0),
                                    Color.clear,
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .position(hoverLocation)
                        .opacity(isHovered ? 1 : 0)

                    // Border
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(isHovered ? 0.6 : 0.35),
                                    color.opacity(0.08),
                                    color.opacity(isHovered ? 0.3 : 0.15),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.03 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                hoverLocation = location
                isHovered = true
            case .ended:
                isHovered = false
            }
        }
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in isPressed = pressing }, perform: {})
    }
}

// MARK: - Glass Panel (standard, no lens)

struct GlassPanel<Content: View>: View {
    var content: Content
    var cornerRadius: CGFloat = 24
    @EnvironmentObject var theme: ThemeManager

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

// MARK: - Glass Card

struct GlassCard: View {
    let title: String
    let value: String
    var icon: String = "star.fill"
    @EnvironmentObject var theme: ThemeManager

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
    @EnvironmentObject var theme: ThemeManager

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
    @EnvironmentObject var theme: ThemeManager

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

// MARK: - Theme Toggle Button (lens glass)

struct ThemeToggleButton: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var isHovered = false

    var body: some View {
        Button(action: { theme.toggle() }) {
            Image(systemName: theme.mode.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.colors.textSecondary)
                .frame(width: 36, height: 36)
                .background(
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Circle().fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.2 : 0.1),
                                    Color.white.opacity(0.03),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(isHovered ? 0.2 : 0.08),
                                        Color.clear,
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 18
                                )
                            )
                        Circle().stroke(
                            Color.white.opacity(isHovered ? 0.4 : 0.2),
                            lineWidth: 1
                        )
                    }
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovered = hovering }
    }
}
