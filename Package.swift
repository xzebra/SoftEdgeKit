// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SoftEdgeKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "SoftEdgeKit", targets: ["SoftEdgeKit"])
    ],
    targets: [
        .target(name: "SoftEdgeKit"),
        .testTarget(name: "SoftEdgeKitTests", dependencies: ["SoftEdgeKit"])
    ]
)
