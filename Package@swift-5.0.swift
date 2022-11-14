// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCLogParser",
    platforms: [.macOS(.v10_13)],
    products: [
    	.executable(name: "xclogparser", targets: ["XCLogParserApp"]),
        .library(name: "XCLogParser", targets: ["XCLogParser"])
    ],
    dependencies: [
        .package(url: "https://github.com/1024jp/GzipSwift", from: "5.1.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .exact("1.3.3")),
        .package(url: "https://github.com/kylef/PathKit.git", from: "1.0.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0")),
    ],
    targets: [
        .target(
            name:"XcodeHasher",
            dependencies: ["CryptoSwift"]
        ),
        .target(
            name: "XCLogParser",
            dependencies: ["Gzip", "XcodeHasher", "PathKit"]
        ),
        .target(
            name: "XCLogParserApp",
            dependencies: [
                "XCLogParser",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "XCLogParserTests",
            dependencies: ["XCLogParser"]
        ),
    ]

)
