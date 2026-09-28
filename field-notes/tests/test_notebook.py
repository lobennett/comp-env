"""Execute real kernels: source preservation, repeatability and useful failures."""
import os
from pathlib import Path
import sys
import tempfile
import unittest
import nbformat
from nbclient.exceptions import CellExecutionError
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from execute_notebook import execute


class NotebookTest(unittest.TestCase):
    def setUp(self):
        self.source = Path(os.environ['FIELD_NOTEBOOK'])
        self.kernel = os.environ.get('FIELD_KERNEL', 'field-notes')
        self.tmp = tempfile.TemporaryDirectory(prefix='notebook test ')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)

    def test_clean_kernel_repeat_preserves_source(self):
        source = self.root / 'source with spaces.ipynb'
        source.write_bytes(self.source.read_bytes())
        before = source.read_bytes()
        for index in range(2):
            output = self.root / f'result {index}.ipynb'
            execute(source, output, self.kernel)
            result = nbformat.read(output, as_version=4)
            cells = [cell for cell in result.cells if cell.cell_type == 'code']
            self.assertGreater(len(cells), 0)
            self.assertTrue(all(cell.execution_count is not None for cell in cells))
            outputs = [out for cell in cells for out in cell.outputs]
            self.assertFalse(any(out.output_type == 'error' for out in outputs))
            self.assertIn('PASS: Python + FSL volume check', ''.join(out.get('text', '') for out in outputs))
        self.assertEqual(source.read_bytes(), before)
        self.assertEqual({p.name for p in self.root.iterdir()}, {'source with spaces.ipynb', 'result 0.ipynb', 'result 1.ipynb'})

    def test_missing_tool_is_actionable_and_saved(self):
        notebook = nbformat.read(self.source, as_version=4)
        notebook.cells.insert(0, nbformat.v4.new_code_cell("import os; os.environ['PATH'] = '/nonexistent'"))
        source, output = self.root / 'missing.ipynb', self.root / 'failure.ipynb'
        nbformat.write(notebook, source)
        with self.assertRaisesRegex(CellExecutionError, 'fslmaths is unavailable'):
            execute(source, output, self.kernel)
        failed = nbformat.read(output, as_version=4)
        self.assertTrue(any(out.output_type == 'error' for cell in failed.cells if cell.cell_type == 'code' for out in cell.outputs))

    def test_refuses_source_overwrite(self):
        with self.assertRaisesRegex(ValueError, 'source'):
            execute(self.source, self.source, self.kernel)

    def test_missing_identity_fails_clearly(self):
        notebook = nbformat.read(self.source, as_version=4)
        notebook.cells.insert(0, nbformat.v4.new_code_cell("import os; os.environ.pop('FIELD_NOTES_NATIVE_IDENTITY', None)"))
        source = self.root / 'missing identity.ipynb'
        nbformat.write(notebook, source)
        with self.assertRaisesRegex(CellExecutionError, 'Native identity is missing'):
            execute(source, self.root / 'failure.ipynb', self.kernel)


if __name__ == '__main__':
    unittest.main()
