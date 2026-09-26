"""Catch unsafe rebuild inputs before a container build starts."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_inputs import validate_inputs


class InputsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.inputs = {'platform': 'linux/amd64', 'python_version': '3.12.12',
                       'uv_version': '0.9.0', 'micromamba_version': '2.3.0', 'lock_sha256': {}}
        for field in ('python_image', 'uv_image', 'micromamba_image'):
            self.inputs[field] = 'example/image@sha256:' + 'a' * 64
        for name in ('core/uv.lock', 'neuro/conda-lock.yml', 'neuro/conda-linux-64.lock'):
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('fixture\n')
            self.inputs['lock_sha256'][name] = hashlib.sha256(path.read_bytes()).hexdigest()
        self.inventory = {'platform': 'linux-64', 'packages': [{
            'name': 'fsl-avwutils', 'version': '2209.3', 'build': 'h123_0',
            'url': 'https://example.org/linux-64/fsl-avwutils.conda', 'sha256': 'b' * 64}]}
        self.write_fixture()

    def write_fixture(self):
        path = self.root / 'neuro/artifacts.json'
        path.write_text(json.dumps(self.inventory))
        self.inputs['lock_sha256']['neuro/artifacts.json'] = hashlib.sha256(path.read_bytes()).hexdigest()
        (self.root / 'build-inputs.json').write_text(json.dumps(self.inputs))

    def test_valid_inputs(self):
        self.assertEqual(validate_inputs(self.root)['platform'], 'linux/amd64')

    def test_rejects_wrong_platform(self):
        self.inputs['platform'] = 'linux/arm64'
        self.write_fixture()
        with self.assertRaisesRegex(ValueError, 'linux/amd64'):
            validate_inputs(self.root)

    def test_rejects_floating_base(self):
        self.inputs['python_image'] = 'python:latest'
        self.write_fixture()
        with self.assertRaisesRegex(ValueError, 'digest'):
            validate_inputs(self.root)

    def test_rejects_lock_tampering(self):
        (self.root / 'core/uv.lock').write_bytes(b'changed')
        with self.assertRaisesRegex(ValueError, 'checksum'):
            validate_inputs(self.root)

    def test_rejects_missing_lock_coverage(self):
        del self.inputs['lock_sha256']['core/uv.lock']
        self.write_fixture()
        with self.assertRaisesRegex(ValueError, 'core/uv.lock'):
            validate_inputs(self.root)

    def test_rejects_unhashed_native_artifact(self):
        self.inventory['packages'][0]['sha256'] = ''
        self.write_fixture()
        with self.assertRaisesRegex(ValueError, 'sha256'):
            validate_inputs(self.root)

    def test_rejects_native_wrong_platform(self):
        self.inventory['platform'] = 'osx-arm64'
        self.write_fixture()
        with self.assertRaisesRegex(ValueError, 'linux-64'):
            validate_inputs(self.root)

    def test_rejects_path_escape(self):
        self.inputs['lock_sha256']['../secret'] = 'a' * 64
        self.write_fixture()
        with self.assertRaisesRegex(ValueError, 'path'):
            validate_inputs(self.root)


if __name__ == '__main__':
    unittest.main()
