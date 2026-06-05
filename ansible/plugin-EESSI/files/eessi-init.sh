#!/bin/bash
set -e

EESSI_VERSION=2025.06
NEXTFLOW_VERSION=26.04.0

# Load the EESSI environment. init/bash auto-detects the CPU architecture and
# configures both MODULEPATH and Lmod, so no compat-layer paths are hardcoded.
if [ -f "/cvmfs/software.eessi.io/versions/${EESSI_VERSION}/init/bash" ]; then
    source "/cvmfs/software.eessi.io/versions/${EESSI_VERSION}/init/bash"
else
    echo "EESSI ${EESSI_VERSION} initialization script not found! Exiting."
    exit 1
fi

# Load Nextflow
if module load "Nextflow/${NEXTFLOW_VERSION}"; then
    echo "Successfully loaded Nextflow/${NEXTFLOW_VERSION}"
else
    echo "Failed to load Nextflow/${NEXTFLOW_VERSION}"
    exit 1
fi

echo "EESSI ${EESSI_VERSION} environment with Nextflow initialized."
echo "Current modules:"
module list
