#!/bin/bash
set -e

EESSI_VERSION=2025.06
NEXTFLOW_VERSION=26.04.0

# Load EESSI environment (archdetect + Lmod handled by init/bash)
if [ -f "/cvmfs/software.eessi.io/versions/${EESSI_VERSION}/init/bash" ]; then
    source "/cvmfs/software.eessi.io/versions/${EESSI_VERSION}/init/bash"
else
    echo "EESSI ${EESSI_VERSION} initialization script not found! Exiting."
    exit 1
fi

module load "Nextflow/${NEXTFLOW_VERSION}"

echo "EESSI ${EESSI_VERSION} environment and Nextflow module loaded."
