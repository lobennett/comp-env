#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

TMPDIR=/tmp
export DEBIAN_FRONTEND=noninteractive

# Install Python 3.12.1 from source
cd $TMPDIR
curl -O https://www.python.org/ftp/python/3.12.1/Python-3.12.1.tgz
tar -xzf Python-3.12.1.tgz
cd Python-3.12.1
./configure --enable-optimizations --prefix=/usr/local
make -j$(nproc)
make altinstall
cd $TMPDIR
rm -rf Python-3.12.1 Python-3.12.1.tgz
ln -sf /usr/local/bin/python3.12 /usr/bin/python3
curl https://bootstrap.pypa.io/get-pip.py -o $TMPDIR/get-pip.py
python3 $TMPDIR/get-pip.py --break-system-packages
rm $TMPDIR/get-pip.py

pip install --break-system-packages \
    python-dotenv numpy pandas \
    ipython ipykernel notebook jupyterlab voila \
    jupyterlab-git jupyterlab_hdf \
    nilearn nipype templateflow factor-analyzer miniqc tedana==24.0.1 bokeh flywheel-sdk \
    plotly seaborn ggplot \
    statsmodels scikit-image networkx pytest \
    python-rclone python-dateutil img2pdf \
    requests requests_oauthlib lxml beautifulsoup4

# Cleanup
apt-get -qq -y autoremove
apt-get -qq clean
rm -rf /var/lib/apt/lists/*
pip cache purge