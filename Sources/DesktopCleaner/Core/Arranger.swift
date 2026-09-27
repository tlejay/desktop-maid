import AppKit

/// Orchestrates collect → compute → snapshot → apply, and owns Undo and Clean Desk state.
@MainActor
final class Arranger: ObservableObject {
    static let shared = Arranger()

    private struct Snapshot {
        var frames: [(AXUIElement, CGRect)] = []
        var hiddenApps: [NSRunningApplication] = []
    }

    private var undoStack: [Snapshot] = []
    private var cleanDeskHidden: [NSRunningApplication] = []

    @Published private(set) var canUndo = false
    @Published private(set) var isCleanDeskActive = false

    var gap: CGFloat { CGFloat(UserDefaults.standard.object(forKey: "gap") as? Double ?? 8) }

    func run(_ mode: any LayoutMode) {
        guard Accessibility.ensureTrusted() else { return }
        let screen = ScreenGeometry.activeScreen
        let screenFrame = ScreenGeometry.fullFrameAX(of: screen)
        let windows = WindowCollector.collect().filter {
            screenFrame.contains(CGPoint(x: $0.info.frame.midX, y: $0.info.frame.midY))
        }
        guard let front = windows.first else { return }

        let targets = mode.arrange(
            windows: windows.map(\.info),
            in: ScreenGeometry.usableFrameAX(of: screen),
            gap: gap
        )
        let moves = windows.compactMap { w in targets[w.info.id].map { (w, $0) } }

        var hidden: [NSRunningApplication] = []
        if mode.hidesOtherApps {
            hidden = visibleApps().filter { $0.processIdentifier != front.info.pid }
            hidden.forEach { $0.hide() }
        }
        apply(moves, alsoHid: hidden)
    }

    /// Moves windows and records an undo snapshot of where they were.
    func apply(_ moves: [(ManagedWindow, CGRect)], alsoHid hidden: [NSRunningApplication] = []) {
        guard !moves.isEmpty || !hidden.isEmpty else { return }
        pushUndo(Snapshot(frames: moves.map { ($0.0.element, $0.0.info.frame) }, hiddenApps: hidden))
        for (window, rect) in moves {
            WindowMover.setFrame(window.element, to: rect.integral)
        }
    }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        last.hiddenApps.forEach { $0.unhide() }
        for (element, rect) in last.frames {
            WindowMover.setFrame(element, to: rect)
        }
        canUndo = !undoStack.isEmpty
    }

    /// Hides every app so only the desktop shows; calling again brings them back.
    func toggleCleanDesk() {
        if isCleanDeskActive {
            cleanDeskHidden.forEach { $0.unhide() }
            cleanDeskHidden = []
            isCleanDeskActive = false
        } else {
            cleanDeskHidden = visibleApps()
            cleanDeskHidden.forEach { $0.hide() }
            isCleanDeskActive = !cleanDeskHidden.isEmpty
        }
    }

    private func pushUndo(_ snapshot: Snapshot) {
        undoStack.append(snapshot)
        if undoStack.count > 20 { undoStack.removeFirst() }
        canUndo = true
    }

    private func visibleApps() -> [NSRunningApplication] {
        let ownPID = ProcessInfo.processInfo.processIdentifier
        return NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isHidden && $0.processIdentifier != ownPID
        }
    }
}
