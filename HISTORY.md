# DocumentSafer Text 변경 기록

## DS-TXT — 2026-11-15, 미배포

- CotEditor의 편집기를 TXT 전용 메모리 창으로 연결하고 DocumentSafer 규약 6을 사용한다. 서명된 root 연결 도구, 현재 로그인/정책 확인, 암호문 원자 저장, 신규 문서 자동암호화를 추가한다.
- 인코딩/BOM/개행/빈 문서를 보존하며 저장 실패와 외부 원본 변경 시 기존 파일을 유지한다. 보호 문서의 자동복구/클립보드/인쇄/서비스/접근성 본문 노출을 차단한다.
- 제품 이름과 번들 ID를 DocumentSafer Text / com.markany.DocumentSaferText로 분리한다. 배포 이미지를 자체 도형으로 교체하고 원본 소스 및 의존성 고지를 포함한다. 원본 프로젝트 파일·Info.plist·README·도움말과 이미지 변경은 이 배포 목적의 수정이다.
- NSApplication 중복 생성으로 시작 시 종료되던 결함을 shared 인스턴스 우선 초기화로 수정하고 실행 유지로 검증했다. 지역화된 앱 이름도 분리했다.
- 검증. TXT 코어 4개 통과, DocumentSafer 전체 38개 중 22개 통과/외부 파일 경로가 필요한 16개 건너뜀, 두 앱 Release arm64 컴파일 통과. 배포 서명·원본 이미지 396개 감사·설치·실제 앱 실행과 접근성 본문 비노출 검증을 통과했다. TXT 예외 정책 OFF의 일반 저장 및 ON의 실제 신규 암호문 저장·잠금 배지·새 프로세스 재열람을 확인했다. 기존 암호문 편집·ID/ACL/정책 보존 저장·새 프로세스 재열람도 사용자와 확인했다. 시험 계정·앱·리스너를 정리했다.

## 2026-11-17 · GIT-SECURITY

- 인증 파일·운영 정책·배포 산출물의 Git 제외 규칙과 실제 commit/push 대상의 민감 파일 검사 훅을 추가한다. 비밀 값은 출력하지 않는다.
- 임시 저장소 회귀 2개와 전체 변경 파일 검사를 통과했다. 새 clone의 훅 활성화 방법 및 로컬 훅·과거 이력의 한계는 docs/git-sensitive-files.md에 기록한다.

## 2026-11-17 · MAEDITOR-DIST

- CotEditor 기반 회사 배포본을 maEditor / com.markany.securedocs.textedit, 제품 버전 1.0.0과 한국시간 MM.dd.HHmm 빌드 번호로 구분한다.
- 기존 인증을 참조하는 fastlane Universal 앱·연결 도구·서명/공증 PKG와 실제 payload 감사를 추가한다.
- Unicode/ICU·Ed25519 하위 고지 누락을 보완하고 30개 고정 입력/32개 고지 manifest 및 사용자 라이선스 메뉴를 포함한다. 검증 결과와 범위는 docs/maeditor-distribution.md에 기록한다.

- 사용자 지정 MM.dd.HHmm 빌드 번호를 한국시간으로 자동 생성한다. 명시 번호의 날짜·시각을 검증하고 앱/PKG 영수증/파일명에 같은 값을 사용한다.
- 검증. 1.0.0(11.17.1702) Universal PKG의 fastlane 생성·Apple 공증·staple·Gatekeeper·실제 payload 검사를 통과했다. 빌드 번호 14개 검사, TXT 코어 4개/메모리 왕복 1개, 라이선스 회귀 3개와 Git 보호 회귀 2개를 통과했다. 설치·운영 GUI 시험은 별도다. 검증 패키지는 커밋 전 작업 트리에서 생성했다.
