# Binder adapter: build from the same locked inputs, without a registry release.
FROM ghcr.io/astral-sh/uv@sha256:04d046b13e60d6bcec73cbc5e1cad25d680dea90c8573340950a0ac2d1aef424 AS uv
FROM mambaorg/micromamba@sha256:e0a99b0f17a759e14c2f967dc0ca2d3a3c1ca3c62955f4d20bba770eaaf0184d AS mamba
FROM python@sha256:392307d22300de8b5986851a12d9176dfc0fc073e65bf6523ebd7dcbeb23564e
COPY --from=uv /uv /usr/local/bin/uv
COPY --from=mamba /bin/micromamba /usr/local/bin/micromamba
ENV UV_PROJECT_ENVIRONMENT=/opt/python-env UV_PYTHON_DOWNLOADS=never UV_NO_CACHE=1 UV_LINK_MODE=copy
WORKDIR /opt/field-notes/core
COPY field-notes/core/pyproject.toml field-notes/core/uv.lock field-notes/core/kernel_launcher.py ./
RUN uv sync --locked --no-dev --no-editable --python /usr/local/bin/python
ENV PATH="/opt/python-env/bin:${PATH}"
RUN python -m ipykernel install --prefix=/opt/python-env --name=field-notes --display-name="Field notes" \
    && useradd --create-home --uid 1000 --shell /bin/bash jovyan
RUN python -c 'import json; from pathlib import Path; p=Path("/opt/python-env/share/jupyter/kernels/field-notes/kernel.json"); k=json.loads(p.read_text()); k["argv"]=["/opt/python-env/bin/python","-Xfrozen_modules=off","/opt/field-notes/core/kernel_launcher.py","-f","{connection_file}"]; p.write_text(json.dumps(k,indent=2)+"\n")'
COPY field-notes/neuro/artifacts.json field-notes/neuro/conda-linux-64.lock field-notes/neuro/install_native.py /opt/field-notes/neuro/
ENV MAMBA_ROOT_PREFIX=/opt/mamba
RUN python /opt/field-notes/neuro/install_native.py && micromamba clean --all --yes
ENV FSLDIR=/opt/fsl FSLOUTPUTTYPE=NIFTI_GZ FIELD_NOTES_PROFILE=neuro
ENV FIELD_NOTES_NATIVE_IDENTITY="fsl-avwutils=2209.8=h67d7eeb_2"
ENV PATH="/opt/fsl/share/fsl/bin:/opt/python-env/bin:/opt/fsl/bin:${PATH}"
ENV HOME=/home/jovyan USER=jovyan NB_UID=1000
COPY --chown=1000:1000 field-notes/notebooks/ /home/jovyan/notes/
COPY --chown=1000:1000 field-notes/tests/fixtures/environment.ipynb /home/jovyan/notes/python-fsl-environment/environment.ipynb
COPY --chown=1000:1000 field-notes/BINDER.md /home/jovyan/README.md
USER 1000
WORKDIR /home/jovyan
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser"]
