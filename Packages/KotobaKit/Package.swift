// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "KotobaKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "KotobaKit", targets: ["KotobaKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.10.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.20")
    ],
    targets: [
        .target(
            name: "KotobaKit",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            linkerSettings: [.linkedLibrary("z")]
        ),
        .executableTarget(
            name: "kotoba-pack",
            dependencies: ["KotobaKit"]
        ),
        .testTarget(
            name: "KotobaKitTests",
            dependencies: [
                "KotobaKit",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            resources: [.copy("Fixtures")]
        )
    ]
)
