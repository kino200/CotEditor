
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
