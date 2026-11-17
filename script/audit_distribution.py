# 배포 이미지의 원본 해시 잔존과 보호 앱 메타데이터·서명 권한을 검사한다.
from pathlib import Path
import hashlib
import json
import plistlib
import subprocess
import sys

if not __debug__:
    raise RuntimeError('Distribution audits require Python assertions; do not use -O/PYTHONOPTIMIZE')

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'docs/replaced-image-resources.json').read_text())
forbidden = {item['sha256'] for item in manifest['upstream_images']}
for folder in [root / 'CotEditor/Resources', root / 'Packages/MacUI/Sources']:
    for file in folder.rglob('*'):
        if file.is_file() and file.suffix.lower() in ['.png', '.svg', '.pdf', '.jpg', '.jpeg', '.icns', '.tiff']:
            assert hashlib.sha256(file.read_bytes()).hexdigest() not in forbidden, f'Original restricted image remains: {file}'
assert not (root / 'screenshot@2x.png').exists()
if len(sys.argv) > 1:
    app = Path(sys.argv[1])
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] == 'com.markany.securedocs.textedit'
    assert info['CFBundleName'] == 'maEditor'
    assert info['CFBundleExecutable'] == 'maEditor'
    assert not info.get('SUFeedURL')
    assert info['DocumentSaferEditorProtocol'] == 6
    assert info['NSPrincipalClass'] == 'DocumentSaferTextApplication'
    for localized in app.glob('Contents/Resources/*.lproj/InfoPlist.strings'):
        content = subprocess.check_output(['/usr/bin/plutil', '-convert', 'xml1', '-o', '-', str(localized)])
        strings = plistlib.loads(content)
        if 'CFBundleName' in strings: assert strings['CFBundleName'] == 'maEditor'
    assert info.get('NSAppleScriptEnabled') is False
    assert not any(key in info for key in ['NSMainStoryboardFile', 'NSServices', 'OSAScriptingDefinition', 'NSUbiquitousContainers'])
    for item in info['CFBundleDocumentTypes']:
        assert 'NSDocumentClass' not in item
    assert not (app / 'Contents/SharedSupport/bin/cot').exists()
    for file in app.rglob('*'):
        if file.is_file() and file.stat().st_size < 10_000_000:
            assert hashlib.sha256(file.read_bytes()).hexdigest() not in forbidden, f'Original image in bundle: {file}'
    ent = plistlib.loads(subprocess.check_output(['/usr/bin/codesign', '-d', '--entitlements', '-', '--xml', str(app)], stderr=subprocess.DEVNULL))
    for key in ['com.apple.security.get-task-allow', 'com.apple.security.cs.disable-library-validation',
                'com.apple.security.cs.allow-dyld-environment-variables', 'com.apple.security.cs.allow-jit',
                'com.apple.security.cs.allow-unsigned-executable-memory', 'com.apple.security.cs.disable-executable-page-protection']:
        assert not ent.get(key), f'Unsafe entitlement: {key}'
    for notice in ['CotEditor-Apache.txt', 'DocumentSaferText.txt', 'ThirdParty.txt', 'Dependencies.json', 'Distribution.txt']:
        bundled = app / 'Contents/Resources/Licenses' / notice
        assert bundled.read_bytes() == (root / 'CotEditor/Resources/Licenses' / notice).read_bytes(), f'License mismatch: {notice}'
print(f'Distribution audit passed; {len(manifest["upstream_images"])} original image records checked.')
