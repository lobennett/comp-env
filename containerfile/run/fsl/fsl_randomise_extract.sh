#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

PATH_TO_FSL_TARBALL=${1:-fsl-6.0.5.2-centos7_64.tar.gz}
FSL_URL="https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.5.2-centos7_64.tar.gz"

# Check if FSL tarball exists, download if not
if [[ ! -f "$PATH_TO_FSL_TARBALL" ]]; then
    echo "FSL tarball not found: $PATH_TO_FSL_TARBALL"
    echo "Attempting to download from: $FSL_URL"
    if wget -O "$PATH_TO_FSL_TARBALL" "$FSL_URL"; then
        echo "Successfully downloaded $PATH_TO_FSL_TARBALL"
    else
        echo "Error: Failed to download FSL from $FSL_URL"
        exit 1
    fi
fi

# Create output directory
mkdir -p fsl_randomise_minimal

# Extract specific files from FSL tarball
tar -xzf "$PATH_TO_FSL_TARBALL" -C fsl_randomise_minimal --strip-components=1 \
    "fsl/bin/randomise" \
    "fsl/lib/libopenblas.so.0" \
    "fsl/lib/libgfortran.so.3" \
    "fsl/etc/fslversion"

# Create minimal tarball
tar -czf fsl_randomise_minimal.tar.gz -C fsl_randomise_minimal .

# Clean up temporary directory
rm -rf fsl_randomise_minimal

echo "Successfully created fsl_randomise_minimal.tar.gz"