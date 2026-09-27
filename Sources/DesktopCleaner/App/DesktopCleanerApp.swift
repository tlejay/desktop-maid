import SwiftUI

@main
struct DesktopCleanerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Desktop Cleaner", systemImage: "rectangle.3.group") {
            MenuContent()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = Accessibility.ensureTrusted()
        registerHotkeys()
    }

    private func registerHotkeys() {
        let actions: [String: @MainActor () -> Void] = Dictionary(
            uniqueKeysWithValues: LayoutModes.all.map { mode in (mode.id, { Arranger.shared.run(mode) }) }
        ).merging([
            "cleanDesk": { Arranger.shared.toggleCleanDesk() },
            "undo": { Arranger.shared.undo() },
        ]) { $1 }

        for shortcut in Shortcuts.all {
            guard let action = actions[shortcut.id] else { continue }
            HotkeyCenter.shared.register(keyCode: shortcut.keyCode) {
                MainActor.assumeIsolated { action() }
            }
        }
    }
}
