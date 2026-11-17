# Git 인덱스와 push 대상 커밋에서 인증 파일·개인 키·토큰·배포 산출물을 차단한다.
import argparse
import hashlib
import fnmatch
import re
import subprocess
import sys
from pathlib import PurePosixPath

ZERO = '0' * 40
# 가상 사용자·시험 키 fixture만 승인하며 실제 정책으로 바뀌면 차단한다.
APPROVED_TEST_POLICIES = {
    "MobileDOCS/Modules/DocumentSaferCrypto/Tests/DocumentSaferCryptoTests/Fixtures/dto-policies.json": "c97a4de860b4c9c55a9e16b38c68e98f001c5e46733299468f851a0985ca9414",
    "MobileDOCS/Modules/DocumentSaferCrypto/Tests/DocumentSaferCryptoTests/Fixtures/policies.json": "074c78176924ed6b36b3b8706b00e370caf3ea4c2ac9a61404aab0fc12c3e864",
    "MobileDOCS/Modules/DocumentSaferCrypto/Examples/DocumentSaferCryptoDemo/Sources/DocumentSaferCryptoDemo/Resources/document-safer-policy.json": "2f7344bbced0d178befe952e213f1fc577c889fa5e4f4e4b31d283c33441c42d"
}
PRIVATE = re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----\s+[A-Za-z0-9+/=\s]{32,}')
TOKEN = re.compile(rb'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,}|AKIA[A-Z0-9]{16}|xox[baprs]-[A-Za-z0-9-]{24,})')
PATTERNS = ['*.p8', '*.p12', '*.pfx', '*.pem', '*.key', '*.mobileprovision', '*.provisionprofile',
            '*.keychain', '*.keychain-db', 'credentials.json', 'secrets.json', 'update-key.txt', 'id_rsa', 'id_ed25519',
            'socket_policy_response*.json', 'daemon_policy_response*.json', '*.log', '*.pkg', '*.dmg', '*.ipa', '*.dsym.zip']


def git(*arguments, data=None):
    """Git 인자와 선택 입력을 받아 출력 바이트를 반환한다. 파일 내용은 출력하지 않는다."""
    return subprocess.check_output(['git', *arguments], input=data, stderr=subprocess.PIPE)


def blocked_path(name):
    """저장소 상대 경로가 로컬 인증/배포 파일인지 반환한다. 환경 설정 예시만 허용한다."""
    if '/service/network/mock/' in '/' + name.lower():
        return True
    path = PurePosixPath(name)
    base = path.name.lower()
    if base == '.env' or base.startswith('.env.') and base not in {'.env.example', '.env.sample', '.env.template'}:
        return True
    if any(fnmatch.fnmatchcase(base, pattern) for pattern in PATTERNS):
        return True
    return any(part.lower() in {'build', 'dist', '.build', 'deriveddata'} or
               part.lower().endswith(('.app', '.xcarchive', '.xcresult', '.dsym')) for part in path.parts[:-1])


def index_entries():
    """작업 파일 대신 Git 인덱스에 실제 포함된 blob ID와 파일명을 반환한다."""
    entries = []
    for record in git('ls-files', '--stage', '-z').split(b'\0'):
        if not record:
            continue
        metadata, name = record.split(b'\t', 1)
        mode, oid, stage = metadata.decode().split()
        if mode != '160000':
            entries.append((oid, name.decode('utf-8', errors='replace')))
    return entries


def tree_entries(revision):
    """커밋 tip의 실제 파일 blob을 반환해 미커밋 삭제로 push 검사를 우회하지 못하게 한다."""
    entries = []
    for record in git('ls-tree', '-r', '-z', revision).split(b'\0'):
        if not record:
            continue
        metadata, name = record.split(b'\t', 1)
        _, kind, oid = metadata.decode().split()
        if kind == 'blob':
            entries.append((oid, name.decode('utf-8', errors='replace')))
    return entries


def push_entries(remote, updates):
    """원격 이름과 pre-push 입력으로 tip 및 새로 전송하는 과거 커밋의 blob까지 수집한다."""
    entries = []
    remotes = git('remote').decode().splitlines()
    for update in updates.splitlines():
        _, local_oid, _, remote_oid = update.split()
        if local_oid == ZERO:
            continue
        entries.extend(tree_entries(local_oid))
        arguments = ['rev-list', '--objects', local_oid]
        if remote_oid != ZERO:
            arguments.append('^' + remote_oid)
        elif remote in remotes:
            arguments.extend(['--not', '--remotes=' + remote])
        for line in git(*arguments).decode('utf-8', errors='replace').splitlines():
            oid, separator, name = line.partition(' ')
            if separator:
                entries.append((oid, name))
    return entries


def findings(entries):
    """객체 목록을 검사해 파일명/이유만 반환한다. 비밀 값은 진단에 포함하지 않는다."""
    entries = sorted(set(entries))
    if not entries:
        return []
    oids = list(dict.fromkeys(oid for oid, _ in entries))
    sizes = {}
    for line in git('cat-file', '--batch-check=%(objectname) %(objecttype) %(objectsize)', data=('\n'.join(oids) + '\n').encode()).decode().splitlines():
        oid, kind, size = line.split()
        if kind == 'blob':
            sizes[oid] = int(size)
    result = set()
    scanned = {}
    for oid, name in entries:
        if oid not in sizes:
            continue
        if blocked_path(name):
            result.add((name, 'local credential/policy or generated artifact'))
        if oid not in scanned:
            # 큰 파일은 내용을 검사하지 않지만 인증/산출물 경로 차단은 크기와 무관하다.
            data = git('cat-file', 'blob', oid) if sizes[oid] <= 2_000_000 else b''
            scanned[oid] = bool(PRIVATE.search(data.replace(b'\\n', b'\n')) or TOKEN.search(data))
        if name.endswith('.json') and sizes[oid] <= 2_000_000:
            policy = git('cat-file', 'blob', oid)
            if b'"KEYBOX"' in policy and hashlib.sha256(policy).hexdigest() != APPROVED_TEST_POLICIES.get(name):
                result.add((name, 'unapproved stored policy/key material'))
        if scanned[oid]:
            result.add((name, 'private key or access token pattern'))
    return sorted(result)


def main():
    """인덱스 또는 push 검사 모드를 실행하고 민감 파일/검사 오류가 있으면 실패로 종료한다."""
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--index', action='store_true')
    mode.add_argument('--pre-push', metavar='REMOTE')
    args = parser.parse_args()
    try:
        entries = index_entries() if args.index else push_entries(args.pre_push, sys.stdin.read())
        matches = findings(entries)
    except (subprocess.CalledProcessError, ValueError):
        print('Git sensitive-file check could not complete; commit/push blocked.', file=sys.stderr)
        return 1
    if matches:
        for name, reason in matches:
            print(f'BLOCKED {name}: {reason}', file=sys.stderr)
        print('Keep local secrets outside Git. Commit removal of tracked credentials before pushing.', file=sys.stderr)
        return 1
    print('Git sensitive-file check passed.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
