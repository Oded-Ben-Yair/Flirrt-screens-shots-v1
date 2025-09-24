// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Flirrt",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Flirrt",
            targets: ["Flirrt"]),
        .library(
            name: "FlirrtKeyboard",
            targets: ["FlirrtKeyboard"]),
        .library(
            name: "FlirrtShare",
            targets: ["FlirrtShare"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "Flirrt",
            dependencies: [
                "Alamofire",
                "KeychainAccess"
            ],
            path: "Flirrt",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .swiftLanguageMode(.v6)
            ]),
        .target(
            name: "FlirrtKeyboard",
            dependencies: [],
            path: "FlirrtKeyboard",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .swiftLanguageMode(.v6)
            ]),
        .target(
            name: "FlirrtShare",
            dependencies: [],
            path: "FlirrtShare",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .swiftLanguageMode(.v6)
            ]),
    ]
)