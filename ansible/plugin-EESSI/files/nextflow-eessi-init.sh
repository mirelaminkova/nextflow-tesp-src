#!/bin/bash
set -e

# Manually set MODULEPATH so Lmod can find available modules
export MODULEPATH="/cvmfs/software.eessi.io/versions/2023.06/software/linux/x86_64/amd/zen2/modules/all:/cvmfs/software.eessi.io/host_injections/2023.06/software/linux/x86_64/amd/zen2/modules/all"

# Load the base EESSI environment
if [ -f "/cvmfs/software.eessi.io/versions/2023.06/init/bash" ]; then
    source /cvmfs/software.eessi.io/versions/2023.06/init/bash
else
    echo "EESSI initialization script not found! Exiting."
    exit 1
fi

# Initialize Lmod by sourcing its initialization script
if [ -f "/usr/share/lmod/lmod/init/bash" ]; then
    source /usr/share/lmod/lmod/init/bash
else
    echo "Lmod initialization script not found! Exiting."
    exit 1
fi

# Load the Nextflow module explicitly
if module load Nextflow/23.10.0; then
    echo "Successfully loaded Nextflow/23.10.0"
else
    echo "Failed to load Nextflow/23.10.0"
    exit 1
fi

echo "EESSI environment with Nextflow initialized."
