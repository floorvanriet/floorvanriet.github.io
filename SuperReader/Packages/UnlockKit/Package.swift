// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UnlockKit",
    defaultLocalization: "nl",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "UnlockKit", targets: ["UnlockKit"])
    ],
    targets: [
        .target(
            name: "UnlockKit",
            path: "Sources/UnlockKit"
        ),
        .testTarget(
            name: "UnlockKitTests",
            dependencies: ["UnlockKit"],
            path: "Tests/UnlockKitTests"
        )
    ]
)
