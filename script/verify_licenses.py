# 고정 Swift 의존성의 실제 revision·원문 고지·승인 해시를 배포 전에 검증한다.
import argparse
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "CotEditor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
LICENSES = ROOT / "CotEditor/Resources/Licenses"


def inventory(checkouts):
    """체크아웃 폴더에서 잠금 버전과 일치하는 의존성별 원문 고지 및 해시를 반환한다."""
    packages, notices = [], []
    for pin in json.loads(LOCK.read_text())["pins"]:
        matches = [p for p in checkouts.iterdir() if p.name.lower() == pin["identity"]]
        if len(matches) != 1:
            raise ValueError("Missing checkout: " + pin["identity"])
        repo = matches[0]
        revision = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD"], text=True).strip()
        if revision != pin["state"]["revision"]:
            raise ValueError("Unpinned checkout: " + pin["identity"])
        dirty = subprocess.check_output(["git", "-C", str(repo), "status", "--porcelain", "--untracked-files=no"], text=True)
        if dirty:
            raise ValueError("Modified dependency: " + pin["identity"])
        tracked = subprocess.check_output(["git", "-C", str(repo), "ls-files"], text=True).splitlines()
        files = []
        for name in sorted(tracked):
            file = repo / name
            if not file.is_file() or not file.name.lower().startswith(("license", "notice", "copying", "copyright")):
                continue
            raw = file.read_bytes()
            files.append({"path": name, "sha256": hashlib.sha256(raw).hexdigest()})
            notices.append(f"\n{'=' * 72}\n{pin['identity']} @ {revision} / {name}\n{'=' * 72}\n" + raw.decode())
        if not files:
            raise ValueError("Missing license: " + pin["identity"])
        packages.append({"name": pin["identity"], "source": pin["location"], "state": pin["state"],
                         "modified": False, "license_files": files})
    return {"scope": "Pinned build inputs; includes build-only and optional packages, not a runtime-only SBOM", "packages": packages}, notices


def main():
    """체크아웃과 검토용 갱신 옵션을 받아 고지·승인 목록을 생성하거나 일치 여부를 검사한다."""
    parser = argparse.ArgumentParser()
    parser.add_argument("checkouts", type=Path)
    parser.add_argument("--refresh", action="store_true", help="검토용 고지/manifest 생성. 배포 lane은 사용하지 않음")
    args = parser.parse_args()
    manifest, notices = inventory(args.checkouts)
    destination = LICENSES / "Dependencies.json"
    third_party = LICENSES / "ThirdParty.txt"
    if args.refresh:
        destination.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
        third_party.write_text("maEditor third-party notices\n\nPinned dependency license and nested notices follow unchanged.\n" + "".join(notices))
    if json.loads(destination.read_text()) != manifest:
        raise ValueError("Dependency license inventory changed; review before release")
    text = third_party.read_text()
    for notice in notices:
        if notice not in text:
            raise ValueError("Missing or altered third-party notice")
    print(f"License audit passed: {len(manifest['packages'])} pinned packages, {len(notices)} license/notice files")


if __name__ == "__main__":
    main()
