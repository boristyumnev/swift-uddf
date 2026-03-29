// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-uddf",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "UDDF", targets: ["UDDF"])
    ],
    targets: [
        .target(
            name: "UDDF",
            path: "Sources/UDDF"
        ),
        .testTarget(
            name: "UDDFTests",
            dependencies: ["UDDF"],
            path: "Tests/UDDFTests",
            resources: [.copy("Resources")]
        )
    ]
)
