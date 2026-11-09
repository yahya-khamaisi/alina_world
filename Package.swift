// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "AlinaWorld",
    platforms: [.macOS(.v27)],
    products: [
        .executable(name: "AlinaWorld", targets: ["AlinaWorld"])
    ],
    targets: [
        .executableTarget(
            name: "AlinaWorld",
            path: "Sources/AlinaWorld",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "AlinaWorldTests", dependencies: ["AlinaWorld"])
    ]
)
