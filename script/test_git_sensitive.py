# 임시 Git 저장소에서 민감 파일 및 과거 커밋의 push 차단을 회귀 검증한다.
import subprocess
import tempfile
import unittest
from pathlib import Path

CHECKER = Path(__file__).with_name('check_git_sensitive.py').resolve()


class GitSensitiveTests(unittest.TestCase):
    """실제 Git 인덱스와 객체 이력으로 민감 파일 업로드 방지를 검증한다."""

    def setUp(self):
        """안전한 기준 커밋을 가진 독립 시험 저장소를 만든다. 반환값은 없다."""
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.git('init', '-q')
        (self.root / 'README.md').write_text('Safe source')
        (self.root / '.env.example').write_text('ASC_KEY_PATH=/path/to/local-key.p8\n')
        self.git('add', 'README.md', '.env.example')
        self.base = self.commit('safe')

    def git(self, *args):
        """시험 저장소에서 Git 인자를 실행해 문자열 출력을 반환한다."""
        return subprocess.check_output(['git', '-C', str(self.root), *args], stderr=subprocess.PIPE).decode().strip()

    def commit(self, message):
        """시험용 작성자와 메시지로 커밋하고 SHA를 반환한다. 실제 저장소에는 영향이 없다."""
        self.git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', message)
        return self.git('rev-parse', 'HEAD')

    def check(self, expected, *args, data=None):
        """검사 인자와 입력을 전달하고 기대 종료 코드를 확인한다. 비밀 값은 출력하지 않는다."""
        result = subprocess.run(['python3', str(CHECKER), *args], cwd=self.root, input=data, capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stderr)

    def test_index_and_example(self):
        """예시 설정은 허용하고 실제 환경 파일과 운영 KEYBOX JSON은 차단한다."""
        self.check(0, '--index')
        (self.root / '.env').write_text('LOCAL_ONLY=placeholder\n')
        self.git('add', '.env')
        self.check(1, '--index')
        self.git('rm', '--cached', '.env')
        (self.root / 'renamed.json').write_text('{"KEYBOX":{"PRODUCTKEY":"synthetic-but-unapproved"}}')
        self.git('add', 'renamed.json')
        self.check(1, '--index')

    def test_outgoing_history_and_cleanup(self):
        """이름을 숨긴 개인 키와 중간 커밋 유입을 막고 기존 원격의 삭제 정리는 허용한다."""
        fake = '-----BEGIN ' + 'PRIVATE KEY-----\n' + 'A' * 64 + '\n-----END ' + 'PRIVATE KEY-----\n'
        (self.root / 'notes.txt').write_text(fake)
        self.git('add', 'notes.txt')
        self.check(1, '--index')
        bad = self.commit('synthetic-secret')
        self.git('rm', '--cached', 'notes.txt')
        tip = self.commit('remove-synthetic-secret')
        self.check(0, '--index')
        self.check(1, '--pre-push', 'origin', data=f'refs/heads/main {tip} refs/heads/main {self.base}\n')
        self.check(0, '--pre-push', 'origin', data=f'refs/heads/main {tip} refs/heads/main {bad}\n')


if __name__ == '__main__':
    unittest.main()
