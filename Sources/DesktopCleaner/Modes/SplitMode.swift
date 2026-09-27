import CoreGraphics

/// The two frontmost windows side by side, 50/50. Other windows are left alone.
struct SplitMode: LayoutMode {
    let id = "split"
    let title = "Split"

    func arrange(windows: [WindowInfo], in screen: CGRect, gap: CGFloat) -> [WindowID: CGRect] {
        let pair = Array(windows.prefix(2))
        let cells = Layout.columns(screen.insetBy(dx: gap, dy: gap), count: pair.count, gap: gap)
        return Dictionary(uniqueKeysWithValues: zip(pair.map(\.id), cells))
    }
}
