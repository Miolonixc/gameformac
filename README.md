# LiquidTetris

A multiplayer Tetris game for macOS built with SwiftUI and MultipeerConnectivity, featuring a Liquid Glass design language.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

### Core Gameplay
- Classic Tetris mechanics with all 7 tetrominoes (I, O, T, S, Z, J, L)
- 7-bag randomizer for fair piece distribution
- Wall kick rotation system for smooth movement
- Ghost piece preview showing where the current piece will land
- Hold piece mechanic (press C to hold)
- Hard drop (Space) and soft drop (Down arrow)
- Progressive difficulty — speed increases every 10 lines cleared
- Garbage lines sent to opponent when clearing multiple lines

### Multiplayer
- **Automatic opponent discovery** via Bonjour/mDNS — no server required
- Host or Join a game on the same Wi-Fi network
- Real-time board synchronization over MultipeerConnectivity
- Garbage line attack system — clear multiple lines to send garbage to opponent
- Connection state UI with peer discovery status
- Graceful disconnection handling

### Liquid Glass UI
- Translucent glass panels with `.ultraThinMaterial` backgrounds
- Gradient strokes with light refraction effects on all panels
- Animated floating gradient orbs in the background
- Glassmorphic buttons with hover and press animations
- Glowing tetromino cells with type-specific colors
- Smooth theme transitions with 0.3s animation

### Theme System
- **Dark mode** — deep indigo/purple background with cyan and purple accents
- **Light mode** — frosted glass on soft blue-gray with muted accents
- Persistent theme preference saved to UserDefaults
- Theme toggle button in the top-right corner of lobby screens
- All components fully adapt to the active theme

### Controls
| Key | Action |
|-----|--------|
| ← → | Move piece left/right |
| ↑ | Rotate piece |
| ↓ | Soft drop |
| Space | Hard drop |
| C | Hold piece |

---

## Architecture

```
LiquidTetris/
├── Package.swift
└── Sources/LiquidTetris/
    ├── LiquidTetrisApp.swift          # App entry point, window config
    ├── Models/
    │   ├── Tetromino.swift            # Piece types, shapes, colors
    │   ├── GameBoard.swift            # Board state, collision, scoring
    │   └── ThemeManager.swift         # Theme mode, colors, persistence
    ├── Views/
    │   ├── ContentView.swift          # Root view, keyboard input routing
    │   ├── LobbyView.swift            # Main menu, multiplayer lobby
    │   ├── GameBoardView.swift        # Player & opponent board rendering
    │   ├── GameViewModel.swift        # Game loop, state coordination
    │   └── GlassComponents.swift      # Reusable glass UI components
    └── Networking/
        └── NetworkManager.swift       # MultipeerConnectivity wrapper
```

### Key Design Decisions
- **No server needed** — MultipeerConnectivity handles peer discovery and data transfer using Bonjour under the hood
- **Environment-based theming** — `@Environment(\.theme)` makes theme available to all child views without prop drilling
- **SwiftUI native keyboard input** — `.onKeyPress` (macOS 14+) for reliable key handling without NSEvent hacks
- **Codable board state** — Full game state is encodable for network sync and potential save/replay

---

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.9+
- Two Macs on the same Wi-Fi network for multiplayer

## Build & Run

```bash
cd LiquidTetris
swift build
swift run
```

Or open in Xcode:
```bash
open Package.swift
```

---

## Gameplay Rules

1. **Single Player** — clear lines, survive as long as possible, chase high scores
2. **Multiplayer** — clear 2+ lines at once to send garbage lines to your opponent
3. **Garbage system**: 2 lines = 1 garbage, 3 lines = 2 garbage, 4 lines (Tetris) = 3 garbage
4. **Win condition** — opponent's board fills up to the top
5. **Level progression** — speed increases every 10 lines cleared

---

## License

MIT
