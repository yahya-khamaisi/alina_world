// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AlinaWorld",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "AlinaWorld", targets: ["AlinaWorld"])
    ],
    targets: [
        .executableTarget(
            name: "AlinaWorld",
            path: "Sources/AlinaWorld",
            resources: [.process("Resources")]
        )
    ]
)
