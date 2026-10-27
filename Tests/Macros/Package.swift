// swift-tools-version: 6.2
import CompilerPluginSupport
import PackageDescription

// A library that uses a macro, which checks that the compiler can still load and run macro
// plugins through the toolchain’s own compiler libraries.
let package: Package = .init(
    name: "swift-macros-test",
    products: [
        .library(name: "Probe", targets: ["Probe"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", exact: "603.0.2"),
    ],
    targets: [
        .macro(
            name: "ProbeMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .target(name: "Probe", dependencies: ["ProbeMacros"]),
    ]
)
