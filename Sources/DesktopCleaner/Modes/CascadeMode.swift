import CoreGraphics

/// Overlapping diagonal stack, like fanned cards; the frontmost window ends bottom-right so every title bar shows.
struct CascadeMode: LayoutMode {
    let id = "cascade"
    let title = "Cascade"
    var step: CGFloat = 32

    func arrange(windows: [WindowInfo], in screen: CGRect, gap: CGFloat) -> [WindowID: CGRect] {
        guard !windows.isEmpty else { return [:] }
        let area = screen.insetBy(dx: gap, dy: gap)
        let size = CGSize(width: area.width * 0.65, height: area.height * 0.75)
        let room = min(area.width - size.width, area.height - size.height)
        let slots = max(1, Int(room / step) + 1) // wrap around if there are more windows than fit

        var result: [WindowID: CGRect] = [:]
        for (i, window) in windows.reversed().enumerated() {
            let offset = CGFloat(i % slots) * step
            result[window.id] = CGRect(origin: CGPoint(x: area.minX + offset, y: area.minY + offset), size: size)
        }
        return result
    }
}
