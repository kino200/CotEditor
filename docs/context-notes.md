
## DS-TXT

- 2026-11-15. 현재 fork는 macOS 26+, Xcode 27.2를 기술한 7.2 beta 소스이며 project.xcproj 형식을 사용한다. 로컬 Xcode 27.0의 실제 빌드 호환성을 먼저 확인한다. 기존 기능의 평문 자동복구와 AppleScript/서비스/원격 편집이 보호 문서를 받지 않도록 경계를 분리한다.
- 사용자가 DocumentSafer Text 이름과 com.markany.DocumentSaferText ID를 선택했다. CotEditor에는 codex/documentsafer-memory-txt를 만들고 DocumentSafer의 refactor/abstract-external-app-handler는 유지한다.

- CotEditor의 실제 EditorTextView를 재사용한 전용 NSWindowController를 구성한다. NSDocument 자동저장/복구·AppleScript·서비스·원격 편집·확장 UI는 연결하지 않는다. 이 배포본은 TXT 열기/편집/저장 중심이며 원본 CotEditor 전체 메뉴를 제공하지 않는다.
- 메모리 평문은 앱/관리앱/브리지의 주소 공간과 상속 소켓에만 존재한다. 보호 저장에는 암호문만 0600 임시 파일에 기록 후 교체한다. Swift String/NSTextStorage의 모든 사본 소거, OS swap/crash dump, 관리자·커널·입력기·화면 촬영까지 절대 차단한다고 주장하지 않는다.
- BOM UTF-8/16/32, BOM 없는 UTF-8과 CP949 호환 한국어 입력을 무손실 왕복한다. BOM 없는 UTF-16 및 모호한 임의 레거시 인코딩은 범위 밖이다. 기존 파일의 BOM/개행을 보존하며 표현 불가능한 입력은 저장 거부한다.
- 원본 배포 이미지 396개의 SHA를 기록하고 자체 도형으로 교체하거나 제거했다. 원본 소스 Apache 고지와 고정 의존성 라이선스 전문을 포함했다. 배포 자산 감사는 원본 해시의 다른 경로 이동도 검사한다. 테스트 전용 원본 이미지 fixture는 제품 번들에 포함하지 않는다.
- 서명은 기존 MarkAny Developer ID와 Hardened Runtime을 사용하며 get-task-allow 등 완화 권한은 허용하지 않는다. 현재 TXT 앱은 root 브리지 실행을 위해 App Sandbox를 사용하지 않는다. 공개 릴리스/공증은 이번 범위가 아니다.
- 안전한 재실행 스크립트는 실행 중인 앱을 강제 종료하지 않고 저장 후 닫도록 안내한다. 미저장 메모리 문서 유실을 방지하기 위한 선택이다.
- 검증 중 상위 PPTX 최초 교환 거부 시험에 예약된 값 6이 남아 있었음을 확인해 새 예약 값 7로 바꿨다. 제품 인증을 완화하지 않았다.
- 실제 서명 앱 시작에서 NSApplication 직접 생성과 접근성 초기화의 sharedApplication 생성이 충돌해 종료됨을 진단 로그로 확인했다. 전용 클래스의 shared를 첫 호출하고 NSPrincipalClass를 같은 런타임 이름으로 지정한다. 최종 실행 검증은 이 회귀를 포함한다.
- 최종 Developer ID 서명·Hardened Runtime·리소스 396개 해시 감사와 실제 NSApplication 시작 검증이 통과했다. 설치된 규약 6 연결 도구의 root/wheel 0755와 고정 산출물 SHA 일치를 확인했다. 비인가 부모의 hello는 본문 없이 거부됐다.
- 실제 TXT 샘플 원본을 변경하지 않고 승인 정책으로 암호문 시험 사본을 만들었다. 원본 엄격 정책은 편집 거부가 확인됐다. 첫 엄격 정책 실행은 제품 번들에 시험 정책 파일이 없어서 실패했고, 저장소의 원본 Mock 경로로 다시 실행해 통과했다.
- 사용자 아이디 입력 문제는 시험용 로그인 화면의 AX 값 설정으로 로컬 계정 로그인·정책 적용을 완료했다. 로그인 창의 일반 키보드 포커스 문제를 수정했다고 주장하지 않는다. TXT 설정은 DocumentSafer Text로 선택했다.
- 최종 설치본의 새 문서 창이 유지되고 앱 이름·메뉴가 DocumentSafer Text이며 AX에서 본문이 보이지 않는 것을 확인했다. 실제 신규 TXT 사용자 입력·저장·재열람 시험은 현재 사용자 입력 대기 중이다.
- 최초 실제 새 TXT 저장은 34바이트 평문이었다. 설치된 시험 정책의 기본 NOTEPAD 값은 1이지만 활성 EXCEPT_POLICY_LIST[0]의 NOTEPAD 값 0이 우선되어 현재 앱이 자동암호화 OFF로 동작한 결과다. 제품 우선순위를 바꾸지 않고 시험 정책의 해당 값만 1로 올려 성공 흐름을 다시 검증한다. OFF 결과는 별도 시험 파일로 보존했다.
- TXT 예외 정책 ON 상태에서 사용자가 새 TXT를 저장했다. 1,090바이트의 DocumentSafer 암호문이며 시험 문구가 저장 바이트에 존재하지 않음을 확인했다. 메모리 복호화 후 문구/권한 검사, Finder 사용자 아이콘 플래그/ResourceFork 검사 통과. 설치 앱 경로의 새 프로세스로 재열람해 사용자가 문구 보존을 확인했다. 전용 Saved Application State 디렉터리는 생성되지 않았다.

- 기존 TXT 암호문을 사용자가 편집·저장한 뒤 메모리 복호화로 시험 문구 변경, 문서 ID/ACL/모든 정책 헤더 보존, 원본 TXT 해시 보존을 검사했고 통과했다. 암호문 바이트에 시험 문구가 없고 잠금 배지가 유지됐다. 설치 경로의 새 프로세스에서 다시 열어 사용자가 편집 문구 보존을 확인했다.
- 최종 검사. CotEditor TXT 코어 Swift 4개 통과. DocumentSafer 전체 Swift 38개 중 22개 실행 통과/외부 경로 16개 skipped 후 TXT 외부 fixture, 신규 저장본, 기존 편집 저장본을 실제 경로로 각각 실행해 통과했다. 엄격 원본 정책 거부와 비인가 부모 연결 거부, 메뉴 정책 23 assertions와 편집기 설정 회귀, Release arm64 빌드, Developer ID/권한/원본 이미지 396개 감사도 통과했다.
- 실제 시험은 지원 정책의 macOS ARM64 TXT 왕복 범위다. 운영 서버 정책 전체, Intel 실행, OS 전체 파일 I/O 추적, 입력기·관리자·스왑·촬영 차단, Apple 공증은 검증 범위 밖이다. 자동암호화 OFF는 일반 저장을 허용하며 ON 성공 시험에는 NOTEPAD의 활성 예외 정책도 1이어야 한다. 최초 OFF 결과는 시험 자료로 별도 보존했다.
- 정리. 사용자 재열람 확인 후 TXT 앱과 시험 DocumentSafer를 정상 종료하고 시험 계정을 로그아웃했다. 두 프로세스·설치 도구·모의 서버 35001 리스너 종료를 확인했다. 시험 앱/임시 빌드 등록을 해제하고 설치된 운영 DocumentSafer와 DocumentSafer Text를 재등록했다. 기존 백업과 암호문 시험 자료는 보존했으며 커밋/push는 하지 않았다.

## MAEDITOR-DIST · 2026-11-17

- 앱 이름은 maEditor, 번들 ID는 com.markany.securedocs.textedit로 사용자가 지정했다. 회사 제품 버전 1.0.0(1)로 상위 beta 버전과 구분한다.
- 원본 이미지 396개 감사 및 30개 잠금 의존성 고지가 기존에 있지만 최종 PKG의 자동 감사·공증이 없었다. 새 fastlane 경로에 포함한다.
- 원본 CotEditor 소스/내부 Swift 타입 이름은 유지하며 배포 UI만 구분한다. 두 scheme의 기존 변경은 제품 이름 변경뿐임을 실제 diff로 확인했다.
- 기존 관리앱/브리지는 정확한 옛 TXT ID를 인증한다. 새 ID를 반영한 관리앱과 연결 도구가 필요하며 Team 전체 허용으로 완화하지 않는다.
- 기존 MobileDOCS .env의 ASC_* 설정 및 외부 .p8, 키체인의 Developer ID 인증서를 참조한다. 비밀 값은 출력하거나 저장소에 복사하지 않는다.

- 초기 루트 라이선스 30개 검사에서 빠졌던 Tree-sitter lib/src/unicode/LICENSE(Unicode/ICU 통합 고지)와 Sparkle Vendor/ed25519-sparkle/license.txt를 추가했다. 30개 고정 revision, 32개 고지 전문과 해시가 일치한다. 원문 공백을 보존하기 위해 ThirdParty.txt만 Git 공백 교정에서 제외했다.
- 실제 Universal 아카이브가 생성됐고 앱 metadata/지역화 이름/396개 원본 이미지/entitlement/번들 고지가 통과했다. 초기 codesign CLI에는 inline 요구식의 = 접두사가 빠졌고, 현재 lipo의 다중 verify_arch 인자도 실패했다. = 접두사와 -archs 결과 집합 검사로 수정했다. 앱/정책 인증은 완화하지 않았다.
- 앱 공증 d38bf851-f010-41e4-8451-40a70bd1dd31 및 Gatekeeper 실행 검사가 통과했다. 첫 PKG 공증 ec7edb7f-7d81-4402-bb80-ebb9ef02a372도 통과했으나 payload 검사에서 연결 도구의 필요한 앱 그룹을 빈 권한으로 잘못 가정해 중단됐다. 실제 서명의 단일 9N6VX5RKP7.DocumentSaferEditor 그룹과 정확히 비교하도록 수정했고 PKG 검증을 통과했다.
- Ruby fastlane lane에 검증한 아카이브 재사용 옵션을 추가했다. 현재 작업 트리 기준 커밋을 아카이브의 소스 커밋으로 오인하지 않도록 workspace_commit/workspace_dirty/provided_archive를 기록한다. 기존 유효한 앱 공증 티켓은 재사용한다.
- TXT 코어 4개, 관리앱 TXT 메모리 왕복 1개, 설정 이전 회귀, 새 아카이브의 실제 관리앱 호환성 승인/옛 ID 거부, 라이선스 감사 실패 회귀 3개, 최적화 Python 검사 생략 거부, 실행 중 편집기 설치 차단을 확인했다. 서명 연결 도구가 비인가 Python 부모를 본문 없이 거부했다.
- DocumentSafer 저장소에 별도로 변경된 ScreenCaptureBlocker.swift와 document_capture_hotkeys_test.rb는 이번 작업의 변경이 아니며 보존한다. 관리앱 전체를 설치하거나 해당 변경을 되돌리지 않는다.

- 2026-11-17 후속 요청. DocumentSafer 연동은 5efac3c, 민감 파일 추적 정리는 30015ed로 커밋됐다. 기존 PKG 1.0.0(1)의 manifest는 커밋 전 기준을 기록하므로 보존하고, 최신 관리앱 커밋을 기록하는 1.0.0(2)를 전체 fastlane 경로로 생성한다. CotEditor 변경은 아직 미커밋이며 검증 manifest에도 이를 명시한다.
- CotEditor에도 Git 훅 회귀 시험과 새 clone의 훅 활성화 안내를 추가했다. 검사 대상은 실제 인덱스/전송 커밋이며 인증 자료나 산출물을 stage하지 않는다. 현재 `.githooks` 로컬 설정을 확인했다.

- 사용자 요청에 따라 기본 빌드 번호를 한국시간 MM.dd.HHmm으로 변경했다. 일반 fastlane은 실행 시작 시각을 사용하며 재시도는 같은 번호를 명시할 수 있다. 최종 검증 번호는 11.17.1702이다. PKG 영수증 버전도 앱 CFBundleVersion과 일치시키고 비교한다. 기존 정수 빌드의 중간 검증 결과는 보존한다.
- 정수 빌드 1.0.0(2)의 전체 fastlane 실행은 16:59에 성공했다. 최종 제공물은 사용자가 이후 지정한 날짜 형식의 빌드로 교체한다. Ruby 3.4 환경에 minitest가 없어 테스트 의존성을 추가하지 않고 실제 Fastfile을 로드하는 14개 검사로 구성했으며 통과했다.

- 최종 1.0.0(11.17.1702)는 17:07 Universal 아카이브 생성 후 PKG 공증 도중 실행이 중단됐다. 남아 있는 아카이브의 서명·유효한 공증 티켓을 확인하고 archive 옵션으로 재개했으며 19:56 fastlane 종료 코드 0을 확인했다. 앱/PKG Gatekeeper 승인과 실제 payload의 빌드 번호·서명·CPU·고지·root 소유 검사를 통과했다. PKG SHA-256은 2d7aa80018058c8e9556dafa64957ce9198eb926e3ef1a112869fdd69b239e6c이다.
- 최종 manifest는 관리앱 5efac3c, CotEditor 미커밋 상태, 아카이브 재사용을 명시한다. Git 민감 파일 전체 변경 검사와 2개 회귀, 빌드 번호 14개 검사가 통과했다. 설치·운영 GUI 시험·커밋·push는 하지 않았다. 기존 공증 API 키 교체와 Intel/깨끗한 기기 설치 검증은 후속 조건이다.

- 2026-11-17 커밋 승인. 사용자 요청으로 현재 codex/documentsafer-memory-txt에 Git 보호와 maEditor 배포 준비를 분리해 커밋한다. 빌드 번호 14개 검사·Git 보호 2개·라이선스 3개 회귀를 다시 통과했고 최종 PKG 해시가 동일하다. 이 커밋은 기존 서명 PKG/manifest를 다시 생성하거나 과거 provenance를 변경하지 않는다. push는 하지 않는다.
