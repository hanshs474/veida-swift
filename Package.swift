// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Veida",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [.library(name: "Veida", targets: ["Veida"])],
    targets: [.target(name: "Veida")]
)
