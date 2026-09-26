"""A changed archive must not reach the native package installer."""
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'neuro'))
from install_native import verify_archive


class NativeTest(unittest.TestCase):
    def test_rejects_changed_archive(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'package.conda'
            path.write_bytes(b'tampered')
            with self.assertRaisesRegex(ValueError, 'SHA256'):
                verify_archive(path, hashlib.sha256(b'original').hexdigest())

    def test_accepts_matching_archive(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'package.conda'
            path.write_bytes(b'original')
            verify_archive(path, hashlib.sha256(b'original').hexdigest())
