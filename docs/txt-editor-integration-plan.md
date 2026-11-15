# DocumentSafer Text 메모리 TXT 연동 계획

2026-11-15. DS-TXT.

- 목표. CotEditor의 텍스트 편집 기능을 사용해 인증된 관리앱에서 TXT를 메모리로 열고, 편집 후 암호문만 저장한다. 새 문서는 현재 TXT 자동암호화 정책에 따른다.
- 배포 이름. 사용자 선택에 따라 DocumentSafer Text, com.markany.DocumentSaferText를 사용한다. 원본 CotEditor와 앱 데이터·서명을 구분한다.
- 보안 경계. 규약 6·서명 앱 인증·매 저장 정책 재검사·원본 ID/ACL 보존·원본 변경 거부·비인가 앱 차단을 적용한다. 보호 문서의 자동저장·복구·버전·스크립트·서비스·클립보드·인쇄·로그 평문 출력은 허용하지 않는다. 실패 시 평문 저장으로 전환하지 않는다.
- TXT 보존. 인코딩·BOM·줄바꿈·마지막 개행·빈 문서를 시험하고, 표현 불가능한 문자는 저장을 거부한다. 외부 원본의 오인코딩 방지 기준을 명시한다.
- 리소스. 비상업·변경금지 원본 이미지를 배포 대상에서 제거하고 자체 벡터/렌더 리소스와 출처 목록으로 대체한다. 원본 소스 고지와 Apache 라이선스를 유지하고 변경 파일에 수정 고지를 추가한다.
- 구현. 관리앱의 TXT 종류/설정/정책/인증을 확장하고, CotEditor의 파일 기반 부가 기능과 구분한 보호 편집 경로를 연결한다. 현재 fork의 macOS 26+ 요구사항은 유지한다.
- 검증. 메모리 암복호화·인코딩 왕복·빈 문서·정책/로그인 변경·교차 앱 거부·암호문 원자 교체·반출 차단 회귀, 앱 빌드·배포 서명·리소스 감사, 사용자 입력 기반 새 문서/기존 문서 실제 저장·재열람을 확인한다.
- 범위 밖. HWPX/DOCX/XLSX/PPTX 동작 변경, 미지원 정책 완화, OS/관리자 메모리 접근의 절대 차단, 공개 릴리스/Apple 공증/원격 push는 포함하지 않는다.
- 복구. 기존 앱과 root 연결 도구를 보존한다. 새 편집기/관리앱/브리지의 규약 호환성을 함께 검증한다. 요청 없이 커밋하지 않는다.

## 빌드와 검증 명령

- `swift test --package-path Packages/DocumentSaferText`로 인코딩과 저장 경계를 검증한다.
- `./script/build_and_run.sh --build-only`로 Release arm64 빌드·Developer ID 서명·배포 리소스 감사를 실행한다. 기본 서명은 MarkAny Developer ID이며 `DOCUMENTSAFER_SIGN_IDENTITY`로 해당 인증서를 지정할 수 있다. `DOCUMENTSAFER_TEXT_BUILD_DIR`로 빌드 경로를 지정한다.
- `./script/build_and_run.sh --verify`는 같은 빌드 후 실제 앱을 실행하고 프로세스 유지 여부를 확인한다. 기존 미저장 창이 있으면 강제 종료하지 않는다.
- `python3 script/audit_distribution.py /path/to/DocumentSafer\ Text.app`는 원본 이미지 해시, TXT 전용 메타데이터, 라이선스 포함 여부와 서명 권한을 검사한다.
- SwiftLint 빌드 플러그인은 고정된 Package.resolved 소스를 확인한 상태에서 명령 단위로 실행한다. 전역 Xcode 보안 설정은 변경하지 않는다.
