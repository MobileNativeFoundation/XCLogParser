// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCLogParser",
    products: [
    	.executable(name: "xclogparser", targets: ["XCLogParserApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/1024jp/GzipSwift", from: "4.0.4"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.13.1"),
        .package(url: "https://github.com/Carthage/Commandant.git", from: "0.16.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.0.0"),
        .package(url: "https://github.com/mxcl/Path.swift.git", from: "0.13.0"),
    ],
    targets: [
        .target(
            name:"XcodeHasher",
            dependencies: ["CryptoSwift"]
        ),
        .target(
            name: "XCLogParser",
            dependencies: ["Gzip", "Stencil", "XcodeHasher", "Path"]
        ),
        .target(
            name: "XCLogParserApp",
            dependencies: ["XCLogParser", "Commandant"]
        ),
        .testTarget(
            name: "XCLogParserTests",
            dependencies: ["XCLogParser"]
        ),
    ]

)
