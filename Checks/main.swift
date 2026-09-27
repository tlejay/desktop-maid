// Layout-math checks. `swift test` can't run on Command Line Tools alone, so scripts/check.sh
// compiles this file together with Modes/ and WindowInfo.swift and runs it directly.
import CoreGraphics
import Foundation

private let screen = CGRect(x: 0, y: 25, width: 1000, height: 600)
private var failures = 0

private func expect(_ condition: Bool, _ message: String, line: Int = #line) {
    if !condition {
        failures += 1
        print("❌ line \(line): \(message)")
    }
}

private func windows(_ count: Int) -> [WindowInfo] {
    (0..<count).map {
        WindowInfo(id: WindowID($0 + 1), pid: 1, bundleID: "test", appName: "App", title: "\($0)",
                   frame: CGRect(x: 0, y: 0, width: 300, height: 200))
    }
}

/// Every frame must sit inside the usable area and none may overlap.
private func expectTiled(_ name: String, _ frames: [WindowID: CGRect], count: Int) {
    expect(frames.count == count, "\(name)(\(count)): got \(frames.count) frames")
    let rects = Array(frames.values)
    for rect in rects { expect(screen.contains(rect), "\(name)(\(count)): \(rect) outside screen") }
    for i in rects.indices {
        for j in rects.indices where i < j {
            expect(!rects[i].intersects(rects[j]), "\(name)(\(count)): overlap \(rects[i]) / \(rects[j])")
        }
    }
}

for n in 1...9 { expectTiled("grid", GridMode().arrange(windows: windows(n), in: screen, gap: 8), count: n) }
for n in 1...6 { expectTiled("mainStack", MainStackMode().arrange(windows: windows(n), in: screen, gap: 8), count: n) }
for n in 1...3 { expectTiled("split", SplitMode().arrange(windows: windows(n), in: screen, gap: 8), count: min(n, 2)) }

let grid3 = GridMode().arrange(windows: windows(3), in: screen, gap: 0)
expect(grid3[3]!.width == screen.width, "grid: short last row should stretch full width")
expect(grid3[1]!.width == screen.width / 2, "grid: first row should be halves")

let split = SplitMode().arrange(windows: windows(4), in: screen, gap: 0)
expect(Set(split.keys) == [1, 2], "split: only the two frontmost windows move")

let mainStack = MainStackMode().arrange(windows: windows(3), in: screen, gap: 0)
expect(mainStack[1]!.width == screen.width * 0.6, "mainStack: front window gets 60%")

let focus = FocusMode().arrange(windows: windows(3), in: screen, gap: 0)
expect(focus.count == 1 && focus[1]!.midX == screen.midX, "focus: only front window, centered")

let cascade = CascadeMode().arrange(windows: windows(20), in: screen, gap: 8)
expect(cascade.count == 20, "cascade: all windows placed")
for rect in cascade.values { expect(screen.contains(rect), "cascade: \(rect) outside screen") }
expect(cascade[1]!.minX > cascade[2]!.minX, "cascade: frontmost sits furthest down-right")

print(failures == 0 ? "✅ all layout checks passed" : "❌ \(failures) failure(s)")
exit(failures == 0 ? 0 : 1)
