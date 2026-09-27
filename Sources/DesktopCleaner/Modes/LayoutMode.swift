import CoreGraphics

/// A layout is pure math: given windows (front-to-back) and the usable screen area, return target frames.
/// It must never touch the Accessibility API — `Arranger` applies the result.
protocol LayoutMode {
    var id: String { get }
    var title: String { get }
    /// Hide every app except the frontmost one after arranging.
    var hidesOtherApps: Bool { get }
    func arrange(windows: [WindowInfo], in screen: CGRect, gap: CGFloat) -> [WindowID: CGRect]
}

extension LayoutMode {
    var hidesOtherApps: Bool { false }
}

enum LayoutModes {
    static let all: [any LayoutMode] = [GridMode(), FocusMode(), SplitMode(), MainStackMode(), CascadeMode()]
}

/// Rectangle slicing helpers shared by all modes. `gap` is the space between slices.
enum Layout {
    static func columns(_ rect: CGRect, count: Int, gap: CGFloat) -> [CGRect] {
        guard count > 0 else { return [] }
        let width = (rect.width - gap * CGFloat(count - 1)) / CGFloat(count)
        return (0..<count).map { i in
            CGRect(x: rect.minX + CGFloat(i) * (width + gap), y: rect.minY, width: width, height: rect.height)
        }
    }

    static func rows(_ rect: CGRect, count: Int, gap: CGFloat) -> [CGRect] {
        guard count > 0 else { return [] }
        let height = (rect.height - gap * CGFloat(count - 1)) / CGFloat(count)
        return (0..<count).map { i in
            CGRect(x: rect.minX, y: rect.minY + CGFloat(i) * (height + gap), width: rect.width, height: height)
        }
    }

    /// Splits horizontally; `ratio` is the left side's share of the width.
    static func split(_ rect: CGRect, ratio: CGFloat, gap: CGFloat) -> (left: CGRect, right: CGRect) {
        let leftWidth = (rect.width - gap) * ratio
        let left = CGRect(x: rect.minX, y: rect.minY, width: leftWidth, height: rect.height)
        let right = CGRect(x: left.maxX + gap, y: rect.minY, width: rect.width - leftWidth - gap, height: rect.height)
        return (left, right)
    }
}
