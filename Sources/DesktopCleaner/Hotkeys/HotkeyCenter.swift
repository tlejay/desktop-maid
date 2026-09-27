import Carbon.HIToolbox
import SwiftUI

struct Shortcut {
    let id: String
    let key: Character
    let keyCode: Int
}

/// Every global shortcut is ⌃⌥ + a letter.
enum Shortcuts {
    static let all: [Shortcut] = [
        Shortcut(id: "grid", key: "g", keyCode: kVK_ANSI_G),
        Shortcut(id: "focus", key: "f", keyCode: kVK_ANSI_F),
        Shortcut(id: "split", key: "s", keyCode: kVK_ANSI_S),
        Shortcut(id: "mainStack", key: "m", keyCode: kVK_ANSI_M),
        Shortcut(id: "cascade", key: "c", keyCode: kVK_ANSI_C),
        Shortcut(id: "cleanDesk", key: "d", keyCode: kVK_ANSI_D),
        Shortcut(id: "undo", key: "z", keyCode: kVK_ANSI_Z),
    ]

    static func key(for id: String) -> KeyEquivalent? {
        all.first { $0.id == id }.map { KeyEquivalent($0.key) }
    }
}

/// Registers system-wide hotkeys through Carbon (still the only public API for this).
final class HotkeyCenter {
    static let shared = HotkeyCenter()
    private var actions: [UInt32: () -> Void] = [:]
    private var refs: [EventHotKeyRef] = []
    private var handlerInstalled = false

    func register(keyCode: Int, action: @escaping () -> Void) {
        installHandlerIfNeeded()
        let id = UInt32(actions.count + 1)
        actions[id] = action
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x4443_4C4E), id: id) // "DCLN"
        let modifiers = UInt32(controlKey | optionKey)
        if RegisterEventHotKey(UInt32(keyCode), modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &ref) == noErr,
           let ref {
            refs.append(ref)
        }
    }

    fileprivate func fire(_ id: UInt32) { actions[id]?() }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            HotkeyCenter.shared.fire(hotKeyID.id)
            return noErr
        }, 1, &spec, nil, nil)
    }
}
