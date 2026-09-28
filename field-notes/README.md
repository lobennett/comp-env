# Portable field-note environments

Local feasibility work on `field-note-environments`; not a published Binder image.
The first profile is Linux amd64. Apple Silicon runs it under emulation.
Existing comp-env images and Makefile defaults are unchanged.

## Rebuild without updating dependencies

From the comp-env root, with Docker available on PATH:

```sh
python3 field-notes/verify_inputs.py
docker build --platform linux/amd64 -f field-notes/core/Containerfile -t logben-field-notes-core:local field-notes
cat field-notes/core/Containerfile field-notes/neuro/Containerfile | docker build --platform linux/amd64 -f - -t logben-field-notes-neuro:local field-notes
docker run --rm --platform linux/amd64 --network none --mount type=bind,source="$PWD/field-notes",target=/checks,readonly logben-field-notes-core:local python /checks/tests/test_runtime.py
docker run --rm --platform linux/amd64 --network none --mount type=bind,source="$PWD/field-notes",target=/checks,readonly logben-field-notes-neuro:local python /checks/tests/test_runtime.py
```

On this Mac, prepend `/Applications/Docker.app/Contents/Resources/bin` to PATH;
both Docker and its credential helper need to be discoverable. No daemon changes.
The neuro recipe extends the named core stage in the combined build, avoiding
a registry lookup for an unpublished local core digest. Both builds use the same
pinned core inputs and build cache. Images need network during build only.

Python/uv dependencies live in `/opt/python-env`; native FSL dependencies live
in `/opt/fsl`. FSL's own transitive Python must not replace the notebook kernel.
The native installer checks every downloaded archive's SHA256 before invoking
micromamba with an explicit offline installation list. Package licenses and
conda metadata remain installed; redistribution review precedes publication.

## Deliberate dependency updates

Build `field-notes/tools/Containerfile` as `logben-field-notes-resolver:local`.
Its base Python, uv and micromamba are digest pinned. In a disposable amd64
container mount only `field-notes` at `/work`, then run:

```sh
cd /work/core
uv lock
cd /work/tools
uv sync --locked
cd /work/neuro
/work/tools/.venv/bin/conda-lock lock --micromamba --conda /usr/local/bin/micromamba --platform linux-64 --without-cuda --file environment.yml --lockfile conda-lock.yml --kind lock --kind explicit
```

Updates are not rebuilds. Review the generated locks and derive `artifacts.json`
from every package entry (name/version/build/URL/SHA256/MD5), update lock hashes
in `build-inputs.json`, then repeat all checks. Resolver Python dependencies are
locked separately in `tools/uv.lock`. Never run an unversioned installer script.

## Native x86-64 validation

The test-only `Field-note native amd64 validation` workflow runs on the
`field-note-environments` branch. It verifies locked inputs, builds both images,
then runs core smoke tests and the complete neuro suite without network access,
as UID 1000 with a 2 GiB memory cap. No credentials are passed into containers.
It does not publish images or deploy the portfolio.

`tests/fixtures/environment.ipynb` is a synthetic snapshot of the portfolio's
workbench notebook, included so CI does not depend on an unpublished checkout.
It contains no scan data and no saved outputs. Keep this fixture aligned with
the published notebook when publication is reviewed. Test logs record the
fixture hash and local image identities; neither is a registry digest.

The kernel launcher preloads debugger support before initializing kernel
threads. This resolves an observed startup stall under Docker Desktop amd64
emulation on Apple Silicon, but a subsequent subprocess stall remains locally.
Native x86-64 CI is a separate compatibility check, not proof of Mac support.

## Boundaries

The feature-branch source push and CI run are authorized; no image publication,
public Binder session, or live website change is included.
Local image IDs are not evidence of public availability. Exact package versions
do not guarantee bit-identical rebuilt layers. Locks and built image identities
are complementary records, not substitutes for actual notebook execution.
