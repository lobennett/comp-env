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

# Install necessary dependencies for ANTs
apt-get -qq install -y wget gcc g++ zlib1g-dev libjpeg-dev

# Install ANTs 2.4.0 (no root privileges required if writing to local dirs)
ANTSVERSION="2.4.0"
ANTSPREFIX="/opt/ants"
mkdir -p $ANTSPREFIX
wget -qO- https://github.com/ANTsX/ANTs/releases/download/v${ANTSVERSION}/ants_v${ANTSVERSION}_Linux.tar.gz | tar -xz -C $ANTSPREFIX --strip-components=1

# Make sure the binaries are in the PATH and shared libraries in LD_LIBRARY_PATH
export PATH=$ANTSPREFIX/bin:$PATH
export LD_LIBRARY_PATH=$ANTSPREFIX/lib:$LD_LIBRARY_PATH

# python packages
pip install -r $TMPDIR/fmri_env.txt

# cleanup
apt-get -qq autoremove
apt-get -qq clean
pip cache purge

# in addition to these above, we also use fmriprep, qsiprep, and mriqc singularity images. 
# right now, these just exist in our group (russpold) partition in Sherlock. 
