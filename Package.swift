// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DesktopCleaner",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DesktopCleaner",
            path: "Sources/DesktopCleaner",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
