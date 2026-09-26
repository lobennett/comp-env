"""Validate committed build inputs before rebuilding; never resolves versions."""
import argparse
import hashlib
import json
from pathlib import Path
import re
from urllib.parse import urlsplit


def validate_inputs(root: Path) -> dict:
    root = root.resolve()
    inputs = json.loads((root / 'build-inputs.json').read_text())
    if inputs.get('platform') != 'linux/amd64':
        raise ValueError('Only linux/amd64 is verified')
    for key in ('python_image', 'uv_image', 'micromamba_image'):
        if not re.fullmatch(r'[^\s]+@sha256:[0-9a-f]{64}', inputs.get(key, '')):
            raise ValueError(f'{key} must use an immutable digest')
    for key in ('python_version', 'uv_version', 'micromamba_version'):
        if not re.fullmatch(r'\d+\.\d+\.\d+', inputs.get(key, '')):
            raise ValueError(f'{key} must be an exact version')
    checksums = inputs.get('lock_sha256', {})
    required = {'core/uv.lock', 'neuro/conda-lock.yml', 'neuro/conda-linux-64.lock', 'neuro/artifacts.json'}
    if not required.issubset(checksums):
        raise ValueError(f'Missing lock checksum: {sorted(required - checksums.keys())}')
    for name, expected in checksums.items():
        path = root / name
        if path.is_symlink() or not path.resolve().is_relative_to(root) or Path(name).is_absolute():
            raise ValueError(f'Invalid lock path: {name}')
        if not re.fullmatch(r'[0-9a-f]{64}', expected) or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            raise ValueError(f'Lock checksum mismatch: {name}')
    inventory = json.loads((root / 'neuro/artifacts.json').read_text())
    if inventory.get('platform') != 'linux-64':
        raise ValueError('Native inventory must target linux-64')
    packages = inventory.get('packages', [])
    if not packages or not any(p.get('name') == 'fsl-avwutils' for p in packages):
        raise ValueError('Native inventory requires fsl-avwutils')
    for package in packages:
        if not all(package.get(key) for key in ('name', 'version', 'build')):
            raise ValueError('Native artifact requires name, version and build')
        if not re.fullmatch(r'[0-9a-f]{64}', package.get('sha256', '')):
            raise ValueError('Native artifact requires sha256')
        url = urlsplit(package.get('url', ''))
        if url.scheme != 'https' or not url.hostname or url.username or url.password:
            raise ValueError('Native artifact requires public HTTPS URL')
    return inputs


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', nargs='?', type=Path, default=Path(__file__).parent)
    args = parser.parse_args()
    validate_inputs(args.root)
    print('Build inputs verified: linux/amd64; immutable images; lock checksums; native hashes')
