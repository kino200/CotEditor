# maEditor 배포

검토일. 2026-11-17.

## 제품과 지원 범위

| 항목 | 값 |
| --- | --- |
| 앱 이름 / 번들 ID | maEditor / `com.markany.securedocs.textedit` |
| 회사 제품 버전 | 기본 1.0.0, 빌드 번호는 한국시간 `MM.dd.HHmm`. `version:` / `build_number:`로 재지정 가능 |
| OS / 빌드 CPU | macOS 26.0 이상 / arm64 + x86_64 Universal |
| 편집기 규약 | TXT 규약 6. 메모리 복호화·편집·암호문 저장·정책 기반 신규 자동암호화 |
| 설치 위치 | `/Applications/maEditor.app` |
| 공용 연결 도구 | `/Library/PrivilegedHelperTools/com.markany.DocumentSaferEditorBridge` |
| 서명 | MarkAny Team `9N6VX5RKP7`, Developer ID Application + Developer ID Installer |
| Xcode 프로젝트 / scheme | `CotEditor.xcodeproj` / `CotEditor`, Release |

내부 Swift 패키지/클래스의 DocumentSaferText 이름은 프로토콜·코드 호환을 위해 유지한다. 앱의 이름, 실행 파일, 번들 ID, 지역화된 이름과 메뉴는 maEditor다. 원본 CotEditor 자동 업데이트 채널을 사용하지 않는다. 이 릴리스는 설치 PKG로 갱신하며 별도 업데이트 서비스를 추가하지 않는다.

## 단독 사용

DocumentSafer가 설치·실행되지 않은 환경에서는 maEditor를 직접 실행해 새 일반 TXT와 기존 일반 TXT를 열고 편집·저장한다. 암복호화 서비스와 연결 도구는 호출하지 않는다. 암호문 마커가 있는 문서는 관리앱 필요 오류로 거부한다. 연결 도구가 설치되어 있어도 관리앱이 없으면 단독 일반 편집이 가능하다.

실제 설치 판별 범위는 시스템/사용자 Applications 아래의 운영·데몬·시험 앱 설치본 및 실행 중인 정식 번들 ID다. 루트 밖의 미실행 개발·백업 등록은 제외한다. 관리앱을 감지한 같은 세션은 연결 실패/로그아웃/제거 후에도 관리 상태를 유지하고 저장 실패 시 원본을 보존한다. 단독 편집 중 새 설치는 다음 저장 시 정책을 조회한다. 기존 보호 UI의 클립보드·인쇄·자동복구·외부 본문 조회 제한은 그대로다.

## 관리앱과 호환성

DocumentSafer와 연결 도구는 **정확한 편집기 ID와 MarkAny 서명**을 검증한다. 기존 `com.markany.DocumentSaferText`만 아는 관리앱으로는 maEditor를 인증할 수 없다. `5efac3c` 커밋 또는 다음 변경이 포함된 DocumentSafer를 먼저 준비해야 한다.

- `DocumentSaferEditorIPC/EditorIPC.swift`의 `textEditorID`가 `com.markany.securedocs.textedit`다.
- TXT 편집기 선택 UI가 maEditor를 표시하고, 이전 DocumentSafer Text 선택 값을 새 ID로 이전한다.
- 이 PKG는 해당 소스에서 빌드한 연결 도구를 포함한다. 기존 ID를 임의로 허용하거나 다른 앱으로 자동 전환하지 않는다.

관리앱·운영 정책·DRM 공급 dylib는 maEditor PKG에 포함하지 않는다. 실제 관리앱 없이 독립적인 암호화 편집을 제공하는 패키지가 아니다. 기존 DocumentSafer Text를 삭제하거나 문서·키체인·설정을 옮기지 않으며, 관리앱/연결 도구가 새 ID로 전환된 뒤에는 TXT 편집에 maEditor를 사용한다. 다른 형식의 편집기 ID와 규약은 유지된다.

설치 전에 관리앱과 편집기의 문서를 저장하고 앱을 종료한다. 설치 스크립트는 실행 중인 앱이 있으면 실패하고, 강제 종료하지 않는다. Finder 기본 연결은 기존 DocumentSafer 구성에 맡기며 이 PKG가 기본 앱을 덮어쓰지 않는다. 삭제했던 관리앱을 자동으로 재설치하지 않는다.

## 빌드와 인증

Ruby 3.4.1과 Bundler, Xcode 27.0 이상, MarkAny Developer ID Application/Installer의 개인 키가 있는 키체인이 필요하다. 최소 배포 OS는 Xcode 버전과 별개로 macOS 26.0이다.

```sh
bundle install
bundle exec fastlane mac distribute_pkg \
  documentsafer_root:/path/to/securedocs/MobileDOCS \
  version:1.0.0
```

빌드 번호를 생략하면 lane 시작 시점의 한국시간(UTC+09:00)을 사용한다. 예를 들어 `11.17.1700`은 11월 17일 17시 00분이다. 재시도는 `build_number:11.17.1700`처럼 같은 값을 명시한다. 앱 `CFBundleVersion`, PKG 영수증 버전, 파일명과 manifest에 동일한 문자열을 사용하며 잘못된 날짜·시각은 거부한다.

연도가 없는 사용자 지정 규칙이므로 해가 바뀌면 번호가 감소한다. 이전 연도 설치본과의 업그레이드는 별도 검증이 필요하며, 이 작업에서 버전 비교나 다운그레이드 보호를 해제하지 않는다. Apple의 [빌드 문자열 안내](https://developer.apple.com/help/glossary/build-string/)에 맞춰 점으로 구분된 세 숫자 부분으로 저장한다.

`DOCUMENTSAFER_DISTRIBUTION_ROOT`를 지정하면 `documentsafer_root:`를 생략할 수 있다. `source_packages:/path/to/SourcePackages`로 **같은 Package.resolved revision**의 기존 체크아웃을 재사용할 수 있다. 없으면 빌드 전용 폴더에 고정 버전을 resolve한다. 의존성이나 승인 라이선스 manifest를 자동 갱신하지 않는다.

공증 인증은 `MobileDOCS/.env`의 `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`를 읽는다. 동일 이름의 환경 변수가 우선한다. 상대 키 경로는 MobileDOCS 루트 기준이며, 기존 `.p8`을 참조한다. 인증서·개인 키·비밀번호·실제 `.env`를 저장소에 복사하지 않는다. 새 clone에서 commit/push하기 전에는 [Git 보호 설정](git-sensitive-files.md)의 로컬 훅을 활성화한다. `.env.example`에는 변수 이름과 예시 경로만 있다.

lane은 다음 검증을 순서대로 수행하며 실패한 산출물을 배포 완료로 표시하지 않는다.

1. 잠금 의존성·라이선스 해시·전체 고지와 원본 이미지 396개를 검사한다.
2. TXT 코어 시험 및 관리앱의 TXT 메모리 암복호화·정책 보존 시험을 실행한다.
3. Release Universal 아카이브를 만들고 엄격한 서명·위험 entitlement·번들 이름/ID·고지를 검사한다.
4. 앱을 공증·staple하고 Gatekeeper 실행 평가를 통과시킨다.
5. 같은 관리앱 소스의 Universal 연결 도구를 빌드·서명한다.
6. `/Applications` 고정 설치·macOS 26+ 조건·root 소유 연결 도구를 가진 PKG를 만들고 공증·staple한다.
7. PKG 서명·Gatekeeper 설치 평가 후 **설치하지 않고 payload를 추출**해 앱/연결 도구의 ID, CPU, 서명, 고지, 인증 키/시험 정책 부재를 재검증한다.

산출물은 `build/maEditor/dist/<version>/<build>/`의 PKG, 공증 앱, dSYM ZIP, `release.json`이다. 아카이브는 `build/maEditor/work/`에 남는다. 완료 manifest가 이미 있는 버전·빌드는 덮어쓰지 않는다. PKG SHA-256·소스 커밋·미커밋 여부가 manifest에 기록된다. 사용자 검토 전에는 커밋/태그/공개 게시를 수행하지 않는다.

아카이브 생성 후 공증/패키징만 재시도하려면 같은 명령에 `archive:/path/to/maEditor.xcarchive`를 지정한다. 이 경우 앱 컴파일만 생략하며 버전·빌드 일치, 서명·CPU·현재 고지, 공증·PKG 검사를 모두 실행한다. manifest의 `provided_archive`로 재사용 여부를 구분한다. `workspace_commit`은 실행 당시 작업 트리의 기준 커밋이며 미커밋 아카이브의 정확한 소스 커밋이라고 주장하지 않는다.

## 라이선스 보완

CotEditor 소스의 Apache-2.0은 조건을 지키는 수정·상용 재배포를 허용한다. 라이선스 전문, 원저작권, 변경 사실을 유지하며 원본 프로젝트의 제품명/상표를 회사 배포명으로 쓰지 않는다. [Apache 원문](https://www.apache.org/licenses/LICENSE-2.0).

원본 이미지에 적용된 CC BY-NC-ND는 상용 수정 배포의 근거로 사용할 수 없다. 기존에 만든 자체 도형으로 대체한 상태를 최종 번들에서 재검사한다. [CC 조건](https://creativecommons.org/licenses/by-nc-nd/4.0/).

| 확인·보완 | 배포물에 반영한 내용 |
| --- | --- |
| 원저작권과 Apache 조건 | `CotEditor-Apache.txt`, `Distribution.txt`, 변경 파일의 수정 고지 |
| 회사 명칭과 원본 구분 | maEditor 이름·ID, CotEditor 기반이라는 설명과 원저작자 표기 유지 |
| 비상업 이미지 | 자체 AppIcon/도형 사용. 396개 원본 이미지 해시 검사, 원본 테스트 이미지/소스 ZIP은 배포 제외 |
| 의존성 고지 | 고정 30개 revision의 32개 라이선스/고지 전문과 SHA-256 목록 |
| 추가로 찾은 누락 | Tree-sitter `lib/src/unicode/LICENSE` 전체 Unicode/ICU 고지, Sparkle `Vendor/ed25519-sparkle/license.txt` 추가 |
| 원문 유지 | MIT, BSD, Apache 및 Runtime Library Exception, Sparkle의 추가 조건, Unicode/ICU 통합 고지를 번역·축약 없이 동봉 |
| 사용자 접근 | 앱 메뉴의 ‘오픈소스 라이선스…’에서 실제 설치된 고지 폴더를 열 수 있음 |

`Dependencies.json`은 빌드 도구와 선택적 패키지도 포함한 보수적인 **입력 의존성 목록**이다. 모든 항목이 런타임에 링크되었다는 의미는 아니다. 체크아웃의 수정 여부·revision·고지 해시를 검사하고, 새 라이선스가 생기면 검토 후 `verify_licenses.py --refresh`를 수동 실행해야 한다. 배포 lane에는 갱신 옵션이 없다.

현재 작업 범위는 maEditor 바이너리/PKG다. 다른 Craft/HOP 앱의 상표·MPL·폰트 문제를 해결한 것으로 확대하지 않는다. 공급 DRM 모듈이 없는 이 PKG의 오픈소스 보완과 전체 DocumentSafer 제품의 계약·암호 수출입·상표 권원 검토는 구분한다.

## 검증 기록 · 11.17.1702 (단독 실행 추가 전)

2026-11-17 한국시간 기준. 단독 실행 추가 전 `maEditor 1.0.0 (11.17.1702)` 패키지 생성을 완료했다.

| 검사 | 실제 결과 |
| --- | --- |
| 전체 fastlane 아카이브 | `distribute_pkg version:1.0.0 build_number:11.17.1702`에서 17:07 Release Universal 아카이브 성공 |
| 공증 단계 재개 | 실행 중단 후 같은 `archive:`를 재사용한 lane이 19:56 종료 코드 0으로 완료. manifest의 `provided_archive`는 true |
| TXT 회귀 | `swift test --disable-sandbox --package-path Packages/DocumentSaferText` 4개 통과 |
| 관리앱 메모리 암복호화 | DocumentSaferCrypto의 `DocumentEditingTests/testTextMemoryRoundTripAndIsolation` 1개 통과 |
| 빌드 번호 | `bundle exec ruby script/test_release_version.rb` 14개 검사 통과. 한국시간 날짜 전환·선행 0·오류 입력 포함 |
| 라이선스 | `verify_licenses.py` 30개 고정 패키지 / 32개 고지 일치, `test_release_audits.py` 3개 통과 |
| 최종 앱 감사 | `audit_distribution.py`에서 396개 원본 이미지 해시·이름/ID·위험 권한 부재·고지 일치 통과 |
| 설치 파일 | `verify_package.py`에서 앱/연결 도구 Universal slice·엄격한 서명·root:wheel 0755·앱 그룹·앱/영수증 빌드 번호 일치 통과 |
| 배포 인증 | Developer ID Application/Installer 서명, 앱·PKG `stapler validate`, `spctl --assess`의 Notarized Developer ID 승인 통과 |
| 번호 불일치 거부 | 이전 영수증 버전과 앱 빌드가 다른 실제 PKG를 임시 추출해 오류로 차단되는 것을 확인 |
| Git 보호 | `python3 script/test_git_sensitive.py` 2개 통과. 전체 변경 파일을 임시 인덱스에서 검사해 통과했고 실제 인덱스는 변경하지 않음 |
| 민감 파일 제외 | 인증·정책·산출물 ignore 규칙 및 설치 payload의 인증/운영 응답 파일명 부재 검사 통과 |

최종 산출물 폴더는 `build/maEditor/dist/1.0.0/11.17.1702/`다.

- 설치 파일. `maEditor-1.0.0-11.17.1702-universal.pkg`. 약 19.4 MB.
- SHA-256. `2d7aa80018058c8e9556dafa64957ce9198eb926e3ef1a112869fdd69b239e6c`.
- 함께 생성한 파일. `maEditor.app`, `maEditor.dSYM.zip`, `release.json`.
- 관리앱 기준 커밋. `5efac3cecbac9e95caf0e88b44fbc838c8b3798d`.
- 실행 로그. `build/maEditor/logs/package-1.0.0-11.17.1702.log` 및 `package-1.0.0-11.17.1702-resume.log`.

CotEditor는 미커밋 변경으로 빌드했으며 manifest에 `workspace_dirty: true`를 기록했다. 기존 정수 빌드 1·2는 중간 검증 자료로 보존하고 최종 배포물로 안내하지 않는다. 동일 빌드 번호로 완료 manifest를 덮어쓰지 않으므로 다음 신규 빌드는 `build_number:`를 생략해 새 한국시간 번호로 생성한다.

이번 작업은 설치하지 않은 PKG 생성·공증·정적 검증 범위다. 실제 Intel 기기 실행, 깨끗한 기기 설치, 새 이름/ID 설치본으로 운영 서버 정책을 사용한 GUI 통합 시험은 아직 수행하지 않았다. 새 ID를 지원하는 DocumentSafer를 함께 준비해야 한다. 기존 DocumentSafer 이력에 포함됐던 공증 API 키 폐기·재발급도 남아 있으며 [Git 보호 안내](git-sensitive-files.md)에 기록했다. 패키지 생성 단계에서는 사용자 문서와 기존 설치 앱을 변경하지 않았고 commit/push도 수행하지 않았다. 이후 사용자가 배포 준비 소스의 현재 브랜치 커밋을 요청했다. 이미 생성한 PKG와 manifest는 빌드 당시의 미커밋 상태 기록을 그대로 보존한다.

## 단독 지원 검증 · 11.17.2027

2026-11-17 한국시간 기준. `maEditor 1.0.0 (11.17.2027)`를 새 아카이브부터 생성했으며 `bundle exec fastlane mac distribute_pkg`는 20:34 종료 코드 0으로 완료했다. 앱과 PKG의 Apple 공증·staple·Gatekeeper 승인, Universal slice와 실제 payload 검사가 통과했다.

- 최신 PKG. `build/maEditor/dist/1.0.0/11.17.2027/maEditor-1.0.0-11.17.2027-universal.pkg`.
- SHA-256. `9b3bcf21e59ad337c1307b1bee3e5041133753abd141a9eb2e806fd15eed76d7`.
- 로그. `build/maEditor/logs/standalone-1.0.0-11.17.2027.log`.
- `swift test --disable-sandbox --package-path Packages/DocumentSaferText`. 단독 회귀 6개와 기존 회귀 4개, 합계 10개 통과.
- 실제 기본 서비스. 아래 smoke 명령으로 현재 기기의 미설치 판별, 새/기존 TXT 일반 저장·재열람, 암호문/암호화 요청 거부를 확인했다. 실행 중인 관리앱이나 설치본이 있으면 이 smoke는 중단하며 관리 상태를 변경하지 않는다.
- 실제 앱. DocumentSafer를 실행하지 않고 공증 빌드를 `open -n`으로 실행했다. 시작 완료와 `새 문서.txt — maEditor` 창(900×682)을 창 메타데이터로 확인했다. 문서 본문을 외부에서 읽거나 GUI 키 입력으로 자동 편집하지 않았다. 실행한 아카이브와 배포 앱 실행 파일의 SHA-256이 같다.
- 관리 환경. 설치/연결 실패·정책 변경·관리앱 제거 시 원본 보존 회귀와 기존 DocumentSafer TXT 메모리 왕복 시험 1개가 통과했다. 실제 운영 서버의 새 로그인/GUI 암호화 시험은 이번 범위가 아니다.
- 민감 정보. 전체 변경 파일을 임시 Git 인덱스에서 검사해 통과했다. 실제 인덱스는 변경하지 않았고 commit/push도 하지 않았다.

```sh
swiftc Packages/DocumentSaferText/Sources/DocumentSaferText/*.swift \
  script/standalone_smoke.swift -o /tmp/maeditor-standalone-smoke
/tmp/maeditor-standalone-smoke
```

이전 `11.17.1702`는 단독 실행 추가 전 패키지이며 이번 기능은 새 PKG에 포함된다. 기존 설치 앱을 교체하거나 연결 도구를 설치하지 않았다. 현재 시험 앱은 아카이브 경로에서 실행했으며 새 PKG 설치 전에는 열린 maEditor 문서를 저장하고 종료해야 한다.
