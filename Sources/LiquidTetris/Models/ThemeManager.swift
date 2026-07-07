import SwiftUI

// MARK: - Theme

enum ThemeMode: String, CaseIterable {
    case dark
    case light

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }

    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
}

// MARK: - Theme Colors

struct ThemeColors {
    // Background
    let bgTop: Color
    let bgMiddle: Color
    let bgBottom: Color

    // Glass panels
    let panelFill: Color
    let panelStrokeTop: Color
    let panelStrokeBottom: Color
    let panelShadow: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color

    // Accents
    let accentCyan: Color
    let accentPurple: Color
    let accentGreen: Color
    let accentOrange: Color
    let accentYellow: Color
    let accentRed: Color

    // Board
    let cellEmpty: Color
    let cellStroke: Color
    let boardBackground: Color

    // Overlay
    let overlayBackground: Color

    static let dark = ThemeColors(
        bgTop: Color(red: 0.05, green: 0.05, blue: 0.15),
        bgMiddle: Color(red: 0.02, green: 0.02, blue: 0.08),
        bgBottom: Color(red: 0.08, green: 0.03, blue: 0.12),

        panelFill: .white.opacity(0.05),
        panelStrokeTop: .white.opacity(0.25),
        panelStrokeBottom: .white.opacity(0.08),
        panelShadow: .black.opacity(0.25),

        textPrimary: .white,
        textSecondary: .white.opacity(0.6),
        textMuted: .white.opacity(0.3),

        accentCyan: .cyan,
        accentPurple: Color(red: 0.7, green: 0.3, blue: 1.0),
        accentGreen: .green,
        accentOrange: .orange,
        accentYellow: .yellow,
        accentRed: .red,

        cellEmpty: Color.white.opacity(0.04),
        cellStroke: Color.white.opacity(0.08),
        boardBackground: Color.black.opacity(0.2),

        overlayBackground: Color.black.opacity(0.7)
    )

    static let light = ThemeColors(
        bgTop: Color(red: 0.85, green: 0.90, blue: 0.98),
        bgMiddle: Color(red: 0.92, green: 0.95, blue: 1.0),
        bgBottom: Color(red: 0.88, green: 0.92, blue: 0.97),

        panelFill: .white.opacity(0.55),
        panelStrokeTop: .white.opacity(0.9),
        panelStrokeBottom: .white.opacity(0.4),
        panelShadow: .black.opacity(0.08),

        textPrimary: Color(red: 0.1, green: 0.1, blue: 0.15),
        textSecondary: Color(red: 0.35, green: 0.35, blue: 0.4),
        textMuted: Color(red: 0.6, green: 0.6, blue: 0.65),

        accentCyan: Color(red: 0.0, green: 0.65, blue: 0.8),
        accentPurple: Color(red: 0.55, green: 0.2, blue: 0.85),
        accentGreen: Color(red: 0.15, green: 0.7, blue: 0.35),
        accentOrange: Color(red: 0.9, green: 0.55, blue: 0.1),
        accentYellow: Color(red: 0.9, green: 0.8, blue: 0.1),
        accentRed: Color(red: 0.9, green: 0.2, blue: 0.25),

        cellEmpty: Color.black.opacity(0.06),
        cellStroke: Color.black.opacity(0.1),
        boardBackground: Color.white.opacity(0.3),

        overlayBackground: Color.black.opacity(0.5)
    )
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
        }
    }

    var colors: ThemeColors {
        switch mode {
        case .dark: return .dark
        case .light: return .light
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "themeMode") ?? ThemeMode.dark.rawValue
        self.mode = ThemeMode(rawValue: saved) ?? .dark
    }

    func toggle() {
        withAnimation(.easeInOut(duration: 0.3)) {
            mode = mode == .dark ? .light : .dark
        }
    }
}

// MARK: - Environment Key

struct ThemeKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var theme: ThemeManager {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
