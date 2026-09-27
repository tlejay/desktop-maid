import ApplicationServices
import CoreGraphics

typealias WindowID = CGWindowID

/// A snapshot of one on-screen window. Frames use AX coordinates (origin = top-left of main display).
struct WindowInfo: Hashable {
    let id: WindowID
    let pid: pid_t
    let bundleID: String?
    let appName: String
    let title: String
    let frame: CGRect
}

/// A window plus the AX handle needed to move it. Only `Core/` should touch `element`.
struct ManagedWindow {
    let info: WindowInfo
    let element: AXUIElement
}
