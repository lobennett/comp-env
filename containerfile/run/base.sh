#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

TMPDIR=$TMPDIR
export DEBIAN_FRONTEND=noninteractive

apt-get -qq update 
apt-get -qq -y upgrade
apt-get -qq -y dist-upgrade
apt-get -qq -y install apt-utils wget curl rsync git zip unzip p7zip man-db less vim ca-certificates gnupg file
 
# Install Python build dependencies (needed for both FSL and poldrack_fmri layers)
apt-get -qq -y install build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev \
    libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libncurses5-dev libgdbm-dev libnss3-dev

# Install minimal FSL (only randomise and dependencies) from pre-built tar
echo "=== Installing minimal FSL from local archive ==="
mkdir -p /usr/local/fsl
tar -xzf $TMPDIR/fsl_randomise_minimal.tar.gz -C /usr/local/fsl
chmod +x /usr/local/fsl/bin/randomise

# Set up FSL environment only
cat > /etc/profile.d/neuroimaging.sh << 'EOF'
# FSL Configuration
export FSLDIR=/usr/local/fsl
export PATH=$FSLDIR/bin:$PATH
export LD_LIBRARY_PATH=$FSLDIR/lib:${LD_LIBRARY_PATH:-}
EOF

# Make FSL environment available for current session
export FSLDIR="/usr/local/fsl"
export PATH="/usr/local/fsl/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/fsl/lib:${LD_LIBRARY_PATH:-}"

# Test randomise installation
set +e
randomise --help >/dev/null 2>&1
set -e
echo "=== FSL installation complete! ==="

# Install antsRegistration and antsApplyTransforms from ANTs (minimal installation)
curl -fsSL -o ants-2.6.2-ubuntu-22.04-X64-gcc.zip https://github.com/ANTsX/ANTs/releases/download/v2.6.2/ants-2.6.2-ubuntu-22.04-X64-gcc.zip
unzip -q ants-2.6.2-ubuntu-22.04-X64-gcc.zip ants-2.6.2/bin/antsRegistration ants-2.6.2/bin/antsApplyTransforms ants-2.6.2/lib/* -d $TMPDIR/
mkdir -p /opt/ants/bin /opt/ants/lib
cp $TMPDIR/ants-2.6.2/bin/antsRegistration /opt/ants/bin/
cp $TMPDIR/ants-2.6.2/bin/antsApplyTransforms /opt/ants/bin/
cp $TMPDIR/ants-2.6.2/lib/* /opt/ants/lib/ 2>/dev/null || true
rm -rf $TMPDIR/ants-2.6.2 ants-2.6.2-ubuntu-22.04-X64-gcc.zip

# Add ANTs configuration to neuroimaging.sh after installation
cat >> /etc/profile.d/neuroimaging.sh << 'EOF'

# ANTs Configuration  
export ANTSPATH=/opt/ants/bin
export PATH=$ANTSPATH:$PATH
export LD_LIBRARY_PATH=/opt/ants/lib:${LD_LIBRARY_PATH:-}
EOF

# Update current session environment to include ANTs
export ANTSPATH="/opt/ants/bin"
export PATH="/opt/ants/bin:$PATH"
export LD_LIBRARY_PATH="/opt/ants/lib:${LD_LIBRARY_PATH:-}"

# Test ANTs installation
which antsRegistration >/dev/null
which antsApplyTransforms >/dev/null

# Install Node.js and npm
apt-get -qq -y install nodejs npm

# Install rclone
curl -fsSL https://rclone.org/install.sh | bash

# coder/code-server
curl -fsSL https://raw.githubusercontent.com/coder/code-server/main/install.sh | bash

# Get uv
curl -fsSL https://astral.sh/uv/install.sh | bash

# Final cleanup
apt-get -qq -y autoremove
apt-get -qq clean
rm -rf /var/lib/apt/lists/*