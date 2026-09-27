import CoreGraphics

/// Centers the frontmost window at a comfortable reading size and hides every other app.
struct FocusMode: LayoutMode {
    let id = "focus"
    let title = "Focus"
    let hidesOtherApps = true

    func arrange(windows: [WindowInfo], in screen: CGRect, gap: CGFloat) -> [WindowID: CGRect] {
        guard let front = windows.first else { return [:] }
        let area = screen.insetBy(dx: gap, dy: gap)
        let width = area.width * 0.8
        let height = area.height
        return [front.id: CGRect(x: area.midX - width / 2, y: area.minY, width: width, height: height)]
    }
}
