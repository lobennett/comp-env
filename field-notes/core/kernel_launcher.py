"""Load debugger support before kernel threads start (Docker/Rosetta workaround).

The pinned stack starts natively on arm64 but stalls importing debugger support
after thread initialization under amd64 emulation. Keep output capture enabled.
The kernel/output smoke test guards this narrow import-order workaround.
"""
from ipykernel.debugger import Debugger  # noqa: F401 -- import side effects required
from ipykernel.kernelapp import IPKernelApp

if __name__ == '__main__':
    IPKernelApp.launch_instance()
