// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "ResultPromises",
  products: [
         .library(
             name: "ResultPromises",
             targets: ["ResultPromises"]
        ),
     ],
  targets: [
    .target(
        name:"ResultPromises",
        path: "./ResultPromises",
        sources: ["Sources"]
    )
  ]
)
