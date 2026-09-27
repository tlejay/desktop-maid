import SwiftUI

struct MenuContent: View {
    var body: some View {
        if !Accessibility.isTrusted {
            Button("Grant Accessibility Permission…") { Accessibility.requestPermission() }
            Divider()
        }
        ForEach(LayoutModes.all, id: \.id) { mode in
            Button(mode.title) {
                // TODO: collect windows → mode.arrange → WindowMover.apply
            }
            .disabled(true)
        }
        Divider()
        Button("Quit") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
