import SwiftUI

// MARK: - Window Accessor (makes window key for keyboard input)

struct WindowAccessor: NSViewRepresentable {
    var onWindowReady: ((NSWindow) -> Void)?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.onWindowReady?(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - App Entry

@main
struct LiquidTetrisApp: App {
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(theme)
                .frame(minWidth: 700, minHeight: 620)
                .background(WindowAccessor { window in
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                    window.title = "LiquidTetris"
                })
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 820, height: 680)
    }
}
