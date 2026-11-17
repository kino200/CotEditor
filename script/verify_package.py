# 서명 PKG를 설치하지 않고 풀어 실제 설치 파일·메타데이터·서명·고지를 검증한다.
import plistlib
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BRIDGE = 'com.markany.DocumentSaferEditorBridge'
TEAM = '9N6VX5RKP7'


def verify(package):
    """PKG 경로를 받아 추출된 앱과 연결 도구가 승인한 설치 구성을 만족하는지 검사한다."""
    subprocess.run(['pkgutil', '--check-signature', str(package)], check=True)
    with tempfile.TemporaryDirectory(prefix='maeditor-package-') as temporary:
        expanded = Path(temporary) / 'expanded'
        subprocess.run(['pkgutil', '--expand-full', str(package), str(expanded)], check=True)
        payloads = list(expanded.rglob('Payload'))
        if len(payloads) != 1:
            raise ValueError('Expected exactly one application/bridge component')
        payload = payloads[0]
        app = payload / 'Applications/maEditor.app'
        bridge = payload / 'Library/PrivilegedHelperTools' / BRIDGE
        if sorted(p.name for p in (payload / 'Applications').iterdir()) != ['maEditor.app']:
            raise ValueError('Unexpected application in installer')
        if sorted(p.name for p in (payload / 'Library/PrivilegedHelperTools').iterdir()) != [BRIDGE]:
            raise ValueError('Unexpected privileged helper in installer')
        info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
        component = ET.parse(payload.parent / 'PackageInfo').getroot()
        if component.get('version') != info['CFBundleVersion']:
            raise ValueError('Installer receipt and app build versions must match')
        if info.get('LSMinimumSystemVersion') != '26.0':
            raise ValueError('Unexpected minimum macOS version')
        subprocess.run([sys.executable, str(ROOT / 'script/audit_distribution.py'), str(app)], check=True)
        for path, identifier in [(app, 'com.markany.securedocs.textedit'), (bridge, BRIDGE)]:
            rule = f'=anchor apple generic and certificate leaf[subject.OU] = "{TEAM}" and identifier "{identifier}"'
            subprocess.run(['codesign', '--verify', '--deep', '--strict', '-R', rule, str(path)], check=True)
        for executable in [app / 'Contents/MacOS/maEditor', bridge]:
            architectures = subprocess.check_output(['lipo', '-archs', str(executable)], text=True).split()
            if set(architectures) != {'arm64', 'x86_64'}:
                raise ValueError('Missing Universal architecture')
        if bridge.stat().st_mode & 0o777 != 0o755:
            raise ValueError('Bridge must be mode 0755')
        bom = payload.parent / 'Bom'
        rows = subprocess.check_output(['lsbom', '-p', 'fmug', str(bom)], text=True).splitlines()
        bridge_rows = [row.split('\t') for row in rows if row.split('\t')[0] == './Library/PrivilegedHelperTools/' + BRIDGE]
        if len(bridge_rows) != 1 or bridge_rows[0][2:] != ['0', '0'] or int(bridge_rows[0][1], 8) & 0o777 != 0o755:
            raise ValueError('Installer must assign root:wheel 0755 to bridge')
        entitlements = plistlib.loads(subprocess.check_output(['codesign', '-d', '--entitlements', '-', '--xml', str(bridge)], stderr=subprocess.DEVNULL))
        expected = {'com.apple.security.application-groups': ['9N6VX5RKP7.DocumentSaferEditor']}
        if entitlements != expected:
            raise ValueError('Unexpected bridge entitlement')
        for file in payload.rglob('*'):
            if file.suffix.lower() in ['.p8', '.p12', '.mobileprovision'] or file.name.startswith('socket_policy_response'):
                raise ValueError('Private credential or test policy in payload')
        subprocess.run(['xcrun', 'stapler', 'validate', str(app)], check=True)
    print('PKG payload verification passed; installer was not executed.')


if __name__ == '__main__':
    verify(Path(sys.argv[1]).resolve(strict=True))
