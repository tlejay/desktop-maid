// Dumps the frames each real LayoutMode produces for a sample desktop, as JSON for the README diagrams.
import CoreGraphics
import Foundation

let screen = CGRect(x: 0, y: 25, width: 1440, height: 800) // 1440x900 display minus menu bar and Dock
let apps = ["Browser", "Editor", "Terminal", "Notes", "Music"]
let messy: [CGRect] = [
    CGRect(x: 380, y: 110, width: 760, height: 520),
    CGRect(x: 60, y: 60, width: 640, height: 470),
    CGRect(x: 820, y: 360, width: 520, height: 330),
    CGRect(x: 180, y: 420, width: 420, height: 360),
    CGRect(x: 980, y: 70, width: 400, height: 300),
]
let windows = apps.enumerated().map { i, name in
    WindowInfo(id: WindowID(i + 1), pid: pid_t(i + 1), bundleID: name, appName: name, title: name, frame: messy[i])
}
func pack(_ frames: [WindowID: CGRect]) -> [[String: Any]] {
    windows.map { w in
        var d: [String: Any] = ["app": w.appName]
        if let r = frames[w.id] { d["x"] = r.minX; d["y"] = r.minY - screen.minY; d["w"] = r.width; d["h"] = r.height }
        else { d["hidden"] = true }
        return d
    }
}
var out: [String: Any] = ["screen": ["w": screen.width, "h": screen.height],
                          "messy": pack(Dictionary(uniqueKeysWithValues: windows.map { ($0.id, $0.frame) }))]
for mode in LayoutModes.all {
    var frames = mode.arrange(windows: windows, in: screen, gap: 8)
    // Split / Focus leave other windows where they were unless the mode hides their apps.
    if !mode.hidesOtherApps { for w in windows where frames[w.id] == nil { frames[w.id] = w.frame } }
    out[mode.id] = pack(frames)
}
let data = try! JSONSerialization.data(withJSONObject: out, options: [.sortedKeys])
print(String(data: data, encoding: .utf8)!)
