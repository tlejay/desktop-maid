import CoreGraphics

/// A layout is pure math: given windows and the usable screen area, return target frames.
/// It must never touch the Accessibility API — `WindowMover` applies the result.
protocol LayoutMode {
    var id: String { get }
    var title: String { get }
    func arrange(windows: [WindowInfo], in screen: CGRect) -> [WindowID: CGRect]
}

enum LayoutModes {
    // Register new modes here once implemented.
    static let all: [any LayoutMode] = []
}
