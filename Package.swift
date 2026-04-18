// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FloatingChatCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "FloatingChatCore", targets: ["FloatingChatCore"])
    ],
    targets: [
        .target(
            name: "FloatingChatCore",
            path: "FloatingChat",
            exclude: [
                "Assets.xcassets",
                "ContentView.swift",
                "FloatingChat-Bridging-Header.h",
                "FloatingChatApp.swift",
                "HotKeyController.swift",
                "Info.plist",
                "MessageBubble.swift",
                "SettingsSheet.swift"
            ],
            sources: [
                "APIKeyStore.swift",
                "AppConfiguration.swift",
                "AppSettingsStore.swift",
                "ChatModels.swift",
                "ChatViewModel.swift",
                "OpenAIService.swift"
            ],
            linkerSettings: [
                .linkedFramework("Security")
            ]
        ),
        .testTarget(
            name: "FloatingChatCoreTests",
            dependencies: ["FloatingChatCore"],
            path: "Tests/FloatingChatCoreTests"
        )
    ]
)