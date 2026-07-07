# LiquidTetris — Development Roadmap

## v1.0 (Current) — Foundation
- [x] Core Tetris engine (board, pieces, collision, rotation)
- [x] 7-bag randomizer
- [x] Ghost piece preview
- [x] Hold piece mechanic
- [x] Hard drop / soft drop
- [x] Score system with level progression
- [x] Liquid Glass UI (dark theme)
- [x] Light theme with toggle
- [x] MultipeerConnectivity networking (Bonjour auto-discovery)
- [x] Real-time board sync
- [x] Garbage line attack system
- [x] SwiftUI native keyboard input

---

## v1.1 — Polish & UX
- [x] **Pause menu** — ESC to pause, resume/quit options
- [x] **Game statistics** — pieces placed, lines sent, longest combo, Tetris count
- [x] **Piece lock delay** — 0.5s window to slide piece after landing, 15 max resets
- [x] **DAS (Delayed Auto Shift)** — smooth held-key movement (0.15s delay, 0.05s repeat)
- [x] **Next piece queue** — show 3 upcoming pieces
- [x] **Combo counter** — animated multiplier display
- [x] **Local 2-player mode** — P1: arrows, P2: WASD/E/Q
- [x] **Keyboard fix** — NSEvent global monitor, works without focus
- [ ] **Game start countdown** — 3-2-1-GO sync before multiplayer match
- [ ] **Rematch system** — both players agree to play again
- [ ] **Score history** — persistent local leaderboard
- [ ] **Sound effects** — move, rotate, drop, line clear, Tetris, game over
- [ ] **Haptic feedback** — subtle vibration on drop/clear (via trackpad)

## v1.2 — Visual Upgrade
- [x] **Active piece glow** — brighter gradient + thicker stroke on current piece
- [x] **Line clear animation** — flash white + scale up on cleared rows
- [x] **Hard drop shake** — board shakes briefly on hard drop
- [ ] **Tetromino glow effects** — animated neon glow around active pieces
- [ ] **Garbage warning** — red flash when opponent sends garbage
- [ ] **Background music** — ambient electronic soundtrack
- [ ] **Particle system** — sparks on hard drop, shatter on line clear
- [ ] **Board grid lines** — subtle grid overlay for better visual structure
- [ ] **Mini-map during gameplay** — small opponent preview in corner

## v1.3 — Competitive Features
- [ ] **Ranked mode** — ELO-based matchmaking rating
- [ ] **Match history** — wins/losses/last 10 games
- [ ] **Friend list** — remember paired devices
- [ ] **Chat** — quick emotes or text during match
- [ ] **Spectator mode** — watch ongoing matches
- [ ] **Tournaments** — bracket system for 4+ players

## v1.4 — Game Modes
- [ ] **Marathon** — classic endless with increasing speed
- [ ] **Sprint** — clear 40 lines as fast as possible
- [ ] **Ultra** — 2-minute time trial, highest score wins
- [ ] **Battle Royale** — 3-6 player free-for-all with garbage bombs
- [ ] **Co-op mode** — two players share one board
- [ ] **Puzzle mode** — pre-set boards, solve in minimum moves

## v1.5 — Advanced Networking
- [ ] **Internet multiplayer** — relay server for play over the internet
- [ ] **Room codes** — join games via 6-digit code
- [ ] **Reconnection** — handle Wi-Fi drops gracefully
- [ ] **Replay system** — record and playback matches
- [ ] **Anti-cheat** — validate board state server-side
- [ ] **Cross-platform** — iOS companion app via shared Swift package

## v2.0 — Ecosystem
- [ ] **Custom themes** — user-created color palettes and backgrounds
- [ ] **Piece skins** — unlockable tetromino visual styles
- [ ] **Achievements** — Tetris, Perfect Clear, 100 lines, etc.
- [ ] **Daily challenges** — special objectives with rewards
- [ ] **Localization** — multi-language support
- [ ] **Accessibility** — VoiceOver support, colorblind modes, adjustable speed
- [ ] **App Store release** — notarize, sandbox, distribute

---

## Technical Debt (Address Along the Way)
- [ ] Unit tests for GameBoard logic
- [ ] Unit tests for Tetromino rotation and collision
- [ ] Integration test for network message encoding/decoding
- [ ] Performance profiling for 60fps board rendering
- [ ] Memory leak audit for NetworkManager
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] SwiftLint integration
- [ ] Code coverage reporting
