#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

TMPDIR=/tmp
export DEBIAN_FRONTEND=noninteractive

# Update package lists and install dependencies for compiling python 3.9.0 from source.
apt-get -qq update
apt-get -qq -y install build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev \
    libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# Install Python 3.9.0 from source
cd $TMPDIR
curl -O https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tgz
tar -xzf Python-3.9.0.tgz
cd Python-3.9.0
./configure --enable-optimizations --prefix=/usr/local
make -j$(nproc)
make altinstall
cd $TMPDIR
rm -rf Python-3.9.0 Python-3.9.0.tgz
ln -sf /usr/local/bin/python3.9 /usr/bin/python3
curl https://bootstrap.pypa.io/get-pip.py -o $TMPDIR/get-pip.py
python3 $TMPDIR/get-pip.py --break-system-packages
rm $TMPDIR/get-pip.py

# Many python libraries - pin versions to resolve tedana 0.0.12 conflicts.
pip install --break-system-packages \
    python-dotenv 'numpy<1.24' duecredit 'pandas>=0.24.0,<2.0' \
    ipython ipykernel notebook jupyterlab voila \
    jupyterlab-git jupyterlab_hdf \
    nilearn nipype templateflow factor-analyzer miniqc 'tedana==0.0.12' 'bokeh<3.4.0' \
    plotly seaborn ggplot \
    statsmodels scikit-image networkx pytest \
    python-rclone python-dateutil img2pdf \
    requests requests_oauthlib lxml beautifulsoup4

# cleanup
apt-get -qq autoremove
apt-get -qq clean
rm -rf /var/lib/apt/lists/*
pip cache purge