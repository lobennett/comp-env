# Set shell options for safer script execution:
# nounset: Exit if undefined variable is used
# errexit: Exit if any command fails
# pipefail: Exit if any command in a pipeline fails
set -o nounset
set -o errexit
set -o pipefail

REPO=http://us.archive.ubuntu.com/ubuntu
DIST=jammy
TMPDIR=/tmp
export DEBIAN_FRONTEND=noninteractive

# update repositories
echo "deb $REPO $DIST main restricted universe multiverse" > /etc/apt/sources.list
echo "deb-src $REPO $DIST main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb $REPO $DIST-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src $REPO $DIST-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb $REPO $DIST-backports main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src $REPO $DIST-backports main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb http://security.ubuntu.com/ubuntu $DIST-security main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src http://security.ubuntu.com/ubuntu $DIST-security main restricted universe multiverse" >> /etc/apt/sources.list

# fully upgrade
apt-get -qq update
apt-get -qq install apt-utils
apt-get -qq upgrade
apt-get -qq dist-upgrade

# base packages
apt-get -qq install wget curl rsync git zip unzip p7zip man-db less vim ca-certificates

# python + pip
apt-get -qq install python3 python3-venv
curl https://bootstrap.pypa.io/get-pip.py -o $TMPDIR/get-pip.py
python3 $TMPDIR/get-pip.py
rm $TMPDIR/get-pip.py

# rclone
# curl https://rclone.org/install.sh | bash

# clean up
apt-get -qq autoremove
apt-get -qq clean
