import AppKit

struct SavedWindow: Codable {
    let bundleID: String
    let title: String
    let frame: CGRect
}

struct NamedLayout: Codable, Identifiable {
    var id = UUID()
    var name: String
    var windows: [SavedWindow]
}

/// Named Layouts: remember where each app's windows sit, then put them back (launching missing apps).
@MainActor
final class LayoutStore: ObservableObject {
    static let shared = LayoutStore()
    private let key = "namedLayouts"

    @Published private(set) var layouts: [NamedLayout] = []

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([NamedLayout].self, from: data) {
            layouts = decoded
        }
    }

    func saveCurrent() {
        guard Accessibility.ensureTrusted() else { return }
        // Capture before the name prompt activates us and changes window order.
        let windows = WindowCollector.collect().compactMap { w in
            w.info.bundleID.map { SavedWindow(bundleID: $0, title: w.info.title, frame: w.info.frame) }
        }
        guard !windows.isEmpty,
              let name = NamePrompt.ask(title: "Save Layout", message: "\(windows.count) windows", defaultValue: "Layout \(layouts.count + 1)")
        else { return }

        if let index = layouts.firstIndex(where: { $0.name == name }) {
            layouts[index].windows = windows
        } else {
            layouts.append(NamedLayout(name: name, windows: windows))
        }
        persist()
    }

    func delete(_ layout: NamedLayout) {
        layouts.removeAll { $0.id == layout.id }
        persist()
    }

    func apply(_ layout: NamedLayout) {
        guard Accessibility.ensureTrusted() else { return }
        let bundleIDs = Set(layout.windows.map(\.bundleID))
        let running = NSWorkspace.shared.runningApplications

        for app in running where app.isHidden && bundleIDs.contains(app.bundleIdentifier ?? "") {
            app.unhide()
        }
        let runningIDs = Set(running.compactMap(\.bundleIdentifier))
        let missing = bundleIDs.subtracting(runningIDs)
        for id in missing {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
                NSWorkspace.shared.openApplication(at: url, configuration: .init())
            }
        }

        Task {
            // Give freshly launched / unhidden apps time to put their windows on screen.
            for _ in 0..<(missing.isEmpty ? 1 : 16) {
                try? await Task.sleep(for: .milliseconds(300))
                let present = Set(WindowCollector.collect().compactMap(\.info.bundleID))
                if bundleIDs.isSubset(of: present) { break }
            }
            place(layout)
        }
    }

    private func place(_ layout: NamedLayout) {
        var pool = WindowCollector.collect()
        var moves: [(ManagedWindow, CGRect)] = []
        for saved in layout.windows {
            let candidates = pool.indices.filter { pool[$0].info.bundleID == saved.bundleID }
            guard let index = candidates.first(where: { pool[$0].info.title == saved.title }) ?? candidates.first
            else { continue }
            moves.append((pool.remove(at: index), saved.frame))
        }
        Arranger.shared.apply(moves)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(layouts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
