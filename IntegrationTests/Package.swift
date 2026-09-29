// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IntegrationTests",
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                .product(name: "SotoACM", package: "soto"),
                .product(name: "SotoAPIGateway", package: "soto"),
                .product(name: "SotoApiGatewayV2", package: "soto"),
                .product(name: "SotoCloudFront", package: "soto"),
                .product(name: "SotoCloudTrail", package: "soto"),
                .product(name: "SotoDynamoDB", package: "soto"),
                .product(name: "SotoEC2", package: "soto"),
                .product(name: "SotoIAM", package: "soto"),
                .product(name: "SotoLambda", package: "soto"),
                .product(name: "SotoRoute53", package: "soto"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "SotoS3Control", package: "soto"),
                .product(name: "SotoSES", package: "soto"),
                .product(name: "SotoSNS", package: "soto"),
                .product(name: "SotoSQS", package: "soto"),
                .product(name: "SotoSSM", package: "soto"),
                .product(name: "SotoSTS", package: "soto"),
                .product(name: "SotoTimestreamWrite", package: "soto"),
            ]
        )
    ]
)
