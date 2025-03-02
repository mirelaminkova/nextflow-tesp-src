#!/bin/bash
set -e

# Load the base EESSI environment
if [ -f "/cvmfs/software.eessi.io/versions/2023.06/init/bash" ]; then
    source /cvmfs/software.eessi.io/versions/2023.06/init/bash
else
    echo "EESSI initialization script not found! Exiting."
    exit 1
fi

# Initialize Lmod - using a more direct and resilient approach
if [ -d "/cvmfs/software.eessi.io/versions/2023.06" ]; then
    # Try different potential Lmod initialization paths
    LMOD_PATHS=(
        "/cvmfs/software.eessi.io/versions/2023.06/compat/linux/x86_64-001/usr/share/lmod/lmod/init/bash"
        "/cvmfs/software.eessi.io/versions/2023.06/compat/linux/x86_64-002/usr/share/lmod/lmod/init/bash"
        "/cvmfs/software.eessi.io/versions/2023.06/init/lmod/bash"
    )
    
    LMOD_LOADED=0
    for LMOD_PATH in "${LMOD_PATHS[@]}"; do
        if [ -f "$LMOD_PATH" ]; then
            source "$LMOD_PATH"
            LMOD_LOADED=1
            break
        fi
    done
    
    if [ $LMOD_LOADED -eq 0 ]; then
        echo "Warning: Could not find Lmod initialization script. Trying PATH modification."
        export PATH="/cvmfs/software.eessi.io/versions/2023.06/compat/linux/x86_64-002/usr/share/Lmod:$PATH"
    fi
else
    echo "EESSI 2023.06 directory not found! Exiting."
    exit 1
fi

# Load Nextflow module without redirection to make error handling clear
if module load Nextflow/23.10.0; then
    echo "Successfully loaded Nextflow/23.10.0"
else
    echo "Failed to load Nextflow/23.10.0"
    exit 1
fi

echo "EESSI environment with Nextflow initialized."
echo "Current modules:"
module list
