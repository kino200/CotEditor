// swift-tools-version: 5.9
// TXT 인코딩과 인증 메모리 통신·암호문 파일 교체를 검증하는 패키지다.
import PackageDescription

let package = Package(
    name: "DocumentSaferText",
    platforms: [.macOS(.v13)],
    products: [.library(name: "DocumentSaferText", targets: ["DocumentSaferText"])],
    targets: [
        .target(name: "DocumentSaferText"),
        .testTarget(name: "DocumentSaferTextTests", dependencies: ["DocumentSaferText"]),
    ]
)
