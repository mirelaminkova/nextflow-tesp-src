#!/bin/bash
set -e

# Set MODULEPATH as before
export MODULEPATH="/cvmfs/software.eessi.io/versions/2023.06/software/linux/x86_64/amd/zen2/modules/all:/cvmfs/software.eessi.io/host_injections/2023.06/software/linux/x86_64/amd/zen2/modules/all"

# Set LMOD_LUA_PATH so Lmod finds its Lua modules
export LMOD_LUA_PATH="/usr/share/lmod/lmod/libexec/?.lua;/usr/share/lmod/lmod/libexec/?/init.lua"

# Load the base EESSI environment
source /cvmfs/software.eessi.io/versions/2023.06/init/bash

# Initialize Lmod
source /usr/share/lmod/lmod/init/bash

# Load the Nextflow module
module load Nextflow/23.10.0

echo "EESSI environment with Nextflow initialized."
