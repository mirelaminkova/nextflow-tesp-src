#!/bin/bash

# Create log directory
mkdir -p /var/log/nextflow
LOGFILE="/var/log/nextflow/nextflow-service.log"

# Start logging
echo "$(date): Starting simplified Nextflow service wrapper" > $LOGFILE
echo "$(date): Initial environment check" >> $LOGFILE
echo "PATH=$PATH" >> $LOGFILE

# Source the EESSI environment directly
echo "$(date): Setting up EESSI environment" >> $LOGFILE
export MODULEPATH="/cvmfs/software.eessi.io/versions/2023.06/software/linux/x86_64/amd/zen2/modules/all:/cvmfs/software.eessi.io/host_injections/2023.06/software/linux/x86_64/amd/zen2/modules/all"
export LMOD_LUA_PATH="/usr/share/lmod/lmod/libexec/?.lua;/usr/share/lmod/lmod/libexec/?/init.lua"

# Try sourcing each component separately and log any errors
if [ -f /cvmfs/software.eessi.io/versions/2023.06/init/bash ]; then
    echo "$(date): Sourcing EESSI base environment" >> $LOGFILE
    source /cvmfs/software.eessi.io/versions/2023.06/init/bash >> $LOGFILE 2>&1
else
    echo "$(date): ERROR - EESSI base environment file not found" >> $LOGFILE
fi

if [ -f /usr/share/lmod/lmod/init/bash ]; then
    echo "$(date): Initializing Lmod" >> $LOGFILE
    source /usr/share/lmod/lmod/init/bash >> $LOGFILE 2>&1
else
    echo "$(date): ERROR - Lmod initialization file not found" >> $LOGFILE
fi

# Check if the module command is available
echo "$(date): Checking for module command" >> $LOGFILE
if command -v module >/dev/null 2>&1; then
    echo "$(date): Module command found, loading Nextflow" >> $LOGFILE
    module load Nextflow/23.10.0 >> $LOGFILE 2>&1
    echo "$(date): Module load completed with status $?" >> $LOGFILE
else
    echo "$(date): ERROR - module command not found" >> $LOGFILE
fi

# Check for nextflow in path
echo "$(date): Looking for nextflow in PATH" >> $LOGFILE
which nextflow >> $LOGFILE 2>&1 || echo "$(date): nextflow not found in PATH" >> $LOGFILE

# Keep the service running with simple sleep
echo "$(date): Starting sleep loop" >> $LOGFILE
sleep infinity
