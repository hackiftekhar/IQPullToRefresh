import PackageDescription

let package = Package(
    name: "IQPullToRefresh",
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
