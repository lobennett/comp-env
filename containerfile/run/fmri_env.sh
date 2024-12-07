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

# Install ANTs 2.4.0
ANTSVERSION="2.4.0"
ANTSPREFIX="/opt/ants"
ANTSTARBALL="ANTs-${ANTSVERSION}.tar.gz"
ANTSTARBALL_URL="https://github.com/ANTsX/ANTs/releases/download/v${ANTSVERSION}/${ANTSTARBALL}"

# Create ANTs installation directory
mkdir -p $ANTSPREFIX

# Download ANTs 2.4.0 from the official GitHub release page
echo "Downloading ANTs ${ANTSVERSION}..."
wget -O $TMPDIR/$ANTSTARBALL $ANTSTARBALL_URL
if [[ $? -ne 0 ]]; then
    echo "Failed to download ${ANTSTARBALL}."
    exit 1
fi

# Extract the tarball
echo "Extracting ANTs ${ANTSVERSION}..."
tar -xz -C $ANTSPREFIX --strip-components=1 -f $TMPDIR/$ANTSTARBALL
if [[ $? -ne 0 ]]; then
    echo "Failed to extract ${ANTSTARBALL}."
    exit 1
fi

# Make sure the binaries are in the PATH and shared libraries in LD_LIBRARY_PATH
export PATH=$ANTSPREFIX/bin:$PATH
export LD_LIBRARY_PATH=$ANTSPREFIX/lib:$LD_LIBRARY_PATH

# Verify ANTs installation
echo "Verifying ANTs installation..."
antsRegistration --version

# python packages
pip install -r $TMPDIR/fmri_env.txt

# cleanup
apt-get -qq autoremove
apt-get -qq clean
pip cache purge

# in addition to these above, we also use fmriprep, qsiprep, and mriqc singularity images. 
# right now, these just exist in our group (russpold) partition in Sherlock. 
