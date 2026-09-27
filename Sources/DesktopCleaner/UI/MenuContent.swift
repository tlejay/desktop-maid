import ServiceManagement
import SwiftUI

struct MenuContent: View {
    @ObservedObject private var arranger = Arranger.shared
    @ObservedObject private var store = LayoutStore.shared
    @AppStorage("gap") private var gap: Double = 8
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        if !Accessibility.isTrusted {
            Button("⚠️ Grant Accessibility Permission…") { Accessibility.requestPermission() }
            Divider()
        }

        ForEach(LayoutModes.all, id: \.id) { mode in
            Button(mode.title) { arranger.run(mode) }
                .shortcut(for: mode.id)
        }

        Divider()
        Button(arranger.isCleanDeskActive ? "Restore Desk" : "Clean Desk") { arranger.toggleCleanDesk() }
            .shortcut(for: "cleanDesk")
        Button("Undo") { arranger.undo() }
            .shortcut(for: "undo")
            .disabled(!arranger.canUndo)

        Divider()
        Menu("Layouts") {
            ForEach(store.layouts) { layout in
                Button(layout.name) { store.apply(layout) }
            }
            if !store.layouts.isEmpty { Divider() }
            Button("Save Current Layout…") { store.saveCurrent() }
            if !store.layouts.isEmpty {
                Menu("Delete") {
                    ForEach(store.layouts) { layout in
                        Button(layout.name) { store.delete(layout) }
                    }
                }
            }
        }

        Divider()
        Picker("Gap", selection: $gap) {
            ForEach([0.0, 8, 16, 24], id: \.self) { Text("\(Int($0)) pt").tag($0) }
        }
        Toggle("Launch at Login", isOn: $launchAtLogin)
            .onChange(of: launchAtLogin) { _, enabled in
                try? enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
            }
        Button("Quit") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}

private extension View {
    /// Shows the global ⌃⌥ shortcut next to the menu item.
    @ViewBuilder func shortcut(for id: String) -> some View {
        if let key = Shortcuts.key(for: id) {
            keyboardShortcut(key, modifiers: [.control, .option])
        } else {
            self
        }
    }
}
