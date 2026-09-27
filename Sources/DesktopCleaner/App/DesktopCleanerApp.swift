import SwiftUI

@main
struct DesktopCleanerApp: App {
    var body: some Scene {
        MenuBarExtra("Desktop Cleaner", systemImage: "rectangle.3.group") {
            MenuContent()
        }
    }
}
