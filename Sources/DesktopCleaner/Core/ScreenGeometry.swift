import AppKit

/// The single place that converts between Cocoa (bottom-left origin) and AX (top-left origin) coordinates.
enum ScreenGeometry {
    private static var primaryHeight: CGFloat { NSScreen.screens.first?.frame.height ?? 0 }

    static func toAX(_ cocoaRect: CGRect) -> CGRect {
        CGRect(x: cocoaRect.minX, y: primaryHeight - cocoaRect.maxY, width: cocoaRect.width, height: cocoaRect.height)
    }

    /// The screen under the mouse pointer — the one the user is looking at.
    static var activeScreen: NSScreen {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    /// Usable area (excludes menu bar and Dock) in AX coordinates.
    static func usableFrameAX(of screen: NSScreen) -> CGRect { toAX(screen.visibleFrame) }

    static func fullFrameAX(of screen: NSScreen) -> CGRect { toAX(screen.frame) }
}
