#!/bin/bash
set -e

# Load EESSI environment
if [ -f "/cvmfs/software.eessi.io/versions/2023.06/init/bash" ]; then
    source /cvmfs/software.eessi.io/versions/2023.06/init/bash
else
    echo "EESSI initialization script not found! Exiting."
    exit 1
fi

# Initialize Lmod
if [ -f "/cvmfs/software.eessi.io/versions/2023.06/compat/linux/x86_64-001/usr/share/lmod/lmod/init/bash" ]; then
    source /cvmfs/software.eessi.io/versions/2023.06/compat/linux/x86_64-001/usr/share/lmod/lmod/init/bash
elif [ -f "/cvmfs/software.eessi.io/versions/2023.06/compat/linux/x86_64-002/usr/share/lmod/lmod/init/bash" ]; then
    source /cvmfs/software.eessi.io/versions/2023.06/compat/linux/x86_64-002/usr/share/lmod/lmod/init/bash
else
    export PATH="/cvmfs/software.eessi.io/versions/2023.06/compat/linux/x86_64-002/usr/share/Lmod:$PATH"
fi

# Load necessary EESSI modules for Nextflow
#module load GCCcore/13.2.0
module load Nextflow/23.10.0

echo "EESSI environment and Nextflow module loaded."

