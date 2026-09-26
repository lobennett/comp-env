"""Download SHA256-verified locked archives, then install them without solving."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
from urllib.parse import urlsplit
from urllib.request import urlopen


def verify_archive(path: Path, expected: str) -> None:
    with path.open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    if actual != expected:
        raise ValueError(f'SHA256 mismatch: {path.name}')


def install(inventory_path: Path) -> None:
    packages = json.loads(inventory_path.read_text())['packages']
    with tempfile.TemporaryDirectory(prefix='native-archives-') as directory:
        root = Path(directory)

        def download(package):
            url = urlsplit(package['url'])
            if url.scheme != 'https' or url.username or url.password:
                raise ValueError('Only public HTTPS package URLs are allowed')
            target = root / Path(url.path).name
            with urlopen(package['url'], timeout=120) as source, target.open('wb') as dest:
                shutil.copyfileobj(source, dest)
            verify_archive(target, package['sha256'])
            return target.as_uri() + '#' + package['md5']

        with ThreadPoolExecutor(max_workers=4) as pool:
            urls = list(pool.map(download, packages))
        explicit = root / 'explicit.lock'
        explicit.write_text('@EXPLICIT\n' + '\n'.join(urls) + '\n')
        subprocess.run(['/usr/local/bin/micromamba', 'create', '--yes', '--offline',
                        '--prefix', '/opt/fsl', '--file', str(explicit)], check=True)


if __name__ == '__main__':
    install(Path('/opt/field-notes/neuro/artifacts.json'))
