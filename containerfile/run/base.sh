#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

TMPDIR=/tmp
export DEBIAN_FRONTEND=noninteractive

apt-get -qq update 
apt-get -qq -y upgrade
apt-get -qq -y dist-upgrade
apt-get -qq -y install apt-utils wget curl rsync git zip unzip p7zip man-db less vim ca-certificates gnupg
 
wget -O- http://neuro.debian.net/lists/bionic.us-ca.full | tee /etc/apt/sources.list.d/neurodebian.sources.list

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA5D32F012649A5A9

apt-get update
apt-get install -qq -y fsl ants

# Get node and npm
apt-get -qq -y install nodejs npm

# Install rclone
curl -fsSL https://rclone.org/install.sh | bash

# coder/code-server
curl -fsSL https://raw.githubusercontent.com/coder/code-server/main/install.sh | bash

# Get uv
curl -fsSL https://astral.sh/uv/install.sh | bash

# clean up
apt-get -qq autoremove
apt-get -qq clean
rm -rf /var/lib/apt/lists/*