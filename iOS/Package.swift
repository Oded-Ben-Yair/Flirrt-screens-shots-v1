// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Vibe8",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Vibe8",
            targets: ["Vibe8"]),
        .library(
            name: "Vibe8Keyboard",
            targets: ["Vibe8Keyboard"]),
        .library(
            name: "Vibe8Share",
            targets: ["Vibe8Share"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/KeyboardKit/KeyboardKit.git", from: "9.9.0"),
    ],
    targets: [
        .target(
            name: "Vibe8",
            dependencies: [
                "Alamofire",
                "KeychainAccess"
            ],
            path: "Vibe8"),
        .target(
            name: "Vibe8Keyboard",
            dependencies: [
                .product(name: "KeyboardKit", package: "KeyboardKit")
            ],
            path: "Vibe8Keyboard"),
        .target(
            name: "Vibe8Share",
            dependencies: [],
            path: "Vibe8Share"),
    ]
)