"""Run inside each image to catch unusable user/kernel/native configuration."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class RuntimeTest(unittest.TestCase):
    def test_nonroot_writable_home(self):
        self.assertEqual(os.getuid(), 1000)
        with tempfile.TemporaryFile(dir=Path.home()) as stream:
            stream.write(b'writable')

    def test_python_packages_and_kernel(self):
        import nibabel
        import numpy
        from jupyter_client.kernelspec import KernelSpecManager
        self.assertEqual(sys.executable, '/opt/python-env/bin/python')
        self.assertEqual(KernelSpecManager().get_kernel_spec('field-notes').argv[0], sys.executable)

    def test_native_operation_available(self):
        if os.environ.get('FIELD_NOTES_PROFILE') == 'core':
            self.assertIsNone(shutil.which('fslmaths'))
        else:
            tool = shutil.which('fslmaths')
            self.assertIsNotNone(tool)
            result = subprocess.run([tool], capture_output=True, text=True, timeout=30)
            self.assertIn('Usage', result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
