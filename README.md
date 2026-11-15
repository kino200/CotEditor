# DocumentSafer Text

CotEditor 기반의 DocumentSafer 연동 TXT 편집기입니다. 원본 CotEditor와 구분되는 배포 이름과 번들 ID `com.markany.DocumentSaferText`를 사용합니다. macOS 26 이상이 필요합니다.

## 동작

- 서명된 DocumentSafer·규약 6 연결 도구와 현재 로그인 정책을 확인한 후 TXT를 엽니다. 암호화 문서는 메모리에서만 복호화합니다.
- 기존 보호 문서는 편집 후 ID·ACL·정책을 보존한 암호문으로 저장합니다. 새 문서와 일반 TXT는 현재 NOTEPAD 자동암호화 정책을 확인합니다. 오류가 나면 평문 저장으로 전환하지 않습니다.
- UTF-8, BOM을 가진 UTF-16/32, CP949 호환 한국어 인코딩의 무손실 왕복과 기존 BOM·개행을 지원합니다. 모호한 임의 레거시 인코딩이나 표현할 수 없는 문자는 거부합니다.
- CotEditor의 `EditorTextView`를 사용한 전용 TXT 창입니다. 원본의 전체 메뉴를 제공하지 않으며 자동복구·버전 저장·클립보드·인쇄·찾기 기록·서비스·AppleScript·원격 편집·접근성 본문 조회를 연결하지 않습니다. 다른 이름으로 저장은 새 문서의 최초 저장에만 사용합니다.

DocumentSafer의 **문서 편집 앱 → TXT → DocumentSafer Text**를 선택합니다. 기존 TXT는 ⌘O로 열고, 새 문서는 ⌘N, 저장은 ⌘S를 사용합니다. 보호 문서의 실제 저장 경로에는 암호문만 기록하며, 보호 창의 접근성 제한 때문에 본문을 읽는 보조 도구는 사용할 수 없습니다.

## 빌드

Xcode 프로젝트의 이름과 스킴은 `CotEditor`로 유지합니다. 로컬 Xcode 27.0에서 Release arm64 빌드를 검증합니다. 메모리 연동에는 허용된 MarkAny Developer ID 서명이 필요하며 ad hoc 빌드는 인증에서 거부됩니다.

```sh
swift test --package-path Packages/DocumentSaferText
./script/build_and_run.sh --build-only
./script/build_and_run.sh --verify
```

`DOCUMENTSAFER_SIGN_IDENTITY`와 `DOCUMENTSAFER_TEXT_BUILD_DIR`로 인증서와 빌드 경로를 지정할 수 있습니다. 실행 중인 편집 창은 미저장 내용 보호를 위해 강제 종료하지 않습니다. 빌드·리소스 감사·실제 시험 범위는 [연동 계획](docs/txt-editor-integration-plan.md), [체크리스트](docs/checklist.md), [작업 기록](docs/context-notes.md)을 참고하세요.

## 라이선스와 배포

CotEditor 원본 소스의 Apache License 2.0 및 저작권 고지를 유지합니다. 원본의 비상업·변경금지 이미지 허가는 수정 배포 이미지에 사용하지 않으며, 제품에 포함되는 이미지는 자체 도형으로 교체하거나 제거했습니다. 신규 이미지·생성 소스는 Apache-2.0이며 [ATTRIBUTION.md](ATTRIBUTION.md)에 기록했습니다. 원본 이미지 해시 목록과 배포 감사 스크립트가 재유입을 검사합니다.

원본 테스트 전용 이미지 fixture의 라이선스는 원본 [LICENSE](LICENSE)를 따르며 앱 번들에 포함하지 않습니다. 제품에는 원본 소스와 고정 의존성의 라이선스 전문을 포함합니다. 이 작업은 Apple 공증·공개 릴리스나 원본 CotEditor의 상표 사용 허가를 의미하지 않습니다.

원본 프로젝트는 [CotEditor](https://github.com/coteditor/CotEditor)입니다. 원본 소스의 저작권은 © 2005–2009 nakamuxu, © 2011, 2014 usami-k, © 2013–2026 1024jp에게 있습니다. 수정 내역은 [HISTORY.md](HISTORY.md)에 기록합니다.
