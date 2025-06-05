#!/bin/bash
set -e

# Source ANTs environment
if [ -f /etc/profile.d/ants.sh ]; then
    source /etc/profile.d/ants.sh
fi

# If no command is provided, start bash
if [ $# -eq 0 ]; then
    exec /bin/bash
else
    # Execute the provided command
    exec "$@"
fi 