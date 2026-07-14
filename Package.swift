// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HydrationPet",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "HydrationPet",
            path: "Sources/HydrationPet",
            resources: [
                .copy("Resources/Assets")
            ]
        )
    ]
)
