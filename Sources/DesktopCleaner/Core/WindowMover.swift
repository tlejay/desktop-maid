import ApplicationServices

enum WindowMover {
    /// Size → position → size: the first resize may be clamped by the screen edge, the second one lands it.
    static func setFrame(_ element: AXUIElement, to rect: CGRect) {
        element.setSize(rect.size)
        element.setPosition(rect.origin)
        element.setSize(rect.size)
    }
}
