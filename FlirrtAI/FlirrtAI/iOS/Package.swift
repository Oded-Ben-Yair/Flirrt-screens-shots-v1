// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Flirrt",
    platforms: [
        .iOS(.v16)
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
            path: "Flirrt"),
        .target(
            name: "FlirrtKeyboard",
            dependencies: [],
            path: "FlirrtKeyboard"),
        .target(
            name: "FlirrtShare",
            dependencies: [],
            path: "FlirrtShare"),
    ]
)