import AppKit

enum WindowCollector {
    /// Standard, visible windows on the current Space, ordered front-to-back.
    static func collect() -> [ManagedWindow] {
        let order = zOrder()
        let ownPID = ProcessInfo.processInfo.processIdentifier
        var result: [ManagedWindow] = []

        for app in NSWorkspace.shared.runningApplications
        where app.activationPolicy == .regular && !app.isHidden && app.processIdentifier != ownPID {
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            AXUIElementSetMessagingTimeout(axApp, 0.5) // don't hang on unresponsive apps
            guard let windows: [AXUIElement] = axApp.attribute(kAXWindowsAttribute) else { continue }

            for window in windows {
                guard (window.attribute(kAXRoleAttribute) as String?) == kAXWindowRole,
                      (window.attribute(kAXSubroleAttribute) as String?) == kAXStandardWindowSubrole,
                      (window.attribute(kAXMinimizedAttribute) as Bool?) != true,
                      (window.attribute("AXFullScreen") as Bool?) != true,
                      let id = window.windowID, order[id] != nil,
                      let frame = window.frame, frame.width >= 100, frame.height >= 60
                else { continue }

                let info = WindowInfo(
                    id: id,
                    pid: app.processIdentifier,
                    bundleID: app.bundleIdentifier,
                    appName: app.localizedName ?? "",
                    title: window.attribute(kAXTitleAttribute) ?? "",
                    frame: frame
                )
                result.append(ManagedWindow(info: info, element: window))
            }
        }
        return result.sorted { order[$0.info.id]! < order[$1.info.id]! }
    }

    /// Window number → stacking index (0 = frontmost). Only normal-layer, on-screen windows are included.
    private static func zOrder() -> [WindowID: Int] {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]] else { return [:] }
        var order: [WindowID: Int] = [:]
        for (index, entry) in list.enumerated() where (entry[kCGWindowLayer as String] as? Int) == 0 {
            if let number = entry[kCGWindowNumber as String] as? Int {
                order[WindowID(number)] = index
            }
        }
        return order
    }
}
