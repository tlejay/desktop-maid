import CoreGraphics

typealias WindowID = CGWindowID

/// A snapshot of one on-screen window. Frames use AX coordinates (origin = top-left of main display).
struct WindowInfo: Hashable {
    let id: WindowID
    let pid: pid_t
    let appName: String
    let title: String
    let frame: CGRect
}
