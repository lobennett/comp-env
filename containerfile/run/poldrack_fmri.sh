#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

TMPDIR=/tmp
export DEBIAN_FRONTEND=noninteractive

# Update package lists and install python 3.13.5 and pip
apt-get -qq update
apt-get -qq -y install python3 python3-venv python3-pip

pip install --break-system-packages \
    python-dotenv numpy pandas \
    ipython ipykernel notebook jupyterlab voila \
    jupyterlab-git jupyterlab_hdf \
    nilearn nipype templateflow factor-analyzer miniqc tedana bokeh \
    plotly seaborn ggplot \
    statsmodels scikit-image networkx pytest \
    python-rclone python-dateutil img2pdf \
    requests requests_oauthlib lxml beautifulsoup4

# cleanup
apt-get -qq autoremove
apt-get -qq clean
rm -rf /var/lib/apt/lists/*
pip cache purge