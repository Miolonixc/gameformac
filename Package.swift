// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LiquidTetris",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LiquidTetris",
            path: "Sources/LiquidTetris",
            linkerSettings: [
                .linkedFramework("MultipeerConnectivity"),
                .linkedFramework("CryptoKit"),
            ]
        )
    ]
)
