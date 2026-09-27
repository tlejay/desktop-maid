import CoreGraphics

/// Frontmost window takes the left 60%; the rest stack vertically on the right.
struct MainStackMode: LayoutMode {
    let id = "mainStack"
    let title = "Main + Stack"
    var ratio: CGFloat = 0.6

    func arrange(windows: [WindowInfo], in screen: CGRect, gap: CGFloat) -> [WindowID: CGRect] {
        guard let main = windows.first else { return [:] }
        let area = screen.insetBy(dx: gap, dy: gap)
        let rest = windows.dropFirst()
        guard !rest.isEmpty else { return [main.id: area] }

        let (left, right) = Layout.split(area, ratio: ratio, gap: gap)
        var result = [main.id: left]
        for (window, cell) in zip(rest, Layout.rows(right, count: rest.count, gap: gap)) {
            result[window.id] = cell
        }
        return result
    }
}
