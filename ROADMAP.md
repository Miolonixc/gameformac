# LiquidTetris — Complete Project Documentation

> macOS Tetris with Liquid Glass UI, multiplayer over Wi-Fi, local 2P mode.
> SwiftUI + MultipeerConnectivity, serverless peer-to-peer.

---

## Table of Contents
1. [What's Done](#what-s-done)
2. [Current State](#current-state)
3. [Architecture](#architecture)
4. [Controls](#controls)
5. [Roadmap](#roadmap)
6. [Ideas & Concepts](#ideas--concepts)
7. [Technical Notes](#technical-notes)

---

## What's Done

### v1.0 — Foundation
- [x] Core Tetris engine — board, pieces, collision, rotation (SRS)
- [x] 7-bag randomizer — fair piece distribution
- [x] Ghost piece — shows where piece will land
- [x] Hold piece — swap current with hold slot
- [x] Hard drop / soft drop
- [x] Score system with level progression
- [x] Liquid Glass UI — dark theme (indigo/purple glass panels)
- [x] Light theme with toggle — frosted glass blue-gray
- [x] MultipeerConnectivity networking — Bonjour auto-discovery on same Wi-Fi
- [x] Real-time board sync — opponent board updates live
- [x] Garbage line attack system — send lines on multi-line clears
- [x] SwiftUI keyboard input

### v1.1 — Polish & UX
- [x] Pause menu — ESC to pause, resume/quit
- [x] Game statistics — pieces placed, lines sent, longest combo, Tetris count
- [x] Piece lock delay — 0.5s window to slide after landing, 15 max resets
- [x] DAS (Delayed Auto Shift) — smooth held-key movement (0.15s delay, 0.05s repeat)
- [x] Next piece queue — 3 upcoming pieces
- [x] Combo counter — animated multiplier display
- [x] Local 2-player mode — P1: arrows + Space/C, P2: WASD + Space/E
- [x] Keyboard fix — NSEvent global monitor, works without focus

### v1.2 — Visual Upgrade
- [x] Active piece glow — brighter gradient + thicker stroke
- [x] Line clear animation — flash white + scale up on cleared rows
- [x] Hard drop shake — board shakes briefly on hard drop
- [x] **Cascade line clear** — column-by-column left→right sweep (0.03s per col)
- [x] **Lock flash** — white overlay + 1.08x scale on placed pieces
- [x] **Impact rings** — 3 concentric glass rings expanding from center on hard drop
- [x] **Transparent falling pieces** — active piece visible with brightness boost
- [x] **Layout compact** — 820x680 window, 24px padding, 10pt stats font
- [x] **Theme toggle fix** — switched from @Environment to @EnvironmentObject

---

## Current State

```
Latest commit:  f521c63
Platform:       macOS 14+ (Sonoma), Swift 5.9+
Bundle:         LiquidTetris.app (proper .app bundle for keyboard input)
GitHub:         volodymyrk8/gameformac
Collaborator:   @Miolonixc (admin)
```

### What works now
- Single player Tetris with all core mechanics
- Networked 2P over Wi-Fi (auto-discover peer)
- Local 2P on same keyboard
- Dark/light theme toggle (persists in UserDefaults)
- Glass panel UI with shadows, gradients, blur materials
- Visual feedback: ghost piece, hold piece, 3-piece queue
- Smooth keyboard: DAS, lock delay, hard drop shake
- Cascade line clear, impact rings, lock flash animations
- Pause/resume, game over screen

---

## Architecture

### Project Structure
```
LiquidTetris/
├── Sources/LiquidTetris/
│   ├── LiquidTetrisApp.swift          # App entry, window config
│   ├── Models/
│   │   ├── Tetromino.swift            # Piece types, shapes, rotation, colors
│   │   ├── GameBoard.swift            # Core game logic, grid, physics
│   │   └── ThemeManager.swift         # Theme colors, dark/light modes
│   ├── Views/
│   │   ├── LobbyView.swift            # Main menu, network discovery
│   │   ├── ContentView.swift          # Game layout, overlays, stats
│   │   ├── GameBoardView.swift        # Board grid rendering, animations
│   │   ├── GlassComponents.swift      # GlassPanel, GlassButton, GlassCell
│   │   └── GameViewModel.swift        # Game loop, input, network callbacks
│   └── Networking/
│       └── NetworkManager.swift       # MultipeerConnectivity wrapper
├── run.sh                             # Build + launch as .app bundle
├── Info.plist                          # App metadata
└── ROADMAP.md                          # This file
```

### Key Design Decisions
| Decision | Why |
|----------|-----|
| MultipeerConnectivity (not Socket) | Serverless, auto-discovery, no backend needed |
| NSEvent.addLocalMonitorForEvents | .onKeyPress never worked — focus issues in terminal |
| @EnvironmentObject for theme | @Environment doesn't observe ObservableObject changes |
| Proper .app bundle | Terminal keeps keyboard focus otherwise |
| 7-bag randomizer | Standard Tetris fairness — each 7 pieces, all 7 types appear once |
| SRS rotation | Super Rotation System — standard wall kick offsets |
| Lock delay 0.5s / 15 resets | Competitive standard — enough time to slide, not infinite |

### Game Constants
```swift
struct GameConstants {
    static let rows = 20
    static let cols = 10
    static let cellSize: CGFloat = 28
    static let lockDelay: TimeInterval = 0.5
    static let maxLockResets = 15
    static let dasDelay: TimeInterval = 0.15
    static let dasRepeat: TimeInterval = 0.05
}
```

---

## Controls

### Player 1 (Keyboard)
| Key | Action |
|-----|--------|
| ← → | Move left/right |
| ↑ | Rotate |
| ↓ | Soft drop |
| Space | Hard drop |
| C | Hold piece |
| ESC | Pause |

### Player 2 (Local 2P)
| Key | Action |
|-----|--------|
| A / D | Move left/right |
| W | Rotate |
| S | Soft drop |
| Space | Hard drop |
| E | Hold piece |

### Network Play
- Host creates game → peer joins automatically via Bonjour
- Both players see each other's board in real-time
- Garbage lines sent on multi-line clears

---

## Roadmap

### v1.3 — Competitive Features
- [ ] Game start countdown — 3-2-1-GO sync before multiplayer match
- [ ] Rematch system — both players agree to play again
- [ ] Score history — persistent local leaderboard
- [ ] Ranked mode — ELO-based matchmaking rating
- [ ] Match history — wins/losses/last 10 games
- [ ] Friend list — remember paired devices
- [ ] Chat — quick emotes or text during match
- [ ] Spectator mode — watch ongoing matches
- [ ] Tournaments — bracket system for 4+ players

### v1.4 — Game Modes
- [ ] Marathon — classic endless with increasing speed
- [ ] Sprint — clear 40 lines as fast as possible
- [ ] Ultra — 2-minute time trial, highest score wins
- [ ] Battle Royale — 3-6 player free-for-all with garbage bombs
- [ ] Co-op mode — two players share one board
- [ ] Puzzle mode — pre-set boards, solve in minimum moves

### v1.5 — Audio & Haptics
- [ ] Sound effects — move, rotate, drop, line clear, Tetris, game over
- [ ] Haptic feedback — subtle vibration on drop/clear (via trackpad)
- [ ] Background music — ambient electronic soundtrack

### v1.6 — Visual Polish
- [ ] Tetromino glow effects — animated neon glow around active pieces
- [ ] Garbage warning — red flash when opponent sends garbage
- [ ] Particle system — sparks on hard drop, shatter on line clear
- [ ] Board grid lines — subtle grid overlay for better visual structure
- [ ] Mini-map during gameplay — small opponent preview in corner

### v1.7 — Advanced Networking
- [ ] Internet multiplayer — relay server for play over the internet
- [ ] Room codes — join games via 6-digit code
- [ ] Reconnection — handle Wi-Fi drops gracefully
- [ ] Replay system — record and playback matches
- [ ] Anti-cheat — validate board state server-side

### v1.8 — Cross-Platform
- [ ] iOS companion app — shared Swift package, same codebase
- [ ] iPad optimizations — larger touch targets, gesture controls
- [ ] Universal binary — macOS + iOS in one build via Xcode project
- [ ] CloudKit sync — sync scores, themes, settings across devices
- [ ] Handoff — start game on Mac, continue on iPhone
- [ ] iMessage integration — send game invites via Messages
- [ ] watchOS companion — score notifications, quick play mode

### v2.0 — Ecosystem
- [ ] Custom themes — user-created color palettes and backgrounds
- [ ] Piece skins — unlockable tetromino visual styles
- [ ] Achievements — Tetris, Perfect Clear, 100 lines, etc.
- [ ] Daily challenges — special objectives with rewards
- [ ] Localization — multi-language support
- [ ] Accessibility — VoiceOver support, colorblind modes, adjustable speed
- [ ] App Store release — notarize, sandbox, distribute

---

## Ideas & Concepts

### Gameplay Ideas
- **Power-ups** — temporary abilities like piece preview, row destruction, time slow
- **Theme packs** — unlockable visual themes (neon, retro, minimal, nature)
- **Boss battles** — AI opponent with special attack patterns
- **Zen mode** — no score, no timer, just relaxing play
- **Tutorial mode** — learn rotation systems, T-spins, combos
- **Community boards** — user-created custom boards with obstacles

### Technical Ideas
- **Metal rendering** — GPU-accelerated board rendering for particles
- **Core Data** — persistent game state, resume interrupted games
- **Push notifications** — "your friend is online, want to play?"
- **SharePlay** — play together via FaceTime
- **Shortcuts integration** — "start Tetris" via Siri
- **Widget** — show current high score or active game

### Visual Ideas
- **Liquid physics** — real fluid simulation on piece landing
- **Dynamic backgrounds** — parallax cityscapes or abstract art
- **Piece trails** — glowing trail behind falling pieces
- **Board ripple** — water ripple effect on hard drop
- **Glass refraction** — pieces distort background slightly
- **Color themes per piece** — I=blue, O=yellow, T=purple, etc. (already done)

### Multiplayer Ideas
- **Team mode** — 2v2 with shared garbage pool
- **Handicap system** — board height adjustment for skill difference
- **Speed chess style** — incremental time control
- **Clan system** — group identity, clan leaderboards
- **Live streaming** — built-in OBS integration

---

## Technical Notes

### Build & Run
```bash
cd LiquidTetris
swift build          # Build
./run.sh             # Launch as .app bundle
```

### Known Limitations
- macOS only (no iOS yet — needs SwiftUI lifecycle port)
- No sound effects yet
- No persistent score history
- Network requires same Wi-Fi (no internet play yet)
- No game countdown before multiplayer start

### Performance
- Target: 60fps board rendering
- 200 cells (20x10) + ghost piece + active piece = manageable
- MultipeerConnectivity handles ~50ms latency on local Wi-Fi
- Glass materials (.ultraThinMaterial) are GPU-accelerated

### Keyboard Input
- Uses `NSEvent.addLocalMonitorForEvents(mask: .keyDown)` — global within app
- `NSEvent.addLocalMonitorForEvents(mask: .keyUp)` — for DAS release
- `.onKeyPress` modifier doesn't work — SwiftUI macOS keyboard focus issues
- Proper .app bundle required — terminal app doesn't receive keyboard events

### Theme System
- `ThemeManager` is `ObservableObject` with `@Published var mode`
- Injected via `.environmentObject(theme)` (NOT `@Environment(\.theme)`)
- `@Environment` doesn't observe ObservableObject changes — that was a bug
- Colors defined as static `.dark` and `.light` ThemeColors instances
- Persisted to UserDefaults under key "themeMode"
