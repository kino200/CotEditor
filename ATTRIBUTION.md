# maEditor 리소스·라이선스

- CotEditor 원본 소스의 저작권·Apache License 2.0 고지는 유지한다. 수정 파일에는 변경 사실을 표시하며 상세 변경은 HISTORY.md에 기록한다.
- 원본 이미지의 CC BY-NC-ND 4.0 허가는 상용 수정 배포의 근거로 사용하지 않는다. 배포 이미지의 교체 전 경로·SHA256은 docs/replaced-image-resources.json에 기록한다.
- AppIcon 및 설정·문서 PNG는 Scripts/generateDocumentSaferAssets.swift가 원본 그림 없이 좌표로 그리는 자체 문서·잠금 도형이다. 새 벡터 glyph도 이 변경에서 직접 작성했다. 이 신규 소스와 신규 그림에는 Apache License 2.0을 적용한다.
- CotEditor 도움말 스크린샷·원본 Icon Composer 그림·README 스크린샷은 배포 대상에서 제거했다. 상위 테스트 전용 이미지 fixture는 제품 번들에 포함하지 않는다.
- 시스템 제공 UI·서체·SF Symbols는 macOS API를 통해 사용하며 원본 CotEditor 이미지로부터 복사하지 않는다.
- 의존성 고지는 CotEditor/Resources/Licenses에 유지한다. 신규 TXT 메모리 패키지에는 외부 오픈소스 의존성을 추가하지 않는다.

| 배포 리소스 | 출처 | 라이선스 |
| --- | --- | --- |
| `Assets.xcassets/AppIcon.appiconset/*.png` | 자체 도형, 생성 스크립트 | Apache-2.0 |
| `Assets.xcassets/Icons/**/*.png` | 자체 문서·잠금 도형, 생성 스크립트 | Apache-2.0 |
| `Assets.xcassets/Symbols/**/*.svg` | 자체 선·문서 도형 | Apache-2.0 |
| `Assets.xcassets/Templates/**/*.svg` | 자체 방향 표시 도형 | Apache-2.0 |
| `Packages/MacUI/Sources/ControlUI/Assets.xcassets/**/*.svg` | 자체 방향 표시 도형 | Apache-2.0 |
| 암호문 파일 배지 | TextBadge의 자체 AppKit 도형 | Apache-2.0 |
