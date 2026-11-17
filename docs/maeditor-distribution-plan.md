# maEditor 배포 계획

2026-11-17. 사용자가 maEditor / com.markany.securedocs.textedit 및 fastlane PKG·기존 DocumentSafer 인증 재사용을 요청했다.

1. 앱 표시 이름·번들 ID와 회사 제품 버전 1.0.0과 한국시간 MM.dd.HHmm 빌드 번호를 설정한다. 내부 패키지/Swift 타입 이름과 원저작권은 유지한다.
2. 새 ID를 DocumentSafer 편집기 설정·정확한 서명 인증 목록에 반영한다. 지원 관리앱 업데이트 필요성을 안내한다. 기존 TXT 설정은 새 ID로 이전한다.
3. 고정 의존성의 revision·라이선스·NOTICE, 자체 이미지 출처를 검증하고 최종 번들에 고지와 manifest를 포함한다. 비상업 원본 이미지가 있는 전체 저장소 ZIP은 배포하지 않는다.
4. fastlane으로 Universal Release 앱·연결 도구를 빌드하고 Developer ID Application/Installer로 서명한다. 기존 MobileDOCS 인증 자료는 참조하며 저장소로 비밀 키를 복사하지 않는다.
5. macOS 26+ PKG 생성, Apple 공증·staple·Gatekeeper·payload 검증을 수행한다. 관련 회귀 시험을 실행하고 사용 방법·남는 배포 조건을 기록한다.

기존 두 scheme의 미커밋 제품 이름 변경은 새 요청에 맞게 이어가며 다른 변경은 보존한다. 설치·재설치·커밋·게시·push는 이번 요청 범위에 포함하지 않는다.

## 2026-11-17 후속 검증

DocumentSafer의 maEditor 연동 커밋 5efac3c를 사용해 fastlane 전체 경로를 다시 실행한다. 기존 검증 산출물은 보존하고 사용자 지정 MM.dd.HHmm 번호로 새 아카이브부터 생성한다. 실제 PKG의 서명·공증·고지·민감 파일 제외 검증을 마친 뒤 결과와 재현 명령을 문서에 기록한다. 이번 요청은 패키지 생성까지이며 앱 설치·커밋·push는 수행하지 않는다.

사용자 추가 지시. 빌드 번호를 한국시간 MM.dd.HHmm 형식으로 지정한다. fastlane 기본 생성·재시도 옵션 검증과 앱/PKG 영수증/파일명 일치를 검사하고 해당 번호의 패키지를 최종 산출물로 제공한다.

2026-11-17 커밋 요청. 사용자가 현재 codex/documentsafer-memory-txt 브랜치에 커밋하도록 승인했다. 민감 파일 업로드 차단과 maEditor 배포 준비를 각각 기록하고 git status/log로 결과를 확인한다. push는 요청 범위에 포함하지 않는다.
