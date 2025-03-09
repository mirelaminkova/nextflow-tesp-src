#!/bin/bash
# /etc/profile.d/eessi_nextflow.sh
#
# Set up the EESSI environment and load the Nextflow module

# Define MODULEPATH and LMOD_LUA_PATH for EESSI and Lmod
export MODULEPATH="/cvmfs/software.eessi.io/versions/2023.06/software/linux/x86_64/amd/zen2/modules/all:/cvmfs/software.eessi.io/host_injections/2023.06/software/linux/x86_64/amd/zen2/modules/all"
export LMOD_LUA_PATH="/usr/share/lmod/lmod/libexec/?.lua;/usr/share/lmod/lmod/libexec/?/init.lua"

# Source the EESSI initialization script if it exists
if [ -f /cvmfs/software.eessi.io/versions/2023.06/init/bash ]; then
    source /cvmfs/software.eessi.io/versions/2023.06/init/bash
fi

# Load the Nextflow module automatically
module load Nextflow/23.10.0
