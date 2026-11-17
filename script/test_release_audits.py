# 배포 라이선스의 버전 변경·누락·수정 감지를 실제 임시 Git 저장소로 검증한다.
import contextlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('license_audit', Path(__file__).with_name('verify_licenses.py'))
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class ReleaseAuditTests(unittest.TestCase):
    """배포 의존성 감사가 라이선스 의무를 빠뜨린 입력을 거부하는지 검사한다."""

    def setUp(self):
        """테스트마다 고정 커밋과 하위 고지가 있는 저장소를 만든다. 인자·반환값은 없다."""
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = self.root / 'checkouts/example'
        self.repo.mkdir(parents=True)
        (self.repo / 'LICENSE').write_text('Original license permission and copyright.\n')
        (self.repo / 'vendor').mkdir()
        (self.repo / 'vendor/NOTICE').write_text('Required nested attribution.\n')
        for args in [['init', '-q'], ['add', '.'], ['-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'fixture']]:
            subprocess.run(['git', '-C', str(self.repo), *args], check=True)
        self.revision = subprocess.check_output(['git', '-C', str(self.repo), 'rev-parse', 'HEAD'], text=True).strip()
        self.lock = self.root / 'Package.resolved'
        self.pin = {'identity': 'example', 'location': 'https://example.invalid/source', 'state': {'revision': self.revision, 'version': '1.0.0'}}
        self.lock.write_text(json.dumps({'pins': [self.pin]}))
        self.licenses = self.root / 'Licenses'
        self.licenses.mkdir()
        self.patcher = patch.multiple(audit, LOCK=self.lock, LICENSES=self.licenses)
        self.patcher.start()
        self.addCleanup(self.patcher.stop)

    def test_unpinned_checkout_is_rejected(self):
        """잠금 revision이 실제 체크아웃과 다른 경우 배포 감사를 거부한다."""
        self.pin['state']['revision'] = '0' * 40
        self.lock.write_text(json.dumps({'pins': [self.pin]}))
        with self.assertRaisesRegex(ValueError, 'Unpinned'):
            audit.inventory(self.repo.parent)

    def test_modified_license_is_rejected(self):
        """의존성 라이선스가 로컬에서 바뀐 경우 배포 감사를 거부한다."""
        (self.repo / 'LICENSE').write_text('Changed terms')
        with self.assertRaisesRegex(ValueError, 'Modified dependency'):
            audit.inventory(self.repo.parent)

    def test_missing_nested_notice_is_rejected(self):
        """루트 라이선스만 동봉하고 하위 고지를 누락한 배포를 거부한다."""
        manifest, notices = audit.inventory(self.repo.parent)
        self.assertEqual(len(notices), 2)
        (self.licenses / 'Dependencies.json').write_text(json.dumps(manifest))
        (self.licenses / 'ThirdParty.txt').write_text(notices[0])
        with patch.object(sys, 'argv', ['verify_licenses.py', str(self.repo.parent)]):
            with self.assertRaisesRegex(ValueError, 'Missing or altered'):
                audit.main()
            (self.licenses / 'ThirdParty.txt').write_text(''.join(notices))
            with contextlib.redirect_stdout(io.StringIO()):
                audit.main()


if __name__ == '__main__':
    unittest.main()
