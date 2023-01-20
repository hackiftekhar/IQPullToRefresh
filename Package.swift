// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "IQPullToRefresh",
    platforms: [
        .iOS(.v11)
    ],
    products: [
       .library(name: "IQPullToRefresh", targets: ["IQPullToRefresh"])
   ],
   targets: [
       .target(
           name: "IQPullToRefresh",
           path: "IQPullToRefresh"
       )
   ]
)
