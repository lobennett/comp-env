"""Execute a trusted notebook in a fresh kernel; keep evidence, never edit source."""
import argparse
from pathlib import Path
import tempfile
import nbformat
from nbclient import NotebookClient


def execute(source: Path, output: Path, kernel: str = 'field-notes') -> None:
    if source.resolve() == output.resolve() or (output.exists() and source.samefile(output)):
        raise ValueError('Evidence output must differ from source')
    notebook = nbformat.read(source, as_version=4)
    # Clear stale evidence even when the source is an executed local working copy.
    for cell in notebook.cells:
        if cell.cell_type == 'code':
            cell.outputs = []
            cell.execution_count = None
    with tempfile.TemporaryDirectory(prefix='field-note-kernel-') as directory:
        client = NotebookClient(notebook, timeout=120, kernel_name=kernel,
                                resources={'metadata': {'path': directory}})
        try:
            client.execute()
        finally:
            nbformat.write(notebook, output)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--kernel', default='field-notes')
    args = parser.parse_args()
    execute(args.source, args.output, args.kernel)
