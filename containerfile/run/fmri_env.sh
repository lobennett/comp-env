# Set shell options for safer script execution:
# nounset: Exit if undefined variable is used
# errexit: Exit if any command fails
# pipefail: Exit if any command in a pipeline fails
set -o nounset
set -o errexit
set -o pipefail

NUM_CPUS=12
TMPDIR=/tmp
export DEBIAN_FRONTEND=noninteractive

# update apt
apt-get -qq update

# Install antsRegistration and antsApplyTransforms from ANTs (minimal installation)
curl -LO https://github.com/ANTsX/ANTs/releases/download/v2.6.1/ants-2.6.1-ubuntu-22.04-X64-gcc.zip
unzip -q ants-2.6.1-ubuntu-22.04-X64-gcc.zip ants-2.6.1/bin/antsRegistration ants-2.6.1/bin/antsApplyTransforms ants-2.6.1/lib/* -d /tmp/
mkdir -p /opt/ants/bin /opt/ants/lib
cp /tmp/ants-2.6.1/bin/antsRegistration /opt/ants/bin/
cp /tmp/ants-2.6.1/bin/antsApplyTransforms /opt/ants/bin/
cp /tmp/ants-2.6.1/lib/* /opt/ants/lib/ 2>/dev/null || true
rm -rf /tmp/ants-2.6.1 ants-2.6.1-ubuntu-22.04-X64-gcc.zip

# Add minimal ANTs to PATH
echo 'export ANTSPATH=/opt/ants/bin/' >> /etc/profile.d/ants.sh
echo 'export PATH=${ANTSPATH}:$PATH' >> /etc/profile.d/ants.sh
echo 'export LD_LIBRARY_PATH=/opt/ants/lib:$LD_LIBRARY_PATH' >> /etc/profile.d/ants.sh
chmod +x /etc/profile.d/ants.sh

# Also add to .bashrc for non-login shells
echo 'export ANTSPATH=/opt/ants/bin/' >> /root/.bashrc
echo 'export PATH=${ANTSPATH}:$PATH' >> /root/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/ants/lib:$LD_LIBRARY_PATH' >> /root/.bashrc

# Add python alias for both login and non-login shells
echo 'alias python=python3' >> /etc/profile.d/python_alias.sh
echo 'alias python=python3' >> /root/.bashrc

# python packages (install with no cache)
pip install --no-cache-dir --break-system-packages -r $TMPDIR/fmri_env.txt

# comprehensive cleanup
apt-get -qq autoremove --purge
apt-get -qq clean
pip cache purge
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /root/.cache
find /usr/local/lib/python*/site-packages -name "*.pyc" -delete 2>/dev/null || true
find /usr/local/lib/python*/site-packages -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# in addition to these above, we also use fmriprep, qsiprep, and mriqc singularity images. 
# right now, these just exist in our group (russpold) partition in Sherlock. 
