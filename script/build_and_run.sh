#!/bin/bash
# 보호 TXT 앱을 배포 서명으로 빌드하고 선택적으로 실행·검증한다.
set -euo pipefail
mode="${1:---verify}"
case "$mode" in run|--verify|--build-only) ;; *) echo 'usage: build_and_run.sh [run|--verify|--build-only]' >&2; exit 2;; esac
root=$(cd -- "$(dirname -- "$0")/.." && pwd)
build_dir="${DOCUMENTSAFER_TEXT_BUILD_DIR:-$root/build/DocumentSaferText}"
identity="${DOCUMENTSAFER_SIGN_IDENTITY:-Developer ID Application: MarkAny Inc. (9N6VX5RKP7)}"
if [ "$mode" != --build-only ] && pgrep -x 'maEditor' >/dev/null; then
    echo '미저장 본문을 보존하려면 실행 중인 maEditor를 저장 후 종료해 주세요.' >&2
    exit 1
fi
cd "$root"
# 고정 Package.resolved의 SwiftLint 빌드 플러그인 소스를 검토한 뒤에만 이 명령을 사용한다.
xcodebuild -project CotEditor.xcodeproj -scheme CotEditor -configuration Release \
    -derivedDataPath "$build_dir" -skipPackagePluginValidation \
    -destination 'platform=macOS,arch=arm64' \
    CODE_SIGN_IDENTITY="$identity" DEVELOPMENT_TEAM=9N6VX5RKP7 CODE_SIGN_STYLE=Manual \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO build
app="$build_dir/Build/Products/Release/maEditor.app"
/usr/bin/codesign --verify --deep --strict -R '=anchor apple generic and certificate leaf[subject.OU] = "9N6VX5RKP7" and identifier "com.markany.securedocs.textedit"' "$app"
python3 script/audit_distribution.py "$app"
if [ "$mode" != --build-only ]; then
    /usr/bin/open -n "$app"
    if [ "$mode" = --verify ]; then
        sleep 2
        pgrep -x 'maEditor' >/dev/null
    fi
fi
