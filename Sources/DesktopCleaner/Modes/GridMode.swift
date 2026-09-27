import CoreGraphics

/// Tiles every window into a near-square grid; a short last row stretches to fill the width.
struct GridMode: LayoutMode {
    let id = "grid"
    let title = "Grid"

    func arrange(windows: [WindowInfo], in screen: CGRect, gap: CGFloat) -> [WindowID: CGRect] {
        let n = windows.count
        guard n > 0 else { return [:] }
        let cols = Int(ceil(sqrt(Double(n))))
        let rowCount = Int(ceil(Double(n) / Double(cols)))
        let rows = Layout.rows(screen.insetBy(dx: gap, dy: gap), count: rowCount, gap: gap)

        var result: [WindowID: CGRect] = [:]
        for (row, rowRect) in rows.enumerated() {
            let start = row * cols
            let items = Array(windows[start..<min(start + cols, n)])
            for (window, cell) in zip(items, Layout.columns(rowRect, count: items.count, gap: gap)) {
                result[window.id] = cell
            }
        }
        return result
    }
}
