// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "IQPullToRefresh",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "IQPullToRefresh",
            targets: ["IQPullToRefresh"]
        )
    ],
    targets: [
        .target(
            name: "IQPullToRefresh",
            path: "IQPullToRefresh",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
