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

# python packages
pip install -r $TMPDIR/parcel_env.txt

# coder/code-server
wget -qO - https://raw.githubusercontent.com/coder/code-server/main/install.sh | bash

# cleanup
apt-get -qq autoremove
apt-get -qq clean
pip cache purge
