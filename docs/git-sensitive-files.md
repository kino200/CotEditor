# Git 민감 파일 업로드 방지

2026-11-17. maEditor 배포 작업에 적용한다.

실제 `.env`, 공증 개인 키, 인증서 묶음, 키체인, 운영 정책 응답, 로그와 빌드/공증 산출물은 Git에서 제외한다. `.env.example`에는 변수 이름과 예시 경로만 둔다. fastlane은 외부 DocumentSafer 인증 자료를 참조하며 이 저장소로 복사하지 않는다.

현재 작업 복사본에는 아래 설정을 적용했다. 새 clone에서 commit/push하기 전에도 실행한다.

```sh
git config --local core.hooksPath .githooks
python3 script/check_git_sensitive.py --index
python3 script/test_git_sensitive.py
```

`pre-commit`은 실제 Git 인덱스를, `pre-push`는 전송할 tip과 새 커밋 이력의 객체를 검사한다. 중간 커밋에 개인 키를 추가했다가 마지막 커밋에서만 지우는 경우도 차단한다. 파일명과 탐지 이유만 출력하며 비밀 값은 출력하지 않는다. 민감 파일명 검사는 크기 제한 없이, 내용 패턴 검사는 2 MB 이하 blob에 적용한다.

로컬 훅은 `--no-verify`나 Git 설정 변경으로 우회할 수 있으므로 조직 차원의 강제 적용은 원격 저장소의 push protection/비밀 탐지 정책으로 보완한다. 모든 형식의 비밀 정보를 탐지한다고 보장하지 않는다. 승인 없이 원격 설정을 변경하지 않는다.

`.gitignore`는 이미 추적 중인 파일이나 과거 Git 이력을 제거하지 않는다. 기존 DocumentSafer 저장소 이력의 공증 API 키는 해당 서비스에서 폐기·재발급해야 하며, 이 작업에서는 키 폐기나 강제 push를 수행하지 않는다. 교체 키는 외부 `.env`의 ASC_* 참조만 갱신하고 로컬에 보관한다.

회귀 검사는 임시 저장소와 가짜 입력만 사용한다. 안전한 예시 설정 허용, 실제 환경 파일·이름을 숨긴 개인 키·미승인 KEYBOX JSON 차단, 중간 커밋 차단과 기존 원격의 민감 파일 삭제 정리 허용을 확인한다.
